import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kktc_taksim/data/firebase/switch_map.dart';
import 'package:kktc_taksim/data/repositories/shared_ride_repository.dart';
import 'package:kktc_taksim/models/chat_message.dart';
import 'package:kktc_taksim/models/shared_ride.dart';

/// Paylaşımlı gruplar Firestore'da `sharedRides/{rideId}` altında; giriş yapan herkes görür,
/// üyeliğe yalnızca kendini ekleyip çıkarabilir (bkz. firestore.rules).
class FirebaseSharedRideRepository implements SharedRideRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirebaseSharedRideRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _rides => _firestore.collection('sharedRides');

  CollectionReference<Map<String, dynamic>> _messages(String rideId) => _rides.doc(rideId).collection('messages');

  String get _userId {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Giriş yapılmadan paylaşımlı yolculuk değiştirilemez');
    return user.uid;
  }

  @override
  Stream<List<SharedRide>> watchActive() {
    // Kurallar giriş yapmayanın okumasına izin vermez; çıkışta liste boşalır.
    return switchMap(_auth.authStateChanges(), (User? user) {
      if (user == null) return Stream.value(const <SharedRide>[]);
      final now = DateTime.now().millisecondsSinceEpoch;
      return _rides.where('departure', isGreaterThan: now).orderBy('departure').snapshots().map((snapshot) {
        // Akış açık kaldıkça kalkışı geçen gruplar da düşsün.
        final current = DateTime.now();
        return snapshot.docs.map(sharedRideFromDocument).where((r) => r.departure.isAfter(current)).toList();
      });
    });
  }

  @override
  Future<void> create(SharedRide ride) {
    final ref = _rides.doc();
    return ref.set(sharedRideToDocument(ride.copyWith(id: ref.id, memberIds: [_userId])));
  }

  @override
  Future<void> join(String rideId) async {
    final userId = _userId;
    final ref = _rides.doc(rideId);
    // Hata transaction'ın dışında fırlatılır; web'de içeride fırlatılan hata sarmalanabiliyor.
    // Aynı anda iki kişi son koltuğa katılırsa Firestore birini yeniden dener, o da `full` alır.
    final error = await _firestore.runTransaction<SharedRideError?>((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) return SharedRideError.notFound;
      final ride = sharedRideFromDocument(snapshot);
      try {
        final members = membersAfterJoin(ride, userId);
        if (!identical(members, ride.memberIds)) transaction.update(ref, {'memberIds': members});
        return null;
      } on SharedRideException catch (e) {
        return e.error;
      }
    });
    if (error != null) throw SharedRideException(error);
  }

  @override
  Future<void> leave(String rideId) async {
    final userId = _userId;
    final ref = _rides.doc(rideId);
    // Firestore alt koleksiyonları belgeyle birlikte silmez; kurallar mesajları yalnızca tek kalan
    // üyenin silmesine izin verir. Bu arada biri katılırsa mesajlar yine silinmiş olur (nadir).
    final current = await ref.get();
    if (current.exists && sharedRideFromDocument(current).memberIds.every((id) => id == userId)) {
      await _deleteMessages(rideId);
    }
    final error = await _firestore.runTransaction<SharedRideError?>((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) return SharedRideError.notFound;
      final ride = sharedRideFromDocument(snapshot);
      if (!ride.hasMember(userId)) return null;
      final members = membersAfterLeave(ride, userId);
      if (members.isEmpty) {
        transaction.delete(ref);
      } else {
        transaction.update(ref, {'memberIds': members});
      }
      return null;
    });
    if (error != null) throw SharedRideException(error);
  }

  Future<void> _deleteMessages(String rideId) async {
    while (true) {
      final batch = await _messages(rideId).limit(400).get();
      if (batch.docs.isEmpty) return;
      final writes = _firestore.batch();
      for (final doc in batch.docs) {
        writes.delete(doc.reference);
      }
      await writes.commit();
    }
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String rideId) => _messages(rideId)
      .orderBy('sentAt', descending: true)
      .limit(chatHistoryLimit)
      .snapshots()
      .map((snapshot) => snapshot.docs.reversed.map(chatMessageFromDocument).toList());

  @override
  Stream<ChatMessage?> watchLatestMessage(String rideId) => _messages(rideId)
      .orderBy('sentAt', descending: true)
      .limit(1)
      .snapshots()
      .map((snapshot) => snapshot.docs.isEmpty ? null : chatMessageFromDocument(snapshot.docs.first));

  @override
  Future<void> sendMessage(String rideId, String text) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Giriş yapılmadan mesaj gönderilemez');
    final normalized = normalizeMessage(text);
    if (normalized == null) return;
    try {
      await _messages(rideId).add({
        'senderId': user.uid,
        'senderName': user.displayName,
        'text': normalized,
        'sentAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      // Kurallar üye olmayanı reddeder (gruptan çıkarılmış ya da grup silinmiş).
      if (e.code == 'permission-denied') throw const SharedRideException(SharedRideError.notMember);
      rethrow;
    }
  }
}

/// Belgede kimlik tekrar tutulmaz; belge kimliğinin kendisidir.
Map<String, dynamic> sharedRideToDocument(SharedRide ride) => ride.toJson()..remove('id');

SharedRide sharedRideFromDocument(DocumentSnapshot<Map<String, dynamic>> doc) =>
    SharedRide.fromJson({...doc.data()!, 'id': doc.id});

/// Sunucu zamanı henüz yazılmamış (yeni gönderilen) mesajlarda şimdiki zaman kullanılır.
ChatMessage chatMessageFromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
  final data = doc.data()!;
  final sentAt = data['sentAt'];
  return ChatMessage(
    id: doc.id,
    senderId: data['senderId'] as String,
    senderName: data['senderName'] as String?,
    text: data['text'] as String,
    sentAt: sentAt is Timestamp ? sentAt.toDate() : DateTime.now(),
  );
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:kktc_taksim/data/firebase/switch_map.dart';
import 'package:kktc_taksim/data/repositories/shared_ride_repository.dart';
import 'package:kktc_taksim/models/chat_message.dart';
import 'package:kktc_taksim/models/group_diagnostics.dart';
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

  CollectionReference<Map<String, dynamic>> _blockedOf(String userId) =>
      _firestore.collection('users').doc(userId).collection('blocked');

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
  Future<GroupDiagnostics> diagnose() async {
    final user = _auth.currentUser;
    if (user == null) return GroupDiagnostics(signedIn: false, localTime: DateTime.now());

    const timeout = Duration(seconds: 8);
    String? tokenError;
    try {
      await user.getIdToken(true).timeout(timeout);
    } on FirebaseException catch (e) {
      tokenError = e.code;
    } catch (e) {
      tokenError = e.runtimeType.toString();
    }

    String? readError;
    try {
      await _rides.limit(1).get(const GetOptions(source: Source.server)).timeout(timeout);
    } on FirebaseException catch (e) {
      readError = e.code;
    } catch (e) {
      readError = e.runtimeType.toString();
    }

    DateTime? serverTime;
    var localTime = DateTime.now();
    try {
      // Firestore sunucu saatini vermiyor; aynı alan adının yanıt başlığından okunur (saniye hassasiyetinde).
      final response = await http.head(Uri.parse('https://firestore.googleapis.com/')).timeout(timeout);
      localTime = DateTime.now();
      serverTime = parseHttpDate(response.headers['date']);
    } catch (e) {
      debugPrint('Sunucu saati ölçülemedi: $e');
    }

    return GroupDiagnostics(
      signedIn: true,
      userIdPrefix: user.uid.substring(0, user.uid.length < 6 ? user.uid.length : 6),
      tokenError: tokenError,
      readError: readError,
      serverTime: serverTime,
      localTime: localTime,
    );
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

  @override
  Future<void> removeMe() async {
    final userId = _userId;
    final groups = await _rides.where('memberIds', arrayContains: userId).get();
    for (final group in groups.docs) {
      // Önce kendi mesajları (üyeyken silinebilir), sonra ayrılma; son üyeyse grup sohbetiyle gider.
      final mine = await _messages(group.id).where('senderId', isEqualTo: userId).get();
      for (final message in mine.docs) {
        await message.reference.delete();
      }
      await leave(group.id);
    }
    final blocked = await _blockedOf(userId).get();
    for (final doc in blocked.docs) {
      await doc.reference.delete();
    }
  }

  @override
  Future<void> report(String rideId, ChatMessage message, ReportReason reason) =>
      _firestore.collection('reports').add({
        'reporterId': _userId,
        'reportedId': message.senderId,
        'rideId': rideId,
        'messageId': message.id,
        'text': message.text,
        'reason': reason.name,
        'createdAt': FieldValue.serverTimestamp(),
      });

  @override
  Future<void> block(String userId) async {
    final me = _userId;
    if (userId == me) return;
    await _blockedOf(me).doc(userId).set({'createdAt': FieldValue.serverTimestamp()});
  }

  @override
  Future<void> unblock(String userId) => _blockedOf(_userId).doc(userId).delete();

  @override
  Stream<Set<String>> watchBlocked() => switchMap(_auth.authStateChanges(), (User? user) {
        if (user == null) return Stream.value(const <String>{});
        return _blockedOf(user.uid).snapshots().map((snapshot) => snapshot.docs.map((d) => d.id).toSet());
      });

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
  Stream<List<ChatMessage>> watchMessages(String rideId) => retryWhilePermissionDenied(() => _messages(rideId)
      .orderBy('sentAt', descending: true)
      .limit(chatHistoryLimit)
      .snapshots()
      .map((snapshot) => snapshot.docs.reversed.map(chatMessageFromDocument).toList()));

  @override
  Stream<ChatMessage?> watchLatestMessage(String rideId) => retryWhilePermissionDenied(() => _messages(rideId)
      .orderBy('sentAt', descending: true)
      .limit(1)
      .snapshots()
      .map((snapshot) => snapshot.docs.isEmpty ? null : chatMessageFromDocument(snapshot.docs.first)));

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

/// Yeni oluşturulan ya da yeni katılınan grupta sohbet dinlemesi, grup belgesi sunucuya ulaşmadan
/// başlayabiliyor; kurallar o an üyeliği göremediği için "izin yok" deyip dinlemeyi kapatıyordu.
/// Kısa aralıklarla birkaç kez yeniden dener; gerçekten üye değilse hata sonunda iletilir.
Stream<T> retryWhilePermissionDenied<T>(
  Stream<T> Function() open, {
  int retries = 3,
  Duration delay = const Duration(seconds: 2),
}) async* {
  for (var attempt = 0;; attempt++) {
    try {
      await for (final value in open()) {
        yield value;
      }
      return;
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied' || attempt >= retries) rethrow;
      await Future<void>.delayed(delay);
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

/// HTTP `Date` başlığı ("Thu, 05 Nov 2026 13:02:24 GMT"); okunamazsa null.
@visibleForTesting
DateTime? parseHttpDate(String? value) {
  if (value == null) return null;
  try {
    return DateFormat('EEE, dd MMM yyyy HH:mm:ss', 'en_US').parseUtc(value.replaceAll(' GMT', ''));
  } on FormatException {
    return null;
  }
}

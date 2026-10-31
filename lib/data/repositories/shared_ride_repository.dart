import 'package:kktc_taksim/models/chat_message.dart';
import 'package:kktc_taksim/models/shared_ride.dart';

enum SharedRideError { full, notFound, notMember }

/// Sohbet mesajı şikâyet nedenleri; Firestore kurallarındaki listeyle aynı adlar.
enum ReportReason { spam, harassment, inappropriate, other }

class SharedRideException implements Exception {
  final SharedRideError error;

  const SharedRideException(this.error);

  @override
  String toString() => 'SharedRideException($error)';
}

/// Paylaşımlı yolculuk grupları; herkes görür, üyeliği yalnızca kullanıcı kendisi değiştirir.
abstract class SharedRideRepository {
  /// Kalkış zamanı gelmemiş gruplar, en yakın kalkış başta.
  Stream<List<SharedRide>> watchActive();

  /// Grubu oluşturur; oluşturan kişi ilk üye olur. Kimliği repository verir.
  Future<void> create(SharedRide ride);

  /// Dolu gruba katılmak [SharedRideException] fırlatır.
  Future<void> join(String rideId);

  /// Son üye ayrılırsa grup sohbetiyle birlikte silinir.
  Future<void> leave(String rideId);

  /// Grup sohbeti, eskiden yeniye (en fazla son [chatHistoryLimit] mesaj). Yalnızca üyeler okur.
  Stream<List<ChatMessage>> watchMessages(String rideId);

  /// Sohbetteki en son mesaj; okunmamış mesaj rozeti için. Mesaj yoksa null.
  Stream<ChatMessage?> watchLatestMessage(String rideId);

  /// Üye olmayan yazamaz ([SharedRideError.notMember]). Metin kırpılır; boşsa gönderilmez.
  Future<void> sendMessage(String rideId, String text);

  /// Hesap silinirken: kullanıcının (kalkışı geçmişler dahil) bütün gruplarındaki kendi mesajlarını
  /// siler, gruplardan ayrılır (son üyesi olduğu gruplar sohbetiyle silinir) ve engelleme listesini siler.
  Future<void> removeMe();

  /// Mesajı incelenmek üzere şikâyet eder (kimse okuyamaz; Firebase konsolundan incelenir).
  Future<void> report(String rideId, ChatMessage message, ReportReason reason);

  /// Engellenen kişinin sohbet mesajları gizlenir ve okunmamış rozetini etkilemez.
  Future<void> block(String userId);

  Future<void> unblock(String userId);

  /// Giriş yapan kullanıcının engellediği kişiler; girişsizken boş.
  Stream<Set<String>> watchBlocked();
}

const int chatHistoryLimit = 200;

/// Gönderilecek metin: baştaki/sondaki boşluklar atılır, [ChatMessage.maxLength]'e kısaltılır.
/// Boş metin için null.
String? normalizeMessage(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;
  return trimmed.length <= ChatMessage.maxLength ? trimmed : trimmed.substring(0, ChatMessage.maxLength);
}

/// [userId] katılınca üye listesi; zaten üyeyse liste aynen döner.
/// Dolu grupta [SharedRideException] fırlatır.
List<String> membersAfterJoin(SharedRide ride, String userId) {
  if (ride.hasMember(userId)) return ride.memberIds;
  if (ride.isFull) throw const SharedRideException(SharedRideError.full);
  return [...ride.memberIds, userId];
}

/// [userId] ayrılınca üye listesi; boşsa grup silinmelidir.
List<String> membersAfterLeave(SharedRide ride, String userId) =>
    ride.memberIds.where((id) => id != userId).toList();

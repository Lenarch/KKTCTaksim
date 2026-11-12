import 'package:kktc_taksim/core/group_fare.dart';
import 'package:kktc_taksim/models/chat_message.dart';
import 'package:kktc_taksim/models/group_diagnostics.dart';
import 'package:kktc_taksim/models/shared_ride.dart';

enum SharedRideError { full, notFound, notMember, closed }

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

  /// Grup açılamayınca oturumu, sunucudan okumayı ve telefon saatini ölçer; hata fırlatmaz.
  Future<GroupDiagnostics> diagnose();

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

/// Üyelerin sapmalarına göre kişi başı ücret; [members] en az 1 olmalı.
int _priceFor(SharedRide ride, Map<String, int> detours, int members) => groupPricePerPerson(
      baseMeters: ride.baseMeters,
      extraMeters: detours.values.fold(0, (sum, d) => sum + d),
      capacity: ride.capacity,
      members: members,
    );

/// Taslaktan, [userId] tek üye olarak yeni grup; sapması ve ücreti hesaplanır.
SharedRide newGroup(SharedRide draft, String userId, int detourMeters) {
  final detours = {userId: detourMeters};
  return draft.copyWith(memberIds: [userId], detours: detours, pricePerPerson: _priceFor(draft, detours, 1));
}

/// [userId] katılınca grup; zaten üyeyse aynı nesne döner.
/// Eski biçimli ya da açık olmayan grupta [SharedRideError.closed], dolu grupta
/// [SharedRideError.full] fırlatır.
SharedRide rideAfterJoin(SharedRide ride, String userId, int detourMeters) {
  if (ride.hasMember(userId)) return ride;
  if (ride.isLegacy || ride.status != SharedRideStatus.open) {
    throw const SharedRideException(SharedRideError.closed);
  }
  if (ride.isFull) throw const SharedRideException(SharedRideError.full);
  final members = [...ride.memberIds, userId];
  final detours = {...ride.detours, userId: detourMeters};
  return ride.copyWith(memberIds: members, detours: detours, pricePerPerson: _priceFor(ride, detours, members.length));
}

/// [userId] ayrılınca grup; son üyeyse null (grup silinmelidir), üye değilse aynı nesne.
/// Eski biçimde yalnızca üye çıkar, ücret değişmez.
SharedRide? rideAfterLeave(SharedRide ride, String userId) {
  if (!ride.hasMember(userId)) return ride;
  final members = ride.memberIds.where((id) => id != userId).toList();
  if (members.isEmpty) return null;
  if (ride.isLegacy) return ride.copyWith(memberIds: members);
  final detours = {...ride.detours}..remove(userId);
  return ride.copyWith(memberIds: members, detours: detours, pricePerPerson: _priceFor(ride, detours, members.length));
}

/// [userId] biniş noktasını değiştirince grup; yalnızca onun sapması ve ücret güncellenir.
/// Üye değilse [SharedRideError.notMember], eski biçimli ya da açık olmayan grupta
/// [SharedRideError.closed] fırlatır.
SharedRide rideAfterRepick(SharedRide ride, String userId, int detourMeters) {
  if (!ride.hasMember(userId)) throw const SharedRideException(SharedRideError.notMember);
  if (ride.isLegacy || ride.status != SharedRideStatus.open) {
    throw const SharedRideException(SharedRideError.closed);
  }
  final detours = {...ride.detours, userId: detourMeters};
  return ride.copyWith(detours: detours, pricePerPerson: _priceFor(ride, detours, ride.current));
}

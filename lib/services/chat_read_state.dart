import 'package:flutter/foundation.dart';
import 'package:kktc_taksim/models/chat_message.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Hangi grup sohbetinin en son ne zaman okunduğu; cihazda saklanır.
/// Okunmamış mesaj rozeti için kullanılır.
class ChatReadState {
  ChatReadState._();

  static final ChatReadState instance = ChatReadState._();

  static const String _prefix = 'chat_read_';

  /// Grup kimliği → son okunan mesajın zamanı (milisaniye). Değişince rozetler güncellenir.
  final ValueNotifier<Map<String, int>> lastRead = ValueNotifier(const {});

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      lastRead.value = {
        for (final key in prefs.getKeys().where((k) => k.startsWith(_prefix)))
          key.substring(_prefix.length): prefs.getInt(key) ?? 0,
      };
    } catch (_) {
      // Okunamazsa bütün sohbetler okunmamış görünebilir; zararsız.
    }
  }

  /// [message] başkasından geldiyse ve sohbet o mesajdan sonra açılmadıysa true.
  bool isUnread(String rideId, ChatMessage? message, String? userId) {
    if (message == null || message.senderId == userId) return false;
    return message.sentAt.millisecondsSinceEpoch > (lastRead.value[rideId] ?? 0);
  }

  Future<void> markRead(String rideId, DateTime at) async {
    final millis = at.millisecondsSinceEpoch;
    if ((lastRead.value[rideId] ?? 0) >= millis) return;
    lastRead.value = {...lastRead.value, rideId: millis};
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('$_prefix$rideId', millis);
    } catch (_) {
      // Kaydedilemese de bu açılış boyunca okundu sayılır.
    }
  }
}

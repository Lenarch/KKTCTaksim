/// Paylaşımlı grubun sohbetindeki bir mesaj. Gönderenin telefonu tutulmaz, yalnızca adı.
class ChatMessage {
  /// Bir mesajın en fazla uzunluğu (karakter); Firestore kuralları da bunu denetler.
  static const int maxLength = 500;

  final String id;
  final String senderId;

  /// Gönderildiği andaki ad; adı olmayan kullanıcılarda null.
  final String? senderName;
  final String text;
  final DateTime sentAt;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.sentAt,
  });
}

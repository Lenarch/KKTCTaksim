/// Asistana sorulan soru. Tam konum değil, yaklaşık bölge adı gönderilir.
class AssistantQuery {
  final String prompt;

  /// Yolcunun bulunduğu yaklaşık bölge (şehir/semt); bilinmiyorsa boş.
  final String areaName;
  final DateTime localTime;
  final String languageCode;

  const AssistantQuery({
    required this.prompt,
    required this.areaName,
    required this.localTime,
    required this.languageCode,
  });
}

/// Asistanın önerdiği yer. Koordinatı YZ vermez; adres aramasıyla doğrulanır.
class PlaceSuggestion {
  final String name;
  final String reason;

  const PlaceSuggestion({required this.name, required this.reason});
}

enum AssistantError { limitReached, failed }

class AssistantException implements Exception {
  final AssistantError error;

  const AssistantException(this.error);

  @override
  String toString() => 'AssistantException($error)';
}

/// Yolcuya gidilecek yer öneren yapay zekâ asistanı.
abstract class AssistantRepository {
  Future<List<PlaceSuggestion>> suggest(AssistantQuery query);
}

import 'package:kktc_taksim/data/repositories/assistant_repository.dart';

/// Sabit öneriler döner (testler ve YZ bağlanana kadar demo).
class MockAssistantRepository implements AssistantRepository {
  final Duration delay;

  /// Testler için: dolu ise bu hata fırlatılır.
  AssistantError? failWith;

  MockAssistantRepository({this.delay = const Duration(milliseconds: 600)});

  @override
  Future<List<PlaceSuggestion>> suggest(AssistantQuery query) async {
    await Future<void>.delayed(delay);
    if (failWith != null) throw AssistantException(failWith!);
    final tr = query.languageCode == 'tr';
    return [
      PlaceSuggestion(
        name: 'Girne Antik Limanı',
        reason: tr ? 'Deniz kenarında yürüyüş ve kafeler.' : 'Seaside walk and cafes.',
      ),
      PlaceSuggestion(
        name: 'Bellapais Manastırı',
        reason: tr ? 'Tarihi manastır, manzara ve çay bahçesi.' : 'Historic abbey with views and a tea garden.',
      ),
      PlaceSuggestion(
        name: 'Escape Beach',
        reason: tr ? 'Gün batımı için sakin bir plaj.' : 'A relaxed beach for sunset.',
      ),
    ];
  }
}

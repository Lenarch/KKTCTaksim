import 'package:kktc_taksim/data/backend.dart';
import 'package:kktc_taksim/services/chat_read_state.dart';

/// Hesabı ve kullanıcının bütün verisini siler (App Store ve Google Play bunu uygulama içinde ister).
///
/// Sıra önemli: Firestore kuralları verileri yalnızca sahibine sildirdiği için önce veriler, en son
/// hesap silinir. Firebase hesabı silmek için yakın zamanda giriş istediğinden, çağırmadan hemen
/// önce SMS koduyla yeniden doğrulanmalı.
Future<void> deleteAccountAndData(Backend backend) async {
  await backend.liveShares.deleteAllMine();
  await backend.sharedRides.removeMe();
  await backend.trips.deleteAll();
  await backend.auth.deleteAccount();
  await ChatReadState.instance.clear();
}

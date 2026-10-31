import 'package:kktc_taksim/models/app_user.dart';

enum AuthErrorCode { invalidPhone, invalidCode, tooManyRequests, network, unknown }

class AuthException implements Exception {
  final AuthErrorCode code;

  const AuthException(this.code);

  @override
  String toString() => 'AuthException($code)';
}

/// Telefon numarası + SMS koduyla giriş.
abstract class AuthRepository {
  /// Kayıtlı oturumu yükler; uygulama açılırken bir kez çağrılır.
  Future<void> init();

  AppUser? get currentUser;

  /// Önce o anki kullanıcıyı, sonra her değişikliği (giriş, çıkış, ad güncelleme) yayar.
  Stream<AppUser?> get authState;

  /// SMS kodunun hane sayısı (Firebase: 6).
  int get codeLength;

  /// Numaraya doğrulama kodu gönderir.
  Future<void> sendCode(String phone);

  /// Son gönderilen kodu doğrular ve oturumu açar. Kod yanlışsa [AuthException] fırlatır.
  Future<AppUser> verifyCode(String code);

  Future<void> updateName(String name);

  Future<void> signOut();

  /// Profili ve hesabı siler, oturumu kapatır. Firebase yakın zamanda giriş istediği için
  /// çağırmadan hemen önce SMS koduyla yeniden doğrulanmalı (bkz. `deleteAccount` servisi).
  Future<void> deleteAccount();
}

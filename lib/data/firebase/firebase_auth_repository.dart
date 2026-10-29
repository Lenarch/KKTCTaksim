import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:kktc_taksim/data/repositories/auth_repository.dart';
import 'package:kktc_taksim/models/app_user.dart';

/// Firebase Authentication ile telefon + SMS kodu girişi. Ad, Firebase kullanıcısının
/// `displayName`'inde tutulur; profil ayrıca Firestore'da `users/{uid}` belgesine yazılır.
///
/// Web'de kod `signInWithPhoneNumber` ile (görünmez reCAPTCHA), Android/iOS'ta
/// `verifyPhoneNumber` ile gönderilir.
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// Web: kodu doğrulayacak nesne. Mobil: Firebase'in verdiği doğrulama kimliği.
  ConfirmationResult? _confirmation;
  String? _verificationId;

  /// Android bazen SMS'i kendiliğinden okuyup girişi tamamlar; o durumda kod beklenmez.
  UserCredential? _autoSignIn;

  FirebaseAuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  int get codeLength => 6;

  @override
  AppUser? get currentUser => _toAppUser(_auth.currentUser);

  /// `userChanges` ad güncellemelerini de yayar; `authStateChanges` yalnızca giriş/çıkışı.
  @override
  Stream<AppUser?> get authState => _auth.userChanges().map(_toAppUser);

  @override
  Future<void> init() async {
    // Kayıtlı oturum yüklenene kadar bekle; yoksa açılışta kullanıcı yanlışlıkla "çıkmış" görünür.
    await _auth.authStateChanges().first;
  }

  @override
  Future<void> sendCode(String phone) async {
    final normalized = normalizePhone(phone);
    if (normalized == null) throw const AuthException(AuthErrorCode.invalidPhone);
    _confirmation = null;
    _verificationId = null;
    _autoSignIn = null;

    try {
      if (kIsWeb) {
        _confirmation = await _auth.signInWithPhoneNumber(normalized);
      } else {
        await _verifyOnDevice(normalized);
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException(mapAuthError(e.code));
    }
  }

  Future<void> _verifyOnDevice(String phone) {
    final sent = Completer<void>();
    _auth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (credential) async {
        try {
          _autoSignIn = await _auth.signInWithCredential(credential);
        } catch (_) {
          // Otomatik giriş olmazsa kullanıcı kodu elle girer.
        }
        if (!sent.isCompleted) sent.complete();
      },
      verificationFailed: (e) {
        if (!sent.isCompleted) sent.completeError(e);
      },
      codeSent: (verificationId, _) {
        _verificationId = verificationId;
        if (!sent.isCompleted) sent.complete();
      },
      codeAutoRetrievalTimeout: (verificationId) => _verificationId ??= verificationId,
    );
    return sent.future;
  }

  @override
  Future<AppUser> verifyCode(String code) async {
    try {
      final credential = _autoSignIn ??
          await switch ((_confirmation, _verificationId)) {
            (final confirmation?, _) => confirmation.confirm(code),
            (_, final verificationId?) => _auth.signInWithCredential(
                PhoneAuthProvider.credential(verificationId: verificationId, smsCode: code),
              ),
            _ => throw const AuthException(AuthErrorCode.unknown),
          };
      final user = credential.user!;
      await _saveProfile(user);
      return _toAppUser(user)!;
    } on FirebaseAuthException catch (e) {
      throw AuthException(mapAuthError(e.code));
    } finally {
      _autoSignIn = null;
    }
  }

  @override
  Future<void> updateName(String name) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.updateDisplayName(name.trim());
    await user.reload();
    await _saveProfile(_auth.currentUser!);
  }

  @override
  Future<void> signOut() => _auth.signOut();

  /// Profil belgesi; Firestore kuralları yalnızca kullanıcının kendi belgesine izin verir.
  Future<void> _saveProfile(User user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'phone': user.phoneNumber,
        'name': user.displayName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Profil yazılamasa da giriş geçerli; bir sonraki girişte yeniden denenir.
    }
  }

  static AppUser? _toAppUser(User? user) {
    if (user == null) return null;
    final name = user.displayName;
    return AppUser(
      id: user.uid,
      phone: user.phoneNumber ?? '',
      name: name == null || name.isEmpty ? null : name,
    );
  }
}

/// Kullanıcının yazdığı numarayı Firebase'in istediği uluslararası biçime çevirir:
/// `0533 123 45 67`, `533 123 45 67`, `+90 533 123 45 67` → `+905331234567`.
/// KKTC cep numaraları da +90 ile başlar. Geçersizse null.
@visibleForTesting
String? normalizePhone(String input) {
  final hasPlus = input.trim().startsWith('+');
  var digits = input.replaceAll(RegExp(r'\D'), '');
  if (hasPlus) return digits.length >= 10 && digits.length <= 15 ? '+$digits' : null;
  if (digits.startsWith('0')) digits = digits.substring(1);
  if (digits.length == 10) return '+90$digits';
  if (digits.length == 12 && digits.startsWith('90')) return '+$digits';
  return null;
}

/// Firebase hata kodlarını uygulamanın anlaşılır hatalarına çevirir.
@visibleForTesting
AuthErrorCode mapAuthError(String code) => switch (code) {
      'invalid-phone-number' || 'missing-phone-number' => AuthErrorCode.invalidPhone,
      'invalid-verification-code' ||
      'missing-verification-code' ||
      'session-expired' ||
      'code-expired' =>
        AuthErrorCode.invalidCode,
      'too-many-requests' || 'quota-exceeded' => AuthErrorCode.tooManyRequests,
      'network-request-failed' => AuthErrorCode.network,
      _ => AuthErrorCode.unknown,
    };

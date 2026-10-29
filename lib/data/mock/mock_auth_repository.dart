import 'dart:async';
import 'dart:convert';

import 'package:kktc_taksim/data/mock/watch_value.dart';
import 'package:kktc_taksim/data/repositories/auth_repository.dart';
import 'package:kktc_taksim/models/app_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Demo girişi: SMS gönderilmez, doğru uzunluktaki her kod kabul edilir. Oturum cihazda saklanır.
class MockAuthRepository implements AuthRepository {
  static const String _sessionKey = 'mock_session';

  @override
  int get codeLength => 6;

  final StreamController<void> _changes = StreamController.broadcast();
  AppUser? _user;
  String? _pendingPhone;

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> get authState => watchValue(_changes.stream, () => _user);

  @override
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_sessionKey);
      if (json != null) _user = AppUser.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      // Kayıt okunamazsa oturum kapalı başlar.
    }
  }

  @override
  Future<void> sendCode(String phone) async {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) throw const AuthException(AuthErrorCode.invalidPhone);
    _pendingPhone = phone.trim();
  }

  @override
  Future<AppUser> verifyCode(String code) async {
    final phone = _pendingPhone;
    if (phone == null) throw const AuthException(AuthErrorCode.unknown);
    if (!RegExp('^\\d{$codeLength}\$').hasMatch(code)) {
      throw const AuthException(AuthErrorCode.invalidCode);
    }
    final id = 'demo-${phone.replaceAll(RegExp(r'\D'), '')}';
    // Aynı numarayla yeniden girişte önceki ad korunur.
    final previousName = _user?.id == id ? _user?.name : null;
    _pendingPhone = null;
    await _setUser(AppUser(id: id, phone: phone, name: previousName));
    return _user!;
  }

  @override
  Future<void> updateName(String name) async {
    final user = _user;
    if (user == null) return;
    await _setUser(user.copyWith(name: name.trim()));
  }

  @override
  Future<void> signOut() => _setUser(null);

  Future<void> _setUser(AppUser? user) async {
    _user = user;
    _changes.add(null);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (user == null) {
        await prefs.remove(_sessionKey);
      } else {
        await prefs.setString(_sessionKey, jsonEncode(user.toJson()));
      }
    } catch (_) {
      // Kaydedilemese de oturum bu açılış boyunca geçerli kalır.
    }
  }
}

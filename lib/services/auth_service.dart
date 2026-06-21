import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'preferences_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  static const String _kLoggedIn = 'auth_logged_in';
  static const String _kEmail = 'auth_email';
  static const String _kDisplayName = 'auth_display_name';
  static const String _kPassword = 'auth_password';

  factory AuthService() => _instance;

  AuthService._internal();

  bool get isLoggedIn => PreferencesService().getBool(_kLoggedIn);
  String? get userEmail => PreferencesService().getString(_kEmail);
  String? get displayName => PreferencesService().getString(_kDisplayName);

  static String _hash(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  Future<bool> login(String email, String password) async {
    final storedEmail = PreferencesService().getString(_kEmail);
    final storedHash = PreferencesService().getString(_kPassword);

    if (storedEmail == null || storedHash == null) return false;

    final valid = storedEmail == email && storedHash == _hash(password);
    if (valid) await PreferencesService().setBool(_kLoggedIn, true);
    return valid;
  }

  Future<bool> register(String email, String password, String displayName) async {
    final storedEmail = PreferencesService().getString(_kEmail);
    if (storedEmail != null && storedEmail != email) return false;

    await PreferencesService().setString(_kEmail, email);
    await PreferencesService().setString(_kPassword, _hash(password));
    await PreferencesService().setString(_kDisplayName, displayName);
    await PreferencesService().setBool(_kLoggedIn, true);
    return true;
  }

  Future<void> logout() async {
    await PreferencesService().setBool(_kLoggedIn, false);
  }

  Future<void> deleteAccount() async {
    await PreferencesService().remove(_kLoggedIn);
    await PreferencesService().remove(_kEmail);
    await PreferencesService().remove(_kDisplayName);
    await PreferencesService().remove(_kPassword);
  }
}

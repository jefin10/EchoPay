import 'package:shared_preferences/shared_preferences.dart';

/// Typed wrapper over [SharedPreferences].
///
/// Before this existed, ~17 files reached into `SharedPreferences` directly
/// with stringly-typed keys (`prefs.getString('phoneNumber')` etc.), which
/// made the persisted contract impossible to see in one place. Everything
/// the app stores locally now goes through here.
class SessionStore {
  SessionStore(this._prefs);

  final SharedPreferences _prefs;

  // ---- keys (single source of truth) ----
  static const _kPhoneNumber = 'phoneNumber';
  static const _kIsLoggedIn = 'isLoggedIn';
  static const _kUserName = 'userName';
  static const _kUpiName = 'upiName';
  static const _kUpiId = 'upiId';
  static const _kUpiMail = 'upiMail';
  static const _kIsSignedUp = 'isSignedUp';
  static const _kSignedUpPhone = 'signedUpPhoneNumber';
  static const _kBiometricEnabled = 'biometricEnabled';

  // ---- identity ----
  String? get phoneNumber => _prefs.getString(_kPhoneNumber);
  Future<void> setPhoneNumber(String value) =>
      _prefs.setString(_kPhoneNumber, value);

  bool get isLoggedIn => _prefs.getBool(_kIsLoggedIn) ?? false;
  Future<void> setLoggedIn(bool value) => _prefs.setBool(_kIsLoggedIn, value);

  /// Display name. Falls back to the legacy `upiName` key for older installs.
  String? get userName =>
      _prefs.getString(_kUserName) ?? _prefs.getString(_kUpiName);
  Future<void> setUserName(String value) =>
      _prefs.setString(_kUserName, value);

  /// UPI handle. Falls back to the legacy `upiMail` key for older installs.
  String? get upiId =>
      _prefs.getString(_kUpiId) ?? _prefs.getString(_kUpiMail);
  Future<void> setUpiId(String value) => _prefs.setString(_kUpiId, value);

  // ---- signup flow ----
  bool get isSignedUp => _prefs.getBool(_kIsSignedUp) ?? false;
  Future<void> setSignedUp(bool value) => _prefs.setBool(_kIsSignedUp, value);

  String? get signedUpPhoneNumber => _prefs.getString(_kSignedUpPhone);
  Future<void> setSignedUpPhoneNumber(String value) =>
      _prefs.setString(_kSignedUpPhone, value);

  // ---- security ----
  bool get biometricEnabled => _prefs.getBool(_kBiometricEnabled) ?? false;
  Future<void> setBiometricEnabled(bool value) =>
      _prefs.setBool(_kBiometricEnabled, value);

  // ---- arbitrary toggles (notification prefs etc.) ----
  bool flag(String key, {bool defaultValue = false}) =>
      _prefs.getBool(key) ?? defaultValue;
  Future<void> setFlag(String key, bool value) => _prefs.setBool(key, value);

  /// Wipe all persisted state (used on logout).
  Future<void> clear() => _prefs.clear();

  /// Persist the full identity in one call after a successful login/signup.
  Future<void> saveSession({
    required String phoneNumber,
    String? userName,
    String? upiId,
  }) async {
    await setPhoneNumber(phoneNumber);
    await setLoggedIn(true);
    if (userName != null && userName.isNotEmpty) await setUserName(userName);
    if (upiId != null && upiId.isNotEmpty) await setUpiId(upiId);
  }
}

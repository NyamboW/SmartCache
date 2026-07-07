import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight service for device security (biometrics / PIN).
/// No network dependency – uses SharedPreferences for the toggle flag.
class SecurityService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  static const _deviceSecurityKey = 'device_security_enabled';

  bool _isAuthenticating = false;
  DateTime? _lastAuthTime;
  bool _isSecurityEnabled = false;

  bool get isAuthenticating => _isAuthenticating;
  DateTime? get lastAuthTime => _lastAuthTime;
  bool get isSecurityEnabled => _isSecurityEnabled;

  /// Load the persisted toggle value.
  Future<bool> getDeviceSecurityEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    _isSecurityEnabled = prefs.getBool(_deviceSecurityKey) ?? false;
    return _isSecurityEnabled;
  }

  /// Persist the toggle value.
  Future<void> setDeviceSecurityEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_deviceSecurityKey, enabled);
    _isSecurityEnabled = enabled;
  }

  /// Trigger biometric / PIN authentication.
  Future<bool> authenticateWithBiometrics() async {
    if (_isAuthenticating) return false;

    try {
      _isAuthenticating = true;
      final canAuthenticate =
          await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();

      if (!canAuthenticate) {
        return false;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Secure SmartCache with device security',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (authenticated) {
        _lastAuthTime = DateTime.now();
      }

      return authenticated;
    } on PlatformException catch (e) {
      debugPrint('Auth error: ${e.code} - ${e.message}');
      return false;
    } finally {
      _isAuthenticating = false;
    }
  }
}

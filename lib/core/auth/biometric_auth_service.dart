import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';

class BiometricAuthService {
  BiometricAuthService._();

  static final BiometricAuthService instance = BiometricAuthService._();

  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<bool> canUseFingerprintLogin() async {
    if (kIsWeb) {
      return false;
    }

    try {
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!canCheckBiometrics && !isDeviceSupported) {
        return false;
      }

      final List<BiometricType> biometrics =
          await _localAuth.getAvailableBiometrics();
      return _hasFingerprintBiometric(biometrics);
    } catch (_) {
      return false;
    }
  }

  bool _hasFingerprintBiometric(List<BiometricType> biometrics) {
    return biometrics.contains(BiometricType.fingerprint) ||
        // Android can report fingerprint-capable biometrics as strong/weak.
        biometrics.contains(BiometricType.strong) ||
        biometrics.contains(BiometricType.weak);
  }

  Future<BiometricAuthResult> authenticateQuickLogin() async {
    if (kIsWeb) {
      return const BiometricAuthResult.failure(
        'Fingerprint login is not available on Flutter web. Test it on Android or iPhone.',
      );
    }

    try {
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!canCheckBiometrics && !isDeviceSupported) {
        return const BiometricAuthResult.failure(
          'This device does not support biometric login yet.',
        );
      }

      final List<BiometricType> biometrics =
          await _localAuth.getAvailableBiometrics();
      if (biometrics.isEmpty) {
        return const BiometricAuthResult.failure(
          'No fingerprint or face login is set up on this device.',
        );
      }

      final bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Confirm your biometric to unlock PTS DATA',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (!authenticated) {
        return const BiometricAuthResult.failure(
          'Biometric login was cancelled.',
        );
      }

      return const BiometricAuthResult.success();
    } on PlatformException catch (error) {
      switch (error.code) {
        case auth_error.notAvailable:
          return const BiometricAuthResult.failure(
            'This device has no biometric hardware.',
          );
        case auth_error.notEnrolled:
          return const BiometricAuthResult.failure(
            'Set up fingerprint or face login on this device first.',
          );
        case auth_error.lockedOut:
        case auth_error.permanentlyLockedOut:
          return const BiometricAuthResult.failure(
            'Biometric login is temporarily locked. Use your PIN for now.',
          );
        default:
          return BiometricAuthResult.failure(
            error.message?.toString() ?? 'Biometric login failed. Try again.',
          );
      }
    } catch (_) {
      return const BiometricAuthResult.failure(
        'Biometric login could not start on this device.',
      );
    }
  }
}

class BiometricAuthResult {
  const BiometricAuthResult._({required this.isSuccess, this.message});

  const BiometricAuthResult.success() : this._(isSuccess: true);

  const BiometricAuthResult.failure(String message)
    : this._(isSuccess: false, message: message);

  final bool isSuccess;
  final String? message;
}

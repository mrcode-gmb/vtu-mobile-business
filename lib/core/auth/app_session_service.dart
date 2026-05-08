import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/app_routes.dart';
import '../settings/app_settings_service.dart';

class AppSessionService {
  AppSessionService._();

  static final AppSessionService instance = AppSessionService._();

  static const Duration instantUnlockWindow = Duration(hours: 1);

  static const String _displayNameKey = 'session.display_name';
  static const String _identifierKey = 'session.identifier';
  static const String _hasTransactionPinKey = 'session.has_transaction_pin';
  static const String _apiTokenKey = 'session.api_token';
  static const String _lastFullAuthAtKey = 'session.last_full_auth_at';
  static const String _lastUnlockAtKey = 'session.last_unlock_at';

  Future<RememberedUser?> getRememberedUser() async {
    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      final String? displayName = preferences.getString(_displayNameKey);
      final String? identifier = preferences.getString(_identifierKey);

      if (displayName == null || identifier == null) {
        return null;
      }

      return RememberedUser(
        displayName: displayName,
        identifier: identifier,
        hasTransactionPin: preferences.getBool(_hasTransactionPinKey) ?? false,
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> getApiToken() async {
    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      final String? token = preferences.getString(_apiTokenKey);
      if (token == null || token.isEmpty) {
        return null;
      }

      return token;
    } catch (_) {
      return null;
    }
  }

  Future<bool> canUseQuickLogin() async {
    final RememberedUser? rememberedUser = await getRememberedUser();
    if (rememberedUser == null) {
      return false;
    }

    final AppSettings settings = await AppSettingsService.instance.load();
    return settings.biometricUnlockEnabled ||
        (settings.pinQuickUnlockEnabled && rememberedUser.hasTransactionPin);
  }

  Future<String> getLaunchRoute() async {
    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      final String? displayName = preferences.getString(_displayNameKey);
      final String? identifier = preferences.getString(_identifierKey);

      if (displayName == null || identifier == null) {
        return AppRoutes.welcome;
      }

      final DateTime? lastUnlockAt = _readDate(
        preferences.getString(_lastUnlockAtKey),
      );
      final DateTime now = DateTime.now();

      if (lastUnlockAt != null &&
          now.difference(lastUnlockAt) <= instantUnlockWindow) {
        return AppRoutes.dashboard;
      }

      final bool canUseQuickLogin = await this.canUseQuickLogin();
      return canUseQuickLogin ? AppRoutes.quickLogin : AppRoutes.login;
    } catch (_) {
      return AppRoutes.welcome;
    }
  }

  Future<void> recordFullAuth({
    required String displayName,
    required String identifier,
    String? apiToken,
    required bool hasTransactionPin,
  }) async {
    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      final String timestamp = DateTime.now().toIso8601String();

      await preferences.setString(_displayNameKey, displayName);
      await preferences.setString(_identifierKey, identifier);
      await preferences.setBool(_hasTransactionPinKey, hasTransactionPin);
      if (apiToken != null && apiToken.isNotEmpty) {
        await preferences.setString(_apiTokenKey, apiToken);
      }
      await preferences.setString(_lastFullAuthAtKey, timestamp);
      await preferences.setString(_lastUnlockAtKey, timestamp);
    } catch (_) {
      return;
    }
  }

  Future<void> recordQuickUnlock({
    String? displayName,
    String? identifier,
    String? apiToken,
    bool? hasTransactionPin,
  }) async {
    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      if (displayName != null && displayName.isNotEmpty) {
        await preferences.setString(_displayNameKey, displayName);
      }
      if (identifier != null && identifier.isNotEmpty) {
        await preferences.setString(_identifierKey, identifier);
      }
      if (apiToken != null && apiToken.isNotEmpty) {
        await preferences.setString(_apiTokenKey, apiToken);
      }
      if (hasTransactionPin != null) {
        await preferences.setBool(_hasTransactionPinKey, hasTransactionPin);
      }
      await preferences.setString(
        _lastUnlockAtKey,
        DateTime.now().toIso8601String(),
      );
    } catch (_) {
      return;
    }
  }

  Future<void> updateTransactionPinStatus(bool hasTransactionPin) async {
    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      await preferences.setBool(_hasTransactionPinKey, hasTransactionPin);
    } catch (_) {
      return;
    }
  }

  Future<void> clear() async {
    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      await preferences.remove(_apiTokenKey);
      await preferences.remove(_lastUnlockAtKey);
    } catch (_) {
      return;
    }
  }

  Future<void> signOut() async {
    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      await preferences.remove(_displayNameKey);
      await preferences.remove(_identifierKey);
      await preferences.remove(_hasTransactionPinKey);
      await preferences.remove(_apiTokenKey);
      await preferences.remove(_lastFullAuthAtKey);
      await preferences.remove(_lastUnlockAtKey);
    } catch (_) {
      return;
    }
  }

  Future<String> invalidateForReauth() async {
    await clear();

    final RememberedUser? rememberedUser = await getRememberedUser();
    if (rememberedUser == null) {
      return AppRoutes.login;
    }

    final bool canQuickUnlock = await canUseQuickLogin();
    return canQuickUnlock ? AppRoutes.quickLogin : AppRoutes.login;
  }

  Future<void> redirectToReauth(BuildContext context) async {
    final String routeName = await invalidateForReauth();
    if (!context.mounted) {
      return;
    }

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(routeName, (Route<dynamic> route) => false);
  }

  DateTime? _readDate(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }
}

class RememberedUser {
  const RememberedUser({
    required this.displayName,
    required this.identifier,
    required this.hasTransactionPin,
  });

  final String displayName;
  final String identifier;
  final bool hasTransactionPin;
}

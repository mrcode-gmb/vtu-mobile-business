import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsService {
  AppSettingsService._();

  static final AppSettingsService instance = AppSettingsService._();

  static const String _themeModeKey = 'settings.theme_mode';
  static const String _biometricUnlockKey = 'settings.biometric_unlock_enabled';
  static const String _pinQuickUnlockKey = 'settings.pin_quick_unlock_enabled';
  static const String _transactionAlertsKey =
      'settings.transaction_alerts_enabled';
  static const String _marketingUpdatesKey =
      'settings.marketing_updates_enabled';
  static const String _hideBalanceKey = 'settings.hide_balance_enabled';

  Future<AppSettings> load() async {
    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();

      return AppSettings(
        themeMode: _themeModeFromString(preferences.getString(_themeModeKey)),
        biometricUnlockEnabled:
            preferences.getBool(_biometricUnlockKey) ?? false,
        pinQuickUnlockEnabled: preferences.getBool(_pinQuickUnlockKey) ?? true,
        transactionAlertsEnabled:
            preferences.getBool(_transactionAlertsKey) ?? true,
        marketingUpdatesEnabled:
            preferences.getBool(_marketingUpdatesKey) ?? false,
        hideBalanceEnabled: preferences.getBool(_hideBalanceKey) ?? false,
      );
    } catch (_) {
      return const AppSettings.defaults();
    }
  }

  Future<ThemeMode> getThemeMode() async => (await load()).themeMode;

  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      await preferences.setString(_themeModeKey, _themeModeToString(mode));
    } catch (_) {
      return;
    }
  }

  Future<void> setBiometricUnlockEnabled(bool value) async {
    await _setBool(_biometricUnlockKey, value);
  }

  Future<void> setPinQuickUnlockEnabled(bool value) async {
    await _setBool(_pinQuickUnlockKey, value);
  }

  Future<void> setTransactionAlertsEnabled(bool value) async {
    await _setBool(_transactionAlertsKey, value);
  }

  Future<void> setMarketingUpdatesEnabled(bool value) async {
    await _setBool(_marketingUpdatesKey, value);
  }

  Future<void> setHideBalanceEnabled(bool value) async {
    await _setBool(_hideBalanceKey, value);
  }

  Future<void> _setBool(String key, bool value) async {
    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      await preferences.setBool(key, value);
    } catch (_) {
      return;
    }
  }

  ThemeMode _themeModeFromString(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
      case 'system':
      default:
        return ThemeMode.dark;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'dark';
    }
  }
}

class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.biometricUnlockEnabled,
    required this.pinQuickUnlockEnabled,
    required this.transactionAlertsEnabled,
    required this.marketingUpdatesEnabled,
    required this.hideBalanceEnabled,
  });

  const AppSettings.defaults()
    : this(
        themeMode: ThemeMode.dark,
        biometricUnlockEnabled: false,
        pinQuickUnlockEnabled: true,
        transactionAlertsEnabled: true,
        marketingUpdatesEnabled: false,
        hideBalanceEnabled: false,
      );

  final ThemeMode themeMode;
  final bool biometricUnlockEnabled;
  final bool pinQuickUnlockEnabled;
  final bool transactionAlertsEnabled;
  final bool marketingUpdatesEnabled;
  final bool hideBalanceEnabled;

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? biometricUnlockEnabled,
    bool? pinQuickUnlockEnabled,
    bool? transactionAlertsEnabled,
    bool? marketingUpdatesEnabled,
    bool? hideBalanceEnabled,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      biometricUnlockEnabled:
          biometricUnlockEnabled ?? this.biometricUnlockEnabled,
      pinQuickUnlockEnabled:
          pinQuickUnlockEnabled ?? this.pinQuickUnlockEnabled,
      transactionAlertsEnabled:
          transactionAlertsEnabled ?? this.transactionAlertsEnabled,
      marketingUpdatesEnabled:
          marketingUpdatesEnabled ?? this.marketingUpdatesEnabled,
      hideBalanceEnabled: hideBalanceEnabled ?? this.hideBalanceEnabled,
    );
  }
}

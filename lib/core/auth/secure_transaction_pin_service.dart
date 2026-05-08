import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureTransactionPinService {
  SecureTransactionPinService._();

  static final SecureTransactionPinService instance =
      SecureTransactionPinService._();

  static const String _transactionPinKey = 'secure.transaction_pin';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<bool> savePin(String pin) async {
    if (pin.trim().length != 4) {
      return false;
    }

    try {
      await _storage.write(key: _transactionPinKey, value: pin.trim());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> readPin() async {
    try {
      final String? pin = await _storage.read(key: _transactionPinKey);
      if (pin == null || pin.trim().length != 4) {
        return null;
      }

      return pin.trim();
    } catch (_) {
      return null;
    }
  }

  Future<void> clearPin() async {
    try {
      await _storage.delete(key: _transactionPinKey);
    } catch (_) {
      return;
    }
  }
}

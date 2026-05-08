// features/airtime/presentation/pages/buy_airtime_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/auth/app_session_service.dart';
import '../../../../core/auth/biometric_auth_service.dart';
import '../../../../core/auth/secure_transaction_pin_service.dart';
import '../../../../core/settings/app_settings_service.dart';
import '../../data/airtime_api_service.dart';
import '../../../dashboard/data/dashboard_api_service.dart';
import '../../../navigation/presentation/widgets/app_bottom_navigation.dart';
import '../../../shared/presentation/widgets/pts_data_loader_overlay.dart';
import '../../../shared/presentation/widgets/network_logo_badge.dart';

const Color _primary = Color(0xFFB89CFF);
const Color _primaryDark = Color(0xFF7FA0F5);
const Color _softTint = Color(0xFFF3F4F6);
const Color _softBorder = Color(0xFFE5E7EB);
const Color _darkBackground = Color(0xFF171925);
const Color _darkSurface = Color(0xFF22263A);
const Color _darkPanel = Color(0xFF252A42);
const Color _darkMuted = Color(0xFFC7CDDC);

class BuyAirtimePage extends StatefulWidget {
  const BuyAirtimePage({super.key});

  @override
  State<BuyAirtimePage> createState() => _BuyAirtimePageState();
}

class _BuyAirtimePageState extends State<BuyAirtimePage> {
  static const List<int> _quickAmounts = <int>[100, 200, 500, 1000, 2000, 5000];
  static const List<_NetworkOption> _networkOptions = <_NetworkOption>[
    _NetworkOption(
      id: '1',
      name: 'MTN',
      shortName: 'MTN',
      assetPath: 'assets/images/mtn_logo.jpeg',
      brandColor: Color(0xFFFACC15),
      foregroundColor: Color(0xFF111827),
    ),
    _NetworkOption(
      id: '2',
      name: 'GLO',
      shortName: 'GLO',
      assetPath: 'assets/images/Glo_logo.png',
      brandColor: Color(0xFF16A34A),
      foregroundColor: Colors.white,
    ),
    _NetworkOption(
      id: '3',
      name: '9MOBILE',
      shortName: '9M',
      assetPath: 'assets/images/9mobile-1.svg',
      brandColor: Color(0xFF10B981),
      foregroundColor: Colors.white,
    ),
    _NetworkOption(
      id: '4',
      name: 'AIRTEL',
      shortName: 'ATL',
      assetPath: 'assets/images/Airtel_logo-01.png',
      brandColor: Color(0xFFEF4444),
      foregroundColor: Colors.white,
    ),
  ];
  static const List<_SavedRecipient> _initialRecipients = <_SavedRecipient>[
    _SavedRecipient(phoneNumber: '08031234567', networkId: '1', usageCount: 4),
    _SavedRecipient(phoneNumber: '07041234567', networkId: '2', usageCount: 2),
    _SavedRecipient(phoneNumber: '08151234567', networkId: '4', usageCount: 3),
    _SavedRecipient(phoneNumber: '09091234567', networkId: '3', usageCount: 1),
  ];
  static const double _discountRate = 0.02;
  static const int _minimumAmount = 100;
  static const int _maximumAmount = 30000;

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  late List<_SavedRecipient> _recentRecipients;

  double _walletBalance = 0;
  String? _selectedNetworkId;
  bool _isLoadingWalletBalance = true;
  bool _saveRecipient = true;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _recentRecipients = List<_SavedRecipient>.from(_initialRecipients);
    _loadWalletBalance();
    _loadSavedRecipients();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  String get _phoneNumber => _phoneController.text.trim();

  int get _amount {
    final int parsed = int.tryParse(_amountController.text) ?? 0;
    return parsed.clamp(0, _maximumAmount);
  }

  double get _paidAmount {
    if (_amount < 1) {
      return 0;
    }

    return double.parse((_amount * (1 - _discountRate)).toStringAsFixed(2));
  }

  double get _savedAmount => (_amount - _paidAmount).clamp(0, double.infinity);

  bool get _hasValidPhone =>
      _phoneNumber.length >= 10 && _phoneNumber.length <= 15;

  bool get _hasValidAmount =>
      _amount >= _minimumAmount && _amount <= _maximumAmount;

  bool get _canContinue =>
      !_isLoadingWalletBalance &&
      _selectedNetworkId != null &&
      _hasValidPhone &&
      _hasValidAmount;

  _NetworkOption get _selectedNetwork => _networkOptions.firstWhere(
    (_NetworkOption option) => option.id == _selectedNetworkId,
  );

  Future<void> _handleUnauthorized() async {
    await AppSessionService.instance.clear();
    if (!mounted) {
      return;
    }

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (Route<dynamic> route) => false);
  }

  Future<void> _loadWalletBalance() async {
    final String? token = await AppSessionService.instance.getApiToken();
    if (token == null || token.isEmpty) {
      if (!mounted) {
        return;
      }

      setState(() => _isLoadingWalletBalance = false);
      return;
    }

    final DashboardOverviewApiResult result = await DashboardApiService.instance
        .fetchOverview(token: token);
    if (!mounted) {
      return;
    }

    if (result.isUnauthorized) {
      setState(() => _isLoadingWalletBalance = false);
      await _handleUnauthorized();
      return;
    }

    if (result.isSuccess && result.overview != null) {
      setState(() {
        _walletBalance = result.overview!.walletBalance;
        _isLoadingWalletBalance = false;
      });
      return;
    }

    setState(() => _isLoadingWalletBalance = false);
  }

  Future<void> _loadSavedRecipients() async {
    final String? token = await AppSessionService.instance.getApiToken();
    if (token == null || token.isEmpty) {
      return;
    }

    final AirtimeRecipientsApiResult result = await AirtimeApiService.instance
        .fetchRecipients(token: token, limit: 8);
    if (!mounted) {
      return;
    }

    if (result.isUnauthorized) {
      await _handleUnauthorized();
      return;
    }

    if (result.isSuccess) {
      setState(() {
        _recentRecipients = _mapSavedRecipients(result.recipients);
      });
      return;
    }

    if (result.message != null && result.message!.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message!)));
    }
  }

  List<_SavedRecipient> _mapSavedRecipients(
    List<AirtimeSavedRecipient> recipients,
  ) {
    return recipients
        .map(
          (AirtimeSavedRecipient recipient) => _SavedRecipient(
            phoneNumber: recipient.phoneNumber,
            networkId: recipient.networkId,
            usageCount: recipient.usageCount,
          ),
        )
        .toList(growable: false);
  }

  void _onAmountChanged(String value) {
    if (value.isEmpty) {
      setState(() {});
      return;
    }

    final int parsed = int.tryParse(value) ?? 0;
    final int clamped = parsed.clamp(0, _maximumAmount);

    if (clamped.toString() != value) {
      _amountController.value = TextEditingValue(
        text: clamped.toString(),
        selection: TextSelection.collapsed(offset: clamped.toString().length),
      );
    }

    setState(() {});
  }

  void _applyQuickAmount(int amount) {
    final String value =
        amount.clamp(_minimumAmount, _maximumAmount).toString();
    _amountController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    setState(() {});
  }

  void _pickRecipient(_SavedRecipient recipient) {
    _phoneController.value = TextEditingValue(
      text: recipient.phoneNumber,
      selection: TextSelection.collapsed(offset: recipient.phoneNumber.length),
    );
    setState(() {
      _selectedNetworkId = recipient.networkId;
    });
  }

  Future<void> _handleBottomNavigation(
    AppBottomNavDestination destination,
  ) async {
    await handleAppBottomNavigationTap(
      context,
      destination: destination,
      currentDestination: AppBottomNavDestination.airtime,
    );
  }

  Future<void> _openAllRecipientsSheet() async {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color sheetColor = isDark ? _darkSurface : Colors.white;
    final _SavedRecipient?
    selected = await showModalBottomSheet<_SavedRecipient>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return SafeArea(
          top: false,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.76,
            ),
            decoration: BoxDecoration(
              color: sheetColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Column(
                    children: <Widget>[
                      Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color:
                              isDark
                                  ? const Color(0xFF374151)
                                  : const Color(0xFFC7CDDC),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Saved Numbers',
                                  style: TextStyle(
                                    color:
                                        isDark
                                            ? const Color(0xFFF8FAFC)
                                            : const Color(0xFF111827),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tap any recipient to use it for airtime.',
                                  style: TextStyle(
                                    color:
                                        isDark
                                            ? _darkMuted
                                            : const Color(0xFF6B7280),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(
                              Icons.close_rounded,
                              color:
                                  isDark
                                      ? const Color(0xFFE5E7EB)
                                      : const Color(0xFF374151),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    itemCount: _recentRecipients.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (BuildContext context, int index) {
                      final _SavedRecipient recipient =
                          _recentRecipients[index];
                      final _NetworkOption network = _networkOptions.firstWhere(
                        (_NetworkOption option) =>
                            option.id == recipient.networkId,
                      );

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(recipient),
                          borderRadius: BorderRadius.circular(18),
                          child: Ink(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color:
                                  isDark ? _darkPanel : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color:
                                    isDark
                                        ? const Color(0xFF3A4054)
                                        : _softBorder,
                              ),
                            ),
                            child: Row(
                              children: <Widget>[
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: network.brandColor,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    network.shortName,
                                    style: TextStyle(
                                      color: network.foregroundColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        recipient.phoneNumber,
                                        style: TextStyle(
                                          color:
                                              isDark
                                                  ? const Color(0xFFF8FAFC)
                                                  : const Color(0xFF111827),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${network.name} - used ${recipient.usageCount}x',
                                        style: TextStyle(
                                          color:
                                              isDark
                                                  ? _darkMuted
                                                  : const Color(0xFF4B5563),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color:
                                      isDark
                                          ? const Color(0xFFE5E7EB)
                                          : const Color(0xFF374151),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || selected == null) {
      return;
    }

    _pickRecipient(selected);
  }

  Future<void> _openConfirmationSheet() async {
    if (!_canContinue) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select network, phone number, and amount first.'),
        ),
      );
      return;
    }

    final bool? saveRecipient = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _AirtimeConfirmationSheet(
          amountPaid: _formatCurrency(_paidAmount),
          networkName: _selectedNetwork.name,
          phoneNumber: _phoneNumber,
          initialSaveRecipient: _saveRecipient,
        );
      },
    );

    if (!mounted || saveRecipient == null) {
      return;
    }

    setState(() {
      _saveRecipient = saveRecipient;
    });

    await _openPinSheet();
  }

  Future<void> _openPinSheet() async {
    final AppSettings settings = await AppSettingsService.instance.load();
    if (!mounted) {
      return;
    }

    final _AirtimeResult? result = await showModalBottomSheet<_AirtimeResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: !_processing,
      builder: (BuildContext context) {
        return _AirtimePinSheet(
          canUseBiometric: settings.biometricUnlockEnabled,
          onSubmit: (String pin) => _submitPurchase(pin: pin),
          onBiometricSubmit:
              settings.biometricUnlockEnabled
                  ? _submitPurchaseWithBiometric
                  : null,
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    await _openResultSheet(result);
  }

  Future<_PinSheetActionResult> _submitPurchase({
    required String pin,
    bool fromBiometric = false,
  }) async {
    if (!_canContinue || _processing || pin.length != 4) {
      return const _PinSheetActionResult.error(
        'Complete the airtime form and confirm a valid 4-digit PIN.',
      );
    }

    setState(() {
      _processing = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) {
      return const _PinSheetActionResult.error(
        'The airtime page closed before the purchase could finish.',
      );
    }

    final String? token = await AppSessionService.instance.getApiToken();
    if (token == null || token.isEmpty) {
      setState(() {
        _processing = false;
      });
      await _handleUnauthorized();
      return const _PinSheetActionResult.error(
        'Your session has expired. Please sign in again.',
      );
    }

    final AirtimePurchaseApiResult result = await AirtimeApiService.instance
        .purchaseAirtime(
          token: token,
          networkId: _selectedNetwork.id,
          phoneNumber: _phoneNumber,
          amount: _amount,
          saveRecipient: _saveRecipient,
          pin: pin,
        );

    if (!mounted) {
      return const _PinSheetActionResult.error(
        'The airtime page closed before the purchase could finish.',
      );
    }

    if (result.isUnauthorized) {
      setState(() {
        _processing = false;
      });
      await _handleUnauthorized();
      return const _PinSheetActionResult.error(
        'Your session has expired. Please sign in again.',
      );
    }

    if (fromBiometric && result.fieldErrors['pin'] != null) {
      await AppSettingsService.instance.setBiometricUnlockEnabled(false);
      await SecureTransactionPinService.instance.clearPin();
    }

    final bool success = result.isSuccess;
    final _AirtimeResult nextResult = _AirtimeResult(
      isSuccessful: success,
      networkName: _selectedNetwork.name,
      phoneNumber: _phoneNumber,
      amountPaid: _paidAmount,
      reference:
          result.reference.isNotEmpty
              ? result.reference
              : 'AIR-${DateTime.now().millisecondsSinceEpoch}',
      message:
          fromBiometric && result.fieldErrors['pin'] != null
              ? 'Your saved fingerprint payment PIN is out of date. Use your transaction PIN and enable fingerprint again in Settings.'
              : success
              ? (result.message ??
                  'Your airtime purchase was completed successfully.')
              : (result.fieldErrors['pin'] ??
                  result.fieldErrors['amount'] ??
                  result.message ??
                  'Unable to complete this purchase right now.'),
    );

    if (success) {
      final double nextBalance = (_walletBalance - _amount).clamp(
        0,
        double.infinity,
      );
      final List<_SavedRecipient> nextRecipients =
          result.recentRecipients.isNotEmpty
              ? _mapSavedRecipients(result.recentRecipients)
              : _recentRecipients;

      setState(() {
        _walletBalance = nextBalance;
        _recentRecipients = nextRecipients;
      });
    }

    setState(() {
      _processing = false;
    });

    return _PinSheetActionResult.result(nextResult);
  }

  Future<_PinSheetActionResult> _submitPurchaseWithBiometric() async {
    final BiometricAuthResult biometricResult =
        await BiometricAuthService.instance.authenticateQuickLogin();
    if (!biometricResult.isSuccess) {
      return _PinSheetActionResult.error(
        biometricResult.message ?? 'Biometric payment could not start.',
      );
    }

    final String? storedPin =
        await SecureTransactionPinService.instance.readPin();
    if (storedPin == null || storedPin.length != 4) {
      await AppSettingsService.instance.setBiometricUnlockEnabled(false);
      await SecureTransactionPinService.instance.clearPin();
      return const _PinSheetActionResult.error(
        'Fingerprint payment needs to be enabled again in Settings on this device.',
      );
    }

    return _submitPurchase(pin: storedPin, fromBiometric: true);
  }

  Future<void> _openResultSheet(_AirtimeResult result) async {
    final _AirtimeResultAction? action =
        await showModalBottomSheet<_AirtimeResultAction>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (BuildContext context) {
            return _AirtimeResultSheet(
              result: result,
              formatter: _formatCurrency,
            );
          },
        );

    if (!mounted) {
      return;
    }

    if (result.isSuccessful) {
      _resetFormAfterSuccess();
      return;
    }

    if (action == _AirtimeResultAction.retry) {
      await _openConfirmationSheet();
    }
  }

  void _resetFormAfterSuccess() {
    setState(() {
      _selectedNetworkId = null;
      _phoneController.clear();
      _amountController.clear();
      _saveRecipient = true;
    });
  }

  String _formatCurrency(num amount) {
    final String fixed = amount.toStringAsFixed(2);
    final List<String> parts = fixed.split('.');
    final String whole = parts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (Match match) => ',',
    );
    return '\u20A6$whole.${parts.last}';
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor = isDark ? _darkBackground : Colors.white;
    final Color pageSurface = isDark ? _darkSurface : Colors.white;
    final Color inputColor = isDark ? _darkPanel : const Color(0xFFF8FAFC);
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);
    final Color mutedText = isDark ? _darkMuted : const Color(0xFF4B5563);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: titleColor,
          ),
        ),
        title: Text(
          'Buy Airtime',
          style: TextStyle(
            color: titleColor,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Stack(
        children: <Widget>[
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double bottomPadding =
                  112 + MediaQuery.paddingOf(context).bottom;

              return SingleChildScrollView(
                padding: EdgeInsets.only(bottom: bottomPadding),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - bottomPadding + 24,
                  ),
                  child: Container(
                    color: pageSurface,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          const SizedBox(height: 14),
                          LayoutBuilder(
                            builder: (
                              BuildContext context,
                              BoxConstraints constraints,
                            ) {
                              final double itemWidth =
                                  (constraints.maxWidth - 16) / 3;

                              return Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: <Widget>[
                                  SizedBox(
                                    width: itemWidth,
                                    child: _WalletMetricTile(
                                      label: 'Discount',
                                      value: '2%',
                                      isDark: isDark,
                                    ),
                                  ),
                                  SizedBox(
                                    width: itemWidth,
                                    child: _WalletMetricTile(
                                      label: 'Min Amount',
                                      value: '\u20A6100',
                                      isDark: isDark,
                                    ),
                                  ),
                                  SizedBox(
                                    width: itemWidth,
                                    child: _WalletMetricTile(
                                      label: 'Max Amount',
                                      value: '\u20A630,000',
                                      isDark: isDark,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Select Network *',
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _networkOptions.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                  childAspectRatio: 1.0,
                                ),
                            itemBuilder: (BuildContext context, int index) {
                              final _NetworkOption option =
                                  _networkOptions[index];

                              return _NetworkTile(
                                option: option,
                                isDark: isDark,
                                selected: _selectedNetworkId == option.id,
                                onTap: () {
                                  setState(() {
                                    _selectedNetworkId = option.id;
                                  });
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Phone Number *',
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            onChanged: (_) => setState(() {}),
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(15),
                            ],
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: '08012345678',
                              prefixIcon: Icon(
                                Icons.call_rounded,
                                size: 18,
                                color: mutedText,
                              ),
                              filled: true,
                              fillColor: inputColor,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 15,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(
                                  color:
                                      isDark
                                          ? const Color(0xFF3A4054)
                                          : _softBorder,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(
                                  color:
                                      isDark
                                          ? const Color(0xFF3A4054)
                                          : _softBorder,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(
                                  color: _primary,
                                  width: 1.3,
                                ),
                              ),
                            ),
                          ),
                          if (_phoneNumber.isNotEmpty && !_hasValidPhone)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Enter a valid phone number.',
                                style: TextStyle(
                                  color: const Color(0xFFDC2626),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          if (_recentRecipients.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: inputColor,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color:
                                      isDark
                                          ? const Color(0xFF3A4054)
                                          : _softBorder,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Text(
                                          'Recent Numbers',
                                          style: TextStyle(
                                            color: titleColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: _openAllRecipientsSheet,
                                        style: TextButton.styleFrom(
                                          foregroundColor: _primary,
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: const Text('View all'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children:
                                        _recentRecipients
                                            .take(2)
                                            .map(
                                              (
                                                _SavedRecipient recipient,
                                              ) => _RecentRecipientChip(
                                                recipient: recipient,
                                                isDark: isDark,
                                                network: _networkOptions
                                                    .firstWhere(
                                                      (_NetworkOption option) =>
                                                          option.id ==
                                                          recipient.networkId,
                                                    ),
                                                onTap:
                                                    () => _pickRecipient(
                                                      recipient,
                                                    ),
                                              ),
                                            )
                                            .toList(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          Text(
                            'Amount *',
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            onChanged: _onAmountChanged,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(5),
                            ],
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: '100',
                              prefixText: '\u20A6 ',
                              prefixStyle: TextStyle(
                                color: mutedText,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              filled: true,
                              fillColor: inputColor,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 15,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(
                                  color:
                                      isDark
                                          ? const Color(0xFF3A4054)
                                          : _softBorder,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(
                                  color:
                                      isDark
                                          ? const Color(0xFF3A4054)
                                          : _softBorder,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(
                                  color: _primary,
                                  width: 1.3,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _amount > 0 && !_hasValidAmount
                                ? 'Minimum is \u20A6100 and maximum is \u20A630,000.'
                                : 'Minimum \u20A6100 - maximum \u20A630,000.',
                            style: TextStyle(
                              color:
                                  _amount > 0 && !_hasValidAmount
                                      ? const Color(0xFFDC2626)
                                      : mutedText,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          LayoutBuilder(
                            builder: (
                              BuildContext context,
                              BoxConstraints constraints,
                            ) {
                              final double itemWidth =
                                  (constraints.maxWidth - 16) / 3;

                              return Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children:
                                    _quickAmounts
                                        .map(
                                          (int amount) => SizedBox(
                                            width: itemWidth,
                                            child: _QuickAmountButton(
                                              amount: amount,
                                              selected: _amount == amount,
                                              isDark: isDark,
                                              onTap:
                                                  () =>
                                                      _applyQuickAmount(amount),
                                            ),
                                          ),
                                        )
                                        .toList(),
                              );
                            },
                          ),
                          if (_paidAmount > 0) ...<Widget>[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color:
                                    isDark
                                        ? _primary.withValues(alpha: 0.12)
                                        : _softTint,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color:
                                      isDark
                                          ? _primary.withValues(alpha: 0.16)
                                          : _softBorder,
                                ),
                              ),
                              child: Column(
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Text(
                                          'Amount to Pay',
                                          style: TextStyle(
                                            color:
                                                isDark
                                                    ? const Color(0xFFF3F4F6)
                                                    : const Color(0xFF374151),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        _formatCurrency(_paidAmount),
                                        style: TextStyle(
                                          color:
                                              isDark
                                                  ? const Color(0xFFF8FAFC)
                                                  : _primaryDark,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'You save ${_formatCurrency(_savedAmount)} (2% discount)',
                                      style: TextStyle(
                                        color:
                                            isDark
                                                ? const Color(0xFFD1D5DB)
                                                : const Color(0xFF7FA0F5),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed:
                                _canContinue ? _openConfirmationSheet : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: _primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(54),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            icon: const Icon(Icons.call_rounded, size: 18),
                            label: const Text('Buy Airtime Now'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavigation(
        isDark: isDark,
        selectedDestination: AppBottomNavDestination.airtime,
        onSelect: _handleBottomNavigation,
      ),
    );
  }
}

class _WalletMetricTile extends StatelessWidget {
  const _WalletMetricTile({
    required this.label,
    required this.value,
    required this.isDark,
  });

  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color mutedText = isDark ? _darkMuted : const Color(0xFF4B5563);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: isDark ? _darkPanel : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF3A4054) : _softBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: titleColor,
              fontSize: 12.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: mutedText,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _NetworkTile extends StatelessWidget {
  const _NetworkTile({
    required this.option,
    required this.isDark,
    required this.selected,
    required this.onTap,
  });

  final _NetworkOption option;
  final bool isDark;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient:
                selected
                    ? const LinearGradient(
                      colors: <Color>[_primary, _primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                    : null,
            color:
                selected
                    ? null
                    : (isDark ? _darkPanel : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color:
                  selected
                      ? Colors.transparent
                      : (isDark ? const Color(0xFF3A4054) : _softBorder),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              NetworkLogoBadge(
                assetPath: option.assetPath,
                fallbackLabel: option.shortName,
                size: 46,
                borderRadius: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentRecipientChip extends StatelessWidget {
  const _RecentRecipientChip({
    required this.recipient,
    required this.network,
    required this.isDark,
    required this.onTap,
  });

  final _SavedRecipient recipient;
  final _NetworkOption network;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? _darkPanel : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isDark ? const Color(0xFF3A4054) : _softBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: network.brandColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                recipient.phoneNumber,
                style: TextStyle(
                  color:
                      isDark
                          ? const Color(0xFFF8FAFC)
                          : const Color(0xFF252A42),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAmountButton extends StatelessWidget {
  const _QuickAmountButton({
    required this.amount,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final int amount;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        elevation: 0,
        backgroundColor:
            selected ? _primary : (isDark ? _darkPanel : Colors.white),
        foregroundColor:
            selected
                ? Colors.white
                : (isDark ? const Color(0xFFE5E7EB) : const Color(0xFF374151)),
        side: BorderSide(
          color:
              selected
                  ? Colors.transparent
                  : (isDark ? const Color(0xFF3A4054) : _softBorder),
        ),
        padding: const EdgeInsets.symmetric(vertical: 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
      ),
      child: Text('\u20A6${amount.toString()}'),
    );
  }
}

class _AirtimeConfirmationSheet extends StatefulWidget {
  const _AirtimeConfirmationSheet({
    required this.amountPaid,
    required this.networkName,
    required this.phoneNumber,
    required this.initialSaveRecipient,
  });

  final String amountPaid;
  final String networkName;
  final String phoneNumber;
  final bool initialSaveRecipient;

  @override
  State<_AirtimeConfirmationSheet> createState() =>
      _AirtimeConfirmationSheetState();
}

class _AirtimeConfirmationSheetState extends State<_AirtimeConfirmationSheet> {
  late bool _saveRecipient = widget.initialSaveRecipient;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? _darkSurface : Colors.white;
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);
    final Color mutedText = isDark ? _darkMuted : const Color(0xFF4B5563);

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? const Color(0xFF374151)
                            : const Color(0xFFC7CDDC),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Confirm Airtime Purchase',
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: mutedText),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Review this airtime payment before entering your PIN.',
                style: TextStyle(
                  color: mutedText,
                  fontSize: 11.2,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                widget.amountPaid,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:
                      isDark
                          ? const Color(0xFFF8FAFC)
                          : const Color(0xFF0F172A),
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _CompactSummaryTile(
                      label: 'Network',
                      value: widget.networkName,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _CompactSummaryTile(
                      label: 'Number',
                      value: widget.phoneNumber,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.fromLTRB(11, 8, 11, 8),
                decoration: BoxDecoration(
                  color: isDark ? _darkPanel : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? const Color(0xFF3A4054) : _softBorder,
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Save number for later',
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 10.8,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Store this recipient after a successful purchase.',
                            style: TextStyle(
                              color: mutedText,
                              fontSize: 9.8,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: _saveRecipient,
                      onChanged: (bool value) {
                        setState(() {
                          _saveRecipient = value;
                        });
                      },
                      activeColor: Colors.white,
                      activeTrackColor: _primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(_saveRecipient),
                style: FilledButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Continue to PIN'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AirtimePinSheet extends StatefulWidget {
  const _AirtimePinSheet({
    required this.onSubmit,
    required this.canUseBiometric,
    this.onBiometricSubmit,
  });

  final Future<_PinSheetActionResult> Function(String pin) onSubmit;
  final bool canUseBiometric;
  final Future<_PinSheetActionResult> Function()? onBiometricSubmit;

  @override
  State<_AirtimePinSheet> createState() => _AirtimePinSheetState();
}

class _AirtimePinSheetState extends State<_AirtimePinSheet> {
  String _pin = '';
  bool _processing = false;
  String? _errorText;

  void _appendDigit(String digit) {
    if (_processing || _pin.length >= 4) {
      return;
    }

    setState(() {
      _errorText = null;
      _pin = '$_pin$digit';
    });

    if (_pin.length == 4) {
      Future<void>.delayed(const Duration(milliseconds: 120), _submitPin);
    }
  }

  void _removeDigit() {
    if (_processing || _pin.isEmpty) {
      return;
    }

    setState(() {
      _errorText = null;
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  Future<void> _submitPin() async {
    if (_processing || _pin.length != 4) {
      return;
    }

    final NavigatorState rootNavigator = Navigator.of(
      context,
      rootNavigator: true,
    );
    late final _PinSheetActionResult submitResult;

    setState(() {
      _processing = true;
      _errorText = null;
    });

    showPtsDataLoaderDialog<void>(
      context,
      text: 'Processing payment...',
      color: _primary,
    );

    try {
      submitResult = await widget.onSubmit(_pin);
    } catch (_) {
      submitResult = const _PinSheetActionResult.error(
        'We could not complete this payment right now.',
      );
    } finally {
      if (rootNavigator.canPop()) {
        rootNavigator.pop();
      }
    }

    if (!mounted) {
      return;
    }

    final String? errorMessage = submitResult.errorMessage;
    if (errorMessage != null) {
      setState(() {
        _processing = false;
        _pin = '';
        _errorText = errorMessage;
      });
      return;
    }

    if (submitResult.result != null) {
      Navigator.of(context).pop(submitResult.result);
    }
  }

  Future<void> _submitBiometric() async {
    if (_processing || widget.onBiometricSubmit == null) {
      return;
    }

    final NavigatorState rootNavigator = Navigator.of(
      context,
      rootNavigator: true,
    );
    late final _PinSheetActionResult submitResult;

    setState(() {
      _processing = true;
      _errorText = null;
    });

    showPtsDataLoaderDialog<void>(
      context,
      text: 'Confirming fingerprint...',
      color: _primary,
    );

    try {
      submitResult = await widget.onBiometricSubmit!.call();
    } catch (_) {
      submitResult = const _PinSheetActionResult.error(
        'We could not complete biometric payment right now.',
      );
    } finally {
      if (rootNavigator.canPop()) {
        rootNavigator.pop();
      }
    }

    if (!mounted) {
      return;
    }

    final String? errorMessage = submitResult.errorMessage;
    if (errorMessage != null) {
      setState(() {
        _processing = false;
        _pin = '';
        _errorText = errorMessage;
      });
      return;
    }

    if (submitResult.result != null) {
      Navigator.of(context).pop(submitResult.result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? _darkSurface : Colors.white;
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);
    final Color mutedText = isDark ? _darkMuted : const Color(0xFF4B5563);
    final double screenHeight = MediaQuery.sizeOf(context).height;
    final double maxHeight = screenHeight * 0.72;
    final bool compact = screenHeight < 700;

    return PopScope(
      canPop: !_processing,
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      compact ? 10 : 12,
                      16,
                      compact ? 10 : 12,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Center(
                          child: Container(
                            width: 44,
                            height: 5,
                            decoration: BoxDecoration(
                              color:
                                  isDark
                                      ? const Color(0xFF374151)
                                      : const Color(0xFFC7CDDC),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                'Enter Payment PIN',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: titleColor,
                                  fontSize: compact ? 14.4 : 15.2,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed:
                                  _processing
                                      ? null
                                      : () => Navigator.of(context).pop(),
                              icon: Icon(Icons.close_rounded, color: mutedText),
                            ),
                          ],
                        ),
                        SizedBox(height: compact ? 12 : 14),
                        _PinIndicatorBoxes(
                          length: _pin.length,
                          isDark: isDark,
                          boxSize: compact ? 44 : 52,
                        ),
                        SizedBox(height: compact ? 10 : 12),
                        TextButton(
                          onPressed:
                              _processing
                                  ? null
                                  : () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Payment PIN recovery is not connected yet.',
                                        ),
                                      ),
                                    );
                                  },
                          style: TextButton.styleFrom(
                            foregroundColor: mutedText,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            _processing
                                ? 'Processing payment...'
                                : 'Forgot Payment PIN?',
                            style: TextStyle(
                              fontSize: compact ? 10.5 : 10.8,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (_errorText != null) ...<Widget>[
                          const SizedBox(height: 8),
                          Text(
                            _errorText!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFDC2626),
                              fontSize: 11.2,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        if (widget.canUseBiometric &&
                            widget.onBiometricSubmit != null) ...<Widget>[
                          SizedBox(height: compact ? 10 : 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _processing ? null : _submitBiometric,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(42),
                                side: BorderSide(
                                  color:
                                      isDark
                                          ? const Color(0xFF374151)
                                          : const Color(0xFFE5E7EB),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: Icon(
                                Icons.fingerprint_rounded,
                                color:
                                    isDark ? const Color(0xFFB89CFF) : _primary,
                                size: 18,
                              ),
                              label: Text(
                                'Use Fingerprint Instead',
                                style: TextStyle(
                                  color: titleColor,
                                  fontSize: compact ? 11.2 : 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(
                      10,
                      compact ? 8 : 10,
                      10,
                      compact ? 8 : 10,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? const Color(0xFF171925)
                              : const Color(0xFFF8FAFC),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const Icon(
                              Icons.shield_rounded,
                              color: Color(0xFF16A34A),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'PTS DATA Secure Numeric Keypad',
                              style: TextStyle(
                                color: mutedText,
                                fontSize: compact ? 10.4 : 10.7,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: compact ? 8 : 10),
                        _CustomPinKeyboard(
                          isDark: isDark,
                          compact: compact,
                          onDigitTap: _processing ? null : _appendDigit,
                          onBackspace: _processing ? null : _removeDigit,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactSummaryTile extends StatelessWidget {
  const _CompactSummaryTile({
    required this.label,
    required this.value,
    required this.isDark,
  });

  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);
    final Color mutedText = isDark ? _darkMuted : const Color(0xFF4B5563);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: BoxDecoration(
        color: isDark ? _darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              color: mutedText,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: titleColor,
              fontSize: 11.2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.isDark,
  });

  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isDark ? _darkMuted : const Color(0xFF4B5563),
              fontSize: 10.8,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827),
            fontSize: 11.2,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PinIndicatorBoxes extends StatelessWidget {
  const _PinIndicatorBoxes({
    required this.length,
    required this.isDark,
    this.boxSize = 56,
  });

  final int length;
  final bool isDark;
  final double boxSize;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double resolvedSize =
            (((constraints.maxWidth - 30) / 4).clamp(42.0, boxSize)).toDouble();
        final double spacing = resolvedSize <= 46 ? 6 : 10;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List<Widget>.generate(4, (int index) {
            final bool filled = index < length;
            final bool active = index == length && length < 4;

            return Padding(
              padding: EdgeInsets.only(right: index == 3 ? 0 : spacing),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: resolvedSize,
                height: resolvedSize,
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? const Color(0xFF202331)
                          : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        filled || active
                            ? _primary.withValues(alpha: filled ? 0.48 : 0.24)
                            : (isDark
                                ? const Color(0xFF3A4054)
                                : const Color(0xFFE5E7EB)),
                    width: 1.25,
                  ),
                ),
                child: Center(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 120),
                    opacity: filled ? 1 : 0,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: _primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _CustomPinKeyboard extends StatelessWidget {
  const _CustomPinKeyboard({
    required this.isDark,
    required this.compact,
    required this.onDigitTap,
    required this.onBackspace,
  });

  final bool isDark;
  final bool compact;
  final ValueChanged<String>? onDigitTap;
  final VoidCallback? onBackspace;

  @override
  Widget build(BuildContext context) {
    final double spacing = compact ? 6 : 8;
    final double buttonHeight = compact ? 42 : 48;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _PinKeyButton(
                label: '1',
                isDark: isDark,
                height: buttonHeight,
                onTap: onDigitTap == null ? null : () => onDigitTap!('1'),
              ),
            ),
            SizedBox(width: spacing),
            Expanded(
              child: _PinKeyButton(
                label: '2',
                isDark: isDark,
                height: buttonHeight,
                onTap: onDigitTap == null ? null : () => onDigitTap!('2'),
              ),
            ),
            SizedBox(width: spacing),
            Expanded(
              child: _PinKeyButton(
                label: '3',
                isDark: isDark,
                height: buttonHeight,
                onTap: onDigitTap == null ? null : () => onDigitTap!('3'),
              ),
            ),
          ],
        ),
        SizedBox(height: spacing),
        Row(
          children: <Widget>[
            Expanded(
              child: _PinKeyButton(
                label: '4',
                isDark: isDark,
                height: buttonHeight,
                onTap: onDigitTap == null ? null : () => onDigitTap!('4'),
              ),
            ),
            SizedBox(width: spacing),
            Expanded(
              child: _PinKeyButton(
                label: '5',
                isDark: isDark,
                height: buttonHeight,
                onTap: onDigitTap == null ? null : () => onDigitTap!('5'),
              ),
            ),
            SizedBox(width: spacing),
            Expanded(
              child: _PinKeyButton(
                label: '6',
                isDark: isDark,
                height: buttonHeight,
                onTap: onDigitTap == null ? null : () => onDigitTap!('6'),
              ),
            ),
          ],
        ),
        SizedBox(height: spacing),
        Row(
          children: <Widget>[
            Expanded(
              child: _PinKeyButton(
                label: '7',
                isDark: isDark,
                height: buttonHeight,
                onTap: onDigitTap == null ? null : () => onDigitTap!('7'),
              ),
            ),
            SizedBox(width: spacing),
            Expanded(
              child: _PinKeyButton(
                label: '8',
                isDark: isDark,
                height: buttonHeight,
                onTap: onDigitTap == null ? null : () => onDigitTap!('8'),
              ),
            ),
            SizedBox(width: spacing),
            Expanded(
              child: _PinKeyButton(
                label: '9',
                isDark: isDark,
                height: buttonHeight,
                onTap: onDigitTap == null ? null : () => onDigitTap!('9'),
              ),
            ),
          ],
        ),
        SizedBox(height: spacing),
        Row(
          children: <Widget>[
            Expanded(
              child: _PinKeyButton(
                isDark: isDark,
                height: buttonHeight,
                placeholder: true,
                onTap: null,
              ),
            ),
            SizedBox(width: spacing),
            Expanded(
              child: _PinKeyButton(
                label: '0',
                isDark: isDark,
                height: buttonHeight,
                onTap: onDigitTap == null ? null : () => onDigitTap!('0'),
              ),
            ),
            SizedBox(width: spacing),
            Expanded(
              child: _PinKeyButton(
                icon: Icons.backspace_outlined,
                isDark: isDark,
                height: buttonHeight,
                onTap: onBackspace,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PinKeyButton extends StatelessWidget {
  const _PinKeyButton({
    this.label,
    this.icon,
    required this.isDark,
    required this.height,
    required this.onTap,
    this.placeholder = false,
  });

  final String? label;
  final IconData? icon;
  final bool isDark;
  final double height;
  final VoidCallback? onTap;
  final bool placeholder;

  @override
  Widget build(BuildContext context) {
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);

    if (placeholder) {
      return SizedBox(height: height);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Ink(
          height: height,
          decoration: BoxDecoration(
            color: isDark ? _darkPanel : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isDark ? const Color(0xFF3A4054) : const Color(0xFFE5E7EB),
            ),
            boxShadow:
                isDark
                    ? null
                    : <BoxShadow>[
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
          ),
          child: Center(
            child:
                icon != null
                    ? Icon(icon, color: titleColor, size: 18)
                    : Text(
                      label ?? '',
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
          ),
        ),
      ),
    );
  }
}

enum _AirtimeResultAction { close, retry }

class _PinSheetActionResult {
  const _PinSheetActionResult._({this.result, this.errorMessage});

  const _PinSheetActionResult.result(_AirtimeResult result)
    : this._(result: result);

  const _PinSheetActionResult.error(String errorMessage)
    : this._(errorMessage: errorMessage);

  final _AirtimeResult? result;
  final String? errorMessage;
}

class _AirtimeResultSheet extends StatelessWidget {
  const _AirtimeResultSheet({required this.result, required this.formatter});

  final _AirtimeResult result;
  final String Function(num amount) formatter;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDark ? _darkSurface : Colors.white;
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);
    final Color mutedText = isDark ? _darkMuted : const Color(0xFF4B5563);
    final Color statusColor =
        result.isSuccessful ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final Color accentTint =
        result.isSuccessful
            ? const Color(0xFF16A34A).withValues(alpha: isDark ? 0.16 : 0.10)
            : const Color(0xFFDC2626).withValues(alpha: isDark ? 0.18 : 0.10);
    final IconData statusIcon =
        result.isSuccessful ? Icons.check_rounded : Icons.close_rounded;
    final double sheetHeight = MediaQuery.sizeOf(context).height * 0.84;
    final Widget actionSection =
        result.isSuccessful
            ? FilledButton.icon(
              onPressed:
                  () => Navigator.of(context).pop(_AirtimeResultAction.close),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 12.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              icon: const Icon(Icons.home_rounded, size: 16),
              label: const Text('Done'),
            )
            : Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        () => Navigator.of(
                          context,
                        ).pop(_AirtimeResultAction.close),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: titleColor,
                      side: BorderSide(
                        color:
                            isDark
                                ? const Color(0xFF374151)
                                : const Color(0xFFC7CDDC),
                      ),
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed:
                        () => Navigator.of(
                          context,
                        ).pop(_AirtimeResultAction.retry),
                    style: FilledButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12.1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Try Again'),
                  ),
                ),
              ],
            );

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: sheetHeight),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.16),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? const Color(0xFF374151)
                            : const Color(0xFFC7CDDC),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accentTint,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        result.isSuccessful ? 'Successful' : 'Failed',
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed:
                          () => Navigator.of(
                            context,
                          ).pop(_AirtimeResultAction.close),
                      visualDensity: VisualDensity.compact,
                      iconSize: 20,
                      icon: Icon(Icons.close_rounded, color: mutedText),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    Container(
                      width: 102,
                      height: 102,
                      decoration: BoxDecoration(
                        color: accentTint,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.26),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(statusIcon, color: Colors.white, size: 28),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  result.isSuccessful
                      ? 'Payment Successful!'
                      : 'Payment Failed',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 20.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  result.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: mutedText,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  decoration: BoxDecoration(
                    color: isDark ? _darkPanel : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color:
                          isDark
                              ? const Color(0xFF3A4054)
                              : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        'Transaction details',
                        style: TextStyle(
                          color: titleColor,
                          fontSize: 11.8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SummaryRow(
                        label: 'Network',
                        value: result.networkName,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 8),
                      _SummaryRow(
                        label: 'Phone Number',
                        value: result.phoneNumber,
                        isDark: isDark,
                      ),
                      if (result.isSuccessful) ...<Widget>[
                        const SizedBox(height: 8),
                        _SummaryRow(
                          label: 'Reference',
                          value: result.reference,
                          isDark: isDark,
                        ),
                      ],
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color:
                              result.isSuccessful
                                  ? const Color(
                                    0xFF16A34A,
                                  ).withValues(alpha: isDark ? 0.16 : 0.10)
                                  : const Color(
                                    0xFFDC2626,
                                  ).withValues(alpha: isDark ? 0.18 : 0.10),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                result.isSuccessful ? 'Amount Paid' : 'Amount',
                                style: TextStyle(
                                  color: mutedText,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              formatter(result.amountPaid),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 16.8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                actionSection,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NetworkOption {
  const _NetworkOption({
    required this.id,
    required this.name,
    required this.shortName,
    required this.assetPath,
    required this.brandColor,
    required this.foregroundColor,
  });

  final String id;
  final String name;
  final String shortName;
  final String assetPath;
  final Color brandColor;
  final Color foregroundColor;
}

class _SavedRecipient {
  const _SavedRecipient({
    required this.phoneNumber,
    required this.networkId,
    required this.usageCount,
  });

  final String phoneNumber;
  final String networkId;
  final int usageCount;
}

class _AirtimeResult {
  const _AirtimeResult({
    required this.isSuccessful,
    required this.networkName,
    required this.phoneNumber,
    required this.amountPaid,
    required this.reference,
    required this.message,
  });

  final bool isSuccessful;
  final String networkName;
  final String phoneNumber;
  final double amountPaid;
  final String reference;
  final String message;
}

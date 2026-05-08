import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/auth/app_session_service.dart';
import '../../../../core/auth/biometric_auth_service.dart';
import '../../../../core/auth/secure_transaction_pin_service.dart';
import '../../../../core/settings/app_settings_service.dart';
import '../../../bills/data/bill_payment_api_service.dart';
import '../../../navigation/presentation/widgets/app_bottom_navigation.dart';
import '../../../shared/presentation/widgets/pts_data_loader_overlay.dart';

const Color _primary = Color(0xFFB89CFF);
const Color _softTint = Color(0xFFF3F4F6);
const Color _softBorder = Color(0xFFE5E7EB);
const Color _darkBackground = Color(0xFF171925);
const Color _darkSurface = Color(0xFF22263A);
const Color _darkPanel = Color(0xFF252A42);
const Color _darkMuted = Color(0xFFC7CDDC);

class BillPaymentPage extends StatefulWidget {
  const BillPaymentPage({super.key});

  @override
  State<BillPaymentPage> createState() => _BillPaymentPageState();
}

class _BillPaymentPageState extends State<BillPaymentPage> {
  static const List<int> _quickAmounts = <int>[
    1000,
    2000,
    5000,
    10000,
    20000,
    50000,
  ];
  static const List<_BillProvider> _fallbackProviders = <_BillProvider>[
    _BillProvider(
      id: '1',
      serviceId: '1',
      name: 'Ikeja Electric',
      meterTypes: <String>['prepaid', 'postpaid'],
      accent: Color(0xFFB89CFF),
    ),
    _BillProvider(
      id: '2',
      serviceId: '2',
      name: 'Eko Electric',
      meterTypes: <String>['prepaid', 'postpaid'],
      accent: Color(0xFF16A34A),
    ),
    _BillProvider(
      id: '3',
      serviceId: '3',
      name: 'Abuja Electric',
      meterTypes: <String>['prepaid', 'postpaid'],
      accent: Color(0xFFF97316),
    ),
    _BillProvider(
      id: '6',
      serviceId: '6',
      name: 'Port Harcourt Electric',
      meterTypes: <String>['prepaid', 'postpaid'],
      accent: Color(0xFF7FA0F5),
    ),
    _BillProvider(
      id: '4',
      serviceId: '4',
      name: 'Kano Electric',
      meterTypes: <String>['prepaid', 'postpaid'],
      accent: Color(0xFF7C3AED),
    ),
    _BillProvider(
      id: '5',
      serviceId: '5',
      name: 'Enugu Electric',
      meterTypes: <String>['prepaid', 'postpaid'],
      accent: Color(0xFFEC4899),
    ),
    _BillProvider(
      id: '7',
      serviceId: '7',
      name: 'Ibadan Electric',
      meterTypes: <String>['prepaid', 'postpaid'],
      accent: Color(0xFF0F766E),
    ),
    _BillProvider(
      id: '8',
      serviceId: '8',
      name: 'Kaduna Electric',
      meterTypes: <String>['prepaid', 'postpaid'],
      accent: Color(0xFFB45309),
    ),
    _BillProvider(
      id: '9',
      serviceId: '9',
      name: 'Jos Electric',
      meterTypes: <String>['prepaid', 'postpaid'],
      accent: Color(0xFFDC2626),
    ),
    _BillProvider(
      id: '10',
      serviceId: '10',
      name: 'Benin Electric',
      meterTypes: <String>['prepaid', 'postpaid'],
      accent: Color(0xFF4F46E5),
    ),
    _BillProvider(
      id: '11',
      serviceId: '11',
      name: 'Yola Electric',
      meterTypes: <String>['prepaid', 'postpaid'],
      accent: Color(0xFF059669),
    ),
  ];

  final TextEditingController _meterController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  late List<_BillHistoryItem> _history;
  late List<_BillProvider> _providers;

  double _serviceCharge = 100;
  double _minimumAmount = 100;
  double _maximumAmount = 500000;

  String? _selectedProviderId;
  String _meterType = 'prepaid';
  String? _verifiedCustomerName;
  String? _verifiedAddress;
  bool _validating = false;
  bool _processing = false;
  bool _isLoadingCatalog = true;

  @override
  void initState() {
    super.initState();
    _providers = List<_BillProvider>.from(_fallbackProviders);
    _history = <_BillHistoryItem>[];
    _loadCatalog();
  }

  @override
  void dispose() {
    _meterController.dispose();
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  _BillProvider? get _selectedProvider {
    final String? providerId = _selectedProviderId;
    if (providerId == null) {
      return null;
    }

    for (final _BillProvider provider in _providers) {
      if (provider.id == providerId) {
        return provider;
      }
    }

    return null;
  }

  double get _amount => double.tryParse(_amountController.text.trim()) ?? 0;

  bool get _canValidate {
    return !_isLoadingCatalog &&
        _selectedProvider != null &&
        _meterController.text.trim().length >= 8 &&
        _phoneController.text.trim().length >= 10 &&
        _amount >= _minimumAmount &&
        _amount <= _maximumAmount;
  }

  Future<void> _handleBottomNavigation(
    AppBottomNavDestination destination,
  ) async {
    await handleUtilityBottomNavigationTap(context, destination: destination);
  }

  Future<void> _handleUnauthorized() async {
    await AppSessionService.instance.clear();
    if (!mounted) {
      return;
    }

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (Route<dynamic> route) => false);
  }

  Future<void> _loadCatalog() async {
    final String? token = await AppSessionService.instance.getApiToken();
    if (token == null || token.isEmpty) {
      if (mounted) {
        setState(() => _isLoadingCatalog = false);
      }
      return;
    }

    final BillCatalogApiResult result = await BillPaymentApiService.instance
        .fetchCatalog(token: token, limit: 20);
    if (!mounted) {
      return;
    }

    if (result.isUnauthorized) {
      setState(() => _isLoadingCatalog = false);
      await _handleUnauthorized();
      return;
    }

    if (result.isSuccess) {
      final List<_BillProvider> nextProviders = _mapProviders(result.providers);
      setState(() {
        _providers =
            nextProviders.isEmpty
                ? List<_BillProvider>.from(_fallbackProviders)
                : nextProviders;
        _history = _mapHistory(result.history);
        _serviceCharge = result.serviceCharge;
        _minimumAmount = result.minAmount;
        _maximumAmount = result.maxAmount;
        _isLoadingCatalog = false;
      });
      return;
    }

    setState(() => _isLoadingCatalog = false);
    if (result.message != null && result.message!.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message!)));
    }
  }

  Future<void> _refreshBillCatalog() async {
    await _loadCatalog();
  }

  void _applyQuickAmount(int amount) {
    final String value = amount.toString();
    _amountController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    setState(() {
      _verifiedCustomerName = null;
      _verifiedAddress = null;
    });
  }

  List<_BillProvider> _mapProviders(List<BillApiProvider> providers) {
    return providers
        .map(
          (BillApiProvider provider) => _BillProvider(
            id: provider.id.isNotEmpty ? provider.id : provider.serviceId,
            serviceId:
                provider.serviceId.isNotEmpty
                    ? provider.serviceId
                    : provider.id,
            name: provider.name,
            meterTypes:
                provider.meterTypes.isEmpty
                    ? const <String>['prepaid', 'postpaid']
                    : provider.meterTypes,
            accent: _providerAccent(provider.serviceId, provider.name),
          ),
        )
        .toList(growable: false);
  }

  List<_BillHistoryItem> _mapHistory(List<BillApiHistoryItem> history) {
    return history.map(_mapHistoryItem).toList(growable: false);
  }

  _BillHistoryItem _mapHistoryItem(BillApiHistoryItem item) {
    return _BillHistoryItem(
      provider: item.provider,
      meterNumber: item.meterNumber,
      amount: item.amount,
      status: _normalizeDisplayStatus(item.status),
      meterType: item.meterType,
      createdAt: DateTime.tryParse(item.createdAt) ?? DateTime.now(),
    );
  }

  Color _providerAccent(String serviceId, String name) {
    final String normalizedServiceId = serviceId.toLowerCase();
    final String normalizedName = name.toLowerCase();
    if (normalizedServiceId == '1' ||
        normalizedName.contains('ikeja') ||
        normalizedName.contains('ikedc')) {
      return const Color(0xFFB89CFF);
    }
    if (normalizedServiceId == '2' ||
        normalizedName.contains('eko') ||
        normalizedName.contains('ekedc')) {
      return const Color(0xFF16A34A);
    }
    if (normalizedServiceId == '3' ||
        normalizedName.contains('abuja') ||
        normalizedName.contains('aedc')) {
      return const Color(0xFFF97316);
    }
    if (normalizedServiceId == '6' ||
        normalizedName.contains('port harcourt') ||
        normalizedName.contains('phed')) {
      return const Color(0xFF7FA0F5);
    }
    if (normalizedServiceId == '4' || normalizedName.contains('kano')) {
      return const Color(0xFF7C3AED);
    }
    if (normalizedServiceId == '5' || normalizedName.contains('enugu')) {
      return const Color(0xFFEC4899);
    }
    if (normalizedServiceId == '7' || normalizedName.contains('ibadan')) {
      return const Color(0xFF0F766E);
    }
    if (normalizedServiceId == '8' || normalizedName.contains('kaduna')) {
      return const Color(0xFFB45309);
    }
    if (normalizedServiceId == '9' || normalizedName.contains('jos')) {
      return const Color(0xFFDC2626);
    }
    if (normalizedServiceId == '10' || normalizedName.contains('benin')) {
      return const Color(0xFF4F46E5);
    }
    if (normalizedServiceId == '11' || normalizedName.contains('yola')) {
      return const Color(0xFF059669);
    }

    return _primary;
  }

  String _normalizeDisplayStatus(String status) {
    switch (status.toLowerCase()) {
      case 'successful':
      case 'success':
      case 'completed':
        return 'Successful';
      case 'processing':
      case 'pending':
      case 'queued':
        return 'Processing';
      default:
        return 'Failed';
    }
  }

  Future<void> _validateMeter() async {
    if (!_canValidate || _validating) {
      return;
    }

    setState(() {
      _validating = true;
      _verifiedCustomerName = null;
      _verifiedAddress = null;
    });

    final NavigatorState rootNavigator = Navigator.of(
      context,
      rootNavigator: true,
    );
    showPtsDataLoaderDialog<void>(
      context,
      text: 'Validating meter...',
      color: _primary,
    );

    final String? token = await AppSessionService.instance.getApiToken();
    BillValidateMeterApiResult result;
    try {
      if (token == null || token.isEmpty) {
        result = const BillValidateMeterApiResult.unauthorized(
          'Your session has expired. Please sign in again.',
        );
      } else {
        result = await BillPaymentApiService.instance.validateMeter(
          token: token,
          serviceId: _selectedProvider!.serviceId,
          meterNumber: _meterController.text.trim(),
          meterType: _meterType,
        );
      }
    } finally {
      rootNavigator.pop();
    }

    if (!mounted) {
      return;
    }

    if (result.isUnauthorized) {
      setState(() => _validating = false);
      await _handleUnauthorized();
      return;
    }

    if (result.isSuccess) {
      setState(() {
        _validating = false;
        _verifiedCustomerName = result.customerName;
        _verifiedAddress = result.address;
      });
      return;
    }

    setState(() => _validating = false);
    final String message =
        result.fieldErrors['meter_number'] ??
        result.fieldErrors['service_id'] ??
        result.message ??
        'We could not validate this meter right now.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openConfirmationSheet() async {
    final _BillProvider? selectedProvider = _selectedProvider;
    if (_verifiedCustomerName == null ||
        _verifiedAddress == null ||
        selectedProvider == null) {
      return;
    }

    final bool? shouldContinue = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _BillConfirmationSheet(
          providerName: selectedProvider.name,
          meterType: _meterType == 'prepaid' ? 'Prepaid' : 'Postpaid',
          meterNumber: _meterController.text.trim(),
          customerName: _verifiedCustomerName!,
          address: _verifiedAddress!,
          totalAmount: _formatCurrency(_amount + _serviceCharge),
        );
      },
    );

    if (!mounted || shouldContinue != true) {
      return;
    }

    await _openPinSheet();
  }

  Future<void> _openPinSheet() async {
    final AppSettings settings = await AppSettingsService.instance.load();
    if (!mounted) {
      return;
    }

    final _BillResult? result = await showModalBottomSheet<_BillResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: !_processing,
      builder: (BuildContext context) {
        return _BillPinSheet(
          canUseBiometric: settings.biometricUnlockEnabled,
          onSubmit: (String pin) => _submitPayment(pin),
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    await _openResultSheet(result);
  }

  Future<_BillResult> _submitPayment(String pin) async {
    final _BillProvider? selectedProvider = _selectedProvider;
    if (_processing ||
        pin.length != 4 ||
        selectedProvider == null ||
        _verifiedCustomerName == null ||
        _verifiedAddress == null) {
      throw StateError('Bill payment is invalid or already processing.');
    }

    setState(() {
      _processing = true;
    });

    final String? token = await AppSessionService.instance.getApiToken();
    if (token == null || token.isEmpty) {
      setState(() {
        _processing = false;
      });
      await _handleUnauthorized();
      return _BillResult(
        status: BillPurchaseStatus.failed,
        providerName: selectedProvider.name,
        meterNumber: _meterController.text.trim(),
        customerName: _verifiedCustomerName!,
        address: _verifiedAddress!,
        meterType: _meterType == 'prepaid' ? 'Prepaid' : 'Postpaid',
        amount: _amount + _serviceCharge,
        reference: '',
        message: 'Your session has expired. Please sign in again.',
      );
    }

    final BillPurchaseApiResult result = await BillPaymentApiService.instance
        .purchase(
          token: token,
          serviceId: selectedProvider.serviceId,
          meterNumber: _meterController.text.trim(),
          meterType: _meterType,
          amount: _amount,
          phoneNumber: _phoneController.text.trim(),
          pin: pin,
        );

    if (!mounted) {
      throw StateError('Widget was disposed during bill payment.');
    }

    if (result.isUnauthorized) {
      setState(() {
        _processing = false;
      });
      await _handleUnauthorized();
      return _BillResult(
        status: BillPurchaseStatus.failed,
        providerName: selectedProvider.name,
        meterNumber: _meterController.text.trim(),
        customerName: _verifiedCustomerName!,
        address: _verifiedAddress!,
        meterType: _meterType == 'prepaid' ? 'Prepaid' : 'Postpaid',
        amount: _amount + _serviceCharge,
        reference: '',
        message: 'Your session has expired. Please sign in again.',
      );
    }

    final String meterTypeLabel =
        _meterType == 'prepaid' ? 'Prepaid' : 'Postpaid';
    if (result.isSuccess && result.historyItem != null) {
      final _BillHistoryItem nextItem = _mapHistoryItem(result.historyItem!);
      setState(() {
        _processing = false;
        _history = <_BillHistoryItem>[nextItem, ..._history];
      });
    } else {
      setState(() {
        _processing = false;
      });
    }

    final BillPurchaseStatus status =
        result.isSuccess ? result.status : BillPurchaseStatus.failed;
    final String message =
        result.fieldErrors['pin'] ??
        result.fieldErrors['amount'] ??
        result.fieldErrors['meter_number'] ??
        result.message ??
        (status == BillPurchaseStatus.successful
            ? 'Your electricity bill was completed successfully.'
            : status == BillPurchaseStatus.processing
            ? 'Your electricity bill is being processed. Please check your history shortly.'
            : 'We could not complete this electricity bill right now. Please try again.');

    return _BillResult(
      status: status,
      providerName: selectedProvider.name,
      meterNumber: _meterController.text.trim(),
      customerName: _verifiedCustomerName!,
      address: _verifiedAddress!,
      meterType: meterTypeLabel,
      amount: result.historyItem?.amount ?? (_amount + _serviceCharge),
      reference:
          result.reference.isNotEmpty
              ? result.reference
              : 'EBL-${DateTime.now().millisecondsSinceEpoch}',
      message: message,
    );
  }

  Future<void> _openResultSheet(_BillResult result) async {
    final _BillResultAction? action =
        await showModalBottomSheet<_BillResultAction>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (BuildContext context) {
            return _BillResultSheet(result: result, formatter: _formatCurrency);
          },
        );

    if (!mounted) {
      return;
    }

    if (result.isSuccessful || result.isProcessing) {
      _resetFormAfterSuccess();
      await _loadCatalog();
      return;
    }

    if (action == _BillResultAction.retry) {
      await _openConfirmationSheet();
    }
  }

  void _resetFormAfterSuccess() {
    setState(() {
      _selectedProviderId = null;
      _meterType = 'prepaid';
      _meterController.clear();
      _amountController.clear();
      _phoneController.clear();
      _verifiedCustomerName = null;
      _verifiedAddress = null;
    });
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'successful':
        return const Color(0xFF16A34A);
      case 'processing':
      case 'pending':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFFEF4444);
    }
  }

  String _formatCurrency(num amount) {
    final bool isNegative = amount < 0;
    final String fixed = amount.abs().toStringAsFixed(2);
    final List<String> parts = fixed.split('.');
    final String whole = parts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (Match match) => ',',
    );
    return '${isNegative ? '-' : ''}\u20A6$whole.${parts.last}';
  }

  String _formatDate(DateTime value) {
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final int hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final String suffix = value.hour >= 12 ? 'PM' : 'AM';
    final String minute = value.minute.toString().padLeft(2, '0');
    return '${months[value.month - 1]} ${value.day}, ${value.year}, $hour:$minute $suffix';
  }

  InputDecoration _fieldDecoration({
    required bool isDark,
    required Color mutedText,
    required String hintText,
    Widget? prefixIcon,
    String? prefixText,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: prefixIcon,
      prefixText: prefixText,
      prefixStyle: TextStyle(
        color: mutedText,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
      filled: true,
      fillColor: isDark ? _darkPanel : const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF3A4054) : _softBorder,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF3A4054) : _softBorder,
        ),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
        borderSide: BorderSide(color: _primary, width: 1.3),
      ),
      hintStyle: TextStyle(color: mutedText, fontSize: 12.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor = isDark ? _darkBackground : Colors.white;
    final Color pageSurface = isDark ? _darkSurface : Colors.white;
    final Color panelColor = isDark ? _darkPanel : const Color(0xFFF8FAFC);
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
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
          'Bill Payment',
          style: TextStyle(
            color: titleColor,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double bottomPadding =
              112 + MediaQuery.paddingOf(context).bottom;

          return RefreshIndicator.adaptive(
            color: _primary,
            onRefresh: _refreshBillCatalog,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
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
                        Text(
                          'Validate the meter, confirm the customer details, and complete your electricity bill securely.',
                          style: TextStyle(
                            color: mutedText,
                            fontSize: 12.2,
                            fontWeight: FontWeight.w500,
                            height: 1.45,
                          ),
                        ),
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
                                  child: _BillMetricTile(
                                    label: 'Min Amount',
                                    value: _formatCurrency(_minimumAmount),
                                    isDark: isDark,
                                  ),
                                ),
                                SizedBox(
                                  width: itemWidth,
                                  child: _BillMetricTile(
                                    label: 'Charge',
                                    value: _formatCurrency(_serviceCharge),
                                    isDark: isDark,
                                  ),
                                ),
                                SizedBox(
                                  width: itemWidth,
                                  child: _BillMetricTile(
                                    label: 'Token',
                                    value: 'Instant',
                                    isDark: isDark,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Electricity Bill Payment',
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pick a provider, enter your meter details, and validate the customer before we charge your wallet.',
                          style: TextStyle(
                            color: mutedText,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Select Provider *',
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        LayoutBuilder(
                          builder: (
                            BuildContext context,
                            BoxConstraints constraints,
                          ) {
                            final double itemWidth =
                                (constraints.maxWidth - 24) / 4;

                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  _providers
                                      .map(
                                        (_BillProvider provider) => SizedBox(
                                          width: itemWidth,
                                          child: _ProviderTile(
                                            provider: provider,
                                            isDark: isDark,
                                            selected:
                                                provider.id ==
                                                _selectedProviderId,
                                            onTap: () {
                                              setState(() {
                                                _selectedProviderId =
                                                    provider.id;
                                                if (!provider.meterTypes
                                                    .contains(_meterType)) {
                                                  _meterType =
                                                      provider.meterTypes.first;
                                                }
                                                _verifiedCustomerName = null;
                                                _verifiedAddress = null;
                                              });
                                            },
                                          ),
                                        ),
                                      )
                                      .toList(),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Meter Type *',
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark ? _darkPanel : _softTint,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: _MeterTypeChip(
                                  label: 'Prepaid',
                                  active: _meterType == 'prepaid',
                                  enabled:
                                      _selectedProvider?.meterTypes.contains(
                                        'prepaid',
                                      ) ??
                                      true,
                                  onTap: () {
                                    setState(() {
                                      _meterType = 'prepaid';
                                      _verifiedCustomerName = null;
                                      _verifiedAddress = null;
                                    });
                                  },
                                ),
                              ),
                              Expanded(
                                child: _MeterTypeChip(
                                  label: 'Postpaid',
                                  active: _meterType == 'postpaid',
                                  enabled:
                                      _selectedProvider?.meterTypes.contains(
                                        'postpaid',
                                      ) ??
                                      true,
                                  onTap: () {
                                    setState(() {
                                      _meterType = 'postpaid';
                                      _verifiedCustomerName = null;
                                      _verifiedAddress = null;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _meterController,
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(16),
                          ],
                          onChanged: (_) {
                            setState(() {
                              _verifiedCustomerName = null;
                              _verifiedAddress = null;
                            });
                          },
                          decoration: _fieldDecoration(
                            isDark: isDark,
                            mutedText: mutedText,
                            hintText: 'Meter number',
                            prefixIcon: Icon(
                              Icons.confirmation_number_outlined,
                              size: 18,
                              color: mutedText,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(15),
                          ],
                          onChanged: (_) {
                            setState(() {
                              _verifiedCustomerName = null;
                              _verifiedAddress = null;
                            });
                          },
                          decoration: _fieldDecoration(
                            isDark: isDark,
                            mutedText: mutedText,
                            hintText: 'Phone number',
                            prefixIcon: Icon(
                              Icons.call_outlined,
                              size: 18,
                              color: mutedText,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (_) {
                            setState(() {
                              _verifiedCustomerName = null;
                              _verifiedAddress = null;
                            });
                          },
                          decoration: _fieldDecoration(
                            isDark: isDark,
                            mutedText: mutedText,
                            hintText: '500',
                            prefixText: '\u20A6 ',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _amount > _maximumAmount
                              ? 'Maximum amount is ${_formatCurrency(_maximumAmount)}.'
                              : 'Minimum ${_formatCurrency(_minimumAmount)} • Maximum ${_formatCurrency(_maximumAmount)}.',
                          style: TextStyle(
                            color:
                                (_amount > 0 && _amount < _minimumAmount) ||
                                        _amount > _maximumAmount
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
                                            amountLabel: '\u20A6$amount',
                                            isDark: isDark,
                                            selected: _amount == amount,
                                            onTap:
                                                () => _applyQuickAmount(amount),
                                          ),
                                        ),
                                      )
                                      .toList(),
                            );
                          },
                        ),
                        if (_verifiedCustomerName != null &&
                            _verifiedAddress != null) ...<Widget>[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color:
                                  isDark
                                      ? const Color(0xFF052E16)
                                      : const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color:
                                    isDark
                                        ? const Color(0xFF166534)
                                        : const Color(0xFF86EFAC),
                              ),
                            ),
                            child: Row(
                              children: <Widget>[
                                const CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Color(0xFFDCFCE7),
                                  child: Icon(
                                    Icons.verified_rounded,
                                    color: Color(0xFF16A34A),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        _verifiedCustomerName!,
                                        style: TextStyle(
                                          color:
                                              isDark
                                                  ? const Color(0xFFF8FAFC)
                                                  : const Color(0xFF166534),
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _verifiedAddress!,
                                        style: TextStyle(
                                          color:
                                              isDark
                                                  ? const Color(0xFFBBF7D0)
                                                  : const Color(0xFF15803D),
                                          fontSize: 11.2,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (_amount > 0) ...<Widget>[
                          const SizedBox(height: 14),
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
                                        ? _primary.withValues(alpha: 0.18)
                                        : _softBorder,
                              ),
                            ),
                            child: Column(
                              children: <Widget>[
                                _BillBreakdownRow(
                                  label: 'Meter Type',
                                  value:
                                      _meterType == 'prepaid'
                                          ? 'Prepaid'
                                          : 'Postpaid',
                                  valueColor: titleColor,
                                  isDark: isDark,
                                ),
                                const SizedBox(height: 10),
                                _BillBreakdownRow(
                                  label: 'Bill Amount',
                                  value: _formatCurrency(_amount),
                                  valueColor: titleColor,
                                  isDark: isDark,
                                ),
                                const SizedBox(height: 10),
                                _BillBreakdownRow(
                                  label: 'Service Charge',
                                  value: _formatCurrency(_serviceCharge),
                                  valueColor: titleColor,
                                  isDark: isDark,
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  child: Divider(height: 1),
                                ),
                                _BillBreakdownRow(
                                  label: 'Total to Pay',
                                  value: _formatCurrency(
                                    _amount + _serviceCharge,
                                  ),
                                  valueColor: _primary,
                                  emphasize: true,
                                  isDark: isDark,
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed:
                                _verifiedCustomerName == null
                                    ? (_canValidate ? _validateMeter : null)
                                    : _openConfirmationSheet,
                            style: FilledButton.styleFrom(
                              backgroundColor: _primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            icon: Icon(
                              _verifiedCustomerName == null
                                  ? Icons.verified_user_rounded
                                  : Icons.bolt_rounded,
                              size: 18,
                            ),
                            label: Text(
                              _verifiedCustomerName == null
                                  ? (_validating
                                      ? 'Validating...'
                                      : 'Validate Meter')
                                  : 'Pay Bill Now',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: panelColor,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color:
                                  isDark
                                      ? const Color(0xFF3A4054)
                                      : _softBorder,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Text(
                                'Recent Bill Payments',
                                style: TextStyle(
                                  color: titleColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'See the latest electricity payments and their statuses.',
                                style: TextStyle(
                                  color: mutedText,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (_history.isEmpty)
                                Text(
                                  'No electricity payments yet. Your completed bills will appear here.',
                                  style: TextStyle(
                                    color: mutedText,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                )
                              else
                                ..._history.map((_BillHistoryItem item) {
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom: item == _history.last ? 0 : 12,
                                    ),
                                    child: _BillHistoryCard(
                                      item: item,
                                      isDark: isDark,
                                      statusColor: _statusColor(item.status),
                                      formatter: _formatCurrency,
                                      dateFormatter: _formatDate,
                                    ),
                                  );
                                }),
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
        },
      ),
      bottomNavigationBar: AppBottomNavigation(
        isDark: isDark,
        selectedDestination: AppBottomNavDestination.home,
        onSelect: _handleBottomNavigation,
      ),
    );
  }
}

class _BillMetricTile extends StatelessWidget {
  const _BillMetricTile({
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
              fontSize: 12.2,
              fontWeight: FontWeight.w800,
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

class _ProviderTile extends StatelessWidget {
  const _ProviderTile({
    required this.provider,
    required this.isDark,
    required this.selected,
    required this.onTap,
  });

  final _BillProvider provider;
  final bool isDark;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color:
                selected
                    ? provider.accent.withValues(alpha: 0.12)
                    : (isDark ? _darkPanel : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color:
                  selected
                      ? provider.accent
                      : (isDark ? const Color(0xFF3A4054) : _softBorder),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            children: <Widget>[
              CircleAvatar(
                radius: 16,
                backgroundColor: provider.accent.withValues(alpha: 0.14),
                child: Icon(
                  Icons.bolt_rounded,
                  size: 18,
                  color: provider.accent,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                provider.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 10.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeterTypeChip extends StatelessWidget {
  const _MeterTypeChip({
    required this.label,
    required this.active,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool active;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color:
              !enabled
                  ? (isDark ? const Color(0xFF111827) : const Color(0xFFE5E7EB))
                  : active
                  ? _primary
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color:
                  !enabled
                      ? (isDark
                          ? const Color(0xFFC7CDDC)
                          : const Color(0xFF4B5563))
                      : active
                      ? Colors.white
                      : (isDark
                          ? const Color(0xFFE5E7EB)
                          : const Color(0xFF0F172A)),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAmountButton extends StatelessWidget {
  const _QuickAmountButton({
    required this.amountLabel,
    required this.isDark,
    required this.selected,
    required this.onTap,
  });

  final String amountLabel;
  final bool isDark;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color textColor =
        isDark ? const Color(0xFFE5E7EB) : const Color(0xFF374151);

    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        elevation: 0,
        backgroundColor:
            selected ? _primary : (isDark ? _darkPanel : Colors.white),
        foregroundColor: selected ? Colors.white : textColor,
        side: BorderSide(
          color:
              selected
                  ? Colors.transparent
                  : (isDark ? const Color(0xFF3A4054) : _softBorder),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
      ),
      child: Text(amountLabel),
    );
  }
}

class _BillBreakdownRow extends StatelessWidget {
  const _BillBreakdownRow({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.isDark,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool isDark;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final Color mutedText = isDark ? _darkMuted : const Color(0xFF4B5563);

    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: mutedText,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: emphasize ? 13 : 12,
            fontWeight: emphasize ? FontWeight.w800 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _BillConfirmationSheet extends StatelessWidget {
  const _BillConfirmationSheet({
    required this.providerName,
    required this.meterType,
    required this.meterNumber,
    required this.customerName,
    required this.address,
    required this.totalAmount,
  });

  final String providerName;
  final String meterType;
  final String meterNumber;
  final String customerName;
  final String address;
  final String totalAmount;

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
                      'Confirm Electricity Payment',
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
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
                'Review this bill payment before entering your payment PIN.',
                style: TextStyle(
                  color: mutedText,
                  fontSize: 11.2,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                totalAmount,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:
                      isDark
                          ? const Color(0xFFF8FAFC)
                          : const Color(0xFF0F172A),
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _CompactSummaryTile(
                      label: 'Provider',
                      value: providerName,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _CompactSummaryTile(
                      label: 'Meter Type',
                      value: meterType,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _CompactSummaryTile(
                      label: 'Meter',
                      value: meterNumber,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _CompactSummaryTile(
                      label: 'Customer',
                      value: customerName,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _CompactSummaryTile(
                label: 'Address',
                value: address,
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12.4,
                    fontWeight: FontWeight.w800,
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
        color: isDark ? _darkPanel : const Color(0xFFF8FAFC),
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: titleColor,
              fontSize: 11.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BillPinSheet extends StatefulWidget {
  const _BillPinSheet({required this.onSubmit, required this.canUseBiometric});

  final Future<_BillResult> Function(String pin) onSubmit;
  final bool canUseBiometric;

  @override
  State<_BillPinSheet> createState() => _BillPinSheetState();
}

class _BillPinSheetState extends State<_BillPinSheet> {
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
    _BillResult? submitResult;

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
      submitResult = null;
    } finally {
      rootNavigator.pop();
    }

    if (!mounted) {
      return;
    }

    if (submitResult == null) {
      setState(() {
        _processing = false;
        _errorText = 'We could not complete this payment right now.';
      });
      return;
    }

    Navigator.of(context).pop(submitResult);
  }

  Future<void> _submitBiometric() async {
    if (_processing || !widget.canUseBiometric) {
      return;
    }

    setState(() {
      _processing = true;
      _errorText = null;
    });

    final BiometricAuthResult biometricResult =
        await BiometricAuthService.instance.authenticateQuickLogin();
    if (!mounted) {
      return;
    }

    if (!biometricResult.isSuccess) {
      setState(() {
        _processing = false;
        _errorText =
            biometricResult.message ?? 'Biometric payment could not start.';
      });
      return;
    }

    final String? storedPin =
        await SecureTransactionPinService.instance.readPin();
    if (!mounted) {
      return;
    }

    if (storedPin == null || storedPin.length != 4) {
      await AppSettingsService.instance.setBiometricUnlockEnabled(false);
      await SecureTransactionPinService.instance.clearPin();
      if (!mounted) {
        return;
      }

      setState(() {
        _processing = false;
        _errorText =
            'Fingerprint payment needs to be enabled again in Settings on this device.';
      });
      return;
    }

    final NavigatorState rootNavigator = Navigator.of(
      context,
      rootNavigator: true,
    );
    _BillResult? submitResult;

    showPtsDataLoaderDialog<void>(
      context,
      text: 'Confirming fingerprint...',
      color: _primary,
    );

    try {
      submitResult = await widget.onSubmit(storedPin);
    } catch (_) {
      submitResult = null;
    } finally {
      if (rootNavigator.canPop()) {
        rootNavigator.pop();
      }
    }

    if (!mounted) {
      return;
    }

    if (submitResult == null) {
      setState(() {
        _processing = false;
        _errorText = 'We could not complete biometric payment right now.';
      });
      return;
    }

    Navigator.of(context).pop(submitResult);
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
                        if (widget.canUseBiometric) ...<Widget>[
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
                                fontWeight: FontWeight.w700,
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

enum _BillResultAction { close, retry }

class _BillResultSheet extends StatelessWidget {
  const _BillResultSheet({required this.result, required this.formatter});

  final _BillResult result;
  final String Function(num amount) formatter;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDark ? _darkSurface : Colors.white;
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);
    final Color mutedText = isDark ? _darkMuted : const Color(0xFF4B5563);
    final Color statusColor =
        result.isSuccessful
            ? const Color(0xFF16A34A)
            : result.isProcessing
            ? const Color(0xFFF59E0B)
            : const Color(0xFFDC2626);
    final Color accentTint =
        result.isSuccessful
            ? const Color(0xFF16A34A).withValues(alpha: isDark ? 0.16 : 0.10)
            : result.isProcessing
            ? const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.16 : 0.10)
            : const Color(0xFFDC2626).withValues(alpha: isDark ? 0.18 : 0.10);
    final IconData statusIcon =
        result.isSuccessful
            ? Icons.check_rounded
            : result.isProcessing
            ? Icons.schedule_rounded
            : Icons.close_rounded;
    final double sheetHeight = MediaQuery.sizeOf(context).height * 0.84;
    final Widget actionSection =
        (result.isSuccessful || result.isProcessing)
            ? FilledButton.icon(
              onPressed:
                  () => Navigator.of(context).pop(_BillResultAction.close),
              style: FilledButton.styleFrom(
                backgroundColor:
                    result.isSuccessful
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFF59E0B),
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
              icon: Icon(
                result.isProcessing
                    ? Icons.schedule_rounded
                    : Icons.home_rounded,
                size: 16,
              ),
              label: Text(result.isProcessing ? 'Okay' : 'Done'),
            )
            : Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        () =>
                            Navigator.of(context).pop(_BillResultAction.close),
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
                        () =>
                            Navigator.of(context).pop(_BillResultAction.retry),
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
                        result.isSuccessful
                            ? 'Successful'
                            : result.isProcessing
                            ? 'Processing'
                            : 'Failed',
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
                          ).pop(_BillResultAction.close),
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
                      : result.isProcessing
                      ? 'Payment Processing'
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
                      _ResultSummaryRow(
                        label: 'Provider',
                        value: result.providerName,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 8),
                      _ResultSummaryRow(
                        label: 'Meter',
                        value: result.meterNumber,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 8),
                      _ResultSummaryRow(
                        label: 'Meter Type',
                        value: result.meterType,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 8),
                      _ResultSummaryRow(
                        label: 'Customer',
                        value: result.customerName,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 8),
                      _ResultSummaryRow(
                        label: 'Reference',
                        value: result.reference,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 8),
                      _ResultSummaryRow(
                        label: 'Address',
                        value: result.address,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: accentTint,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                result.isProcessing ? 'Amount' : 'Amount Paid',
                                style: TextStyle(
                                  color: mutedText,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              formatter(result.amount),
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

class _ResultSummaryRow extends StatelessWidget {
  const _ResultSummaryRow({
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
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827),
              fontSize: 11.8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _BillHistoryCard extends StatelessWidget {
  const _BillHistoryCard({
    required this.item,
    required this.isDark,
    required this.statusColor,
    required this.formatter,
    required this.dateFormatter,
  });

  final _BillHistoryItem item;
  final bool isDark;
  final Color statusColor;
  final String Function(num amount) formatter;
  final String Function(DateTime value) dateFormatter;

  @override
  Widget build(BuildContext context) {
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color mutedText = isDark ? _darkMuted : const Color(0xFF4B5563);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? _darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF3A4054) : _softBorder,
        ),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 18,
            backgroundColor: statusColor.withValues(alpha: 0.12),
            child: Icon(Icons.bolt_rounded, color: statusColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${item.provider} - ${item.meterType}',
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.meterNumber} - ${dateFormatter(item.createdAt)}',
                  style: TextStyle(
                    color: mutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                formatter(item.amount),
                style: TextStyle(
                  color: titleColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BillProvider {
  const _BillProvider({
    required this.id,
    required this.serviceId,
    required this.name,
    required this.meterTypes,
    required this.accent,
  });

  final String id;
  final String serviceId;
  final String name;
  final List<String> meterTypes;
  final Color accent;
}

class _BillHistoryItem {
  const _BillHistoryItem({
    required this.provider,
    required this.meterNumber,
    required this.amount,
    required this.status,
    required this.meterType,
    required this.createdAt,
  });

  final String provider;
  final String meterNumber;
  final double amount;
  final String status;
  final String meterType;
  final DateTime createdAt;
}

class _BillResult {
  const _BillResult({
    required this.status,
    required this.providerName,
    required this.meterNumber,
    required this.customerName,
    required this.address,
    required this.meterType,
    required this.amount,
    required this.reference,
    required this.message,
  });

  final BillPurchaseStatus status;
  final String providerName;
  final String meterNumber;
  final String customerName;
  final String address;
  final String meterType;
  final double amount;
  final String reference;
  final String message;

  bool get isSuccessful => status == BillPurchaseStatus.successful;
  bool get isProcessing => status == BillPurchaseStatus.processing;
}

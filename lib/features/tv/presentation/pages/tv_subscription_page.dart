import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/auth/app_session_service.dart';
import '../../../../core/auth/biometric_auth_service.dart';
import '../../../../core/auth/secure_transaction_pin_service.dart';
import '../../../../core/settings/app_settings_service.dart';
import '../../../navigation/presentation/widgets/app_bottom_navigation.dart';
import '../../../shared/presentation/widgets/pts_data_loader_overlay.dart';
import '../../../shared/presentation/widgets/pts_data_select_page.dart';
import '../../data/tv_subscription_api_service.dart';

const Color _primary = Color(0xFFB89CFF);
const Color _softTint = Color(0xFFF3F4F6);
const Color _softBorder = Color(0xFFE5E7EB);
const Color _darkBackground = Color(0xFF171925);
const Color _darkSurface = Color(0xFF22263A);
const Color _darkPanel = Color(0xFF252A42);
const Color _darkMuted = Color(0xFFC7CDDC);

class TvSubscriptionPage extends StatefulWidget {
  const TvSubscriptionPage({super.key});

  @override
  State<TvSubscriptionPage> createState() => _TvSubscriptionPageState();
}

class _TvSubscriptionPageState extends State<TvSubscriptionPage> {
  final TextEditingController _decoderController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  List<_TvProvider> _providers = <_TvProvider>[
    _TvProvider(
      id: 'dstv',
      name: 'DSTV',
      serviceId: 'dstv',
      meterTypes: const <String>['prepaid', 'postpaid'],
      image: 'https://unitybills.ng/assets/images/brands/dstv.png',
      accent: const Color(0xFF0F4C81),
      plans: const <_TvPlan>[],
    ),
    _TvProvider(
      id: 'gotv',
      name: 'GOTV',
      serviceId: 'gotv',
      meterTypes: const <String>['prepaid'],
      image: 'https://unitybills.ng/assets/images/brands/gotv.png',
      accent: const Color(0xFF16A34A),
      plans: const <_TvPlan>[],
    ),
    _TvProvider(
      id: 'startimes',
      name: 'Startimes',
      serviceId: 'startimes',
      meterTypes: const <String>['prepaid'],
      image: 'https://unitybills.ng/assets/images/brands/startimes.png',
      accent: const Color(0xFFF97316),
      plans: const <_TvPlan>[],
    ),
  ];
  List<_TvHistoryItem> _history = const <_TvHistoryItem>[];
  double _serviceCharge = 100;

  String? _selectedProviderId;
  String? _selectedPlanCode;
  String? _verifiedCustomerName;
  bool _validating = false;
  bool _processing = false;
  bool _isLoadingCatalog = true;
  bool _isLoadingPlans = false;
  String? _plansError;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  @override
  void dispose() {
    _decoderController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  _TvProvider? get _selectedProvider {
    final String? providerId = _selectedProviderId;
    if (providerId == null) {
      return null;
    }

    for (final _TvProvider provider in _providers) {
      if (provider.id == providerId) {
        return provider;
      }
    }

    return null;
  }

  _TvPlan? get _selectedPlan {
    final _TvProvider? provider = _selectedProvider;
    final String? planCode = _selectedPlanCode;
    if (provider == null || planCode == null) {
      return null;
    }

    for (final _TvPlan plan in provider.plans) {
      if (plan.code == planCode) {
        return plan;
      }
    }

    return null;
  }

  bool get _canValidate {
    return !_isLoadingCatalog &&
        !_isLoadingPlans &&
        _selectedProvider != null &&
        _selectedPlan != null &&
        _decoderController.text.trim().length >= 8 &&
        _phoneController.text.trim().length >= 10;
  }

  String get _selectedMeterType {
    final _TvProvider? provider = _selectedProvider;
    if (provider == null || provider.meterTypes.isEmpty) {
      return 'prepaid';
    }

    return provider.meterTypes.first;
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
    setState(() {
      _isLoadingCatalog = true;
    });

    final String? token = await AppSessionService.instance.getApiToken();
    if (token == null || token.isEmpty) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingCatalog = false;
      });
      return;
    }

    final TvCatalogApiResult result = await TvSubscriptionApiService.instance
        .fetchCatalog(token: token, limit: 8);
    if (!mounted) {
      return;
    }

    if (result.isUnauthorized) {
      setState(() {
        _isLoadingCatalog = false;
      });
      await _handleUnauthorized();
      return;
    }

    if (result.isSuccess) {
      setState(() {
        _providers = _mapProviders(result.providers);
        _history = _mapHistory(result.history);
        _serviceCharge = result.serviceCharge;
        _isLoadingCatalog = false;
      });
      return;
    }

    setState(() {
      _isLoadingCatalog = false;
    });

    if (result.message != null && result.message!.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message!)));
    }
  }

  Future<void> _selectProvider(_TvProvider provider) async {
    setState(() {
      _selectedProviderId = provider.id;
      _selectedPlanCode = null;
      _verifiedCustomerName = null;
      _plansError = null;
    });

    if (provider.plans.isNotEmpty) {
      return;
    }

    await _loadPlans(provider);
  }

  Future<void> _loadPlans(_TvProvider provider) async {
    final String? token = await AppSessionService.instance.getApiToken();
    if (token == null || token.isEmpty) {
      return;
    }

    setState(() {
      _isLoadingPlans = true;
      _plansError = null;
    });

    final TvPlansApiResult result = await TvSubscriptionApiService.instance
        .fetchPlans(token: token, serviceId: provider.serviceId);
    if (!mounted) {
      return;
    }

    if (result.isUnauthorized) {
      setState(() {
        _isLoadingPlans = false;
      });
      await _handleUnauthorized();
      return;
    }

    if (result.isSuccess) {
      final List<_TvPlan> plans = _mapPlans(result.plans);
      setState(() {
        _providers = _providers
            .map(
              (_TvProvider item) =>
                  item.id == provider.id ? item.copyWith(plans: plans) : item,
            )
            .toList(growable: false);
        _isLoadingPlans = false;
      });
      return;
    }

    setState(() {
      _plansError =
          result.message ?? 'We could not load the cable bouquets right now.';
      _isLoadingPlans = false;
    });

    if (result.message != null && result.message!.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message!)));
    }
  }

  Future<void> _refreshTvCatalog() async {
    final String? selectedProviderId = _selectedProviderId;
    await _loadCatalog();
    if (!mounted || selectedProviderId == null) {
      return;
    }

    final _TvProvider? provider = _providers.cast<_TvProvider?>().firstWhere(
      (_TvProvider? item) => item?.id == selectedProviderId,
      orElse: () => null,
    );
    if (provider != null) {
      await _loadPlans(provider);
    }
  }

  Future<void> _openTvPlanSelector(_TvProvider provider) async {
    if (provider.plans.isEmpty) {
      return;
    }

    final String? selectedPlanCode = await showPtsDataSelectPage<String>(
      context: context,
      title: 'Select Bouquet',
      searchHint: 'Enter search content',
      pinnedTitle: 'Popular Bouquets',
      selectedValue: _selectedPlanCode,
      options: provider.plans
          .asMap()
          .entries
          .map((MapEntry<int, _TvPlan> entry) {
            final _TvPlan plan = entry.value;
            return PtsDataSelectOption<String>(
              value: plan.code,
              title: plan.name,
              trailing: _formatCurrency(plan.amount),
              searchText:
                  '${plan.name} ${plan.amount} ${_formatCurrency(plan.amount)}',
              pinned: entry.key < 6,
            );
          })
          .toList(growable: false),
      emptyText: 'No bouquet matches your search.',
    );

    if (!mounted || selectedPlanCode == null) {
      return;
    }

    setState(() {
      _selectedPlanCode = selectedPlanCode;
      _verifiedCustomerName = null;
    });
  }

  Future<void> _validateSubscriber() async {
    if (!_canValidate || _validating) {
      return;
    }

    setState(() {
      _validating = true;
      _verifiedCustomerName = null;
    });

    final NavigatorState rootNavigator = Navigator.of(
      context,
      rootNavigator: true,
    );
    showPtsDataLoaderDialog<void>(
      context,
      text: 'Validating decoder...',
      color: _primary,
    );

    final String? token = await AppSessionService.instance.getApiToken();
    TvValidationApiResult result;
    try {
      if (token == null || token.isEmpty) {
        result = const TvValidationApiResult.unauthorized(
          'Your session has expired. Please sign in again.',
        );
      } else {
        result = await TvSubscriptionApiService.instance.validateSubscriber(
          token: token,
          serviceId: _selectedProvider!.serviceId,
          smartCardNumber: _decoderController.text.trim(),
          meterType: _selectedMeterType,
        );
      }
    } finally {
      rootNavigator.pop();
    }

    if (!mounted) {
      return;
    }

    if (result.isUnauthorized) {
      setState(() {
        _validating = false;
      });
      await _handleUnauthorized();
      return;
    }

    if (result.isSuccess) {
      setState(() {
        _validating = false;
        _verifiedCustomerName = result.customerName;
      });
      return;
    }

    setState(() {
      _validating = false;
    });

    final String validationMessage =
        result.fieldErrors['smart_card_number'] ??
        result.fieldErrors['service_id'] ??
        result.message ??
        'We could not verify this decoder right now.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(validationMessage)));
  }

  Future<void> _openConfirmationSheet() async {
    final _TvPlan? selectedPlan = _selectedPlan;
    final _TvProvider? selectedProvider = _selectedProvider;
    if (_verifiedCustomerName == null ||
        selectedPlan == null ||
        selectedProvider == null) {
      return;
    }

    final bool? shouldContinue = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _TvConfirmationSheet(
          providerName: selectedProvider.name,
          planName: selectedPlan.name,
          smartCardNumber: _decoderController.text.trim(),
          customerName: _verifiedCustomerName!,
          totalAmount: _formatCurrency(selectedPlan.amount + _serviceCharge),
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

    final _TvResult? result = await showModalBottomSheet<_TvResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: !_processing,
      builder: (BuildContext context) {
        return _TvPinSheet(
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

  Future<_TvResult> _submitPayment(String pin) async {
    final _TvPlan? selectedPlan = _selectedPlan;
    final _TvProvider? selectedProvider = _selectedProvider;
    if (_processing ||
        pin.length != 4 ||
        selectedPlan == null ||
        selectedProvider == null ||
        _verifiedCustomerName == null) {
      throw StateError('TV payment is invalid or already processing.');
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
      return _TvResult(
        isSuccessful: false,
        providerName: selectedProvider.name,
        planName: selectedPlan.name,
        smartCardNumber: _decoderController.text.trim(),
        customerName: _verifiedCustomerName!,
        amount: selectedPlan.amount + _serviceCharge,
        reference: '',
        message: 'Your session has expired. Please sign in again.',
      );
    }

    final TvPurchaseApiResult result = await TvSubscriptionApiService.instance
        .purchase(
          token: token,
          serviceId: selectedProvider.serviceId,
          smartCardNumber: _decoderController.text.trim(),
          meterType: _selectedMeterType,
          amount: selectedPlan.amount,
          phoneNumber: _phoneController.text.trim(),
          pin: pin,
          variationCode: selectedPlan.code,
          planName: selectedPlan.name,
        );

    if (!mounted) {
      throw StateError('Widget was disposed during TV payment.');
    }

    if (result.isUnauthorized) {
      setState(() {
        _processing = false;
      });
      await _handleUnauthorized();
      return _TvResult(
        isSuccessful: false,
        providerName: selectedProvider.name,
        planName: selectedPlan.name,
        smartCardNumber: _decoderController.text.trim(),
        customerName: _verifiedCustomerName!,
        amount: selectedPlan.amount + _serviceCharge,
        reference: '',
        message: 'Your session has expired. Please sign in again.',
      );
    }

    if (result.isSuccess && result.historyItem != null) {
      final _TvHistoryItem nextItem = _mapHistoryItem(result.historyItem!);
      setState(() {
        _history = <_TvHistoryItem>[nextItem, ..._history];
        _processing = false;
      });
    } else {
      setState(() {
        _processing = false;
      });
    }

    final bool isSuccessful = result.isSuccess;
    final String message =
        result.fieldErrors['pin'] ??
        result.fieldErrors['amount'] ??
        result.message ??
        (isSuccessful
            ? 'Your cable bill was completed successfully.'
            : 'We could not complete this cable bill right now. Please try again.');

    return _TvResult(
      isSuccessful: isSuccessful,
      providerName: selectedProvider.name,
      planName: selectedPlan.name,
      smartCardNumber: _decoderController.text.trim(),
      customerName: _verifiedCustomerName!,
      amount: selectedPlan.amount + _serviceCharge,
      reference:
          result.reference.isNotEmpty
              ? result.reference
              : 'CBL-${DateTime.now().millisecondsSinceEpoch}',
      message:
          isSuccessful && result.providerToken.isNotEmpty
              ? '$message Token: ${result.providerToken}'
              : message,
    );
  }

  List<_TvProvider> _mapProviders(List<TvApiProvider> providers) {
    return providers
        .map(
          (TvApiProvider provider) => _TvProvider(
            id: provider.id,
            name: provider.name,
            serviceId: provider.serviceId,
            meterTypes: provider.meterTypes,
            image: provider.image,
            accent: _providerAccent(provider.serviceId),
            plans: const <_TvPlan>[],
          ),
        )
        .toList(growable: false);
  }

  List<_TvPlan> _mapPlans(List<TvApiPlan> plans) {
    return plans
        .map(
          (TvApiPlan plan) => _TvPlan(
            code: plan.variationCode,
            name: plan.name,
            amount: plan.amount,
          ),
        )
        .toList(growable: false);
  }

  List<_TvHistoryItem> _mapHistory(List<TvApiHistoryItem> history) {
    return history.map(_mapHistoryItem).toList(growable: false);
  }

  _TvHistoryItem _mapHistoryItem(TvApiHistoryItem item) {
    return _TvHistoryItem(
      provider: item.provider,
      plan: item.plan,
      smartCardNumber: item.smartCardNumber,
      amount: item.amount,
      status: item.status,
      createdAt: DateTime.tryParse(item.createdAt) ?? DateTime.now(),
    );
  }

  Color _providerAccent(String serviceId) {
    switch (serviceId.toLowerCase()) {
      case 'dstv':
        return const Color(0xFF0F4C81);
      case 'gotv':
        return const Color(0xFF16A34A);
      case 'startimes':
        return const Color(0xFFF97316);
      case 'showmax':
        return const Color(0xFF9333EA);
      default:
        return _primary;
    }
  }

  Future<void> _openResultSheet(_TvResult result) async {
    final _TvResultAction? action = await showModalBottomSheet<_TvResultAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _TvResultSheet(result: result, formatter: _formatCurrency);
      },
    );

    if (!mounted) {
      return;
    }

    if (result.isSuccessful) {
      _resetForm();
      return;
    }

    if (action == _TvResultAction.retry) {
      await _openConfirmationSheet();
    }
  }

  void _resetForm() {
    setState(() {
      _decoderController.clear();
      _phoneController.clear();
      _selectedPlanCode = null;
      _verifiedCustomerName = null;
    });
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'successful':
        return const Color(0xFF16A34A);
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
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: prefixIcon,
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
    final _TvPlan? selectedPlan = _selectedPlan;
    final double totalAmount =
        selectedPlan == null ? 0 : selectedPlan.amount + _serviceCharge;

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
          'Cable Bill',
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
            onRefresh: _refreshTvCatalog,
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
                          'Validate your decoder details, choose a bouquet, and complete your cable bill securely.',
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
                                  child: _TvMetricTile(
                                    label: 'Providers',
                                    value: '${_providers.length}',
                                    isDark: isDark,
                                  ),
                                ),
                                SizedBox(
                                  width: itemWidth,
                                  child: _TvMetricTile(
                                    label: 'Charge',
                                    value: _formatCurrency(_serviceCharge),
                                    isDark: isDark,
                                  ),
                                ),
                                SizedBox(
                                  width: itemWidth,
                                  child: _TvMetricTile(
                                    label: 'Delivery',
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
                          'Cable Bill Payment',
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pick a provider, choose a bouquet, and confirm the decoder before we charge your wallet.',
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
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        LayoutBuilder(
                          builder: (
                            BuildContext context,
                            BoxConstraints constraints,
                          ) {
                            final int columns =
                                constraints.maxWidth > 360 ? 4 : 3;
                            final double itemWidth =
                                (constraints.maxWidth - ((columns - 1) * 8)) /
                                columns;

                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  _providers.map((_TvProvider provider) {
                                    final bool active =
                                        provider.id == _selectedProviderId;

                                    return SizedBox(
                                      width: itemWidth,
                                      child: _ProviderTile(
                                        provider: provider,
                                        isDark: isDark,
                                        selected: active,
                                        onTap: () => _selectProvider(provider),
                                      ),
                                    );
                                  }).toList(),
                            );
                          },
                        ),
                        if (_selectedProvider != null) ...<Widget>[
                          const SizedBox(height: 16),
                          Text(
                            'Select Bouquet *',
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (_isLoadingPlans) ...<Widget>[
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: panelColor,
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
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.1,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Loading bouquets for ${_selectedProvider!.name}...',
                                      style: TextStyle(
                                        color: mutedText,
                                        fontSize: 11.8,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else if (_selectedProvider!
                              .plans
                              .isEmpty) ...<Widget>[
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: panelColor,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color:
                                      isDark
                                          ? const Color(0xFF3A4054)
                                          : _softBorder,
                                ),
                              ),
                              child: Text(
                                _plansError ??
                                    'No bouquets are available for this provider right now.',
                                style: TextStyle(
                                  color: mutedText,
                                  fontSize: 11.8,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ] else ...<Widget>[
                            LayoutBuilder(
                              builder: (
                                BuildContext context,
                                BoxConstraints constraints,
                              ) {
                                final List<_TvPlan> visiblePlans =
                                    _selectedProvider!.plans.take(3).toList();
                                final double itemWidth =
                                    (constraints.maxWidth - 16) / 3;

                                return Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children:
                                      visiblePlans
                                          .map(
                                            (_TvPlan plan) => SizedBox(
                                              width: itemWidth,
                                              child: _PlanTile(
                                                plan: plan,
                                                isDark: isDark,
                                                selected:
                                                    plan.code ==
                                                    _selectedPlanCode,
                                                formatter: _formatCurrency,
                                                onTap: () {
                                                  setState(() {
                                                    _selectedPlanCode =
                                                        plan.code;
                                                    _verifiedCustomerName =
                                                        null;
                                                  });
                                                },
                                              ),
                                            ),
                                          )
                                          .toList(),
                                );
                              },
                            ),
                          ],
                          if (!_isLoadingPlans &&
                              _selectedProvider!.plans.length > 3) ...<Widget>[
                            const SizedBox(height: 12),
                            PtsDataSelectField(
                              placeholder: 'See all bouquets',
                              value:
                                  selectedPlan == null
                                      ? null
                                      : '${selectedPlan.name} • ${_formatCurrency(selectedPlan.amount)}',
                              icon: Icons.tv_rounded,
                              onTap:
                                  () => _openTvPlanSelector(_selectedProvider!),
                            ),
                          ],
                        ],
                        const SizedBox(height: 12),
                        TextField(
                          controller: _decoderController,
                          keyboardType: TextInputType.number,
                          onChanged:
                              (_) =>
                                  setState(() => _verifiedCustomerName = null),
                          decoration: _fieldDecoration(
                            isDark: isDark,
                            mutedText: mutedText,
                            hintText: 'Smart card / IUC number',
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
                          onChanged:
                              (_) =>
                                  setState(() => _verifiedCustomerName = null),
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                          ],
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
                        if (_verifiedCustomerName != null) ...<Widget>[
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
                                        'Customer details confirmed and ready for payment.',
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
                        if (selectedPlan != null) ...<Widget>[
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
                                _BreakdownRow(
                                  label: 'Bouquet',
                                  value: selectedPlan.name,
                                  valueColor: titleColor,
                                  isDark: isDark,
                                ),
                                const SizedBox(height: 10),
                                _BreakdownRow(
                                  label: 'Plan Amount',
                                  value: _formatCurrency(selectedPlan.amount),
                                  valueColor: titleColor,
                                  isDark: isDark,
                                ),
                                const SizedBox(height: 10),
                                _BreakdownRow(
                                  label: 'Service Charge',
                                  value: _formatCurrency(_serviceCharge),
                                  valueColor: titleColor,
                                  isDark: isDark,
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  child: Divider(height: 1),
                                ),
                                _BreakdownRow(
                                  label: 'Total to Pay',
                                  value: _formatCurrency(totalAmount),
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
                                    ? (_canValidate
                                        ? _validateSubscriber
                                        : null)
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
                                  : Icons.tv_rounded,
                              size: 18,
                            ),
                            label: Text(
                              _verifiedCustomerName == null
                                  ? (_validating
                                      ? 'Validating...'
                                      : 'Validate Decoder')
                                  : 'Pay Cable Bill',
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
                                'Recent Cable Bills',
                                style: TextStyle(
                                  color: titleColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Your latest cable bill payments from the mobile app.',
                                style: TextStyle(
                                  color: mutedText,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ..._history.map((_TvHistoryItem item) {
                                final Color statusColor = _statusColor(
                                  item.status,
                                );

                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: item == _history.last ? 0 : 12,
                                  ),
                                  child: _TvHistoryCard(
                                    item: item,
                                    isDark: isDark,
                                    statusColor: statusColor,
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

class _TvMetricTile extends StatelessWidget {
  const _TvMetricTile({
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

  final _TvProvider provider;
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: provider.accent.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  provider.name.substring(0, 1),
                  style: TextStyle(
                    color: provider.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                provider.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 10.5,
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

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.plan,
    required this.isDark,
    required this.selected,
    required this.formatter,
    required this.onTap,
  });

  final _TvPlan plan;
  final bool isDark;
  final bool selected;
  final String Function(num amount) formatter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color mutedText = isDark ? _darkMuted : const Color(0xFF4B5563);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          decoration: BoxDecoration(
            color:
                selected
                    ? _primary.withValues(alpha: isDark ? 0.18 : 0.10)
                    : (isDark ? _darkPanel : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  selected
                      ? _primary
                      : (isDark ? const Color(0xFF3A4054) : _softBorder),
              width: selected ? 1.3 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                plan.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 11.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                formatter(plan.amount),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? _primary : mutedText,
                  fontSize: 10.4,
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

class _TvConfirmationSheet extends StatelessWidget {
  const _TvConfirmationSheet({
    required this.providerName,
    required this.planName,
    required this.smartCardNumber,
    required this.customerName,
    required this.totalAmount,
  });

  final String providerName;
  final String planName;
  final String smartCardNumber;
  final String customerName;
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
                      'Confirm Cable Bill',
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
                'Review this cable bill before entering your payment PIN.',
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
                      label: 'Bouquet',
                      value: planName,
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
                      label: 'Smart Card',
                      value: smartCardNumber,
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
            maxLines: 1,
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

class _TvPinSheet extends StatefulWidget {
  const _TvPinSheet({required this.onSubmit, required this.canUseBiometric});

  final Future<_TvResult> Function(String pin) onSubmit;
  final bool canUseBiometric;

  @override
  State<_TvPinSheet> createState() => _TvPinSheetState();
}

class _TvPinSheetState extends State<_TvPinSheet> {
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
    _TvResult? submitResult;

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
    _TvResult? submitResult;

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

enum _TvResultAction { close, retry }

class _TvResultSheet extends StatelessWidget {
  const _TvResultSheet({required this.result, required this.formatter});

  final _TvResult result;
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
              onPressed: () => Navigator.of(context).pop(_TvResultAction.close),
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
                        () => Navigator.of(context).pop(_TvResultAction.close),
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
                        () => Navigator.of(context).pop(_TvResultAction.retry),
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
                          () =>
                              Navigator.of(context).pop(_TvResultAction.close),
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
                      _ResultSummaryRow(
                        label: 'Provider',
                        value: result.providerName,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 8),
                      _ResultSummaryRow(
                        label: 'Bouquet',
                        value: result.planName,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 8),
                      _ResultSummaryRow(
                        label: 'Smart Card',
                        value: result.smartCardNumber,
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
                                'Amount Paid',
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

class _TvHistoryCard extends StatelessWidget {
  const _TvHistoryCard({
    required this.item,
    required this.isDark,
    required this.statusColor,
    required this.formatter,
    required this.dateFormatter,
  });

  final _TvHistoryItem item;
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
            child: Icon(Icons.tv_rounded, color: statusColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${item.provider} • ${item.plan}',
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.smartCardNumber} • ${dateFormatter(item.createdAt)}',
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

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
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

class _TvProvider {
  const _TvProvider({
    required this.id,
    required this.name,
    required this.serviceId,
    required this.meterTypes,
    required this.image,
    required this.accent,
    required this.plans,
  });

  final String id;
  final String name;
  final String serviceId;
  final List<String> meterTypes;
  final String image;
  final Color accent;
  final List<_TvPlan> plans;

  _TvProvider copyWith({List<_TvPlan>? plans}) {
    return _TvProvider(
      id: id,
      name: name,
      serviceId: serviceId,
      meterTypes: meterTypes,
      image: image,
      accent: accent,
      plans: plans ?? this.plans,
    );
  }
}

class _TvPlan {
  const _TvPlan({required this.code, required this.name, required this.amount});

  final String code;
  final String name;
  final double amount;
}

class _TvHistoryItem {
  const _TvHistoryItem({
    required this.provider,
    required this.plan,
    required this.smartCardNumber,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  final String provider;
  final String plan;
  final String smartCardNumber;
  final double amount;
  final String status;
  final DateTime createdAt;
}

class _TvResult {
  const _TvResult({
    required this.isSuccessful,
    required this.providerName,
    required this.planName,
    required this.smartCardNumber,
    required this.customerName,
    required this.amount,
    required this.reference,
    required this.message,
  });

  final bool isSuccessful;
  final String providerName;
  final String planName;
  final String smartCardNumber;
  final String customerName;
  final double amount;
  final String reference;
  final String message;
}

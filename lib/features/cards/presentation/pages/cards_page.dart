import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/auth/app_session_service.dart';
import '../../../../core/auth/biometric_auth_service.dart';
import '../../../../core/auth/secure_transaction_pin_service.dart';
import '../../../../core/settings/app_settings_service.dart';
import '../../data/cards_api_service.dart';
import '../../../navigation/presentation/widgets/app_bottom_navigation.dart';
import '../../../shared/presentation/widgets/pts_data_loader_overlay.dart';
import '../../../shared/presentation/widgets/pts_data_select_page.dart';

const Color _primary = Color(0xFFB89CFF);
const Color _softBorder = Color(0xFFE5E7EB);
const Color _softTint = Color(0xFFF3F4F6);
const Color _darkBackground = Color(0xFF171925);
const Color _darkSurface = Color(0xFF22263A);
const Color _darkPanel = Color(0xFF252A42);
const Color _darkMuted = Color(0xFFC7CDDC);

class CardsPage extends StatefulWidget {
  const CardsPage({super.key});

  @override
  State<CardsPage> createState() => _CardsPageState();
}

class _CardsPageState extends State<CardsPage> {
  static const List<int> _quickQuantities = <int>[1, 5, 10, 20];
  static const List<_CardMode> _fallbackModes = <_CardMode>[
    _CardMode(
      id: 'airtime',
      label: 'Airtime Card',
      icon: Icons.call_rounded,
      accent: _primary,
      options: <_CardOption>[
        _CardOption(id: '13', label: 'MTN ₦100', amount: 98),
        _CardOption(id: '3', label: 'MTN ₦500', amount: 490),
        _CardOption(id: '5', label: 'GLO ₦200', amount: 195),
        _CardOption(id: '12', label: 'Airtel ₦500', amount: 497),
      ],
    ),
    _CardMode(
      id: 'data',
      label: 'Data Card',
      icon: Icons.wifi_rounded,
      accent: Color(0xFF7FA0F5),
      options: <_CardOption>[
        _CardOption(id: '7', label: 'MTN 1GB', amount: 245),
        _CardOption(id: '8', label: 'MTN 2GB', amount: 490),
        _CardOption(id: '11', label: 'MTN 5GB', amount: 1215),
      ],
    ),
    _CardMode(
      id: 'epin',
      label: 'E-PIN',
      icon: Icons.pin_rounded,
      accent: Color(0xFFF59E0B),
      options: <_CardOption>[
        _CardOption(
          id: 'WAEC Result Checker',
          label: 'WAEC Result Checker',
          amount: 3400,
        ),
        _CardOption(id: 'NECO Token', label: 'NECO Token', amount: 1150),
        _CardOption(id: 'JAMB ePIN', label: 'JAMB ePIN', amount: 6200),
      ],
    ),
  ];

  final TextEditingController _quantityController = TextEditingController(
    text: '1',
  );
  final TextEditingController _businessController = TextEditingController();

  List<_CardMode> _modes = List<_CardMode>.from(_fallbackModes);
  late List<_GeneratedCardItem> _history;

  String _selectedModeId = 'airtime';
  String? _selectedOptionLabel;
  bool _processing = false;
  bool _loadingOverview = true;
  double _walletBalance = 0;

  @override
  void initState() {
    super.initState();
    _history = const <_GeneratedCardItem>[];
    _loadOverview();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _businessController.dispose();
    super.dispose();
  }

  Future<void> _handleUnauthorized() async {
    await AppSessionService.instance.clear();
    if (!mounted) {
      return;
    }

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
  }

  Future<void> _loadOverview({bool showFailure = true}) async {
    final String? token = await AppSessionService.instance.getApiToken();
    if (token == null || token.isEmpty) {
      if (mounted) {
        setState(() {
          _loadingOverview = false;
        });
      }
      await _handleUnauthorized();
      return;
    }

    final CardsOverviewApiResult result = await CardsApiService.instance
        .fetchOverview(token: token, historyLimit: 12);

    if (!mounted) {
      return;
    }

    if (result.isUnauthorized) {
      setState(() {
        _loadingOverview = false;
      });
      await _handleUnauthorized();
      return;
    }

    if (!result.isSuccess) {
      setState(() {
        _loadingOverview = false;
      });
      if (showFailure) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result.message)));
      }
      return;
    }

    final List<_CardMode> nextModes = _buildModesFromApi(result.modes);
    final bool selectedStillExists = nextModes
        .expand((_CardMode mode) => mode.options)
        .any((_CardOption option) => option.label == _selectedOptionLabel);

    setState(() {
      _loadingOverview = false;
      _walletBalance = result.walletBalance;
      _modes =
          nextModes.isEmpty ? List<_CardMode>.from(_fallbackModes) : nextModes;
      _history = _mapHistory(result.history);
      if (!selectedStillExists) {
        _selectedOptionLabel = null;
      }
    });
  }

  List<_CardMode> _buildModesFromApi(List<CardsApiMode> modes) {
    if (modes.isEmpty) {
      return List<_CardMode>.from(_fallbackModes);
    }

    return modes
        .map((CardsApiMode modeApi) {
          final _CardMode presentation = _fallbackModes.firstWhere(
            (_CardMode item) => item.id == modeApi.id,
            orElse: () => _fallbackModes.first,
          );

          return _CardMode(
            id: modeApi.id,
            label: modeApi.label.isEmpty ? presentation.label : modeApi.label,
            icon: presentation.icon,
            accent: presentation.accent,
            options: modeApi.options
                .map(
                  (CardsApiOption option) => _CardOption(
                    id: option.id,
                    label: option.label,
                    amount: option.amount,
                    meta: option.meta,
                  ),
                )
                .toList(growable: false),
          );
        })
        .toList(growable: false);
  }

  List<_GeneratedCardItem> _mapHistory(List<CardsApiHistoryItem> items) {
    return items
        .map(
          (CardsApiHistoryItem item) => _GeneratedCardItem(
            title: item.title,
            quantity: item.quantity,
            amount: item.amount,
            category: item.category,
            createdAt: item.createdAt,
            businessLabel: item.businessName,
            reference: item.reference,
          ),
        )
        .toList(growable: false);
  }

  _CardMode get _selectedMode {
    return _modes.firstWhere(
      (_CardMode mode) => mode.id == _selectedModeId,
      orElse: () => _modes.isNotEmpty ? _modes.first : _fallbackModes.first,
    );
  }

  _CardOption? get _selectedOption {
    final String? selectedOptionLabel = _selectedOptionLabel;
    if (selectedOptionLabel == null) {
      return null;
    }

    for (final _CardOption option in _selectedMode.options) {
      if (option.label == selectedOptionLabel) {
        return option;
      }
    }
    return null;
  }

  String? _cardOptionMetaText(_CardOption option) {
    if (option.meta.isEmpty) {
      return null;
    }

    final String text = option.meta.entries
        .map((MapEntry<String, dynamic> entry) => entry.value.toString().trim())
        .where((String value) => value.isNotEmpty)
        .join(' • ');

    return text.isEmpty ? null : text;
  }

  Future<void> _openCardOptionSelector() async {
    final _CardMode selectedMode = _selectedMode;
    if (selectedMode.options.isEmpty) {
      return;
    }

    final String? selectedOptionLabel = await showPtsDataSelectPage<String>(
      context: context,
      title: 'Select Option',
      searchHint: 'Enter search content',
      pinnedTitle: 'Popular Options',
      selectedValue: _selectedOptionLabel,
      options: selectedMode.options
          .asMap()
          .entries
          .map((MapEntry<int, _CardOption> entry) {
            final _CardOption option = entry.value;
            final String? subtitle = _cardOptionMetaText(option);
            return PtsDataSelectOption<String>(
              value: option.label,
              title: option.label,
              subtitle: subtitle,
              trailing: _formatCurrency(option.amount),
              searchText:
                  '${option.label} ${subtitle ?? ''} ${option.amount} ${_formatCurrency(option.amount)}',
              pinned: entry.key < 6,
            );
          })
          .toList(growable: false),
      emptyText: 'No option matches your search.',
    );

    if (!mounted || selectedOptionLabel == null) {
      return;
    }

    setState(() {
      _selectedOptionLabel = selectedOptionLabel;
    });
  }

  int get _quantity => int.tryParse(_quantityController.text.trim()) ?? 0;

  double get _totalAmount => (_selectedOption?.amount ?? 0) * _quantity;

  bool get _canGenerate {
    return _selectedOption != null &&
        _quantity > 0 &&
        _businessController.text.trim().isNotEmpty;
  }

  Future<void> _handleBottomNavigation(
    AppBottomNavDestination destination,
  ) async {
    await handleUtilityBottomNavigationTap(context, destination: destination);
  }

  void _applyQuickQuantity(int quantity) {
    final String value = quantity.toString();
    _quantityController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    setState(() {});
  }

  Future<void> _openConfirmationSheet() async {
    final _CardOption? selectedOption = _selectedOption;
    if (!_canGenerate || selectedOption == null) {
      return;
    }

    final bool? shouldContinue = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _CardsConfirmationSheet(
          category: _selectedMode.label,
          option: selectedOption.label,
          quantity: _quantity,
          businessLabel: _businessController.text.trim(),
          totalAmount: _formatCurrency(_totalAmount),
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
    final _CardsResult? result = await showModalBottomSheet<_CardsResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: !_processing,
      builder: (BuildContext context) {
        return _CardsPinSheet(
          onSubmit: (String pin) => _submitGeneration(pin: pin),
          canUseBiometric: settings.biometricUnlockEnabled,
          onBiometricSubmit:
              settings.biometricUnlockEnabled
                  ? _submitGenerationWithBiometric
                  : null,
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    await _openResultSheet(result);
  }

  Future<_CardsResult> _submitGeneration({
    required String pin,
    bool fromBiometric = false,
  }) async {
    final _CardOption? selectedOption = _selectedOption;
    if (_processing || pin.length != 4 || selectedOption == null) {
      return _CardsResult(
        isSuccessful: false,
        category: _selectedMode.label,
        option: selectedOption?.label ?? 'Card request',
        quantity: _quantity <= 0 ? 0 : _quantity,
        businessLabel: _businessController.text.trim(),
        totalAmount: _totalAmount,
        reference: '',
        message: 'Card generation is invalid or already processing.',
      );
    }

    setState(() {
      _processing = true;
    });

    final String? token = await AppSessionService.instance.getApiToken();
    if (token == null || token.isEmpty) {
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
      await _handleUnauthorized();
      return _CardsResult(
        isSuccessful: false,
        category: _selectedMode.label,
        option: selectedOption.label,
        quantity: _quantity,
        businessLabel: _businessController.text.trim(),
        totalAmount: _totalAmount,
        reference: '',
        message: 'Your session has expired. Please sign in again.',
      );
    }

    final CardsGenerateApiResult result = await CardsApiService.instance
        .generate(
          token: token,
          mode: _selectedMode.id,
          optionId: selectedOption.id,
          quantity: _quantity,
          businessName: _businessController.text.trim(),
          pin: pin,
        );

    if (!mounted) {
      return _CardsResult(
        isSuccessful: false,
        category: _selectedMode.label,
        option: selectedOption.label,
        quantity: _quantity,
        businessLabel: _businessController.text.trim(),
        totalAmount: _totalAmount,
        reference: '',
        message: 'The cards page closed before your request completed.',
      );
    }

    if (result.isUnauthorized) {
      setState(() {
        _processing = false;
      });
      await _handleUnauthorized();
      return _CardsResult(
        isSuccessful: false,
        category: _selectedMode.label,
        option: selectedOption.label,
        quantity: _quantity,
        businessLabel: _businessController.text.trim(),
        totalAmount: _totalAmount,
        reference: '',
        message: 'Your session has expired. Please sign in again.',
      );
    }

    if (fromBiometric && result.fieldErrors['pin'] != null) {
      await AppSettingsService.instance.setBiometricUnlockEnabled(false);
      await SecureTransactionPinService.instance.clearPin();
    }

    if (result.isSuccess) {
      final _GeneratedCardItem nextHistory =
          result.historyItem != null
              ? _GeneratedCardItem(
                title: result.historyItem!.title,
                quantity: result.historyItem!.quantity,
                amount: result.historyItem!.amount,
                category: result.historyItem!.category,
                createdAt: result.historyItem!.createdAt,
                businessLabel: result.historyItem!.businessName,
                reference: result.historyItem!.reference,
              )
              : _GeneratedCardItem(
                title: selectedOption.label,
                quantity: _quantity,
                amount: _totalAmount,
                category: _selectedMode.label,
                createdAt: DateTime.now(),
                businessLabel: _businessController.text.trim(),
                reference: '',
              );

      setState(() {
        _processing = false;
        _walletBalance = result.walletBalance;
        _history = <_GeneratedCardItem>[nextHistory, ..._history];
      });

      return _CardsResult(
        isSuccessful: true,
        category: _selectedMode.label,
        option: selectedOption.label,
        quantity: _quantity,
        businessLabel: _businessController.text.trim(),
        totalAmount: _totalAmount,
        reference: nextHistory.reference,
        message: result.message,
      );
    }

    setState(() {
      _processing = false;
    });

    return _CardsResult(
      isSuccessful: false,
      category: _selectedMode.label,
      option: selectedOption.label,
      quantity: _quantity,
      businessLabel: _businessController.text.trim(),
      totalAmount: _totalAmount,
      reference: '',
      message:
          fromBiometric && result.fieldErrors['pin'] != null
              ? 'Your saved fingerprint payment PIN is out of date. Use your transaction PIN and enable fingerprint again in Settings.'
              : (result.fieldErrors['pin'] ??
                  result.fieldErrors['option_id'] ??
                  result.fieldErrors['amount'] ??
                  result.message),
    );
  }

  Future<_CardsPinBiometricResult> _submitGenerationWithBiometric() async {
    final BiometricAuthResult biometricResult =
        await BiometricAuthService.instance.authenticateQuickLogin();
    if (!biometricResult.isSuccess) {
      return _CardsPinBiometricResult.error(
        biometricResult.message ?? 'Biometric payment could not start.',
      );
    }

    final String? storedPin =
        await SecureTransactionPinService.instance.readPin();
    if (storedPin == null || storedPin.length != 4) {
      await AppSettingsService.instance.setBiometricUnlockEnabled(false);
      await SecureTransactionPinService.instance.clearPin();
      return const _CardsPinBiometricResult.error(
        'Fingerprint payment needs to be enabled again in Settings on this device.',
      );
    }

    return _CardsPinBiometricResult.result(
      await _submitGeneration(pin: storedPin, fromBiometric: true),
    );
  }

  Future<void> _openResultSheet(_CardsResult result) async {
    final _CardsResultAction? action =
        await showModalBottomSheet<_CardsResultAction>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (BuildContext context) {
            return _CardsResultSheet(
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
      await _loadOverview(showFailure: false);
      return;
    }

    if (action == _CardsResultAction.retry) {
      await _openConfirmationSheet();
    }
  }

  void _resetFormAfterSuccess() {
    setState(() {
      _selectedOptionLabel = null;
      _quantityController.text = '1';
      _businessController.clear();
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
    final _CardOption? selectedOption = _selectedOption;

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
          'Cards & E-PIN',
          style: TextStyle(
            color: titleColor,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: LayoutBuilder(
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
                      Text(
                        'Create recharge cards, data cards, and exam ePINs for resale or internal distribution from one clean mobile flow.',
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
                                child: _CardsMetricTile(
                                  label: 'Wallet',
                                  value:
                                      _loadingOverview
                                          ? 'Loading...'
                                          : _formatCurrency(_walletBalance),
                                  isDark: isDark,
                                ),
                              ),
                              SizedBox(
                                width: itemWidth,
                                child: _CardsMetricTile(
                                  label: 'Modes',
                                  value: '${_modes.length}',
                                  isDark: isDark,
                                ),
                              ),
                              SizedBox(
                                width: itemWidth,
                                child: _CardsMetricTile(
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
                        'Generate Cards',
                        style: TextStyle(
                          color: titleColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Switch between airtime cards, data cards, and result checker ePINs, then review the request before wallet authorization.',
                        style: TextStyle(
                          color: mutedText,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            _modes.map((_CardMode mode) {
                              final bool active = mode.id == _selectedModeId;

                              return _ModeChip(
                                mode: mode,
                                isDark: isDark,
                                active: active,
                                onTap: () {
                                  setState(() {
                                    _selectedModeId = mode.id;
                                    _selectedOptionLabel = null;
                                  });
                                },
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Select Option *',
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
                          final List<_CardOption> visibleOptions =
                              _selectedMode.options.take(3).toList();
                          final double itemWidth =
                              (constraints.maxWidth - 16) / 3;

                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                visibleOptions
                                    .map(
                                      (_CardOption option) => SizedBox(
                                        width: itemWidth,
                                        child: _OptionTile(
                                          option: option,
                                          isDark: isDark,
                                          selected:
                                              option.label ==
                                              _selectedOptionLabel,
                                          formatter: _formatCurrency,
                                          accent: _selectedMode.accent,
                                          onTap: () {
                                            setState(() {
                                              _selectedOptionLabel =
                                                  option.label;
                                            });
                                          },
                                        ),
                                      ),
                                    )
                                    .toList(),
                          );
                        },
                      ),
                      if (_selectedMode.options.length > 3) ...<Widget>[
                        const SizedBox(height: 12),
                        PtsDataSelectField(
                          placeholder: 'See all options',
                          value:
                              selectedOption == null
                                  ? null
                                  : '${selectedOption.label} • ${_formatCurrency(selectedOption.amount)}',
                          icon: _selectedMode.icon,
                          onTap: _openCardOptionSelector,
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (_) => setState(() {}),
                        decoration: _fieldDecoration(
                          isDark: isDark,
                          mutedText: mutedText,
                          hintText: 'Quantity',
                          prefixIcon: Icon(
                            Icons.format_list_numbered_rounded,
                            size: 18,
                            color: mutedText,
                          ),
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
                                _quickQuantities
                                    .map(
                                      (int quantity) => SizedBox(
                                        width: itemWidth,
                                        child: _QuickQuantityButton(
                                          label: '$quantity pcs',
                                          isDark: isDark,
                                          selected: _quantity == quantity,
                                          onTap:
                                              () =>
                                                  _applyQuickQuantity(quantity),
                                        ),
                                      ),
                                    )
                                    .toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _businessController,
                        onChanged: (_) => setState(() {}),
                        decoration: _fieldDecoration(
                          isDark: isDark,
                          mutedText: mutedText,
                          hintText: 'Business / print label',
                          prefixIcon: Icon(
                            Icons.business_center_rounded,
                            size: 18,
                            color: mutedText,
                          ),
                        ),
                      ),
                      if (selectedOption != null && _quantity > 0) ...<Widget>[
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
                              _CardsBreakdownRow(
                                label: 'Category',
                                value: _selectedMode.label,
                                valueColor: titleColor,
                                isDark: isDark,
                              ),
                              const SizedBox(height: 10),
                              _CardsBreakdownRow(
                                label: 'Selected Option',
                                value: selectedOption.label,
                                valueColor: titleColor,
                                isDark: isDark,
                              ),
                              const SizedBox(height: 10),
                              _CardsBreakdownRow(
                                label: 'Quantity',
                                value: '$_quantity pcs',
                                valueColor: titleColor,
                                isDark: isDark,
                              ),
                              const SizedBox(height: 10),
                              _CardsBreakdownRow(
                                label: 'Business Label',
                                value:
                                    _businessController.text.trim().isEmpty
                                        ? 'Not added yet'
                                        : _businessController.text.trim(),
                                valueColor: titleColor,
                                isDark: isDark,
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                child: Divider(height: 1),
                              ),
                              _CardsBreakdownRow(
                                label: 'Total',
                                value: _formatCurrency(_totalAmount),
                                valueColor: _primary,
                                emphasize: true,
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _canGenerate ? _openConfirmationSheet : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 12.8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        icon: const Icon(Icons.credit_card_rounded, size: 18),
                        label: const Text('Generate Now'),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: panelColor,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color:
                                isDark ? const Color(0xFF3A4054) : _softBorder,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Text(
                              'Generation History',
                              style: TextStyle(
                                color: titleColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Latest card and ePIN generation records from your account.',
                              style: TextStyle(
                                color: mutedText,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_history.isEmpty)
                              Text(
                                _loadingOverview
                                    ? 'Loading generation history...'
                                    : 'No card generation history yet.',
                                style: TextStyle(
                                  color: mutedText,
                                  fontSize: 11.8,
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            else
                              ..._history.map((_GeneratedCardItem item) {
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: item == _history.last ? 0 : 12,
                                  ),
                                  child: _HistoryCard(
                                    item: item,
                                    isDark: isDark,
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

class _CardsMetricTile extends StatelessWidget {
  const _CardsMetricTile({
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

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.mode,
    required this.isDark,
    required this.active,
    required this.onTap,
  });

  final _CardMode mode;
  final bool isDark;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color:
              active
                  ? mode.accent.withValues(alpha: 0.12)
                  : (isDark ? _darkPanel : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                active
                    ? mode.accent
                    : (isDark ? const Color(0xFF3A4054) : _softBorder),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(mode.icon, size: 16, color: active ? mode.accent : titleColor),
            const SizedBox(width: 8),
            Text(
              mode.label,
              style: TextStyle(
                color: active ? mode.accent : titleColor,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.isDark,
    required this.selected,
    required this.formatter,
    required this.accent,
    required this.onTap,
  });

  final _CardOption option;
  final bool isDark;
  final bool selected;
  final String Function(num amount) formatter;
  final Color accent;
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
                    ? accent.withValues(alpha: isDark ? 0.18 : 0.10)
                    : (isDark ? _darkPanel : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  selected
                      ? accent
                      : (isDark ? const Color(0xFF3A4054) : _softBorder),
              width: selected ? 1.3 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                option.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 11.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatter(option.amount),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? accent : mutedText,
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

class _QuickQuantityButton extends StatelessWidget {
  const _QuickQuantityButton({
    required this.label,
    required this.isDark,
    required this.selected,
    required this.onTap,
  });

  final String label;
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
      child: Text(label),
    );
  }
}

class _CardsBreakdownRow extends StatelessWidget {
  const _CardsBreakdownRow({
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
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor,
              fontSize: emphasize ? 13 : 12,
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _CardsConfirmationSheet extends StatelessWidget {
  const _CardsConfirmationSheet({
    required this.category,
    required this.option,
    required this.quantity,
    required this.businessLabel,
    required this.totalAmount,
  });

  final String category;
  final String option;
  final int quantity;
  final String businessLabel;
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
                      'Confirm Card Generation',
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
                'Review this generation request before entering your payment PIN.',
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
                      label: 'Category',
                      value: category,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _CompactSummaryTile(
                      label: 'Quantity',
                      value: '$quantity pcs',
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
                      label: 'Option',
                      value: option,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _CompactSummaryTile(
                      label: 'Business',
                      value: businessLabel,
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

class _CardsPinSheet extends StatefulWidget {
  const _CardsPinSheet({
    required this.onSubmit,
    required this.canUseBiometric,
    this.onBiometricSubmit,
  });

  final Future<_CardsResult> Function(String pin) onSubmit;
  final bool canUseBiometric;
  final Future<_CardsPinBiometricResult> Function()? onBiometricSubmit;

  @override
  State<_CardsPinSheet> createState() => _CardsPinSheetState();
}

class _CardsPinSheetState extends State<_CardsPinSheet> {
  String _pin = '';
  bool _processing = false;
  String? _errorText;

  void _appendDigit(String digit) {
    if (_processing || _pin.length >= 4) {
      return;
    }

    setState(() {
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
    _CardsResult? submitResult;

    setState(() {
      _processing = true;
    });

    showPtsDataLoaderDialog<void>(
      context,
      text: 'Generating cards...',
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
        _errorText = 'We could not complete this request right now.';
      });
      return;
    }

    Navigator.of(context).pop(submitResult);
  }

  Future<void> _submitBiometric() async {
    final Future<_CardsPinBiometricResult> Function()? onBiometricSubmit =
        widget.onBiometricSubmit;
    if (_processing || onBiometricSubmit == null) {
      return;
    }

    setState(() {
      _processing = true;
      _errorText = null;
    });

    final _CardsPinBiometricResult action = await onBiometricSubmit();
    if (!mounted) {
      return;
    }

    final _CardsResult? result = action.result;
    if (result != null) {
      setState(() {
        _processing = false;
      });
      Navigator.of(context).pop(result);
      return;
    }

    setState(() {
      _processing = false;
      _errorText =
          action.errorMessage ?? 'We could not complete biometric payment.';
    });
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
                                  fontWeight: FontWeight.w800,
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
                                ? 'Generating cards...'
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

enum _CardsResultAction { close, retry }

class _CardsResultSheet extends StatelessWidget {
  const _CardsResultSheet({required this.result, required this.formatter});

  final _CardsResult result;
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
    final double sheetHeight = MediaQuery.sizeOf(context).height * 0.88;
    final Widget actionSection =
        result.isSuccessful
            ? FilledButton.icon(
              onPressed:
                  () => Navigator.of(context).pop(_CardsResultAction.close),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              icon: const Icon(Icons.check_circle_rounded, size: 18),
              label: const Text('Done'),
            )
            : Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        () =>
                            Navigator.of(context).pop(_CardsResultAction.close),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: titleColor,
                      side: BorderSide(
                        color:
                            isDark
                                ? const Color(0xFF374151)
                                : const Color(0xFFC7CDDC),
                      ),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed:
                        () =>
                            Navigator.of(context).pop(_CardsResultAction.retry),
                    style: FilledButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.20),
                blurRadius: 30,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
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
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed:
                        () =>
                            Navigator.of(context).pop(_CardsResultAction.close),
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.close_rounded, color: mutedText),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: accentTint,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    result.isSuccessful ? 'Successful' : 'Failed',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    Container(
                      width: 118,
                      height: 118,
                      decoration: BoxDecoration(
                        color: accentTint,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.34),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(statusIcon, color: Colors.white, size: 36),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  result.isSuccessful
                      ? 'Generation Successful!'
                      : 'Generation Failed',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  result.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: mutedText,
                    fontSize: 12.4,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? _darkPanel : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color:
                          isDark
                              ? const Color(0xFF3A4054)
                              : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Column(
                    children: <Widget>[
                      _ResultSummaryRow(
                        label: 'Category',
                        value: result.category,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                      _ResultSummaryRow(
                        label: 'Option',
                        value: result.option,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                      _ResultSummaryRow(
                        label: 'Quantity',
                        value: '${result.quantity} pcs',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                      _ResultSummaryRow(
                        label: 'Business',
                        value: result.businessLabel,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                      _ResultSummaryRow(
                        label: 'Reference',
                        value: result.reference,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color: accentTint,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                'Total',
                                style: TextStyle(
                                  color: mutedText,
                                  fontSize: 11.8,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              formatter(result.totalAmount),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
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
              fontSize: 11.5,
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
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.item,
    required this.isDark,
    required this.formatter,
    required this.dateFormatter,
  });

  final _GeneratedCardItem item;
  final bool isDark;
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
            backgroundColor: _primary.withValues(alpha: 0.12),
            child: const Icon(
              Icons.credit_card_rounded,
              color: _primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.category} • ${item.quantity} pcs • ${dateFormatter(item.createdAt)}',
                  style: TextStyle(
                    color: mutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            formatter(item.amount),
            style: const TextStyle(
              color: _primary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardMode {
  const _CardMode({
    required this.id,
    required this.label,
    required this.icon,
    required this.accent,
    required this.options,
  });

  final String id;
  final String label;
  final IconData icon;
  final Color accent;
  final List<_CardOption> options;
}

class _CardOption {
  const _CardOption({
    required this.id,
    required this.label,
    required this.amount,
    this.meta = const <String, dynamic>{},
  });

  final String id;
  final String label;
  final double amount;
  final Map<String, dynamic> meta;
}

class _GeneratedCardItem {
  const _GeneratedCardItem({
    required this.title,
    required this.quantity,
    required this.amount,
    required this.category,
    required this.createdAt,
    this.businessLabel = '',
    this.reference = '',
  });

  final String title;
  final int quantity;
  final double amount;
  final String category;
  final DateTime createdAt;
  final String businessLabel;
  final String reference;
}

class _CardsPinBiometricResult {
  const _CardsPinBiometricResult.result(this.result) : errorMessage = null;

  const _CardsPinBiometricResult.error(this.errorMessage) : result = null;

  final _CardsResult? result;
  final String? errorMessage;
}

class _CardsResult {
  const _CardsResult({
    required this.isSuccessful,
    required this.category,
    required this.option,
    required this.quantity,
    required this.businessLabel,
    required this.totalAmount,
    required this.reference,
    required this.message,
  });

  final bool isSuccessful;
  final String category;
  final String option;
  final int quantity;
  final String businessLabel;
  final double totalAmount;
  final String reference;
  final String message;
}

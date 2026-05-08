import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/auth/app_session_service.dart';
import '../../../../core/auth/biometric_auth_service.dart';
import '../../../../core/auth/secure_transaction_pin_service.dart';
import '../../../../core/settings/app_settings_service.dart';
import '../../data/data_api_service.dart';
import '../../../dashboard/data/dashboard_api_service.dart';
import '../../../navigation/presentation/widgets/app_bottom_navigation.dart';
import '../../../shared/presentation/widgets/network_logo_badge.dart';
import '../../../shared/presentation/widgets/pts_data_loader_overlay.dart';
import '../../../shared/presentation/widgets/pts_data_select_page.dart';

const Color _primary = Color(0xFFB89CFF);
const Color _primaryDark = Color(0xFF7FA0F5);
const Color _softTint = Color(0xFFF3F4F6);
const Color _softBorder = Color(0xFFE5E7EB);
const Color _darkBackground = Color(0xFF171925);
const Color _darkSurface = Color(0xFF22263A);
const Color _darkPanel = Color(0xFF252A42);
const Color _darkMuted = Color(0xFFC7CDDC);

class BuyDataPage extends StatefulWidget {
  const BuyDataPage({super.key});

  @override
  State<BuyDataPage> createState() => _BuyDataPageState();
}

class _BuyDataPageState extends State<BuyDataPage> {
  static const List<_DataNetworkOption> _fallbackNetworkOptions =
      <_DataNetworkOption>[
        _DataNetworkOption(
          id: '1',
          name: 'MTN',
          shortName: 'MTN',
          assetPath: 'assets/images/mtn_logo.jpeg',
          brandColor: Color(0xFFFACC15),
          foregroundColor: Color(0xFF111827),
          dataTypes: <_DataTypeOption>[
            _DataTypeOption(
              key: 'SME',
              label: 'SME',
              plans: <_DataPlan>[
                _DataPlan(
                  id: 'mtn-sme-1',
                  name: '500MB',
                  validity: '30 days',
                  amount: 500,
                ),
                _DataPlan(
                  id: 'mtn-sme-2',
                  name: '1GB',
                  validity: '30 days',
                  amount: 950,
                ),
                _DataPlan(
                  id: 'mtn-sme-3',
                  name: '2GB',
                  validity: '30 days',
                  amount: 1850,
                ),
                _DataPlan(
                  id: 'mtn-sme-4',
                  name: '5GB',
                  validity: '30 days',
                  amount: 4550,
                ),
              ],
            ),
            _DataTypeOption(
              key: 'GIFTING',
              label: 'Gifting',
              plans: <_DataPlan>[
                _DataPlan(
                  id: 'mtn-gift-1',
                  name: '1.5GB',
                  validity: '30 days',
                  amount: 1200,
                ),
                _DataPlan(
                  id: 'mtn-gift-2',
                  name: '3GB',
                  validity: '30 days',
                  amount: 2300,
                ),
                _DataPlan(
                  id: 'mtn-gift-3',
                  name: '10GB',
                  validity: '30 days',
                  amount: 5200,
                ),
              ],
            ),
          ],
        ),
        _DataNetworkOption(
          id: '2',
          name: 'GLO',
          shortName: 'GLO',
          assetPath: 'assets/images/Glo_logo.png',
          brandColor: Color(0xFF16A34A),
          foregroundColor: Colors.white,
          dataTypes: <_DataTypeOption>[
            _DataTypeOption(
              key: 'SME',
              label: 'SME',
              plans: <_DataPlan>[
                _DataPlan(
                  id: 'glo-sme-1',
                  name: '1GB',
                  validity: '30 days',
                  amount: 980,
                ),
                _DataPlan(
                  id: 'glo-sme-2',
                  name: '2.5GB',
                  validity: '30 days',
                  amount: 1900,
                ),
                _DataPlan(
                  id: 'glo-sme-3',
                  name: '5GB',
                  validity: '30 days',
                  amount: 3600,
                ),
              ],
            ),
            _DataTypeOption(
              key: 'GIFTING',
              label: 'Gifting',
              plans: <_DataPlan>[
                _DataPlan(
                  id: 'glo-gift-1',
                  name: '1.8GB',
                  validity: '14 days',
                  amount: 1000,
                ),
                _DataPlan(
                  id: 'glo-gift-2',
                  name: '5.8GB',
                  validity: '30 days',
                  amount: 2600,
                ),
                _DataPlan(
                  id: 'glo-gift-3',
                  name: '7.7GB',
                  validity: '30 days',
                  amount: 3100,
                ),
              ],
            ),
          ],
        ),
        _DataNetworkOption(
          id: '3',
          name: '9MOBILE',
          shortName: '9M',
          assetPath: 'assets/images/9mobile-1.svg',
          brandColor: Color(0xFF10B981),
          foregroundColor: Colors.white,
          dataTypes: <_DataTypeOption>[
            _DataTypeOption(
              key: 'SME',
              label: 'SME',
              plans: <_DataPlan>[
                _DataPlan(
                  id: '9m-sme-1',
                  name: '500MB',
                  validity: '30 days',
                  amount: 500,
                ),
                _DataPlan(
                  id: '9m-sme-2',
                  name: '1.5GB',
                  validity: '30 days',
                  amount: 1150,
                ),
                _DataPlan(
                  id: '9m-sme-3',
                  name: '3GB',
                  validity: '30 days',
                  amount: 2200,
                ),
              ],
            ),
            _DataTypeOption(
              key: 'CORPORATE',
              label: 'Corporate',
              plans: <_DataPlan>[
                _DataPlan(
                  id: '9m-corp-1',
                  name: '2GB',
                  validity: '30 days',
                  amount: 1700,
                ),
                _DataPlan(
                  id: '9m-corp-2',
                  name: '4.5GB',
                  validity: '30 days',
                  amount: 3400,
                ),
              ],
            ),
          ],
        ),
        _DataNetworkOption(
          id: '4',
          name: 'AIRTEL',
          shortName: 'ATL',
          assetPath: 'assets/images/Airtel_logo-01.png',
          brandColor: Color(0xFFEF4444),
          foregroundColor: Colors.white,
          dataTypes: <_DataTypeOption>[
            _DataTypeOption(
              key: 'SME',
              label: 'SME',
              plans: <_DataPlan>[
                _DataPlan(
                  id: 'air-sme-1',
                  name: '500MB',
                  validity: '30 days',
                  amount: 500,
                ),
                _DataPlan(
                  id: 'air-sme-2',
                  name: '1GB',
                  validity: '30 days',
                  amount: 980,
                ),
                _DataPlan(
                  id: 'air-sme-3',
                  name: '2GB',
                  validity: '30 days',
                  amount: 1900,
                ),
                _DataPlan(
                  id: 'air-sme-4',
                  name: '10GB',
                  validity: '30 days',
                  amount: 5000,
                ),
              ],
            ),
            _DataTypeOption(
              key: 'GIFTING',
              label: 'Gifting',
              plans: <_DataPlan>[
                _DataPlan(
                  id: 'air-gift-1',
                  name: '1.5GB',
                  validity: '30 days',
                  amount: 1200,
                ),
                _DataPlan(
                  id: 'air-gift-2',
                  name: '6GB',
                  validity: '30 days',
                  amount: 2950,
                ),
                _DataPlan(
                  id: 'air-gift-3',
                  name: '15GB',
                  validity: '30 days',
                  amount: 6200,
                ),
              ],
            ),
          ],
        ),
      ];
  static const List<_DataRecipient> _initialRecipients = <_DataRecipient>[
    _DataRecipient(phoneNumber: '08031234567', networkId: '1', usageCount: 4),
    _DataRecipient(phoneNumber: '07041234567', networkId: '2', usageCount: 2),
    _DataRecipient(phoneNumber: '09091234567', networkId: '3', usageCount: 3),
    _DataRecipient(phoneNumber: '08151234567', networkId: '4', usageCount: 1),
  ];

  final TextEditingController _phoneController = TextEditingController();

  late List<_DataNetworkOption> _networkOptions;
  late List<_DataRecipient> _recentRecipients;

  double _walletBalance = 0;
  String? _selectedNetworkId;
  String? _selectedTypeKey;
  String? _selectedPlanId;
  bool _isLoadingWalletBalance = true;
  bool _isLoadingCatalog = true;
  bool _saveRecipient = true;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _networkOptions = List<_DataNetworkOption>.from(_fallbackNetworkOptions);
    _recentRecipients = List<_DataRecipient>.from(_initialRecipients);
    _loadWalletBalance();
    _loadDataCatalog();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String get _phoneNumber => _phoneController.text.trim();

  bool get _hasValidPhone =>
      _phoneNumber.length >= 10 && _phoneNumber.length <= 15;

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

  Future<void> _loadDataCatalog() async {
    final String? token = await AppSessionService.instance.getApiToken();
    if (token == null || token.isEmpty) {
      if (!mounted) {
        return;
      }

      setState(() => _isLoadingCatalog = false);
      return;
    }

    final DataCatalogApiResult result = await DataApiService.instance
        .fetchCatalog(token: token, recipientLimit: 8);
    if (!mounted) {
      return;
    }

    if (result.isUnauthorized) {
      setState(() => _isLoadingCatalog = false);
      await _handleUnauthorized();
      return;
    }

    if (result.isSuccess) {
      setState(() {
        _networkOptions = _mapCatalogNetworks(result.networks);
        _recentRecipients = _mapSavedRecipients(result.recentRecipients);
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

  Future<void> _loadSavedRecipients({
    int limit = 50,
    bool showError = true,
  }) async {
    final String? token = await AppSessionService.instance.getApiToken();
    if (token == null || token.isEmpty) {
      return;
    }

    final DataRecipientsApiResult result = await DataApiService.instance
        .fetchRecipients(token: token, limit: limit);
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

    if (showError && result.message != null && result.message!.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message!)));
    }
  }

  List<_DataNetworkOption> _mapCatalogNetworks(List<DataApiNetwork> networks) {
    if (networks.isEmpty) {
      return List<_DataNetworkOption>.from(_fallbackNetworkOptions);
    }

    return networks
        .map((DataApiNetwork network) {
          final _DataNetworkOption visual = _fallbackVisualForNetwork(network);

          return _DataNetworkOption(
            id: network.networkId,
            name: network.networkName,
            shortName: visual.shortName,
            assetPath: visual.assetPath,
            brandColor: visual.brandColor,
            foregroundColor: visual.foregroundColor,
            purchaseNetworkId: network.purchaseNetworkId,
            dataTypes: network.types
                .map(
                  (DataApiType type) => _DataTypeOption(
                    key: type.key,
                    label: type.label,
                    plans: type.plans
                        .map(
                          (DataApiPlan plan) => _DataPlan(
                            id: plan.id,
                            dataPlanId: plan.dataPlanId,
                            name: plan.name,
                            validity: plan.validity,
                            amount: plan.amount,
                          ),
                        )
                        .toList(growable: false),
                  ),
                )
                .toList(growable: false),
          );
        })
        .toList(growable: false);
  }

  List<_DataRecipient> _mapSavedRecipients(
    List<DataSavedRecipient> recipients,
  ) {
    if (recipients.isEmpty) {
      return <_DataRecipient>[];
    }

    return recipients
        .map(
          (DataSavedRecipient recipient) => _DataRecipient(
            phoneNumber: recipient.phoneNumber,
            networkId: recipient.networkId,
            usageCount: recipient.usageCount,
          ),
        )
        .toList(growable: false);
  }

  _DataNetworkOption _fallbackVisualForNetwork(DataApiNetwork network) {
    for (final _DataNetworkOption option in _fallbackNetworkOptions) {
      if (option.id == network.networkId ||
          option.name.toUpperCase() == network.networkName.toUpperCase()) {
        return option;
      }
    }

    return _fallbackNetworkOptions.first;
  }

  _DataNetworkOption? get _selectedNetwork {
    final String? networkId = _selectedNetworkId;
    if (networkId == null) {
      return null;
    }

    for (final _DataNetworkOption option in _networkOptions) {
      if (option.id == networkId) {
        return option;
      }
    }

    return null;
  }

  _DataTypeOption? get _selectedType {
    final _DataNetworkOption? network = _selectedNetwork;
    final String? typeKey = _selectedTypeKey;
    if (network == null || typeKey == null) {
      return null;
    }

    for (final _DataTypeOption type in network.dataTypes) {
      if (type.key == typeKey) {
        return type;
      }
    }

    return null;
  }

  _DataPlan? get _selectedPlan {
    final _DataTypeOption? type = _selectedType;
    final String? planId = _selectedPlanId;
    if (type == null || planId == null) {
      return null;
    }

    for (final _DataPlan plan in type.plans) {
      if (plan.id == planId) {
        return plan;
      }
    }

    return null;
  }

  List<_DataPlan> get _quickPlans {
    final _DataTypeOption? type = _selectedType;
    if (type == null) {
      return <_DataPlan>[];
    }

    return type.plans.take(4).toList();
  }

  bool get _canContinue =>
      !_isLoadingWalletBalance &&
      !_isLoadingCatalog &&
      _selectedNetwork != null &&
      _selectedType != null &&
      _selectedPlan != null &&
      _hasValidPhone;

  void _selectNetwork(String networkId) {
    setState(() {
      _selectedNetworkId = networkId;
      _selectedTypeKey = null;
      _selectedPlanId = null;
    });
  }

  Future<void> _openDataPlanSelector(_DataTypeOption type) async {
    if (type.plans.isEmpty) {
      return;
    }

    final String? selectedPlanId = await showPtsDataSelectPage<String>(
      context: context,
      title: 'Select Data Plan',
      searchHint: 'Enter search content',
      pinnedTitle: 'Popular Plans',
      selectedValue: _selectedPlanId,
      options: type.plans
          .asMap()
          .entries
          .map((MapEntry<int, _DataPlan> entry) {
            final _DataPlan plan = entry.value;
            return PtsDataSelectOption<String>(
              value: plan.id,
              title: plan.name,
              subtitle: plan.validity,
              trailing: _formatCurrency(plan.amount),
              searchText:
                  '${plan.name} ${plan.validity} ${plan.amount} ${_formatCurrency(plan.amount)}',
              pinned: entry.key < 6,
            );
          })
          .toList(growable: false),
      emptyText: 'No data plan matches your search.',
    );

    if (!mounted || selectedPlanId == null) {
      return;
    }

    setState(() {
      _selectedPlanId = selectedPlanId;
    });
  }

  Future<void> _handleBottomNavigation(
    AppBottomNavDestination destination,
  ) async {
    await handleAppBottomNavigationTap(
      context,
      destination: destination,
      currentDestination: AppBottomNavDestination.data,
    );
  }

  void _pickRecipient(_DataRecipient recipient) {
    _phoneController.value = TextEditingValue(
      text: recipient.phoneNumber,
      selection: TextSelection.collapsed(offset: recipient.phoneNumber.length),
    );
    setState(() {
      _selectedNetworkId = recipient.networkId;
      _selectedTypeKey = null;
      _selectedPlanId = null;
    });
  }

  Future<void> _openAllRecipientsSheet() async {
    await _loadSavedRecipients(limit: 50, showError: false);
    if (!mounted) {
      return;
    }
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final _DataRecipient? selected = await showModalBottomSheet<_DataRecipient>(
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
              color: isDark ? _darkSurface : Colors.white,
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
                                  'Tap any recipient to use it for data.',
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
                      final _DataRecipient recipient = _recentRecipients[index];
                      final _DataNetworkOption network = _networkForRecipient(
                        recipient.networkId,
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

  _DataNetworkOption _networkForRecipient(String networkId) {
    for (final _DataNetworkOption option in _networkOptions) {
      if (option.id == networkId) {
        return option;
      }
    }

    for (final _DataNetworkOption option in _fallbackNetworkOptions) {
      if (option.id == networkId) {
        return option;
      }
    }

    return _fallbackNetworkOptions.first;
  }

  Future<void> _openConfirmationSheet() async {
    final _DataNetworkOption? network = _selectedNetwork;
    final _DataPlan? plan = _selectedPlan;
    if (!_canContinue || network == null || plan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Select a network, plan type, data plan, and phone number first.',
          ),
        ),
      );
      return;
    }

    final bool? saveRecipient = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _DataConfirmationSheet(
          amountPaid: _formatCurrency(plan.amount),
          networkName: network.name,
          phoneNumber: _phoneNumber,
          planName: plan.name,
          validity: plan.validity,
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

    final _DataResult? result = await showModalBottomSheet<_DataResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: !_processing,
      builder: (BuildContext context) {
        return _DataPinSheet(
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

  Future<_DataPinSheetActionResult> _submitPurchase({
    required String pin,
    bool fromBiometric = false,
  }) async {
    final _DataPlan? plan = _selectedPlan;
    final _DataNetworkOption? network = _selectedNetwork;
    if (!_canContinue ||
        _processing ||
        pin.length != 4 ||
        plan == null ||
        network == null) {
      return const _DataPinSheetActionResult.error(
        'Complete the data form and confirm a valid 4-digit PIN.',
      );
    }

    setState(() {
      _processing = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) {
      return const _DataPinSheetActionResult.error(
        'The data page closed before the purchase could finish.',
      );
    }

    final String? token = await AppSessionService.instance.getApiToken();
    if (token == null || token.isEmpty) {
      setState(() {
        _processing = false;
      });
      await _handleUnauthorized();
      return const _DataPinSheetActionResult.error(
        'Your session has expired. Please sign in again.',
      );
    }

    final DataPurchaseApiResult result = await DataApiService.instance
        .purchaseData(
          token: token,
          networkId: network.purchaseNetworkId,
          dataType: _selectedType?.key ?? '',
          dataPlanId: plan.dataPlanId,
          phoneNumber: _phoneNumber,
          amount: plan.amount,
          validity: plan.validity,
          saveRecipient: _saveRecipient,
          pin: pin,
        );

    if (!mounted) {
      return const _DataPinSheetActionResult.error(
        'The data page closed before the purchase could finish.',
      );
    }

    if (result.isUnauthorized) {
      setState(() {
        _processing = false;
      });
      await _handleUnauthorized();
      return const _DataPinSheetActionResult.error(
        'Your session has expired. Please sign in again.',
      );
    }

    if (fromBiometric && result.fieldErrors['pin'] != null) {
      await AppSettingsService.instance.setBiometricUnlockEnabled(false);
      await SecureTransactionPinService.instance.clearPin();
    }

    final bool success = result.isSuccess;
    final _DataResult nextResult = _DataResult(
      isSuccessful: success,
      networkName: network.name,
      phoneNumber: _phoneNumber,
      planName: plan.name,
      validity: plan.validity,
      amountPaid: plan.amount,
      reference:
          result.reference.isNotEmpty
              ? result.reference
              : 'DAT-${DateTime.now().millisecondsSinceEpoch}',
      message:
          fromBiometric && result.fieldErrors['pin'] != null
              ? 'Your saved fingerprint payment PIN is out of date. Use your transaction PIN and enable fingerprint again in Settings.'
              : success
              ? (result.message ??
                  'Your data purchase was completed successfully.')
              : (result.fieldErrors['pin'] ??
                  result.fieldErrors['data_plan'] ??
                  result.fieldErrors['validity'] ??
                  result.message ??
                  'Unable to complete this data purchase right now.'),
    );

    if (success) {
      final double nextBalance = (_walletBalance - plan.amount).clamp(
        0,
        double.infinity,
      );
      final List<_DataRecipient> nextRecipients =
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

    return _DataPinSheetActionResult.result(nextResult);
  }

  Future<_DataPinSheetActionResult> _submitPurchaseWithBiometric() async {
    final BiometricAuthResult biometricResult =
        await BiometricAuthService.instance.authenticateQuickLogin();
    if (!biometricResult.isSuccess) {
      return _DataPinSheetActionResult.error(
        biometricResult.message ?? 'Biometric payment could not start.',
      );
    }

    final String? storedPin =
        await SecureTransactionPinService.instance.readPin();
    if (storedPin == null || storedPin.length != 4) {
      await AppSettingsService.instance.setBiometricUnlockEnabled(false);
      await SecureTransactionPinService.instance.clearPin();
      return const _DataPinSheetActionResult.error(
        'Fingerprint payment needs to be enabled again in Settings on this device.',
      );
    }

    return _submitPurchase(pin: storedPin, fromBiometric: true);
  }

  Future<void> _openResultSheet(_DataResult result) async {
    final _DataResultAction? action =
        await showModalBottomSheet<_DataResultAction>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (BuildContext context) {
            return _DataResultSheet(result: result, formatter: _formatCurrency);
          },
        );

    if (!mounted) {
      return;
    }

    if (result.isSuccessful) {
      _resetFormAfterSuccess();
      return;
    }

    if (action == _DataResultAction.retry) {
      await _openConfirmationSheet();
    }
  }

  void _resetFormAfterSuccess() {
    setState(() {
      _selectedNetworkId = null;
      _selectedTypeKey = null;
      _selectedPlanId = null;
      _phoneController.clear();
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
    final Color inputColor = isDark ? _darkPanel : const Color(0xFFF8FAFC);
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);
    final Color mutedText = isDark ? _darkMuted : const Color(0xFF4B5563);
    final _DataNetworkOption? network = _selectedNetwork;
    final _DataTypeOption? type = _selectedType;
    final _DataPlan? plan = _selectedPlan;

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
          'Buy Data',
          style: TextStyle(
            color: titleColor,
            fontSize: 17,
            fontWeight: FontWeight.w700,
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
                        'Choose a network, plan type, and bundle for instant activation.',
                        style: TextStyle(
                          color: mutedText,
                          fontSize: 12.2,
                          fontWeight: FontWeight.w500,
                          height: 1.45,
                        ),
                      ),
                      if (_isLoadingCatalog) ...<Widget>[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: const LinearProgressIndicator(minHeight: 4),
                        ),
                      ],
                      const SizedBox(height: 14),
                      LayoutBuilder(
                        builder: (
                          BuildContext context,
                          BoxConstraints constraints,
                        ) {
                          final double itemWidth =
                              (constraints.maxWidth - 16) / 3;
                          final int typeCount = network?.dataTypes.length ?? 2;

                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[
                              SizedBox(
                                width: itemWidth,
                                child: _DataInfoTile(
                                  label: 'Networks',
                                  value: '${_networkOptions.length}',
                                  isDark: isDark,
                                ),
                              ),
                              SizedBox(
                                width: itemWidth,
                                child: _DataInfoTile(
                                  label: 'Plan Types',
                                  value: '$typeCount',
                                  isDark: isDark,
                                ),
                              ),
                              SizedBox(
                                width: itemWidth,
                                child: _DataInfoTile(
                                  label: 'Checkout',
                                  value: 'PIN',
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
                          final _DataNetworkOption option =
                              _networkOptions[index];
                          return _DataNetworkTile(
                            option: option,
                            isDark: isDark,
                            selected: option.id == _selectedNetworkId,
                            onTap: () => _selectNetwork(option.id),
                          );
                        },
                      ),
                      if (network != null) ...<Widget>[
                        const SizedBox(height: 18),
                        Text(
                          'Select Data Type *',
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              network.dataTypes
                                  .map(
                                    (_DataTypeOption option) => _DataTypeChip(
                                      label: option.label,
                                      selected: option.key == _selectedTypeKey,
                                      isDark: isDark,
                                      onTap: () {
                                        setState(() {
                                          _selectedTypeKey = option.key;
                                          _selectedPlanId = null;
                                        });
                                      },
                                    ),
                                  )
                                  .toList(),
                        ),
                      ],
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
                        decoration: _fieldDecoration(
                          isDark: isDark,
                          mutedText: mutedText,
                          hintText: '08012345678',
                          prefixIcon: Icon(
                            Icons.call_rounded,
                            size: 18,
                            color: mutedText,
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
                                            _DataRecipient recipient,
                                          ) => _DataRecipientChip(
                                            recipient: recipient,
                                            isDark: isDark,
                                            network: _networkForRecipient(
                                              recipient.networkId,
                                            ),
                                            onTap:
                                                () => _pickRecipient(recipient),
                                          ),
                                        )
                                        .toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (type != null) ...<Widget>[
                        const SizedBox(height: 18),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                'Select Data Plan *',
                                style: TextStyle(
                                  color: titleColor,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              type.label,
                              style: TextStyle(
                                color: mutedText,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (_quickPlans.isNotEmpty) ...<Widget>[
                          Text(
                            'Quick Select',
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          LayoutBuilder(
                            builder: (
                              BuildContext context,
                              BoxConstraints constraints,
                            ) {
                              final double itemWidth =
                                  (constraints.maxWidth - 8) / 2;
                              return Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children:
                                    _quickPlans
                                        .map(
                                          (_DataPlan quickPlan) => SizedBox(
                                            width: itemWidth,
                                            child: _QuickPlanCard(
                                              plan: quickPlan,
                                              isDark: isDark,
                                              selected:
                                                  _selectedPlanId ==
                                                  quickPlan.id,
                                              formatter: _formatCurrency,
                                              onTap: () {
                                                setState(() {
                                                  _selectedPlanId =
                                                      quickPlan.id;
                                                });
                                              },
                                            ),
                                          ),
                                        )
                                        .toList(),
                              );
                            },
                          ),
                          const SizedBox(height: 14),
                        ],
                        Text(
                          type.plans.length > 4
                              ? 'Or choose from all plans'
                              : 'Choose data plan',
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        PtsDataSelectField(
                          placeholder: 'Select data plan',
                          value:
                              plan == null
                                  ? null
                                  : '${plan.name} • ${_formatCurrency(plan.amount)}',
                          icon: Icons.list_alt_rounded,
                          onTap: () => _openDataPlanSelector(type),
                        ),
                      ],
                      if (plan != null) ...<Widget>[
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
                                      ? _primary.withValues(alpha: 0.18)
                                      : _softBorder,
                            ),
                          ),
                          child: Column(
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          'Selected Plan',
                                          style: TextStyle(
                                            color:
                                                isDark
                                                    ? const Color(0xFFF3F4F6)
                                                    : const Color(0xFF374151),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          plan.name,
                                          style: TextStyle(
                                            color:
                                                isDark
                                                    ? const Color(0xFFF8FAFC)
                                                    : const Color(0xFF0F172A),
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '${network?.name ?? ''} • ${plan.validity}',
                                          style: TextStyle(
                                            color:
                                                isDark
                                                    ? const Color(0xFFD1D5DB)
                                                    : const Color(0xFF7FA0F5),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: <Widget>[
                                      Text(
                                        'Amount',
                                        style: TextStyle(
                                          color:
                                              isDark
                                                  ? const Color(0xFFF3F4F6)
                                                  : const Color(0xFF374151),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        _formatCurrency(plan.amount),
                                        style: TextStyle(
                                          color:
                                              isDark
                                                  ? const Color(0xFFF8FAFC)
                                                  : _primaryDark,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: _canContinue ? _openConfirmationSheet : null,
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
                        icon: const Icon(Icons.wifi_rounded, size: 18),
                        label: const Text('Buy Data Now'),
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
        selectedDestination: AppBottomNavDestination.data,
        onSelect: _handleBottomNavigation,
      ),
    );
  }
}

class _DataInfoTile extends StatelessWidget {
  const _DataInfoTile({
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

class _DataNetworkTile extends StatelessWidget {
  const _DataNetworkTile({
    required this.option,
    required this.isDark,
    required this.selected,
    required this.onTap,
  });

  final _DataNetworkOption option;
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

class _DataTypeChip extends StatelessWidget {
  const _DataTypeChip({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool selected;
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color:
                selected
                    ? (isDark ? _primary.withValues(alpha: 0.18) : _softTint)
                    : (isDark ? _darkPanel : Colors.white),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color:
                  selected
                      ? _primary
                      : (isDark ? const Color(0xFF3A4054) : _softBorder),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color:
                  selected
                      ? (isDark
                          ? const Color(0xFFF3F4F6)
                          : const Color(0xFF7FA0F5))
                      : (isDark
                          ? const Color(0xFFF8FAFC)
                          : const Color(0xFF374151)),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _DataRecipientChip extends StatelessWidget {
  const _DataRecipientChip({
    required this.recipient,
    required this.network,
    required this.isDark,
    required this.onTap,
  });

  final _DataRecipient recipient;
  final _DataNetworkOption network;
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

class _QuickPlanCard extends StatelessWidget {
  const _QuickPlanCard({
    required this.plan,
    required this.isDark,
    required this.selected,
    required this.formatter,
    required this.onTap,
  });

  final _DataPlan plan;
  final bool isDark;
  final bool selected;
  final String Function(num amount) formatter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                selected
                    ? (isDark ? _primary.withValues(alpha: 0.18) : _softTint)
                    : (isDark ? _darkPanel : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  selected
                      ? _primary
                      : (isDark ? const Color(0xFF3A4054) : _softBorder),
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
                  color:
                      isDark
                          ? const Color(0xFFF8FAFC)
                          : const Color(0xFF111827),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                plan.validity.toLowerCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? _darkMuted : const Color(0xFF4B5563),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                formatter(plan.amount),
                style: TextStyle(
                  color: isDark ? const Color(0xFFD1D5DB) : _primaryDark,
                  fontSize: 14,
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

class _DataConfirmationSheet extends StatefulWidget {
  const _DataConfirmationSheet({
    required this.amountPaid,
    required this.networkName,
    required this.phoneNumber,
    required this.planName,
    required this.validity,
    required this.initialSaveRecipient,
  });

  final String amountPaid;
  final String networkName;
  final String phoneNumber;
  final String planName;
  final String validity;
  final bool initialSaveRecipient;

  @override
  State<_DataConfirmationSheet> createState() => _DataConfirmationSheetState();
}

class _DataConfirmationSheetState extends State<_DataConfirmationSheet> {
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
                      'Confirm Data Purchase',
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
                'Review this data payment before entering your PIN.',
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
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _CompactSummaryTile(
                      label: 'Plan',
                      value: widget.planName,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _CompactSummaryTile(
                      label: 'Validity',
                      value: widget.validity,
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

class _DataPinSheet extends StatefulWidget {
  const _DataPinSheet({
    required this.onSubmit,
    required this.canUseBiometric,
    this.onBiometricSubmit,
  });

  final Future<_DataPinSheetActionResult> Function(String pin) onSubmit;
  final bool canUseBiometric;
  final Future<_DataPinSheetActionResult> Function()? onBiometricSubmit;

  @override
  State<_DataPinSheet> createState() => _DataPinSheetState();
}

class _DataPinSheetState extends State<_DataPinSheet> {
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
    late final _DataPinSheetActionResult submitResult;

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
      submitResult = const _DataPinSheetActionResult.error(
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
    late final _DataPinSheetActionResult submitResult;

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
      submitResult = const _DataPinSheetActionResult.error(
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
              fontWeight: FontWeight.w600,
            ),
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

enum _DataResultAction { close, retry }

class _DataPinSheetActionResult {
  const _DataPinSheetActionResult._({this.result, this.errorMessage});

  const _DataPinSheetActionResult.result(_DataResult result)
    : this._(result: result);

  const _DataPinSheetActionResult.error(String errorMessage)
    : this._(errorMessage: errorMessage);

  final _DataResult? result;
  final String? errorMessage;
}

class _DataResultSheet extends StatelessWidget {
  const _DataResultSheet({required this.result, required this.formatter});

  final _DataResult result;
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
                  () => Navigator.of(context).pop(_DataResultAction.close),
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
                        () =>
                            Navigator.of(context).pop(_DataResultAction.close),
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
                            Navigator.of(context).pop(_DataResultAction.retry),
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
                          ).pop(_DataResultAction.close),
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
                      const SizedBox(height: 8),
                      _SummaryRow(
                        label: 'Data Plan',
                        value: result.planName,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 8),
                      _SummaryRow(
                        label: 'Validity',
                        value: result.validity,
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

class _DataNetworkOption {
  const _DataNetworkOption({
    required this.id,
    required this.name,
    required this.shortName,
    required this.assetPath,
    required this.brandColor,
    required this.foregroundColor,
    required this.dataTypes,
    String? purchaseNetworkId,
  }) : purchaseNetworkId = purchaseNetworkId ?? id;

  final String id;
  final String name;
  final String shortName;
  final String assetPath;
  final Color brandColor;
  final Color foregroundColor;
  final List<_DataTypeOption> dataTypes;
  final String purchaseNetworkId;
}

class _DataTypeOption {
  const _DataTypeOption({
    required this.key,
    required this.label,
    required this.plans,
  });

  final String key;
  final String label;
  final List<_DataPlan> plans;
}

class _DataPlan {
  const _DataPlan({
    required this.id,
    required this.name,
    required this.validity,
    required this.amount,
    String? dataPlanId,
  }) : dataPlanId = dataPlanId ?? id;

  final String id;
  final String name;
  final String validity;
  final double amount;
  final String dataPlanId;
}

class _DataRecipient {
  const _DataRecipient({
    required this.phoneNumber,
    required this.networkId,
    required this.usageCount,
  });

  final String phoneNumber;
  final String networkId;
  final int usageCount;
}

class _DataResult {
  const _DataResult({
    required this.isSuccessful,
    required this.networkName,
    required this.phoneNumber,
    required this.planName,
    required this.validity,
    required this.amountPaid,
    required this.reference,
    required this.message,
  });

  final bool isSuccessful;
  final String networkName;
  final String phoneNumber;
  final String planName;
  final String validity;
  final double amountPaid;
  final String reference;
  final String message;
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/auth/app_session_service.dart';
import '../../../navigation/presentation/widgets/app_bottom_navigation.dart';
import '../../../shared/presentation/widgets/pts_data_mobile_ui.dart';
import '../../data/virtual_accounts_api_service.dart';

class VirtualAccountsPage extends StatefulWidget {
  const VirtualAccountsPage({super.key});

  @override
  State<VirtualAccountsPage> createState() => _VirtualAccountsPageState();
}

class _VirtualAccountsPageState extends State<VirtualAccountsPage> {
  List<VirtualAccountItem> _accounts = const <VirtualAccountItem>[];
  bool _hasAccounts = false;
  bool _isLoading = true;
  String _customerCode = '';
  String _customerEmail = '';
  String? _copiedAccountNumber;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final String? token = await AppSessionService.instance.getApiToken();
    if (token == null || token.isEmpty) {
      await _handleUnauthorized();
      return;
    }

    final VirtualAccountsApiResult result = await VirtualAccountsApiService
        .instance
        .fetchAccounts(token: token);
    if (!mounted) {
      return;
    }

    if (result.isUnauthorized) {
      await _handleUnauthorized();
      return;
    }

    if (result.isSuccess) {
      setState(() {
        _accounts = result.accounts;
        _hasAccounts = result.hasAccounts;
        _customerCode = result.customerCode;
        _customerEmail = result.customerEmail;
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = false);
    if (result.message != null && result.message!.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message!)));
    }
  }

  Future<void> _copyAccountNumber(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) {
      return;
    }

    setState(() => _copiedAccountNumber = value);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Account number copied.')));

    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted || _copiedAccountNumber != value) {
      return;
    }
    setState(() => _copiedAccountNumber = null);
  }

  Future<void> _handleUnauthorized() async {
    await AppSessionService.instance.clear();
    if (!mounted) {
      return;
    }

    setState(() => _isLoading = false);
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (Route<dynamic> route) => false);
  }

  Future<void> _handleBottomNavigation(
    AppBottomNavDestination destination,
  ) async {
    await handleUtilityBottomNavigationTap(context, destination: destination);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mutedText = isDark ? ptsDataDarkMuted : const Color(0xFF4B5563);
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

    return PtsDataPageScaffold(
      title: 'Virtual Accounts',
      onRefresh: _loadAccounts,
      selectedBottomNav: AppBottomNavDestination.wallet,
      onBottomNavigation: _handleBottomNavigation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (_isLoading) ...<Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: const LinearProgressIndicator(minHeight: 4),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            'Use these assigned accounts to fund your wallet directly. They are fetched from your real PTS DATA profile.',
            style: TextStyle(
              color: mutedText,
              fontSize: 12.2,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? ptsDataDarkSurface : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark ? const Color(0xFF3A4054) : ptsDataSoftBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Account Provisioning',
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _hasAccounts
                      ? 'Your wallet can receive direct transfers through the accounts below.'
                      : 'We could not find an active virtual account yet. Please try again shortly.',
                  style: TextStyle(
                    color: mutedText,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
                if (_customerEmail.isNotEmpty || _customerCode.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        if (_customerEmail.isNotEmpty)
                          _InfoChip(
                            label: 'Customer Email',
                            value: _customerEmail,
                            isDark: isDark,
                          ),
                        if (_customerCode.isNotEmpty)
                          _InfoChip(
                            label: 'Customer Code',
                            value: _customerCode,
                            isDark: isDark,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          PtsDataSectionHeader(
            title: 'Assigned Accounts',
            subtitle: 'Copy any account number below and fund your wallet.',
          ),
          const SizedBox(height: 12),
          if (!_isLoading && _accounts.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? ptsDataDarkSurface : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark ? const Color(0xFF3A4054) : ptsDataSoftBorder,
                ),
              ),
              child: Text(
                'No virtual accounts are available for this profile yet.',
                style: TextStyle(
                  color: mutedText,
                  fontSize: 11.8,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            )
          else
            ..._accounts.map(
              (VirtualAccountItem account) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _VirtualAccountCard(
                  account: account,
                  isDark: isDark,
                  copied: _copiedAccountNumber == account.accountNumber,
                  onCopy: () => _copyAccountNumber(account.accountNumber),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _VirtualAccountCard extends StatelessWidget {
  const _VirtualAccountCard({
    required this.account,
    required this.isDark,
    required this.copied,
    required this.onCopy,
  });

  final VirtualAccountItem account;
  final bool isDark;
  final bool copied;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color mutedText = isDark ? ptsDataDarkMuted : const Color(0xFF4B5563);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? ptsDataDarkSurface : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF3A4054) : ptsDataSoftBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  account.bankName,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ptsDataPrimary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  account.isActive ? 'Active' : 'Inactive',
                  style: const TextStyle(
                    color: ptsDataPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            account.accountNumber,
            style: TextStyle(
              color: titleColor,
              fontSize: 21,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            account.accountName,
            style: TextStyle(
              color: mutedText,
              fontSize: 11.8,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Created ${account.createdLabel}',
                  style: TextStyle(
                    color: mutedText,
                    fontSize: 10.8,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: onCopy,
                style: FilledButton.styleFrom(
                  backgroundColor: copied ? ptsDataSecondary : ptsDataPrimary,
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: Icon(
                  copied ? Icons.check_rounded : Icons.copy_rounded,
                  size: 15,
                ),
                label: Text(copied ? 'Copied' : 'Copy'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
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
    final Color mutedText = isDark ? ptsDataDarkMuted : const Color(0xFF4B5563);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: isDark ? ptsDataDarkPanel : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              color: mutedText,
              fontSize: 9.6,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: titleColor,
              fontSize: 11.4,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

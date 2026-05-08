import 'package:flutter/material.dart';

import '../../../navigation/presentation/widgets/app_bottom_navigation.dart';
import '../../../shared/presentation/widgets/pts_data_loader_overlay.dart';
import '../../../shared/presentation/widgets/pts_data_mobile_ui.dart';
import '../../../shared/presentation/widgets/pts_data_select_page.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  static const List<String> _categories = <String>[
    'Payment issue',
    'Account access',
    'Wallet funding',
    'Transfer issue',
    'General enquiry',
  ];

  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  late List<_SupportTicket> _tickets;
  String _selectedCategory = _categories.first;

  @override
  void initState() {
    super.initState();
    _tickets = <_SupportTicket>[
      _SupportTicket(
        id: 'SUP-2041',
        title: 'Wallet funding not reflecting',
        category: 'Wallet funding',
        status: _SupportTicketStatus.inReview,
        updatedAt: DateTime(2026, 3, 13, 18, 10),
      ),
      _SupportTicket(
        id: 'SUP-2036',
        title: 'Need help updating my transaction PIN',
        category: 'Account access',
        status: _SupportTicketStatus.resolved,
        updatedAt: DateTime(2026, 3, 11, 14, 5),
      ),
    ];
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _handleBottomNavigation(
    AppBottomNavDestination destination,
  ) async {
    await handleUtilityBottomNavigationTap(context, destination: destination);
  }

  int get _openTicketCount =>
      _tickets
          .where(
            (_SupportTicket ticket) =>
                ticket.status != _SupportTicketStatus.resolved,
          )
          .length;

  Future<void> _openCategorySelector() async {
    final String? selectedCategory = await showPtsDataSelectPage<String>(
      context: context,
      title: 'Select Category',
      searchHint: 'Enter search content',
      pinnedTitle: 'Common Categories',
      selectedValue: _selectedCategory,
      options: _categories
          .asMap()
          .entries
          .map((MapEntry<int, String> entry) {
            final String category = entry.value;
            return PtsDataSelectOption<String>(
              value: category,
              title: category,
              searchText: category,
              pinned: entry.key < 6,
            );
          })
          .toList(growable: false),
      emptyText: 'No category matches your search.',
    );

    if (!mounted || selectedCategory == null) {
      return;
    }

    setState(() {
      _selectedCategory = selectedCategory;
    });
  }

  Future<void> _openChannel(String label) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label channel is ready for backend wiring.')),
    );
  }

  Future<void> _submitRequest() async {
    final String subject = _subjectController.text.trim();
    final String message = _messageController.text.trim();

    if (subject.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a subject and support message.')),
      );
      return;
    }

    final bool? confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _SupportConfirmationSheet(
          category: _selectedCategory,
          subject: subject,
          message: message,
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    showPtsDataLoaderDialog<void>(
      context,
      text: 'Sending support request...',
      color: ptsDataPrimary,
    );

    await Future<void>.delayed(const Duration(milliseconds: 950));
    if (!mounted) {
      return;
    }

    Navigator.of(context, rootNavigator: true).pop();

    final _SupportTicket ticket = _SupportTicket(
      id: 'SUP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      title: subject,
      category: _selectedCategory,
      status: _SupportTicketStatus.open,
      updatedAt: DateTime.now(),
    );

    setState(() {
      _tickets = <_SupportTicket>[ticket, ..._tickets];
      _selectedCategory = _categories.first;
      _subjectController.clear();
      _messageController.clear();
    });

    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _SupportResultSheet(ticket: ticket);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return PtsDataPageScaffold(
      title: 'Support Center',
      contentPadding: EdgeInsets.zero,
      selectedBottomNav: AppBottomNavDestination.me,
      onBottomNavigation:
          (AppBottomNavDestination destination) =>
              _handleBottomNavigation(destination),
      child: Container(
        color: isDark ? ptsDataDarkBackground : const Color(0xFFF6F7FB),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _SupportHeroPanel(
              isDark: isDark,
              openTicketCount: _openTicketCount,
            ),
            const SizedBox(height: 14),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: PtsDataSectionHeader(
                title: 'Quick Help Channels',
                subtitle: 'Choose the fastest channel that fits your issue.',
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _SupportChannelTile(
                  title: 'Live Chat',
                  subtitle: 'Fastest response',
                  icon: Icons.chat_bubble_rounded,
                  accent: ptsDataPrimary,
                  isDark: isDark,
                  onTap: () => _openChannel('Live chat'),
                ),
                _SupportChannelTile(
                  title: 'WhatsApp',
                  subtitle: 'Chat on mobile',
                  icon: Icons.phone_rounded,
                  accent: ptsDataAccent,
                  isDark: isDark,
                  onTap: () => _openChannel('WhatsApp'),
                ),
                _SupportChannelTile(
                  title: 'Email',
                  subtitle: 'Detailed issues',
                  icon: Icons.mail_rounded,
                  accent: ptsDataSecondary,
                  isDark: isDark,
                  onTap: () => _openChannel('Email'),
                ),
                _SupportChannelTile(
                  title: 'Call',
                  subtitle: 'Speak with us',
                  icon: Icons.headset_mic_rounded,
                  accent: ptsDataSky,
                  isDark: isDark,
                  onTap: () => _openChannel('Call support'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              decoration: BoxDecoration(
                color: isDark ? ptsDataDarkSurface : Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const PtsDataSectionHeader(
                    title: 'Send Support Request',
                    subtitle:
                        'Describe the issue clearly so we can resolve it faster.',
                  ),
                  const SizedBox(height: 14),
                  PtsDataSelectField(
                    placeholder: 'Category',
                    value: _selectedCategory,
                    icon: Icons.category_rounded,
                    onTap: _openCategorySelector,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _subjectController,
                    decoration: buildPtsDataFieldDecoration(
                      context: context,
                      hintText: 'Subject',
                      prefixIcon: const Icon(
                        Icons.subject_rounded,
                        size: 18,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _messageController,
                    maxLines: 5,
                    decoration: buildPtsDataFieldDecoration(
                      context: context,
                      hintText: 'Tell us what happened',
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 74),
                        child: Icon(
                          Icons.edit_note_rounded,
                          size: 18,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: _submitRequest,
                      style: FilledButton.styleFrom(
                        backgroundColor: ptsDataPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Submit Request'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: PtsDataSectionHeader(
                title: 'Recent Tickets',
                subtitle: 'Keep an eye on the issues you already submitted.',
              ),
            ),
            const SizedBox(height: 10),
            ..._tickets.map(
              (_SupportTicket ticket) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _SupportTicketTile(ticket: ticket, isDark: isDark),
              ),
            ),
            const SizedBox(height: 6),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: PtsDataSectionHeader(
                title: 'Frequently Asked Questions',
                subtitle: 'Quick answers to the issues we see most often.',
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
              decoration: BoxDecoration(
                color: isDark ? ptsDataDarkSurface : Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: const <Widget>[
                    _SupportFaqTile(
                      question: 'How long does wallet funding take to reflect?',
                      answer:
                          'Manual bank transfer funding usually reflects after review. If it delays, submit the exact amount, sender name, and transfer time in Support Center.',
                    ),
                    _SupportFaqTile(
                      question: 'What should I do if a transfer fails?',
                      answer:
                          'Check your transaction history first. If the status remains pending or failed after a short wait, open a support request with the reference and amount.',
                    ),
                    _SupportFaqTile(
                      question: 'Can I reset my payment PIN from the app?',
                      answer:
                          'Yes. Use the Transaction PIN section inside the Me page once the backend wiring is complete, or contact support if you are locked out.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportHeroPanel extends StatelessWidget {
  const _SupportHeroPanel({
    required this.isDark,
    required this.openTicketCount,
  });

  final bool isDark;
  final int openTicketCount;

  @override
  Widget build(BuildContext context) {
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color mutedText = isDark ? ptsDataDarkMuted : const Color(0xFF4B5563);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: isDark ? ptsDataDarkSurface : Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Support Overview',
            style: TextStyle(
              color: titleColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Reach support fast, submit an issue, and track updates without leaving the app.',
            style: TextStyle(
              color: mutedText,
              fontSize: 11.3,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _SupportMetricTile(
                  label: 'Avg Response',
                  value: '5 mins',
                  icon: Icons.timer_rounded,
                  accent: ptsDataPrimary,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SupportMetricTile(
                  label: 'Channels',
                  value: '4',
                  icon: Icons.forum_rounded,
                  accent: ptsDataSecondary,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SupportMetricTile(
                  label: 'Open Tickets',
                  value: '$openTicketCount',
                  icon: Icons.support_agent_rounded,
                  accent: ptsDataAccent,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SupportMetricTile extends StatelessWidget {
  const _SupportMetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.isDark,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? ptsDataDarkPanel : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(icon, size: 14, color: accent),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: isDark ? ptsDataDarkMuted : const Color(0xFF4B5563),
              fontSize: 10.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportChannelTile extends StatelessWidget {
  const _SupportChannelTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.isDark,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.sizeOf(context).width - 52) / 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? ptsDataDarkPanel : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.18 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  color:
                      isDark
                          ? const Color(0xFFF8FAFC)
                          : const Color(0xFF0F172A),
                  fontSize: 12.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: isDark ? ptsDataDarkMuted : const Color(0xFF4B5563),
                  fontSize: 11.1,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportTicketTile extends StatelessWidget {
  const _SupportTicketTile({required this.ticket, required this.isDark});

  final _SupportTicket ticket;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final Color mutedText = isDark ? ptsDataDarkMuted : const Color(0xFF4B5563);

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: isDark ? ptsDataDarkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: ticket.status.accent.withValues(
                alpha: isDark ? 0.18 : 0.12,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              ticket.status.icon,
              size: 18,
              color: ticket.status.accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  ticket.title,
                  style: TextStyle(
                    color:
                        isDark
                            ? const Color(0xFFF8FAFC)
                            : const Color(0xFF0F172A),
                    fontSize: 12.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${ticket.id}  •  ${ticket.category}',
                  style: TextStyle(
                    color: mutedText,
                    fontSize: 10.9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  formatPtsDataDate(ticket.updatedAt),
                  style: TextStyle(
                    color: mutedText,
                    fontSize: 10.7,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: ticket.status.accent.withValues(
                alpha: isDark ? 0.18 : 0.10,
              ),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              ticket.status.label,
              style: TextStyle(
                color: ticket.status.accent,
                fontSize: 10.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportFaqTile extends StatelessWidget {
  const _SupportFaqTile({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mutedText = isDark ? ptsDataDarkMuted : const Color(0xFF4B5563);

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 12),
      iconColor: ptsDataPrimary,
      collapsedIconColor: ptsDataPrimary,
      title: Text(
        question,
        style: TextStyle(
          color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
          fontSize: 12.4,
          fontWeight: FontWeight.w500,
        ),
      ),
      children: <Widget>[
        Text(
          answer,
          style: TextStyle(
            color: mutedText,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _SupportConfirmationSheet extends StatelessWidget {
  const _SupportConfirmationSheet({
    required this.category,
    required this.subject,
    required this.message,
  });

  final String category;
  final String subject;
  final String message;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color surfaceColor = isDark ? ptsDataDarkSurface : Colors.white;
    final Color mutedText = isDark ? ptsDataDarkMuted : const Color(0xFF4B5563);

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(
          18,
          10,
          18,
          18 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? const Color(0xFF374151)
                          : const Color(0xFFD6E3F5),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Confirm Support Request',
              style: TextStyle(
                color:
                    isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'We will send this request to the support queue immediately.',
              style: TextStyle(
                color: mutedText,
                fontSize: 11.8,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? ptsDataDarkPanel : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0xFF3A4054) : ptsDataSoftBorder,
                ),
              ),
              child: Column(
                children: <Widget>[
                  _SupportSummaryRow(label: 'Category', value: category),
                  const SizedBox(height: 10),
                  _SupportSummaryRow(label: 'Subject', value: subject),
                  const SizedBox(height: 10),
                  _SupportSummaryRow(label: 'Message', value: message),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: ptsDataPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Send Now'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportResultSheet extends StatelessWidget {
  const _SupportResultSheet({required this.ticket});

  final _SupportTicket ticket;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color surfaceColor = isDark ? ptsDataDarkSurface : Colors.white;
    final Color mutedText = isDark ? ptsDataDarkMuted : const Color(0xFF4B5563);

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(
          18,
          10,
          18,
          18 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? const Color(0xFF374151)
                          : const Color(0xFFD6E3F5),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: ptsDataPrimary.withValues(alpha: isDark ? 0.18 : 0.12),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                size: 34,
                color: ptsDataPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Request Submitted',
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                    isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your issue was sent to PTS DATA support successfully.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: mutedText,
                fontSize: 11.8,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? ptsDataDarkPanel : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0xFF3A4054) : ptsDataSoftBorder,
                ),
              ),
              child: Column(
                children: <Widget>[
                  _SupportSummaryRow(label: 'Ticket ID', value: ticket.id),
                  const SizedBox(height: 10),
                  _SupportSummaryRow(label: 'Category', value: ticket.category),
                  const SizedBox(height: 10),
                  _SupportSummaryRow(
                    label: 'Status',
                    value: ticket.status.label,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: ptsDataPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportSummaryRow extends StatelessWidget {
  const _SupportSummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mutedText = isDark ? ptsDataDarkMuted : const Color(0xFF4B5563);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 68,
          child: Text(
            label,
            style: TextStyle(
              color: mutedText,
              fontSize: 11.1,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
              fontSize: 11.8,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

enum _SupportTicketStatus {
  open('Open', Icons.mark_email_unread_rounded, ptsDataPrimary),
  inReview('In Review', Icons.schedule_rounded, ptsDataAccent),
  resolved('Resolved', Icons.check_circle_rounded, Color(0xFF14B8A6));

  const _SupportTicketStatus(this.label, this.icon, this.accent);

  final String label;
  final IconData icon;
  final Color accent;
}

class _SupportTicket {
  const _SupportTicket({
    required this.id,
    required this.title,
    required this.category,
    required this.status,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String category;
  final _SupportTicketStatus status;
  final DateTime updatedAt;
}

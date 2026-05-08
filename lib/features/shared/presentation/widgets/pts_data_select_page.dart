import 'package:flutter/material.dart';

import 'pts_data_mobile_ui.dart';

class PtsDataSelectOption<T> {
  const PtsDataSelectOption({
    required this.value,
    required this.title,
    this.subtitle,
    this.trailing,
    this.searchText,
    this.group,
    this.pinned = false,
  });

  final T value;
  final String title;
  final String? subtitle;
  final String? trailing;
  final String? searchText;
  final String? group;
  final bool pinned;

  bool matches(String query) {
    if (query.isEmpty) {
      return true;
    }

    final String haystack =
        searchText ?? '$title ${subtitle ?? ''} ${trailing ?? ''}';
    return haystack.toLowerCase().contains(query.toLowerCase());
  }
}

Future<T?> showPtsDataSelectPage<T>({
  required BuildContext context,
  required String title,
  required List<PtsDataSelectOption<T>> options,
  T? selectedValue,
  String searchHint = 'Enter search content',
  String pinnedTitle = 'Frequently Selected',
  String emptyText = 'No matching item found.',
}) {
  return Navigator.of(context).push<T>(
    MaterialPageRoute<T>(
      fullscreenDialog: true,
      builder:
          (_) => _PtsDataSelectPage<T>(
            title: title,
            searchHint: searchHint,
            pinnedTitle: pinnedTitle,
            emptyText: emptyText,
            options: options,
            selectedValue: selectedValue,
          ),
    ),
  );
}

class PtsDataSelectField extends StatelessWidget {
  const PtsDataSelectField({
    required this.placeholder,
    required this.onTap,
    this.value,
    this.icon = Icons.keyboard_arrow_down_rounded,
    super.key,
  });

  final String placeholder;
  final String? value;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool hasValue = value != null && value!.trim().isNotEmpty;
    final Color borderColor =
        isDark ? const Color(0xFF3A4054) : ptsDataSoftBorder;
    final Color backgroundColor =
        isDark ? ptsDataDarkPanel : const Color(0xFFF8FAFC);
    final Color textColor =
        hasValue
            ? (isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827))
            : (isDark ? ptsDataDarkMuted : const Color(0xFF4B5563));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 18, color: textColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hasValue ? value! : placeholder,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: hasValue ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 21,
                color: isDark ? ptsDataDarkMuted : const Color(0xFF4B5563),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PtsDataSelectPage<T> extends StatefulWidget {
  const _PtsDataSelectPage({
    required this.title,
    required this.searchHint,
    required this.pinnedTitle,
    required this.emptyText,
    required this.options,
    required this.selectedValue,
  });

  final String title;
  final String searchHint;
  final String pinnedTitle;
  final String emptyText;
  final List<PtsDataSelectOption<T>> options;
  final T? selectedValue;

  @override
  State<_PtsDataSelectPage<T>> createState() => _PtsDataSelectPageState<T>();
}

class _PtsDataSelectPageState<T> extends State<_PtsDataSelectPage<T>> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _groupKeys = <String, GlobalKey>{};
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _select(PtsDataSelectOption<T> option) {
    Navigator.of(context).pop(option.value);
  }

  String _groupFor(PtsDataSelectOption<T> option) {
    final String raw = option.group ?? option.title;
    if (raw.isEmpty) {
      return '#';
    }

    final String first = raw.characters.first.toUpperCase();
    final int code = first.codeUnitAt(0);
    if (code >= 65 && code <= 90) {
      return first;
    }
    return '#';
  }

  Map<String, List<PtsDataSelectOption<T>>> _groupOptions(
    List<PtsDataSelectOption<T>> options,
  ) {
    final Map<String, List<PtsDataSelectOption<T>>> groups =
        <String, List<PtsDataSelectOption<T>>>{};

    for (final PtsDataSelectOption<T> option in options) {
      final String group = _groupFor(option);
      groups.putIfAbsent(group, () => <PtsDataSelectOption<T>>[]).add(option);
    }

    final List<MapEntry<String, List<PtsDataSelectOption<T>>>> entries =
        groups.entries.toList()..sort((
          MapEntry<String, List<PtsDataSelectOption<T>>> a,
          MapEntry<String, List<PtsDataSelectOption<T>>> b,
        ) {
          if (a.key == '#') {
            return -1;
          }
          if (b.key == '#') {
            return 1;
          }
          return a.key.compareTo(b.key);
        });

    return Map<String, List<PtsDataSelectOption<T>>>.fromEntries(entries);
  }

  void _scrollToGroup(String group) {
    final BuildContext? groupContext = _groupKeys[group]?.currentContext;
    if (groupContext == null) {
      return;
    }

    Scrollable.ensureVisible(
      groupContext,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      alignment: 0.06,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor = isDark ? ptsDataDarkBackground : Colors.white;
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);
    final Color mutedText = isDark ? ptsDataDarkMuted : const Color(0xFF4B5563);
    final List<PtsDataSelectOption<T>> filteredOptions = widget.options
        .where((PtsDataSelectOption<T> option) => option.matches(_query))
        .toList(growable: false);
    final List<PtsDataSelectOption<T>> pinnedOptions = widget.options
        .where((PtsDataSelectOption<T> option) => option.pinned)
        .take(6)
        .toList(growable: false);
    final bool showPinned = _query.isEmpty && pinnedOptions.isNotEmpty;
    final Map<String, List<PtsDataSelectOption<T>>> groups = _groupOptions(
      filteredOptions,
    );
    _groupKeys
      ..clear()
      ..addEntries(
        groups.keys.map(
          (String group) => MapEntry<String, GlobalKey>(group, GlobalKey()),
        ),
      );

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  child: Row(
                    children: <Widget>[
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: titleColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 18.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: _SelectSearchField(
                    controller: _searchController,
                    hintText: widget.searchHint,
                    onChanged: (String value) {
                      setState(() => _query = value.trim());
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child:
                      filteredOptions.isEmpty
                          ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(28),
                              child: Text(
                                widget.emptyText,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: mutedText,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                          : ListView(
                            controller: _scrollController,
                            padding: EdgeInsets.fromLTRB(
                              18,
                              0,
                              groups.length > 5 ? 34 : 18,
                              28,
                            ),
                            children: <Widget>[
                              if (showPinned) ...<Widget>[
                                _PinnedOptionsGrid<T>(
                                  title: widget.pinnedTitle,
                                  options: pinnedOptions,
                                  selectedValue: widget.selectedValue,
                                  onSelect: _select,
                                ),
                                const SizedBox(height: 18),
                              ],
                              for (final MapEntry<
                                    String,
                                    List<PtsDataSelectOption<T>>
                                  >
                                  entry
                                  in groups.entries) ...<Widget>[
                                _SelectSectionHeader(
                                  key: _groupKeys[entry.key],
                                  label: entry.key,
                                ),
                                for (final PtsDataSelectOption<T> option
                                    in entry.value)
                                  _SelectOptionRow<T>(
                                    option: option,
                                    selected:
                                        widget.selectedValue == option.value,
                                    onTap: () => _select(option),
                                  ),
                              ],
                            ],
                          ),
                ),
              ],
            ),
            if (_query.isEmpty && groups.length > 5)
              Positioned(
                top: 158,
                right: 5,
                bottom: 18,
                child: _AlphabetIndex(
                  groups: groups.keys.toList(growable: false),
                  onSelect: _scrollToGroup,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SelectSearchField extends StatelessWidget {
  const _SelectSearchField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color fillColor = isDark ? ptsDataDarkPanel : const Color(0xFFF3F4F6);
    final Color mutedText = isDark ? ptsDataDarkMuted : const Color(0xFF6B7280);

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: TextStyle(
          color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          prefixIcon: Icon(Icons.search_rounded, color: mutedText, size: 22),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 50,
          ),
          hintText: hintText,
          hintStyle: TextStyle(
            color: mutedText.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }
}

class _PinnedOptionsGrid<T> extends StatelessWidget {
  const _PinnedOptionsGrid({
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.onSelect,
  });

  final String title;
  final List<PtsDataSelectOption<T>> options;
  final T? selectedValue;
  final ValueChanged<PtsDataSelectOption<T>> onSelect;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: TextStyle(
            color: titleColor,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: options.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.14,
          ),
          itemBuilder: (BuildContext context, int index) {
            final PtsDataSelectOption<T> option = options[index];
            return _PinnedOptionTile<T>(
              option: option,
              selected: selectedValue == option.value,
              onTap: () => onSelect(option),
            );
          },
        ),
      ],
    );
  }
}

class _PinnedOptionTile<T> extends StatelessWidget {
  const _PinnedOptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final PtsDataSelectOption<T> option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color titleColor =
        selected
            ? ptsDataPrimary
            : (isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? ptsDataDarkPanel : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color:
                  selected
                      ? ptsDataPrimary
                      : (isDark ? const Color(0xFF3A4054) : ptsDataSoftBorder),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                option.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (option.trailing != null) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  option.trailing!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? ptsDataDarkMuted : const Color(0xFF4B5563),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectSectionHeader extends StatelessWidget {
  const _SelectSectionHeader({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: isDark ? ptsDataDarkBackground : const Color(0xFFF6F7FB),
      child: Text(
        label,
        style: TextStyle(
          color: isDark ? ptsDataDarkMuted : const Color(0xFF6B7280),
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SelectOptionRow<T> extends StatelessWidget {
  const _SelectOptionRow({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final PtsDataSelectOption<T> option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color titleColor =
        selected
            ? ptsDataPrimary
            : (isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827));
    final Color mutedText = isDark ? ptsDataDarkMuted : const Color(0xFF4B5563);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color:
                    isDark ? const Color(0xFF3A4054) : const Color(0xFFE5E7EB),
              ),
            ),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      option.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                    if (option.subtitle != null) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        option.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: mutedText,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (option.trailing != null) ...<Widget>[
                const SizedBox(width: 12),
                Text(
                  option.trailing!,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: selected ? ptsDataPrimary : mutedText,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              if (selected) ...<Widget>[
                const SizedBox(width: 10),
                const Icon(
                  Icons.check_circle_rounded,
                  color: ptsDataPrimary,
                  size: 17,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AlphabetIndex extends StatelessWidget {
  const _AlphabetIndex({required this.groups, required this.onSelect});

  final List<String> groups;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? ptsDataDarkMuted : const Color(0xFF6B7280);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children:
          groups
              .map(
                (String group) => GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onSelect(group),
                  child: SizedBox(
                    width: 24,
                    height: 20,
                    child: Center(
                      child: Text(
                        group,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }
}

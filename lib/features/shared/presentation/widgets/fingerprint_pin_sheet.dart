import 'package:flutter/material.dart';

import 'pts_data_mobile_ui.dart';

class FingerprintPinSheet extends StatefulWidget {
  const FingerprintPinSheet({required this.onVerifyPin, super.key});

  final Future<String?> Function(String pin) onVerifyPin;

  @override
  State<FingerprintPinSheet> createState() => _FingerprintPinSheetState();
}

class _FingerprintPinSheetState extends State<FingerprintPinSheet> {
  static const int _pinLength = 4;

  final List<String> _digits = <String>[];
  bool _isSubmitting = false;
  String? _errorText;

  void _appendDigit(String digit) {
    if (_isSubmitting || _digits.length >= _pinLength) {
      return;
    }

    setState(() {
      _errorText = null;
      _digits.add(digit);
    });

    if (_digits.length == _pinLength) {
      _submit();
    }
  }

  void _removeDigit() {
    if (_isSubmitting || _digits.isEmpty) {
      return;
    }

    setState(() {
      _errorText = null;
      _digits.removeLast();
    });
  }

  Future<void> _submit() async {
    if (_digits.length != _pinLength || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    final String? error = await widget.onVerifyPin(_digits.join());
    if (!mounted) {
      return;
    }

    if (error == null) {
      Navigator.of(context).pop(_digits.join());
      return;
    }

    setState(() {
      _digits.clear();
      _isSubmitting = false;
      _errorText = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color sheetColor = isDark ? ptsDataDarkSurface : Colors.white;
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color mutedText = isDark ? ptsDataDarkMuted : const Color(0xFF4B5563);

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: sheetColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            12,
            18,
            18 + MediaQuery.paddingOf(context).bottom,
          ),
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
                      'Enable Fingerprint Login',
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed:
                        _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.close_rounded,
                      color: titleColor,
                      size: 20,
                    ),
                  ),
                ],
              ),
              Text(
                'Confirm your 4-digit transaction PIN before fingerprint unlock is enabled on this device.',
                style: TextStyle(
                  color: mutedText,
                  fontSize: 12.1,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(_pinLength, (int index) {
                  final bool filled = index < _digits.length;

                  return Container(
                    width: 52,
                    height: 56,
                    margin: EdgeInsets.only(
                      right: index == _pinLength - 1 ? 0 : 10,
                    ),
                    decoration: BoxDecoration(
                      color:
                          filled
                              ? ptsDataPrimary.withValues(alpha: 0.08)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            filled
                                ? ptsDataPrimary
                                : (isDark
                                    ? const Color(0xFF374151)
                                    : const Color(0xFFE5E7EB)),
                        width: 1.2,
                      ),
                    ),
                    child: Center(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 140),
                        opacity: filled ? 1 : 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: ptsDataPrimary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              if (_errorText != null) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  _errorText!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFDC2626),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _FingerprintPinKeypad(
                isDark: isDark,
                enabled: !_isSubmitting,
                onDigit: _appendDigit,
                onBackspace: _removeDigit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FingerprintPinKeypad extends StatelessWidget {
  const _FingerprintPinKeypad({
    required this.isDark,
    required this.enabled,
    required this.onDigit,
    required this.onBackspace,
  });

  final bool isDark;
  final bool enabled;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Column(
        children: <Widget>[
          for (final List<String> row in const <List<String>>[
            <String>['1', '2', '3'],
            <String>['4', '5', '6'],
            <String>['7', '8', '9'],
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children:
                    row
                        .map(
                          (String digit) => Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: digit == row.last ? 0 : 8,
                              ),
                              child: _FingerprintPinKeypadButton(
                                label: digit,
                                isDark: isDark,
                                onTap: enabled ? () => onDigit(digit) : () {},
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
          Row(
            children: <Widget>[
              const Expanded(child: SizedBox.shrink()),
              Expanded(
                child: _FingerprintPinKeypadButton(
                  label: '0',
                  isDark: isDark,
                  onTap: enabled ? () => onDigit('0') : () {},
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FingerprintPinKeypadIconButton(
                  icon: Icons.backspace_outlined,
                  isDark: isDark,
                  onTap: enabled ? onBackspace : () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FingerprintPinKeypadButton extends StatelessWidget {
  const _FingerprintPinKeypadButton({
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color surface = isDark ? const Color(0xFF020B1E) : Colors.white;
    final Color border =
        isDark ? const Color(0xFF3A4054) : const Color(0xFFE5E7EB);
    final Color textColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FingerprintPinKeypadIconButton extends StatelessWidget {
  const _FingerprintPinKeypadIconButton({
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color surface = isDark ? const Color(0xFF020B1E) : Colors.white;
    final Color border =
        isDark ? const Color(0xFF3A4054) : const Color(0xFFE5E7EB);
    final Color iconColor =
        isDark ? const Color(0xFFE5E7EB) : const Color(0xFF374151);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Center(child: Icon(icon, size: 21, color: iconColor)),
        ),
      ),
    );
  }
}

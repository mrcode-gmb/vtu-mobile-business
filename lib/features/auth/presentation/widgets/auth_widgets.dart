import 'package:flutter/material.dart';

class AuthAlertCard extends StatelessWidget {
  const AuthAlertCard({
    required this.message,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    super.key,
  });

  final String message;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.info_rounded, color: textColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 12.8,
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    required this.controller,
    required this.placeholder,
    super.key,
    this.label,
    this.errorText,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
    this.prefixIcon,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String placeholder;
  final String? label;
  final String? errorText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;
  final IconData? prefixIcon;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool hasError = errorText != null && errorText!.isNotEmpty;

    final Color borderColor =
        hasError
            ? const Color(0xFFFDA4AF)
            : isDark
            ? const Color(0xFF252A42)
            : const Color(0xFFE5E7EB);
    final Color fillColor = isDark ? const Color(0xFF171925) : Colors.white;

    final OutlineInputBorder border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: borderColor),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (label != null) ...<Widget>[
            Text(
              label!,
              style: TextStyle(
                color:
                    isDark ? const Color(0xFFE5E7EB) : const Color(0xFF374151),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
          ],
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            textInputAction: textInputAction,
            style: TextStyle(
              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
              fontSize: 14.2,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: TextStyle(
                color:
                    isDark ? const Color(0xFFC7CDDC) : const Color(0xFF4B5563),
                fontSize: 13.6,
                fontWeight: FontWeight.w400,
              ),
              filled: true,
              fillColor: fillColor,
              border: border,
              enabledBorder: border,
              focusedBorder: border.copyWith(
                borderSide: BorderSide(
                  color:
                      hasError
                          ? const Color(0xFFF43F5E)
                          : const Color(0xFFB89CFF),
                  width: 1.5,
                ),
              ),
              errorBorder: border.copyWith(
                borderSide: const BorderSide(
                  color: Color(0xFFF43F5E),
                  width: 1.2,
                ),
              ),
              focusedErrorBorder: border.copyWith(
                borderSide: const BorderSide(
                  color: Color(0xFFF43F5E),
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 15,
              ),
              prefixIcon:
                  prefixIcon == null
                      ? null
                      : Icon(
                        prefixIcon,
                        size: 19,
                        color:
                            isDark
                                ? const Color(0xFFB89CFF)
                                : const Color(0xFFB89CFF),
                      ),
              prefixIconConstraints: const BoxConstraints(
                minHeight: 22,
                minWidth: 46,
              ),
              suffixIcon: suffix,
              constraints: const BoxConstraints(minHeight: 52),
            ),
          ),
          if (hasError) ...<Widget>[
            const SizedBox(height: 5),
            Text(
              errorText!,
              style: const TextStyle(
                color: Color(0xFFDC2626),
                fontSize: 11.6,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AuthGradientButton extends StatelessWidget {
  const AuthGradientButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.loading = false,
    this.loadingLabel,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final String? loadingLabel;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final bool disabled = loading || onPressed == null;

    return Opacity(
      opacity: disabled ? 0.82 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: const Color(0xFFB89CFF),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: disabled ? null : onPressed,
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              height: 50,
              child: Center(
                child:
                    loading
                        ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              loadingLabel ?? label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                        : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            if (icon != null) ...<Widget>[
                              Icon(icon, size: 18, color: Colors.white),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthSecondaryButton extends StatelessWidget {
  const AuthSecondaryButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: isDark ? const Color(0xFF252A42) : const Color(0xFFE5E7EB),
          ),
          backgroundColor: isDark ? const Color(0xFF171925) : Colors.white,
          foregroundColor:
              isDark ? const Color(0xFFE5E7EB) : const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        icon:
            icon == null
                ? const SizedBox.shrink()
                : Icon(
                  icon,
                  size: 18,
                  color:
                      isDark
                          ? const Color(0xFFB89CFF)
                          : const Color(0xFFB89CFF),
                ),
        label: Text(label),
      ),
    );
  }
}

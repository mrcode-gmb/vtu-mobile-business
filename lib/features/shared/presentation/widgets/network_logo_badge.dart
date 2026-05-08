import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class NetworkLogoBadge extends StatelessWidget {
  const NetworkLogoBadge({
    required this.assetPath,
    this.fallbackLabel,
    this.size = 42,
    this.borderRadius = 14,
    this.backgroundColor = Colors.white,
    this.padding = const EdgeInsets.all(8),
    super.key,
  });

  final String assetPath;
  final String? fallbackLabel;
  final double size;
  final double borderRadius;
  final Color backgroundColor;
  final EdgeInsetsGeometry padding;

  bool get _isSvg => assetPath.toLowerCase().endsWith('.svg');

  Widget _buildFallback() {
    final String label = fallbackLabel?.trim() ?? '';

    return Center(
      child:
          label.isEmpty
              ? const Icon(
                Icons.image_not_supported_outlined,
                size: 18,
                color: Color(0xFF4B5563),
              )
              : Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF374151),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child:
          _isSvg
              ? SvgPicture.asset(
                assetPath,
                fit: BoxFit.contain,
                errorBuilder:
                    (
                      BuildContext context,
                      Object error,
                      StackTrace? stackTrace,
                    ) => _buildFallback(),
              )
              : Image.asset(
                assetPath,
                fit: BoxFit.contain,
                errorBuilder:
                    (
                      BuildContext context,
                      Object error,
                      StackTrace? stackTrace,
                    ) => _buildFallback(),
              ),
    );
  }
}

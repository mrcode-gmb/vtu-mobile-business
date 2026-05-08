import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

Future<T?> showPtsDataLoaderDialog<T>(
  BuildContext context, {
  String text = 'Processing...',
  Color color = const Color(0xFFB89CFF),
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Processing',
    barrierColor: Colors.black.withValues(alpha: 0.18),
    pageBuilder: (BuildContext context, _, __) {
      return Material(
        type: MaterialType.transparency,
        child: PtsDataLoaderOverlay(text: text, color: color),
      );
    },
  );
}

class PtsDataLoaderOverlay extends StatefulWidget {
  const PtsDataLoaderOverlay({
    required this.text,
    this.color = const Color(0xFFB89CFF),
    super.key,
  });

  final String text;
  final Color color;

  @override
  State<PtsDataLoaderOverlay> createState() => _PtsDataLoaderOverlayState();
}

class _PtsDataLoaderOverlayState extends State<PtsDataLoaderOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: ColoredBox(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
        Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, Widget? child) {
              final double pulse =
                  (math.sin(_controller.value * math.pi * 2) + 1) / 2;
              final double scale = 0.8 + (0.2 * pulse);
              final double opacity = 0.25 + (0.55 * pulse);

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: widget.color.withValues(alpha: opacity),
                                width: 4,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 72,
                          height: 72,
                          child: CircularProgressIndicator(
                            strokeWidth: 4,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              widget.color,
                            ),
                            backgroundColor: Colors.transparent,
                          ),
                        ),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: widget.color,
                            shape: BoxShape.circle,
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: widget.color.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Opacity(
                    opacity: 0.65 + (0.35 * pulse),
                    child: Text(
                      widget.text,
                      style: TextStyle(
                        color: widget.color,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'game_button.dart';

/// Authentic Unity TutorialConfiguration Spotlight Overlay
/// Dims the screen (0.72 alpha) with a crisp circular cutout over [targetKey],
/// renders an instructional caption, and animates dl_general_hand_icon.png
/// tapping on the target button until the user taps it.
class BoosterTutorialOverlay extends StatefulWidget {
  final GlobalKey targetKey;
  final String title;
  final String subtitle;
  final VoidCallback onTargetTapped;

  const BoosterTutorialOverlay({
    super.key,
    required this.targetKey,
    required this.title,
    required this.subtitle,
    required this.onTargetTapped,
  });

  @override
  State<BoosterTutorialOverlay> createState() => _BoosterTutorialOverlayState();
}

class _BoosterTutorialOverlayState extends State<BoosterTutorialOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _handController;
  Rect? _targetRect;

  @override
  void initState() {
    super.initState();
    _handController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveTargetRect());
  }

  void _resolveTargetRect() {
    if (!mounted) return;
    final targetCtx = widget.targetKey.currentContext;
    final overlayBox = context.findRenderObject() as RenderBox?;
    if (targetCtx != null && overlayBox != null && overlayBox.hasSize) {
      final targetBox = targetCtx.findRenderObject() as RenderBox?;
      if (targetBox != null && targetBox.hasSize) {
        final topLeft = targetBox.localToGlobal(Offset.zero, ancestor: overlayBox);
        setState(() {
          _targetRect = topLeft & targetBox.size;
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant BoosterTutorialOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveTargetRect());
  }

  @override
  void dispose() {
    _handController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_targetRect == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _resolveTargetRect());
      return const SizedBox.shrink();
    }

    final rect = _targetRect!;
    final center = rect.center;
    final spotRadius = rect.longestSide * 0.58;

    const double handW = 92.0;
    const double handH = 68.0;
    // Fingertip in dl_general_hand_icon.png (256x188) is at bottom-left (0.12 * W, 0.86 * H)
    const double tipOffsetX = handW * 0.12;
    const double tipOffsetY = handH * 0.86;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) {
        if ((details.localPosition - center).distance <= spotRadius + 16) {
          widget.onTargetTapped();
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Dark Spotlight Cutout Mask
          CustomPaint(
            painter: _SpotlightCutoutPainter(
              center: center,
              radius: spotRadius,
            ),
          ),

          // 2. Instructional Text Banner above Bottom Bar
          Positioned(
            left: 28,
            right: 28,
            bottom: (MediaQuery.sizeOf(context).height - rect.top) + 64,
            child: IgnorePointer(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StrokedText(
                    widget.title,
                    fontSize: 26,
                    fillColor: const Color(0xFFFFD829),
                    strokeColor: const Color(0xFF041A38),
                    strokeWidth: 4.5,
                  ),
                  const SizedBox(height: 6),
                  StrokedText(
                    widget.subtitle,
                    fontSize: 17,
                    fillColor: Colors.white,
                    strokeColor: const Color(0xFF041A38),
                    strokeWidth: 3.4,
                    height: 1.3,
                  ),
                ],
              ),
            ),
          ),

          // 3. Pulsing Fingertip Glow + Animated Tutorial Hand pressing on Target
          AnimatedBuilder(
            animation: _handController,
            builder: (context, _) {
              final t = Curves.easeInOut.transform(_handController.value);
              // t=0: hovering slightly up-right, scale 1.0
              // t=1: pressed onto button center, scale 0.88 (exact Unity _handPressScale = 0.88)
              final scale = 1.0 - 0.12 * t;
              final hoverDx = (1.0 - t) * 10.0;
              final hoverDy = -(1.0 - t) * 10.0;
              final glowScale = 0.75 + 0.45 * t;
              final glowAlpha = 0.25 + 0.65 * t;

              return Stack(
                children: [
                  // Bottom fingertip glow ring
                  Positioned(
                    left: center.dx - 38,
                    top: center.dy - 38,
                    child: IgnorePointer(
                      child: Transform.scale(
                        scale: glowScale,
                        child: Opacity(
                          opacity: glowAlpha,
                          child: Image.asset(
                            'assets/images/vfx/dl__tuto_hand_bottom_glow_icon.png',
                            width: 76,
                            height: 76,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Cartoon Glove Hand anchored at its fingertip
                  Positioned(
                    left: center.dx - tipOffsetX + hoverDx,
                    top: center.dy - tipOffsetY + hoverDy,
                    child: IgnorePointer(
                      child: Transform.scale(
                        scale: scale,
                        alignment: const Alignment(-0.76, 0.72),
                        child: Image.asset(
                          'assets/images/icons/dl_general_hand_icon.png',
                          width: handW,
                          height: handH,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SpotlightCutoutPainter extends CustomPainter {
  final Offset center;
  final double radius;

  _SpotlightCutoutPainter({
    required this.center,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fullRect = Offset.zero & size;
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(fullRect)
      ..addOval(Rect.fromCircle(center: center, radius: radius));

    canvas.drawPath(
      path,
      Paint()..color = const Color(0xB8040C1A),
    );

    // Subtle golden highlight ring around spotlight cutout
    canvas.drawCircle(
      center,
      radius + 2.0,
      Paint()
        ..color = const Color(0xAAFFD530)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightCutoutPainter oldDelegate) {
    return oldDelegate.center != center || oldDelegate.radius != radius;
  }
}

import 'package:flutter/material.dart';

enum GameButtonColor { green, orange, blue, red, purple }

/// Renders text with a crisp outer stroke and optional drop shadow,
/// matching Unity TextMeshPro outlined typography.
class StrokedText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color fillColor;
  final Color strokeColor;
  final double strokeWidth;
  final double letterSpacing;
  final List<Shadow>? shadows;
  final TextAlign textAlign;
  final double? height;

  const StrokedText(
    this.text, {
    super.key,
    required this.fontSize,
    this.fillColor = Colors.white,
    this.strokeColor = const Color(0xFF0A2446),
    this.strokeWidth = 3.2,
    this.letterSpacing = 0.3,
    this.shadows,
    this.textAlign = TextAlign.center,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveShadows = shadows ??
        [
          Shadow(
            offset: const Offset(0, 2),
            color: strokeColor.withValues(alpha: 0.85),
            blurRadius: 1.5,
          ),
        ];

    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          text,
          textAlign: textAlign,
          style: TextStyle(
            fontFamily: 'Panteon',
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            letterSpacing: letterSpacing,
            height: height,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..strokeJoin = StrokeJoin.round
              ..color = strokeColor,
            shadows: effectiveShadows,
          ),
        ),
        Text(
          text,
          textAlign: textAlign,
          style: TextStyle(
            fontFamily: 'Panteon',
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            letterSpacing: letterSpacing,
            height: height,
            color: fillColor,
          ),
        ),
      ],
    );
  }
}

class GameButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final GameButtonColor color;
  final double height;
  final double? width;
  final double fontSize;
  final Widget? icon;
  final Widget? child;
  final bool showFrame;

  const GameButton({
    super.key,
    this.text = '',
    required this.onTap,
    this.color = GameButtonColor.green,
    this.height = 56,
    this.width,
    this.fontSize = 20,
    this.icon,
    this.child,
    this.showFrame = false,
  });

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    String assetPath;
    Color strokeColor;
    Color frameTintColor;
    Rect centerSlice;
    double imageScale;

    switch (widget.color) {
      case GameButtonColor.green:
        // 96x96 PNG on disk
        assetPath = 'assets/images/ui/GeneralGreenButton.png';
        strokeColor = const Color(0xFF0E470E);
        frameTintColor = const Color(0xFF003300);
        imageScale = 2.0;
        centerSlice = const Rect.fromLTRB(15, 15, 33, 33);
        break;
      case GameButtonColor.orange:
        // 96x96 PNG on disk
        assetPath = 'assets/images/ui/GeneralOrangeButton.png';
        strokeColor = const Color(0xFF6E2508);
        frameTintColor = const Color(0xFF611C08);
        imageScale = 2.0;
        centerSlice = const Rect.fromLTRB(15, 15, 33, 33);
        break;
      case GameButtonColor.blue:
        // 96x96 PNG on disk
        assetPath = 'assets/images/ui/GeneralBlueButton.png';
        strokeColor = const Color(0xFF0A3A66);
        frameTintColor = const Color(0xFF05224A);
        imageScale = 2.0;
        centerSlice = const Rect.fromLTRB(15, 15, 33, 33);
        break;
      case GameButtonColor.red:
        // 96x96 PNG on disk
        assetPath = 'assets/images/ui/GeneralRedButton.png';
        strokeColor = const Color(0xFF6B1414);
        frameTintColor = const Color(0xFF610C0F);
        imageScale = 2.0;
        centerSlice = const Rect.fromLTRB(15, 15, 33, 33);
        break;
      case GameButtonColor.purple:
        // 256x256 PNG on disk (scaled to match 48x48 logical slice geometry)
        assetPath = 'assets/images/ui/GeneralPurpleButton.png';
        strokeColor = const Color(0xFF3E0B4E);
        frameTintColor = const Color(0xFF30004C);
        imageScale = 256.0 / 48.0;
        centerSlice = const Rect.fromLTRB(15, 15, 33, 33);
        break;
    }

    final Widget innerContent = widget.child ??
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              widget.icon!,
              const SizedBox(width: 8),
            ],
            StrokedText(
              widget.text,
              fontSize: widget.fontSize,
              strokeColor: strokeColor,
              strokeWidth: 3.6,
            ),
          ],
        );

    Widget buttonBody = Container(
      width: widget.width ?? double.infinity,
      height: widget.height,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: ExactAssetImage(assetPath, scale: imageScale),
          centerSlice: centerSlice,
          fit: BoxFit.fill,
        ),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.only(bottom: 4), // Compensate for 3D bottom bevel
      child: innerContent,
    );

    if (widget.showFrame) {
      // Authentic Unity GeneralButtonSlot + GeneralButtonFrame + GeneralButtonFrameColor 9-slice
      buttonBody = SizedBox(
        width: widget.width != null ? widget.width! + 12 : null,
        height: widget.height + 12,
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            // 1. Recessed slot shadow backdrop (384x360, border 190,178,190,178)
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: ExactAssetImage(
                    'assets/images/ui/GeneralButtonSlot.png',
                    scale: 6.4,
                  ),
                  centerSlice: Rect.fromLTRB(
                    160 / 6.4,
                    150 / 6.4,
                    224 / 6.4,
                    210 / 6.4,
                  ),
                  fit: BoxFit.fill,
                ),
              ),
            ),
            // 2. Dark color-tinted inner rim (280x260, border 90,90,90,90)
            Padding(
              padding: const EdgeInsets.all(2.0),
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: const ExactAssetImage(
                      'assets/images/popups/GeneralButtonFrameColor.png',
                      scale: 5.0,
                    ),
                    centerSlice: const Rect.fromLTRB(
                      90 / 5.0,
                      90 / 5.0,
                      190 / 5.0,
                      170 / 5.0,
                    ),
                    colorFilter: ColorFilter.mode(
                      frameTintColor.withValues(alpha: 0.85),
                      BlendMode.modulate,
                    ),
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ),
            // 3. Authentic 3D Gold Metallic Frame (256x256, border 99,111,96,106)
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: ExactAssetImage(
                    'assets/images/popups/GeneralButtonFrame.png',
                    scale: 4.6,
                  ),
                  centerSlice: Rect.fromLTRB(
                    96 / 4.6,
                    102 / 4.6,
                    160 / 4.6,
                    148 / 4.6,
                  ),
                  fit: BoxFit.fill,
                ),
              ),
            ),
            // 4. Inner 3D Colored Button
            Padding(
              padding: const EdgeInsets.fromLTRB(5.5, 5.0, 5.5, 6.5),
              child: buttonBody,
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 85),
        curve: Curves.easeOutQuad,
        child: buttonBody,
      ),
    );
  }
}

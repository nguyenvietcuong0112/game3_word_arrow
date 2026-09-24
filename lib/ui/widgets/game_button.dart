import 'package:flutter/material.dart';

enum GameButtonColor { green, orange, blue, red }

class GameButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final GameButtonColor color;
  final double height;
  final double? width;
  final double fontSize;
  final Widget? icon;

  const GameButton({
    super.key,
    required this.text,
    required this.onTap,
    this.color = GameButtonColor.green,
    this.height = 56,
    this.width,
    this.fontSize = 20,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    String assetPath;
    Color shadowColor;

    switch (color) {
      case GameButtonColor.green:
        assetPath = 'assets/images/ui/GeneralGreenButton.png';
        shadowColor = const Color(0xFF0F4A14);
        break;
      case GameButtonColor.orange:
        assetPath = 'assets/images/ui/GeneralOrangeButton.png';
        shadowColor = const Color(0xFF7C2D12);
        break;
      case GameButtonColor.blue:
        assetPath = 'assets/images/ui/GeneralBlueButton.png';
        shadowColor = const Color(0xFF0C4A6E);
        break;
      case GameButtonColor.red:
        assetPath = 'assets/images/ui/GeneralRedButton.png';
        shadowColor = const Color(0xFF7F1D1D);
        break;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(assetPath),
            centerSlice: const Rect.fromLTRB(20, 20, 76, 76),
            fit: BoxFit.fill,
          ),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.only(bottom: 5), // Compensate for 3D bevel bottom
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              icon!,
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: TextStyle(
                fontFamily: 'Panteon',
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: [
                  Shadow(
                    offset: const Offset(0, 2),
                    color: shadowColor,
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

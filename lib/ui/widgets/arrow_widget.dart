import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/game_palette.dart';

class ArrowWidget extends StatelessWidget {
  final String direction; // 'up', 'down', 'left', 'right'
  final int length;
  final int colorId;
  final double size;
  final bool isHighlighted;

  const ArrowWidget({
    super.key,
    required this.direction,
    required this.length,
    required this.colorId,
    required this.size,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = GamePalette.getStyle(colorId);

    double angle = 0;
    switch (direction.toLowerCase()) {
      case 'up':
        angle = 0;
        break;
      case 'right':
        angle = pi / 2;
        break;
      case 'down':
        angle = pi;
        break;
      case 'left':
        angle = -pi / 2;
        break;
    }

    final Color tintColor = isHighlighted ? const Color(0xFFFFE082) : style.light;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Authentic triangular soft shadow rotated in flight direction
          Transform.rotate(
            angle: angle,
            child: Image.asset(
              'assets/images/board/arrow_shadow.png',
              width: size * 0.98,
              height: size * 0.98,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const SizedBox(),
            ),
          ),

          // Authentic 3D Arrow Sprite rotated in flight direction
          Transform.rotate(
            angle: angle,
            child: Image.asset(
              'assets/images/board/arrow_base.png',
              width: size * 0.94,
              height: size * 0.94,
              color: tintColor,
              colorBlendMode: BlendMode.modulate,
              fit: BoxFit.contain,
            ),
          ),

          // Length number unrotated for maximum readability
          Center(
            child: Text(
              '$length',
              style: TextStyle(
                fontSize: size * 0.44,
                fontWeight: FontWeight.w900,
                fontFamily: 'Panteon',
                color: style.textColor,
                shadows: [
                  Shadow(
                    offset: const Offset(0.5, 0.5),
                    color: Colors.white.withOpacity(0.5),
                    blurRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

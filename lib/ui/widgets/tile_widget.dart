import 'package:flutter/material.dart';
import '../../models/game_palette.dart';

class TileWidget extends StatelessWidget {
  final String letter;
  final bool isFirstLetter;
  final int colorId;
  final bool isHighlighted;
  final double size;

  const TileWidget({
    super.key,
    required this.letter,
    required this.isFirstLetter,
    required this.colorId,
    this.isHighlighted = false,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final style = GamePalette.getStyle(colorId);

    // Authentic tile color tinting
    final Color tintColor = isHighlighted
        ? const Color(0xFFFFE082)
        : (isFirstLetter ? style.light : const Color(0xFFFAF7F2));

    final Color textColor = isFirstLetter ? style.textColor : const Color(0xFF261912);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft drop shadow under bottom bevel
          Positioned(
            bottom: -size * 0.02,
            child: Image.asset(
              'assets/images/board/tile_shadow.png',
              width: size * 0.98,
              height: size * 0.98,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const SizedBox(),
            ),
          ),

          // Authentic 3D Tile Sprite
          Image.asset(
            'assets/images/board/tile_base.png',
            width: size * 0.96,
            height: size * 0.96,
            color: tintColor,
            colorBlendMode: BlendMode.modulate,
            fit: BoxFit.contain,
          ),

          // Letter Glyph
          Center(
            child: Padding(
              // Offset slightly up because bottom has 3D bevel extrusion
              padding: EdgeInsets.only(bottom: size * 0.06),
              child: Text(
                letter,
                style: TextStyle(
                  fontSize: size * 0.52,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Panteon',
                  color: textColor,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

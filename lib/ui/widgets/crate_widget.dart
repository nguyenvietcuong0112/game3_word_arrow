import 'package:flutter/material.dart';

class CrateWidget extends StatelessWidget {
  final int threshold;
  final double size;

  const CrateWidget({
    super.key,
    required this.threshold,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft drop shadow
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
          // Authentic Wooden Crate Sprite
          Image.asset(
            'assets/images/board/crate.png',
            width: size * 0.96,
            height: size * 0.96,
            fit: BoxFit.contain,
          ),
          // Threshold Number
          Padding(
            padding: EdgeInsets.only(bottom: size * 0.04),
            child: Text(
              '$threshold',
              style: TextStyle(
                fontSize: size * 0.44,
                fontWeight: FontWeight.w900,
                fontFamily: 'Panteon',
                color: const Color(0xFF261912),
                shadows: const [
                  Shadow(
                    offset: Offset(1, 1),
                    color: Color(0xFFFED8A6),
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

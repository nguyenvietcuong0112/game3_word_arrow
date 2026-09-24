import 'package:flutter/material.dart';

class GameTopBar extends StatelessWidget {
  final int levelNumber;
  final int stars;
  final int coins;
  final VoidCallback onLevelTap;

  const GameTopBar({
    super.key,
    required this.levelNumber,
    required this.stars,
    required this.coins,
    required this.onLevelTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Level Pill Button
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onLevelTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF08489E),
                    Color(0xFF012468),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF00B4FF),
                  width: 2.2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFF01163C),
                    offset: Offset(0, 2.5),
                    blurRadius: 0,
                    spreadRadius: 1.2,
                  ),
                ],
              ),
              child: Text(
                'Level $levelNumber',
                style: const TextStyle(
                  fontFamily: 'Panteon',
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1.5),
                      color: Color(0xFF01163C),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Star Container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF08489E),
                  Color(0xFF012468),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFF00B4FF),
                width: 2.2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFF01163C),
                  offset: Offset(0, 2.5),
                  blurRadius: 0,
                  spreadRadius: 1.2,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                final isLit = index < stars;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                  child: Image.asset(
                    isLit
                        ? 'assets/images/gameplay/WordsArrowIngameGoldStar.png'
                        : 'assets/images/gameplay/WordsArrowIngameGreyStar.png',
                    width: 28,
                    height: 28,
                  ),
                );
              }),
            ),
          ),

          // Coin Container with Authentic GenericPuzzleCurrencyBG & CurrencyCoinIcon
          SizedBox(
            width: 112,
            height: 42,
            child: Stack(
              alignment: Alignment.centerLeft,
              clipBehavior: Clip.none,
              children: [
                // Authentic Background pill
                Positioned(
                  left: 14,
                  right: 0,
                  top: 1,
                  bottom: 1,
                  child: Container(
                    padding: const EdgeInsets.only(left: 20, right: 8),
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/backgrounds/GenericPuzzleCurrencyBG_scaled.png'),
                        centerSlice: Rect.fromLTRB(24, 8, 96, 38),
                        fit: BoxFit.fill,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _formatCoins(coins),
                      style: const TextStyle(
                        fontFamily: 'Panteon',
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF381005),
                      ),
                    ),
                  ),
                ),
                // Authentic Coin Icon with Plus button
                Positioned(
                  left: 0,
                  top: 2,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Image.asset(
                        'assets/images/icons/CurrencyCoinIcon.png',
                        width: 38,
                        height: 38,
                      ),
                      Positioned(
                        bottom: -1,
                        right: -1,
                        child: Image.asset(
                          'assets/images/ui/PlusButton.png',
                          width: 16,
                          height: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCoins(int count) {
    if (count >= 1000) {
      final k = count / 1000.0;
      return k.toStringAsFixed(3);
    }
    return count.toString();
  }
}

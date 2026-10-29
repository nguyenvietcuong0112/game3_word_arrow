import 'package:flutter/material.dart';
import 'game_button.dart';

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
      padding: const EdgeInsets.fromLTRB(14.0, 14.0, 14.0, 6.0),
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
                    Color(0xFF0A4DA4),
                    Color(0xFF02266C),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF00B4FF),
                  width: 2.0,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xCC01163C),
                    offset: Offset(0, 2.0),
                    blurRadius: 1.5,
                    spreadRadius: 0.5,
                  ),
                ],
              ),
              child: StrokedText(
                'Level $levelNumber',
                fontSize: 18,
                fillColor: Colors.white,
                strokeColor: const Color(0xFF011B47),
                strokeWidth: 3.4,
              ),
            ),
          ),

          // Star Container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0A4DA4),
                  Color(0xFF02266C),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFF00B4FF),
                width: 2.0,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xCC01163C),
                  offset: Offset(0, 2.0),
                  blurRadius: 1.5,
                  spreadRadius: 0.5,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                final isLit = index < stars;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: Image.asset(
                    isLit
                        ? 'assets/images/gameplay/WordsArrowIngameGoldStar.png'
                        : 'assets/images/gameplay/WordsArrowIngameGreyStar.png',
                    width: 26,
                    height: 26,
                  ),
                );
              }),
            ),
          ),

          // Coin Container matching authentic Unity top-right coin badge (coin_badge_real.png)
          SizedBox(
            width: 118,
            height: 44,
            child: Stack(
              alignment: Alignment.centerLeft,
              clipBehavior: Clip.none,
              children: [
                // Recessed cream/peach capsule pill (slimmer than the coin icon so the coin overhangs top & bottom)
                Positioned(
                  left: 18,
                  right: 0,
                  top: 6.5,
                  bottom: 6.5,
                  child: Container(
                    padding: const EdgeInsets.only(left: 24, right: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFD8AB8A),
                        width: 1.5,
                      ),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.0, 0.18, 0.55, 1.0],
                        colors: [
                          Color(0xFFC5916E),
                          Color(0xFFECCBB1),
                          Color(0xFFF6DFC9),
                          Color(0xFFFAE9D8),
                        ],
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x403E1604),
                          offset: Offset(0, 1.5),
                          blurRadius: 2.0,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: StrokedText(
                      _formatCoins(coins),
                      fontSize: 16.5,
                      fillColor: const Color(0xFFFFF9F0),
                      strokeColor: const Color(0xFF470C10),
                      strokeWidth: 3.4,
                    ),
                  ),
                ),
                // Authentic Coin Icon with Plus button
                Positioned(
                  left: 0,
                  top: 0,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Image.asset(
                        'assets/images/icons/CurrencyCoinIcon.png',
                        width: 44,
                        height: 44,
                      ),
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: Image.asset(
                          'assets/images/ui/PlusButton.png',
                          width: 19,
                          height: 19,
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

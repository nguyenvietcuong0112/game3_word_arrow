import 'package:flutter/material.dart';
import '../widgets/game_button.dart';
import '../widgets/game_popup_dialog.dart';

class VictoryDialog extends StatelessWidget {
  final int levelNumber;
  final int stars;
  final int coinsEarned;
  final VoidCallback onNextLevel;
  final VoidCallback onReplay;

  const VictoryDialog({
    super.key,
    required this.levelNumber,
    required this.stars,
    required this.coinsEarned,
    required this.onNextLevel,
    required this.onReplay,
  });

  @override
  Widget build(BuildContext context) {
    return GamePopupDialog(
      title: 'VICTORY!',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Level $levelNumber Completed',
            style: const TextStyle(
              fontFamily: 'Panteon',
              fontSize: 16,
              color: Colors.white,
              shadows: [
                Shadow(
                  offset: Offset(0, 1),
                  color: Color(0xFF0C4A6E),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3 Stars Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              final isLit = index < stars;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: Image.asset(
                  isLit
                      ? 'assets/images/gameplay/WordsArrowIngameGoldStar.png'
                      : 'assets/images/gameplay/WordsArrowIngameGreyStar.png',
                  width: 52,
                  height: 52,
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          // Coins Earned Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFDE8D0),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF59E0B), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  offset: const Offset(0, 2),
                  blurRadius: 3,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/icons/Coin.png', width: 28, height: 28),
                const SizedBox(width: 8),
                Text(
                  '+$coinsEarned Coins',
                  style: const TextStyle(
                    fontFamily: 'Panteon',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF78350F),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Next Level Button (Green 9-patch GameButton)
          GameButton(
            text: 'NEXT LEVEL',
            color: GameButtonColor.green,
            height: 54,
            fontSize: 20,
            onTap: onNextLevel,
          ),
          const SizedBox(height: 10),

          // Replay Button (Orange 9-patch GameButton)
          GameButton(
            text: 'REPLAY',
            color: GameButtonColor.orange,
            height: 48,
            fontSize: 17,
            onTap: onReplay,
          ),
        ],
      ),
    );
  }
}

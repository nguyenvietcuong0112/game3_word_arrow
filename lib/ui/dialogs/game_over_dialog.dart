import 'package:flutter/material.dart';
import '../widgets/game_button.dart';
import '../widgets/game_popup_dialog.dart';

class GameOverDialog extends StatelessWidget {
  final int levelNumber;
  final bool isOutOfStars;
  final VoidCallback onRetry;
  final VoidCallback onRevive;

  const GameOverDialog({
    super.key,
    required this.levelNumber,
    required this.isOutOfStars,
    required this.onRetry,
    required this.onRevive,
  });

  @override
  Widget build(BuildContext context) {
    return GamePopupDialog(
      title: isOutOfStars ? 'OUT OF STARS!' : 'OUT OF MOVES!',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Level $levelNumber',
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

          // Icon
          Image.asset(
            'assets/images/gameplay/WordsArrowIngameGreyStar.png',
            width: 68,
            height: 68,
          ),
          const SizedBox(height: 24),

          // Revive Button
          GameButton(
            text: 'REVIVE (+10 Moves)',
            color: GameButtonColor.green,
            height: 54,
            fontSize: 18,
            onTap: onRevive,
          ),
          const SizedBox(height: 12),

          // Retry Button
          GameButton(
            text: 'RETRY LEVEL',
            color: GameButtonColor.orange,
            height: 48,
            fontSize: 17,
            onTap: onRetry,
          ),
        ],
      ),
    );
  }
}

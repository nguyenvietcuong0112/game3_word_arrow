import 'package:flutter/material.dart';
import '../widgets/game_button.dart';

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
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 350),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // Authentic 9-patch Unity Red Frame (VeryHardPopup)
            Container(
              margin: const EdgeInsets.only(top: 36),
              width: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/popups/VeryHardPopup.png'),
                  centerSlice: Rect.fromLTRB(160, 160, 520, 440),
                  fit: BoxFit.fill,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 52, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Subtitle / Failure reason banner
                  Text(
                    isOutOfStars ? 'OUT OF STARS!' : 'OUT OF MOVES!',
                    style: const TextStyle(
                      fontFamily: 'Panteon',
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFFE600), // bright golden yellow
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 3),
                          color: Color(0xFF50000E),
                          blurRadius: 3,
                        ),
                        Shadow(
                          offset: Offset(0, 1),
                          color: Color(0xFF50000E),
                          blurRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Authentic Sad/Broken Star Artwork
                  Image.asset(
                    'assets/images/gameplay/WordsArrowNoAvailableStars.png',
                    width: 130,
                    height: 130,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 14),

                  // Explanatory hint text
                  Text(
                    isOutOfStars
                      ? 'You hit blocked arrows too many times!'
                      : 'You ran out of moves to clear the board!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Panteon',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1.5),
                          color: Color(0xFF50000E),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Revive Button (Green 3D Button)
                  SizedBox(
                    width: 240,
                    height: 58,
                    child: GameButton(
                      text: isOutOfStars ? 'REVIVE (+1 Star)' : 'REVIVE (+10 Moves)',
                      color: GameButtonColor.green,
                      height: 58,
                      fontSize: 18,
                      onTap: onRevive,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Retry Button (Orange 3D Button)
                  SizedBox(
                    width: 220,
                    height: 50,
                    child: GameButton(
                      text: 'RETRY LEVEL',
                      color: GameButtonColor.orange,
                      height: 50,
                      fontSize: 16,
                      onTap: onRetry,
                    ),
                  ),
                ],
              ),
            ),

            // Top Header Banner with RedPopupTitle
            Positioned(
              top: 0,
              child: SizedBox(
                width: 270,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      'assets/images/popups/RedPopupTitle.png',
                      width: 270,
                      height: 80,
                      fit: BoxFit.fill,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'LEVEL $levelNumber',
                        style: const TextStyle(
                          fontFamily: 'Panteon',
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.0,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 2.5),
                              color: Color(0xFF50000E),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Top-right Close Button
            Positioned(
              top: 14,
              right: 8,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onRetry,
                child: SizedBox(
                  width: 46,
                  height: 46,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        'assets/images/popups/CloseButtonFrame.png',
                        width: 46,
                        height: 46,
                      ),
                      Image.asset(
                        'assets/images/ui/BannerCloseButton.png',
                        width: 34,
                        height: 30,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

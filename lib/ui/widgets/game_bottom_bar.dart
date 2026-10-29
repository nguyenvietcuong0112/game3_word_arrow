import 'package:flutter/material.dart';
import 'game_button.dart';

class GameBottomBar extends StatelessWidget {
  final VoidCallback onHintTap;
  final VoidCallback onHammerTap;
  final VoidCallback onRocketTap;
  final VoidCallback onSettingsTap;

  final bool isHammerActive;

  final bool isHintLocked;
  final bool isHammerLocked;
  final bool isFireworkLocked;

  final int hintCount;
  final int hammerCount;
  final int fireworkCount;

  final GlobalKey? hintButtonKey;
  final GlobalKey? hammerButtonKey;
  final GlobalKey? fireworkButtonKey;

  const GameBottomBar({
    super.key,
    required this.onHintTap,
    required this.onHammerTap,
    required this.onRocketTap,
    required this.onSettingsTap,
    this.isHammerActive = false,
    this.isHintLocked = false,
    this.isHammerLocked = false,
    this.isFireworkLocked = false,
    this.hintCount = 0,
    this.hammerCount = 0,
    this.fireworkCount = 0,
    this.hintButtonKey,
    this.hammerButtonKey,
    this.fireworkButtonKey,
  });

  @override
  Widget build(BuildContext context) {
    const double boosterSize = 76.0;
    const double settingsSize = 52.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0, left: 28, right: 20, top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Hint Booster (Unlocks Level 3)
          _buildBoosterButton(
            buttonKey: hintButtonKey,
            iconAsset: 'assets/images/boosters/WordsArrowHintBooster.png',
            onTap: onHintTap,
            size: boosterSize,
            isLocked: isHintLocked,
            count: hintCount,
          ),
          const SizedBox(width: 14),

          // 2. Hammer Booster (Unlocks Level 6)
          _buildBoosterButton(
            buttonKey: hammerButtonKey,
            iconAsset: 'assets/images/boosters/WordsArrowHammerBooster.png',
            onTap: onHammerTap,
            size: boosterSize,
            isLocked: isHammerLocked,
            count: hammerCount,
            isActive: isHammerActive,
          ),
          const SizedBox(width: 14),

          // 3. Firework / Rocket Booster (Unlocks Level 9)
          _buildBoosterButton(
            buttonKey: fireworkButtonKey,
            iconAsset: 'assets/images/boosters/WordsArrowFireworkBooster.png',
            onTap: onRocketTap,
            size: boosterSize,
            isLocked: isFireworkLocked,
            count: fireworkCount,
          ),
          const SizedBox(width: 18),

          // 4. Settings Button (52x52, slightly lower matching Unity bottom bar)
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: _buildSettingsButton(
              onTap: onSettingsTap,
              size: settingsSize,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoosterButton({
    GlobalKey? buttonKey,
    required String iconAsset,
    required VoidCallback onTap,
    required double size,
    required bool isLocked,
    required int count,
    bool isActive = false,
  }) {
    return GestureDetector(
      key: buttonKey,
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Active glow when Hammer is armed
            if (isActive && !isLocked)
              Container(
                width: size * 1.15,
                height: size * 1.15,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amberAccent.withValues(alpha: 0.85),
                      blurRadius: 16,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),

            // Inner Blue Disc (slightly dimmed if locked)
            Opacity(
              opacity: isLocked ? 0.78 : 1.0,
              child: Image.asset(
                'assets/images/boosters/IngameBoosterButton.png',
                width: size * 0.88,
                height: size * 0.88,
                fit: BoxFit.contain,
              ),
            ),

            // Outer Gold / Orange Ring Frame
            Opacity(
              opacity: isLocked ? 0.82 : 1.0,
              child: Image.asset(
                'assets/images/boosters/IngameBoosterButtonFrame.png',
                width: size,
                height: size,
                fit: BoxFit.contain,
              ),
            ),

            // Center Content: Padlock when locked, Booster Icon when unlocked
            if (isLocked)
              Padding(
                padding: EdgeInsets.all(size * 0.25),
                child: Image.asset(
                  'assets/images/gameplay/IngameLockIcon.png',
                  fit: BoxFit.contain,
                ),
              )
            else
              Padding(
                padding: EdgeInsets.all(size * 0.16),
                child: Image.asset(
                  iconAsset,
                  fit: BoxFit.contain,
                ),
              ),

            // Bottom-Right Badge when unlocked:
            // - count > 0 -> RedNotification.png with stroked count
            // - count == 0 -> PlusButton.png
            if (!isLocked && count > 0)
              Positioned(
                bottom: -1,
                right: -1,
                child: SizedBox(
                  width: size * 0.36,
                  height: size * 0.36,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        'assets/images/ui/RedNotification.png',
                        width: size * 0.36,
                        height: size * 0.36,
                        fit: BoxFit.contain,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 1),
                        child: StrokedText(
                          '$count',
                          fontSize: 14,
                          fillColor: Colors.white,
                          strokeColor: const Color(0xFF5A0B0E),
                          strokeWidth: 3.0,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (!isLocked && count <= 0)
              Positioned(
                bottom: 0,
                right: 0,
                child: Image.asset(
                  'assets/images/ui/PlusButton.png',
                  width: size * 0.34,
                  height: size * 0.34,
                  fit: BoxFit.contain,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsButton({
    required VoidCallback onTap,
    required double size,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              'assets/images/boosters/IngameBoosterButton.png',
              width: size * 0.88,
              height: size * 0.88,
              fit: BoxFit.contain,
            ),
            Image.asset(
              'assets/images/popups/IngameSettingsButtonFrame.png',
              width: size,
              height: size,
              fit: BoxFit.contain,
            ),
            Padding(
              padding: EdgeInsets.all(size * 0.27),
              child: Image.asset(
                'assets/images/icons/SettingsWheelIcon.png',
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

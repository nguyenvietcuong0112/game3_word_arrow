import 'package:flutter/material.dart';

class GameBottomBar extends StatelessWidget {
  final VoidCallback onHintTap;
  final VoidCallback onHammerTap;
  final VoidCallback onRocketTap;
  final VoidCallback onSettingsTap;
  final bool isHammerActive;

  const GameBottomBar({
    super.key,
    required this.onHintTap,
    required this.onHammerTap,
    required this.onRocketTap,
    required this.onSettingsTap,
    this.isHammerActive = false,
  });

  @override
  Widget build(BuildContext context) {
    const double buttonSize = 72.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0, left: 16, right: 16, top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 1. Hint Booster
          _buildBoosterButton(
            iconAsset: 'assets/images/boosters/WordsArrowHintBooster.png',
            onTap: onHintTap,
            size: buttonSize,
            showPlus: true,
          ),
          // 2. Hammer Booster
          _buildBoosterButton(
            iconAsset: 'assets/images/boosters/WordsArrowHammerBooster.png',
            onTap: onHammerTap,
            size: buttonSize,
            showPlus: true,
            isActive: isHammerActive,
          ),
          // 3. Rocket Booster
          _buildBoosterButton(
            iconAsset: 'assets/images/boosters/WordsArrowFireworkBooster.png',
            onTap: onRocketTap,
            size: buttonSize,
            showPlus: true,
          ),
          // 4. Settings Button
          _buildSettingsButton(
            onTap: onSettingsTap,
            size: buttonSize * 0.88,
          ),
        ],
      ),
    );
  }

  Widget _buildBoosterButton({
    required String iconAsset,
    required VoidCallback onTap,
    required double size,
    bool showPlus = false,
    bool isActive = false,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Active glow
            if (isActive)
              Container(
                width: size * 1.15,
                height: size * 1.15,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amberAccent.withOpacity(0.8),
                      blurRadius: 16,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),

            // Inner Blue Disc
            Image.asset(
              'assets/images/boosters/IngameBoosterButton.png',
              width: size,
              height: size,
              fit: BoxFit.contain,
            ),

            // Outer Gold / Orange Ring Frame
            Image.asset(
              'assets/images/boosters/IngameBoosterButtonFrame.png',
              width: size,
              height: size,
              fit: BoxFit.contain,
            ),

            // Booster Icon
            Padding(
              padding: EdgeInsets.all(size * 0.16),
              child: Image.asset(
                iconAsset,
                fit: BoxFit.contain,
              ),
            ),

            // Plus Button Badge
            if (showPlus)
              Positioned(
                bottom: 0,
                right: 0,
                child: Image.asset(
                  'assets/images/ui/PlusButton.png',
                  width: size * 0.36,
                  height: size * 0.36,
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
            // Inner Blue Disc
            Image.asset(
              'assets/images/boosters/IngameBoosterButton.png',
              width: size,
              height: size,
              fit: BoxFit.contain,
            ),

            // Outer Blue Ring Frame
            Image.asset(
              'assets/images/popups/IngameSettingsButtonFrame.png',
              width: size,
              height: size,
              fit: BoxFit.contain,
            ),

            // White Gear Icon
            Padding(
              padding: EdgeInsets.all(size * 0.22),
              child: Image.asset(
                'assets/images/icons/SettingsWheelIcon.png',
                fit: BoxFit.contain,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

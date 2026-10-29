import 'package:flutter/material.dart';
import '../../services/audio_service.dart';

class SettingsDialog extends StatefulWidget {
  final VoidCallback onExitLevel;

  const SettingsDialog({
    super.key,
    required this.onExitLevel,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog>
    with SingleTickerProviderStateMixin {
  final AudioService _audio = AudioService();
  late final AnimationController _animController;
  late final Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..forward();
    _expandAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double itemSize = 54.0;
    const double gearSize = 52.0;

    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.pop(context),
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              // Vertical column of circular buttons anchored at bottom-right above Settings gear
              Positioned(
                right: 20,
                bottom: 24,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: _expandAnim,
                      alignment: Alignment.bottomCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 1. Exit / Quit Level Button (Red -> opens QuitLevelDialog)
                          _buildRoundToggleBtn(
                            size: itemSize,
                            iconAsset: 'assets/images/icons/ExitIcon.png',
                            isActive: false,
                            isExitButton: true,
                            onTap: () {
                              _audio.playButtonClick();
                              Navigator.pop(context);
                              widget.onExitLevel();
                            },
                          ),
                          const SizedBox(height: 12),

                          // 2. Vibration / Haptics Toggle Button
                          _buildRoundToggleBtn(
                            size: itemSize,
                            iconAsset: 'assets/images/icons/VibrationIcon.png',
                            isActive: _audio.isVibrationEnabled,
                            onTap: () async {
                              await _audio.toggleVibration();
                              _audio.playButtonClick();
                              setState(() {});
                            },
                          ),
                          const SizedBox(height: 12),

                          // 3. Sound FX Toggle Button
                          _buildRoundToggleBtn(
                            size: itemSize,
                            iconAsset: 'assets/images/icons/SoundIcon.png',
                            isActive: _audio.isSfxEnabled,
                            onTap: () async {
                              await _audio.toggleSfx();
                              _audio.playButtonClick();
                              setState(() {});
                            },
                          ),
                          const SizedBox(height: 12),

                          // 4. Music Toggle Button
                          _buildRoundToggleBtn(
                            size: itemSize,
                            iconAsset: 'assets/images/icons/MusicIcon.png',
                            isActive: _audio.isMusicEnabled,
                            onTap: () async {
                              await _audio.toggleMusic();
                              _audio.playButtonClick();
                              setState(() {});
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),

                    // 5. Bottom Settings Gear Button (illuminated in place)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        _audio.playButtonClick();
                        Navigator.pop(context);
                      },
                      child: SizedBox(
                        width: gearSize,
                        height: gearSize,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.asset(
                              'assets/images/boosters/IngameBoosterButton.png',
                              width: gearSize * 0.88,
                              height: gearSize * 0.88,
                              fit: BoxFit.contain,
                            ),
                            Image.asset(
                              'assets/images/popups/IngameSettingsButtonFrame.png',
                              width: gearSize,
                              height: gearSize,
                              fit: BoxFit.contain,
                            ),
                            Padding(
                              padding: EdgeInsets.all(gearSize * 0.27),
                              child: Image.asset(
                                'assets/images/icons/SettingsWheelIcon.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoundToggleBtn({
    required double size,
    required String iconAsset,
    required bool isActive,
    required VoidCallback onTap,
    bool isExitButton = false,
  }) {
    final String innerAsset = (!isExitButton && isActive)
        ? 'assets/images/ui/SettingsButtonGreen.png'
        : 'assets/images/ui/SettingsButtonRed.png';

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
              'assets/images/popups/SettingsButtonFrame.png',
              width: size,
              height: size,
              fit: BoxFit.contain,
            ),
            Image.asset(
              innerAsset,
              width: size * 0.78,
              height: size * 0.78,
              fit: BoxFit.contain,
            ),
            Padding(
              padding: EdgeInsets.all(size * 0.24),
              child: Image.asset(
                iconAsset,
                fit: BoxFit.contain,
              ),
            ),
            if (!isExitButton && !isActive)
              Padding(
                padding: EdgeInsets.all(size * 0.22),
                child: Image.asset(
                  'assets/images/ui/SettingsDeleteLine.png',
                  fit: BoxFit.contain,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

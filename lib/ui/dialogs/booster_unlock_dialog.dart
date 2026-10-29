import 'package:flutter/material.dart';
import '../../services/level_service.dart';
import '../widgets/game_button.dart';

/// Authentic Unity InGameBoosterUnlockFrame
/// Shown when unlocking Hint (Level 3), Hammer (Level 6), and Firework (Level 9).
class BoosterUnlockDialog extends StatefulWidget {
  final BoosterType boosterType;
  final VoidCallback onClaim;

  const BoosterUnlockDialog({
    super.key,
    required this.boosterType,
    required this.onClaim,
  });

  @override
  State<BoosterUnlockDialog> createState() => _BoosterUnlockDialogState();
}

class _BoosterUnlockDialogState extends State<BoosterUnlockDialog>
    with TickerProviderStateMixin {
  late final AnimationController _sunburstController;
  late final AnimationController _popController;
  late final Animation<double> _popScale;

  @override
  void initState() {
    super.initState();
    _sunburstController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..forward();
    _popScale = CurvedAnimation(
      parent: _popController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _sunburstController.dispose();
    _popController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = LevelService.boosterTitle(widget.boosterType);
    final desc = LevelService.boosterDescription(widget.boosterType);
    final iconAsset = LevelService.boosterIconAsset(widget.boosterType);

    return Material(
      type: MaterialType.transparency,
      child: Container(
        color: const Color(0xD8050E1E),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: SafeArea(
          child: ScaleTransition(
            scale: _popScale,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const StrokedText(
                  'New Booster Unlocked',
                  fontSize: 28,
                  fillColor: Color(0xFFFFD829),
                  strokeColor: Color(0xFF041A38),
                  strokeWidth: 4.8,
                ),
                const SizedBox(height: 8),
                StrokedText(
                  title,
                  fontSize: 25,
                  fillColor: Colors.white,
                  strokeColor: const Color(0xFF041A38),
                  strokeWidth: 4.2,
                ),
                const SizedBox(height: 18),

                // Rotating Sunburst + Booster Badge & "+1" Free Gift Pill
                SizedBox(
                  width: 240,
                  height: 230,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      RotationTransition(
                        turns: _sunburstController,
                        child: Opacity(
                          opacity: 0.75,
                          child: Image.asset(
                            'assets/images/ui/dl_general_sunburst.png',
                            width: 236,
                            height: 236,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 156,
                        height: 156,
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            Image.asset(
                              'assets/images/boosters/IngameBoosterButton.png',
                              width: 138,
                              height: 138,
                              fit: BoxFit.contain,
                            ),
                            Image.asset(
                              'assets/images/boosters/IngameBoosterButtonFrame.png',
                              width: 156,
                              height: 156,
                              fit: BoxFit.contain,
                            ),
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Image.asset(
                                iconAsset,
                                fit: BoxFit.contain,
                              ),
                            ),
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: SizedBox(
                                width: 46,
                                height: 46,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/images/ui/RedNotification.png',
                                      width: 46,
                                      height: 46,
                                    ),
                                    const StrokedText(
                                      'x1',
                                      fontSize: 18,
                                      strokeColor: Color(0xFF5A0B0E),
                                      strokeWidth: 3.4,
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
                const SizedBox(height: 16),

                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 306),
                  child: StrokedText(
                    desc,
                    fontSize: 17,
                    fillColor: Colors.white,
                    strokeColor: const Color(0xFF041A38),
                    strokeWidth: 3.2,
                    height: 1.32,
                  ),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: 226,
                  child: GameButton(
                    text: 'Claim',
                    color: GameButtonColor.green,
                    height: 58,
                    fontSize: 24,
                    showFrame: true,
                    onTap: widget.onClaim,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

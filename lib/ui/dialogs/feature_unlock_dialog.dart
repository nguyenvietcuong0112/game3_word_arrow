import 'package:flutter/material.dart';
import '../widgets/game_button.dart';

/// Authentic Unity InGameFeatureUnlockFrame
/// Shown on first encounter with Crates (Level 10), Hidden Arrows (Level 13),
/// and Locks & Keys (Level 21).
class FeatureUnlockDialog extends StatefulWidget {
  final String featureName;
  final String description;
  final String iconAsset;
  final VoidCallback onContinue;

  const FeatureUnlockDialog({
    super.key,
    required this.featureName,
    required this.description,
    required this.iconAsset,
    required this.onContinue,
  });

  @override
  State<FeatureUnlockDialog> createState() => _FeatureUnlockDialogState();
}

class _FeatureUnlockDialogState extends State<FeatureUnlockDialog>
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
                  'New Feature Unlocked',
                  fontSize: 28,
                  fillColor: Color(0xFFFFD829),
                  strokeColor: Color(0xFF041A38),
                  strokeWidth: 4.8,
                ),
                const SizedBox(height: 8),
                StrokedText(
                  widget.featureName,
                  fontSize: 24,
                  fillColor: Colors.white,
                  strokeColor: const Color(0xFF041A38),
                  strokeWidth: 4.2,
                ),
                const SizedBox(height: 18),

                // Rotating Sunburst + Feature Icon
                SizedBox(
                  width: 240,
                  height: 240,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      RotationTransition(
                        turns: _sunburstController,
                        child: Opacity(
                          opacity: 0.72,
                          child: Image.asset(
                            'assets/images/ui/dl_general_sunburst.png',
                            width: 240,
                            height: 240,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      Image.asset(
                        widget.iconAsset,
                        width: 184,
                        height: 184,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 310),
                  child: StrokedText(
                    widget.description,
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
                    text: 'Continue',
                    color: GameButtonColor.green,
                    height: 58,
                    fontSize: 24,
                    showFrame: true,
                    onTap: widget.onContinue,
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

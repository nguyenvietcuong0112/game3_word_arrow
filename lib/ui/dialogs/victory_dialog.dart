import 'package:flutter/material.dart';
import '../widgets/game_button.dart';
import '../widgets/game_popup_dialog.dart';

class VictoryDialog extends StatefulWidget {
  final int levelNumber;
  final int difficulty;
  final int stars;
  final int baseCoins;
  final int adCoins;
  final VoidCallback onContinue;
  final VoidCallback onClaimAdMultiplier;

  const VictoryDialog({
    super.key,
    required this.levelNumber,
    this.difficulty = 1,
    required this.stars,
    this.baseCoins = 10,
    this.adCoins = 50,
    required this.onContinue,
    required this.onClaimAdMultiplier,
  });

  @override
  State<VictoryDialog> createState() => _VictoryDialogState();
}

class _VictoryDialogState extends State<VictoryDialog>
    with TickerProviderStateMixin {
  late final AnimationController _sunburstController;
  late final AnimationController _sparkleController;
  late final AnimationController _popController;
  late final Animation<double> _popScale;

  @override
  void initState() {
    super.initState();
    _sunburstController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);

    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    )..forward();
    _popScale = CurvedAnimation(
      parent: _popController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _sunburstController.dispose();
    _sparkleController.dispose();
    _popController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = GamePopupDialog.themeFromDifficulty(widget.difficulty);
    final bool isEarlyTutorialLevel = widget.levelNumber <= 2;

    Color textStroke;
    String shineAsset;
    switch (theme) {
      case PopupTheme.blue:
        textStroke = const Color(0xFF06203A);
        shineAsset = 'assets/images/vfx/BluePopupShine.png';
        break;
      case PopupTheme.hard:
        textStroke = const Color(0xFF2B0747);
        shineAsset = 'assets/images/vfx/PurplePopupShine.png';
        break;
      case PopupTheme.veryHard:
        textStroke = const Color(0xFF4B0610);
        shineAsset = 'assets/images/vfx/RedPopupShine.png';
        break;
    }

    return ScaleTransition(
      scale: _popScale,
      child: GamePopupDialog(
        title: 'Level ${widget.levelNumber}',
        theme: theme,
        maxWidth: 356,
        onClose: isEarlyTutorialLevel ? null : widget.onContinue,
        contentPadding: EdgeInsets.fromLTRB(
          18,
          widget.difficulty >= 2 ? 68 : 50,
          18,
          24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title: "PERFECT!"
            StrokedText(
              'PERFECT!',
              fontSize: 42,
              fillColor: const Color(0xFFFFD829),
              strokeColor: textStroke,
              strokeWidth: 5.5,
              letterSpacing: 1.1,
            ),
            const SizedBox(height: 2),

            // Subtitle: "Rewards:"
            StrokedText(
              'Rewards:',
              fontSize: 22,
              fillColor: Colors.white,
              strokeColor: textStroke,
              strokeWidth: 3.8,
            ),
            const SizedBox(height: 6),

            // Center 3D Coin Stack with Rotating Sunburst & Twinkling Star Sparkles
            SizedBox(
              width: 260,
              height: 184,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Soft Theme Background Glow
                  ShaderMask(
                    shaderCallback: (bounds) => const RadialGradient(
                      colors: [
                        Colors.white,
                        Color(0xAAFFFFFF),
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.55, 0.92],
                    ).createShader(bounds),
                    blendMode: BlendMode.dstIn,
                    child: Opacity(
                      opacity: 0.72,
                      child: Image.asset(
                        shineAsset,
                        width: 236,
                        height: 236,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // Authentic Rotating Sunburst Rays (true alpha PNG)
                  RotationTransition(
                    turns: _sunburstController,
                    child: Opacity(
                      opacity: 0.65,
                      child: Image.asset(
                        'assets/images/ui/dl_general_sunburst.png',
                        width: 226,
                        height: 226,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // Authentic 3D Coin Stack Graphic
                  Image.asset(
                    'assets/images/popups/PopupRewardsImage.png',
                    width: 226,
                    height: 164,
                    fit: BoxFit.contain,
                  ),

                  // Sparkle 1 (Top Center 4-point star)
                  Positioned(
                    top: 22,
                    left: 112,
                    child: FadeTransition(
                      opacity: _sparkleController,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.65, end: 1.15)
                            .animate(_sparkleController),
                        child: Image.asset(
                          'assets/images/vfx/shop_legendary_shine.png',
                          width: 26,
                          height: 26,
                        ),
                      ),
                    ),
                  ),

                  // Sparkle 2 (Left Coin 4-point star)
                  Positioned(
                    bottom: 56,
                    left: 30,
                    child: FadeTransition(
                      opacity: ReverseAnimation(_sparkleController),
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.65, end: 1.1)
                            .animate(ReverseAnimation(_sparkleController)),
                        child: Image.asset(
                          'assets/images/vfx/shop_legendary_shine.png',
                          width: 22,
                          height: 22,
                        ),
                      ),
                    ),
                  ),

                  // Sparkle 3 (Right Coin 4-point star)
                  Positioned(
                    top: 46,
                    right: 62,
                    child: FadeTransition(
                      opacity: _sparkleController,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.7, end: 1.15)
                            .animate(_sparkleController),
                        child: Image.asset(
                          'assets/images/vfx/shop_legendary_shine.png',
                          width: 24,
                          height: 24,
                        ),
                      ),
                    ),
                  ),

                  // Base Reward Number Overlay (bottom right of coin pile)
                  Positioned(
                    bottom: 14,
                    right: 36,
                    child: StrokedText(
                      '${widget.baseCoins}',
                      fontSize: 36,
                      fillColor: Colors.white,
                      strokeColor: textStroke,
                      strokeWidth: 5.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Bottom CTA Buttons:
            // Levels 1-2: Single wide framed Green "Continue" button
            // Levels >= 3: Side-by-side Green "Continue" & Purple "x5 (50)" Ad button
            if (isEarlyTutorialLevel)
              SizedBox(
                width: 236,
                child: GameButton(
                  text: 'Continue',
                  color: GameButtonColor.green,
                  height: 58,
                  fontSize: 25,
                  showFrame: true,
                  onTap: widget.onContinue,
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: GameButton(
                      text: 'Continue',
                      color: GameButtonColor.green,
                      height: 58,
                      fontSize: 20,
                      showFrame: true,
                      onTap: widget.onContinue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.topCenter,
                      children: [
                        GameButton(
                          color: GameButtonColor.purple,
                          height: 58,
                          showFrame: true,
                          onTap: widget.onClaimAdMultiplier,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/icons/AdsIcon.png',
                                width: 24,
                                height: 24,
                              ),
                              const SizedBox(width: 5),
                              StrokedText(
                                '${widget.adCoins}',
                                fontSize: 22,
                                strokeColor: const Color(0xFF3E0B4E),
                                strokeWidth: 3.8,
                              ),
                              const SizedBox(width: 4),
                              Image.asset(
                                'assets/images/icons/CurrencyCoinIcon.png',
                                width: 22,
                                height: 22,
                              ),
                            ],
                          ),
                        ),
                        // Top "x5" Orange Sign Crown
                        Positioned(
                          top: -11,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 2,
                            ),
                            decoration: const BoxDecoration(
                              image: DecorationImage(
                                image: ExactAssetImage(
                                  'assets/images/ui/OrangeTopSign.png',
                                  scale: 3.0,
                                ),
                                centerSlice: Rect.fromLTRB(
                                  80 / 3.0,
                                  12 / 3.0,
                                  144 / 3.0,
                                  48 / 3.0,
                                ),
                                fit: BoxFit.fill,
                              ),
                            ),
                            child: const StrokedText(
                              'x5',
                              fontSize: 13,
                              strokeColor: Color(0xFF6B2206),
                              strokeWidth: 2.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

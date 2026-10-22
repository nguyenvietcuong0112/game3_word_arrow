import 'package:flutter/material.dart';
import '../widgets/game_button.dart';

class VictoryDialog extends StatefulWidget {
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
  State<VictoryDialog> createState() => _VictoryDialogState();
}

class _VictoryDialogState extends State<VictoryDialog> with SingleTickerProviderStateMixin {
  late final AnimationController _sparkleController;

  @override
  void initState() {
    super.initState();
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    super.dispose();
  }

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
            // Authentic 9-patch Unity Blue Frame
            Container(
              margin: const EdgeInsets.only(top: 36),
              width: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/popups/GeneralBluePopup.png'),
                  centerSlice: Rect.fromLTRB(160, 160, 520, 444),
                  fit: BoxFit.fill,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 52, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title: "PERFECT!"
                  const Text(
                    'PERFECT!',
                    style: TextStyle(
                      fontFamily: 'Panteon',
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: Color(0xFFFFD530),
                      shadows: [
                        Shadow(
                          offset: Offset(0, 3.5),
                          color: Color(0xFF002A5A),
                          blurRadius: 2,
                        ),
                        Shadow(
                          offset: Offset(0, 1.5),
                          color: Color(0xFFFFF7A0),
                          blurRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),

                  // Subtitle: "Rewards:"
                  const Text(
                    'Rewards:',
                    style: TextStyle(
                      fontFamily: 'Panteon',
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 2),
                          color: Color(0xFF002A5A),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Center 3D Coin Stack with Soft Cyan Shine & Sparkles
                  SizedBox(
                    width: 260,
                    height: 180,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // Soft Cyan Background Glow
                        Image.asset(
                          'assets/images/vfx/BluePopupShine.png',
                          width: 260,
                          height: 260,
                          fit: BoxFit.contain,
                        ),

                        // Authentic 3D Coin Stack Graphic
                        Image.asset(
                          'assets/images/popups/PopupRewardsImage.png',
                          width: 235,
                          height: 172,
                          fit: BoxFit.contain,
                        ),

                        // Sparkle 1 (Top Center)
                        Positioned(
                          top: 22,
                          left: 110,
                          child: FadeTransition(
                            opacity: _sparkleController,
                            child: Image.asset(
                              'assets/images/vfx/flare01.png',
                              width: 24,
                              height: 24,
                            ),
                          ),
                        ),

                        // Sparkle 2 (Left Coin)
                        Positioned(
                          bottom: 60,
                          left: 28,
                          child: FadeTransition(
                            opacity: ReverseAnimation(_sparkleController),
                            child: Image.asset(
                              'assets/images/vfx/flare01.png',
                              width: 20,
                              height: 20,
                            ),
                          ),
                        ),

                        // Sparkle 3 (Right Coin)
                        Positioned(
                          top: 48,
                          right: 68,
                          child: FadeTransition(
                            opacity: _sparkleController,
                            child: Image.asset(
                              'assets/images/vfx/flare01.png',
                              width: 22,
                              height: 22,
                            ),
                          ),
                        ),

                        // Reward Number Overlay (bottom right of coin pile)
                        Positioned(
                          bottom: 12,
                          right: 28,
                          child: Text(
                            '+${widget.coinsEarned}',
                            style: const TextStyle(
                              fontFamily: 'Panteon',
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  offset: Offset(0, 3),
                                  color: Color(0xFF1B1B1B),
                                  blurRadius: 4,
                                ),
                                Shadow(
                                  offset: Offset(2, 0),
                                  color: Color(0xFF1B1B1B),
                                  blurRadius: 3,
                                ),
                                Shadow(
                                  offset: Offset(-2, 0),
                                  color: Color(0xFF1B1B1B),
                                  blurRadius: 3,
                                ),
                                Shadow(
                                  offset: Offset(0, -2),
                                  color: Color(0xFF1B1B1B),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Continue Action Button (Wide Green 3D Button)
                  SizedBox(
                    width: 230,
                    height: 66,
                    child: GameButton(
                      text: 'Continue',
                      color: GameButtonColor.green,
                      height: 66,
                      fontSize: 24,
                      onTap: widget.onNextLevel,
                    ),
                  ),
                ],
              ),
            ),

            // Top Tab Banner: "Level X"
            Positioned(
              top: 0,
              child: SizedBox(
                width: 270,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      'assets/images/popups/BluePopupTitle.png',
                      width: 270,
                      height: 80,
                      fit: BoxFit.fill,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Level ${widget.levelNumber}',
                        style: const TextStyle(
                          fontFamily: 'Panteon',
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 2.5),
                              color: Color(0xFF003870),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Round Close Button (Top-Right)
            Positioned(
              top: 14,
              right: 8,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onNextLevel,
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

import 'package:flutter/material.dart';
import '../widgets/game_button.dart';
import '../widgets/game_popup_dialog.dart';

/// Authentic Unity NoAvailableMovesFrame ("No Available Stars")
/// Includes free +1 Star revive, 500-coin +3 Stars revive, top coin pill,
/// round Close button, and press-and-hold "Hold to see the board" peek.
class GameOverDialog extends StatefulWidget {
  final int levelNumber;
  final int coins;
  final int reviveCoinsCost;
  final VoidCallback onReviveFree;
  final VoidCallback onReviveCoins;
  final VoidCallback onClose;

  const GameOverDialog({
    super.key,
    required this.levelNumber,
    required this.coins,
    this.reviveCoinsCost = 500,
    required this.onReviveFree,
    required this.onReviveCoins,
    required this.onClose,
  });

  @override
  State<GameOverDialog> createState() => _GameOverDialogState();
}

class _GameOverDialogState extends State<GameOverDialog>
    with SingleTickerProviderStateMixin {
  bool _isPeekingBoard = false;
  late final AnimationController _sunburstController;

  @override
  void initState() {
    super.initState();
    _sunburstController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
  }

  @override
  void dispose() {
    _sunburstController.dispose();
    super.dispose();
  }

  String _formatCoins(int count) {
    if (count >= 1000) {
      return (count / 1000.0).toStringAsFixed(3);
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Dark overlay backdrop that fades out when holding "Hold to see the board"
          AnimatedOpacity(
            opacity: _isPeekingBoard ? 0.05 : 1.0,
            duration: const Duration(milliseconds: 140),
            child: Container(
              color: const Color(0xD6050E1D),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Column(
                    children: [
                      // Top Row: Coin Badge + Close Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildCoinPill(widget.coins),
                          const SizedBox(width: 14),
                          PopupCloseButton(
                            onTap: widget.onClose,
                            size: 46,
                          ),
                        ],
                      ),

                      const Spacer(flex: 2),

                      // Main Title: "No Available Stars"
                      const StrokedText(
                        'No Available Stars',
                        fontSize: 34,
                        fillColor: Colors.white,
                        strokeColor: Color(0xFF041A38),
                        strokeWidth: 5.2,
                      ),
                      const SizedBox(height: 16),

                      // Broken Star Graphic with Soft Ambient Sunburst
                      SizedBox(
                        width: 220,
                        height: 205,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            RotationTransition(
                              turns: _sunburstController,
                              child: Opacity(
                                opacity: 0.35,
                                child: Image.asset(
                                  'assets/images/ui/dl_general_sunburst.png',
                                  width: 215,
                                  height: 215,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            Image.asset(
                              'assets/images/gameplay/WordsArrowNoAvailableStars.png',
                              width: 185,
                              height: 185,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Two Side-by-Side Revive Buttons crowned with "Add Stars"
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 348),
                        child: Row(
                          children: [
                            // Left: Purple (+1 Star FREE Ad)
                            Expanded(
                              child: _buildAddStarsCard(
                                color: GameButtonColor.purple,
                                starBonusText: '+1',
                                strokeColor: const Color(0xFF3E0B4E),
                                onTap: widget.onReviveFree,
                                rightContent: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const StrokedText(
                                      'GET',
                                      fontSize: 15,
                                      strokeColor: Color(0xFF3E0B4E),
                                      strokeWidth: 3.0,
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Image.asset(
                                          'assets/images/icons/AdsIcon.png',
                                          width: 19,
                                          height: 19,
                                        ),
                                        const SizedBox(width: 4),
                                        const StrokedText(
                                          'FREE',
                                          fontSize: 16,
                                          strokeColor: Color(0xFF3E0B4E),
                                          strokeWidth: 3.2,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Right: Green (+3 Stars for 500 Coins)
                            Expanded(
                              child: _buildAddStarsCard(
                                color: GameButtonColor.green,
                                starBonusText: '+3',
                                strokeColor: const Color(0xFF0E470E),
                                onTap: widget.onReviveCoins,
                                rightContent: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const StrokedText(
                                      'GET',
                                      fontSize: 15,
                                      strokeColor: Color(0xFF0E470E),
                                      strokeWidth: 3.0,
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Image.asset(
                                          'assets/images/icons/CurrencyCoinIcon.png',
                                          width: 19,
                                          height: 19,
                                        ),
                                        const SizedBox(width: 4),
                                        StrokedText(
                                          '${widget.reviveCoinsCost}',
                                          fontSize: 17,
                                          strokeColor: const Color(0xFF0E470E),
                                          strokeWidth: 3.2,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(flex: 3),

                      const SizedBox(height: 48), // Reserve space for peek button
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom "Hold to see the board" interactive area (always stays touchable)
          Positioned(
            left: 0,
            right: 0,
            bottom: 34,
            child: SafeArea(
              top: false,
              child: Center(
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (_) => setState(() => _isPeekingBoard = true),
                  onPointerUp: (_) => setState(() => _isPeekingBoard = false),
                  onPointerCancel: (_) => setState(() => _isPeekingBoard = false),
                  child: AnimatedOpacity(
                    opacity: _isPeekingBoard ? 0.35 : 0.92,
                    duration: const Duration(milliseconds: 120),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x55000000),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white24,
                          width: 1.2,
                        ),
                      ),
                      child: const StrokedText(
                        'Hold to see the board',
                        fontSize: 17,
                        fillColor: Colors.white,
                        strokeColor: Color(0xFF04152D),
                        strokeWidth: 3.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddStarsCard({
    required GameButtonColor color,
    required String starBonusText,
    required Color strokeColor,
    required Widget rightContent,
    required VoidCallback onTap,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: GameButton(
            color: color,
            height: 68,
            showFrame: true,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Star icon with +1 / +3
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.asset(
                          'assets/images/gameplay/WordsArrowGetPopupStar.png',
                          width: 42,
                          height: 42,
                          fit: BoxFit.contain,
                        ),
                        StrokedText(
                          starBonusText,
                          fontSize: 17,
                          fillColor: Colors.white,
                          strokeColor: const Color(0xFF5A2600),
                          strokeWidth: 3.4,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1.5,
                    height: 36,
                    color: Colors.black26,
                  ),
                  rightContent,
                ],
              ),
            ),
          ),
        ),
        // Top "Add Stars" Orange Sign
        Positioned(
          top: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: ExactAssetImage(
                  'assets/images/ui/OrangeTopSign.png',
                  scale: 2.6,
                ),
                centerSlice: Rect.fromLTRB(
                  80 / 2.6,
                  12 / 2.6,
                  144 / 2.6,
                  48 / 2.6,
                ),
                fit: BoxFit.fill,
              ),
            ),
            child: const StrokedText(
              'Add Stars',
              fontSize: 13,
              fillColor: Colors.white,
              strokeColor: Color(0xFF6B2206),
              strokeWidth: 2.8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCoinPill(int coins) {
    return SizedBox(
      width: 116,
      height: 42,
      child: Stack(
        alignment: Alignment.centerLeft,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 18,
            right: 0,
            top: 6,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.only(left: 22, right: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFD8AB8A),
                  width: 1.5,
                ),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFC5916E),
                    Color(0xFFECCBB1),
                    Color(0xFFFAE9D8),
                  ],
                ),
              ),
              alignment: Alignment.center,
              child: StrokedText(
                _formatCoins(coins),
                fontSize: 16,
                fillColor: const Color(0xFFFFF9F0),
                strokeColor: const Color(0xFF470C10),
                strokeWidth: 3.2,
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: Image.asset(
              'assets/images/icons/CurrencyCoinIcon.png',
              width: 42,
              height: 42,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'game_button.dart';

enum PopupTheme { blue, hard, veryHard }

/// Authentic round 3D Unity Close Button (CloseButtonFrame.png + CloseIcon.png)
class PopupCloseButton extends StatefulWidget {
  final VoidCallback onTap;
  final double size;

  const PopupCloseButton({
    super.key,
    required this.onTap,
    this.size = 48.0,
  });

  @override
  State<PopupCloseButton> createState() => _PopupCloseButtonState();
}

class _PopupCloseButtonState extends State<PopupCloseButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(
                'assets/images/popups/CloseButtonFrame.png',
                width: widget.size,
                height: widget.size,
                fit: BoxFit.contain,
              ),
              Image.asset(
                'assets/images/icons/CloseIcon.png',
                width: widget.size * 0.705,
                height: widget.size * 0.705,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GamePopupDialog extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onClose;
  final double maxWidth;
  final PopupTheme theme;
  final EdgeInsetsGeometry contentPadding;

  const GamePopupDialog({
    super.key,
    required this.title,
    required this.child,
    this.onClose,
    this.maxWidth = 352,
    this.theme = PopupTheme.blue,
    this.contentPadding = const EdgeInsets.fromLTRB(22, 52, 22, 24),
  });

  static PopupTheme themeFromDifficulty(int difficulty) {
    if (difficulty >= 3) return PopupTheme.veryHard;
    if (difficulty == 2) return PopupTheme.hard;
    return PopupTheme.blue;
  }

  @override
  Widget build(BuildContext context) {
    String frameAsset;
    String titleAsset;
    String shineAsset;
    Color titleStrokeColor;
    double frameHeightPx;
    String? difficultyBadgeAsset;
    String? difficultyBadgeLabel;
    Color difficultyStrokeColor = const Color(0xFF2E0849);

    switch (theme) {
      case PopupTheme.blue:
        frameAsset = 'assets/images/popups/GeneralBluePopup.png';
        titleAsset = 'assets/images/popups/BluePopupTitle.png';
        shineAsset = 'assets/images/vfx/BluePopupShine.png';
        titleStrokeColor = const Color(0xFF072549);
        frameHeightPx = 604.0;
        break;
      case PopupTheme.hard:
        frameAsset = 'assets/images/popups/HardPopup.png';
        titleAsset = 'assets/images/popups/PurplePopupTitle.png';
        shineAsset = 'assets/images/vfx/PurplePopupShine.png';
        titleStrokeColor = const Color(0xFF2D074A);
        frameHeightPx = 600.0;
        difficultyBadgeAsset = 'assets/images/popups/PopupHardTextBG.png';
        difficultyBadgeLabel = 'Hard';
        difficultyStrokeColor = const Color(0xFF2D074A);
        break;
      case PopupTheme.veryHard:
        frameAsset = 'assets/images/popups/VeryHardPopup.png';
        titleAsset = 'assets/images/popups/RedPopupTitle.png';
        shineAsset = 'assets/images/vfx/RedPopupShine.png';
        titleStrokeColor = const Color(0xFF50000E);
        frameHeightPx = 600.0;
        difficultyBadgeAsset = 'assets/images/popups/PopupVeryHardTextBG.png';
        difficultyBadgeLabel = 'Very Hard';
        difficultyStrokeColor = const Color(0xFF50000E);
        break;
    }

    // Exact Unity 9-slice border for 680x604 / 680x600 popup frames: (L:300, B:240, R:300, T:200)
    const double frameScale = 2.65;
    final Rect frameCenterSlice = Rect.fromLTRB(
      280 / frameScale,
      190 / frameScale,
      400 / frameScale,
      (frameHeightPx - 240) / frameScale,
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // 1. Authentic 9-patch Unity Popup Frame
            Container(
              margin: const EdgeInsets.only(top: 36),
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: ExactAssetImage(frameAsset, scale: frameScale),
                  centerSlice: frameCenterSlice,
                  fit: BoxFit.fill,
                ),
              ),
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  // Subtle top ambient shine inside popup
                  Positioned(
                    top: 6,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: 0.45,
                        child: Image.asset(
                          shineAsset,
                          width: 260,
                          height: 110,
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: contentPadding,
                    child: child,
                  ),
                ],
              ),
            ),

            // 2. Optional Difficulty Sub-Ribbon ("Hard" / "Very Hard") tucked under Title Ribbon
            if (difficultyBadgeAsset != null && difficultyBadgeLabel != null)
              Positioned(
                top: 58,
                child: SizedBox(
                  width: 116,
                  height: 44,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        difficultyBadgeAsset,
                        width: 116,
                        height: 44,
                        fit: BoxFit.contain,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: StrokedText(
                          difficultyBadgeLabel,
                          fontSize: 14,
                          fillColor: Colors.white,
                          strokeColor: difficultyStrokeColor,
                          strokeWidth: 2.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 3. Top Ribbon Title Banner (904x268)
            Positioned(
              top: 0,
              child: SizedBox(
                width: 278,
                height: 82,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      titleAsset,
                      width: 278,
                      height: 82,
                      fit: BoxFit.fill,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: StrokedText(
                        title,
                        fontSize: 26,
                        fillColor: Colors.white,
                        strokeColor: titleStrokeColor,
                        strokeWidth: 4.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 4. Authentic Round 3D Close Button (CloseButtonFrame + CloseIcon)
            if (onClose != null)
              Positioned(
                top: 14,
                right: 4,
                child: PopupCloseButton(
                  onTap: onClose!,
                  size: 48,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

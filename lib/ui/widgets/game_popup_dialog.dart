import 'package:flutter/material.dart';

class GamePopupDialog extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onClose;
  final double maxWidth;

  const GamePopupDialog({
    super.key,
    required this.title,
    required this.child,
    this.onClose,
    this.maxWidth = 340,
  });

  @override
  Widget build(BuildContext context) {
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
            // Popup Frame (Authentic 9-patch SettingsPanel)
            Container(
              margin: const EdgeInsets.only(top: 28),
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/ui/SettingsPanel.png'),
                  centerSlice: Rect.fromLTRB(60, 60, 220, 200),
                  fit: BoxFit.fill,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 46, 24, 24),
              child: child,
            ),

            // Top Title Banner
            Positioned(
              top: 0,
              child: SizedBox(
                width: 260,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      'assets/images/popups/GeneralOrangePopupTitleBG.png',
                      width: 260,
                      height: 72,
                      fit: BoxFit.fill,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Panteon',
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 2),
                              color: Color(0xFF7C2D12),
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

            // Close Button
            if (onClose != null)
              Positioned(
                top: 14,
                right: 4,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onClose,
                  child: Image.asset(
                    'assets/images/ui/BannerCloseButton.png',
                    width: 44,
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../widgets/game_button.dart';
import '../widgets/game_popup_dialog.dart';

/// Authentic Unity QuitLevelFrame ("Quit Level?")
/// Uses GeneralBluePopup + PopupInInfoBG cream card + BrokenLiveIcon + Red "Quit" button.
class QuitLevelDialog extends StatelessWidget {
  final VoidCallback onConfirmQuit;
  final VoidCallback? onSelectAnotherLevel;

  const QuitLevelDialog({
    super.key,
    required this.onConfirmQuit,
    this.onSelectAnotherLevel,
  });

  @override
  Widget build(BuildContext context) {
    return GamePopupDialog(
      title: 'Quit Level?',
      theme: PopupTheme.blue,
      maxWidth: 344,
      onClose: () => Navigator.pop(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 4),
          // Authentic Cream Info Card (PopupInInfoBG.png, 476x476, border 230)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: ExactAssetImage(
                  'assets/images/popups/PopupInInfoBG.png',
                  scale: 4.0,
                ),
                centerSlice: Rect.fromLTRB(
                  190 / 4.0,
                  190 / 4.0,
                  286 / 4.0,
                  286 / 4.0,
                ),
                fit: BoxFit.fill,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/icons/BrokenLiveIcon.png',
                  width: 88,
                  height: 82,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 12),
                const StrokedText(
                  'You will lose a life!',
                  fontSize: 20,
                  fillColor: Colors.white,
                  strokeColor: Color(0xFF471A0A),
                  strokeWidth: 3.6,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Primary Red "Quit" CTA Button (restarts / exits current attempt)
          SizedBox(
            width: 210,
            child: GameButton(
              text: 'Quit',
              color: GameButtonColor.red,
              height: 56,
              fontSize: 23,
              showFrame: true,
              onTap: () {
                Navigator.pop(context);
                onConfirmQuit();
              },
            ),
          ),

          if (onSelectAnotherLevel != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Navigator.pop(context);
                onSelectAnotherLevel!();
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                child: StrokedText(
                  'Select Level',
                  fontSize: 15,
                  fillColor: Color(0xFFD6EEFF),
                  strokeColor: Color(0xFF06203F),
                  strokeWidth: 2.8,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

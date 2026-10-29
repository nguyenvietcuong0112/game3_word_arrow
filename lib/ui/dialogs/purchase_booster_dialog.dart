import 'package:flutter/material.dart';
import '../../services/level_service.dart';
import '../widgets/game_button.dart';
import '../widgets/game_popup_dialog.dart';

/// Authentic Unity PurchaseBoosterFrame
/// Opens when tapping an unlocked booster with 0 remaining charges.
/// Offers FREE Ad x1 or Coin Pack x3 (Hint 900, Hammer 1800, Firework 2400).
class PurchaseBoosterDialog extends StatelessWidget {
  final BoosterType boosterType;
  final VoidCallback onWatchAdFree;
  final VoidCallback onBuyPackWithCoins;

  const PurchaseBoosterDialog({
    super.key,
    required this.boosterType,
    required this.onWatchAdFree,
    required this.onBuyPackWithCoins,
  });

  @override
  Widget build(BuildContext context) {
    final title = LevelService.boosterTitle(boosterType);
    final desc = LevelService.boosterDescription(boosterType);
    final iconAsset = LevelService.boosterIconAsset(boosterType);
    final packPrice = LevelService.packPriceFor(boosterType);
    const packAmount = LevelService.boosterPackAmount;

    return GamePopupDialog(
      title: title,
      theme: PopupTheme.blue,
      maxWidth: 356,
      onClose: () => Navigator.pop(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cream Info Card (PopupInInfoBG.png)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
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
                // Booster Icon with x3 Red Badge
                SizedBox(
                  width: 108,
                  height: 108,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Image.asset(
                        'assets/images/boosters/IngameBoosterButton.png',
                        width: 96,
                        height: 96,
                        fit: BoxFit.contain,
                      ),
                      Image.asset(
                        'assets/images/boosters/IngameBoosterButtonFrame.png',
                        width: 108,
                        height: 108,
                        fit: BoxFit.contain,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Image.asset(
                          iconAsset,
                          fit: BoxFit.contain,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.asset(
                                'assets/images/ui/RedNotification.png',
                                width: 36,
                                height: 36,
                              ),
                              const StrokedText(
                                'x$packAmount',
                                fontSize: 15,
                                strokeColor: Color(0xFF5A0B0E),
                                strokeWidth: 3.0,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                StrokedText(
                  desc,
                  fontSize: 15,
                  fillColor: Colors.white,
                  strokeColor: const Color(0xFF471A0A),
                  strokeWidth: 3.0,
                  height: 1.28,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Side-by-Side Framed Buttons: Left Purple (GET x1 FREE Ad), Right Green (GET x3 Coins)
          Row(
            children: [
              Expanded(
                child: GameButton(
                  color: GameButtonColor.purple,
                  height: 62,
                  showFrame: true,
                  onTap: () {
                    Navigator.pop(context);
                    onWatchAdFree();
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const StrokedText(
                        'GET x1',
                        fontSize: 14,
                        strokeColor: Color(0xFF3E0B4E),
                        strokeWidth: 2.8,
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
              const SizedBox(width: 10),
              Expanded(
                child: GameButton(
                  color: GameButtonColor.green,
                  height: 62,
                  showFrame: true,
                  onTap: () {
                    Navigator.pop(context);
                    onBuyPackWithCoins();
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const StrokedText(
                        'GET x$packAmount',
                        fontSize: 14,
                        strokeColor: Color(0xFF0E470E),
                        strokeWidth: 2.8,
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
                            '$packPrice',
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
        ],
      ),
    );
  }
}

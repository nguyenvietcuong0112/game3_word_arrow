import 'package:flutter/material.dart';
import '../../services/level_service.dart';
import '../widgets/game_button.dart';
import '../widgets/game_popup_dialog.dart';

class LevelSelectDialog extends StatefulWidget {
  final int currentLevel;
  final Function(int level) onSelectLevel;

  const LevelSelectDialog({
    super.key,
    required this.currentLevel,
    required this.onSelectLevel,
  });

  @override
  State<LevelSelectDialog> createState() => _LevelSelectDialogState();
}

class _LevelSelectDialogState extends State<LevelSelectDialog> {
  final LevelService _levelService = LevelService();
  final Map<int, int> _levelStars = {};

  @override
  void initState() {
    super.initState();
    _loadStars();
  }

  Future<void> _loadStars() async {
    for (int i = 1; i <= 200; i++) {
      final s = await _levelService.getLevelStars(i);
      if (s > 0) {
        _levelStars[i] = s;
      }
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GamePopupDialog(
      title: 'Select Level',
      theme: PopupTheme.blue,
      maxWidth: 376,
      onClose: () => Navigator.pop(context),
      contentPadding: const EdgeInsets.fromLTRB(18, 52, 18, 22),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 460),
        child: Container(
          padding: const EdgeInsets.all(10),
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.92,
              ),
              itemCount: 200,
              itemBuilder: (context, index) {
                final levelNum = index + 1;
                final isCurrent = levelNum == widget.currentLevel;
                final stars = _levelStars[levelNum] ?? 0;

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Navigator.pop(context);
                    widget.onSelectLevel(levelNum);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: ExactAssetImage(
                          isCurrent
                              ? 'assets/images/ui/GeneralOrangeButton.png'
                              : (stars > 0
                                  ? 'assets/images/ui/GeneralGreenButton.png'
                                  : 'assets/images/ui/GeneralBlueButton.png'),
                          scale: 2.0,
                        ),
                        centerSlice: const Rect.fromLTRB(15, 15, 33, 33),
                        fit: BoxFit.fill,
                      ),
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        StrokedText(
                          '$levelNum',
                          fontSize: 19,
                          fillColor: Colors.white,
                          strokeColor: isCurrent
                              ? const Color(0xFF6E2508)
                              : (stars > 0
                                  ? const Color(0xFF0E470E)
                                  : const Color(0xFF0A3A66)),
                          strokeWidth: 3.2,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (starIdx) {
                            final isEarned = starIdx < stars;
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 1.0),
                              child: Image.asset(
                                isEarned
                                    ? 'assets/images/gameplay/WordsArrowIngameGoldStar.png'
                                    : 'assets/images/gameplay/WordsArrowIngameGreyStar.png',
                                width: 11,
                                height: 11,
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

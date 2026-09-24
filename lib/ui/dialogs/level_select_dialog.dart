import 'package:flutter/material.dart';
import '../../services/level_service.dart';

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
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 600),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // Popup Frame
            Container(
              margin: const EdgeInsets.only(top: 28),
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/ui/SettingsPanel.png'),
                  centerSlice: Rect.fromLTRB(60, 60, 220, 200),
                  fit: BoxFit.fill,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 44, 20, 26),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.9,
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
                            image: AssetImage(
                              isCurrent
                                  ? 'assets/images/ui/GeneralOrangeButton.png'
                                  : 'assets/images/ui/GeneralBlueButton.png',
                            ),
                            centerSlice: const Rect.fromLTRB(20, 20, 76, 76),
                            fit: BoxFit.fill,
                          ),
                        ),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.only(bottom: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$levelNum',
                            style: const TextStyle(
                              fontFamily: 'Panteon',
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  offset: Offset(0, 1.5),
                                  color: Colors.black45,
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          // Star indicators
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(3, (starIdx) {
                              final isEarned = starIdx < stars;
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 1.0),
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

            // Top Title Banner
            Positioned(
              top: 0,
              child: SizedBox(
                width: 250,
                height: 68,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      'assets/images/popups/GeneralOrangePopupTitleBG.png',
                      width: 250,
                      height: 68,
                      fit: BoxFit.fill,
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Text(
                        'SELECT LEVEL',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Panteon',
                          fontSize: 21,
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
            Positioned(
              top: 14,
              right: 6,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.pop(context),
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

import 'dart:async';
import 'package:flutter/material.dart';
import '../game/board_controller.dart';
import '../models/game_palette.dart';
import '../models/level_model.dart';
import '../services/audio_service.dart';
import '../services/level_service.dart';
import 'dialogs/booster_unlock_dialog.dart';
import 'dialogs/feature_unlock_dialog.dart';
import 'dialogs/game_over_dialog.dart';
import 'dialogs/level_select_dialog.dart';
import 'dialogs/purchase_booster_dialog.dart';
import 'dialogs/quit_level_dialog.dart';
import 'dialogs/settings_dialog.dart';
import 'dialogs/victory_dialog.dart';
import 'widgets/booster_tutorial_overlay.dart';
import 'widgets/game_board.dart';
import 'widgets/game_bottom_bar.dart';
import 'widgets/game_button.dart';
import 'widgets/game_top_bar.dart';

class GameScreen extends StatefulWidget {
  final int? initialLevel;

  const GameScreen({super.key, this.initialLevel});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final LevelService _levelService = LevelService();
  final AudioService _audio = AudioService();

  final GlobalKey _hintBtnKey = GlobalKey();
  final GlobalKey _hammerBtnKey = GlobalKey();
  final GlobalKey _fireworkBtnKey = GlobalKey();

  late int _currentLevelNumber;
  BoardController? _controller;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isDialogShowing = false;

  // Guided Booster Spotlight Tutorial (Level 3 Hint, Level 6 Hammer Step 1, Level 9 Firework)
  BoosterType? _activeBoosterSpotlight;

  // Clean in-game floating toast message
  String? _toastMessage;
  Timer? _toastTimer;

  @override
  void initState() {
    super.initState();
    _currentLevelNumber = widget.initialLevel ?? 1;
    _initAndLoadLevel();
  }

  Future<void> _initAndLoadLevel() async {
    await _levelService.init();
    final lvl = widget.initialLevel ?? _levelService.currentLevelIndex;
    await _loadLevel(lvl);
  }

  void _showToast(String message) {
    _toastTimer?.cancel();
    setState(() {
      _toastMessage = message;
    });
    _toastTimer = Timer(const Duration(milliseconds: 1700), () {
      if (mounted) {
        setState(() {
          _toastMessage = null;
        });
      }
    });
  }

  Future<void> _loadLevel(int levelNum) async {
    _isDialogShowing = false;
    _activeBoosterSpotlight = null;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final levelModel = await _levelService.loadLevel(levelNum);
      _currentLevelNumber = levelNum;
      await _levelService.setCurrentLevel(levelNum);

      _controller?.removeListener(_onControllerChanged);
      _controller?.dispose();

      final newController = BoardController(
        level: levelModel,
        levelNumber: levelNum,
      );
      newController.onHammerConsumedOnBoard = () async {
        await _levelService.consumeBooster(BoosterType.hammer);
        if (!_levelService.isBoosterTutorialCompleted(BoosterType.hammer)) {
          await _levelService.markBoosterTutorialCompleted(BoosterType.hammer);
        }
        if (mounted) setState(() {});
      };
      newController.addListener(_onControllerChanged);

      setState(() {
        _controller = newController;
        _isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _checkLevelEntryUnlocks(levelNum, levelModel);
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load Level $levelNum: $e';
      });
    }
  }

  Future<void> _checkLevelEntryUnlocks(
    int levelNum,
    LevelModel levelModel,
  ) async {
    if (!mounted) return;

    // 1. Booster Unlocks (Level 3 Hint, Level 6 Hammer, Level 9 Firework)
    BoosterType? unlockBooster;
    if (levelNum == LevelService.hintUnlockLevel &&
        !_levelService.hasClaimedBoosterUnlock(BoosterType.hint)) {
      unlockBooster = BoosterType.hint;
    } else if (levelNum == LevelService.hammerUnlockLevel &&
        !_levelService.hasClaimedBoosterUnlock(BoosterType.hammer)) {
      unlockBooster = BoosterType.hammer;
    } else if (levelNum == LevelService.fireworkUnlockLevel &&
        !_levelService.hasClaimedBoosterUnlock(BoosterType.firework)) {
      unlockBooster = BoosterType.firework;
    }

    if (unlockBooster != null) {
      final type = unlockBooster;
      _audio.playReward();
      await showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        builder: (dialogCtx) => BoosterUnlockDialog(
          boosterType: type,
          onClaim: () async {
            _audio.playButtonClick();
            await _levelService.claimBoosterUnlock(type, giftAmount: 1);
            if (dialogCtx.mounted) {
              Navigator.pop(dialogCtx);
            }
            if (mounted) {
              setState(() {
                _activeBoosterSpotlight = type;
              });
            }
          },
        ),
      );
      return;
    }

    // Resume unfinished booster tutorial if player claimed gift earlier on this unlock level
    for (final type in BoosterType.values) {
      if (levelNum == LevelService.unlockLevelFor(type) &&
          _levelService.hasClaimedBoosterUnlock(type) &&
          !_levelService.isBoosterTutorialCompleted(type) &&
          _levelService.getBoosterCount(type) > 0) {
        setState(() {
          _activeBoosterSpotlight = type;
        });
        return;
      }
    }

    // 2. Feature Unlocks (Level 10 Crates, Level 13 Hidden Arrows, Level 21 Locks & Keys)
    final bool hasCrates = levelModel.crates.isNotEmpty;
    final bool hasHidden = levelModel.lanes.any((l) => l.hidden);
    final bool hasLocks =
        levelModel.lanes.any((l) => l.cells.any((c) => c.locked));

    if ((levelNum == LevelService.cratesUnlockLevel || hasCrates) &&
        !_levelService.hasShownFeatureUnlock('crates')) {
      _audio.playReward();
      await showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        builder: (dialogCtx) => FeatureUnlockDialog(
          featureName: 'Crates',
          description:
              "Crates block a word's path. Clear the shown number of words to break one.",
          iconAsset: 'assets/images/gameplay/InGameFeatureCrateUnlockIcon.png',
          onContinue: () async {
            _audio.playButtonClick();
            await _levelService.markFeatureUnlockShown('crates');
            if (dialogCtx.mounted) Navigator.pop(dialogCtx);
          },
        ),
      );
      return;
    }

    if ((levelNum == LevelService.hiddenArrowsUnlockLevel || hasHidden) &&
        !_levelService.hasShownFeatureUnlock('hidden')) {
      _audio.playReward();
      await showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        builder: (dialogCtx) => FeatureUnlockDialog(
          featureName: 'Hidden Arrows',
          description:
              'This arrow hides its length. Find the word by trying it out.',
          iconAsset:
              'assets/images/gameplay/InGameFeatureHiddenArrowUnlockIcon.png',
          onContinue: () async {
            _audio.playButtonClick();
            await _levelService.markFeatureUnlockShown('hidden');
            if (dialogCtx.mounted) Navigator.pop(dialogCtx);
          },
        ),
      );
      return;
    }

    if ((levelNum == LevelService.locksUnlockLevel || hasLocks) &&
        !_levelService.hasShownFeatureUnlock('locks')) {
      _audio.playReward();
      await showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        builder: (dialogCtx) => FeatureUnlockDialog(
          featureName: 'Locks & Keys',
          description:
              'A locked letter cannot be used. Send the word holding its key to open it.',
          iconAsset:
              'assets/images/gameplay/InGameFeatureLockKeyUnlockIcon.png',
          onContinue: () async {
            _audio.playButtonClick();
            await _levelService.markFeatureUnlockShown('locks');
            if (dialogCtx.mounted) Navigator.pop(dialogCtx);
          },
        ),
      );
      return;
    }
  }

  void _onControllerChanged() {
    if (!mounted || _controller == null) return;

    setState(() {});

    if (_controller!.status == GameStatus.won) {
      _showVictoryDialog();
    } else if (_controller!.status == GameStatus.lost) {
      _showGameOverDialog();
    }
  }

  void _showVictoryDialog() {
    if (_isDialogShowing) return;
    _isDialogShowing = true;
    _activeBoosterSpotlight = null;

    final completedLevel = _currentLevelNumber;
    final difficulty = _controller?.level.difficulty ?? 1;
    final earnedStars = _controller?.stars ?? 3;

    _levelService.saveLevelStars(completedLevel, earnedStars);
    _levelService.addCoins(LevelService.baseWinCoins);
    _levelService.completeLevelAndAdvance(completedLevel);
    setState(() {});

    Future.delayed(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      final nextLvl = completedLevel < 200 ? completedLevel + 1 : 1;

      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.72),
        builder: (dialogCtx) => VictoryDialog(
          levelNumber: completedLevel,
          difficulty: difficulty,
          stars: earnedStars,
          baseCoins: LevelService.baseWinCoins,
          adCoins: LevelService.adWinCoins,
          onContinue: () {
            _audio.playButtonClick();
            Navigator.pop(dialogCtx);
            _loadLevel(nextLvl);
          },
          onClaimAdMultiplier: () async {
            _audio.playReward();
            await _levelService.addCoins(
              LevelService.adWinCoins - LevelService.baseWinCoins,
            );
            if (dialogCtx.mounted) {
              Navigator.pop(dialogCtx);
            }
            if (mounted) {
              _loadLevel(nextLvl);
            }
          },
        ),
      );
    });
  }

  void _showGameOverDialog() {
    if (_isDialogShowing) return;
    _isDialogShowing = true;
    _activeBoosterSpotlight = null;

    Future.delayed(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.transparent, // Managed inside GameOverDialog for board peek
        builder: (gameOverCtx) => GameOverDialog(
          levelNumber: _currentLevelNumber,
          coins: _levelService.coins,
          reviveCoinsCost: LevelService.reviveCoinsCost,
          onReviveFree: () {
            _audio.playReward();
            Navigator.pop(gameOverCtx);
            _isDialogShowing = false;
            _controller?.revive(addStars: 1);
          },
          onReviveCoins: () async {
            final spent =
                await _levelService.spendCoins(LevelService.reviveCoinsCost);
            if (!spent) {
              _audio.playBlockedBounce();
              _showToast('Not enough coins! Use FREE +1 Star.');
              return;
            }
            _audio.playReward();
            if (gameOverCtx.mounted) {
              Navigator.pop(gameOverCtx);
            }
            _isDialogShowing = false;
            _controller?.revive(addStars: 3);
            if (mounted) setState(() {});
          },
          onClose: () {
            _audio.playButtonClick();
            showDialog(
              context: gameOverCtx,
              barrierColor: Colors.black.withValues(alpha: 0.65),
              builder: (_) => QuitLevelDialog(
                onConfirmQuit: () {
                  if (gameOverCtx.mounted) {
                    Navigator.pop(gameOverCtx);
                  }
                  _isDialogShowing = false;
                  _loadLevel(_currentLevelNumber);
                },
                onSelectAnotherLevel: () {
                  if (gameOverCtx.mounted) {
                    Navigator.pop(gameOverCtx);
                  }
                  _isDialogShowing = false;
                  _openLevelSelect();
                },
              ),
            );
          },
        ),
      );
    });
  }

  void _openPurchaseBoosterDialog(BoosterType type) {
    _audio.playButtonClick();
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (_) => PurchaseBoosterDialog(
        boosterType: type,
        onWatchAdFree: () async {
          await _levelService.addBooster(type, 1);
          _audio.playReward();
          if (mounted) setState(() {});
        },
        onBuyPackWithCoins: () async {
          final price = LevelService.packPriceFor(type);
          final ok = await _levelService.spendCoins(price);
          if (!ok) {
            _audio.playBlockedBounce();
            _showToast('Not enough coins!');
            return;
          }
          await _levelService.addBooster(type, LevelService.boosterPackAmount);
          _audio.playReward();
          if (mounted) setState(() {});
        },
      ),
    );
  }

  Future<void> _handleHintTap() async {
    if (_controller == null || _controller!.status != GameStatus.playing) return;

    if (!_levelService.isBoosterUnlocked(BoosterType.hint, _currentLevelNumber)) {
      _audio.playButtonClick();
      _showToast('Unlocks at Level ${LevelService.hintUnlockLevel}');
      return;
    }

    final count = _levelService.getBoosterCount(BoosterType.hint);
    if (count <= 0) {
      _openPurchaseBoosterDialog(BoosterType.hint);
      return;
    }

    final ok = _controller!.useHintBooster();
    if (ok) {
      await _levelService.consumeBooster(BoosterType.hint);
      if (_activeBoosterSpotlight == BoosterType.hint) {
        _activeBoosterSpotlight = null;
        await _levelService.markBoosterTutorialCompleted(BoosterType.hint);
      }
      if (mounted) setState(() {});
    } else {
      _showToast('No unobstructed word found!');
    }
  }

  Future<void> _handleHammerTap() async {
    if (_controller == null || _controller!.status != GameStatus.playing) return;

    if (!_levelService.isBoosterUnlocked(
      BoosterType.hammer,
      _currentLevelNumber,
    )) {
      _audio.playButtonClick();
      _showToast('Unlocks at Level ${LevelService.hammerUnlockLevel}');
      return;
    }

    // Step 1 -> Step 2 (WaitForHammerArmedStateStep) during Level 6 Hammer Tutorial
    if (_activeBoosterSpotlight == BoosterType.hammer) {
      setState(() {
        _activeBoosterSpotlight = null;
      });
      _controller!.armHammerBooster(isTutorial: true);
      return;
    }

    if (_controller!.isHammerActive) {
      _controller!.cancelHammerBooster();
      return;
    }

    final count = _levelService.getBoosterCount(BoosterType.hammer);
    if (count <= 0) {
      _openPurchaseBoosterDialog(BoosterType.hammer);
      return;
    }

    _controller!.armHammerBooster();
  }

  Future<void> _handleFireworkTap() async {
    if (_controller == null || _controller!.status != GameStatus.playing) return;

    if (!_levelService.isBoosterUnlocked(
      BoosterType.firework,
      _currentLevelNumber,
    )) {
      _audio.playButtonClick();
      _showToast('Unlocks at Level ${LevelService.fireworkUnlockLevel}');
      return;
    }

    final count = _levelService.getBoosterCount(BoosterType.firework);
    if (count <= 0) {
      _openPurchaseBoosterDialog(BoosterType.firework);
      return;
    }

    final ok = _controller!.useRocketBooster();
    if (ok) {
      await _levelService.consumeBooster(BoosterType.firework);
      if (_activeBoosterSpotlight == BoosterType.firework) {
        _activeBoosterSpotlight = null;
        await _levelService.markBoosterTutorialCompleted(BoosterType.firework);
      }
      if (mounted) setState(() {});
    }
  }

  void _openLevelSelect() {
    _audio.playButtonClick();
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (_) => LevelSelectDialog(
        currentLevel: _currentLevelNumber,
        onSelectLevel: (lvl) {
          _loadLevel(lvl);
        },
      ),
    );
  }

  void _openQuitLevelDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (_) => QuitLevelDialog(
        onConfirmQuit: () {
          _loadLevel(_currentLevelNumber);
        },
        onSelectAnotherLevel: () {
          _openLevelSelect();
        },
      ),
    );
  }

  void _openSettings() {
    _audio.playButtonClick();
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.68),
      builder: (_) => SettingsDialog(
        onExitLevel: _openQuitLevelDialog,
      ),
    );
  }

  Widget _buildBoosterSpotlightOverlay() {
    final type = _activeBoosterSpotlight;
    if (type == null) return const SizedBox.shrink();

    switch (type) {
      case BoosterType.hint:
        return BoosterTutorialOverlay(
          targetKey: _hintBtnKey,
          title: 'Hint Booster',
          subtitle: 'Tap Hint to highlight a clear word!',
          onTargetTapped: _handleHintTap,
        );
      case BoosterType.hammer:
        return BoosterTutorialOverlay(
          targetKey: _hammerBtnKey,
          title: 'Hammer Booster',
          subtitle: 'Tap Hammer, then tap any word to smash it!',
          onTargetTapped: _handleHammerTap,
        );
      case BoosterType.firework:
        return BoosterTutorialOverlay(
          targetKey: _fireworkBtnKey,
          title: 'Firework Booster',
          subtitle: 'Tap Firework to blast up to 5 words away!',
          onTargetTapped: _handleFireworkTap,
        );
    }
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _controller?.removeListener(_onControllerChanged);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hintUnlocked =
        _levelService.isBoosterUnlocked(BoosterType.hint, _currentLevelNumber);
    final hammerUnlocked =
        _levelService.isBoosterUnlocked(BoosterType.hammer, _currentLevelNumber);
    final fireworkUnlocked = _levelService.isBoosterUnlocked(
      BoosterType.firework,
      _currentLevelNumber,
    );

    return Scaffold(
      backgroundColor: GamePalette.boardBg,
      body: Stack(
        children: [
          // Authentic Game Background
          Positioned.fill(
            child: Image.asset(
              'assets/images/backgrounds/WordOutLevelBackground.png',
              fit: BoxFit.fill,
            ),
          ),
          SafeArea(
            bottom: false,
            child: Stack(
              children: [
                // Main Game Layout
                Column(
                  children: [
                    // Top Bar
                    GameTopBar(
                      levelNumber: _currentLevelNumber,
                      stars: _controller?.stars ?? 3,
                      coins: _levelService.coins,
                      onLevelTap: _openLevelSelect,
                    ),

                    // Board Area
                    Expanded(
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.amberAccent,
                              ),
                            )
                          : _errorMessage != null
                              ? Center(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                )
                              : GameBoard(
                                  key: ValueKey(_controller),
                                  controller: _controller!,
                                  onWin: _showVictoryDialog,
                                  onLose: _showGameOverDialog,
                                ),
                    ),

                    // Bottom Bar
                    GameBottomBar(
                      hintButtonKey: _hintBtnKey,
                      hammerButtonKey: _hammerBtnKey,
                      fireworkButtonKey: _fireworkBtnKey,
                      isHintLocked: !hintUnlocked,
                      isHammerLocked: !hammerUnlocked,
                      isFireworkLocked: !fireworkUnlocked,
                      hintCount: _levelService.getBoosterCount(BoosterType.hint),
                      hammerCount:
                          _levelService.getBoosterCount(BoosterType.hammer),
                      fireworkCount:
                          _levelService.getBoosterCount(BoosterType.firework),
                      onHintTap: _handleHintTap,
                      onHammerTap: _handleHammerTap,
                      onRocketTap: _handleFireworkTap,
                      onSettingsTap: _openSettings,
                      isHammerActive: _controller?.isHammerActive ?? false,
                    ),
                  ],
                ),

                // Red Flash Overlay on Blocked Move
                if (_controller != null && _controller!.isRedFlashing)
                  IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.redAccent.withValues(alpha: 0.7),
                          width: 12,
                        ),
                        color: Colors.red.withValues(alpha: 0.18),
                      ),
                    ),
                  ),

                // Hammer Armed Banner Indicator
                if (_controller != null && _controller!.isHammerActive)
                  Positioned(
                    top: 74,
                    left: 20,
                    right: 20,
                    child: IgnorePointer(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xEE071A36),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFFFFD530),
                              width: 2,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black45,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/images/boosters/WordsArrowHammerBooster.png',
                                width: 22,
                                height: 22,
                              ),
                              const SizedBox(width: 8),
                              const StrokedText(
                                'Tap any word or crate to smash!',
                                fontSize: 14,
                                strokeColor: Color(0xFF04152E),
                                strokeWidth: 2.8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // Clean In-Game Floating Toast
                if (_toastMessage != null)
                  Positioned(
                    bottom: 116,
                    left: 24,
                    right: 24,
                    child: IgnorePointer(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xEB071B38),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: const Color(0xFF39B9FF),
                              width: 1.6,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black54,
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: StrokedText(
                            _toastMessage!,
                            fontSize: 15,
                            strokeColor: const Color(0xFF031229),
                            strokeWidth: 3.0,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Guided Booster Spotlight Tutorial Overlay (above SafeArea so cutout spans full screen)
          if (_activeBoosterSpotlight != null) _buildBoosterSpotlightOverlay(),
        ],
      ),
    );
  }
}

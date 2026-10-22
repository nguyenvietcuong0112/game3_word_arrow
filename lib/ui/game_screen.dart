import 'package:flutter/material.dart';
import '../game/board_controller.dart';
import '../models/game_palette.dart';
import '../services/level_service.dart';
import 'dialogs/game_over_dialog.dart';
import 'dialogs/level_select_dialog.dart';
import 'dialogs/settings_dialog.dart';
import 'dialogs/victory_dialog.dart';
import 'widgets/game_bottom_bar.dart';
import 'widgets/game_board.dart';
import 'widgets/game_top_bar.dart';

class GameScreen extends StatefulWidget {
  final int? initialLevel;

  const GameScreen({super.key, this.initialLevel});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final LevelService _levelService = LevelService();

  late int _currentLevelNumber;
  BoardController? _controller;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isDialogShowing = false;

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

  Future<void> _loadLevel(int levelNum) async {
    _isDialogShowing = false;
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

      final newController = BoardController(level: levelModel);
      newController.addListener(_onControllerChanged);

      setState(() {
        _controller = newController;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load Level $levelNum: $e';
      });
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

    final earnedStars = _controller?.stars ?? 3;
    _levelService.saveLevelStars(_currentLevelNumber, earnedStars);
    _levelService.addCoins(50);
    _levelService.unlockNextLevel();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.72),
        builder: (_) => VictoryDialog(
          levelNumber: _currentLevelNumber,
          stars: earnedStars,
          coinsEarned: 50,
          onNextLevel: () {
            Navigator.pop(context);
            final nextLvl = _currentLevelNumber < 200 ? _currentLevelNumber + 1 : 1;
            _loadLevel(nextLvl);
          },
          onReplay: () {
            Navigator.pop(context);
            _loadLevel(_currentLevelNumber);
          },
        ),
      );
    });
  }

  void _showGameOverDialog() {
    if (_isDialogShowing) return;
    _isDialogShowing = true;

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.72),
        builder: (_) => GameOverDialog(
          levelNumber: _currentLevelNumber,
          isOutOfStars: (_controller?.stars ?? 0) <= 0,
          onRetry: () {
            Navigator.pop(context);
            _isDialogShowing = false;
            _loadLevel(_currentLevelNumber);
          },
          onRevive: () {
            Navigator.pop(context);
            _isDialogShowing = false;
            _controller?.revive();
          },
        ),
      );
    });
  }

  void _openLevelSelect() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.72),
      builder: (_) => LevelSelectDialog(
        currentLevel: _currentLevelNumber,
        onSelectLevel: (lvl) {
          _loadLevel(lvl);
        },
      ),
    );
  }

  void _openSettings() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.72),
      builder: (_) => SettingsDialog(
        onRestart: () {
          _loadLevel(_currentLevelNumber);
        },
        onOpenLevelSelect: () {
          _openLevelSelect();
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerChanged);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                                style: const TextStyle(color: Colors.white, fontSize: 16),
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
                  onHintTap: () {
                    if (_controller != null) {
                      final ok = _controller!.useHintBooster();
                      if (!ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No unobstructed lane found!'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    }
                  },
                  onHammerTap: () {
                    _controller?.toggleHammerBooster();
                  },
                  onRocketTap: () {
                    _controller?.useRocketBooster();
                  },
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
                      color: Colors.redAccent.withOpacity(0.7),
                      width: 12,
                    ),
                    color: Colors.red.withOpacity(0.18),
                  ),
                ),
              ),

            // Hammer Mode Banner Indicator
            if (_controller != null && _controller!.isHammerActive)
              Positioned(
                top: 76,
                left: 20,
                right: 20,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xEE0B192C),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFFFD530), width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black45,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      '🔨 HAMMER: Tap any tile or crate to smash!',
                      style: TextStyle(
                        fontFamily: 'Panteon',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ],
  ),
);
  }
}

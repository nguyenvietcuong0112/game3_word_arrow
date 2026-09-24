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
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => VictoryDialog(
          levelNumber: _currentLevelNumber,
          stars: _controller?.stars ?? 3,
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
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => GameOverDialog(
          levelNumber: _currentLevelNumber,
          isOutOfStars: (_controller?.stars ?? 0) <= 0,
          onRetry: () {
            Navigator.pop(context);
            _loadLevel(_currentLevelNumber);
          },
          onRevive: () {
            Navigator.pop(context);
            _controller?.revive();
          },
        ),
      );
    });
  }

  void _openLevelSelect() {
    showDialog(
      context: context,
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
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
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
                          : GameBoard(controller: _controller!),
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
                top: 70,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber, width: 2),
                    ),
                    child: const Text(
                      'HAMMER ACTIVE: Tap any tile or crate to destroy!',
                      style: TextStyle(
                        fontFamily: 'Panteon',
                        fontSize: 14,
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

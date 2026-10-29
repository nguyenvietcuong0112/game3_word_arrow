import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../../game/board_controller.dart';
import '../../game/flame/word_arrow_flame_game.dart';

class GameBoard extends StatefulWidget {
  final BoardController controller;
  final VoidCallback? onWin;
  final VoidCallback? onLose;

  const GameBoard({
    super.key,
    required this.controller,
    this.onWin,
    this.onLose,
  });

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  late WordArrowFlameGame _game;

  @override
  void initState() {
    super.initState();
    _createGame();
  }

  @override
  void didUpdateWidget(covariant GameBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _createGame();
    }
  }

  void _createGame() {
    _game = WordArrowFlameGame(
      controller: widget.controller,
      onWin: () => widget.onWin?.call(),
      onLose: () => widget.onLose?.call(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: GameWidget(
        key: ObjectKey(_game),
        game: _game,
      ),
    );
  }
}

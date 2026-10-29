import 'dart:math';
import 'package:flutter/material.dart';
import '../models/level_model.dart';
import '../services/audio_service.dart';

enum GameStatus { playing, won, lost }

class BoardController extends ChangeNotifier {
  final LevelModel level;
  final int levelNumber;
  final AudioService _audio = AudioService();

  late int movesLeft;
  int stars = 3;
  GameStatus status = GameStatus.playing;

  List<Lane> activeLanes = [];
  List<Crate> activeCrates = [];

  // Dragging state
  Lane? draggedLane;
  List<int> highlightedCellIndices = [];
  bool hasArrowHighlighted = false;
  List<Offset> dragPathPoints = [];

  // Animating lanes
  final Map<String, double> exitingLaneProgress = {};
  final Map<String, Offset> exitingLaneDirection = {};
  final Set<String> bouncingLaneIds = {};

  // Red flash effect for blocked move
  bool isRedFlashing = false;

  // Hint booster
  String? hintedLaneId;

  // Hammer booster & Hammer tutorial step 2 state
  bool isHammerActive = false;
  bool isHammerTutorialStep = false;
  VoidCallback? onHammerConsumedOnBoard;

  BoardController({
    required this.level,
    int? levelNumber,
  }) : levelNumber = levelNumber ??
            (level.levelIndex > 0
                ? level.levelIndex
                : (level.settings.levelNumber > 0 ? level.settings.levelNumber : 1)) {
    movesLeft = level.settings.moveLimit > 0 ? level.settings.moveLimit : 30;
    activeLanes = List.from(level.lanes);
    activeCrates = level.crates.map((c) => c.clone()).toList();
  }

  void notifyBoardChanged() => notifyListeners();

  /// Check if a cell is occupied by any active lane (other than [excludeLane])
  bool isCellOccupiedByOtherLane(int x, int y, {Lane? excludeLane}) {
    for (final lane in activeLanes) {
      if (excludeLane != null && lane.id == excludeLane.id) continue;
      if (lane.arrow.x == x && lane.arrow.y == y) return true;
      for (final cell in lane.cells) {
        if (cell.x == x && cell.y == y) return true;
      }
    }
    return false;
  }

  /// Check if a cell has an active crate
  bool isCellOccupiedByCrate(int x, int y) {
    return activeCrates.any((c) => c.x == x && c.y == y && c.threshold > 0);
  }

  /// Raycast along lane's arrow direction from arrow position to board edge
  /// Returns true if CLEAR to exit, false if BLOCKED by other lane or crate
  bool isPathClear(Lane lane) {
    if (lane.isLocked) return false;

    int dx = 0;
    int dy = 0;
    switch (lane.direction.toLowerCase()) {
      case 'up':
        dy = -1;
        break;
      case 'down':
        dy = 1;
        break;
      case 'left':
        dx = -1;
        break;
      case 'right':
        dx = 1;
        break;
      default:
        return true;
    }

    int cx = lane.arrow.x + dx;
    int cy = lane.arrow.y + dy;

    final w = level.grid.width;
    final h = level.grid.height;

    while (cx >= 0 && cx < w && cy >= 0 && cy < h) {
      if (isCellOccupiedByOtherLane(cx, cy, excludeLane: lane)) {
        return false;
      }
      if (isCellOccupiedByCrate(cx, cy)) {
        return false;
      }
      cx += dx;
      cy += dy;
    }

    return true;
  }

  /// Booster: Hint
  bool useHintBooster() {
    if (status != GameStatus.playing) return false;
    for (final lane in activeLanes) {
      if (isPathClear(lane)) {
        hintedLaneId = lane.id;
        _audio.playReward();
        notifyListeners();
        return true;
      }
    }
    // Fallback: if all clear lanes are locked/blocked, highlight first unlocked lane
    for (final lane in activeLanes) {
      if (!lane.isLocked) {
        hintedLaneId = lane.id;
        _audio.playReward();
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  /// Booster: Hammer
  void armHammerBooster({bool isTutorial = false}) {
    isHammerActive = true;
    isHammerTutorialStep = isTutorial;
    _audio.playButtonClick();
    notifyListeners();
  }

  void cancelHammerBooster() {
    if (isHammerTutorialStep) return; // Keep armed during tutorial step 2
    isHammerActive = false;
    _audio.playButtonClick();
    notifyListeners();
  }

  void toggleHammerBooster() {
    if (isHammerActive) {
      cancelHammerBooster();
    } else {
      armHammerBooster();
    }
  }

  /// Booster: Rocket / Firework callback delegate (handled by WordArrowFlameGame)
  bool Function()? onRocketBoosterTriggered;

  bool useRocketBooster() {
    if (status != GameStatus.playing) return false;
    if (onRocketBoosterTriggered != null) {
      return onRocketBoosterTriggered!();
    }
    return false;
  }

  /// Revive when out of stars (RewardedReviveLives = 1, PurchaseReviveLives = 3)
  void revive({int addStars = 3}) {
    if (movesLeft <= 0) {
      movesLeft += 10;
    }
    stars = (max(0, stars) + addStars).clamp(1, 3);
    status = GameStatus.playing;
    notifyListeners();
  }
}

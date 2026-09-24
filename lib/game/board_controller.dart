import 'dart:math';
import 'package:flutter/material.dart';
import '../models/level_model.dart';
import '../services/audio_service.dart';
import '../services/level_service.dart';

enum GameStatus { playing, won, lost }

class BoardController extends ChangeNotifier {
  final LevelModel level;
  final AudioService _audio = AudioService();
  final LevelService _levelService = LevelService();

  late int movesLeft;
  int stars = 3;
  GameStatus status = GameStatus.playing;

  List<Lane> activeLanes = [];
  List<Crate> activeCrates = [];

  // Dragging state
  Lane? draggedLane;
  List<int> highlightedCellIndices = []; // indices into draggedLane.cells
  bool hasArrowHighlighted = false;
  List<Offset> dragPathPoints = []; // screen coordinates for trail drawing

  // Animating lanes
  // laneId -> slide offset vector (normalized direction * progress * distance)
  final Map<String, double> exitingLaneProgress = {}; // 0.0 -> 1.0
  final Map<String, Offset> exitingLaneDirection = {};
  final Set<String> bouncingLaneIds = {};

  // Red flash effect for blocked move
  bool isRedFlashing = false;

  // Hint booster
  String? hintedLaneId;

  // Hammer booster
  bool isHammerActive = false;

  BoardController({required this.level}) {
    movesLeft = level.settings.moveLimit > 0 ? level.settings.moveLimit : 30;
    activeLanes = List.from(level.lanes);
    activeCrates = level.crates.map((c) => c.clone()).toList();
  }

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

  /// Start dragging interaction
  void onTouchDown(Offset localPos, double cellSize) {
    if (status != GameStatus.playing) return;

    final gx = (localPos.dx / cellSize).floor();
    final gy = (localPos.dy / cellSize).floor();

    if (isHammerActive) {
      _applyHammer(gx, gy);
      return;
    }

    // Find lane that contains this grid cell
    for (final lane in activeLanes) {
      if (lane.arrow.x == gx && lane.arrow.y == gy) {
        // Started on arrow
        draggedLane = lane;
        highlightedCellIndices = [];
        hasArrowHighlighted = true;
        dragPathPoints = [localPos];
        _audio.playTileSelect();
        notifyListeners();
        return;
      }
      for (int i = 0; i < lane.cells.length; i++) {
        if (lane.cells[i].x == gx && lane.cells[i].y == gy) {
          draggedLane = lane;
          highlightedCellIndices = [i];
          hasArrowHighlighted = true;
          dragPathPoints = [localPos];
          _audio.playTileSelect();
          notifyListeners();
          return;
        }
      }
    }
  }

  /// Drag hover over cell with segment collision detection
  void onTouchMove(Offset localPos, double cellSize) {
    if (draggedLane == null || status != GameStatus.playing) return;

    final prevPos = dragPathPoints.isNotEmpty ? dragPathPoints.last : localPos;
    dragPathPoints.add(localPos);

    final lane = draggedLane!;

    while (highlightedCellIndices.length < lane.cells.length) {
      final nextIdx = highlightedCellIndices.length;
      final expectedCell = lane.cells[nextIdx];
      final cellCenter = Offset(
        expectedCell.x * cellSize + cellSize / 2,
        expectedCell.y * cellSize + cellSize / 2,
      );

      final dist = _distToSegment(cellCenter, prevPos, localPos);
      if (dist < cellSize * 0.58) {
        highlightedCellIndices.add(nextIdx);
        _audio.playTileSelect();
      } else {
        break;
      }
    }

    notifyListeners();
  }

  double _distToSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final lengthSquared = ab.dx * ab.dx + ab.dy * ab.dy;
    if (lengthSquared == 0) return (p - a).distance;
    final t = (((p.dx - a.dx) * ab.dx + (p.dy - a.dy) * ab.dy) / lengthSquared).clamp(0.0, 1.0);
    final projection = Offset(a.dx + t * ab.dx, a.dy + t * ab.dy);
    return (p - projection).distance;
  }

  /// Touch up / release
  void onTouchUp() {
    if (draggedLane != null) {
      final lane = draggedLane!;
      _triggerLaneAction(lane);
      _resetDrag();
    }
  }

  void _resetDrag() {
    draggedLane = null;
    highlightedCellIndices = [];
    hasArrowHighlighted = false;
    dragPathPoints = [];
    notifyListeners();
  }

  /// Process lane release / completion
  void _triggerLaneAction(Lane lane) {
    if (isPathClear(lane)) {
      _executeLaneClear(lane);
    } else {
      _executeLaneBlocked(lane);
    }
  }

  /// Lane successfully clears!
  Future<void> _executeLaneClear(Lane lane) async {
    movesLeft--;
    hintedLaneId = null;

    Offset exitDir = Offset.zero;
    switch (lane.direction.toLowerCase()) {
      case 'up':
        exitDir = const Offset(0, -1);
        break;
      case 'down':
        exitDir = const Offset(0, 1);
        break;
      case 'left':
        exitDir = const Offset(-1, 0);
        break;
      case 'right':
        exitDir = const Offset(1, 0);
        break;
    }

    exitingLaneDirection[lane.id] = exitDir;
    exitingLaneProgress[lane.id] = 0.0;
    _audio.playLaneClear();
    notifyListeners();

    // Smooth exit slide animation
    const steps = 15;
    for (int i = 1; i <= steps; i++) {
      await Future.delayed(const Duration(milliseconds: 20));
      exitingLaneProgress[lane.id] = Curves.easeIn.transform(i / steps);
      notifyListeners();
    }

    // Remove lane from active board
    activeLanes.removeWhere((l) => l.id == lane.id);
    exitingLaneProgress.remove(lane.id);
    exitingLaneDirection.remove(lane.id);

    // Damage crates
    bool crateDamaged = false;
    for (final crate in activeCrates) {
      if (crate.threshold > 0) {
        crate.threshold--;
        crateDamaged = true;
      }
    }
    if (crateDamaged) {
      _audio.playCrateHit();
      // Remove broken crates
      activeCrates.removeWhere((c) => c.threshold <= 0);
    }

    // Check Win condition
    if (activeLanes.isEmpty) {
      status = GameStatus.won;
      _audio.playWin();
      await _levelService.saveLevelStars(level.levelIndex, stars);
      await _levelService.addCoins(50);
      await _levelService.unlockNextLevel();
    } else if (movesLeft <= 0) {
      status = GameStatus.lost;
      _audio.playLose();
    }

    notifyListeners();
  }

  /// Lane is blocked: bounce, deduct star, flash red
  Future<void> _executeLaneBlocked(Lane lane) async {
    bouncingLaneIds.add(lane.id);
    isRedFlashing = true;
    stars = max(0, stars - 1);
    _audio.playBlockedBounce();
    notifyListeners();

    // Shake / bounce duration
    await Future.delayed(const Duration(milliseconds: 400));
    bouncingLaneIds.remove(lane.id);
    isRedFlashing = false;

    // Check lose condition
    if (stars <= 0) {
      status = GameStatus.lost;
      _audio.playLose();
    }

    notifyListeners();
  }

  /// Booster: Hint
  bool useHintBooster() {
    if (status != GameStatus.playing) return false;
    // Find first clear lane
    for (final lane in activeLanes) {
      if (isPathClear(lane)) {
        hintedLaneId = lane.id;
        _audio.playReward();
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  /// Booster: Hammer
  void toggleHammerBooster() {
    isHammerActive = !isHammerActive;
    _audio.playButtonClick();
    notifyListeners();
  }

  void _applyHammer(int gx, int gy) {
    isHammerActive = false;

    // Smashes crate or removes lane
    final crateIndex = activeCrates.indexWhere((c) => c.x == gx && c.y == gy);
    if (crateIndex != -1) {
      activeCrates.removeAt(crateIndex);
      _audio.playCrateHit();
      notifyListeners();
      return;
    }

    final laneIndex = activeLanes.indexWhere((l) => l.containsPos(gx, gy));
    if (laneIndex != -1) {
      final lane = activeLanes[laneIndex];
      _executeLaneClear(lane);
    }
  }

  /// Booster: Rocket / Firework (Clears first clear or removes an obstacle crate)
  bool useRocketBooster() {
    if (status != GameStatus.playing) return false;

    if (activeCrates.isNotEmpty) {
      activeCrates.removeAt(0);
      _audio.playLaneClear();
      notifyListeners();
      return true;
    }

    if (activeLanes.isNotEmpty) {
      final lane = activeLanes.first;
      _executeLaneClear(lane);
      return true;
    }

    return false;
  }

  /// Revive when out of moves or stars
  void revive() {
    movesLeft += 10;
    stars = max(1, stars);
    status = GameStatus.playing;
    notifyListeners();
  }
}

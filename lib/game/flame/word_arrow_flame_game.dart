import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' hide Image;
import '../board_controller.dart';
import '../../models/game_palette.dart';
import '../../models/level_model.dart';
import '../../services/audio_service.dart';

class WordArrowFlameGame extends FlameGame with PanDetector {
  final BoardController controller;
  final VoidCallback onWin;
  final VoidCallback onLose;

  WordArrowFlameGame({
    required this.controller,
    required this.onWin,
    required this.onLose,
  });

  final AudioService _audio = AudioService();

  // Loaded images
  ui.Image? _tileCream;
  ui.Image? _tileShadow;
  ui.Image? _arrowBase;
  ui.Image? _crateImg;
  ui.Image? _cloudImg;
  ui.Image? _rocketImg;

  final Map<int, ui.Image> _lockImages = {};
  final Map<int, ui.Image> _keyImages = {};

  // Layout metrics
  double _cellSize = 48.0;
  double _tileSize = 44.0;
  double _tileSpacing = 4.0;
  Vector2 _origin = Vector2.zero();

  // Animation & game structures
  final Map<String, _LaneAnimState> _laneAnims = {};
  final Map<PointPos, _LockState> _locks = {};
  final List<_FlyingKey> _flyingKeys = [];
  final List<_FlyingRocket> _flyingRockets = [];
  final List<_Particle> _particles = [];
  final Random _rng = Random();
  double _hintPulseTime = 0.0;

  // Dragging state
  Lane? _draggedLane;
  Vector2? _dragStartPos;
  Vector2? _dragLastPos;

  @override
  Color backgroundColor() => Colors.transparent;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Preload all authentic board images
    _tileCream = await images.load('board/tile_cream.png');
    _tileShadow = await images.load('board/tile_shadow.png');
    _arrowBase = await images.load('board/arrow_base.png');
    _crateImg = await images.load('board/crate.png');

    try {
      _cloudImg = await images.load('vfx/T_VFX_Cloud.png');
    } catch (_) {}

    try {
      _rocketImg = await images.load('boosters/WordsArrowFireworkBooster.png');
    } catch (_) {}

    // Locks & Keys (0: gold, 1: red, 2: blue, 3: green)
    final lockFiles = ['lock_gold.png', 'lock_red.png', 'lock_blue.png', 'lock_green.png'];
    final keyFiles = ['key_gold.png', 'key_red.png', 'key_blue.png', 'key_green.png'];

    for (int i = 0; i < 4; i++) {
      try {
        _lockImages[i] = await images.load('board/${lockFiles[i]}');
        _keyImages[i] = await images.load('board/${keyFiles[i]}');
      } catch (_) {}
    }

    controller.onRocketBoosterTriggered = triggerRocketBooster;
    _initLevelState();
  }

  @override
  void onRemove() {
    controller.onRocketBoosterTriggered = null;
    super.onRemove();
  }

  void _initLevelState() {
    _laneAnims.clear();
    _locks.clear();
    _flyingKeys.clear();
    _flyingRockets.clear();
    _particles.clear();
    _hintPulseTime = 0.0;

    for (final lane in controller.activeLanes) {
      _laneAnims[lane.id] = _LaneAnimState(lane: lane);
    }

    // Build lock and key associations
    int lockIdx = 0;
    for (final lane in controller.activeLanes) {
      for (final cell in lane.cells) {
        if (cell.locked && cell.keyRef != null) {
          final colorIdx = lockIdx % 4;
          _locks[cell.pos] = _LockState(
            pos: cell.pos,
            keyPos: cell.keyRef!,
            colorIdx: colorIdx,
          );
          lockIdx++;
        }
      }
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _calculateLayout();
  }

  void _calculateLayout() {
    final gridW = controller.level.grid.width;
    final gridH = controller.level.grid.height;
    if (gridW <= 0 || gridH <= 0) return;

    final availW = size.x * 0.94;
    final availH = size.y * 0.94;

    final cellW = availW / gridW;
    final cellH = availH / gridH;

    _cellSize = min(cellW, cellH).clamp(36.0, 78.0);
    _tileSpacing = _cellSize * 0.08;
    _tileSize = _cellSize - _tileSpacing;

    final boardW = _cellSize * gridW;
    final boardH = _cellSize * gridH;

    _origin = Vector2(
      (size.x - boardW) / 2.0,
      (size.y - boardH) / 2.0,
    );
  }

  Vector2 _gridToPixel(int gx, int gy) {
    return Vector2(
      _origin.x + gx * _cellSize + _tileSpacing / 2.0,
      _origin.y + gy * _cellSize + _tileSpacing / 2.0,
    );
  }

  PointPos _pixelToGrid(Vector2 pos) {
    final gx = ((pos.x - _origin.x) / _cellSize).floor();
    final gy = ((pos.y - _origin.y) / _cellSize).floor();
    return PointPos(x: gx, y: gy);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Update lane animations
    final List<String> finishedExits = [];
    _laneAnims.forEach((id, anim) {
      anim.update(dt);
      if (anim.isExited) {
        finishedExits.add(id);
      }
    });

    for (final id in finishedExits) {
      final anim = _laneAnims.remove(id);
      if (anim != null) {
        controller.activeLanes.removeWhere((l) => l.id == id);
      }
      if (controller.activeLanes.isEmpty) {
        controller.status = GameStatus.won;
        _audio.playWin();
        onWin();
      }
    }

    // Update flying keys
    for (int i = _flyingKeys.length - 1; i >= 0; i--) {
      final k = _flyingKeys[i];
      k.update(dt);
      if (k.isFinished) {
        k.onArrive();
        _flyingKeys.removeAt(i);
      }
    }

    // Update lock unlock animations
    _locks.forEach((pos, lock) {
      if (lock.isUnlocking) {
        lock.unlockProgress += dt * 2.5;
        if (lock.unlockProgress >= 1.0) {
          lock.isUnlocking = false;
          lock.isUnlocked = true;
          // Unlock letter cell in controller
          for (int li = 0; li < controller.activeLanes.length; li++) {
            final l = controller.activeLanes[li];
            final cellIdx = l.cells.indexWhere((c) => c.pos == pos);
            if (cellIdx != -1) {
              final updatedCells = List<LetterCell>.from(l.cells);
              updatedCells[cellIdx] = updatedCells[cellIdx].copyWith(locked: false);
              final updatedLane = l.copyWith(cells: updatedCells);
              controller.activeLanes[li] = updatedLane;
              _laneAnims[updatedLane.id]?.lane = updatedLane;
              break;
            }
          }
        }
      }
    });

    // Update hint pulse
    if (controller.hintedLaneId != null) {
      _hintPulseTime += dt;
    }

    // Update flying rockets
    for (int i = _flyingRockets.length - 1; i >= 0; i--) {
      final r = _flyingRockets[i];
      r.update(dt);
      // Spawn trail smoke while flying
      final trailPos = r.currentPosition;
      _spawnSmokeParticle(trailPos, -r.direction * 30.0);
      if (r.isFinished) {
        r.onImpact();
        _flyingRockets.removeAt(i);
      }
    }

    // Update particles
    for (int i = _particles.length - 1; i >= 0; i--) {
      final p = _particles[i];
      p.update(dt);
      if (p.isDead) {
        _particles.removeAt(i);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (size.x <= 0 || size.y <= 0) return;

    // 1. Draw Crate drop shadows and Crates
    for (final crate in controller.activeCrates) {
      if (crate.threshold <= 0) continue;
      final pos = _gridToPixel(crate.x, crate.y);
      _drawCrate(canvas, pos, crate);
    }

    // 2. Draw Soft Drop Shadows for all Active Tiles & Arrows
    _laneAnims.forEach((id, anim) {
      if (anim.isExited) return;
      _drawLaneShadows(canvas, anim);
    });

    // 3. Draw Active Tiles and Arrows
    _laneAnims.forEach((id, anim) {
      if (anim.isExited) return;
      _drawLaneTiles(canvas, anim);
    });

    // 4. Draw Locks
    _locks.forEach((pos, lock) {
      if (!lock.isUnlocked) {
        _drawLock(canvas, pos, lock);
      }
    });

    // 5. Draw Keys attached to cells
    _locks.forEach((lockPos, lock) {
      if (!lock.isUnlocked) {
        final keyPos = lock.keyPos;
        // Check if key cell's lane is still on board
        final lane = controller.activeLanes.firstWhere(
          (l) => l.cells.any((c) => c.pos == keyPos),
          orElse: () => Lane(id: '', color: 0, arrow: const PointPos(x: -1, y: -1), direction: '', cells: []),
        );
        if (lane.id.isNotEmpty) {
          final anim = _laneAnims[lane.id];
          final offset = anim != null ? anim.currentOffset : Vector2.zero();
          final pixelPos = _gridToPixel(keyPos.x, keyPos.y) + offset;
          _drawKeyBadge(canvas, pixelPos, lock.colorIdx);
        }
      }
    });

    // 6. Draw Flying Keys
    for (final fk in _flyingKeys) {
      _drawFlyingKey(canvas, fk);
    }

    // 6b. Draw Flying Rockets
    for (final r in _flyingRockets) {
      _drawFlyingRocket(canvas, r);
    }

    // 7. Draw Particles (Smoke clouds, sparklers)
    for (final p in _particles) {
      p.render(canvas, _cloudImg);
    }
  }

  void _drawCrate(Canvas canvas, Vector2 pos, Crate crate) {
    if (_tileShadow != null) {
      final sRect = Rect.fromLTWH(pos.x - 1, pos.y + _tileSize * 0.08, _tileSize + 2, _tileSize + 2);
      canvas.drawImageRect(
        _tileShadow!,
        Rect.fromLTWH(0, 0, _tileShadow!.width.toDouble(), _tileShadow!.height.toDouble()),
        sRect,
        Paint()..color = Colors.white.withOpacity(0.38),
      );
    }

    final rect = Rect.fromLTWH(pos.x, pos.y, _tileSize, _tileSize);
    if (_crateImg != null) {
      canvas.drawImageRect(_crateImg!, Rect.fromLTWH(0, 0, _crateImg!.width.toDouble(), _crateImg!.height.toDouble()), rect, Paint());
    } else {
      final p = Paint()..color = const Color(0xFFDF9548);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(_tileSize * 0.2)), p);
    }

    // Draw Crate Threshold number
    final tp = TextPainter(
      text: TextSpan(
        text: '${crate.threshold}',
        style: TextStyle(
          fontFamily: 'Panteon',
          fontSize: _tileSize * 0.44,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          shadows: const [
            Shadow(offset: Offset(0, 1.5), color: Color(0xFF3B1E05), blurRadius: 2),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.x + (_tileSize - tp.width) / 2, pos.y + (_tileSize - tp.height) / 2 - 2));
  }

  void _drawLaneShadows(Canvas canvas, _LaneAnimState anim) {
    final lane = anim.lane;
    final offset = anim.currentOffset;

    if (_tileShadow == null) return;
    final shadowPaint = Paint()..color = Colors.white.withOpacity(0.38 * anim.opacity);

    // Arrow soft downward drop shadow (never rotate with arrow direction - global top-down lighting)
    final aPos = _gridToPixel(lane.arrow.x, lane.arrow.y) + offset;
    final aShadowRect = Rect.fromLTWH(aPos.x - 1, aPos.y + _tileSize * 0.08, _tileSize + 2, _tileSize + 2);
    canvas.drawImageRect(
      _tileShadow!,
      Rect.fromLTWH(0, 0, _tileShadow!.width.toDouble(), _tileShadow!.height.toDouble()),
      aShadowRect,
      shadowPaint,
    );

    // Tile shadows (consistent soft downward drop shadow)
    for (final cell in lane.cells) {
      final pos = _gridToPixel(cell.x, cell.y) + offset;
      final sRect = Rect.fromLTWH(pos.x - 1, pos.y + _tileSize * 0.08, _tileSize + 2, _tileSize + 2);
      canvas.drawImageRect(
        _tileShadow!,
        Rect.fromLTWH(0, 0, _tileShadow!.width.toDouble(), _tileShadow!.height.toDouble()),
        sRect,
        shadowPaint,
      );
    }
  }

  void _drawLaneTiles(Canvas canvas, _LaneAnimState anim) {
    final lane = anim.lane;
    final offset = anim.currentOffset;
    final style = GamePalette.getStyle(lane.color);
    final isHinted = lane.id == controller.hintedLaneId;
    final hintPulse = isHinted ? (sin(_hintPulseTime * 6.0) + 1.0) / 2.0 : 0.0;

    final aPos = _gridToPixel(lane.arrow.x, lane.arrow.y) + offset;

    // Glowing border outline when hinted
    if (isHinted) {
      final glowPaint = Paint()
        ..color = Color.lerp(const Color(0xFFFFD530), const Color(0xFF00E5FF), hintPulse)!.withOpacity(0.85 * anim.opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5 + hintPulse * 2.0;

      // Glow around arrow
      final aRect = Rect.fromCenter(
        center: Offset(aPos.x + _tileSize / 2, aPos.y + _tileSize / 2),
        width: _tileSize * 1.02,
        height: _tileSize * 1.02,
      );
      canvas.drawRRect(RRect.fromRectAndRadius(aRect, Radius.circular(_tileSize * 0.22)), glowPaint);

      // Glow around all cells
      for (final cell in lane.cells) {
        final cPos = _gridToPixel(cell.x, cell.y) + offset;
        final cRect = Rect.fromLTWH(cPos.x - 1, cPos.y - 1, _tileSize + 2, _tileSize + 2);
        canvas.drawRRect(RRect.fromRectAndRadius(cRect, Radius.circular(_tileSize * 0.22)), glowPaint);
      }
    }

    // 1. Draw Arrow
    final arrowScale = 1.0 + (isHinted ? 0.12 * sin(_hintPulseTime * 6.0) : 0.0);
    canvas.save();
    canvas.translate(aPos.x + _tileSize / 2, aPos.y + _tileSize / 2);
    canvas.rotate(_directionToAngle(lane.direction));
    canvas.scale(arrowScale);

    final arrowDrawRect = Rect.fromCenter(center: Offset.zero, width: _tileSize, height: _tileSize);
    if (_arrowBase != null) {
      final p = Paint()
        ..color = style.light.withOpacity(anim.opacity)
        ..colorFilter = ColorFilter.mode(style.light.withOpacity(anim.opacity), BlendMode.modulate);
      canvas.drawImageRect(
        _arrowBase!,
        Rect.fromLTWH(0, 0, _arrowBase!.width.toDouble(), _arrowBase!.height.toDouble()),
        arrowDrawRect,
        p,
      );
    }
    canvas.restore();

    // Draw word length on arrow (unrotated)
    final wordLength = lane.length;

    final atp = TextPainter(
      text: TextSpan(
        text: '$wordLength',
        style: TextStyle(
          fontFamily: 'Panteon',
          fontSize: _tileSize * 0.44,
          fontWeight: FontWeight.w900,
          color: style.textColor.withOpacity(anim.opacity),
          shadows: [
            Shadow(
              offset: const Offset(0, 1),
              color: Colors.white.withOpacity(0.3 * anim.opacity),
              blurRadius: 1,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    atp.paint(canvas, Offset(aPos.x + (_tileSize - atp.width) / 2, aPos.y + (_tileSize - atp.height) / 2 - 2));

    // 2. Draw Letter Cells
    for (int i = 0; i < lane.cells.length; i++) {
      final cell = lane.cells[i];
      final pos = _gridToPixel(cell.x, cell.y) + offset;
      final isHead = (i == 0);

      _drawLetterTile(
        canvas: canvas,
        pos: pos,
        letter: cell.letter,
        isHead: isHead,
        isHighlighted: false,
        isLocked: cell.locked,
        style: style,
        anim: anim,
      );
    }
  }

  void _drawLetterTile({
    required Canvas canvas,
    required Vector2 pos,
    required String letter,
    required bool isHead,
    required bool isHighlighted,
    required bool isLocked,
    required LaneColorStyle style,
    required _LaneAnimState anim,
  }) {
    final rect = Rect.fromLTWH(pos.x, pos.y, _tileSize, _tileSize);

    // Base tile
    if (_tileCream != null) {
      Color tint = const Color(0xFFFFFDF9);
      if (isHighlighted) {
        tint = const Color(0xFFFFE082); // Gold selection
      } else if (isHead) {
        tint = style.light; // Head tile matches arrow accent color
      }

      final p = Paint()
        ..color = tint.withOpacity(anim.opacity)
        ..colorFilter = ColorFilter.mode(tint.withOpacity(anim.opacity), BlendMode.modulate);

      canvas.drawImageRect(
        _tileCream!,
        Rect.fromLTWH(0, 0, _tileCream!.width.toDouble(), _tileCream!.height.toDouble()),
        rect,
        p,
      );
    }

    // Red Shudder overlay on blocked bounce
    if (anim.redFlashAlpha > 0.0) {
      final redPaint = Paint()
        ..color = const Color(0xFFFB7185).withOpacity(anim.redFlashAlpha * anim.opacity);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(_tileSize * 0.22)),
        redPaint,
      );
    }

    // If locked, padlock will be drawn over it in lock pass, hide letter
    if (isLocked) return;

    // Draw Letter
    final textColor = (isHead || isHighlighted)
        ? style.textColor.withOpacity(anim.opacity)
        : const Color(0xFF261912).withOpacity(anim.opacity);

    final tp = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          fontFamily: 'Panteon',
          fontSize: _tileSize * 0.52,
          fontWeight: FontWeight.w900,
          color: textColor,
          letterSpacing: -0.5,
          shadows: (isHead || isHighlighted)
              ? [
                  Shadow(
                    offset: const Offset(0, 1),
                    color: Colors.white.withOpacity(0.3 * anim.opacity),
                    blurRadius: 1,
                  ),
                ]
              : null,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Offset slightly upward due to 3D bevel extrusion
    tp.paint(canvas, Offset(pos.x + (_tileSize - tp.width) / 2, pos.y + (_tileSize - tp.height) / 2 - _tileSize * 0.06));
  }

  void _drawLock(Canvas canvas, PointPos pos, _LockState lock) {
    final lane = controller.activeLanes.firstWhere(
      (l) => l.cells.any((c) => c.pos == pos),
      orElse: () => Lane(id: '', color: 0, arrow: const PointPos(x: -1, y: -1), direction: '', cells: []),
    );
    final anim = lane.id.isNotEmpty ? _laneAnims[lane.id] : null;
    final offset = anim != null ? anim.currentOffset : Vector2.zero();
    final pPos = _gridToPixel(pos.x, pos.y) + offset;

    final img = _lockImages[lock.colorIdx];
    if (img == null) return;

    final lockW = _tileSize * 0.72;
    final lockH = _tileSize * 0.82;

    double scale = 1.0;
    double alpha = 1.0;
    if (lock.isUnlocking) {
      // Pop scale up, then shrink to 0
      final t = lock.unlockProgress;
      if (t < 0.4) {
        scale = 1.0 + sin(t / 0.4 * pi) * 0.35;
      } else {
        scale = (1.0 - (t - 0.4) / 0.6).clamp(0.0, 1.0);
        alpha = scale;
      }
    }

    canvas.save();
    canvas.translate(pPos.x + _tileSize / 2, pPos.y + _tileSize / 2 - 2);
    canvas.scale(scale);

    final lRect = Rect.fromCenter(center: Offset.zero, width: lockW, height: lockH);
    canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      lRect,
      Paint()..color = Colors.white.withOpacity(alpha),
    );
    canvas.restore();
  }

  void _drawKeyBadge(Canvas canvas, Vector2 tilePos, int colorIdx) {
    final img = _keyImages[colorIdx];
    if (img == null) return;

    final keySize = _tileSize * 0.44;
    // Positioned at the bottom-left corner of the letter tile
    final rect = Rect.fromLTWH(
      tilePos.x - keySize * 0.15,
      tilePos.y + _tileSize - keySize * 0.95,
      keySize,
      keySize,
    );

    canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      rect,
      Paint(),
    );
  }

  void _drawFlyingKey(Canvas canvas, _FlyingKey key) {
    final img = _keyImages[key.colorIdx];
    if (img == null) return;

    final curPos = key.currentPosition;
    final keySize = _tileSize * 0.65;

    // Drop shadow under flying key
    final shadowPaint = Paint()..color = Colors.black.withOpacity(0.35);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(curPos.x + 4, curPos.y + 12), width: keySize * 0.8, height: keySize * 0.4),
      shadowPaint,
    );

    canvas.save();
    canvas.translate(curPos.x, curPos.y);
    canvas.rotate(key.rotation);

    final kRect = Rect.fromCenter(center: Offset.zero, width: keySize, height: keySize);
    canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      kRect,
      Paint(),
    );
    canvas.restore();
  }

  // ==================== GESTURE INPUT ====================

  @override
  void onPanStart(DragStartInfo info) {
    if (controller.status != GameStatus.playing) return;

    // Reset hint on any interaction
    if (controller.hintedLaneId != null) {
      controller.hintedLaneId = null;
      controller.notifyBoardChanged();
    }

    final pos = Vector2(info.eventPosition.widget.x, info.eventPosition.widget.y);
    _dragStartPos = pos;
    _dragLastPos = pos;
    final gridPos = _pixelToGrid(pos);

    // Booster: Hammer
    if (controller.isHammerActive) {
      _applyHammer(gridPos.x, gridPos.y);
      return;
    }

    // Find clicked lane (tap/drag on arrow or any cell of the word)
    for (final lane in controller.activeLanes) {
      if (lane.arrow.x == gridPos.x && lane.arrow.y == gridPos.y) {
        _draggedLane = lane;
        _audio.playTileSelect();
        return;
      }
      for (int i = 0; i < lane.cells.length; i++) {
        if (lane.cells[i].x == gridPos.x && lane.cells[i].y == gridPos.y) {
          _draggedLane = lane;
          _audio.playTileSelect();
          return;
        }
      }
    }
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (_draggedLane == null || controller.status != GameStatus.playing) return;
    _dragLastPos = Vector2(info.eventPosition.widget.x, info.eventPosition.widget.y);
  }

  @override
  void onPanEnd(DragEndInfo info) {
    if (_draggedLane != null) {
      final lane = _draggedLane!;
      final vel = Vector2(info.velocity.x, info.velocity.y);
      final delta = (_dragLastPos != null && _dragStartPos != null)
          ? (_dragLastPos! - _dragStartPos!)
          : Vector2.zero();
      final dirVec = _directionToVector(lane.direction);

      bool shouldCommit = false;

      // 1. Short tap anywhere on the lane (arrow or letters)
      if (delta.length < 24.0) {
        shouldCommit = true;
      } else {
        // 2. Flick / swipe gesture in the direction of the arrow
        final velProj = vel.dot(dirVec);
        final deltaProj = delta.dot(dirVec);

        if (vel.length > 80.0 && velProj > 0.2) {
          shouldCommit = true;
        } else if (delta.length > 15.0 && deltaProj > 0.25 * delta.length) {
          shouldCommit = true;
        }
      }

      if (shouldCommit) {
        _commitLane(lane);
      }

      _resetDrag();
    }
  }

  @override
  void onPanCancel() {
    _resetDrag();
  }

  void _resetDrag() {
    _draggedLane = null;
    _dragStartPos = null;
    _dragLastPos = null;
  }

  // ==================== GAME LOGIC & COMMITS ====================

  void _commitLane(Lane lane) {
    final anim = _laneAnims[lane.id];
    if (anim == null || anim.isExiting) return;

    // Check if lane is locked
    if (lane.isLocked) {
      _executeBlockedRecoil(anim, isLockedDirectly: true);
      return;
    }

    // Check raycast path
    if (controller.isPathClear(lane)) {
      _executeExitFlight(anim);
    } else {
      _executeBlockedRecoil(anim);
    }
  }

  void _executeExitFlight(_LaneAnimState anim) {
    final lane = anim.lane;
    controller.movesLeft--;

    final dirVec = _directionToVector(lane.direction);
    anim.beginExitFlight(dirVec);
    _audio.playLaneClear();

    // Spawn exit smoke particles
    final arrowPixel = _gridToPixel(lane.arrow.x, lane.arrow.y) + Vector2(_tileSize / 2, _tileSize / 2);
    for (int i = 0; i < 8; i++) {
      _spawnSmokeParticle(arrowPixel, dirVec);
    }

    // Check if this lane carries any keys
    for (final cell in lane.cells) {
      final matchingLockEntry = _locks.entries.firstWhere(
        (e) => e.value.keyPos == cell.pos && !e.value.isUnlocked,
        orElse: () => MapEntry(const PointPos(x: -1, y: -1), _LockState(pos: const PointPos(x: -1, y: -1), keyPos: const PointPos(x: -1, y: -1), colorIdx: 0)),
      );

      if (matchingLockEntry.key.x != -1) {
        final lockState = matchingLockEntry.value;
        final startPos = _gridToPixel(cell.x, cell.y) + Vector2(_tileSize / 2, _tileSize / 2);
        final targetPos = _gridToPixel(lockState.pos.x, lockState.pos.y) + Vector2(_tileSize / 2, _tileSize / 2);

        _flyingKeys.add(_FlyingKey(
          start: startPos,
          target: targetPos,
          colorIdx: lockState.colorIdx,
          onArrive: () {
            lockState.isUnlocking = true;
            _audio.playUnlock();
            // Spawn sparkler burst
            for (int s = 0; s < 12; s++) {
              _spawnSparklerParticle(targetPos);
            }
          },
        ));
      }
    }

    // Damage crates along path
    bool crateDamaged = false;
    for (final crate in controller.activeCrates) {
      if (crate.threshold > 0) {
        crate.threshold--;
        crateDamaged = true;
      }
    }
    if (crateDamaged) {
      _audio.playCrateHit();
      controller.activeCrates.removeWhere((c) => c.threshold <= 0);
    }

    controller.notifyBoardChanged();
  }

  void _executeBlockedRecoil(_LaneAnimState anim, {bool isLockedDirectly = false}) {
    final lane = anim.lane;
    final dirVec = _directionToVector(lane.direction);

    anim.beginRecoil(dirVec);
    controller.stars = max(0, controller.stars - 1);
    _audio.playBlockedBounce();

    if (controller.stars <= 0) {
      controller.status = GameStatus.lost;
      _audio.playLose();
      onLose();
    }

    controller.notifyBoardChanged();
  }

  void _applyHammer(int gx, int gy) {
    controller.isHammerActive = false;

    // 1. Crate check
    final crateIdx = controller.activeCrates.indexWhere((c) => c.x == gx && c.y == gy);
    if (crateIdx != -1) {
      final crate = controller.activeCrates[crateIdx];
      final pPos = _gridToPixel(crate.x, crate.y) + Vector2(_tileSize / 2, _tileSize / 2);
      for (int i = 0; i < 18; i++) {
        _spawnSmokeParticle(pPos, Vector2.zero());
      }
      for (int i = 0; i < 12; i++) {
        _spawnSparklerParticle(pPos);
      }
      controller.activeCrates.removeAt(crateIdx);
      _audio.playCrateHit();
      controller.notifyBoardChanged();
      return;
    }

    // 2. Active Lane check (tapped arrow or any letter tile in lane)
    for (final lane in controller.activeLanes) {
      if ((lane.arrow.x == gx && lane.arrow.y == gy) || lane.cells.any((c) => c.x == gx && c.y == gy)) {
        final anim = _laneAnims[lane.id];
        if (anim != null && !anim.isExiting) {
          final aPos = _gridToPixel(lane.arrow.x, lane.arrow.y) + Vector2(_tileSize / 2, _tileSize / 2);
          for (int i = 0; i < 10; i++) {
            _spawnSmokeParticle(aPos, Vector2.zero());
          }
          for (final cell in lane.cells) {
            final cPos = _gridToPixel(cell.x, cell.y) + Vector2(_tileSize / 2, _tileSize / 2);
            for (int i = 0; i < 10; i++) {
              _spawnSmokeParticle(cPos, Vector2.zero());
            }
            for (int i = 0; i < 6; i++) {
              _spawnSparklerParticle(cPos);
            }
          }
          _audio.playCrateHit();
          _executeExitFlight(anim);
          return;
        }
      }
    }

    controller.notifyBoardChanged();
  }

  bool triggerRocketBooster() {
    if (controller.status != GameStatus.playing) return false;

    // 1. Target crate if any exist
    if (controller.activeCrates.isNotEmpty) {
      final crate = controller.activeCrates.first;
      final targetPos = _gridToPixel(crate.x, crate.y) + Vector2(_tileSize / 2, _tileSize / 2);
      final startPos = Vector2(targetPos.x, size.y + 80);

      _flyingRockets.add(_FlyingRocket(
        start: startPos,
        target: targetPos,
        onImpact: () {
          for (int i = 0; i < 20; i++) {
            _spawnSmokeParticle(targetPos, Vector2.zero());
          }
          for (int i = 0; i < 15; i++) {
            _spawnSparklerParticle(targetPos);
          }
          controller.activeCrates.remove(crate);
          _audio.playCrateHit();
          controller.notifyBoardChanged();
        },
      ));
      _audio.playSwipe();
      return true;
    }

    // 2. Target first clear or active lane
    Lane? targetLane;
    for (final l in controller.activeLanes) {
      if (controller.isPathClear(l) && !l.isLocked) {
        targetLane = l;
        break;
      }
    }
    targetLane ??= (controller.activeLanes.isNotEmpty ? controller.activeLanes.first : null);

    if (targetLane != null) {
      final anim = _laneAnims[targetLane.id];
      if (anim != null && !anim.isExiting) {
        final aPos = _gridToPixel(targetLane.arrow.x, targetLane.arrow.y) + Vector2(_tileSize / 2, _tileSize / 2);
        final startPos = Vector2(aPos.x, size.y + 80);

        _flyingRockets.add(_FlyingRocket(
          start: startPos,
          target: aPos,
          onImpact: () {
            for (int i = 0; i < 15; i++) {
              _spawnSparklerParticle(aPos);
            }
            _executeExitFlight(anim);
          },
        ));
        _audio.playSwipe();
        return true;
      }
    }

    return false;
  }

  void _drawFlyingRocket(Canvas canvas, _FlyingRocket rocket) {
    final curPos = rocket.currentPosition;
    final rSize = _tileSize * 0.95;

    canvas.save();
    canvas.translate(curPos.x, curPos.y);
    canvas.rotate(rocket.angle + pi / 2);

    if (_rocketImg != null) {
      final rect = Rect.fromCenter(center: Offset.zero, width: rSize, height: rSize);
      canvas.drawImageRect(
        _rocketImg!,
        Rect.fromLTWH(0, 0, _rocketImg!.width.toDouble(), _rocketImg!.height.toDouble()),
        rect,
        Paint(),
      );
    } else {
      final p = Paint()..color = const Color(0xFFFF3E5A);
      canvas.drawCircle(Offset.zero, rSize * 0.35, p);
    }
    canvas.restore();
  }

  void _spawnSmokeParticle(Vector2 pos, Vector2 biasDir) {
    final angle = _rng.nextDouble() * 2 * pi;
    final speed = 40.0 + _rng.nextDouble() * 90.0;
    final vel = Vector2(cos(angle), sin(angle)) * speed + biasDir * 50.0;

    _particles.add(_Particle(
      pos: pos.clone() + Vector2((_rng.nextDouble() - 0.5) * 16, (_rng.nextDouble() - 0.5) * 16),
      vel: vel,
      scale: 0.5 + _rng.nextDouble() * 0.4,
      maxLife: 0.5 + _rng.nextDouble() * 0.3,
      color: Colors.white,
      rotation: _rng.nextDouble() * 2 * pi,
      rotSpeed: (_rng.nextDouble() - 0.5) * 3.0,
      isCloud: true,
    ));
  }

  void _spawnSparklerParticle(Vector2 pos) {
    final angle = _rng.nextDouble() * 2 * pi;
    final speed = 80.0 + _rng.nextDouble() * 140.0;
    final vel = Vector2(cos(angle), sin(angle)) * speed;

    final goldColors = [
      const Color(0xFFFFD700),
      const Color(0xFFFFEB3B),
      const Color(0xFFFFA000),
      Colors.white,
    ];

    _particles.add(_Particle(
      pos: pos.clone(),
      vel: vel,
      scale: 0.25 + _rng.nextDouble() * 0.25,
      maxLife: 0.45 + _rng.nextDouble() * 0.25,
      color: goldColors[_rng.nextInt(goldColors.length)],
      rotation: 0,
      rotSpeed: 0,
      isCloud: false,
    ));
  }

  double _directionToAngle(String dir) {
    switch (dir.toLowerCase()) {
      case 'up':
        return 0;
      case 'right':
        return pi / 2;
      case 'down':
        return pi;
      case 'left':
        return -pi / 2;
      default:
        return 0;
    }
  }

  Vector2 _directionToVector(String dir) {
    switch (dir.toLowerCase()) {
      case 'up':
        return Vector2(0, -1);
      case 'right':
        return Vector2(1, 0);
      case 'down':
        return Vector2(0, 1);
      case 'left':
        return Vector2(-1, 0);
      default:
        return Vector2.zero();
    }
  }
}

// ==================== INTERNAL HELPER CLASSES ====================

class _LaneAnimState {
  Lane lane;
  Vector2 currentOffset = Vector2.zero();
  double opacity = 1.0;

  // Exit Flight
  bool isExiting = false;
  bool isExited = false;
  double _exitTime = 0.0;
  Vector2 _exitDir = Vector2.zero();

  // Damped Recoil Bounce
  bool isBouncing = false;
  double _bounceTime = 0.0;
  Vector2 _bounceDir = Vector2.zero();

  // Red Shudder Flash
  double redFlashAlpha = 0.0;

  _LaneAnimState({required this.lane});

  void beginExitFlight(Vector2 dir) {
    isExiting = true;
    _exitDir = dir;
    _exitTime = 0.0;
  }

  void beginRecoil(Vector2 dir) {
    isBouncing = true;
    _bounceTime = 0.0;
    _bounceDir = dir;
    redFlashAlpha = 0.85;
  }

  void update(double dt) {
    if (isExiting) {
      _exitTime += dt;
      // Quadratic acceleration flight: x(t) = v0*t + 0.5*a*t^2
      final dist = (300.0 * _exitTime + 2200.0 * _exitTime * _exitTime);
      currentOffset = _exitDir * dist;
      opacity = (1.0 - _exitTime * 1.5).clamp(0.0, 1.0);
      if (_exitTime > 0.65) {
        isExited = true;
      }
    } else if (isBouncing) {
      _bounceTime += dt;
      // Damped harmonic oscillation: A * exp(-gamma*t) * sin(omega*t)
      const omega = 24.0;
      const gamma = 10.0;
      final amplitude = 18.0 * exp(-gamma * _bounceTime) * sin(omega * _bounceTime);
      currentOffset = _bounceDir * amplitude;

      redFlashAlpha = max(0.0, redFlashAlpha - dt * 2.8);

      if (_bounceTime > 0.45) {
        isBouncing = false;
        currentOffset = Vector2.zero();
        redFlashAlpha = 0.0;
      }
    }
  }
}

class _LockState {
  final PointPos pos;
  final PointPos keyPos;
  final int colorIdx;
  bool isUnlocked = false;
  bool isUnlocking = false;
  double unlockProgress = 0.0;

  _LockState({
    required this.pos,
    required this.keyPos,
    required this.colorIdx,
  });
}

class _FlyingKey {
  final Vector2 start;
  final Vector2 target;
  final int colorIdx;
  final VoidCallback onArrive;

  double progress = 0.0;
  final double duration = 0.55;
  bool isFinished = false;

  late final Vector2 _controlPoint;

  _FlyingKey({
    required this.start,
    required this.target,
    required this.colorIdx,
    required this.onArrive,
  }) {
    // Arch control point upwards
    final mid = (start + target) / 2.0;
    _controlPoint = mid + Vector2(0, -90);
  }

  void update(double dt) {
    progress += dt / duration;
    if (progress >= 1.0) {
      progress = 1.0;
      isFinished = true;
    }
  }

  Vector2 get currentPosition {
    final t = progress.clamp(0.0, 1.0);
    // Quadratic Bezier: (1-t)^2 * P0 + 2(1-t)t * P1 + t^2 * P2
    final it = 1.0 - t;
    return start * (it * it) + _controlPoint * (2.0 * it * t) + target * (t * t);
  }

  double get rotation => progress * pi * 1.5;
}

class _FlyingRocket {
  final Vector2 start;
  final Vector2 target;
  final VoidCallback onImpact;

  double progress = 0.0;
  final double duration = 0.42;
  bool isFinished = false;

  _FlyingRocket({
    required this.start,
    required this.target,
    required this.onImpact,
  });

  void update(double dt) {
    progress += dt / duration;
    if (progress >= 1.0) {
      progress = 1.0;
      isFinished = true;
    }
  }

  Vector2 get currentPosition {
    final t = progress.clamp(0.0, 1.0);
    // Quadratic ease-in acceleration towards target
    final eased = t * t;
    return start + (target - start) * eased;
  }

  Vector2 get direction {
    final d = target - start;
    if (d.length == 0) return Vector2(0, -1);
    return d.normalized();
  }

  double get angle {
    final d = target - start;
    return atan2(d.y, d.x);
  }
}

class _Particle {
  Vector2 pos;
  Vector2 vel;
  double scale;
  double maxLife;
  Color color;
  double rotation;
  double rotSpeed;
  bool isCloud;

  double life = 0.0;
  double alpha = 1.0;

  _Particle({
    required this.pos,
    required this.vel,
    required this.scale,
    required this.maxLife,
    required this.color,
    required this.rotation,
    required this.rotSpeed,
    required this.isCloud,
  });

  bool get isDead => life >= maxLife;

  void update(double dt) {
    pos += vel * dt;
    vel *= pow(0.88, dt * 60).toDouble();
    rotation += rotSpeed * dt;
    life += dt;
    alpha = (1.0 - (life / maxLife)).clamp(0.0, 1.0);
    if (isCloud) {
      scale += dt * 0.4;
    }
  }

  void render(Canvas canvas, ui.Image? cloudImg) {
    if (alpha <= 0.0) return;

    if (isCloud && cloudImg != null) {
      canvas.save();
      canvas.translate(pos.x, pos.y);
      canvas.rotate(rotation);
      final size = 48.0 * scale;
      final rect = Rect.fromCenter(center: Offset.zero, width: size, height: size);
      final p = Paint()
        ..color = Colors.white.withOpacity(alpha * 0.75)
        ..colorFilter = ColorFilter.mode(Colors.white.withOpacity(alpha * 0.75), BlendMode.modulate);
      canvas.drawImageRect(cloudImg, Rect.fromLTWH(0, 0, cloudImg.width.toDouble(), cloudImg.height.toDouble()), rect, p);
      canvas.restore();
    } else {
      // Sparkler star
      final p = Paint()..color = color.withOpacity(alpha);
      canvas.drawCircle(Offset(pos.x, pos.y), 4.0 * scale, p);
    }
  }
}

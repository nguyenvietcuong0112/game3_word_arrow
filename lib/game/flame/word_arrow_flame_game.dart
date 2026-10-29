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
  ui.Image? _handImg;
  ui.Image? _handGlowImg;

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
  final Map<String, TextPainter> _textPainterCache = {};
  final Random _rng = Random();
  double _hintPulseTime = 0.0;

  // Dragging & Word Preview Banner state
  Lane? _draggedLane;
  Vector2? _dragLastPos;
  int _tracedCellCount = 0;

  // Top Word Preview Banner state (persists briefly during release flash / collapse)
  Lane? _bannerLane;
  int _bannerTracedCount = 0;
  double _bannerScaleX = 0.0;
  bool _bannerClosing = false;
  double _bannerFlashTimer = 0.0;

  // Authentic Unity WordOutTutorialConfig & WordOutTutorialHand state
  static const double _handPressSeconds = 0.250;
  static const double _handCellSeconds = 0.220;
  static const double _handReleaseSeconds = 0.180;
  static const double _handLoopDelaySeconds = 0.150;
  static const double _handPressScale = 0.880;

  int _clearedWordsCount = 0;
  double _idleSeconds = 0.0;
  double _tutoHandCycleTime = 0.0;
  String? _tutoCurrentTargetId;

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

    try {
      _handImg = await images.load('icons/dl_general_hand_icon.png');
      _handGlowImg = await images.load('vfx/dl__tuto_hand_bottom_glow_icon.png');
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
    _draggedLane = null;
    _tracedCellCount = 0;
    _bannerLane = null;
    _bannerTracedCount = 0;
    _bannerScaleX = 0.0;
    _bannerClosing = false;
    _bannerFlashTimer = 0.0;
    _clearedWordsCount = 0;
    _idleSeconds = 0.0;
    _tutoHandCycleTime = 0.0;
    _tutoCurrentTargetId = null;

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

    const topBannerReserve = 42.0;
    final availW = size.x * 0.94;
    final availH = (size.y - topBannerReserve) * 0.94;

    final cellW = availW / gridW;
    final cellH = availH / gridH;

    _cellSize = min(cellW, cellH).clamp(36.0, 78.0);
    _tileSpacing = _cellSize * 0.08;
    _tileSize = _cellSize - _tileSpacing;
    _textPainterCache.clear();

    final boardW = _cellSize * gridW;
    final boardH = _cellSize * gridH;

    _origin = Vector2(
      (size.x - boardW) / 2.0,
      topBannerReserve + (size.y - topBannerReserve - boardH) / 2.0,
    );
  }

  TextPainter _getCachedTextPainter({
    required String text,
    required double fontSize,
    required Color color,
    double letterSpacing = 0.0,
    List<Shadow>? shadows,
    String shadowTag = '',
  }) {
    final key = '$text|${fontSize.toStringAsFixed(1)}|${color.toARGB32()}|$letterSpacing|$shadowTag';
    final cached = _textPainterCache[key];
    if (cached != null) return cached;

    if (_textPainterCache.length > 512) {
      _textPainterCache.clear();
    }

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Panteon',
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: letterSpacing,
          shadows: shadows,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    _textPainterCache[key] = tp;
    return tp;
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

    // Update lane animations (including smooth per-tile scale interpolation)
    final List<String> finishedExits = [];
    _laneAnims.forEach((id, anim) {
      final activeTraced = (_draggedLane?.id == id) ? _tracedCellCount : 0;
      anim.update(dt, activeTracedCount: activeTraced);
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
      if (r.hasLaunched) {
        final trailPos = r.currentPosition;
        _spawnSmokeParticle(trailPos, -r.direction * 30.0);
      }
      if (r.isFinished) {
        r.onImpact();
        _flyingRockets.removeAt(i);
      }
    }

    // Update tutorial hand timers
    _updateTutorialHand(dt);

    // Update particles
    for (int i = _particles.length - 1; i >= 0; i--) {
      final p = _particles[i];
      p.update(dt);
      if (p.isDead) {
        _particles.removeAt(i);
      }
    }

    // Update Top Word Preview Banner animation
    if (_bannerLane != null) {
      if (_bannerFlashTimer > 0.0) {
        _bannerFlashTimer = max(0.0, _bannerFlashTimer - dt);
        if (_bannerFlashTimer <= 0.0) {
          _bannerClosing = true;
        }
      }
      if (!_bannerClosing) {
        _bannerScaleX = min(1.0, _bannerScaleX + dt * 12.0);
      } else {
        _bannerScaleX = max(0.0, _bannerScaleX - dt * 12.0);
        if (_bannerScaleX <= 0.0) {
          _bannerLane = null;
          _bannerClosing = false;
        }
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
          final cellIdx = lane.cells.indexWhere((c) => c.pos == keyPos);
          final pixelPos = (anim != null && cellIdx != -1)
              ? anim.getCellPixelPos(cellIdx, _origin, _cellSize, _tileSpacing)
              : _gridToPixel(keyPos.x, keyPos.y);
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
      if (r.hasLaunched) {
        _drawFlyingRocket(canvas, r);
      }
    }

    // 7. Draw Particles (Smoke clouds, sparklers)
    for (final p in _particles) {
      p.render(canvas, _cloudImg);
    }

    // 7b. Draw Board Tutorial Hand (Level 1-2 Swipe Tutorial & Hammer Step 2)
    _drawTutorialHand(canvas);

    // 8. Draw Top Word Preview Banner (when tracing a word)
    _drawWordPreviewBanner(canvas);
  }

  void _drawWordPreviewBanner(Canvas canvas) {
    final lane = _bannerLane;
    if (lane == null || _bannerScaleX <= 0.01) return;

    final n = lane.length;
    if (n <= 0) return;

    // For Hidden Arrows (lane.hidden == true), don't spoil total word length before letters are traced!
    final int visibleSlots = lane.hidden
        ? min(n, max(1, _bannerTracedCount + (_bannerTracedCount < n ? 1 : 0)))
        : n;

    final slotW = (_tileSize * 0.56).clamp(22.0, 32.0);
    final padH = (_tileSize * 0.36).clamp(14.0, 22.0);
    final bannerW = visibleSlots * slotW + padH * 2;
    final bannerH = (_tileSize * 0.96).clamp(40.0, 52.0);

    final centerX = size.x / 2.0;
    final centerY = max(bannerH / 2 + 4.0, (_origin.y - 4.0) / 2.0);

    final isFlashingRed = _bannerFlashTimer > 0.0;
    final contentColor = isFlashingRed
        ? const Color(0xFFED3B3B)
        : const Color(0xFF261912);

    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.scale(_bannerScaleX, 1.0);

    final bannerRect = Rect.fromCenter(
      center: Offset.zero,
      width: bannerW,
      height: bannerH,
    );
    final radius = Radius.circular(bannerH * 0.28);

    // 1. Soft drop shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(bannerRect.shift(const Offset(0, 3.5)), radius),
      Paint()..color = const Color(0x2E1A0903),
    );

    // 2. 3D bottom bevel
    canvas.drawRRect(
      RRect.fromRectAndRadius(bannerRect, radius),
      Paint()..color = const Color(0xFFE5D2C7),
    );

    // 3. Cream top face
    final topFaceRect = Rect.fromLTRB(
      bannerRect.left,
      bannerRect.top,
      bannerRect.right,
      bannerRect.bottom - 4.5,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(topFaceRect, radius),
      Paint()..color = const Color(0xFFFFFDF9),
    );

    // 4. Draw letters and underscores (or '?' for unrevealed Hidden Arrow tail)
    final startX = -bannerW / 2.0 + padH;
    for (int i = 0; i < visibleSlots; i++) {
      final slotCenterX = startX + (i + 0.5) * slotW;
      if (i < _bannerTracedCount) {
        final letter = lane.cells[i].letter;
        final tp = _getCachedTextPainter(
          text: letter,
          fontSize: bannerH * 0.48,
          color: contentColor,
        );
        tp.paint(
          canvas,
          Offset(slotCenterX - tp.width / 2.0, -tp.height / 2.0 - 2.5),
        );
      } else if (lane.hidden) {
        final tp = _getCachedTextPainter(
          text: '?',
          fontSize: bannerH * 0.44,
          color: contentColor.withValues(alpha: 0.65),
        );
        tp.paint(
          canvas,
          Offset(slotCenterX - tp.width / 2.0, -tp.height / 2.0 - 2.5),
        );
      } else {
        // Bold bottom underscore bar for remaining letters
        final barW = slotW * 0.64;
        const barH = 3.4;
        final barRect = Rect.fromCenter(
          center: Offset(slotCenterX, bannerH * 0.16),
          width: barW,
          height: barH,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(barRect, const Radius.circular(2.0)),
          Paint()..color = contentColor,
        );
      }
    }

    canvas.restore();
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

    // Draw Crate Threshold number (cached TextPainter)
    final tp = _getCachedTextPainter(
      text: '${crate.threshold}',
      fontSize: _tileSize * 0.44,
      color: Colors.white,
      shadows: const [
        Shadow(offset: Offset(0, 1.5), color: Color(0xFF3B1E05), blurRadius: 2),
      ],
      shadowTag: 'crate',
    );
    tp.paint(canvas, Offset(pos.x + (_tileSize - tp.width) / 2, pos.y + (_tileSize - tp.height) / 2 - 2));
  }

  void _drawLaneShadows(Canvas canvas, _LaneAnimState anim) {
    final lane = anim.lane;

    // Arrow soft downward drop shadow:
    // Translate in screen space (downward +Y) FIRST, then rotate by arrow direction
    // so the triangular shadow matches the arrow shape without square corner artifacts!
    final aPos = anim.getArrowPixelPos(_origin, _cellSize, _tileSpacing);
    if (_arrowBase != null) {
      final arrowScale = 1.0 + (lane.id == controller.hintedLaneId ? 0.12 * sin(_hintPulseTime * 6.0) : 0.0);
      canvas.save();
      canvas.translate(
        aPos.x + _tileSize / 2,
        aPos.y + _tileSize / 2 + _tileSize * 0.065,
      );
      canvas.rotate(_directionToAngle(lane.direction));
      canvas.scale(arrowScale);

      final arrowShadowRect = Rect.fromCenter(
        center: Offset.zero,
        width: _tileSize,
        height: _tileSize,
      );
      final arrowShadowColor = const Color(0xFF1D0B03).withValues(alpha: 0.28 * anim.opacity);
      final p = Paint()
        ..color = arrowShadowColor
        ..colorFilter = ColorFilter.mode(arrowShadowColor, BlendMode.modulate);
      canvas.drawImageRect(
        _arrowBase!,
        Rect.fromLTWH(0, 0, _arrowBase!.width.toDouble(), _arrowBase!.height.toDouble()),
        arrowShadowRect,
        p,
      );
      canvas.restore();
    }

    if (_tileShadow == null) return;
    final shadowPaint = Paint()..color = Colors.white.withValues(alpha: 0.30 * anim.opacity);

    // Tile shadows (consistent soft downward drop shadow with smooth interpolated scale)
    for (int i = 0; i < lane.cells.length; i++) {
      final pos = anim.getCellPixelPos(i, _origin, _cellSize, _tileSpacing);
      final scale = anim.cellScales[i];
      final sSize = (_tileSize + 1.5) * scale;
      final sRect = Rect.fromCenter(
        center: Offset(
          pos.x + _tileSize / 2,
          pos.y + _tileSize / 2 + _tileSize * 0.06,
        ),
        width: sSize,
        height: sSize,
      );
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
    final style = GamePalette.getStyle(lane.color);
    final isHinted = lane.id == controller.hintedLaneId;
    final hintPulse = isHinted ? (sin(_hintPulseTime * 6.0) + 1.0) / 2.0 : 0.0;
    final isActivelyTraced = (_draggedLane?.id == lane.id && _tracedCellCount > 0);
    final isIncompleteFlash = anim.incompleteFlashAlpha > 0.0;

    final aPos = anim.getArrowPixelPos(_origin, _cellSize, _tileSpacing);

    // Glowing border outline when hinted
    if (isHinted) {
      final glowPaint = Paint()
        ..color = Color.lerp(const Color(0xFFFFD530), const Color(0xFF00E5FF), hintPulse)!.withValues(alpha: 0.85 * anim.opacity)
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
      for (int i = 0; i < lane.cells.length; i++) {
        final cPos = anim.getCellPixelPos(i, _origin, _cellSize, _tileSpacing);
        final cRect = Rect.fromLTWH(cPos.x - 1, cPos.y - 1, _tileSize + 2, _tileSize + 2);
        canvas.drawRRect(RRect.fromRectAndRadius(cRect, Radius.circular(_tileSize * 0.22)), glowPaint);
      }
    }

    // 1. Draw Arrow (Arrow keeps its normal theme color during incomplete flash)
    final arrowScale = 1.0 + (isHinted ? 0.12 * sin(_hintPulseTime * 6.0) : 0.0);
    final arrowTint = style.light;

    canvas.save();
    canvas.translate(aPos.x + _tileSize / 2, aPos.y + _tileSize / 2);
    canvas.rotate(_directionToAngle(lane.direction));
    canvas.scale(arrowScale);

    final arrowDrawRect = Rect.fromCenter(center: Offset.zero, width: _tileSize, height: _tileSize);
    if (_arrowBase != null) {
      final p = Paint()
        ..color = arrowTint.withValues(alpha: anim.opacity)
        ..colorFilter = ColorFilter.mode(arrowTint.withValues(alpha: anim.opacity), BlendMode.modulate);
      canvas.drawImageRect(
        _arrowBase!,
        Rect.fromLTWH(0, 0, _arrowBase!.width.toDouble(), _arrowBase!.height.toDouble()),
        arrowDrawRect,
        p,
      );
    }
    canvas.restore();

    // Draw remaining letter count (or '?' when lane.hidden == true, matching Unity HiddenLabel = '?')
    final bool showArrowCount = !(anim.isExiting && anim.exitTime >= 0.05);
    if (showArrowCount) {
      final int displayedCount = anim.isExiting
          ? 0
          : (isActivelyTraced
              ? max(0, lane.length - _tracedCellCount)
              : lane.length);

      final String arrowLabel = lane.hidden ? '?' : '$displayedCount';

      final atp = _getCachedTextPainter(
        text: arrowLabel,
        fontSize: _tileSize * 0.44,
        color: style.textColor.withValues(alpha: anim.opacity),
        shadows: [
          Shadow(
            offset: const Offset(0, 1),
            color: Colors.white.withValues(alpha: 0.3 * anim.opacity),
            blurRadius: 1,
          ),
        ],
        shadowTag: 'hi',
      );
      atp.paint(canvas, Offset(aPos.x + (_tileSize - atp.width) / 2, aPos.y + (_tileSize - atp.height) / 2 - 2));
    }

    // 2. Draw Letter Cells
    for (int i = 0; i < lane.cells.length; i++) {
      final cell = lane.cells[i];
      final pos = anim.getCellPixelPos(i, _origin, _cellSize, _tileSpacing);
      final isHead = (i == 0);
      final isHighlighted = anim.isExiting || (isActivelyTraced && i < _tracedCellCount);
      final isFlashingCell = isIncompleteFlash && i < anim.incompleteTracedCount;
      final tileScale = anim.cellScales[i];

      _drawLetterTile(
        canvas: canvas,
        pos: pos,
        letter: cell.letter,
        isHead: isHead,
        isHighlighted: isHighlighted,
        isIncompleteFlash: isFlashingCell,
        tileScale: tileScale,
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
    required bool isIncompleteFlash,
    required double tileScale,
    required bool isLocked,
    required LaneColorStyle style,
    required _LaneAnimState anim,
  }) {
    final drawSize = _tileSize * tileScale;
    final rect = Rect.fromCenter(
      center: Offset(pos.x + _tileSize / 2, pos.y + _tileSize / 2),
      width: drawSize,
      height: drawSize,
    );

    // Base tile
    if (_tileCream != null) {
      final Color baseRestingColor = isHead ? style.light : const Color(0xFFFFFDF9);
      Color tint = baseRestingColor;
      if (isIncompleteFlash) {
        // Flash bright red (#FF454C) and fade smoothly back to resting color (lane color for head, cream for body)
        tint = Color.lerp(baseRestingColor, const Color(0xFFFF454C), anim.incompleteFlashAlpha)!;
      } else if (isHighlighted || isHead) {
        tint = style.light; // Traced tiles and head tile match the lane's primary accent color
      }

      final p = Paint()
        ..color = tint.withValues(alpha: anim.opacity)
        ..colorFilter = ColorFilter.mode(tint.withValues(alpha: anim.opacity), BlendMode.modulate);

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
        ..color = const Color(0xFFFB7185).withValues(alpha: anim.redFlashAlpha * anim.opacity);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(drawSize * 0.22)),
        redPaint,
      );
    }

    // If locked, padlock will be drawn over it in lock pass, hide letter
    if (isLocked) return;

    // Draw Letter (cached TextPainter for base font size, scaled on canvas if tileScale != 1.0)
    final Color baseRestingTextColor = isHead ? style.textColor : const Color(0xFF261912);
    Color textColor;
    if (isIncompleteFlash) {
      textColor = Color.lerp(baseRestingTextColor, const Color(0xFFB92B27), anim.incompleteFlashAlpha)!
          .withValues(alpha: anim.opacity);
    } else if (isHead || isHighlighted) {
      textColor = style.textColor.withValues(alpha: anim.opacity);
    } else {
      textColor = const Color(0xFF261912).withValues(alpha: anim.opacity);
    }

    final hasHighlightShadow = isHead || isHighlighted;
    final tp = _getCachedTextPainter(
      text: letter,
      fontSize: _tileSize * 0.52,
      color: textColor,
      letterSpacing: -0.5,
      shadows: hasHighlightShadow
          ? [
              Shadow(
                offset: const Offset(0, 1),
                color: Colors.white.withValues(alpha: 0.3 * anim.opacity),
                blurRadius: 1,
              ),
            ]
          : null,
      shadowTag: hasHighlightShadow ? 'hi' : 'no',
    );

    if ((tileScale - 1.0).abs() > 0.002) {
      canvas.save();
      canvas.translate(pos.x + _tileSize / 2, pos.y + _tileSize / 2);
      canvas.scale(tileScale);
      tp.paint(
        canvas,
        Offset(-tp.width / 2, -tp.height / 2 - _tileSize * 0.06),
      );
      canvas.restore();
    } else {
      tp.paint(
        canvas,
        Offset(
          pos.x + (_tileSize - tp.width) / 2,
          pos.y + (_tileSize - tp.height) / 2 - _tileSize * 0.06,
        ),
      );
    }
  }

  void _drawLock(Canvas canvas, PointPos pos, _LockState lock) {
    final lane = controller.activeLanes.firstWhere(
      (l) => l.cells.any((c) => c.pos == pos),
      orElse: () => Lane(id: '', color: 0, arrow: const PointPos(x: -1, y: -1), direction: '', cells: []),
    );
    final anim = lane.id.isNotEmpty ? _laneAnims[lane.id] : null;
    final cellIdx = lane.cells.indexWhere((c) => c.pos == pos);
    final pPos = (anim != null && cellIdx != -1)
        ? anim.getCellPixelPos(cellIdx, _origin, _cellSize, _tileSpacing)
        : _gridToPixel(pos.x, pos.y);

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
    _dragLastPos = pos;
    final gridPos = _pixelToGrid(pos);

    // Booster: Hammer
    if (controller.isHammerActive) {
      _applyHammer(gridPos.x, gridPos.y);
      return;
    }

    // WordOutTutorialConfig: _restrictInputToHintLane = true while _clearedWordsCount < _lessonWordCount (1) on Level 1
    final Lane? restrictedLane = _getLevel1RestrictedLane();

    // Find clicked lane (tap/drag on arrow or any cell of the word)
    for (final lane in controller.activeLanes) {
      final bool hitArrow = lane.arrow.x == gridPos.x && lane.arrow.y == gridPos.y;
      final bool hitCell = lane.cells.any((c) => c.x == gridPos.x && c.y == gridPos.y);
      if (hitArrow || hitCell) {
        if (restrictedLane != null && lane.id != restrictedLane.id) {
          return;
        }
        _startLaneDrag(lane, 1);
        return;
      }
    }
  }

  void _startLaneDrag(Lane lane, int initialCount) {
    _draggedLane = lane;
    _tracedCellCount = initialCount.clamp(1, lane.length);
    _bannerLane = lane;
    _bannerTracedCount = _tracedCellCount;
    _bannerClosing = false;
    _bannerFlashTimer = 0.0;
    _audio.playTileSelect();
  }

  /// Sets an active word trace state for previewing / testing the Top Word Preview Banner.
  void debugSetWordTrace(Lane lane, int tracedCount) {
    _draggedLane = lane;
    _tracedCellCount = tracedCount.clamp(1, lane.length);
    _bannerLane = lane;
    _bannerTracedCount = _tracedCellCount;
    _bannerScaleX = 1.0;
    _bannerClosing = false;
    _bannerFlashTimer = 0.0;
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (_draggedLane == null || controller.status != GameStatus.playing) return;
    final pos = Vector2(info.eventPosition.widget.x, info.eventPosition.widget.y);
    final prevPos = _dragLastPos ?? pos;
    _dragLastPos = pos;

    final lane = _draggedLane!;
    final gridPos = _pixelToGrid(pos);

    // Sequentially trace along the word's exact cell path (supports straight, L-shaped, and U-shaped words)
    while (_tracedCellCount < lane.cells.length) {
      final nextIdx = _tracedCellCount;
      final nextCell = lane.cells[nextIdx];
      final nextCenter = _gridToPixel(nextCell.x, nextCell.y) +
          Vector2(_tileSize / 2, _tileSize / 2);

      final dist = _distToSegment(nextCenter, prevPos, pos);

      bool reachedByStep = false;
      if (nextIdx > 0) {
        final prevCell = lane.cells[nextIdx - 1];
        final prevCenter = _gridToPixel(prevCell.x, prevCell.y) +
            Vector2(_tileSize / 2, _tileSize / 2);
        final stepVec = nextCenter - prevCenter;
        final stepLenSq = stepVec.length2;
        if (stepLenSq > 1.0) {
          final tStep = (pos - prevCenter).dot(stepVec) / stepLenSq;
          final perpDist = ((pos - prevCenter) - stepVec * tStep.clamp(0.0, 1.0)).length;
          if (tStep >= 0.52 && perpDist < _cellSize * 0.85) {
            reachedByStep = true;
          }
        }
      }

      if ((gridPos.x == nextCell.x && gridPos.y == nextCell.y) ||
          dist < _cellSize * 0.62 ||
          reachedByStep) {
        _tracedCellCount++;
        _bannerTracedCount = _tracedCellCount;
        _audio.playTileSelect();
      } else {
        break;
      }
    }
  }

  double _distToSegment(Vector2 p, Vector2 a, Vector2 b) {
    final ab = b - a;
    final lenSq = ab.length2;
    if (lenSq == 0.0) return (p - a).length;
    final t = ((p - a).dot(ab) / lenSq).clamp(0.0, 1.0);
    final proj = a + ab * t;
    return (p - proj).length;
  }

  @override
  void onPanEnd(DragEndInfo info) {
    if (_draggedLane != null) {
      final lane = _draggedLane!;

      if (_tracedCellCount >= lane.length) {
        // User traced all letters of the word -> commit lane!
        _bannerClosing = true;
        _commitLane(lane);
      } else if (_tracedCellCount >= 1) {
        // Incomplete word trace released -> flash coral red briefly before collapsing banner
        final anim = _laneAnims[lane.id];
        anim?.beginIncompleteFlash(_tracedCellCount);
        _bannerFlashTimer = 0.35;
      } else {
        _bannerClosing = true;
      }

      _resetDrag();
    }
  }

  @override
  void onPanCancel() {
    _bannerClosing = true;
    _resetDrag();
  }

  void _resetDrag() {
    _draggedLane = null;
    _dragLastPos = null;
    _tracedCellCount = 0;
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
    _clearedWordsCount++;
    _idleSeconds = 0.0;
    _tutoHandCycleTime = 0.0;

    final dirVec = _directionToVector(lane.direction);
    anim.beginExitFlight(dirVec);
    _audio.playLaneClear();

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

    // Damage crates immediately when clear wave starts (matches Unity f_084)
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
  }

  void _executeBlockedRecoil(_LaneAnimState anim, {bool isLockedDirectly = false}) {
    final lane = anim.lane;
    final dirVec = _directionToVector(lane.direction);

    anim.beginRecoil(dirVec);
    // WordOutTutorialConfig: _unlimitedLives = true on Level 1 tutorial
    if (controller.levelNumber != 1) {
      controller.stars = max(0, controller.stars - 1);
    }
    _audio.playBlockedBounce();

    if (controller.levelNumber != 1 && controller.stars <= 0) {
      controller.status = GameStatus.lost;
      _audio.playLose();
      onLose();
    }

    controller.notifyBoardChanged();
  }

  void _applyHammer(int gx, int gy) {
    // 1. Crate check
    final crateIdx = controller.activeCrates.indexWhere((c) => c.x == gx && c.y == gy);
    if (crateIdx != -1) {
      controller.isHammerActive = false;
      controller.isHammerTutorialStep = false;
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
      controller.onHammerConsumedOnBoard?.call();
      controller.notifyBoardChanged();
      return;
    }

    // 2. Active Lane check (tapped arrow or any letter tile in lane)
    for (final lane in controller.activeLanes) {
      if ((lane.arrow.x == gx && lane.arrow.y == gy) || lane.cells.any((c) => c.x == gx && c.y == gy)) {
        final anim = _laneAnims[lane.id];
        if (anim != null && !anim.isExiting) {
          controller.isHammerActive = false;
          controller.isHammerTutorialStep = false;
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
          controller.onHammerConsumedOnBoard?.call();
          _executeExitFlight(anim);
          controller.notifyBoardChanged();
          return;
        }
      }
    }
  }

  /// Authentic Unity Firework Booster (DefaultFireworkWordCount = 5,
  /// DefaultRocketTravelSeconds = 0.60, DefaultFireworkStaggerSeconds = 0.05)
  bool triggerRocketBooster() {
    if (controller.status != GameStatus.playing) return false;

    const int maxTargets = 5;
    final List<Crate> targetCrates = [];
    final List<_LaneAnimState> targetLaneAnims = [];
    final Set<String> chosenLaneIds = {};

    // 1. Prioritize active crates (up to 2 crates first so words also fly!)
    for (final crate in controller.activeCrates) {
      if (crate.threshold > 0 && targetCrates.length < 2) {
        targetCrates.add(crate);
      }
    }

    // 2. Prioritize clear unlocked lanes
    for (final lane in controller.activeLanes) {
      if (targetCrates.length + targetLaneAnims.length >= maxTargets) break;
      final anim = _laneAnims[lane.id];
      if (anim != null &&
          !anim.isExiting &&
          !lane.isLocked &&
          controller.isPathClear(lane)) {
        targetLaneAnims.add(anim);
        chosenLaneIds.add(lane.id);
      }
    }

    // 3. Fill remaining slots up to 5 with other active non-exiting unlocked lanes (or any lane)
    for (final lane in controller.activeLanes) {
      if (targetCrates.length + targetLaneAnims.length >= maxTargets) break;
      if (chosenLaneIds.contains(lane.id) || lane.isLocked) continue;
      final anim = _laneAnims[lane.id];
      if (anim != null && !anim.isExiting) {
        targetLaneAnims.add(anim);
        chosenLaneIds.add(lane.id);
      }
    }
    for (final lane in controller.activeLanes) {
      if (targetCrates.length + targetLaneAnims.length >= maxTargets) break;
      if (chosenLaneIds.contains(lane.id)) continue;
      final anim = _laneAnims[lane.id];
      if (anim != null && !anim.isExiting) {
        targetLaneAnims.add(anim);
        chosenLaneIds.add(lane.id);
      }
    }

    final int totalCount = targetCrates.length + targetLaneAnims.length;
    if (totalCount == 0) return false;

    int launchIndex = 0;

    for (final crate in targetCrates) {
      final targetPos =
          _gridToPixel(crate.x, crate.y) + Vector2(_tileSize / 2, _tileSize / 2);
      final spreadX = (launchIndex - (totalCount - 1) / 2.0) * 22.0;
      final startPos = Vector2(size.x * 0.5 + spreadX, size.y + 60);

      _flyingRockets.add(_FlyingRocket(
        start: startPos,
        target: targetPos,
        delay: launchIndex * 0.055,
        duration: 0.52,
        onImpact: () {
          for (int i = 0; i < 18; i++) {
            _spawnSmokeParticle(targetPos, Vector2.zero());
          }
          for (int i = 0; i < 14; i++) {
            _spawnSparklerParticle(targetPos);
          }
          controller.activeCrates.remove(crate);
          _audio.playCrateHit();
          controller.notifyBoardChanged();
        },
      ));
      launchIndex++;
    }

    for (final anim in targetLaneAnims) {
      final targetLane = anim.lane;
      final aPos = _gridToPixel(targetLane.arrow.x, targetLane.arrow.y) +
          Vector2(_tileSize / 2, _tileSize / 2);
      final spreadX = (launchIndex - (totalCount - 1) / 2.0) * 22.0;
      final startPos = Vector2(size.x * 0.5 + spreadX, size.y + 60);

      _flyingRockets.add(_FlyingRocket(
        start: startPos,
        target: aPos,
        delay: launchIndex * 0.055,
        duration: 0.54,
        onImpact: () {
          if (!anim.isExiting && !anim.isExited) {
            for (int i = 0; i < 16; i++) {
              _spawnSparklerParticle(aPos);
            }
            for (int i = 0; i < 10; i++) {
              _spawnSmokeParticle(aPos, Vector2.zero());
            }
            _executeExitFlight(anim);
          }
        },
      ));
      launchIndex++;
    }

    _audio.playSwipe();
    return true;
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

  // ==================== BOARD TUTORIALS (LEVEL 1-2 & HAMMER STEP 2) ====================

  Lane? _getLevel1RestrictedLane() {
    if (controller.levelNumber != 1 || _clearedWordsCount >= 1) return null;
    if (controller.level.lanes.isEmpty) return null;
    final hintLaneId = controller.level.lanes.first.id;
    final anim = _laneAnims[hintLaneId];
    if (anim != null && !anim.isExiting && !anim.isExited) {
      return anim.lane;
    }
    return null;
  }

  Lane? _selectSwipeTutorialLane() {
    if (controller.status != GameStatus.playing || controller.isHammerActive) {
      return null;
    }
    final lvl = controller.levelNumber;
    if (lvl != 1 && lvl != 2) return null;

    // On Level 1 first word: strictly guide Lane 0 ('FIND') with 0s idle delay
    final restricted = _getLevel1RestrictedLane();
    if (restricted != null) {
      return restricted;
    }

    // Subsequent words on Level 1 (after 0.8s idle) or Level 2 (after 1.4s idle)
    final double requiredIdle = (lvl == 1) ? 0.80 : 1.40;
    if (_idleSeconds < requiredIdle) return null;

    for (final lane in controller.activeLanes) {
      final anim = _laneAnims[lane.id];
      if (anim != null &&
          !anim.isExiting &&
          !anim.isExited &&
          controller.isPathClear(lane)) {
        return lane;
      }
    }
    return null;
  }

  void _updateTutorialHand(double dt) {
    if (_draggedLane != null || controller.status != GameStatus.playing) {
      _idleSeconds = 0.0;
      _tutoHandCycleTime = 0.0;
      return;
    }

    // Hammer Tutorial Step 2 (WaitForHammerArmedStateStep)
    if (controller.isHammerActive && controller.isHammerTutorialStep) {
      if (_tutoCurrentTargetId != '__hammer__') {
        _tutoCurrentTargetId = '__hammer__';
        _tutoHandCycleTime = 0.0;
      } else {
        _tutoHandCycleTime += dt;
      }
      return;
    }

    _idleSeconds += dt;
    final targetLane = _selectSwipeTutorialLane();
    if (targetLane == null) {
      _tutoCurrentTargetId = null;
      _tutoHandCycleTime = 0.0;
      return;
    }

    if (_tutoCurrentTargetId != targetLane.id) {
      _tutoCurrentTargetId = targetLane.id;
      _tutoHandCycleTime = 0.0;
    } else {
      _tutoHandCycleTime += dt;
    }
  }

  Vector2 _cellCenter(LetterCell cell) {
    return _gridToPixel(cell.x, cell.y) + Vector2(_tileSize / 2, _tileSize / 2);
  }

  void _drawTutorialHand(Canvas canvas) {
    if (_handImg == null ||
        _draggedLane != null ||
        controller.status != GameStatus.playing) {
      return;
    }

    // 1. Hammer Tutorial Step 2: Tap any word tile / crate on board
    if (controller.isHammerActive && controller.isHammerTutorialStep) {
      Vector2? targetPos;
      if (controller.activeCrates.isNotEmpty) {
        final c = controller.activeCrates.first;
        targetPos = _gridToPixel(c.x, c.y) + Vector2(_tileSize / 2, _tileSize / 2);
      } else {
        for (final lane in controller.activeLanes) {
          final anim = _laneAnims[lane.id];
          if (anim != null && !anim.isExiting && lane.cells.isNotEmpty) {
            targetPos = _cellCenter(lane.cells.first);
            break;
          }
        }
      }
      if (targetPos == null) return;

      const double tapCycle = 0.80;
      final double t = _tutoHandCycleTime % tapCycle;
      final double pressPhase = sin((t / tapCycle) * pi);
      final double handScale = 1.0 - (1.0 - _handPressScale) * pressPhase;
      final double hoverOffset = (1.0 - pressPhase) * 9.0;

      _paintHandSprite(
        canvas: canvas,
        fingertipPos: targetPos + Vector2(hoverOffset, -hoverOffset),
        glowCenter: targetPos,
        scale: handScale,
        alpha: 1.0,
        glowAlpha: 0.35 + 0.55 * pressPhase,
      );
      return;
    }

    // 2. Early-Level Swipe Tutorial (WordOutTutorialHand)
    final targetLane = _selectSwipeTutorialLane();
    if (targetLane == null || targetLane.cells.isEmpty) return;

    final int n = targetLane.cells.length;
    final double pressEnd = _handPressSeconds;
    final double moveDuration = max(0, n - 1) * _handCellSeconds;
    final double moveEnd = pressEnd + moveDuration;
    final double releaseEnd = moveEnd + _handReleaseSeconds;
    final double totalCycle = releaseEnd + _handLoopDelaySeconds;

    final double t = _tutoHandCycleTime % totalCycle;
    if (t >= releaseEnd) return; // Loop pause window

    Vector2 fingertipPos;
    double scale = 1.0;
    double alpha = 1.0;
    double glowAlpha = 0.0;
    double tracedSegmentProgress = 0.0;

    if (t < pressEnd) {
      final u = Curves.easeOutCubic.transform((t / pressEnd).clamp(0.0, 1.0));
      fingertipPos = _cellCenter(targetLane.cells.first);
      scale = 1.06 - (1.06 - _handPressScale) * u;
      alpha = u;
      glowAlpha = 0.85 * u;
      tracedSegmentProgress = 0.0;
    } else if (t < moveEnd && n > 1) {
      final segFloat = (t - pressEnd) / _handCellSeconds;
      final idx = segFloat.floor().clamp(0, n - 2);
      final frac = (segFloat - idx).clamp(0.0, 1.0);
      final pA = _cellCenter(targetLane.cells[idx]);
      final pB = _cellCenter(targetLane.cells[idx + 1]);
      fingertipPos = pA + (pB - pA) * frac;
      scale = _handPressScale;
      alpha = 1.0;
      glowAlpha = 0.88;
      tracedSegmentProgress = segFloat;
    } else {
      final u = Curves.easeInQuad
          .transform(((t - moveEnd) / _handReleaseSeconds).clamp(0.0, 1.0));
      fingertipPos = _cellCenter(targetLane.cells.last);
      scale = _handPressScale + (1.05 - _handPressScale) * u;
      alpha = 1.0 - u;
      glowAlpha = 0.85 * (1.0 - u);
      tracedSegmentProgress = (n - 1).toDouble();
    }

    // Draw subtle luminous swipe guide line along the cells traced so far
    if (tracedSegmentProgress > 0.02 && n > 1) {
      final trailPath = Path();
      final p0 = _cellCenter(targetLane.cells[0]);
      trailPath.moveTo(p0.x, p0.y);
      final fullSegments = tracedSegmentProgress.floor().clamp(0, n - 1);
      for (int i = 1; i <= fullSegments; i++) {
        final piPos = _cellCenter(targetLane.cells[i]);
        trailPath.lineTo(piPos.x, piPos.y);
      }
      trailPath.lineTo(fingertipPos.x, fingertipPos.y);

      canvas.drawPath(
        trailPath,
        Paint()
          ..color = const Color(0xFFFFE066).withValues(alpha: 0.42 * alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = _tileSize * 0.24
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    _paintHandSprite(
      canvas: canvas,
      fingertipPos: fingertipPos,
      glowCenter: fingertipPos,
      scale: scale,
      alpha: alpha,
      glowAlpha: glowAlpha,
    );
  }

  void _paintHandSprite({
    required Canvas canvas,
    required Vector2 fingertipPos,
    required Vector2 glowCenter,
    required double scale,
    required double alpha,
    required double glowAlpha,
  }) {
    if (_handGlowImg != null && glowAlpha > 0.01) {
      final glowSize = _tileSize * 1.35;
      final gRect = Rect.fromCenter(
        center: Offset(glowCenter.x, glowCenter.y),
        width: glowSize,
        height: glowSize,
      );
      canvas.drawImageRect(
        _handGlowImg!,
        Rect.fromLTWH(
          0,
          0,
          _handGlowImg!.width.toDouble(),
          _handGlowImg!.height.toDouble(),
        ),
        gRect,
        Paint()..color = Colors.white.withValues(alpha: glowAlpha.clamp(0.0, 1.0)),
      );
    }

    if (_handImg == null || alpha <= 0.01) return;

    final double handW = (_tileSize * 1.65).clamp(72.0, 108.0);
    final double handH = handW * (188.0 / 256.0);
    // Exact index fingertip anchor of dl_general_hand_icon.png (256x188): (0.12 * W, 0.86 * H)
    final double tipX = handW * 0.12;
    final double tipY = handH * 0.86;

    canvas.save();
    canvas.translate(fingertipPos.x, fingertipPos.y);
    canvas.scale(scale);

    // Subtle soft shadow under hand
    canvas.drawImageRect(
      _handImg!,
      Rect.fromLTWH(0, 0, _handImg!.width.toDouble(), _handImg!.height.toDouble()),
      Rect.fromLTWH(-tipX + 2, -tipY + 5, handW, handH),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25 * alpha)
        ..colorFilter = ColorFilter.mode(
          Colors.black.withValues(alpha: 0.25 * alpha),
          BlendMode.srcIn,
        ),
    );

    canvas.drawImageRect(
      _handImg!,
      Rect.fromLTWH(0, 0, _handImg!.width.toDouble(), _handImg!.height.toDouble()),
      Rect.fromLTWH(-tipX, -tipY, handW, handH),
      Paint()..color = Colors.white.withValues(alpha: alpha.clamp(0.0, 1.0)),
    );
    canvas.restore();
  }
}

// ==================== INTERNAL HELPER CLASSES ====================

class _LaneAnimState {
  Lane lane;
  Vector2 currentOffset = Vector2.zero();
  double opacity = 1.0;
  final List<double> cellScales;

  // Exit Flight (Wave Ripple + Path-Following Snake Train)
  bool isExiting = false;
  bool isExited = false;
  double _exitTime = 0.0;
  double _trackDistance = 0.0;
  Vector2 _exitDir = Vector2.zero();

  double get exitTime => _exitTime;

  // Damped Recoil Bounce
  bool isBouncing = false;
  double _bounceTime = 0.0;
  Vector2 _bounceDir = Vector2.zero();

  // Red Shudder Flash (blocked path)
  double redFlashAlpha = 0.0;

  // Incomplete Word Release Flash
  double incompleteFlashAlpha = 0.0;
  int incompleteTracedCount = 0;

  _LaneAnimState({required this.lane})
      : cellScales = List<double>.filled(lane.cells.length, 1.0);

  void beginExitFlight(Vector2 dir) {
    isExiting = true;
    _exitDir = dir;
    _exitTime = 0.0;
    _trackDistance = 0.0;
    incompleteFlashAlpha = 0.0;
    opacity = 1.0;
  }

  void beginRecoil(Vector2 dir) {
    isBouncing = true;
    _bounceTime = 0.0;
    _bounceDir = dir;
    redFlashAlpha = 0.85;
  }

  void beginIncompleteFlash(int tracedCount) {
    incompleteTracedCount = tracedCount;
    incompleteFlashAlpha = 1.0;
  }

  /// Scale compression wave (1.0 -> 0.68 -> 1.0) rippling from head (i=0) to tail (i=n-1)
  double getExitCellScale(int index) {
    if (!isExiting) return 1.0;
    final tPeak = 0.045 + index * 0.036;
    const halfW = 0.095;
    double waveScale = 1.0;
    final diff = (_exitTime - tPeak).abs();
    if (diff < halfW) {
      final u = diff / halfW;
      waveScale = 1.0 - 0.32 * 0.5 * (1.0 + cos(u * pi));
    }
    if (index == lane.cells.length - 1 && _exitTime < 0.06) {
      waveScale = min(waveScale, 0.78 + 0.22 * (_exitTime / 0.06));
    }
    return waveScale;
  }

  Vector2 _gridWaypoint(int k) {
    if (k <= 0) {
      return Vector2(lane.arrow.x.toDouble(), lane.arrow.y.toDouble());
    }
    final idx = (k - 1).clamp(0, lane.cells.length - 1);
    final c = lane.cells[idx];
    return Vector2(c.x.toDouble(), c.y.toDouble());
  }

  /// Continuous grid position along the lane's waypoint track:
  /// s = 0 is arrow, s = 1 is cells[0], ..., s = n is cells[n-1], s < 0 is outward along _exitDir
  Vector2 _gridPosAlongTrack(double s) {
    final w0 = _gridWaypoint(0);
    if (s <= 0.0) {
      return w0 + _exitDir * (-s);
    }
    final n = lane.cells.length;
    if (s >= n) {
      return _gridWaypoint(n);
    }
    final k = s.floor();
    final frac = s - k;
    final a = _gridWaypoint(k);
    final b = _gridWaypoint(k + 1);
    return a + (b - a) * frac;
  }

  Vector2 getArrowPixelPos(Vector2 origin, double cellSize, double tileSpacing) {
    if (isExiting) {
      final gPos = _gridPosAlongTrack(-_trackDistance);
      return Vector2(
        origin.x + gPos.x * cellSize + tileSpacing / 2.0,
        origin.y + gPos.y * cellSize + tileSpacing / 2.0,
      );
    }
    return Vector2(
      origin.x + lane.arrow.x * cellSize + tileSpacing / 2.0,
      origin.y + lane.arrow.y * cellSize + tileSpacing / 2.0,
    ) + currentOffset;
  }

  Vector2 getCellPixelPos(int index, Vector2 origin, double cellSize, double tileSpacing) {
    if (isExiting) {
      final gPos = _gridPosAlongTrack((index + 1) - _trackDistance);
      return Vector2(
        origin.x + gPos.x * cellSize + tileSpacing / 2.0,
        origin.y + gPos.y * cellSize + tileSpacing / 2.0,
      );
    }
    final c = lane.cells[index];
    return Vector2(
      origin.x + c.x * cellSize + tileSpacing / 2.0,
      origin.y + c.y * cellSize + tileSpacing / 2.0,
    ) + currentOffset;
  }

  void update(double dt, {int activeTracedCount = 0}) {
    if (incompleteFlashAlpha > 0.0) {
      incompleteFlashAlpha = max(0.0, incompleteFlashAlpha - dt * 2.8);
    }
    if (isExiting) {
      _exitTime += dt;
      // Smooth continuous acceleration starting right as the head wave peaks (~0.06s)
      if (_exitTime > 0.06) {
        final tm = _exitTime - 0.06;
        _trackDistance = 3.2 * tm + 38.0 * tm * tm;
      } else {
        _trackDistance = 0.0;
      }
      opacity = 1.0;
      if (_trackDistance >= lane.cells.length + 9.0) {
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

    // Smooth per-tile scale interpolation (eliminates 1-frame popping when pressing/releasing tiles)
    final lerpFactor = min(1.0, dt * 24.0);
    for (int i = 0; i < cellScales.length; i++) {
      double targetScale = 1.0;
      if (isExiting) {
        targetScale = getExitCellScale(i);
        cellScales[i] = targetScale;
      } else {
        if (activeTracedCount > 0 && i == activeTracedCount - 1) {
          targetScale = 0.78;
        }
        cellScales[i] += (targetScale - cellScales[i]) * lerpFactor;
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
  final double duration;
  double delay;

  double progress = 0.0;
  bool isFinished = false;

  _FlyingRocket({
    required this.start,
    required this.target,
    required this.onImpact,
    this.delay = 0.0,
    this.duration = 0.52,
  });

  bool get hasLaunched => delay <= 0.0;

  void update(double dt) {
    if (delay > 0.0) {
      delay -= dt;
      if (delay > 0.0) return;
      dt = -delay;
      delay = 0.0;
    }
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

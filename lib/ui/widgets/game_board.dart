import 'dart:math';
import 'package:flutter/material.dart';
import '../../game/board_controller.dart';
import '../../models/game_palette.dart';
import '../../models/level_model.dart';
import 'arrow_widget.dart';
import 'crate_widget.dart';
import 'drag_trail_painter.dart';
import 'tile_widget.dart';

class GameBoard extends StatelessWidget {
  final BoardController controller;

  const GameBoard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final gridW = controller.level.grid.width;
            final gridH = controller.level.grid.height;

            // Calculate cellSize to fit available space
            final double cellW = constraints.maxWidth / gridW;
            final double cellH = constraints.maxHeight / gridH;
            final double cellSize = min(cellW, cellH).clamp(36.0, 72.0);

            final double boardWidth = cellSize * gridW;
            final double boardHeight = cellSize * gridH;
            final double tileSpacing = cellSize * 0.08;
            final double tileSize = cellSize - tileSpacing;

            return Center(
              child: SizedBox(
                width: boardWidth,
                height: boardHeight,
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (e) {
                    controller.onTouchDown(e.localPosition, cellSize);
                  },
                  onPointerMove: (e) {
                    controller.onTouchMove(e.localPosition, cellSize);
                  },
                  onPointerUp: (_) => controller.onTouchUp(),
                  onPointerCancel: (_) => controller.onTouchUp(),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Active Crates
                      for (final crate in controller.activeCrates)
                        Positioned(
                          left: crate.x * cellSize + tileSpacing / 2,
                          top: crate.y * cellSize + tileSpacing / 2,
                          child: CrateWidget(
                            threshold: crate.threshold,
                            size: tileSize,
                          ),
                        ),

                      // Active Lanes
                      for (final lane in controller.activeLanes)
                        ..._buildLaneWidgets(
                          lane,
                          cellSize,
                          tileSize,
                          tileSpacing,
                        ),

                      // Drag Trail Overlay
                      if (controller.dragPathPoints.isNotEmpty && controller.draggedLane != null)
                        IgnorePointer(
                          child: CustomPaint(
                            size: Size(boardWidth, boardHeight),
                            painter: DragTrailPainter(
                              points: controller.dragPathPoints,
                              trailColor: GamePalette.getStyle(controller.draggedLane!.color).primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildLaneWidgets(
    Lane lane,
    double cellSize,
    double tileSize,
    double tileSpacing,
  ) {
    final isExiting = controller.exitingLaneProgress.containsKey(lane.id);
    final exitProgress = controller.exitingLaneProgress[lane.id] ?? 0.0;
    final exitDir = controller.exitingLaneDirection[lane.id] ?? Offset.zero;
    final isBouncing = controller.bouncingLaneIds.contains(lane.id);
    final isHinted = controller.hintedLaneId == lane.id;

    Offset laneOffset = Offset.zero;
    if (isExiting) {
      laneOffset = exitDir * (exitProgress * 900.0);
    } else if (isBouncing) {
      // Bounce nudge towards arrow direction
      Offset bounceDir = Offset.zero;
      switch (lane.direction.toLowerCase()) {
        case 'up':
          bounceDir = const Offset(0, -14);
          break;
        case 'down':
          bounceDir = const Offset(0, 14);
          break;
        case 'left':
          bounceDir = const Offset(-14, 0);
          break;
        case 'right':
          bounceDir = const Offset(14, 0);
          break;
      }
      laneOffset = bounceDir;
    }

    final double opacity = (1.0 - exitProgress * 0.7).clamp(0.0, 1.0);
    final isCurrentDragged = controller.draggedLane?.id == lane.id;

    final widgets = <Widget>[];

    // Arrow tile
    final arrowLeft = lane.arrow.x * cellSize + tileSpacing / 2 + laneOffset.dx;
    final arrowTop = lane.arrow.y * cellSize + tileSpacing / 2 + laneOffset.dy;

    widgets.add(
      Positioned(
        left: arrowLeft,
        top: arrowTop,
        child: Opacity(
          opacity: opacity,
          child: _wrapHint(
            isHinted: isHinted,
            child: ArrowWidget(
              direction: lane.direction,
              length: lane.length,
              colorId: lane.color,
              size: tileSize,
              isHighlighted: isCurrentDragged && controller.hasArrowHighlighted,
            ),
          ),
        ),
      ),
    );

    // Letter Cells
    for (int i = 0; i < lane.cells.length; i++) {
      final cell = lane.cells[i];
      final cellLeft = cell.x * cellSize + tileSpacing / 2 + laneOffset.dx;
      final cellTop = cell.y * cellSize + tileSpacing / 2 + laneOffset.dy;
      final isHighlighted = isCurrentDragged && controller.highlightedCellIndices.contains(i);

      widgets.add(
        Positioned(
          left: cellLeft,
          top: cellTop,
          child: Opacity(
            opacity: opacity,
            child: _wrapHint(
              isHinted: isHinted,
              child: TileWidget(
                letter: cell.letter,
                isFirstLetter: i == 0,
                colorId: lane.color,
                isHighlighted: isHighlighted,
                size: tileSize,
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _wrapHint({required bool isHinted, required Widget child}) {
    if (!isHinted) return child;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.amberAccent.withOpacity(0.8),
            blurRadius: 16,
            spreadRadius: 4,
          ),
        ],
      ),
      child: child,
    );
  }
}

class LevelModel {
  final int levelIndex;
  final String id;
  final int difficulty;
  final int revision;
  final String name;
  final LevelGrid grid;
  final List<Lane> lanes;
  final List<Crate> crates;
  final LevelSettings settings;

  LevelModel({
    required this.levelIndex,
    required this.id,
    required this.difficulty,
    required this.revision,
    required this.name,
    required this.grid,
    required this.lanes,
    required this.crates,
    required this.settings,
  });

  factory LevelModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return LevelModel(
      levelIndex: json['levelIndex'] ?? 0,
      id: json['id'] ?? '',
      difficulty: json['difficulty'] ?? 1,
      revision: json['revision'] ?? 0,
      name: json['name'] ?? '',
      grid: LevelGrid.fromJson(data['grid'] as Map<String, dynamic>),
      lanes: (data['lanes'] as List<dynamic>? ?? [])
          .map((e) => Lane.fromJson(e as Map<String, dynamic>))
          .toList(),
      crates: (data['crates'] as List<dynamic>? ?? [])
          .map((e) => Crate.fromJson(e as Map<String, dynamic>))
          .toList(),
      settings: LevelSettings.fromJson(data['settings'] as Map<String, dynamic>),
    );
  }
}

class LevelGrid {
  final int width;
  final int height;

  LevelGrid({required this.width, required this.height});

  factory LevelGrid.fromJson(Map<String, dynamic> json) {
    return LevelGrid(
      width: json['width'] ?? 0,
      height: json['height'] ?? 0,
    );
  }
}

class PointPos {
  final int x;
  final int y;

  const PointPos({required this.x, required this.y});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PointPos && runtimeType == other.runtimeType && x == other.x && y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  factory PointPos.fromJson(Map<String, dynamic> json) {
    return PointPos(
      x: json['x'] ?? 0,
      y: json['y'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {'x': x, 'y': y};
}

class LetterCell {
  final int x;
  final int y;
  final String letter;

  const LetterCell({required this.x, required this.y, required this.letter});

  PointPos get pos => PointPos(x: x, y: y);

  factory LetterCell.fromJson(Map<String, dynamic> json) {
    return LetterCell(
      x: json['x'] ?? 0,
      y: json['y'] ?? 0,
      letter: json['letter'] ?? '',
    );
  }
}

class Lane {
  final String id;
  final int color;
  final PointPos arrow;
  final String direction; // "up", "down", "left", "right"
  final List<LetterCell> cells;

  Lane({
    required this.id,
    required this.color,
    required this.arrow,
    required this.direction,
    required this.cells,
  });

  /// The complete word formed by this lane
  String get word => cells.map((c) => c.letter).join('');

  /// Total count of letters
  int get length => cells.length;

  /// Check if a coordinate belongs to this lane's arrow or cells
  bool containsPos(int px, int py) {
    if (arrow.x == px && arrow.y == py) return true;
    for (final c in cells) {
      if (c.x == px && c.y == py) return true;
    }
    return false;
  }

  factory Lane.fromJson(Map<String, dynamic> json) {
    return Lane(
      id: json['id'] ?? '',
      color: json['color'] ?? 0,
      arrow: PointPos.fromJson(json['arrow'] as Map<String, dynamic>),
      direction: json['direction'] ?? 'up',
      cells: (json['cells'] as List<dynamic>? ?? [])
          .map((e) => LetterCell.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Crate {
  final int x;
  final int y;
  int threshold;

  Crate({required this.x, required this.y, required this.threshold});

  PointPos get pos => PointPos(x: x, y: y);

  factory Crate.fromJson(Map<String, dynamic> json) {
    return Crate(
      x: json['x'] ?? 0,
      y: json['y'] ?? 0,
      threshold: json['threshold'] ?? 1,
    );
  }

  Crate clone() => Crate(x: x, y: y, threshold: threshold);
}

class LevelSettings {
  final int levelNumber;
  final int moveLimit;
  final int reviveMoves;

  LevelSettings({
    required this.levelNumber,
    required this.moveLimit,
    required this.reviveMoves,
  });

  factory LevelSettings.fromJson(Map<String, dynamic> json) {
    return LevelSettings(
      levelNumber: json['levelNumber'] ?? 0,
      moveLimit: json['moveLimit'] ?? 0,
      reviveMoves: json['reviveMoves'] ?? 0,
    );
  }
}

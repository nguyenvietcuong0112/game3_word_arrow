import 'package:flutter/material.dart';

class LaneColorStyle {
  final Color primary;
  final Color dark;
  final Color light;
  final Color textColor;

  const LaneColorStyle({
    required this.primary,
    required this.dark,
    required this.light,
    required this.textColor,
  });
}

class GamePalette {
  static const Color boardBg = Color(0xFFA96646);
  static const Color boardWoodLight = Color(0xFFBD7854);
  static const Color boardWoodDark = Color(0xFF8F5133);

  // Default Letter Tile colors
  static const Color tileBg = Color(0xFFFFFDF9);
  static const Color tileShadow = Color(0xFFE2D3C4);
  static const Color tileBorder = Color(0xFFEFE4D8);
  static const Color tileText = Color(0xFF261912);

  // Tile Dragged / Selected State
  static const Color tileHighlighted = Color(0xFFFFF3CD);

  // Crate colors
  static const Color crateBg = Color(0xFFDF9548);
  static const Color crateBorder = Color(0xFF9C5A1E);
  static const Color crateText = Color(0xFF261912);

  // Lane color definitions (indexed 0..15 matching Unity WordOutBoardSpriteAtlas)
  static final Map<int, LaneColorStyle> _styles = {
    0: const LaneColorStyle(
      primary: Color(0xFFF8A6F8), // Bubblegum Pink
      dark: Color(0xFFC84EC8),
      light: Color(0xFFF8A6F8),
      textColor: Color(0xFF4A104A),
    ),
    1: const LaneColorStyle(
      primary: Color(0xFFFABAE6), // Light Pastel Pink
      dark: Color(0xFFD660B0),
      light: Color(0xFFFABAE6),
      textColor: Color(0xFF4A1035),
    ),
    2: const LaneColorStyle(
      primary: Color(0xFFC2A5EE), // Lavender Purple
      dark: Color(0xFF8E5DD4),
      light: Color(0xFFC2A5EE),
      textColor: Color(0xFF2E1556),
    ),
    3: const LaneColorStyle(
      primary: Color(0xFFF7C563), // Golden Yellow
      dark: Color(0xFFD99516),
      light: Color(0xFFF7C563),
      textColor: Color(0xFF4A2A04),
    ),
    4: const LaneColorStyle(
      primary: Color(0xFFFDA774), // Warm Orange
      dark: Color(0xFFE26824),
      light: Color(0xFFFDA774),
      textColor: Color(0xFF4A1E04),
    ),
    5: const LaneColorStyle(
      primary: Color(0xFF97E18A), // Apple Green
      dark: Color(0xFF56B546),
      light: Color(0xFF97E18A),
      textColor: Color(0xFF163E10),
    ),
    6: const LaneColorStyle(
      primary: Color(0xFFF2819F), // Magenta / Rose
      dark: Color(0xFFCA2F58),
      light: Color(0xFFF2819F),
      textColor: Color(0xFF4E0C1F),
    ),
    7: const LaneColorStyle(
      primary: Color(0xFFFCBF93), // Warm Peach
      dark: Color(0xFFDD8546),
      light: Color(0xFFFCBF93),
      textColor: Color(0xFF4E2205),
    ),
    8: const LaneColorStyle(
      primary: Color(0xFF99CEF7), // Sky Blue
      dark: Color(0xFF4E9CE6),
      light: Color(0xFF99CEF7),
      textColor: Color(0xFF0C2E52),
    ),
    9: const LaneColorStyle(
      primary: Color(0xFFA382F9), // Violet Purple
      dark: Color(0xFF6E40DE),
      light: Color(0xFFA382F9),
      textColor: Color(0xFF220A58),
    ),
    10: const LaneColorStyle(
      primary: Color(0xFFBEEE95), // Light Lime Green
      dark: Color(0xFF88C951),
      light: Color(0xFFBEEE95),
      textColor: Color(0xFF234407),
    ),
    11: const LaneColorStyle(
      primary: Color(0xFF8CEFC4), // Mint / Seafoam
      dark: Color(0xFF44C88E),
      light: Color(0xFF8CEFC4),
      textColor: Color(0xFF0C442A),
    ),
    12: const LaneColorStyle(
      primary: Color(0xFF9AE9F1), // Cyan / Aqua
      dark: Color(0xFF49BCC9),
      light: Color(0xFF9AE9F1),
      textColor: Color(0xFF0B3A40),
    ),
    13: const LaneColorStyle(
      primary: Color(0xFFABB5FC), // Slate / Periwinkle
      dark: Color(0xFF697CE8),
      light: Color(0xFFABB5FC),
      textColor: Color(0xFF141F61),
    ),
    14: const LaneColorStyle(
      primary: Color(0xFFFB857A), // Red Coral
      dark: Color(0xFFD63C2F),
      light: Color(0xFFFB857A),
      textColor: Color(0xFF4E0E08),
    ),
    15: const LaneColorStyle(
      primary: Color(0xFFCF7975), // Terracotta / Rust
      dark: Color(0xFFA54540),
      light: Color(0xFFCF7975),
      textColor: Color(0xFF441210),
    ),
  };

  static LaneColorStyle getStyle(int colorId) {
    if (_styles.containsKey(colorId)) {
      return _styles[colorId]!;
    }
    // Fallback: pick style based on modulo
    final keys = _styles.keys.toList();
    final key = keys[colorId.abs() % keys.length];
    return _styles[key]!;
  }
}

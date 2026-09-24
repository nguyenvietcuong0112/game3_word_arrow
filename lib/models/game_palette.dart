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

  // Lane color definitions (indexed by level color id)
  static final Map<int, LaneColorStyle> _styles = {
    1: const LaneColorStyle(
      primary: Color(0xFFF472B6), // Pink
      dark: Color(0xFFDB2777),
      light: Color(0xFFFBCFE8),
      textColor: Color(0xFF831843),
    ),
    2: const LaneColorStyle(
      primary: Color(0xFFFB7185), // Rose
      dark: Color(0xFFE11D48),
      light: Color(0xFFFECDD3),
      textColor: Color(0xFF881337),
    ),
    3: const LaneColorStyle(
      primary: Color(0xFFFBBF24), // Yellow
      dark: Color(0xFFD97706),
      light: Color(0xFFFDE68A),
      textColor: Color(0xFF78350F),
    ),
    4: const LaneColorStyle(
      primary: Color(0xFFFB923C), // Orange
      dark: Color(0xFFEA580C),
      light: Color(0xFFFED7AA),
      textColor: Color(0xFF7C2D12),
    ),
    5: const LaneColorStyle(
      primary: Color(0xFF4ADE80), // Green
      dark: Color(0xFF16A34A),
      light: Color(0xFFBBF7D0),
      textColor: Color(0xFF14532D),
    ),
    6: const LaneColorStyle(
      primary: Color(0xFFC084FC), // Lavender
      dark: Color(0xFF9333EA),
      light: Color(0xFFE9D5FF),
      textColor: Color(0xFF581C87),
    ),
    7: const LaneColorStyle(
      primary: Color(0xFFA855F7), // Purple
      dark: Color(0xFF7E22CE),
      light: Color(0xFFE9D5FF),
      textColor: Color(0xFF3B0764),
    ),
    8: const LaneColorStyle(
      primary: Color(0xFF38BDF8), // Blue
      dark: Color(0xFF0284C7),
      light: Color(0xFFBAE6FD),
      textColor: Color(0xFF0C4A6E),
    ),
    10: const LaneColorStyle(
      primary: Color(0xFF34D399), // Mint Green
      dark: Color(0xFF059669),
      light: Color(0xFFA7F3D0),
      textColor: Color(0xFF064E3B),
    ),
    11: const LaneColorStyle(
      primary: Color(0xFF2DD4BF), // Teal
      dark: Color(0xFF0D9488),
      light: Color(0xFF99F6E4),
      textColor: Color(0xFF134E4A),
    ),
    13: const LaneColorStyle(
      primary: Color(0xFF818CF8), // Indigo
      dark: Color(0xFF4F46E5),
      light: Color(0xFFC7D2FE),
      textColor: Color(0xFF1E1B4B),
    ),
    15: const LaneColorStyle(
      primary: Color(0xFFE07A5F), // Terracotta / Peach
      dark: Color(0xFFC05238),
      light: Color(0xFFFFD4C7),
      textColor: Color(0xFF4A180B),
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

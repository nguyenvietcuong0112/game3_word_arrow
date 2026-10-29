import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/level_model.dart';

enum BoosterType { hint, hammer, firework }

class LevelService {
  static final LevelService _instance = LevelService._internal();
  factory LevelService() => _instance;
  LevelService._internal();

  // Exact Unity BoosterConfig & BoosterPricing constants
  static const int hintUnlockLevel = 3;
  static const int hammerUnlockLevel = 6;
  static const int fireworkUnlockLevel = 9;

  static const int hintPackPrice = 900;
  static const int hammerPackPrice = 1800;
  static const int fireworkPackPrice = 2400;
  static const int boosterPackAmount = 3;

  // Exact Unity WordOut reward & revive constants
  static const int baseWinCoins = 10;
  static const int adWinCoins = 50;
  static const int reviveCoinsCost = 500;

  // Feature first-encounter levels
  static const int cratesUnlockLevel = 10;
  static const int hiddenArrowsUnlockLevel = 13;
  static const int locksUnlockLevel = 21;

  int _currentLevelIndex = 1;
  int _coins = 1160;
  int _maxUnlockedLevel = 1;

  final Map<BoosterType, int> _boosterCounts = {
    BoosterType.hint: 0,
    BoosterType.hammer: 0,
    BoosterType.firework: 0,
  };

  final Set<BoosterType> _claimedBoosterUnlocks = {};
  final Set<BoosterType> _completedBoosterTutorials = {};
  final Set<String> _shownFeatureUnlocks = {};

  int get currentLevelIndex => _currentLevelIndex;
  int get coins => _coins;
  int get maxUnlockedLevel => _maxUnlockedLevel;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLevelIndex = prefs.getInt('current_level_index') ?? 1;
    _coins = prefs.getInt('player_coins') ?? 1160;
    _maxUnlockedLevel = prefs.getInt('max_unlocked_level') ?? 1;

    for (final type in BoosterType.values) {
      final key = _boosterCountKey(type);
      _boosterCounts[type] = prefs.getInt(key) ?? 0;

      if (prefs.getBool(_boosterUnlockedKey(type)) == true) {
        _claimedBoosterUnlocks.add(type);
      }
      if (prefs.getBool(_boosterTutorialKey(type)) == true) {
        _completedBoosterTutorials.add(type);
      }
    }

    for (final feat in ['crates', 'hidden', 'locks']) {
      if (prefs.getBool('feature_shown_$feat') == true) {
        _shownFeatureUnlocks.add(feat);
      }
    }
  }

  String _boosterCountKey(BoosterType type) => 'booster_count_${type.name}';
  String _boosterUnlockedKey(BoosterType type) => 'booster_unlocked_${type.name}';
  String _boosterTutorialKey(BoosterType type) => 'booster_tutorial_done_${type.name}';

  static int unlockLevelFor(BoosterType type) {
    switch (type) {
      case BoosterType.hint:
        return hintUnlockLevel;
      case BoosterType.hammer:
        return hammerUnlockLevel;
      case BoosterType.firework:
        return fireworkUnlockLevel;
    }
  }

  static int packPriceFor(BoosterType type) {
    switch (type) {
      case BoosterType.hint:
        return hintPackPrice;
      case BoosterType.hammer:
        return hammerPackPrice;
      case BoosterType.firework:
        return fireworkPackPrice;
    }
  }

  static String boosterTitle(BoosterType type) {
    switch (type) {
      case BoosterType.hint:
        return 'Hint';
      case BoosterType.hammer:
        return 'Hammer';
      case BoosterType.firework:
        return 'Firework';
    }
  }

  static String boosterDescription(BoosterType type) {
    switch (type) {
      case BoosterType.hint:
        return 'Highlights a word with an open path so you can clear it right away.';
      case BoosterType.hammer:
        return 'Smash and clear any chosen word or crate on the board.';
      case BoosterType.firework:
        return 'Launch fireworks to clear up to 5 words or crates at once!';
    }
  }

  static String boosterIconAsset(BoosterType type) {
    switch (type) {
      case BoosterType.hint:
        return 'assets/images/boosters/WordsArrowHintBooster.png';
      case BoosterType.hammer:
        return 'assets/images/boosters/WordsArrowHammerBooster.png';
      case BoosterType.firework:
        return 'assets/images/boosters/WordsArrowFireworkBooster.png';
    }
  }

  int getBoosterCount(BoosterType type) => _boosterCounts[type] ?? 0;

  bool hasClaimedBoosterUnlock(BoosterType type) =>
      _claimedBoosterUnlocks.contains(type);

  bool isBoosterTutorialCompleted(BoosterType type) =>
      _completedBoosterTutorials.contains(type);

  bool isBoosterUnlocked(BoosterType type, int currentPlayingLevel) {
    final unlockLvl = unlockLevelFor(type);
    if (currentPlayingLevel < unlockLvl && !hasClaimedBoosterUnlock(type)) {
      return false;
    }
    return hasClaimedBoosterUnlock(type) || currentPlayingLevel > unlockLvl;
  }

  Future<void> claimBoosterUnlock(BoosterType type, {int giftAmount = 1}) async {
    _claimedBoosterUnlocks.add(type);
    _boosterCounts[type] = (_boosterCounts[type] ?? 0) + giftAmount;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_boosterUnlockedKey(type), true);
    await prefs.setInt(_boosterCountKey(type), _boosterCounts[type]!);
  }

  Future<void> markBoosterTutorialCompleted(BoosterType type) async {
    _completedBoosterTutorials.add(type);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_boosterTutorialKey(type), true);
  }

  Future<void> addBooster(BoosterType type, int amount) async {
    _boosterCounts[type] = (_boosterCounts[type] ?? 0) + amount;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_boosterCountKey(type), _boosterCounts[type]!);
  }

  Future<bool> consumeBooster(BoosterType type) async {
    final current = _boosterCounts[type] ?? 0;
    if (current <= 0) return false;
    _boosterCounts[type] = current - 1;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_boosterCountKey(type), _boosterCounts[type]!);
    return true;
  }

  bool hasShownFeatureUnlock(String featureKey) =>
      _shownFeatureUnlocks.contains(featureKey);

  Future<void> markFeatureUnlockShown(String featureKey) async {
    _shownFeatureUnlocks.add(featureKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('feature_shown_$featureKey', true);
  }

  Future<LevelModel> loadLevel(int levelNumber) async {
    final path = 'assets/levels/json/level_$levelNumber.json';
    final jsonString = await rootBundle.loadString(path);
    final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
    return LevelModel.fromJson(jsonMap);
  }

  Future<void> setCurrentLevel(int levelNumber) async {
    _currentLevelIndex = levelNumber;
    if (_currentLevelIndex > _maxUnlockedLevel) {
      _maxUnlockedLevel = _currentLevelIndex;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_level_index', _currentLevelIndex);
    await prefs.setInt('max_unlocked_level', _maxUnlockedLevel);
  }

  Future<void> completeLevelAndAdvance(int completedLevel) async {
    final nextLevel = completedLevel < 200 ? completedLevel + 1 : 1;
    _currentLevelIndex = nextLevel;
    if (nextLevel > _maxUnlockedLevel) {
      _maxUnlockedLevel = nextLevel;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_level_index', _currentLevelIndex);
    await prefs.setInt('max_unlocked_level', _maxUnlockedLevel);
  }

  Future<void> unlockNextLevel() async {
    await completeLevelAndAdvance(_currentLevelIndex);
  }

  Future<void> addCoins(int amount) async {
    _coins += amount;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('player_coins', _coins);
  }

  Future<bool> spendCoins(int amount) async {
    if (_coins < amount) return false;
    _coins -= amount;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('player_coins', _coins);
    return true;
  }

  Future<void> saveLevelStars(int levelNumber, int stars) async {
    final prefs = await SharedPreferences.getInstance();
    final currentStars = prefs.getInt('stars_level_$levelNumber') ?? 0;
    if (stars > currentStars) {
      await prefs.setInt('stars_level_$levelNumber', stars);
    }
  }

  Future<int> getLevelStars(int levelNumber) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('stars_level_$levelNumber') ?? 0;
  }
}

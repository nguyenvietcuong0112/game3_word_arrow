import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/level_model.dart';

class LevelService {
  static final LevelService _instance = LevelService._internal();
  factory LevelService() => _instance;
  LevelService._internal();

  int _currentLevelIndex = 1;
  int _coins = 1160;
  int _maxUnlockedLevel = 1;

  int get currentLevelIndex => _currentLevelIndex;
  int get coins => _coins;
  int get maxUnlockedLevel => _maxUnlockedLevel;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLevelIndex = prefs.getInt('current_level_index') ?? 1;
    _coins = prefs.getInt('player_coins') ?? 1160;
    _maxUnlockedLevel = prefs.getInt('max_unlocked_level') ?? 1;
  }

  Future<LevelModel> loadLevel(int levelNumber) async {
    final path = 'assets/levels/json/level_$levelNumber.json';
    final jsonString = await rootBundle.loadString(path);
    final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
    return LevelModel.fromJson(jsonMap);
  }

  Future<void> setCurrentLevel(int levelNumber) async {
    _currentLevelIndex = levelNumber;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_level_index', _currentLevelIndex);
  }

  Future<void> unlockNextLevel() async {
    _currentLevelIndex++;
    if (_currentLevelIndex > _maxUnlockedLevel) {
      _maxUnlockedLevel = _currentLevelIndex;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_level_index', _currentLevelIndex);
    await prefs.setInt('max_unlocked_level', _maxUnlockedLevel);
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

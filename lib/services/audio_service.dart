import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _bgmPlayer = AudioPlayer();
  final List<AudioPlayer> _sfxPool = List.generate(6, (_) => AudioPlayer());
  int _poolIndex = 0;

  bool _isMusicEnabled = true;
  bool _isSfxEnabled = true;
  bool _isVibrationEnabled = true;
  int _lastTileSelectMs = 0;

  bool get isMusicEnabled => _isMusicEnabled;
  bool get isSfxEnabled => _isSfxEnabled;
  bool get isVibrationEnabled => _isVibrationEnabled;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isMusicEnabled = prefs.getBool('music_enabled') ?? true;
    _isSfxEnabled = prefs.getBool('sfx_enabled') ?? true;
    _isVibrationEnabled = prefs.getBool('vibration_enabled') ?? true;

    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgmPlayer.setVolume(0.45);
    for (final p in _sfxPool) {
      await p.setPlayerMode(PlayerMode.lowLatency);
      await p.setReleaseMode(ReleaseMode.stop);
      await p.setVolume(0.85);
    }

    if (_isMusicEnabled) {
      playBgm();
    }
  }

  Future<void> toggleMusic() async {
    _isMusicEnabled = !_isMusicEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('music_enabled', _isMusicEnabled);

    if (_isMusicEnabled) {
      playBgm();
    } else {
      pauseBgm();
    }
  }

  Future<void> toggleSfx() async {
    _isSfxEnabled = !_isSfxEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sfx_enabled', _isSfxEnabled);
  }

  Future<void> toggleVibration() async {
    _isVibrationEnabled = !_isVibrationEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibration_enabled', _isVibrationEnabled);
  }

  Future<void> playBgm() async {
    if (!_isMusicEnabled) return;
    try {
      await _bgmPlayer.stop();
      await _bgmPlayer.play(AssetSource('audio/music/Music_InGame_Main.ogg'));
    } catch (_) {}
  }

  Future<void> pauseBgm() async {
    try {
      await _bgmPlayer.pause();
    } catch (_) {}
  }

  Future<void> resumeBgm() async {
    if (!_isMusicEnabled) return;
    try {
      await _bgmPlayer.resume();
    } catch (_) {}
  }

  void playSfx(String soundName) {
    if (!_isSfxEnabled) return;
    try {
      final player = _sfxPool[_poolIndex];
      _poolIndex = (_poolIndex + 1) % _sfxPool.length;
      player.play(AssetSource('audio/sfx/$soundName'));
    } catch (_) {}
  }

  // Common sound & haptic triggers (throttled during rapid swipe to avoid platform channel jank)
  void playTileSelect() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastTileSelectMs < 45) return;
    _lastTileSelectMs = now;
    if (_isVibrationEnabled) {
      HapticFeedback.selectionClick();
    }
    playSfx('SFX_Menu_UI_Pop.ogg');
  }

  void playSwipe() {
    playSfx('SFX_Common_UI_Swipe_Swoosh_Long.ogg');
  }

  void playLaneClear() {
    if (_isVibrationEnabled) {
      HapticFeedback.mediumImpact();
    }
    playSfx('SFX_InGame_Play_Column_Complete_Single.ogg');
  }

  void playBlockedBounce() {
    if (_isVibrationEnabled) {
      HapticFeedback.heavyImpact();
    }
    playSfx('SFX_Common_UI_Click_Negative.ogg');
  }

  void playUnlock() {
    if (_isVibrationEnabled) {
      HapticFeedback.mediumImpact();
    }
    playSfx('SFX_Menu_UI_Unlock.ogg');
  }

  void playCrateHit() {
    if (_isVibrationEnabled) {
      HapticFeedback.mediumImpact();
    }
    playSfx('SFX_Common_UI_Purchase_Success.ogg');
  }

  void playWin() {
    if (_isVibrationEnabled) {
      HapticFeedback.heavyImpact();
    }
    playSfx('SFX_InGame_Play_RoundEnd_Win.ogg');
    Future.delayed(const Duration(milliseconds: 300), () {
      playSfx('SFX_InGame_Play_Confetti.ogg');
    });
  }

  void playLose() {
    if (_isVibrationEnabled) {
      HapticFeedback.vibrate();
    }
    playSfx('SFX_InGame_Play_RoundEnd_Lose.ogg');
  }

  void playButtonClick() {
    if (_isVibrationEnabled) {
      HapticFeedback.lightImpact();
    }
    playSfx('SFX_Common_UI_Click_Generic.ogg');
  }

  void playReward() {
    if (_isVibrationEnabled) {
      HapticFeedback.lightImpact();
    }
    playSfx('SFX_Menu_UI_Sparkles.ogg');
  }
}

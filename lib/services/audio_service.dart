import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  bool _isMusicEnabled = true;
  bool _isSfxEnabled = true;

  bool get isMusicEnabled => _isMusicEnabled;
  bool get isSfxEnabled => _isSfxEnabled;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isMusicEnabled = prefs.getBool('music_enabled') ?? true;
    _isSfxEnabled = prefs.getBool('sfx_enabled') ?? true;

    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgmPlayer.setVolume(0.45);
    await _sfxPlayer.setVolume(0.85);

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

  Future<void> playSfx(String soundName) async {
    if (!_isSfxEnabled) return;
    try {
      final player = AudioPlayer();
      await player.setVolume(0.85);
      await player.play(AssetSource('audio/sfx/$soundName'));
      player.onPlayerComplete.listen((_) {
        player.dispose();
      });
    } catch (_) {}
  }

  // Common sound triggers
  void playTileSelect() => playSfx('SFX_Menu_UI_Pop.ogg');
  void playSwipe() => playSfx('SFX_Common_UI_Swipe_Swoosh_Long.ogg');
  void playLaneClear() => playSfx('SFX_InGame_Play_Column_Complete_Single.ogg');
  void playBlockedBounce() => playSfx('SFX_Common_UI_Click_Negative.ogg');
  void playCrateHit() => playSfx('SFX_Common_UI_Purchase_Success.ogg');
  void playWin() {
    playSfx('SFX_InGame_Play_RoundEnd_Win.ogg');
    Future.delayed(const Duration(milliseconds: 300), () {
      playSfx('SFX_InGame_Play_Confetti.ogg');
    });
  }
  void playLose() => playSfx('SFX_InGame_Play_RoundEnd_Lose.ogg');
  void playButtonClick() => playSfx('SFX_Common_UI_Click_Generic.ogg');
  void playReward() => playSfx('SFX_Menu_UI_Sparkles.ogg');
}

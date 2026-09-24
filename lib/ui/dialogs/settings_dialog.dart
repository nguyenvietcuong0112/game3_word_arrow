import 'package:flutter/material.dart';
import '../../services/audio_service.dart';
import '../widgets/game_button.dart';
import '../widgets/game_popup_dialog.dart';

class SettingsDialog extends StatefulWidget {
  final VoidCallback onRestart;
  final VoidCallback onOpenLevelSelect;

  const SettingsDialog({
    super.key,
    required this.onRestart,
    required this.onOpenLevelSelect,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  final AudioService _audio = AudioService();

  @override
  Widget build(BuildContext context) {
    return GamePopupDialog(
      title: 'SETTINGS',
      onClose: () => Navigator.pop(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),

          // Sound FX Toggle Row
          _buildSettingRow(
            title: 'Sound FX',
            iconAsset: 'assets/images/icons/SoundIcon.png',
            isEnabled: _audio.isSfxEnabled,
            onToggle: () async {
              await _audio.toggleSfx();
              setState(() {});
            },
          ),
          const SizedBox(height: 12),

          // Music Toggle Row
          _buildSettingRow(
            title: 'Music',
            iconAsset: 'assets/images/icons/MusicIcon.png',
            isEnabled: _audio.isMusicEnabled,
            onToggle: () async {
              await _audio.toggleMusic();
              setState(() {});
            },
          ),
          const SizedBox(height: 24),

          // Restart Level Button
          GameButton(
            text: 'RESTART LEVEL',
            color: GameButtonColor.orange,
            height: 52,
            fontSize: 18,
            onTap: () {
              Navigator.pop(context);
              widget.onRestart();
            },
          ),
          const SizedBox(height: 12),

          // Select Level Button
          GameButton(
            text: 'SELECT LEVEL',
            color: GameButtonColor.blue,
            height: 50,
            fontSize: 18,
            onTap: () async {
              Navigator.pop(context);
              await Future.delayed(const Duration(milliseconds: 150));
              widget.onOpenLevelSelect();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow({
    required String title,
    required String iconAsset,
    required bool isEnabled,
    required VoidCallback onToggle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0369A1).withOpacity(0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset(
                iconAsset,
                width: 28,
                height: 28,
                color: Colors.white,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Panteon',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Switch(
            value: isEnabled,
            onChanged: (_) => onToggle(),
            activeColor: const Color(0xFF4ADE80),
          ),
        ],
      ),
    );
  }
}

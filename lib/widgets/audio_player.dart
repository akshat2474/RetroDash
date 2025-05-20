import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

class GameAudio {
  AudioPlayer? _blastPlayer;
  AudioPlayer? _explosionPlayer;
  AudioPlayer? _backgroundPlayer;
  
  bool _initialized = false;
  
  // Sound effect sources
  final String _blastSoundPath = 'audio/blast.mp3';
  final String _explosionSoundPath = 'audio/explosion.mp3';
  final String _backgroundMusicPath = 'audio/space_theme.mp3';

  Future<void> initialize() async {
    try {
      // Create audio players
      _blastPlayer = AudioPlayer();
      _explosionPlayer = AudioPlayer();
      _backgroundPlayer = AudioPlayer();
      
      // Pre-load sound effects
      await _blastPlayer!.setSource(AssetSource(_blastSoundPath));
      await _explosionPlayer!.setSource(AssetSource(_explosionSoundPath));
      await _backgroundPlayer!.setSource(AssetSource(_backgroundMusicPath));
      
      // Set volume
      await _blastPlayer!.setVolume(0.5);
      await _explosionPlayer!.setVolume(0.7);
      await _backgroundPlayer!.setVolume(0.3);
      
      // Loop background music
      await _backgroundPlayer!.setReleaseMode(ReleaseMode.loop);
      
      // Start background music
      await _backgroundPlayer!.resume();
      
      _initialized = true;
      debugPrint('Audio initialized successfully');
    } catch (e) {
      debugPrint('Error initializing audio: $e');
      // Re-throw to let the caller handle the error
      rethrow;
    }
  }

  void playBlastSound() {
    if (!_initialized) return;
    
    try {
      // Clone player to allow overlapping sounds
      _blastPlayer?.stop();
      _blastPlayer?.seek(Duration.zero);
      _blastPlayer?.resume();
    } catch (e) {
      debugPrint('Error playing blast sound: $e');
    }
  }

  void playExplosionSound() {
    if (!_initialized) return;
    
    try {
      _explosionPlayer?.stop();
      _explosionPlayer?.seek(Duration.zero);
      _explosionPlayer?.resume();
    } catch (e) {
      debugPrint('Error playing explosion sound: $e');
    }
  }

  void dispose() {
    _blastPlayer?.dispose();
    _explosionPlayer?.dispose();
    _backgroundPlayer?.dispose();
  }
}
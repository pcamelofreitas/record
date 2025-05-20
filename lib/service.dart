// lib/audio_task.dart
import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class TJAudioHandler extends BaseAudioHandler {
  final _recorder = AudioRecorder();
  bool _initialized = false;
  String? _outputPath;

  Future<void> _init() async {
    if (_initialized) return;
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      throw Exception('Permission to record audio not granted');
    }

    final dir = await getApplicationDocumentsDirectory();
    _outputPath =
        '${dir.path}/scheduled_${DateTime.now().toIso8601String()}.wav';
    _initialized = true;
  }

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    switch (name) {
      case 'startRecording':
        await _init();
        await _recorder.start(
          RecordConfig(
            encoder: AudioEncoder.wav,
            bitRate: 16000 * 16, // 16 bits * 16kHz
            sampleRate: 16000,
          ),
          path: _outputPath!,
        );
        break;

      case 'stopRecording':
        if (await _recorder.isRecording()) {
          await _recorder.stop();
        }
        break;
    }
  }

  @override
  Future<void> stop() async {
    await customAction('stopRecording');
    _initialized = false;
    await super.stop();
  }
}

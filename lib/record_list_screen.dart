import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:path/path.dart' as p;

class RecordListScreen extends StatefulWidget {
  const RecordListScreen({super.key});

  @override
  State<RecordListScreen> createState() => _RecordListScreenState();
}

class _RecordListScreenState extends State<RecordListScreen> {
  final record = AudioRecorder();
  final player = AudioPlayer();
  List<FileSystemEntity> recordings = [];
  bool isRecording = false;
  String? playingPath;

  @override
  void initState() {
    super.initState();
    _loadRecordings();
  }

  Future<String> _getDirectoryPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  Future<void> _loadRecordings() async {
    final dirPath = await _getDirectoryPath();
    final dir = Directory(dirPath);
    final files =
        dir
            .listSync()
            .where((f) => f is File && p.extension(f.path) == '.m4a')
            .toList();

    setState(() {
      recordings = files;
    });
  }

  Future<void> _startRecording() async {
    debugPrint("Iniciando gravação...");
    final dirPath = await _getDirectoryPath();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = p.join(dirPath, '$timestamp.m4a');

    final config = RecordConfig(
      encoder: AudioEncoder.wav,
      bitRate: 128000,
      sampleRate: 44100,
    );

    await record.start(config, path: path);
    setState(() {
      isRecording = true;
    });
  }

  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && isRecording) {
      debugPrint("App em segundo plano. Gravação continua...");
    }
  }

  Future<void> _stopRecording() async {
    await record.stop();
    setState(() {
      isRecording = false;
    });
    _loadRecordings();
  }

  Future<void> _playRecording(String path) async {
    if (playingPath == path) {
      await player.stop();
      setState(() => playingPath = null);
      return;
    }

    await player.stop();
    await player.play(DeviceFileSource(path));
    setState(() {
      playingPath = path;
    });

    player.onPlayerComplete.listen((event) {
      setState(() {
        playingPath = null;
      });
    });
  }

  Future<void> _deleteRecording(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
      _loadRecordings();
    }
  }

  Future<void> _renameRecording(String oldPath) async {
    final dirPath = await _getDirectoryPath();
    final oldFile = File(oldPath);
    final oldName = p.basenameWithoutExtension(oldPath);

    final controller = TextEditingController(text: oldName);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Renomear gravação'),
            content: TextField(controller: controller),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancelar'),
              ),
              TextButton(
                onPressed: () async {
                  final newPath = p.join(dirPath, '${controller.text}.m4a');
                  await oldFile.rename(newPath);
                  Navigator.pop(context);
                  _loadRecordings();
                },
                child: Text('Renomear'),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: isRecording ? null : _startRecording,
              child: Text('Iniciar Gravação'),
            ),
            SizedBox(width: 20),
            ElevatedButton(
              onPressed: isRecording ? _stopRecording : null,
              child: Text('Parar Gravação'),
            ),
          ],
        ),
        SizedBox(height: 20),
        isRecording
            ? ListTile(title: Text('Gravando...'))
            : ListTile(title: Text('Gravação parada')),
        ListTile(),
        Expanded(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: recordings.length,
            itemBuilder: (context, index) {
              final file = recordings[index];
              final name = p.basename(file.path);
              final isPlaying = file.path == playingPath;

              return ListTile(
                title: Text(name),
                onTap: () => _playRecording(file.path),
                subtitle: Text(
                  isPlaying ? 'Reproduzindo...' : 'Toque para reproduzir',
                  style: TextStyle(
                    color: isPlaying ? Colors.green : Colors.black,
                  ),
                ),
                leading: IconButton(
                  icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow),
                  onPressed: () => _playRecording(file.path),
                ),

                trailing: PopupMenuButton<String>(
                  onSelected:
                      (value) =>
                          value == 'delete'
                              ? _deleteRecording(file.path)
                              : _renameRecording(file.path),

                  itemBuilder:
                      (context) => [
                        PopupMenuItem(value: 'rename', child: Text('Renomear')),
                        PopupMenuItem(value: 'delete', child: Text('Excluir')),
                      ],
                ),
              );
            },
            separatorBuilder:
                (context, index) => Divider(color: Colors.grey, height: 1),
          ),
        ),
      ],
    );
  }
}

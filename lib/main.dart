import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:web_socket_channel/io.dart';

void main() {
  runApp(MaterialApp(home: RecordOne()));
}

class RecordOne extends StatefulWidget {
  const RecordOne({super.key});

  @override
  State<RecordOne> createState() => _RecordOneState();
}

class _RecordOneState extends State<RecordOne> {
  final record = AudioRecorder();
  final player = AudioPlayer();
  List<FileSystemEntity> recordings = [];
  bool isRecording = false;
  String? playingPath;
  IOWebSocketChannel? channel;

  @override
  void initState() {
    super.initState();
    _loadRecordings();
  }

  StreamSubscription<Uint8List>? _subscription;

  Future<void> startStream() async {
    print('Iniciando stream...');
    final hasPermission = await record.hasPermission();
    if (!hasPermission) return;

    Stream<Uint8List> stream = await record.startStream(
      RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
    );
    channel = IOWebSocketChannel.connect(
      'ws://192.168.1.3:8080/websocket/audio',
    );

    _subscription = stream.listen((data) {
      if (channel == null) {
        print('Canal não inicializado');
        return;
      }
      print('Stream data: ${data.length} bytes');
      channel?.sink.add(data); // Envia os bytes diretamente
    });

    print('Stream iniciado');
  }

  Future<void> stopStream() async {
    await record.stop();
    await _subscription?.cancel();
    await channel?.sink.close();
    print('Stream parado');
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

  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && isRecording) {
      debugPrint("App em segundo plano. Gravação continua...");
    }
  }

  @override
  void dispose() {
    player.dispose();
    stopStream();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Gravador de Áudio')),
      floatingActionButton: FloatingActionButton(
        onPressed:
            isRecording
                ? _stopRecording
                : () {
                  Future.delayed(const Duration(seconds: 3), () {
                    _startRecording();
                  });
                },

        child: Icon(isRecording ? Icons.stop : Icons.mic),
      ),
      body: PageView(
        children: [
          ListView.separated(
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
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 20,
            children: [
              Text('Streaming'),
              ElevatedButton(
                onPressed: startStream,
                child: Text('Iniciar Stream'),
              ),
              _subscription == null
                  ? Text('Stream não iniciado')
                  : Text('Stream ativo'),
              ElevatedButton(
                onPressed: stopStream,
                child: Text('Parar Stream'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

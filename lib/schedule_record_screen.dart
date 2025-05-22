import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class ScheduleRecordScreen extends StatefulWidget {
  const ScheduleRecordScreen({super.key});

  @override
  State<ScheduleRecordScreen> createState() => _ScheduleRecordScreenState();
}

class _ScheduleRecordScreenState extends State<ScheduleRecordScreen> {
  final player = AudioPlayer();

  List<FileSystemEntity> _recordedFiles = [];

  @override
  void initState() {
    super.initState();
    _loadRecordings();
    FlutterBackgroundService().on('update').listen((event) {
      print("Mensagem do serviço: $event");
    });
  }

  Future<void> _loadRecordings() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files =
          directory.listSync().where((item) {
            return item.path.endsWith('.m4a') || item.path.endsWith('.aac');
          }).toList();
      files.sort(
        (a, b) => File(
          b.path,
        ).lastModifiedSync().compareTo(File(a.path).lastModifiedSync()),
      );
      setState(() {
        _recordedFiles = files;
      });
    } catch (e) {
      print("Erro ao carregar gravações: $e");
      setState(() {
        _recordedFiles = [];
      });
    }
  }

  Future<void> _scheduleRecording() async {
    final service = FlutterBackgroundService();
    bool isRunning = await service.isRunning();
    if (!isRunning) {
      await service.startService();
      print("Serviço iniciado.");
    }

    service.invoke('scheduleRecording');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gravação agendada para daqui a 2 minutos!'),
      ),
    );
  }

  Future<void> _deleteRecording(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        _loadRecordings();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gravação removida: ${path.split('/').last}')),
        );
      }
    } catch (e) {
      print("Erro ao deletar gravação: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao remover: $e')));
    }
  }

  void _playRecording(String path) async {
    print("Tocando gravação: $path");
    await player.play(DeviceFileSource(path));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.schedule_send),
              label: const Text('Agendar Gravação (2 min)'),
              onPressed: _scheduleRecording,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Gravações Salvas",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child:
                _recordedFiles.isEmpty
                    ? const Center(child: Text('Nenhuma gravação encontrada.'))
                    : ListView.builder(
                      itemCount: _recordedFiles.length,
                      itemBuilder: (context, index) {
                        final file = _recordedFiles[index];
                        final fileName = file.path.split('/').last;
                        final fileStat = FileStat.statSync(file.path);
                        final recordingDate = DateFormat(
                          'dd/MM/yy HH:mm',
                        ).format(fileStat.modified);
                        return ListTile(
                          leading: const Icon(
                            Icons.audiotrack,
                            color: Colors.blueAccent,
                          ),
                          title: Text(fileName),
                          subtitle: Text(
                            'Gravado em: $recordingDate\nTamanho: ${(fileStat.size / (1024)).toStringAsFixed(2)} KB',
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => _deleteRecording(file.path),
                          ),
                          onTap: () => _playRecording(file.path),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadRecordings,
        tooltip: 'Atualizar Lista',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

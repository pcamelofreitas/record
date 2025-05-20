import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:web_socket_channel/io.dart';

class StreamingScreen extends StatefulWidget {
  const StreamingScreen({super.key});

  @override
  State<StreamingScreen> createState() => _StreamingScreenState();
}

class _StreamingScreenState extends State<StreamingScreen> {
  final record = AudioRecorder();
  IOWebSocketChannel? channel;
  StreamSubscription<Uint8List>? _subscription;
  String webSocketPath = 'ws://localhost:8080/websocket/audio';
  Future<void> startStream() async {
    print('Iniciando stream...');
    try {
      final hasPermission = await record.hasPermission();
      if (!hasPermission) return;

      Stream<Uint8List> stream = await record.startStream(
        RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );
      channel = IOWebSocketChannel.connect(webSocketPath);

      _subscription = stream.listen((data) {
        if (channel == null) {
          print('Canal não inicializado');
          return;
        }
        print('Stream data: ${data.length} bytes');
        channel?.sink.add(data); // Envia os bytes diretamente
      });

      print('Stream iniciado');
    } catch (e) {
      print('Erro ao iniciar stream: $e');
    }
  }

  Future<void> stopStream() async {
    await record.stop();
    await _subscription?.cancel();
    await channel?.sink.close();
    print('Stream parado');
  }

  @override
  void dispose() {
    stopStream();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 20,
      children: [
        Text('Streaming'),
        TextField(
          decoration: InputDecoration(labelText: 'Websocket URL'),
          onChanged: (value) {
            setState(() {
              webSocketPath = value;
            });
          },
        ),
        Text('Defina seu IP e porta'),

        ElevatedButton(
          onPressed: webSocketPath != '' ? startStream : null,
          child: Text('Iniciar Stream'),
        ),
        _subscription == null
            ? Text('Stream não iniciado')
            : Text('Stream ativo'),
        ElevatedButton(onPressed: stopStream, child: Text('Parar Stream')),
      ],
    );
  }
}

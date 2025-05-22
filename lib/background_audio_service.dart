import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'dart:math';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audio_session/audio_session.dart';
import 'package:intl/intl.dart';

import 'notification_service.dart';

const int BACKGROUND_NOTIFICATION_ID = 888;

@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  await NotificationService.initialize();
  final audioRecorder = AudioRecorder();
  String? currentRecordingPath;

  final session = await AudioSession.instance;
  await session.configure(
    AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.allowBluetooth |
          AVAudioSessionCategoryOptions.defaultToSpeaker,
      avAudioSessionMode: AVAudioSessionMode.videoRecording,
      avAudioSessionRouteSharingPolicy:
          AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.voiceCommunication,
      ),
      androidWillPauseWhenDucked: true,
    ),
  );

  service.on('scheduleRecording').listen((payload) async {
    print('Serviço: Agendamento de gravação recebido.');
    await NotificationService.showNotification(
      id: BACKGROUND_NOTIFICATION_ID,
      title: "Gravador Agendado",
      body: "Aguardando 2 minutos para iniciar a gravação...",
    );

    Timer(const Duration(minutes: 2), () async {
      print('Serviço: Iniciando gravação...');
      if (await session.setActive(true)) {
        try {
          final Directory appDocumentsDir =
              await getApplicationDocumentsDirectory();
          final String formattedTimestamp = DateFormat(
            'yyyyMMdd_HHmmss',
          ).format(DateTime.now());
          final filePath =
              '${appDocumentsDir.path}/recording_$formattedTimestamp.m4a';
          currentRecordingPath = filePath;

          const config = RecordConfig(
            encoder: AudioEncoder.aacLc,
            sampleRate: 44100,
            bitRate: 128000,
          );
          await audioRecorder.start(config, path: filePath);
          print('Serviço: Gravação iniciada em $filePath');

          await NotificationService.showNotification(
            id: BACKGROUND_NOTIFICATION_ID,
            title: "Gravador Ativo",
            body: "Gravando áudio...",
          );

          Timer(const Duration(seconds: 30), () async {
            await audioRecorder.stop();
            currentRecordingPath = null;
            print('Serviço: Gravação finalizada.');
            await NotificationService.showNotification(
              id: BACKGROUND_NOTIFICATION_ID,
              title: "Gravador Agendado",
              body: "Gravação concluída. Pronto para novo agendamento.",
            );
            await session.setActive(false);
          });
        } catch (e) {
          print('Serviço: Erro ao gravar áudio: $e');
          if (currentRecordingPath != null) {
            await audioRecorder.stop();
            currentRecordingPath = null;
          }
          await NotificationService.showNotification(
            id: BACKGROUND_NOTIFICATION_ID,
            title: "Erro na Gravação",
            body:
                "Ocorreu um erro: ${e.toString().substring(0, min(e.toString().length, 50))}",
          );
          await session.setActive(false);
        }
      } else {
        print('Serviço: Não foi possível ativar a sessão de áudio.');
        await NotificationService.showNotification(
          id: BACKGROUND_NOTIFICATION_ID,
          title: "Erro na Gravação",
          body: "Não foi possível ativar a sessão de áudio.",
        );
      }
    });
  });

  print(
    'Serviço: Iniciado e pronto. Configurando notificação inicial via FLN.',
  );
  await NotificationService.showNotification(
    id: BACKGROUND_NOTIFICATION_ID,
    title: "Serviço de Gravação de Áudio",
    body: "Pronto para agendar gravações.",
  );
}

@pragma('vm:entry-point')
Future<bool> iosOnBackgroundHandler(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  print(
    "iOS: onBackgroundHandler iniciando a lógica principal do serviço (onStart)...",
  );

  await onStart(service);

  return true;
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  const String channelId = 'audio_recorder_channel';

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: false,
      notificationChannelId: channelId,
      initialNotificationTitle: 'Serviço de Gravação',
      initialNotificationContent: 'Inicializando...',
      foregroundServiceNotificationId: BACKGROUND_NOTIFICATION_ID,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: iosOnBackgroundHandler,
    ),
  );
}

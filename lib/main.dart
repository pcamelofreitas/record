import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record_one/background_audio_service.dart';
import 'package:record_one/notification_service.dart';
import 'package:record_one/record_list_screen.dart';
import 'package:record_one/schedule_record_screen.dart';
import 'package:record_one/streaming_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await requestPermissions(); // Suas permissões existentes
  await NotificationService.initialize(); // Inicializa flutter_local_notifications
  await initializeService(); // In
  runApp(MaterialApp(home: RecordOne()));
}

Future<void> requestPermissions() async {
  var microphoneStatus = await Permission.microphone.request();
  if (microphoneStatus.isDenied || microphoneStatus.isPermanentlyDenied) {
    print("Permissão de microfone negada.");
  }

  if (Platform.isAndroid) {
    var notificationStatus = await Permission.notification.request();
    if (notificationStatus.isDenied) {
      print("Permissão de notificação negada.");
    }
  }
}

class RecordOne extends StatefulWidget {
  const RecordOne({super.key});

  @override
  State<RecordOne> createState() => _RecordOneState();
}

class _RecordOneState extends State<RecordOne> {
  PageController? pageController;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    pageController = PageController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Gravador de Áudio')),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Gravações'),
          BottomNavigationBarItem(icon: Icon(Icons.stream), label: 'Stream'),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Agendar Gravação',
          ),
        ],
        currentIndex: currentIndex,
        onTap: (index) {
          if (index == 0) {
            pageController?.animateToPage(
              0,
              duration: Duration(milliseconds: 300),
              curve: Curves.ease,
            );
            setState(() {
              currentIndex = index;
            });
          } else if (index == 1) {
            pageController?.animateToPage(
              1,
              duration: Duration(milliseconds: 300),
              curve: Curves.ease,
            );
            setState(() {
              currentIndex = index;
            });
          } else if (index == 2) {
            pageController?.animateToPage(
              2,
              duration: Duration(milliseconds: 300),
              curve: Curves.ease,
            );
            setState(() {
              currentIndex = index;
            });
          }
        },
      ),

      body: PageView(
        controller: pageController,
        children: [
          RecordListScreen(),
          StreamingScreen(),
          ScheduleRecordScreen(),
        ],
      ),
    );
  }
}

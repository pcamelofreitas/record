import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:record_one/record_list_screen.dart';
import 'package:record_one/schedule_record_screen.dart';
import 'package:record_one/service.dart';
import 'package:record_one/streaming_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AudioService.init(
    builder: () => TJAudioHandler(),
    config: AudioServiceConfig(
      androidNotificationChannelName: 'Scheduled Recorder',
      androidNotificationOngoing: true,
    ),
  );

  runApp(MaterialApp(home: RecordOne()));
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

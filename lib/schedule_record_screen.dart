import 'package:android_alarm_manager/android_alarm_manager.dart';
import 'package:flutter/material.dart';
import 'package:record_one/service.dart';

class ScheduleRecordScreen extends StatefulWidget {
  const ScheduleRecordScreen({super.key});

  @override
  State<ScheduleRecordScreen> createState() => _ScheduleRecordScreenState();
}

class _ScheduleRecordScreenState extends State<ScheduleRecordScreen> {
  TimeOfDay selectedTime = TimeOfDay.now();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Agendar Gravação'),
        Text("Apenas Para Android"),
        HourPicker(
          onSelectTime: (time) {
            setState(() {
              selectedTime = time;
            });
          },
        ),
        Center(
          child: ElevatedButton(
            child: Text(
              'Agendar Gravação para ${selectedTime.format(context)}',
            ),
            onPressed: () async {
              // Schedule daily 9:00 AM recording on Android
              await AndroidAlarmManager.periodic(
                const Duration(days: 1),
                0, // alarm ID
                () => TJAudioHandler().customAction('startRecording'),
                startAt: DateTime(
                  DateTime.now().year,
                  DateTime.now().month,
                  DateTime.now().day,
                  9,
                ),
                exact: true,
                wakeup: true,
              );

              // (Optional) schedule stop after 30 minutes
              await AndroidAlarmManager.oneShotAt(
                DateTime(
                  DateTime.now().year,
                  DateTime.now().month,
                  DateTime.now().day,
                  9,
                  30,
                ),
                1,
                () => TJAudioHandler().customAction('stopRecording'),
                exact: true,
                wakeup: true,
              );
            },
          ),
        ),
      ],
    );
  }
}

class HourPicker extends StatefulWidget {
  const HourPicker({super.key, required this.onSelectTime});

  final void Function(TimeOfDay) onSelectTime;

  @override
  State<HourPicker> createState() => _HourPickerState();
}

class _HourPickerState extends State<HourPicker> {
  TimeOfDay selectedTime = TimeOfDay.now();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Hora selecionada: ${selectedTime.format(context)}'),
        ElevatedButton(
          onPressed: () async {
            final time = await showTimePicker(
              context: context,
              initialTime: selectedTime,
            );

            if (time != null) {
              widget.onSelectTime(time);
              setState(() {
                selectedTime = time;
              });
            }
          },
          child: Text('Selecionar Hora'),
        ),
      ],
    );
  }
}

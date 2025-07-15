import 'package:flutter/material.dart';
import 'package:memora/services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isNotificationScheduled = false;

  @override
  void initState() {
    super.initState();
    _checkNotificationStatus();
  }

  Future<void> _checkNotificationStatus() async {
    final notificationService = NotificationService();
    final scheduledTime = await notificationService
        .getScheduledNotificationTime();
    setState(() {
      if (scheduledTime != null) {
        _selectedTime = scheduledTime;
        _isNotificationScheduled = true;
      } else {
        _isNotificationScheduled = false;
      }
    });
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _scheduleNotification() async {
    final notificationService = NotificationService();
    await notificationService.scheduleDailyNotificationAtTime(
      _selectedTime.hour,
      _selectedTime.minute,
    );
    setState(() {
      _isNotificationScheduled = true;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('알림이 설정되었습니다.')));
  }

  Future<void> _cancelNotification() async {
    final notificationService = NotificationService();
    await notificationService.cancelDailyNotification();
    setState(() {
      _isNotificationScheduled = false;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('알림이 해지되었습니다.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('알림 설정')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              title: const Text('알림 시간'),
              subtitle: Text(_selectedTime.format(context)),
              trailing: const Icon(Icons.edit),
              onTap: () => _selectTime(context),
            ),
            const SizedBox(height: 20),
            if (!_isNotificationScheduled)
              ElevatedButton(
                onPressed: _scheduleNotification,
                child: const Text('알림 설정'),
              )
            else
              ElevatedButton(
                onPressed: _cancelNotification,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('알림 해지'),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:memora/services/notification_service.dart';
import 'package:memora/widgets/common_app_bar.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  NotificationSettingsScreenState createState() =>
      NotificationSettingsScreenState();
}

class NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _isEnabled = false;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 21, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _notificationService.getNotificationSettings();
    setState(() {
      _isEnabled = settings['isEnabled'];
      _selectedTime = TimeOfDay(
        hour: settings['hour'],
        minute: settings['minute'],
      );
    });
  }

  Future<void> _updateSettings() async {
    await _notificationService.setNotification(_isEnabled, _selectedTime);
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
      _updateSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: '알림 설정'),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('복습 알림 받기'),
            value: _isEnabled,
            onChanged: (bool value) {
              setState(() {
                _isEnabled = value;
              });
              _updateSettings();
            },
          ),
          ListTile(
            title: const Text('알림 시간'),
            subtitle: Text(_selectedTime.format(context)),
            onTap: () => _selectTime(context),
            enabled: _isEnabled,
          ),
        ],
      ),
    );
  }
}

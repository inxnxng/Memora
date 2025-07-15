import 'package:flutter/material.dart';
import 'package:memora/providers/task_provider.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('프로필 설정')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '이름'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.isNotEmpty) {
                  Provider.of<TaskProvider>(
                    context,
                    listen: false,
                  ).updateUserName(_nameController.text);
                  Navigator.pop(context);
                }
              },
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }
}

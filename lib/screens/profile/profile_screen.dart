import 'package:flutter/material.dart';
import 'package:memora/models/proficiency_level.dart';
import 'package:memora/providers/user_provider.dart';
import 'package:memora/services/auth_service.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  ProficiencyLevel? _selectedLevel;
  final List<ProficiencyLevel> _levels = ProficiencyLevel.values;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _nameController.text = userProvider.displayName ?? '';
    _selectedLevel = userProvider.userLevel;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('프로필 설정')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '이름',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '숙련도',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ..._levels.map((level) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _selectedLevel = level;
                    });
                    _showLevelDescription(level);
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: _selectedLevel == level
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                  ),
                  child: Text(level.displayName),
                ),
              );
            }),
            const Spacer(),
            ElevatedButton(
              onPressed: () async {
                final userProvider = Provider.of<UserProvider>(
                  context,
                  listen: false,
                );
                bool changed = false;

                if (_nameController.text.isNotEmpty &&
                    _nameController.text != userProvider.displayName) {
                  await userProvider.saveUserName(_nameController.text);
                  changed = true;
                }

                if (_selectedLevel != null &&
                    _selectedLevel != userProvider.userLevel) {
                  await userProvider.saveUserLevel(_selectedLevel!);
                  changed = true;
                }

                if (changed) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('프로필이 저장되었습니다.')),
                  );
                }
                if (mounted) {
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('저장'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                await context.read<AuthService>().signOut();
                // The AuthGate will handle navigation to the LoginScreen.
                // We just need to pop this screen.
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('로그아웃'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLevelDescription(ProficiencyLevel level) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(level.displayName),
          content: Text(level.description),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }
}

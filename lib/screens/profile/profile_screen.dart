import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
      appBar: AppBar(title: const Text('내 정보')),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProfileCard(userProvider),
                  const SizedBox(height: 20),
                  _buildEditProfileCard(userProvider),
                  const SizedBox(height: 20),
                  _buildSessionInfoCard(userProvider),
                  const SizedBox(height: 40),
                  _buildLogoutButton(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(UserProvider userProvider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (userProvider.photoURL != null)
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(userProvider.photoURL!),
              ),
            const SizedBox(height: 16),
            Text(
              userProvider.displayName ?? '이름 없음',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (userProvider.email != null)
              Text(
                userProvider.email!,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '${userProvider.streakCount}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('스트릭', style: TextStyle(fontSize: 14)),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      userProvider.userLevel?.displayName ?? '미설정',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('숙련도', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditProfileCard(UserProvider userProvider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '프로필 수정',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '이름',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '숙련도',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: _levels.map((level) {
                return ChoiceChip(
                  label: Text(level.displayName),
                  selected: _selectedLevel == level,
                  onSelected: (selected) {
                    setState(() {
                      _selectedLevel = level;
                    });
                    _showLevelDescription(level);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _saveProfile(userProvider),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionInfoCard(UserProvider userProvider) {
    final sortedSessions = userProvider.sessionMap.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '학습 기록',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (sortedSessions.isEmpty)
              const Center(child: Text('학습 기록이 없습니다.'))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedSessions.length,
                itemBuilder: (context, index) {
                  final entry = sortedSessions[index];
                  final date = DateFormat(
                    'yyyy-MM-dd',
                  ).format(DateTime.parse(entry.key));
                  return ListTile(
                    title: Text(date),
                    trailing: Text(
                      '${entry.value}번 학습',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return ElevatedButton(
      onPressed: () async {
        await context.read<AuthService>().signOut();
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: const Text('로그아웃'),
    );
  }

  void _saveProfile(UserProvider userProvider) async {
    bool changed = false;

    if (_nameController.text.isNotEmpty &&
        _nameController.text != userProvider.displayName) {
      await userProvider.saveUserName(_nameController.text);
      changed = true;
    }

    if (_selectedLevel != null && _selectedLevel != userProvider.userLevel) {
      await userProvider.saveUserLevel(_selectedLevel!);
      changed = true;
    }

    if (changed) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('프로필이 저장되었습니다.')));
    }
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

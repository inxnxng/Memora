import 'package:flutter/material.dart';
import 'package:memora/providers/user_provider.dart';
import 'package:provider/provider.dart';

class ChangeLevelScreen extends StatefulWidget {
  const ChangeLevelScreen({super.key});

  @override
  State<ChangeLevelScreen> createState() => _ChangeLevelScreenState();
}

class _ChangeLevelScreenState extends State<ChangeLevelScreen> {
  String? _selectedLevel;

  @override
  void initState() {
    super.initState();
    _selectedLevel = Provider.of<UserProvider>(
      context,
      listen: false,
    ).userLevel;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('학습 레벨 변경'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '학습 레벨을 선택해주세요',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                '자신에게 맞는 학습량을 선택하여 꾸준히 기억력을 훈련하세요.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              _buildLevelCard(
                icon: Icons.spa_outlined,
                level: 'beginner',
                title: '초급',
                description: '이제 막 기억력 훈련을 시작하는 단계입니다. 부담 없이 시작해 보세요!',
                dailyGoal: '하루 3번 학습',
              ),
              const SizedBox(height: 16),
              _buildLevelCard(
                icon: Icons.eco_outlined,
                level: 'intermediate',
                title: '중급',
                description: '기억력 훈련에 익숙해지고, 더 높은 목표를 향해 나아가는 단계입니다.',
                dailyGoal: '하루 5번 학습',
              ),
              const SizedBox(height: 16),
              _buildLevelCard(
                icon: Icons.workspace_premium_outlined,
                level: 'expert',
                title: '전문가',
                description: '기억력 훈련의 대가! 꾸준한 노력으로 최고의 기억력을 유지하세요.',
                dailyGoal: '하루 7번 학습',
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _selectedLevel == null ? null : _saveLevel,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text('변경 내용 저장'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelCard({
    required IconData icon,
    required String level,
    required String title,
    required String description,
    required String dailyGoal,
  }) {
    final bool isSelected = _selectedLevel == level;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: isSelected ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedLevel = level;
          });
        },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(
                icon,
                size: 40,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dailyGoal,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }

  void _saveLevel() async {
    if (_selectedLevel != null) {
      await Provider.of<UserProvider>(
        context,
        listen: false,
      ).saveUserLevel(_selectedLevel!);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}

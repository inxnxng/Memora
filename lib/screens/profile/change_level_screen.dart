import 'package:flutter/material.dart';
import 'package:memora/models/proficiency_level.dart';
import 'package:memora/providers/user_provider.dart';
import 'package:provider/provider.dart';

class ChangeLevelScreen extends StatefulWidget {
  const ChangeLevelScreen({super.key});

  @override
  State<ChangeLevelScreen> createState() => _ChangeLevelScreenState();
}

class _ChangeLevelScreenState extends State<ChangeLevelScreen> {
  ProficiencyLevel? _selectedLevel;

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
              ...ProficiencyLevel.values.map(
                (level) => _buildLevelCard(level: level),
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

  Widget _buildLevelCard({required ProficiencyLevel level}) {
    final bool isSelected = _selectedLevel == level;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
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
                  level.icon,
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
                        level.displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        level.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '하루 ${level.dailyGoal}번 학습',
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

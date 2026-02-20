import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memora/constants/app_strings.dart';
import 'package:memora/models/proficiency_level.dart';
import 'package:memora/providers/user_provider.dart';
import 'package:memora/router/app_routes.dart';
import 'package:provider/provider.dart';

class LevelSelectionPage extends StatefulWidget {
  const LevelSelectionPage({super.key});

  @override
  State<LevelSelectionPage> createState() => _LevelSelectionPageState();
}

class _LevelSelectionPageState extends State<LevelSelectionPage> {
  ProficiencyLevel? _selectedLevel;
  bool _isLoading = false;

  void _saveLevelAndContinue() async {
    if (_selectedLevel != null) {
      setState(() {
        _isLoading = true;
      });
      try {
        final userProvider = context.read<UserProvider>();
        await userProvider.saveUserLevel(_selectedLevel!);
        if (mounted) {
          // Redirect logic in GoRouter should handle this,
          // but we also call context.go for double assurance.
          context.go(AppRoutes.home);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('저장 중 오류가 발생했습니다: $e')));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            AppStrings.selectYourLevel,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ...ProficiencyLevel.values.map(
            (level) => _buildLevelOption(context, level),
          ),
          const SizedBox(height: 50),
          ElevatedButton(
            onPressed: (_selectedLevel == null || _isLoading)
                ? null
                : _saveLevelAndContinue,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(AppStrings.saveAndContinue),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelOption(BuildContext context, ProficiencyLevel level) {
    final bool isSelected = _selectedLevel == level;
    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: RadioListTile<ProficiencyLevel>(
        title: Text(level.displayName),
        subtitle: Text(AppStrings.dailyGoal(level.dailyGoal)),
        value: level,
        groupValue: _selectedLevel,
        onChanged: (value) {
          setState(() {
            _selectedLevel = value;
          });
        },
        activeColor: Theme.of(context).primaryColor,
      ),
    );
  }
}

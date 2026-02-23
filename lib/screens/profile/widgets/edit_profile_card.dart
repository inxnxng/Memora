import 'package:flutter/material.dart';
import 'package:memora/constants/app_strings.dart';
import 'package:memora/models/proficiency_level.dart';
import 'package:memora/providers/user_provider.dart';
import 'package:provider/provider.dart';

class EditProfileCard extends StatefulWidget {
  const EditProfileCard({super.key});

  @override
  State<EditProfileCard> createState() => _EditProfileCardState();
}

class _EditProfileCardState extends State<EditProfileCard> {
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

  void _saveProfile() async {
    final userProvider = context.read<UserProvider>();
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

    if (changed && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.profileSavedMessage)),
      );
    }
  }

  void _showLevelDescription(ProficiencyLevel level) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(level.icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(level.displayName),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  level.description,
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 16),
                Text(
                  '기준',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  level.criteriaDescription,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(AppStrings.close),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.editProfile,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: AppStrings.nameLabel,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppStrings.proficiency,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _levels.map((level) {
                final isSelected = _selectedLevel == level;
                return FilterChip(
                  label: Text(level.displayName),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedLevel = level;
                    });
                    _showLevelDescription(level);
                  },
                  selectedColor: theme.colorScheme.primaryContainer,
                  checkmarkColor: theme.colorScheme.primary,
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saveProfile,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(AppStrings.save),
            ),
          ],
        ),
      ),
    );
  }
}

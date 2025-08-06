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
          title: Text(level.displayName),
          content: Text(level.description),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text(AppStrings.close),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              AppStrings.editProfile,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: AppStrings.nameLabel,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              AppStrings.proficiency,
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
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(AppStrings.save),
            ),
          ],
        ),
      ),
    );
  }
}

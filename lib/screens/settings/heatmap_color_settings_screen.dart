import 'package:flutter/material.dart';
import 'package:memora/constants/heatmap_colors.dart';
import 'package:memora/constants/storage_keys.dart';
import 'package:memora/services/local_storage_service.dart';

class HeatmapColorSettingsScreen extends StatefulWidget {
  const HeatmapColorSettingsScreen({super.key});

  @override
  State<HeatmapColorSettingsScreen> createState() =>
      _HeatmapColorSettingsScreenState();
}

class _HeatmapColorSettingsScreenState
    extends State<HeatmapColorSettingsScreen> {
  final LocalStorageService _localStorageService = LocalStorageService();
  String _selectedColorName = StorageKeys.defaultHeatmapColor;

  @override
  void initState() {
    super.initState();
    _loadSelectedColor();
  }

  Future<void> _loadSelectedColor() async {
    // getValue is not defined in LocalStorageService, so I will add it.
    final colorName =
        await _localStorageService.getValue(StorageKeys.heatmapColorKey) ??
        StorageKeys.defaultHeatmapColor;
    if (mounted) {
      setState(() {
        _selectedColorName = colorName;
      });
    }
  }

  Future<void> _setSelectedColor(String colorName) async {
    // saveValue is not defined in LocalStorageService, so I will add it.
    await _localStorageService.saveValue(
      StorageKeys.heatmapColorKey,
      colorName,
    );
    if (mounted) {
      setState(() {
        _selectedColorName = colorName;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('히트맵 색상 설정')),
      body: ListView.builder(
        itemCount: heatmapColorOptions.length,
        itemBuilder: (context, index) {
          final colorOption = heatmapColorOptions[index];
          return RadioListTile<String>(
            title: Text(colorOption.name),
            value: colorOption.name,
            groupValue: _selectedColorName,
            onChanged: (String? value) {
              if (value != null) {
                _setSelectedColor(value);
              }
            },
            secondary: Container(
              width: 24,
              height: 24,
              color: colorOption.color,
            ),
          );
        },
      ),
    );
  }
}

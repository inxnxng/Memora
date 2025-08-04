import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:go_router/go_router.dart';
import 'package:memora/constants/heatmap_colors.dart';
import 'package:memora/constants/storage_keys.dart';
import 'package:memora/services/local_storage_service.dart';
import 'package:memora/widgets/common_app_bar.dart';

class HeatmapColorSettingsScreen extends StatefulWidget {
  const HeatmapColorSettingsScreen({super.key});

  @override
  State<HeatmapColorSettingsScreen> createState() =>
      _HeatmapColorSettingsScreenState();
}

class _HeatmapColorSettingsScreenState
    extends State<HeatmapColorSettingsScreen> {
  final LocalStorageService _localStorageService = LocalStorageService();
  Color _currentColor = Colors.green;

  @override
  void initState() {
    super.initState();
    _loadSelectedColor();
  }

  Future<void> _loadSelectedColor() async {
    final colorString = await _localStorageService.getValue(
      StorageKeys.heatmapColorKey,
    );

    Color selectedColor;

    if (colorString != null) {
      try {
        // Try parsing as a hex string first (new format)
        selectedColor = Color(int.parse(colorString, radix: 16));
      } catch (e) {
        // If parsing fails, assume it's a color name (old format)
        final colorOption = heatmapColorOptions.firstWhere(
          (c) => c.name == colorString,
          orElse: () => heatmapColorOptions.firstWhere(
            (c) => c.name == StorageKeys.defaultHeatmapColor,
          ),
        );
        selectedColor = colorOption.color;
      }
    } else {
      // If no color is saved, use the default
      final defaultColorOption = heatmapColorOptions.firstWhere(
        (c) => c.name == StorageKeys.defaultHeatmapColor,
      );
      selectedColor = defaultColorOption.color;
    }

    if (mounted) {
      setState(() {
        _currentColor = selectedColor;
      });
    }
  }

  Future<void> _saveColor() async {
    await _localStorageService.saveValue(
      StorageKeys.heatmapColorKey,
      // ignore: deprecated_member_use
      _currentColor.value.toRadixString(16).padLeft(8, '0'),
    );
    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: '히트맵 색상 설정'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '원하는 색상을 선택하세요',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ColorPicker(
              pickerColor: _currentColor,
              onColorChanged: (color) {
                setState(() {
                  _currentColor = color;
                });
              },
              pickerAreaHeightPercent: 0.8,
            ),
            const SizedBox(height: 20),
            const Text(
              '기본 색상',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: heatmapColorOptions.map((colorOption) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentColor = colorOption.color;
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorOption.color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _currentColor == colorOption.color
                            ? Theme.of(context).primaryColor
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _saveColor,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('저장'),
        ),
      ),
    );
  }
}

import 'package:memora/constants/storage_keys.dart';
import 'package:memora/services/local_storage_service.dart';

class SettingsService {
  final LocalStorageService _localStorageService;

  SettingsService(this._localStorageService);

  // Heatmap Color
  Future<String> getHeatmapColorName() async {
    return await _localStorageService.getValue(StorageKeys.heatmapColorKey) ??
        StorageKeys.defaultHeatmapColor;
  }

  Future<void> setHeatmapColorName(String colorName) async {
    await _localStorageService.saveValue(
      StorageKeys.heatmapColorKey,
      colorName,
    );
  }
}

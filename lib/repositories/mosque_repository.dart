import '../models/mosque_model.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';

class MosqueRepository {
  final DatabaseService _databaseService;
  final SyncService _syncService;

  MosqueRepository(this._databaseService, this._syncService);

  Future<void> saveMosqueSettings(MosqueModel mosque) async {
    await _databaseService.saveMosqueSettings(mosque);
    await _syncService.markNeedsSync();
    await _syncService.syncWithServer();
  }

  Future<MosqueModel?> getMosqueSettings() async {
    return await _databaseService.getMosqueSettings();
  }

  // Method untuk mengupdate pengaturan spesifik
  Future<void> updateRunningText(String text) async {
    final mosque = await getMosqueSettings();
    if (mosque != null) {
      final updatedMosque = MosqueModel(
        id: mosque.id,
        mosqueName: mosque.mosqueName,
        latitude: mosque.latitude,
        longitude: mosque.longitude,
        runningText: text,
        enableAdzanSound: mosque.enableAdzanSound,
        enableIqamahSound: mosque.enableIqamahSound,
      );
      await saveMosqueSettings(updatedMosque);
    }
  }

  Future<void> updateAdzanSound(bool enable) async {
    final mosque = await getMosqueSettings();
    if (mosque != null) {
      final updatedMosque = MosqueModel(
        id: mosque.id,
        mosqueName: mosque.mosqueName,
        latitude: mosque.latitude,
        longitude: mosque.longitude,
        runningText: mosque.runningText,
        enableAdzanSound: enable,
        enableIqamahSound: mosque.enableIqamahSound,
      );
      await saveMosqueSettings(updatedMosque);
    }
  }
} 
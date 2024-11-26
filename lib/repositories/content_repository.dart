import '../models/content_model.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import 'dart:io';

class ContentRepository {
  final DatabaseService _databaseService;
  final StorageService _storageService;

  ContentRepository(this._databaseService, this._storageService);

  Future<void> addContent(File file, String type) async {
    // Simpan file ke storage lokal
    final savedFile = await _storageService.saveFile(file);
    
    // Dapatkan urutan terakhir
    final contents = await _databaseService.getAllContents();
    final lastOrder = contents.isEmpty ? 0 : contents.last.displayOrder + 1;
    
    // Simpan informasi ke database
    final content = ContentModel(
      type: type,
      path: savedFile.path,
      displayOrder: lastOrder,
    );
    
    await _databaseService.saveContent(content);
  }

  Future<void> deleteContent(ContentModel content) async {
    // Hapus file dari storage
    await _storageService.deleteFile(content.path);
    
    // Hapus data dari database
    if (content.id != null) {
      await _databaseService.deleteContent(content.id!);
    }
  }

  Future<List<ContentModel>> getAllContents() async {
    return await _databaseService.getAllContents();
  }

  Future<void> reorderContents(List<ContentModel> contents) async {
    await _databaseService.reorderContents(contents);
  }
} 
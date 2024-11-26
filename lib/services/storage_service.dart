import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class StorageService {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    final contentDir = Directory('${directory.path}/contents');
    if (!await contentDir.exists()) {
      await contentDir.create(recursive: true);
    }
    return contentDir.path;
  }

  Future<File> saveFile(File sourceFile) async {
    final String fileName = path.basename(sourceFile.path);
    final String localPath = await _localPath;
    final String destPath = path.join(localPath, fileName);
    
    return await sourceFile.copy(destPath);
  }

  Future<void> deleteFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<List<String>> getAllFiles() async {
    final String localPath = await _localPath;
    final Directory directory = Directory(localPath);
    final List<FileSystemEntity> files = await directory.list().toList();
    return files
        .whereType<File>()
        .map((file) => file.path)
        .toList();
  }
} 
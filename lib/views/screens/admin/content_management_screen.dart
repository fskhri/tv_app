import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/content_model.dart';
import '../../../repositories/content_repository.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

class ContentManagementScreen extends StatefulWidget {
  const ContentManagementScreen({Key? key}) : super(key: key);

  @override
  State<ContentManagementScreen> createState() => _ContentManagementScreenState();
}

class _ContentManagementScreenState extends State<ContentManagementScreen> {
  List<ContentModel> _contents = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadContents();
  }

  Future<void> _loadContents() async {
    setState(() => _isLoading = true);
    final contentRepo = Provider.of<ContentRepository>(context, listen: false);
    final contents = await contentRepo.getAllContents();
    setState(() {
      _contents = contents;
      _isLoading = false;
    });
  }

  Future<void> _pickAndUploadFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'mp4'],
    );

    if (result != null) {
      final file = File(result.files.single.path!);
      final extension = result.files.single.extension?.toLowerCase();
      
      final contentRepo = Provider.of<ContentRepository>(context, listen: false);
      await contentRepo.addContent(
        file,
        extension == 'mp4' ? 'video' : 'image',
      );
      
      _loadContents();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Konten'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadContents,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickAndUploadFile,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ReorderableListView.builder(
              itemCount: _contents.length,
              onReorder: (oldIndex, newIndex) async {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                final item = _contents.removeAt(oldIndex);
                _contents.insert(newIndex, item);
                
                final contentRepo = Provider.of<ContentRepository>(
                  context,
                  listen: false,
                );
                await contentRepo.reorderContents(_contents);
                _loadContents();
              },
              itemBuilder: (context, index) {
                final content = _contents[index];
                return Card(
                  key: ValueKey(content.id),
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: content.type == 'image'
                        ? Image.file(
                            File(content.path),
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.video_library),
                    title: Text(content.path.split('/').last),
                    subtitle: Text('Tipe: ${content.type}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Konfirmasi'),
                            content: const Text('Yakin ingin menghapus konten ini?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Batal'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Hapus'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          final contentRepo = Provider.of<ContentRepository>(
                            context,
                            listen: false,
                          );
                          await contentRepo.deleteContent(content);
                          _loadContents();
                        }
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
} 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/mosque_model.dart';
import '../../../repositories/mosque_repository.dart';

class MosqueSettingsScreen extends StatefulWidget {
  const MosqueSettingsScreen({Key? key}) : super(key: key);

  @override
  State<MosqueSettingsScreen> createState() => _MosqueSettingsScreenState();
}

class _MosqueSettingsScreenState extends State<MosqueSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _latController = TextEditingController();
  final _longController = TextEditingController();
  final _runningTextController = TextEditingController();
  bool _enableAdzanSound = true;
  bool _enableIqamahSound = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    final mosqueRepo = Provider.of<MosqueRepository>(context, listen: false);
    final settings = await mosqueRepo.getMosqueSettings();
    
    if (settings != null) {
      _nameController.text = settings.mosqueName;
      _latController.text = settings.latitude.toString();
      _longController.text = settings.longitude.toString();
      _runningTextController.text = settings.runningText;
      setState(() {
        _enableAdzanSound = settings.enableAdzanSound;
        _enableIqamahSound = settings.enableIqamahSound;
      });
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Masjid'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Masjid',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama masjid harus diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latController,
                      decoration: const InputDecoration(
                        labelText: 'Latitude',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Latitude harus diisi';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _longController,
                      decoration: const InputDecoration(
                        labelText: 'Longitude',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Longitude harus diisi';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _runningTextController,
                decoration: const InputDecoration(
                  labelText: 'Running Text',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Running text harus diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Aktifkan Suara Adzan'),
                value: _enableAdzanSound,
                onChanged: (value) {
                  setState(() => _enableAdzanSound = value);
                },
              ),
              SwitchListTile(
                title: const Text('Aktifkan Suara Iqamah'),
                value: _enableIqamahSound,
                onChanged: (value) {
                  setState(() => _enableIqamahSound = value);
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final mosque = MosqueModel(
                        mosqueName: _nameController.text,
                        latitude: double.parse(_latController.text),
                        longitude: double.parse(_longController.text),
                        runningText: _runningTextController.text,
                        enableAdzanSound: _enableAdzanSound,
                        enableIqamahSound: _enableIqamahSound,
                      );

                      final mosqueRepo = Provider.of<MosqueRepository>(
                        context,
                        listen: false,
                      );
                      await mosqueRepo.saveMosqueSettings(mosque);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Pengaturan berhasil disimpan'),
                        ),
                      );
                    }
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('SIMPAN PENGATURAN'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _latController.dispose();
    _longController.dispose();
    _runningTextController.dispose();
    super.dispose();
  }
} 
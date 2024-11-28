import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/prayer_time_widget.dart';
import '../widgets/running_text_widget.dart';
import '../../services/sync_service.dart';
import '../../controllers/prayer_controller.dart';
import 'dart:async';
import '../widgets/content_slider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  Timer? _syncTimer;
  bool _isLoading = true;
  String _runningText = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
      _fetchRunningText();
    });

    // Coba sync setiap 5 menit
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (!mounted) return;
      final syncService = Provider.of<SyncService>(context, listen: false);
      syncService.syncWithServer();
    });
  }

  Future<void> _initializeData() async {
    if (!mounted) return;

    try {
      Provider.of<PrayerController>(context, listen: false);
      // await prayerController.updatePrayerTimesByGPS();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat jadwal sholat: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchRunningText() async {
    final url = Uri.parse('https://0g7d00kv-3000.asse.devtunnels.ms/running-text/user-test');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          setState(() {
            _runningText = data['running_text'];
          });
        }
      } else {
        throw Exception('Failed to load running text');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat teks berjalan: $e')),
      );
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      // Panel kiri (Jadwal Sholat)
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: PrayerTimeWidget(),
                        ),
                      ),
                      // Panel kanan (Konten)
                      Expanded(
                        flex: 3,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            border: Border.all(color: Colors.grey[800]!),
                          ),
                          child: ContentSlider(),
                        ),
                      ),
                    ],
                  ),
                ),
                // Running text di bagian bawah
                RunningTextWidget(
                  text: _runningText.isNotEmpty
                      ? _runningText
                      : '',
                ),
              ],
            ),
    );
  }
}
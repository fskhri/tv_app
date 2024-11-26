import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/prayer_time_widget.dart';
import '../widgets/running_text_widget.dart';
import '../../services/sync_service.dart';
import '../../controllers/prayer_controller.dart';
import 'dart:async';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  Timer? _syncTimer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
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
      final prayerController =
          Provider.of<PrayerController>(context, listen: false);
      await prayerController.updatePrayerTimesByGPS();
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
                          // TODO: Implementasi content slider
                          color: Colors.grey[200],
                          child: const Center(
                            child: Text('Area Konten'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Running text di bagian bawah
                RunningTextWidget(
                  text:
                      'Selamat datang di Masjid Al-Ikhlas. Jadwal kajian setiap hari Ahad ba\'da Subuh.',
                ),
              ],
            ),
    );
  }
}

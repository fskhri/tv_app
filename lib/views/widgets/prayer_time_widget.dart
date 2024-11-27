import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/prayer_controller.dart';
import 'dart:async';

class PrayerTimeWidget extends StatefulWidget {
  @override
  _PrayerTimeWidgetState createState() => _PrayerTimeWidgetState();
}

class _PrayerTimeWidgetState extends State<PrayerTimeWidget> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Inisialisasi data awal
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<PrayerController>(context, listen: false);
      controller.updatePrayerTimesByGPS();
    });
    
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PrayerController>(
      builder: (context, controller, child) {
        final (nextPrayer, nextPrayerName) = controller.getNextPrayer();
        final countdown = controller.formatCountdown(controller.getCountdown());

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tanggal
                  Text(
                    controller.getDate(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12),

                  // Countdown
                  Text(
                    'Menuju Waktu $nextPrayerName',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    countdown,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),

                  Divider(height: 24),

                  // Jadwal Sholat
                  ...[
                    _buildPrayerTime('Imsak', controller.imsak),
                    _buildPrayerTime('Subuh', controller.subuh),
                    _buildPrayerTime('Terbit', controller.terbit),
                    _buildPrayerTime('Dhuha', controller.dhuha),
                    _buildPrayerTime('Dzuhur', controller.dzuhur),
                    _buildPrayerTime('Ashar', controller.ashar),
                    _buildPrayerTime('Maghrib', controller.maghrib),
                    _buildPrayerTime('Isya', controller.isya),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrayerTime(String name, DateTime? time) {
    final now = DateTime.now();
    final isActive = time != null &&
        time.day == now.day &&
        time.hour == now.hour &&
        time.minute == now.minute;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 6),
      color: isActive ? Colors.green.withOpacity(0.1) : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            time != null
                ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
                : '--:--',
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

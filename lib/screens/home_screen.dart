import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../services/sync_service.dart';
import '../models/prayer_schedule.dart';

class HomeScreen extends StatelessWidget {
  final List<PrayerSchedule> prayerSchedules;

  const HomeScreen({
    Key? key,
    required this.prayerSchedules,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Sholat'),
      ),
      body: ListView.builder(
        itemCount: prayerSchedules.length,
        itemBuilder: (context, index) {
          final schedule = prayerSchedules[index];
          return ListTile(
            title: Text(schedule.prayerName),
            subtitle: Text('${schedule.time} - ${schedule.date}'),
          );
        },
      ),
    );
  }
} 
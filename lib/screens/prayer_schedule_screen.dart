import 'package:flutter/material.dart';
import 'package:tv_app/screens/location_settings_screen.dart';
import '../services/sync_service.dart';
import '../services/database_service.dart';
import '../controllers/auth_controller.dart';
import '../models/prayer_schedule.dart';
import 'package:provider/provider.dart';

class PrayerScheduleScreen extends StatefulWidget {
  @override
  _PrayerScheduleScreenState createState() => _PrayerScheduleScreenState();
}

class _PrayerScheduleScreenState extends State<PrayerScheduleScreen> {
  final syncService = SyncService(DatabaseService(), AuthController());
  List<PrayerSchedule> todaySchedules = [];
  Map<String, dynamic>? userLocation;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final location = await syncService.getUserLocation();
      final schedules = await syncService.getTodayPrayerSchedules();

      setState(() {
        userLocation = location;
        todaySchedules = schedules;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error loading schedules: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final isAdmin = authController.currentUser?.role == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: Text('Jadwal Sholat'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: Icon(Icons.admin_panel_settings),
              onPressed: () => Navigator.pushNamed(context, '/home'),
            ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => LocationSettingsScreen()),
              );
              if (result == true) {
                setState(() => isLoading = true);
                loadData();
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await authController.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Location info
                Container(
                  padding: EdgeInsets.all(16),
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Row(
                    children: [
                      Icon(Icons.location_on),
                      SizedBox(width: 8),
                      Text(
                        '${userLocation?['city'] ?? 'Loading...'}, ${userLocation?['province']}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),

                // Prayer times list
                Expanded(
                  child: ListView.builder(
                    itemCount: todaySchedules.length,
                    itemBuilder: (context, index) {
                      final schedule = todaySchedules[index];
                      return ListTile(
                        leading: Icon(Icons.access_time),
                        title: Text(schedule.prayerName),
                        subtitle: Text(schedule.time),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

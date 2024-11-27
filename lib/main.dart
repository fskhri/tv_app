import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/database_service.dart';
import 'views/screens/login_screen.dart';
import 'controllers/auth_controller.dart';
import 'controllers/prayer_controller.dart';
import 'repositories/mosque_repository.dart';
import 'repositories/content_repository.dart';
import 'services/storage_service.dart';
import 'services/sync_service.dart';
import 'screens/location_settings_screen.dart';
import 'screens/prayer_schedule_screen.dart';
import 'screens/home_screen.dart';
import 'services/api_service.dart';
import 'screens/user_management_screen.dart';
import 'package:get/get.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi database
  final databaseService = DatabaseService();
  await databaseService.database;

  // Inisialisasi AuthController
  final authController = AuthController();
  await authController.init();

  runApp(
    MultiProvider(
      providers: [
        Provider<DatabaseService>(create: (_) => databaseService),
        ChangeNotifierProvider<AuthController>(
          create: (_) => authController,
        ),
        Provider<ApiService>(
          create: (context) => ApiService(),
        ),
        ChangeNotifierProvider<PrayerController>(
          create: (_) => PrayerController(databaseService),
        ),
        Provider<SyncService>(
          create: (context) => SyncService(
            Provider.of<DatabaseService>(context, listen: false),
            Provider.of<AuthController>(context, listen: false),
          ),
        ),
        Provider<MosqueRepository>(
          create: (context) => MosqueRepository(
            databaseService,
            Provider.of<SyncService>(context, listen: false),
          ),
        ),
        Provider<ContentRepository>(
          create: (_) => ContentRepository(
            databaseService,
            StorageService(),
          ),
        ),
      ],
      child: GetMaterialApp(
        title: 'Adzan TV',
        theme: ThemeData(
          primarySwatch: Colors.green,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: LoginScreen(),
        routes: {
          '/login': (context) => LoginScreen(),
          '/prayer-schedule': (context) => PrayerScheduleScreen(),
          '/location-settings': (context) => LocationSettingsScreen(),
        },
      ),
    ),
  );
}

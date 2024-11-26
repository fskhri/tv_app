import 'package:flutter/material.dart';
import '../services/sync_service.dart';
import '../services/database_service.dart';
import '../controllers/auth_controller.dart';

class LocationSettingsScreen extends StatefulWidget {
  @override
  _LocationSettingsScreenState createState() => _LocationSettingsScreenState();
}

class _LocationSettingsScreenState extends State<LocationSettingsScreen> {
  final syncService = SyncService(DatabaseService(), AuthController());
  List<Map<String, dynamic>> locations = [];
  String? selectedProvince;
  String? selectedCity;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadLocations();
  }

  Future<void> loadLocations() async {
    try {
      final availableLocations = await syncService.getAvailableLocations();
      setState(() {
        locations = availableLocations;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading locations: $e'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pengaturan Lokasi')),
      body: isLoading 
        ? Center(child: CircularProgressIndicator())
        : Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Dropdown Provinsi
                DropdownButton<String>(
                  isExpanded: true,
                  value: selectedProvince,
                  hint: Text('Pilih Provinsi'),
                  items: locations.map<DropdownMenuItem<String>>((location) {
                    return DropdownMenuItem<String>(
                      value: location['province'] as String,
                      child: Text(location['province'] as String),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedProvince = value;
                      selectedCity = null;
                    });
                  },
                ),
                SizedBox(height: 16),
                
                // Dropdown Kota
                if (selectedProvince != null)
                  DropdownButton<String>(
                    isExpanded: true,
                    value: selectedCity,
                    hint: Text('Pilih Kota'),
                    items: locations
                        .firstWhere((loc) => loc['province'] == selectedProvince)['cities']
                        .map<DropdownMenuItem<String>>((city) {
                      return DropdownMenuItem(
                        value: city['name'],
                        child: Text(city['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCity = value;
                      });
                    },
                  ),
                
                SizedBox(height: 32),
                
                ElevatedButton(
                  onPressed: selectedCity == null ? null : () async {
                    try {
                      await syncService.setUserLocation(
                        selectedCity!, 
                        selectedProvince!
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lokasi berhasil disimpan'))
                      );
                      Navigator.pop(context, true); // Return true jika sukses
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Gagal menyimpan lokasi: $e'))
                      );
                    }
                  },
                  child: Text('Simpan Lokasi'),
                ),
              ],
            ),
          ),
    );
  }
} 
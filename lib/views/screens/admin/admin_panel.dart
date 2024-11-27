import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/api_service.dart';
import '../../../models/user.dart';
import '../../../models/user_location.dart';
import '../../../controllers/auth_controller.dart';

class AdminPanel extends StatefulWidget {
  @override
  _AdminPanelState createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  int _selectedIndex = 0;
  bool _isLoading = false;
  bool _isDataLoaded = false;
  List<User> _users = [];
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'user';
  List<Map<String, String>> _provinces = [];
  List<Map<String, String>> _cities = [];
  String? _selectedProvince;
  String? _selectedCity;
  List<UserLocation> userLocations = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadProvinces();
    if (!_isDataLoaded) {
      _loadUserLocations();
    }
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final users = await apiService.getUsers();
      setState(() => _users = users);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createUser() async {
    if (_formKey.currentState!.validate()) {
      try {
        final apiService = Provider.of<ApiService>(context, listen: false);
        final newUser = User(
          id: '', // ID akan digenerate oleh server
          username: _usernameController.text,
          role: _selectedRole,
        );

        await apiService.createUser(
          newUser.username,
          _passwordController.text,
          newUser.role,
        );
        _loadUsers(); // Refresh daftar user
        _clearForm();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User berhasil dibuat')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _clearForm() {
    _usernameController.clear();
    _passwordController.clear();
    setState(() => _selectedRole = 'user');
  }

  Future<void> _deleteUser(String id) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.deleteUser(id);
      _loadUsers(); // Refresh daftar user

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User berhasil dihapus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _loadProvinces() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final provinces = await apiService.getProvinces();
      print('Provinces loaded: $provinces'); // Debug log
      setState(() => _provinces = provinces);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading provinces: $e')),
      );
    }
  }

  Future<void> _loadCities(String provinceName) async {
    try {
      print('Loading cities for province: $provinceName');
      final apiService = Provider.of<ApiService>(context, listen: false);
      final citiesList = await apiService.getCities(provinceName);
      setState(() {
        _cities = citiesList;
      });
    } catch (e) {
      print('Error loading cities: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat daftar kota')),
      );
    }
  }

  void _showAddLocationDialog(String userId) async {
    // Cek apakah user sudah memiliki lokasi
    final existingLocation = userLocations.firstWhere(
      (location) => location.userId == userId,
      orElse: () => UserLocation(userId: '', province: '', city: ''),
    );

    // Reset nilai awal
    setState(() {
      _selectedProvince = null;
      _selectedCity = null;
    });

    // Load data provinsi jika belum ada
    if (_provinces.isEmpty) {
      await _loadProvinces();
    }

    // Jika ada data existing, cari provinsi yang sesuai
    if (existingLocation.userId.isNotEmpty) {
      // Normalisasi nama provinsi yang ada di database
      String normalizedExistingProvince = existingLocation.province
          .toLowerCase()
          .replaceAll('jakrta', 'jakarta')
          .trim();

      // Cari provinsi yang sesuai
      final matchingProvince = _provinces.firstWhere(
        (p) => p['name']?.toString().toLowerCase() == normalizedExistingProvince,
        orElse: () => {'id': '', 'name': ''},
      );

      // Gunakan null-safe access dan null check
      final provinceId = matchingProvince['id']?.toString();
      final provinceName = matchingProvince['name']?.toString();
      
      if (provinceId != null && provinceId.isNotEmpty && provinceName != null) {
        setState(() {
          _selectedProvince = provinceId;
        });
        await _loadCities(provinceName);
      }
    }

    // Tampilkan dialog
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(existingLocation.userId.isNotEmpty
                  ? 'Update Lokasi'
                  : 'Tambah Lokasi'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedProvince,
                    decoration: InputDecoration(labelText: 'Provinsi'),
                    items: _provinces.map((province) {
                      return DropdownMenuItem(
                        value: province['id'],
                        child: Text(province['name']!),
                      );
                    }).toList(),
                    onChanged: (value) async {
                      setState(() {
                        _selectedProvince = value;
                        _selectedCity = null;
                      });
                      if (value != null) {
                        // Dapatkan nama provinsi dari ID yang dipilih
                        final selectedProvinceName = _provinces
                            .firstWhere((p) => p['id'] == value)['name']!;
                        await _loadCities(selectedProvinceName);
                        setState(() {});
                      }
                    },
                  ),
                  SizedBox(height: 16),
                  if (_cities.isNotEmpty)
                    DropdownButtonFormField<String>(
                      value: _selectedCity,
                      decoration: InputDecoration(labelText: 'Kota'),
                      items: _cities.map((city) {
                        return DropdownMenuItem(
                          value: city['id'],
                          child: Text(city['name']!),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedCity = value);
                      },
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_selectedProvince != null && _selectedCity != null) {
                      try {
                        final apiService = Provider.of<ApiService>(context, listen: false);
                        
                        // Dapatkan nama provinsi dan kota dari ID yang dipilih
                        final provinceName = _provinces
                            .firstWhere((p) => p['id'] == _selectedProvince)['name']!;
                        final cityName = _cities
                            .firstWhere((c) => c['id'] == _selectedCity)['name']!;

                        if (existingLocation.userId.isNotEmpty) {
                          await apiService.updateUserLocation(
                            userId,
                            provinceName,
                            cityName,
                          );
                        } else {
                          await apiService.addUserLocation(
                            userId,
                            provinceName,
                            cityName,
                          );
                        }
                        
                        await _loadUserLocations();
                        Navigator.of(context).pop();
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Lokasi berhasil disimpan')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                  child: Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDashboard() {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ringkasan',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                SizedBox(height: 16),
                Text('Total Users: ${_users.length}'),
                Text('Admin: ${_users.where((u) => u.role == 'admin').length}'),
                Text('Users: ${_users.where((u) => u.role == 'user').length}'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserManagement() {
    return Column(
      children: [
        // Form tambah user
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tambah User Baru',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(labelText: 'Username'),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Username wajib diisi' : null,
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Password wajib diisi' : null,
                  ),
                  SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: InputDecoration(labelText: 'Role'),
                    items: ['admin', 'user'].map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(role),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedRole = value!);
                    },
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _createUser,
                    child: Text('Tambah User'),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 16),
        // Daftar user
        Card(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return ListTile(
                      title: Text(user.username),
                      subtitle: Text('Role: ${user.role}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.location_on),
                            onPressed: () => _showAddLocationDialog(user.id),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => _deleteUser(user.id),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _loadUserLocations() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final locations = await apiService.fetchUserLocations();
      setState(() {
        userLocations = locations;
        _isDataLoaded = true;
      });
    } catch (e) {
      print('Error loading user locations: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthController>(context, listen: false).logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar navigation
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            destinations: [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people),
                label: Text('User Management'),
              ),
            ],
          ),
          // Main content
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: _selectedIndex == 0
                    ? _buildDashboard()
                    : _buildUserManagement(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

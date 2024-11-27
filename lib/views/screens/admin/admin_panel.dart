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

  Future<void> _loadCities(String provinceId) async {
    try {
      print('Loading cities for province ID: $provinceId'); // Log provinceId
      final apiService = Provider.of<ApiService>(context, listen: false);
      final cities = await apiService.getCities(provinceId);
      print('Cities loaded: $cities'); // Log cities
      setState(() => _cities = cities);
    } catch (e) {
      print('Error loading cities: $e'); // Log error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading cities: $e')),
      );
    }
  }

  void _showAddLocationDialog(String userId) async {
    // Cek apakah user sudah memiliki lokasi
    final existingLocation = userLocations.firstWhere(
      (location) => location.userId == userId,
      orElse: () => UserLocation(userId: '', province: '', city: ''),
    );
    
    // Set nilai awal berdasarkan data yang ada (jika ada)
    if (existingLocation.userId.isNotEmpty) {
      _selectedProvince = existingLocation.province;
      _selectedCity = existingLocation.city;
      // Load cities untuk provinsi yang ada
      await _loadCities(existingLocation.province);
    } else {
      _selectedProvince = null;
      _selectedCity = null;
    }

    // Tampilkan dialog setelah data siap
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder( // Gunakan StatefulBuilder untuk update state dalam dialog
          builder: (context, setState) {
            return AlertDialog(
              title: Text(existingLocation.userId.isNotEmpty ? 'Update Lokasi' : 'Tambah Lokasi'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedProvince,
                    decoration: InputDecoration(labelText: 'Provinsi'),
                    items: _provinces.map((province) {
                      return DropdownMenuItem(
                        value: province['name'],
                        child: Text(province['name']!),
                      );
                    }).toList(),
                    onChanged: (value) async {
                      setState(() {
                        _selectedProvince = value;
                        _selectedCity = null;
                        _cities = [];
                      });
                      if (value != null) {
                        await _loadCities(value);
                        setState(() {}); // Refresh dialog setelah cities diload
                      }
                    },
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedCity,
                    decoration: InputDecoration(labelText: 'Kota'),
                    items: _cities.map((city) {
                      return DropdownMenuItem(
                        value: city['name'],
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
                  onPressed: () {
                    // Reset nilai saat cancel
                    _selectedProvince = null;
                    _selectedCity = null;
                    Navigator.of(context).pop();
                  },
                  child: Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_selectedProvince != null && _selectedCity != null) {
                      final apiService = Provider.of<ApiService>(context, listen: false);
                      
                      try {
                        if (existingLocation.userId.isNotEmpty) {
                          print('Updating location for user: $userId');
                          await apiService.updateUserLocation(
                            userId,
                            _selectedProvince!,
                            _selectedCity!,
                          );
                          
                          setState(() {
                            final index = userLocations.indexWhere((loc) => loc.userId == userId);
                            if (index != -1) {
                              userLocations[index] = UserLocation(
                                userId: userId,
                                province: _selectedProvince!,
                                city: _selectedCity!,
                              );
                            } else {
                              userLocations.add(UserLocation(
                                userId: userId,
                                province: _selectedProvince!,
                                city: _selectedCity!,
                              ));
                            }
                          });
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Lokasi berhasil diperbarui')),
                          );
                          Navigator.of(context).pop();
                        } else {
                          await apiService.addUserLocation(
                            userId,
                            _selectedProvince!,
                            _selectedCity!,
                          );
                          
                          setState(() {
                            userLocations.add(UserLocation(
                              userId: userId,
                              province: _selectedProvince!,
                              city: _selectedCity!,
                            ));
                          });
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Lokasi berhasil ditambahkan')),
                          );
                        }
                        Navigator.of(context).pop();
                      } catch (e) {
                        print('Error updating location: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Pilih provinsi dan kota')),
                      );
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
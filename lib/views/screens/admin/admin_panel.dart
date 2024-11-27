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
  // PROPERTIES
  // ==========
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  int _selectedIndex = 0;
  String _selectedRole = 'user';
  String? _selectedProvince;
  String? _selectedCity;
  
  bool _isLoading = false;
  bool _isDataLoaded = false;
  
  List<User> _users = [];
  List<Map<String, String>> _provinces = [];
  List<Map<String, String>> _cities = [];
  List<UserLocation> userLocations = [];

  // LIFECYCLE METHODS
  // ================
  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // INITIALIZATION
  // =============
  Future<void> _initializeData() async {
    await Future.wait([
      _loadUsers(),
      _loadProvinces(),
      if (!_isDataLoaded) _loadUserLocations(),
    ]);
  }

  // DATA LOADING METHODS
  // ===================
  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final users = await apiService.getUsers();
      setState(() => _users = users);
    } catch (e) {
      _showErrorSnackBar('Error loading users: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadProvinces() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final provinces = await apiService.getProvinces();
      setState(() => _provinces = provinces);
    } catch (e) {
      _showErrorSnackBar('Error loading provinces: $e');
    }
  }

  Future<void> _loadCities(String provinceName) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final citiesList = await apiService.getCities(provinceName);
      setState(() => _cities = citiesList);
    } catch (e) {
      _showErrorSnackBar('Failed to load cities');
    }
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
      _showErrorSnackBar('Error loading locations: $e');
    }
  }

  // USER MANAGEMENT METHODS
  // =====================
  Future<void> _createUser() async {
    if (_formKey.currentState!.validate()) {
      try {
        final apiService = Provider.of<ApiService>(context, listen: false);
        await apiService.createUser(
          _usernameController.text,
          _passwordController.text,
          _selectedRole,
        );
        
        await _loadUsers();
        _clearForm();
        _showSuccessSnackBar('User created successfully');
      } catch (e) {
        _showErrorSnackBar('Error creating user: $e');
      }
    }
  }

  Future<void> _deleteUser(String id) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.deleteUser(id);
      await _loadUsers();
      _showSuccessSnackBar('User deleted successfully');
    } catch (e) {
      _showErrorSnackBar('Error deleting user: $e');
    }
  }

  // LOCATION MANAGEMENT
  // =================
  void _showAddLocationDialog(String userId) async {
    final existingLocation = _findExistingLocation(userId);
    _resetLocationSelection();

    if (_provinces.isEmpty) {
      await _loadProvinces();
    }

    await _initializeExistingLocation(existingLocation);

    if (!mounted) return;
    _showLocationDialog(userId, existingLocation);
  }

  UserLocation _findExistingLocation(String userId) {
    return userLocations.firstWhere(
      (location) => location.userId == userId,
      orElse: () => UserLocation(userId: '', province: '', city: ''),
    );
  }

  void _resetLocationSelection() {
    setState(() {
      _selectedProvince = null;
      _selectedCity = null;
    });
  }

  Future<void> _initializeExistingLocation(UserLocation location) async {
    if (location.userId.isNotEmpty) {
      final normalizedProvince = _normalizeProvinceName(location.province);
      final matchingProvince = _findMatchingProvince(normalizedProvince);
      await _setSelectedProvince(matchingProvince);
    }
  }

  String _normalizeProvinceName(String province) {
    return province.toLowerCase().replaceAll('jakrta', 'jakarta').trim();
  }

  Map<String, String> _findMatchingProvince(String normalizedName) {
    return _provinces.firstWhere(
      (p) => p['name']?.toString().toLowerCase() == normalizedName,
      orElse: () => {'id': '', 'name': ''},
    );
  }

  Future<void> _setSelectedProvince(Map<String, String> province) async {
    final id = province['id'];
    final name = province['name'];
    
    if (id != null && id.isNotEmpty && name != null) {
      setState(() => _selectedProvince = id);
      await _loadCities(name);
    }
  }

  // UI COMPONENTS
  // ============
  Widget _buildDashboard() {
    return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text('Ringkasan', style: Theme.of(context).textTheme.headlineSmall),
                SizedBox(height: 16),
                Text('Total Users: ${_users.length}'),
                Text('Admin: ${_users.where((u) => u.role == 'admin').length}'),
                Text('Users: ${_users.where((u) => u.role == 'user').length}'),
              ],
            ),
          ),
    );
  }

  Widget _buildUserManagement() {
    return Column(
      children: [
        _buildUserForm(),
        SizedBox(height: 16),
        _buildUserList(),
      ],
    );
  }

  void _showLocationDialog(String userId, UserLocation existingLocation) {
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
                        final provinceName = _provinces
                            .firstWhere((p) => p['id'] == value)['name']!;
                        await _loadCities(provinceName);
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
                        
                        final provinceName = _provinces
                            .firstWhere((p) => p['id'] == _selectedProvince)['name']!;
                        final cityName = _cities
                            .firstWhere((c) => c['id'] == _selectedCity)['name']!;

                        await apiService.saveUserLocation(
                          userId,
                          provinceName,
                          cityName,
                        );
                        
                        await _loadUserLocations();
                        Navigator.of(context).pop();
                        
                        _showSuccessSnackBar('Lokasi berhasil disimpan');
                      } catch (e) {
                        _showErrorSnackBar('Error: $e');
                      }
                    } else {
                      _showErrorSnackBar('Pilih provinsi dan kota');
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

  Widget _buildUserForm() {
    return Card(
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
    );
  }

  Widget _buildUserList() {
    return Card(
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
    );
  }

  // UTILITY METHODS
  // ==============
  void _clearForm() {
    _usernameController.clear();
    _passwordController.clear();
    setState(() => _selectedRole = 'user');
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  // BUILD METHOD
  // ===========
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

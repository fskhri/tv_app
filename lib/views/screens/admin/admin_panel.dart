import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/api_service.dart';
import '../../../models/user.dart';
import '../../../controllers/auth_controller.dart';

class AdminPanel extends StatefulWidget {
  @override
  _AdminPanelState createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  int _selectedIndex = 0;
  bool _isLoading = false;
  List<User> _users = [];
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'user';

  @override
  void initState() {
    super.initState();
    _loadUsers();
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
        
        await apiService.createUser(newUser, _passwordController.text);
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
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _deleteUser(user.id),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
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
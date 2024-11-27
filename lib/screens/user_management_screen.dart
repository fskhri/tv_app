import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import '../controllers/auth_controller.dart';

class UserManagementScreen extends StatefulWidget {
  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<User> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadUsers();
    });
  }

  Future<void> loadUsers() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final loadedUsers = await apiService.getUsers();
      setState(() {
        users = loadedUsers;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading users: $e'))
      );
    }
  }

  Future<void> _updateUserStatus(User user, bool isActive) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final updatedUser = User(
        id: user.id,
        username: user.username,
        role: user.role,
        isActive: isActive,
      );
      await apiService.updateUser(updatedUser);
      loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating user: $e'))
      );
    }
  }

  Future<void> _deleteUser(User user) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.deleteUser(user.id);
      loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting user: $e'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manajemen User'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showAddUserDialog(context),
          ),
        ],
      ),
      body: isLoading
        ? Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: Icon(Icons.person),
                title: Text(user.username),
                subtitle: Text('Role: ${user.role}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: user.isActive,
                      onChanged: (value) => _updateUserStatus(user, value),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => _deleteUser(user),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }

  Future<void> _showAddUserDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    String username = '';
    String password = '';
    String role = 'user';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tambah User'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Username'),
                validator: (value) => 
                  value?.isEmpty ?? true ? 'Username tidak boleh kosong' : null,
                onSaved: (value) => username = value ?? '',
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) => 
                  value?.isEmpty ?? true ? 'Password tidak boleh kosong' : null,
                onSaved: (value) => password = value ?? '',
              ),
              DropdownButtonFormField<String>(
                value: role,
                decoration: InputDecoration(labelText: 'Role'),
                items: ['admin', 'user'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) => role = value ?? 'user',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text('Batal'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: Text('Simpan'),
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                formKey.currentState?.save();
                try {
                  final apiService = Provider.of<ApiService>(context, listen: false);
                  await apiService.createUser(
                    username,
                    password,
                    role,
                  );
                  Navigator.pop(context);
                  loadUsers();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error creating user: $e'))
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
} 
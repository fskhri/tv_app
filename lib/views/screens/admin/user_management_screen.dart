import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/user_model.dart';
import '../../../repositories/user_repository.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<UserModel> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final userRepo = Provider.of<UserRepository>(context, listen: false);
    final users = await userRepo.getAllUsers();
    setState(() {
      _users = users;
    });
  }

  Future<void> _showAddEditUserDialog([UserModel? user]) async {
    final formKey = GlobalKey<FormState>();
    final usernameController = TextEditingController(text: user?.username);
    final passwordController = TextEditingController();
    String selectedRole = user?.role ?? 'user';
    String? selectedMosqueId = user?.mosqueId;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user == null ? 'Tambah User' : 'Edit User'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: usernameController,
                decoration: InputDecoration(labelText: 'Username'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Username harus diisi';
                  }
                  return null;
                },
              ),
              if (user == null) // Password hanya untuk user baru
                TextFormField(
                  controller: passwordController,
                  decoration: InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password harus diisi';
                    }
                    return null;
                  },
                ),
              DropdownButtonFormField<String>(
                value: selectedRole,
                items: ['admin', 'user'].map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedRole = value!;
                },
                decoration: InputDecoration(labelText: 'Role'),
              ),
              // TODO: Tambahkan dropdown untuk memilih masjid
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final userRepo = Provider.of<UserRepository>(context, listen: false);
                
                if (user == null) {
                  // Tambah user baru
                  await userRepo.createUser(
                    username: usernameController.text,
                    password: passwordController.text,
                    role: selectedRole,
                    mosqueId: selectedMosqueId,
                  );
                } else {
                  // Update user yang ada
                  final updatedUser = UserModel(
                    id: user.id,
                    username: usernameController.text,
                    role: selectedRole,
                    mosqueId: selectedMosqueId,
                    createdAt: user.createdAt,
                    updatedAt: DateTime.now(),
                  );
                  await userRepo.updateUser(updatedUser);
                }
                
                Navigator.pop(context);
                _loadUsers();
              }
            },
            child: Text(user == null ? 'Tambah' : 'Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manajemen User'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditUserDialog(),
        child: Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return ListTile(
            title: Text(user.username),
            subtitle: Text('Role: ${user.role.toUpperCase()}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => _showAddEditUserDialog(user),
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Konfirmasi'),
                        content: Text('Yakin ingin menghapus user ini?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text('Batal'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text('Hapus'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      final userRepo = Provider.of<UserRepository>(context, listen: false);
                      await userRepo.deleteUser(user.id!);
                      _loadUsers();
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 
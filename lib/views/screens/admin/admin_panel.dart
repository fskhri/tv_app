import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/api_service.dart';
import '../../../models/user.dart';
import '../../../models/user_location.dart';
import '../../../controllers/auth_controller.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

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
  final _contentTitleController = TextEditingController();
  final _contentDescriptionController = TextEditingController();

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

  final ImagePicker _picker = ImagePicker();
  List<File> _selectedImages = [];

  // Tambahkan property untuk menyimpan konten
  List<Map<String, dynamic>> _userContents = [];

  File? _selectedFile;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _durationController = TextEditingController();

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
    _contentTitleController.dispose();
    _contentDescriptionController.dispose();
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

  // Tambahkan method untuk memuat konten
  Future<void> _loadUserContents(String userId) async {
    try {
      setState(() => _isLoading = true);
      final apiService = Provider.of<ApiService>(context, listen: false);
      final contents = await apiService.getUserContents(userId);
      setState(() => _userContents = contents);
    } catch (e) {
      _showErrorSnackBar('Error loading contents: $e');
    } finally {
      setState(() => _isLoading = false);
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
                        value: province['name'],
                        child: Text(province['name']!.toLowerCase()),
                      );
                    }).toList(),
                    onChanged: (value) async {
                      setState(() {
                        _selectedProvince = value;
                        _selectedCity = null;
                      });
                      if (value != null) {
                        await _loadCities(value);
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
                          value: city['name'],
                          child: Text(city['name']!.toLowerCase()),
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
                        final apiService =
                            Provider.of<ApiService>(context, listen: false);

                        await apiService.saveUserLocation(
                          userId,
                          _selectedProvince!,
                          _selectedCity!,
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
      setState(() {
        _selectedProvince = normalizedProvince;
      });
      await _loadCities(normalizedProvince);

      if (location.city.isNotEmpty) {
        setState(() {
          _selectedCity = location.city;
        });
      }
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
                return ExpansionTile(
                  title: Text(user.username),
                  subtitle: Text('Role: ${user.role}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tambahkan tombol lokasi
                      IconButton(
                        icon: Icon(Icons.location_on),
                        onPressed: () => _showAddLocationDialog(user.id),
                        tooltip: 'Set Lokasi',
                      ),
                      IconButton(
                        icon: Icon(Icons.upload_file),
                        onPressed: () => _showUploadContentDialog(user.id),
                        tooltip: 'Upload Konten',
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _deleteUser(user.id),
                        tooltip: 'Hapus User',
                      ),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildContentList(user.id),
                          SizedBox(height: 16),
                          _buildUploadedImages(user.id),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  // Tambahkan widget untuk menampilkan konten
  Widget _buildContentList(String userId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _userContents.length,
          itemBuilder: (context, index) {
            final content = _userContents[index];
            return Card(
              margin: EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                title: Text(content['title']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(content['description'] ?? ''),
                    if (content['image_urls_full'] != null &&
                        (content['image_urls_full'] as List).isNotEmpty)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: (content['image_urls_full'] as List)
                              .map((url) => Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Image.network(
                                      url,
                                      height: 60,
                                      width: 60,
                                      fit: BoxFit.cover,
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _deleteContent(content['id']),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // Tambahkan method untuk menghapus konten
  Future<void> _deleteContent(int contentId) async {
    // Implementasi penghapusan konten akan ditambahkan nanti
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

  // Tambahkan method untuk menampilkan dialog upload content
  void _showUploadContentDialog(String userId) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              child: Container(
                width: 400, // Tetapkan lebar dialog
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Upload Konten',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _contentTitleController,
                      decoration: InputDecoration(labelText: 'Judul Konten'),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: _contentDescriptionController,
                      decoration: InputDecoration(labelText: 'Deskripsi'),
                      maxLines: 3,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await _pickImages();
                        setState(() {});
                      },
                      icon: Icon(Icons.image),
                      label: Text('Pilih Gambar'),
                    ),
                    if (_selectedImages.isNotEmpty) ...[
                      SizedBox(height: 8),
                      Text('${_selectedImages.length} gambar dipilih'),
                      SizedBox(
                        height: 120,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _selectedImages.map((image) {
                              return Stack(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Image.file(
                                      image,
                                      height: 100,
                                      width: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: IconButton(
                                      icon:
                                          Icon(Icons.close, color: Colors.red),
                                      onPressed: () {
                                        setState(() {
                                          _selectedImages.remove(image);
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            _contentTitleController.clear();
                            _contentDescriptionController.clear();
                            _selectedImages.clear();
                            Navigator.pop(context);
                          },
                          child: Text('Batal'),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              print('Memulai proses upload dari dialog...');

                              if (_contentTitleController.text.isEmpty) {
                                print('Error: Judul kosong');
                                throw Exception('Judul tidak boleh kosong');
                              }

                              if (_selectedImages.isEmpty) {
                                print('Error: Tidak ada gambar yang dipilih');
                                throw Exception('Pilih minimal 1 gambar');
                              }

                              print(
                                  'Validasi berhasil, melanjutkan ke proses upload');
                              print('Judul: ${_contentTitleController.text}');
                              print(
                                  'Deskripsi: ${_contentDescriptionController.text}');
                              print('Jumlah gambar: ${_selectedImages.length}');

                              final apiService = Provider.of<ApiService>(
                                  context,
                                  listen: false);
                              await apiService.uploadContent(
                                userId,
                                _contentTitleController.text,
                                _contentDescriptionController.text,
                                _selectedImages,
                              );

                              print('Upload selesai, membersihkan form...');
                              Navigator.pop(context);
                              _contentTitleController.clear();
                              _contentDescriptionController.clear();
                              _selectedImages.clear();

                              _showSuccessSnackBar('Konten berhasil diupload');
                              print('Proses upload selesai dengan sukses');
                            } catch (e) {
                              print('Error dalam proses upload: $e');
                              _showErrorSnackBar(e.toString());
                            }
                          },
                          child: Text('Upload'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile>? images = await _picker.pickMultiImage();
      if (images != null && images.isNotEmpty) {
        setState(() {
          _selectedImages = images.map((image) => File(image.path)).toList();
        });
      }
    } catch (e) {
      print('Error picking images: $e');
      _showErrorSnackBar('Error memilih gambar: $e');
    }
  }

  Future<void> _uploadContent() async {
    if (_formKey.currentState!.validate() && _selectedFile != null) {
      try {
        final apiService = Provider.of<ApiService>(context, listen: false);
        final response = await apiService.uploadContentFile(
          contentFile: _selectedFile!,
          title: _titleController.text,
          description: _descriptionController.text,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gambar berhasil diupload')),
        );

        // Reset form
        _formKey.currentState!.reset();
        setState(() {
          _selectedFile = null;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengupload gambar: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.image, allowMultiple: false);

    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Widget _buildUploadedImages(String userId) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: Provider.of<ApiService>(context, listen: false)
          .getUploadedImages(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('Belum ada gambar yang diupload'));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Gambar yang Sudah Diupload',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final image = snapshot.data![index];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _showImageDetails(image),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Image.network(
                            image['imageUrl'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(child: Icon(Icons.error));
                            },
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(4),
                          child: Text(
                            image['title'] ?? 'No Title',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showImageDetails(Map<String, dynamic> image) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                image['title'] ?? 'No Title',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 8),
              if (image['description'] != null) ...[
                Text(
                  image['description'],
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: 8),
              ],
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  image['imageUrl'],
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Diupload pada: ${DateTime.parse(image['uploadDate']).toLocal()}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Tutup'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Tambahkan method ini di dalam class _AdminPanelState
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

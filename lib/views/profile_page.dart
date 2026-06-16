import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  final String name;
  final String role;
  final String email;

  const ProfilePage({
    super.key,
    required this.name,
    required this.role,
    required this.email,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();
  
  bool _isLoading = false;
  bool _isUploading = false;
  bool _isEditing = false;
  Map<String, dynamic>? _userProfile;
  String? _profileImageUrl;
  File? _selectedImage;

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _programmeController;
  late TextEditingController _batchController;
  late TextEditingController _departmentController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _phoneController = TextEditingController();
    _programmeController = TextEditingController();
    _batchController = TextEditingController();
    _departmentController = TextEditingController();
    _loadUserProfile();
    _loadProfileImage();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _programmeController.dispose();
    _batchController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        final response = await supabase
            .from('profiles')
            .select()
            .eq('id', userId)
            .maybeSingle();
        _userProfile = response;
        
        if (response != null) {
          _nameController.text = response['name'] ?? widget.name;
          _phoneController.text = response['phone'] ?? '';
          _programmeController.text = response['programme'] ?? '';
          _batchController.text = response['batch'] ?? '';
          _departmentController.text = response['department'] ?? '';
          if (response['avatar_url'] != null) {
            _profileImageUrl = response['avatar_url'];
          }
        }
      }
    } catch (e) {
      print('Error loading profile: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadProfileImage() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    
    try {
      final response = await supabase
          .from('profiles')
          .select('avatar_url')
          .eq('id', userId)
          .maybeSingle();
      
      if (response != null && response['avatar_url'] != null) {
        setState(() {
          _profileImageUrl = response['avatar_url'];
        });
      }
    } catch (e) {
      print('Error loading profile image: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 500,
        maxHeight: 500,
      );
      
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        await _uploadImage();
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to pick image'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;
    
    setState(() => _isUploading = true);
    
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');
      
      // Use a unique file name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '$userId/profile_$timestamp.jpg';
      
      // Upload to storage
      await supabase.storage
          .from('avatars')
          .upload(filePath, _selectedImage!);
      
      // Get public URL
      final imageUrl = supabase.storage.from('avatars').getPublicUrl(filePath);
      
      // Save URL to profiles table
      await supabase
          .from('profiles')
          .update({'avatar_url': imageUrl})
          .eq('id', userId);
      
      setState(() {
        _profileImageUrl = imageUrl;
        _selectedImage = null;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _removeProfileImage() async {
    setState(() => _isUploading = true);
    
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');
      
      // Remove URL from profiles table
      await supabase
          .from('profiles')
          .update({'avatar_url': null})
          .eq('id', userId);
      
      setState(() {
        _profileImageUrl = null;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture removed'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error removing image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            if (_profileImageUrl != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Profile Picture', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _removeProfileImage();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');
      
      final Map<String, dynamic> updateData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
      };
      
      if (widget.role == 'student') {
        updateData['programme'] = _programmeController.text.trim();
        updateData['batch'] = _batchController.text.trim();
      } else {
        updateData['department'] = _departmentController.text.trim();
      }
      
      await supabase
          .from('profiles')
          .update(updateData)
          .eq('id', userId);
      
      setState(() {
        _isEditing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      await _loadUserProfile();
      
    } catch (e) {
      print('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'student': return const Color(0xFF1565C0);
      case 'lecturer': return const Color(0xFF2E7D32);
      case 'registrar': return const Color(0xFF6A1B9A);
      case 'treasury': return const Color(0xFFE65100);
      case 'pusat_adab': return const Color(0xFF00838F);
      default: return Colors.blue;
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'student': return 'Student';
      case 'lecturer': return 'Lecturer';
      case 'registrar': return 'Registrar';
      case 'treasury': return 'Treasury';
      case 'pusat_adab': return 'Pusat Adab';
      default: return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleColor = _getRoleColor(widget.role);
    final isStudent = widget.role == 'student';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: roleColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveProfile,
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _loadUserProfile();
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: roleColor,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _showImageOptions,
                          child: Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: _isUploading
                                      ? Center(
                                          child: CircularProgressIndicator(
                                            color: roleColor,
                                          ),
                                        )
                                      : (_profileImageUrl != null
                                          ? Image.network(
                                              _profileImageUrl!,
                                              width: 100,
                                              height: 100,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Icon(
                                                  Icons.person,
                                                  size: 50,
                                                  color: roleColor,
                                                );
                                              },
                                            )
                                          : Icon(
                                              Icons.person,
                                              size: 50,
                                              color: roleColor,
                                            )),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.camera_alt,
                                    size: 18,
                                    color: roleColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        if (_isEditing)
                          SizedBox(
                            width: 250,
                            child: TextField(
                              controller: _nameController,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter your name',
                                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.white),
                                ),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        else
                          Text(
                            _nameController.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getRoleLabel(widget.role),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildDetailCard(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: widget.email,
                          iconColor: roleColor,
                        ),
                        _buildEditableDetailCard(
                          icon: Icons.phone_outlined,
                          label: 'Phone',
                          controller: _phoneController,
                          iconColor: roleColor,
                        ),
                        _buildDetailCard(
                          icon: Icons.badge_outlined,
                          label: 'Role',
                          value: _getRoleLabel(widget.role),
                          iconColor: roleColor,
                        ),
                        if (isStudent) ...[
                          _buildEditableDetailCard(
                            icon: Icons.school_outlined,
                            label: 'Programme',
                            controller: _programmeController,
                            iconColor: roleColor,
                          ),
                          _buildEditableDetailCard(
                            icon: Icons.calendar_today_outlined,
                            label: 'Batch',
                            controller: _batchController,
                            iconColor: roleColor,
                          ),
                        ] else ...[
                          _buildEditableDetailCard(
                            icon: Icons.business_outlined,
                            label: 'Department',
                            controller: _departmentController,
                            iconColor: roleColor,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        subtitle: Text(
          value.isEmpty ? 'Not provided' : value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildEditableDetailCard({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required Color iconColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        subtitle: _isEditing
            ? TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Enter $label',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              )
            : Text(
                controller.text.isEmpty ? 'Not provided' : controller.text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );
  }
}
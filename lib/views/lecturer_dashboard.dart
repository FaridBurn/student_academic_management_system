import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ManageRegistration/login_page.dart';
import 'ManageAttendance/session_dashboard_page.dart';
import 'profile_page.dart';
import 'my_students_page.dart';
import 'my_subjects_page.dart';

class LecturerHome extends StatefulWidget {
  final String name;
  final String email;
  const LecturerHome({super.key, required this.name, required this.email});

  @override
  State<LecturerHome> createState() => _LecturerHomeState();
}

class _LecturerHomeState extends State<LecturerHome> {
  String? _profileImageUrl;
  bool _isLoadingImage = true;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final response = await Supabase.instance.client
            .from('profiles')
            .select('avatar_url')
            .eq('id', userId)
            .maybeSingle();
        
        setState(() {
          _profileImageUrl = response?['avatar_url'];
          _isLoadingImage = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile image: $e');
      setState(() => _isLoadingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F1),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF2E7D32),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfilePage(
                            name: widget.name,
                            role: 'lecturer',
                            email: Supabase.instance.client.auth.currentUser?.email ?? '',
                          ),
                        ),
                      ).then((_) => _loadProfileImage());
                    },
                    child: Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _isLoadingImage
                            ? const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              )
                            : (_profileImageUrl != null
                                ? Image.network(
                                    _profileImageUrl!,
                                    width: 55,
                                    height: 55,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.person,
                                        size: 30,
                                        color: Color(0xFF2E7D32),
                                      );
                                    },
                                  )
                                : const Icon(
                                    Icons.person,
                                    size: 30,
                                    color: Color(0xFF2E7D32),
                                  )),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome back,',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          widget.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Lecturer',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: () async {
                      await Supabase.instance.client.auth.signOut();
                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _menuCard(Icons.qr_code, 'Generate\nAttendance Code', const Color(0xFF388E3C), () {
                      Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const SessionDashboardPage()));
                    }),
                    _menuCard(Icons.people, 'My\nStudents', const Color(0xFF00796B), () {
  Navigator.push(context, MaterialPageRoute(builder: (_) => MyStudentsPage(lecturerEmail: widget.email)));
}),
                    _menuCard(Icons.bar_chart, 'Attendance\nReport', const Color(0xFF0288D1), () {
                      Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const SessionDashboardPage()));
                    }),
                    _menuCard(Icons.book, 'My\nSubjects', const Color(0xFF558B2F), () {
  Navigator.push(context, MaterialPageRoute(builder: (_) => MySubjectsPage(lecturerEmail: widget.email)));
}),
                    _menuCard(Icons.person, 'My\nProfile', const Color(0xFF5E35B1), () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfilePage(
                            name: widget.name,
                            role: 'lecturer',
                            email: Supabase.instance.client.auth.currentUser?.email ?? '',
                          ),
                        ),
                      ).then((_) => _loadProfileImage());
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuCard(IconData icon, String label, Color cardColor, [VoidCallback? onTap]) {
    return Card(
      elevation: 4,
      shadowColor: cardColor.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap ?? () {},
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [cardColor, cardColor.withValues(alpha: 0.8)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 44, color: Colors.white),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
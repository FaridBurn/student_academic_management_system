import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'subject_list_page.dart';
import 'timetable_view_page.dart';
import 'profile_page.dart';
import 'manage_curriculum_activities/available_activities.dart';
import 'attendance/student/student_checkin_page.dart';
import 'tuition_fee/tuitionfee_dashboard_page.dart';

class StudentHome extends StatefulWidget {
  final String name;
  const StudentHome({super.key, required this.name});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
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
      backgroundColor: const Color(0xFFF0F4FF),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF1565C0),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  // Profile Avatar with actual image
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfilePage(
                            name: widget.name,
                            role: 'student',
                            email: Supabase.instance.client.auth.currentUser?.email ?? '',
                          ),
                        ),
                      ).then((_) => _loadProfileImage()); // Refresh on return
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
                                    color: Color(0xFF1565C0),
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
                                        color: Color(0xFF1565C0),
                                      );
                                    },
                                  )
                                : const Icon(
                                    Icons.person,
                                    size: 30,
                                    color: Color(0xFF1565C0),
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
                            'Student',
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
                    _menuCard(context, Icons.app_registration, 'Subject\nRegistration', const Color(0xFF1976D2), () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SubjectListPage()),
                      );
                    }),
                    _menuCard(context, Icons.book, 'My\nSubjects', const Color(0xFF388E3C), () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TimetableViewPage()),
                      );
                    }),
                    _menuCard(context, Icons.qr_code_scanner, 'Check\nAttendance', const Color(0xFF0288D1), () {
                      Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const StudentCheckinPage()));
                    }),
                    _menuCard(context, Icons.sports, 'Curriculum\nActivities', const Color(0xFF0097A7),
                        () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CurriculumHomeScreen(name: widget.name),
                              ),
                            )),
                    _menuCard(context, Icons.payment, 'Tuition\nFees', const Color(0xFFD32F2F), () {
                      final studentId = Supabase.instance.client.auth.currentUser!.id;
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => TuitionFeeDashboardPage(
                          studentUid: studentId,
                          studentName: widget.name,
                        ),
                      ));
                    }),
                    _menuCard(context, Icons.person, 'My\nProfile', const Color(0xFF5E35B1), () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfilePage(
                            name: widget.name,
                            role: 'student',
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

  Widget _menuCard(BuildContext context, IconData icon, String label, Color cardColor, VoidCallback? onTap) {
    return Card(
      elevation: 4,
      shadowColor: cardColor.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
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
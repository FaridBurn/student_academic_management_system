import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ManageRegistration/login_page.dart';
import 'profile_page.dart';
import 'ManageCurriculumActivities/curriculum_activities.dart';
import 'ManageCurriculumActivities/activity_verification_page.dart';
import 'ManageCurriculumActivities/student_credits.dart';
import 'ManageCurriculumActivities/activity_report.dart';

class PusatAdabHome extends StatefulWidget {
  final String name;
  const PusatAdabHome({super.key, required this.name});

  @override
  State<PusatAdabHome> createState() => _PusatAdabHomeState();
}

class _PusatAdabHomeState extends State<PusatAdabHome> {
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
      } else {
        setState(() => _isLoadingImage = false);
      }
    } catch (e) {
      print('Error loading profile image: $e');
      setState(() => _isLoadingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F7FA),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF00838F),
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
                            role: 'pusat_adab',
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
                                    color: Color(0xFF00838F),
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
                                        color: Color(0xFF00838F),
                                      );
                                    },
                                  )
                                : const Icon(
                                    Icons.person,
                                    size: 30,
                                    color: Color(0xFF00838F),
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
                            'Pusat Adab',
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
                    _menuCard(
                      context,
                      Icons.emoji_events,
                      'Curriculum\nActivities',
                      const Color(0xFF00838F),
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CurriculumActivitiesScreen(),
                        ),
                      ),
                    ),
                    _menuCard(
                      context,
                      Icons.check_circle,
                      'Approve\nClaims',
                      const Color(0xFF00695C),
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ActivityVerificationScreen(),
                        ),
                      ),
                    ),
                    _menuCard(
                      context,
                      Icons.people,
                      'Student\nCredits',
                      const Color(0xFF1565C0),
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StudentCreditsScreen(),
                        ),
                      ),
                    ),
                    _menuCard(
                      context,
                      Icons.bar_chart,
                      'Activity\nReport',
                      const Color(0xFF558B2F),
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ActivityReportScreen(),
                        ),
                      ),
                    ),
                    _menuCard(
                      context,
                      Icons.add_box,
                      'Add\nActivity',
                      const Color(0xFF6A1B9A),
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CurriculumActivitiesScreen(),
                        ),
                      ),
                    ),
                    _menuCard(
                      context,
                      Icons.person,
                      'My\nProfile',
                      const Color(0xFF37474F),
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfilePage(
                              name: widget.name,
                              role: 'pusat_adab',
                              email: Supabase.instance.client.auth.currentUser?.email ?? '',
                            ),
                          ),
                        ).then((_) => _loadProfileImage());
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuCard(
    BuildContext context,
    IconData icon,
    String label,
    Color cardColor,
    VoidCallback? onTap,
  ) {
    return Card(
      elevation: 4,
      shadowColor: cardColor.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
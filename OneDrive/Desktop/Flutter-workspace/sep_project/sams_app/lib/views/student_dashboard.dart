import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'manage_curriculum_activities/available_activities.dart';

class StudentHome extends StatelessWidget {
  final String name;
  const StudentHome({super.key, required this.name});
  static const color = Color(0xFF1565C0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: color,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Welcome back,',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                    Text(name, style: const TextStyle(
                        color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    const Text('Student',
                        style: TextStyle(color: Colors.white60, fontSize: 12)),
                  ]),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: () async {
                      await Supabase.instance.client.auth.signOut();
                      Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()));
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
                    _menuCard(context, Icons.app_registration, 'Subject\nRegistration', const Color(0xFF1976D2), null),
                    _menuCard(context, Icons.qr_code_scanner,  'Check\nAttendance',     const Color(0xFF0288D1), null),
                    _menuCard(context, Icons.sports,           'Curriculum\nActivities', const Color(0xFF0097A7),
                        () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CurriculumHomeScreen(name: name), // 👈 pass name here
                              ),
                            )),
                    _menuCard(context, Icons.payment,          'Tuition\nFees',          const Color(0xFFD32F2F), null),
                    _menuCard(context, Icons.book,             'My\nSubjects',            const Color(0xFF388E3C), null),
                    _menuCard(context, Icons.person,           'My\nProfile',             const Color(0xFF5E35B1), null),
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
      shadowColor: cardColor.withOpacity(0.4),
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
              colors: [cardColor, cardColor.withOpacity(0.8)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 44, color: Colors.white),
              const SizedBox(height: 10),
              Text(label, textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
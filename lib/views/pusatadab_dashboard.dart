import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'manage_curriculum_activities/curriculum_activities.dart';
import 'manage_curriculum_activities/activity_verification.dart';

class PusatAdabHome extends StatelessWidget {
  final String name;
  const PusatAdabHome({super.key, required this.name});
  static const color = Color(0xFF00838F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _menuCard(context, Icons.emoji_events,  'Curriculum\nActivities', const Color(0xFF00838F),
                        () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => const CurriculumActivitiesScreen()))),
                    _menuCard(context, Icons.check_circle,  'Approve\nClaims',        const Color(0xFF00695C),
                        () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => const ActivityVerificationScreen()))),
                    _menuCard(context, Icons.people,        'Student\nCredits',       const Color(0xFF1565C0), null),
                    _menuCard(context, Icons.bar_chart,     'Activity\nReport',       const Color(0xFF558B2F), null),
                    _menuCard(context, Icons.add_box,       'Add\nActivity',          const Color(0xFF6A1B9A),
                        () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => const CurriculumActivitiesScreen()))),
                    _menuCard(context, Icons.person,        'My\nProfile',            const Color(0xFF37474F), null),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
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
            const Text('Pusat Adab',
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
                  style: const TextStyle(color: Colors.white,
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
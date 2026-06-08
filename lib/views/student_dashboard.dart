import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/registration_controller.dart';
import 'subject_list_page.dart';
import 'registration_cart_page.dart';
import 'timetable_view_page.dart';
import 'login_page.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegistrationCartPage()),
              );
            },
          ),
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildDashboardCard(
            context,
            'Subject Registration',
            Icons.assignment,
            Colors.blue,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SubjectListPage()),
            ),
          ),
          _buildDashboardCard(
            context,
            'My Timetable',
            Icons.calendar_month,
            Colors.teal,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TimetableViewPage()),
            ),
          ),
          _buildDashboardCard(
            context,
            'Tuition Fees',
            Icons.payment,
            Colors.green,
            () => {}, // Module 3 later
          ),
          _buildDashboardCard(
            context,
            'Curriculum Activities',
            Icons.emoji_events,
            Colors.orange,
            () => {}, // Module 2 later
          ),
          _buildDashboardCard(
            context,
            'Attendance',
            Icons.fingerprint,
            Colors.purple,
            () => {}, // Module 4 later
          ),
          _buildDashboardCard(
            context,
            'Logout',
            Icons.logout,
            Colors.red,
            () {
              context.read<RegistrationController>().logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
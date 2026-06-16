import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
<<<<<<< HEAD
import 'profile_page.dart';
import 'login_page.dart';
import 'ManageTuitionFees/treasury_fee_overview_page.dart';
import 'ManageTuitionFees/send_reminders_page.dart';
import 'ManageTuitionFees/blocked_students_page.dart';
import 'ManageTuitionFees/payment_report_page.dart';
import 'ManageTuitionFees/verify_payments_page.dart';
=======
import 'login_page.dart';
import 'profile_page.dart';
import 'manage_tuition_fees/treasury_fee_overview_page.dart';
import 'manage_tuition_fees/send_reminders_page.dart';
import 'manage_tuition_fees/blocked_students_page.dart';
import 'manage_tuition_fees/payment_report_page.dart';
import 'manage_tuition_fees/verify_payments_page.dart';
>>>>>>> 51f7658097679a1ca70072b0812edc867825ee55

class TreasuryHome extends StatefulWidget {
  final String name;
  const TreasuryHome({super.key, required this.name});

  @override
  State<TreasuryHome> createState() => _TreasuryHomeState();
}

class _TreasuryHomeState extends State<TreasuryHome> {
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
      debugPrint('Error loading profile image: $e');
      setState(() => _isLoadingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFE65100),
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
                            role: 'treasury',
                            email:
                                Supabase
                                    .instance
                                    .client
                                    .auth
                                    .currentUser
                                    ?.email ??
                                '',
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
                                    color: Color(0xFFE65100),
                                  ),
                                ),
                              )
                            : (_profileImageUrl != null
                                  ? Image.network(
                                      _profileImageUrl!,
                                      width: 55,
                                      height: 55,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return const Icon(
                                              Icons.person,
                                              size: 30,
                                              color: Color(0xFFE65100),
                                            );
                                          },
                                    )
                                  : const Icon(
                                      Icons.person,
                                      size: 30,
                                      color: Color(0xFFE65100),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Treasury',
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
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
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
                      Icons.receipt_long,
                      'Fee\nRecords',
                      const Color(0xFFEF6C00),
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TreasuryFeeOverviewPage(),
                          ),
                        );
                      },
                    ),
                    _menuCard(
                      Icons.notifications,
                      'Send\nReminders',
                      const Color(0xFFF57C00),
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SendRemindersPage(),
                          ),
                        );
                      },
                    ),
                    _menuCard(
                      Icons.block,
                      'Blocked\nStudents',
                      const Color(0xFFC62828),
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BlockedStudentsPage(),
                          ),
                        );
                      },
                    ),
                    _menuCard(
                      Icons.bar_chart,
                      'Payment\nReport',
                      const Color(0xFF2E7D32),
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PaymentReportPage(),
                          ),
                        );
                      },
                    ),
                    _menuCard(
                      Icons.price_check,
                      'Verify\nPayments',
                      const Color(0xFF00838F),
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const VerifyPaymentsPage(),
                          ),
                        );
                      },
                    ),
                    _menuCard(
                      Icons.person,
                      'My\nProfile',
                      const Color(0xFF5E35B1),
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfilePage(
                              name: widget.name,
                              role: 'treasury',
                              email:
                                  Supabase
                                      .instance
                                      .client
                                      .auth
                                      .currentUser
                                      ?.email ??
                                  '',
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
    IconData icon,
    String label,
    Color cardColor, [
    VoidCallback? onTap,
  ]) {
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
<<<<<<< HEAD
}
=======
}
>>>>>>> 51f7658097679a1ca70072b0812edc867825ee55

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/registration_controller.dart';
import 'registration_success_page.dart';
import 'registration_error_page.dart';

class RegistrationConfirmationPage extends StatefulWidget {
  const RegistrationConfirmationPage({super.key});

  @override
  State<RegistrationConfirmationPage> createState() => _RegistrationConfirmationPageState();
}

class _RegistrationConfirmationPageState extends State<RegistrationConfirmationPage> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final student = context.watch<RegistrationController>().currentStudent;
    
    if (student == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F7),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 64, color: Colors.blueGrey),
                    const SizedBox(height: 20),
                    const Text(
                      'Authentication Required',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1F36)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please sign in to your terminal account to proceed with course verification.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A1F36),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Go to Login', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    const currentSemester = 'Sem1';
    const currentAcademicYear = '2025/2026';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text(
          'Confirm Registration',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        backgroundColor: const Color(0xFF1A1F36),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<RegistrationController>(
        builder: (context, controller, child) {
          if (controller.currentStudent == null) {
            return const Center(child: Text('Please login first'));
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.badge_outlined, size: 20, color: Color(0xFF1565C0)),
                                  SizedBox(width: 8),
                                  Text(
                                    'Student Information',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1F36)),
                                  ),
                                ],
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 10.0),
                                child: Divider(color: Color(0xFFEEEEEE), height: 1),
                              ),
                              _buildInfoRow('Name', controller.currentStudent?.stu_name ?? ''),
                              _buildInfoRow('Student ID', controller.currentStudent?.studentID.toString() ?? ''),
                              _buildInfoRow('Programme', controller.currentStudent?.stu_programme ?? ''),
                              _buildInfoRow('Semester', currentSemester),
                              _buildInfoRow('Academic Year', currentAcademicYear),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.menu_book_rounded, size: 20, color: Color(0xFF1565C0)),
                                  SizedBox(width: 8),
                                  Text(
                                    'Selected Subjects',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1F36)),
                                  ),
                                ],
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 10.0),
                                child: Divider(color: Color(0xFFEEEEEE), height: 1),
                              ),
                              ...controller.cartItems.map((subject) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                subject.sub_name,
                                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1F36)),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                subject.sub_code,
                                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE3F2FD),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '${subject.credit_hours} Credits',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1565C0)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12.0),
                                child: Divider(color: Color(0xFFEEEEEE), height: 1),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total Cumulative Workload:',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1A1F36)),
                                  ),
                                  Text(
                                    '${controller.totalCartCredits} / 20 Credits',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: heightIndexedOutlinedButton(
                          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                          child: const Text('Back to Cart', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: heightIndexedElevatedButton(
                          onPressed: _isSubmitting
                              ? null
                              : () async {
                                  setState(() => _isSubmitting = true);
                                  print('Submit button clicked');
                                  final success = await controller.submitRegistration(
                                    currentSemester,
                                    currentAcademicYear,
                                  );
                                  print('Registration success: $success');

                                  if (!context.mounted) return;
                                  setState(() => _isSubmitting = false);

                                  if (success) {
                                    print('Navigating to success page');
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (_) => const RegistrationSuccessPage()),
                                    );
                                  } else {
                                    print('Navigating to error page');
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const RegistrationErrorPage(
                                          errorMessage: 'Registration execution failed. Please verify conditions and try again.',
                                        ),
                                      ),
                                    );
                                  }
                                },
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                                )
                              : const Text('Submit Ledger', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF1A1F36), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget heightIndexedOutlinedButton({required VoidCallback? onPressed, required Widget child}) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF1A1F36),
          side: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: child,
      ),
    );
  }

  Widget heightIndexedElevatedButton({required VoidCallback? onPressed, required Widget child}) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFE0E0E0),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: child,
      ),
    );
  }
}
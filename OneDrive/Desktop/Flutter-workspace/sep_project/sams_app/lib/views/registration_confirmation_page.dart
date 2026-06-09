import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/registration_controller.dart';
import 'registration_success_page.dart';
import 'registration_error_page.dart';

class RegistrationConfirmationPage extends StatelessWidget {
  const RegistrationConfirmationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<RegistrationController>();
    final currentSemester = 'Sem1';
    const currentAcademicYear = '2025/2026';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Registration'),
      ),
      body: Consumer<RegistrationController>(
        builder: (context, controller, child) {
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Student Information',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const Divider(),
                            _buildInfoRow('Name', controller.currentStudent?.stu_name ?? ''),
                            _buildInfoRow('ID', controller.currentStudent?.studentID.toString() ?? ''),
                            _buildInfoRow('Programme', controller.currentStudent?.stu_programme ?? ''),
                            _buildInfoRow('Semester', currentSemester),
                            _buildInfoRow('Academic Year', currentAcademicYear),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Selected Subjects',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const Divider(),
                            ...controller.cartItems.map((subject) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${subject.sub_code} - ${subject.sub_name}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  Text('${subject.credit_hours} credits'),
                                ],
                              ),
                            )),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total Credits:',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${controller.totalCartCredits}',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Back to Cart'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final success = await controller.submitRegistration(
                            currentSemester,
                            currentAcademicYear,
                          );
                          
                          if (!context.mounted) return;
                          
                          if (success) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const RegistrationSuccessPage()),
                            );
                          } else {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegistrationErrorPage(
                                  errorMessage: 'Registration failed. Please try again.',
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.green,
                        ),
                        child: const Text('Submit Registration'),
                      ),
                    ),
                  ],
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
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
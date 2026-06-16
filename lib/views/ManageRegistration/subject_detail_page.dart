import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/subject.dart';
import '../../controllers/registration_controller.dart';

class SubjectDetailPage extends StatelessWidget {
  final Subject subject;

  const SubjectDetailPage({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    final isInCart = context.watch<RegistrationController>().cartItems.any(
          (item) => item.subjectID == subject.subjectID,
        );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text(
          subject.sub_code,
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        backgroundColor: const Color(0xFF1A1F36),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject.sub_name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1F36),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'COURSE SPECIFICATIONS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.blueGrey,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildInfoRow(Icons.code_rounded, 'Subject Code', subject.sub_code),
                      _buildInfoRow(Icons.hourglass_empty_rounded, 'Credit Hours', '${subject.credit_hours} Credits'),
                      _buildInfoRow(Icons.calendar_today_rounded, 'Semester', subject.sub_semester),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Divider(color: Color(0xFFEEEEEE), height: 1),
                      ),
                      const Text(
                        'LOGISTICS & AVAILABILITY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.blueGrey,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildInfoRow(Icons.person_outline_rounded, 'Lecturer', 'Dr. Ahmad (to be assigned)'),
                      _buildInfoRow(Icons.access_time_rounded, 'Schedule', 'Monday, 10:00 AM - 12:00 PM'),
                      _buildInfoRow(Icons.location_on_outlined, 'Location', 'DK 1, Faculty of Computing'),
                      _buildInfoRow(Icons.event_seat_rounded, 'Seats Available', '25 / 40 Seats'),
                      _buildInfoRow(Icons.gavel_rounded, 'Prerequisites', 'None Required'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isInCart
                      ? null
                      : () async {
                          final controller = context.read<RegistrationController>();
                          final success = await controller.addToCart(subject);

                          if (!context.mounted) return;

                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${subject.sub_code} added to registration cart'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                            Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Cannot add: Credit limit exceeded (max 20 credits)'),
                                backgroundColor: Colors.redAccent,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          }
                        },
                  icon: Icon(
                    isInCart ? Icons.check_circle_rounded : Icons.add_shopping_cart_rounded,
                    size: 20,
                  ),
                  label: Text(
                    isInCart ? 'Already in Cart' : 'Add to Registration Cart',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFC8E6C9),
                    disabledForegroundColor: Colors.green.shade800,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.blueGrey.shade400),
          const SizedBox(width: 10),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600, 
                color: Colors.black54,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
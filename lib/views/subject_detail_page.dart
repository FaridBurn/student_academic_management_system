import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subject.dart';
import '../controllers/registration_controller.dart';

class SubjectDetailPage extends StatelessWidget {
  final Subject subject;

  const SubjectDetailPage({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    final isInCart = context.watch<RegistrationController>().cartItems.any(
      (item) => item.subjectID == subject.subjectID,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(subject.sub_code),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.sub_name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Subject Code', subject.sub_code),
                    _buildInfoRow('Credit Hours', '${subject.credit_hours}'),
                    _buildInfoRow('Semester', subject.sub_semester),
                    const Divider(height: 24),
                    _buildInfoRow('Lecturer', 'Dr. Ahmad (to be assigned)'),
                    _buildInfoRow('Schedule', 'Monday, 10:00 AM - 12:00 PM'),
                    _buildInfoRow('Location', 'DK 1, Faculty of Computing'),
                    _buildInfoRow('Seats Available', '25 / 40'),
                    _buildInfoRow('Prerequisites', 'None'),
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
                              content: Text('${subject.sub_code} added to cart'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Cannot add: Credit limit exceeded (max 20 credits)'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                icon: Icon(isInCart ? Icons.check_circle : Icons.add_shopping_cart),
                label: Text(isInCart ? 'Already in Cart' : 'Add to Cart'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isInCart ? Colors.green : const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
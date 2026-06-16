import 'package:flutter/material.dart';
import 'payment_detail_page.dart';

class BlockNotificationPage extends StatelessWidget {
  final String studentUid;
  final String studentName;

  const BlockNotificationPage({
    super.key,
    required this.studentUid,
    required this.studentName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.block_flipped,
                    color: Colors.red, size: 80),
              ),
              const SizedBox(height: 30),
              const Text(
                'Access Restricted',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A3A6B),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Dear $studentName, your academic access has been temporarily suspended due to outstanding tuition fees.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.grey[700], fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 10),
              const Text(
                'Please settle your payment to reactivate your portal.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 50),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A3A6B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.payment),
                  label: const Text('Proceed to Payment',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PaymentDetailPage(studentUid: studentUid),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {},
                child: const Text('Contact Treasury Support',
                    style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
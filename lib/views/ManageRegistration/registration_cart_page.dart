import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/registration_controller.dart';
import 'registration_confirmation_page.dart';

class RegistrationCartPage extends StatelessWidget {
  const RegistrationCartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration Cart'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: Consumer<RegistrationController>(
        builder: (context, controller, child) {
          if (controller.cartItems.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 8),
                  Text('Add subjects from the subject list'),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: controller.cartItems.length,
                  itemBuilder: (context, index) {
                    final subject = controller.cartItems[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            subject.credit_hours.toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          '${subject.sub_code} - ${subject.sub_name}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Credit Hours: ${subject.credit_hours}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () => controller.removeFromCart(subject),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Credit Hours:',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${controller.totalCartCredits} / 20',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: controller.totalCartCredits > 20 ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: controller.totalCartCredits / 20,
                      backgroundColor: Colors.grey.shade200,
                      color: controller.totalCartCredits > 20 ? Colors.red : Colors.green,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: controller.totalCartCredits <= 20 && controller.cartItems.isNotEmpty
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RegistrationConfirmationPage(),
                                  ),
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Proceed to Confirmation',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
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
}
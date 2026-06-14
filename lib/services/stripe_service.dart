import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class StripeService {
  static void init(String publishableKey) {
    Stripe.publishableKey = publishableKey;
  }


  static Future<String> _createPaymentIntent({
    required double amount,
    required String currency,
    required int feeId,
    required String studentId,
  }) async {
    final secretKey = dotenv.env['STRIPE_SECRET_KEY'];
    if (secretKey == null || secretKey.isEmpty) {
      throw Exception('STRIPE_SECRET_KEY not set in .env');
    }

    final amountInCents = (amount * 100).toInt();

    final response = await http
        .post(
          Uri.parse('https://api.stripe.com/v1/payment_intents'),
          headers: {
            'Authorization': 'Bearer $secretKey',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: {
            'amount': amountInCents.toString(),
            'currency': currency,
            'automatic_payment_methods[enabled]': 'true',
            'metadata[fee_id]': feeId.toString(),
            'metadata[student_id]': studentId,
          },
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Failed to create PaymentIntent: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['client_secret'] == null) {
      throw Exception('No client_secret in response');
    }
    return data['client_secret'] as String;
  }

  // ── Present Stripe Payment Sheet ─────────────────────────────
  static Future<String> makePayment({
    required double amount,
    required int feeId,
    required String studentId,
    String currency = 'myr',
  }) async {
    if (kIsWeb) {
      throw UnsupportedError(
          'Stripe payment sheet is not supported on web. Please use the mobile app to make payments.');
    }

    final clientSecret = await _createPaymentIntent(
      amount: amount,
      currency: currency,
      feeId: feeId,
      studentId: studentId,
    );

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'UMPSA SAMS',
        style: ThemeMode.system,
        billingDetailsCollectionConfiguration:
            const BillingDetailsCollectionConfiguration(
              name: CollectionMode.always,
              email: CollectionMode.always,
            ),
      ),
    );

    await Stripe.instance.presentPaymentSheet();

    // client_secret format: pi_XXXXX_secret_YYYYY — extract PaymentIntent ID
    return clientSecret.split('_secret_').first;
  }
}

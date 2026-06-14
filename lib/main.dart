import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'views/login_page.dart';
import 'controllers/registration_controller.dart';
import 'controllers/fee_controller.dart';
import 'services/stripe_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "assets/.env");
  
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
  
  if (supabaseUrl == null || supabaseAnonKey == null) {
    debugPrint('ERROR: Missing Supabase credentials');
    return;
  }
  
  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabaseAnonKey,
  );

  if (!kIsWeb) {
    final stripeKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';
    if (stripeKey.isNotEmpty) StripeService.init(stripeKey);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RegistrationController()),
        ChangeNotifierProvider(create: (_) => FeeController()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SAMS',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const LoginScreen(),
      ),
    );
  }
}
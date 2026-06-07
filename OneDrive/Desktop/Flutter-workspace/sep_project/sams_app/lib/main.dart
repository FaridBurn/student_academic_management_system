import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://sckwdlhsbpgqwwmsxpgz.supabase.co',        
    publishableKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNja3dkbGhzYnBncXd3bXN4cGd6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA3NjI2NDMsImV4cCI6MjA5NjMzODY0M30.xBGptrMXW9wgmHp3bfkOM1ZdOwHY_qenZDE8RpeYQiM',       
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const LoginScreen(), 
    );
  }
}
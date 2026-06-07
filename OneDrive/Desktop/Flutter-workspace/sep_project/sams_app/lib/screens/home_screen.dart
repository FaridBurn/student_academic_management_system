import 'package:flutter/material.dart';
import 'student_home.dart';
import 'lecturer_home.dart';
import 'admin_home.dart';
import 'treasury_home.dart';
import 'pusatadab_home.dart';

class HomeScreen extends StatelessWidget {
  final String role;
  final String name;
  const HomeScreen({super.key, required this.role, required this.name});

  @override
  Widget build(BuildContext context) {
    switch (role) {
      case 'student':   return StudentHome(name: name);
      case 'lecturer':  return LecturerHome(name: name);
      case 'registrar': return AdminHome(name: name);
      case 'treasury':  return TreasuryHome(name: name);
      case 'pusatadab': return PusatAdabHome(name: name);
      default: return const Scaffold(
          body: Center(child: Text('Unknown role')));
    }
  }
}
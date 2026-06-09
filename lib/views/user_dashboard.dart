import 'package:flutter/material.dart';
import 'student_dashboard.dart';
import 'lecturer_dashboard.dart';
import 'registrar_dashboard.dart';
import 'treasury_dashboard.dart';
import 'pusatadab_dashboard.dart';

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
      case 'pusat_adab': return PusatAdabHome(name: name);
      default: return const Scaffold(
          body: Center(child: Text('Unknown role')));
    }
  }
}
import 'package:flutter/material.dart';
import 'ManageRegistration/student_dashboard.dart';
import 'lecturer_dashboard.dart';
import 'registrar_dashboard.dart';
import 'treasury_dashboard.dart';
import 'pusatadab_dashboard.dart';

class HomeScreen extends StatelessWidget {
  final String role;
  final String name;
  final String email;
  const HomeScreen({super.key, required this.role, required this.name, required this.email});

  @override
  Widget build(BuildContext context) {
    switch (role) {
      case 'student':   return StudentHome(name: name);
      case 'lecturer':  return LecturerHome(name: name, email: email);
      case 'registrar': return RegistrarDashboard(name: name);
      case 'treasury':  return TreasuryHome(name: name);
      case 'pusat_adab': return PusatAdabHome(name: name);
      default: return const Scaffold(
          body: Center(child: Text('Unknown role')));
    }
  }
}
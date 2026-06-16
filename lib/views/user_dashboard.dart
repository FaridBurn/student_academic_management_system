import 'package:flutter/material.dart';
import 'student_dashboard.dart';
import 'lecturer_dashboard.dart';
import 'registrar_dashboard.dart';
import 'treasury_dashboard.dart';
import 'pusatadab_dashboard.dart';

class HomeScreen extends StatelessWidget {
  final String role;
  final String name;
<<<<<<< HEAD
  final String email;
  const HomeScreen({super.key, required this.role, required this.name, required this.email});
=======
  const HomeScreen({super.key, required this.role, required this.name});
>>>>>>> 51f7658097679a1ca70072b0812edc867825ee55

  @override
  Widget build(BuildContext context) {
    switch (role) {
      case 'student':   return StudentHome(name: name);
<<<<<<< HEAD
      case 'lecturer':  return LecturerHome(name: name, email: email);
      case 'registrar': return RegistrarDashboard(name: name);
=======
      case 'lecturer':  return LecturerHome(name: name);
      case 'registrar': return AdminHome(name: name);
>>>>>>> 51f7658097679a1ca70072b0812edc867825ee55
      case 'treasury':  return TreasuryHome(name: name);
      case 'pusat_adab': return PusatAdabHome(name: name);
      default: return const Scaffold(
          body: Center(child: Text('Unknown role')));
    }
  }
}
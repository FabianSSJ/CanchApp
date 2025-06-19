import 'package:flutter/material.dart';
import '../utils/colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor: AppColors.primaryGreen,
      ),
      body: const Center(
        child: Text('Pantalla de Perfil', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/colors.dart';
import 'dart:convert';

class RegisterTypeScreen extends StatefulWidget {
  const RegisterTypeScreen({Key? key}) : super(key: key);

  @override
  State<RegisterTypeScreen> createState() => _RegisterTypeScreenState();
}

class _RegisterTypeScreenState extends State<RegisterTypeScreen> with TickerProviderStateMixin {
  String? selectedUserType;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gray900),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Crear Cuenta',
          style: TextStyle(
            color: AppColors.gray900,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 40),
                        const Column(
                          children: [
                            Text(
                              '¿Cómo vas a usar CanchApp?',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: AppColors.gray900,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Elige tu tipo de cuenta',
                              style: TextStyle(
                                fontSize: 18,
                                color: AppColors.gray600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                        const SizedBox(height: 48),
                        _buildUserTypeCard(
                          type: 'Jugador',
                          title: 'Jugador',
                          description: 'Busca y reserva tu cancha',
                          icon: Icons.person_outline,
                          gradient: AppColors.primaryGradient,
                          feature: 'Reserva instantánea',
                          featureIcon: Icons.flash_on,
                          featureColor: AppColors.primaryGreen,
                        ),
                        const SizedBox(height: 24),
                        _buildUserTypeCard(
                          type: 'Dueño',
                          title: 'Dueño de Empresa',
                          description: 'Administra y alquila tus canchas',
                          icon: Icons.business_outlined,
                          gradient: AppColors.blueGradient,
                          feature: 'Maximiza ingresos',
                          featureIcon: Icons.trending_up,
                          featureColor: AppColors.primaryBlue,
                        ),
                        const SizedBox(height: 36),

if (selectedUserType != null)
  AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeInOut,
    padding: const EdgeInsets.only(bottom: 32),
    child: SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          _navigateToRegistration();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: AppColors.primaryGreen.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Continuar como ${_getUserTypeLabel(selectedUserType!)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 20),
          ],
        ),
      ),
    ),
  ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeCard({
    required String type,
    required String title,
    required String description,
    required IconData icon,
    required Gradient gradient,
    required String feature,
    required IconData featureIcon,
    required Color featureColor,
  }) {
    final isSelected = selectedUserType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedUserType = type;
        });
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? featureColor : AppColors.gray200,
            width: isSelected ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? featureColor.withOpacity(0.2) : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 20 : 8,
              offset: Offset(0, isSelected ? 8 : 4),
            ),
          ],
        ),
        transform: Matrix4.identity()..scale(isSelected ? 1.02 : 1.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: isSelected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      featureColor.withOpacity(0.05),
                      featureColor.withOpacity(0.02),
                    ],
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: featureColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 29, 39, 17),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.gray600,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: featureColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(featureIcon, size: 16, color: featureColor),
                            const SizedBox(width: 6),
                            Text(
                              feature,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: featureColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? featureColor : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? featureColor : AppColors.gray300,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getUserTypeLabel(String type) {
    switch (type) {
      case 'Jugador':
        return 'Jugador';
      case 'Dueño':
        return 'Dueño de Empresa';
      default:
        return '';
    }
  }

  void _navigateToRegistration() {
    if (selectedUserType == 'Jugador') {
      Navigator.pushNamed(context, '/register-player');
    } else if (selectedUserType == 'Dueño') {
      Navigator.pushNamed(context, '/register-owner');
    }
  }
}

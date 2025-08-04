import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/login_screen.dart';
import 'screens/client_home_screen.dart';
import 'screens/register_type_screen.dart';
import 'screens/register_player_screen.dart'; // Nueva importación
import 'screens/forgot_password_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/owner_home_screen.dart';
import 'screens/register_owner_screen.dart';
import 'providers/theme_provider.dart';
import 'screens/create_field_screen.dart';
import 'screens/fields_list_screen.dart';
import 'screens/field_detail_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'CanchApp',
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF059669)),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF059669), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF059669),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterTypeScreen(),
        '/register-player': (context) => const RegisterPlayerScreen(),
        '/register-owner': (context) => const RegisterOwnerScreen(), // Nueva ruta
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/client-home': (context) => const ClientHomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/owner-home': (context) => const OwnerHomeScreen(), //
        '/create_field': (context) => const CreateFieldScreen(),
        '/fields_list': (context) => const FieldsListScreen(),
        '/field_detail': (context) => const FieldDetailScreen(),
      },
    );
  }
}
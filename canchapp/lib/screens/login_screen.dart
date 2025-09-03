import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // 🔥 AGREGADO
import 'dart:convert';
import '../../utils/colors.dart';
import '../widgets/base_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 🔥 NUEVO: Método para obtener company_id del dueño usando el endpoint LIST
  Future<int?> _getCompanyId(String token, int userId) async {
    try {
      final response = await http.get(
        Uri.parse('http://104.248.75.98:3000/companies/list'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📋 Companies list response: $data');
        
        // Si la respuesta es una lista directa
        if (data is List) {
          for (var company in data) {
            // Buscar por company_user_id (clave foránea del dueño)
            if (company['company_user_id'] == userId) {
              return company['company_id'];
            }
          }
        }
        // Si la respuesta tiene una propiedad 'companies' o 'data'
        else if (data is Map) {
          List companies = data['companies'] ?? data['data'] ?? [];
          for (var company in companies) {
            // Buscar por company_user_id (clave foránea del dueño)
            if (company['company_user_id'] == userId) {
              return company['company_id'];
            }
          }
        }
        
        print('⚠️ No se encontró empresa para el usuario $userId');
      } else {
        print('❌ Error en companies/list: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ ERROR obteniendo company_id: $e');
    }
    return null;
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Realizar petición HTTP al backend
        final response = await http.post(
          Uri.parse('http://104.248.75.98:3000/api/login'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'user_email': _emailController.text,
            'user_hashed_password': _passwordController.text,
          }),
        );

        setState(() {
          _isLoading = false;
        });

        print('Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          
          if (responseData['message'] == 'Login exitoso') {
            final userData = responseData['user'];
            final userRole = userData['role'];
            final String token = responseData['token'];

            // 🔥 GUARDAR EN SHARED PREFERENCES
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('token', token);
            await prefs.setInt('user_id', userData['id']);
            await prefs.setString('user_name', userData['name']);
            await prefs.setString('user_email', userData['email']);
            await prefs.setString('user_role', userRole);

            print('✅ TOKEN GUARDADO: ${token.substring(0, 20)}...');
            print('✅ USER DATA GUARDADO: ${userData['name']} - $userRole');

            // 🔥 Si es dueño, obtener y guardar company_id
            if (userRole == 'dueño' || userRole == 'dueno') {
              try {
                final companyId = await _getCompanyId(token, userData['id']);
                if (companyId != null) {
                  await prefs.setInt('company_id', companyId);
                  print('✅ COMPANY ID GUARDADO: $companyId');
                } else {
                  print('⚠️ No se pudo obtener company_id');
                }
              } catch (e) {
                print('⚠️ Error obteniendo company_id: $e');
              }
            }

            if (mounted) {
              final userDataForNavigation = {
                'userName': userData['name'],
                'userEmail': userData['email'],
                'profilePhoto': '',
                'userPhone': '',
                'userRole': userRole,
                'userId': userData['id'],
                'token': token,
              };

              // NAVEGACIÓN (sin cambios)
              switch (userRole) {
                case 'jugador':
                  Navigator.pushReplacementNamed(
                    context,
                    '/client-home',
                    arguments: userDataForNavigation,
                  );
                  break;
                case 'dueño':
                case 'dueno':
                  Navigator.pushReplacementNamed(
                    context,
                    '/owner-home',
                    arguments: userDataForNavigation,
                  );
                  break;
                case 'administrador':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pantalla de administrador en desarrollo. Accediendo como jugador temporalmente.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  Navigator.pushReplacementNamed(
                    context,
                    '/client-home',
                    arguments: userDataForNavigation,
                  );
                  break;
                default:
                  Navigator.pushReplacementNamed(
                    context,
                    '/client-home',
                    arguments: userDataForNavigation,
                  );
              }
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(responseData['message'] ?? 'Email o contraseña incorrectos'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } else {
          String errorMessage = 'Error del servidor. Intenta nuevamente.';
          
          try {
            final errorData = json.decode(response.body);
            if (errorData['message'] != null) {
              errorMessage = errorData['message'];
            }
          } catch (e) {
            errorMessage = 'Error ${response.statusCode}: ${response.body}';
          }
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error de conexión. Verifica tu internet.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // EL RESTO DEL CÓDIGO PERMANECE EXACTAMENTE IGUAL
  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Iniciar Sesión',
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 40),
                Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromRGBO(5, 150, 105, 1).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                  ]),
                      child: const Center(
                        child: Text(
                          '⚽',
                          style: TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '¡Bienvenido!',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: AppColors.gray900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ingresa para continuar',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColors.gray600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Email',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'tu@email.com',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa tu email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Por favor ingresa un email válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Contraseña',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa tu contraseña';
                        }
                        if (value.length < 6) {
                          return 'La contraseña debe tener al menos 6 caracteres';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.gray300,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Iniciar Sesión',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/forgot-password');
                  },
                  child: const Text(
                    '¿Olvidaste tu contraseña?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '¿No tienes cuenta? ',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.gray600,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Crear cuenta',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
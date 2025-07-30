import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterPlayerScreen extends StatefulWidget {
  const RegisterPlayerScreen({super.key});

  @override
  _RegisterPlayerScreenState createState() => _RegisterPlayerScreenState();
}

class _RegisterPlayerScreenState extends State<RegisterPlayerScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _userData = {
    'user_name': '',
    'user_last_name': '',
    'user_email': '',
    'user_hashed_password': '',
    'user_profile_photo': '',
    'user_phone': '',
    'user_role': 'jugador'
  };
  
  // Variables para controlar la visibilidad de la contraseña
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  // Variables para almacenar las contraseñas directamente
  String _password = '';
  String _confirmPassword = '';

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      // Asignar la contraseña al mapa después de save()
      _userData['user_hashed_password'] = _password;
      
      // Lógica original de envío al servidor
      try {
        final response = await http.post(
          Uri.parse('http://localhost:3000/users/create'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(_userData),
        );

        if (response.statusCode == 201) {
          // Registro exitoso - misma lógica original
          Navigator.pushReplacementNamed(context, '/login');
        } else {
          // Manejar error - misma lógica original
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Error'),
              content: Text(response.body),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        // Manejar error de conexión - misma lógica original
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Error de conexión'),
            content: const Text('No se pudo conectar al servidor.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Jugador'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2E7D32)),
        titleTextStyle: const TextStyle(
          color: Color(0xFF2E7D32),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Container(
        color: Colors.white,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header con título e icono
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: const Color(0xFFC8E6C9),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.person_add_alt_1,
                          size: 40,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Crear Cuenta de Jugador',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Completa tus datos para comenzar',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Formulario
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(25),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Nombre
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Nombre',
                                prefixIcon: const Icon(Icons.person, color: Color(0xFF2E7D32)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.grey),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              onSaved: (value) => _userData['user_name'] = value ?? '',
                              validator: (value) => (value == null || value.isEmpty) ? 'Requerido' : null,
                            ),
                            const SizedBox(height: 20),
                            
                            // Apellido
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Apellido',
                                prefixIcon: const Icon(Icons.people, color: Color(0xFF2E7D32)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.grey),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              onSaved: (value) => _userData['user_last_name'] = value ?? '',
                              validator: (value) => (value == null || value.isEmpty) ? 'Requerido' : null,
                            ),
                            const SizedBox(height: 20),
                            
                            // Email
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Email',
                                prefixIcon: const Icon(Icons.email, color: Color(0xFF2E7D32)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.grey),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              onSaved: (value) => _userData['user_email'] = value ?? '',
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Requerido';
                                if (!value.contains('@')) return 'Email inválido';
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            
                            // Contraseña con botón de visibilidad
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                prefixIcon: const Icon(Icons.lock, color: Color(0xFF2E7D32)),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                    color: const Color(0xFF2E7D32),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.grey),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              obscureText: _obscurePassword,
                              onChanged: (value) => _password = value,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Requerido';
                                if (value.length < 6) return 'Mínimo 6 caracteres';
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            
                            // Confirmar Contraseña con botón de visibilidad
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Confirmar Contraseña',
                                prefixIcon: const Icon(Icons.lock_reset, color: Color(0xFF2E7D32)),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                    color: const Color(0xFF2E7D32),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword = !_obscureConfirmPassword;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.grey),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              obscureText: _obscureConfirmPassword,
                              onChanged: (value) => _confirmPassword = value,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Por favor repita la contraseña';
                                if (value != _password) {
                                  return 'Las contraseñas no coinciden';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            
                            // Teléfono
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Teléfono',
                                prefixIcon: const Icon(Icons.phone, color: Color(0xFF2E7D32)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.grey),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              keyboardType: TextInputType.phone,
                              onSaved: (value) => _userData['user_phone'] = value ?? '',
                              validator: (value) => (value == null || value.isEmpty) ? 'Requerido' : null,
                            ),
                            const SizedBox(height: 30),
                            
                            // Botón de Registro
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                onPressed: _submitForm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2E7D32),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 3,
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shadowColor: const Color(0xFFC8E6C9).withOpacity(0.8),
                                ),
                                child: const Text(
                                  'REGISTRARSE',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Enlace a login
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  '¿Ya tienes cuenta? ',
                                  style: TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                                  child: const Text(
                                    'Inicia Sesión',
                                    style: TextStyle(
                                      color: Color(0xFF2E7D32),
                                      fontWeight: FontWeight.bold,
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
                ),
                const SizedBox(height: 30),
                
                // Footer
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Al registrarte, aceptas nuestros Términos de Servicio y Política de Privacidad',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
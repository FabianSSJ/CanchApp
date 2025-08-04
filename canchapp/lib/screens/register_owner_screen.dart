import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterOwnerScreen extends StatefulWidget {
  const RegisterOwnerScreen({super.key});

  @override
  _RegisterOwnerScreenState createState() => _RegisterOwnerScreenState();
}

class _RegisterOwnerScreenState extends State<RegisterOwnerScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Formularios
  final _userFormKey = GlobalKey<FormState>();
  final _companyFormKey = GlobalKey<FormState>();

  // Variables para controlar la visibilidad de la contraseña
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Variables para almacenar las contraseñas directamente
  String _password = '';
  String _confirmPassword = '';

  // Datos del usuario
  final Map<String, dynamic> _userData = {
    'user_name': '',
    'user_last_name': '',
    'user_email': '',
    'user_hashed_password': '',
    'user_profile_photo': '',
    'user_phone': '',
    'user_role': 'dueño'
  };

  // Datos de la empresa
  final Map<String, dynamic> _companyData = {
    'company_name': '',
    'company_city_id': 1,
    'company_phone': '',
    'company_email': '',
    'company_location': '',
    'company_description': '',
    'company_services': '',
    'company_logo': '',
  };

  // Token del usuario creado
  String _userToken = '';
  bool _isLoading = false;

  Future<void> _submitUserForm() async {
    if (_userFormKey.currentState!.validate()) {
      _userFormKey.currentState!.save();
      
      setState(() {
        _isLoading = true;
      });

      _userData['user_hashed_password'] = _password;
      
      try {
        final response = await http.post(
          Uri.parse('http://localhost:3000/users/create'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(_userData),
        );

        setState(() {
          _isLoading = false;
        });

        if (response.statusCode == 201) {
          // Usuario creado exitosamente, ahora hacer login para obtener token
          await _loginUser();
        } else {
          _showErrorDialog('Error al crear usuario', response.body);
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('Error de conexión', 'No se pudo conectar al servidor.');
      }
    }
  }

  Future<void> _loginUser() async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_email': _userData['user_email'],
          'user_hashed_password': _password,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['message'] == 'Login exitoso') {
          _userToken = responseData['token'];
          // Avanzar al siguiente paso
          _nextStep();
        } else {
          _showErrorDialog('Error de autenticación', 'No se pudo autenticar el usuario.');
        }
      } else {
        _showErrorDialog('Error de autenticación', 'No se pudo autenticar el usuario.');
      }
    } catch (e) {
      _showErrorDialog('Error de conexión', 'No se pudo conectar al servidor.');
    }
  }

  Future<void> _submitCompanyForm() async {
    if (_companyFormKey.currentState!.validate()) {
      _companyFormKey.currentState!.save();
      
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await http.post(
          Uri.parse('http://localhost:3000/companies/create'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_userToken',
          },
          body: json.encode(_companyData),
        );

        setState(() {
          _isLoading = false;
        });

        if (response.statusCode == 201) {
          // Empresa creada exitosamente
          _showSuccessDialog();
        } else {
          _showErrorDialog('Error al crear empresa', response.body);
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('Error de conexión', 'No se pudo conectar al servidor.');
      }
    }
  }

  void _nextStep() {
    if (_currentStep < 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('¡Registro Exitoso!'),
        content: const Text('Tu cuenta de dueño y empresa han sido creadas correctamente. Ahora puedes iniciar sesión.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Ir a Login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Dueño'),
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
        child: Column(
          children: [
            // Indicador de pasos
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  _buildStepIndicator(0, 'Usuario', _currentStep >= 0),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: _currentStep >= 1 ? const Color(0xFF2E7D32) : Colors.grey[300],
                    ),
                  ),
                  _buildStepIndicator(1, 'Empresa', _currentStep >= 1),
                ],
              ),
            ),
            
            // Contenido de los pasos
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildUserForm(),
                  _buildCompanyForm(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, String title, bool isActive) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF2E7D32) : Colors.grey[300],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              '${step + 1}',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isActive ? const Color(0xFF2E7D32) : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildUserForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header
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
                  'Datos Personales',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Primero crea tu cuenta de usuario',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          
          // Formulario de usuario
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Form(
                key: _userFormKey,
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
                    
                    // Contraseña
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
                    
                    // Confirmar Contraseña
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
                    
                    // Botón Siguiente
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitUserForm,
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
                                'SIGUIENTE',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header
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
                    Icons.business,
                    size: 40,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Datos de la Empresa',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Completa la información de tu empresa',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          
          // Formulario de empresa
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Form(
                key: _companyFormKey,
                child: Column(
                  children: [
                    // Nombre de la empresa
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Nombre de la Empresa',
                        prefixIcon: const Icon(Icons.business, color: Color(0xFF2E7D32)),
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
                      onSaved: (value) => _companyData['company_name'] = value ?? '',
                      validator: (value) => (value == null || value.isEmpty) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 20),
                    
                    // Email de la empresa
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Email de la Empresa',
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
                      onSaved: (value) => _companyData['company_email'] = value ?? '',
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Requerido';
                        if (!value.contains('@')) return 'Email inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    // Teléfono de la empresa
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Teléfono de la Empresa',
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
                      onSaved: (value) => _companyData['company_phone'] = value ?? '',
                      validator: (value) => (value == null || value.isEmpty) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 20),
                    
                    // Ubicación
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Ubicación (Link de Google Maps)',
                        prefixIcon: const Icon(Icons.location_on, color: Color(0xFF2E7D32)),
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
                      onSaved: (value) => _companyData['company_location'] = value ?? '',
                      validator: (value) => (value == null || value.isEmpty) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 20),
                    
                    // Descripción
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Descripción de la Empresa',
                        prefixIcon: const Icon(Icons.description, color: Color(0xFF2E7D32)),
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
                      maxLines: 3,
                      onSaved: (value) => _companyData['company_description'] = value ?? '',
                    ),
                    const SizedBox(height: 20),
                    
                    // Servicios
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Servicios (separados por comas)',
                        prefixIcon: const Icon(Icons.miscellaneous_services, color: Color(0xFF2E7D32)),
                        helperText: 'Ej: parqueadero, iluminación, billar',
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
                      onSaved: (value) => _companyData['company_services'] = value ?? '',
                    ),
                    const SizedBox(height: 30),
                    
                    // Botones
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 55,
                            child: OutlinedButton(
                              onPressed: _previousStep,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF2E7D32)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'ANTERIOR',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SizedBox(
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submitCompanyForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                                shadowColor: const Color(0xFFC8E6C9).withOpacity(0.8),
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
                                      'FINALIZAR',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
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
        ],
      ),
    );
  }
}
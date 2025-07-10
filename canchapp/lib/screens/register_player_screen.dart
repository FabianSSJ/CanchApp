import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final response = await http.post(
        Uri.parse('http://localhost:3000/users/create'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(_userData),
      );

      if (response.statusCode == 201) {
        // Registro exitoso
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        // Manejar error
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Error'),
            content: Text(response.body),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro de Jugador')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nombre'),
                onSaved: (value) => _userData['user_name'] = value!,
                validator: (value) => value!.isEmpty ? 'Requerido' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Apellido'),
                onSaved: (value) => _userData['user_last_name'] = value!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                onSaved: (value) => _userData['user_email'] = value!,
                validator: (value) => 
                  !value!.contains('@') ? 'Email inválido' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
                onSaved: (value) => _userData['user_hashed_password'] = value!,
                validator: (value) => 
                  value!.length < 6 ? 'Mínimo 6 caracteres' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Teléfono'),
                onSaved: (value) => _userData['user_phone'] = value!,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Registrarse'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
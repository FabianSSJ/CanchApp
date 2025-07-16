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

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
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
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Error de conexión'),
            content: Text('No se pudo conectar al servidor.'),
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
      appBar: AppBar(title: const Text('Registro de Jugador')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nombre'),
                onSaved: (value) => _userData['user_name'] = value ?? '',
                validator: (value) => (value == null || value.isEmpty) ? 'Requerido' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Apellido'),
                onSaved: (value) => _userData['user_last_name'] = value ?? '',
                validator: (value) => (value == null || value.isEmpty) ? 'Requerido' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                onSaved: (value) => _userData['user_email'] = value ?? '',
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Requerido';
                  if (!value.contains('@')) return 'Email inválido';
                  return null;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
                onSaved: (value) => _userData['user_hashed_password'] = value ?? '',
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Requerido';
                  if (value.length < 6) return 'Mínimo 6 caracteres';
                  return null;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Teléfono'),
                keyboardType: TextInputType.phone,
                onSaved: (value) => _userData['user_phone'] = value ?? '',
                validator: (value) => (value == null || value.isEmpty) ? 'Requerido' : null,
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
import 'package:flutter/material.dart';

class RegisterTypeScreen extends StatelessWidget {
  const RegisterTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tipo de Registro'),
        backgroundColor: Colors.green[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '¿Cómo deseas registrarte?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                // Aquí puedes navegar a un formulario de cliente
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Formulario de Jugador')),
                );
              },
              icon: const Icon(Icons.person),
              label: const Text('jugador'),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                // Aquí puedes navegar a un formulario de dueño
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Formulario de dueño de cancha')),
                );
              },
              icon: const Icon(Icons.sports_soccer),
              label: const Text('Dueño de Empresa'),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            ),
          ],
        ),
      ),
    );
  }
}

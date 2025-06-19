import 'package:flutter/material.dart';
import '../../utils/colors.dart';

class ClientHomeScreen extends StatelessWidget {
  const ClientHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Usuario simulado
    final String userName = 'Juan Pérez';
    final String userEmail = 'usuario@demo.com';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        backgroundColor: AppColors.primaryGreen,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
              accountName: Text(
                userName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(userEmail),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  userName.substring(0, 1), // Inicial del nombre
                  style: TextStyle(
                    fontSize: 40,
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Opciones del Drawer
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Inicio'),
              onTap: () {
                Navigator.pop(context);
                // Aquí podrías navegar o hacer algo
              },
            ),

            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Perfil'),
              onTap: () {
                Navigator.pop(context);
                // Por ejemplo, navegar a perfil:
                Navigator.pushNamed(context, '/profile');
              },
            ),

            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Configuración'),
              onTap: () {
                Navigator.pop(context);
                // Navegar a configuración (ruta ejemplo)
                Navigator.pushNamed(context, '/settings');
              },
            ),

            const Spacer(),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.logout_outlined, color: Colors.red),
              title: const Text(
                'Cerrar sesión',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                // Simular cerrar sesión: volver a login
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
      body: const Center(
        child: Text(
          'Bienvenido a CanchApp',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

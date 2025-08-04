import 'package:flutter/material.dart';
import '../../utils/colors.dart';

class ClientHomeScreen extends StatelessWidget {
  const ClientHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtener los datos del usuario desde los argumentos
    final Map<String, dynamic>? userData = 
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    // Valores por defecto si no hay argumentos
    final String userName = userData?['userName'] ?? 'Usuario';
    final String userEmail = userData?['userEmail'] ?? 'usuario@email.com';
    final String profilePhoto = userData?['profilePhoto'] ?? '';

    // Lista simulada de canchas (podrás reemplazar con datos del backend)
    final List<Map<String, dynamic>> canchas = [
      {
        'id': 1,
        'nombre': 'Cancha La Pelota',
        'ubicacion': 'Av. Principal 123',
        'precio': 25.0,
        'tipo': 'Fútbol 11',
        'disponible': true,
        'imagen': 'https://ejemplo.com/cancha1.jpg',
      },
      {
        'id': 2,
        'nombre': 'Cancha El Gol',
        'ubicacion': 'Calle Secundaria 456',
        'precio': 20.0,
        'tipo': 'Fútbol 7',
        'disponible': true,
        'imagen': 'https://ejemplo.com/cancha2.jpg',
      },
      {
        'id': 3,
        'nombre': 'Cancha Champions',
        'ubicacion': 'Centro Deportivo Norte',
        'precio': 30.0,
        'tipo': 'Fútbol 11',
        'disponible': false,
        'imagen': 'https://ejemplo.com/cancha3.jpg',
      },
    ];

    // Filtrar solo canchas disponibles
    final List<Map<String, dynamic>> canchasDisponibles = 
        canchas.where((cancha) => cancha['disponible'] == true).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Canchas Disponibles'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
              accountName: Text(
                userName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(userEmail),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: profilePhoto.isNotEmpty ? NetworkImage(profilePhoto) : null,
                child: profilePhoto.isEmpty 
                    ? Text(
                        userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : 'U',
                        style: const TextStyle(
                          fontSize: 40,
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),

            // Opciones del Drawer
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Inicio'),
              onTap: () {
                Navigator.pop(context);
              },
            ),

            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Perfil'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile', arguments: userData);
              },
            ),

            ListTile(
              leading: const Icon(Icons.sports_soccer_outlined),
              title: const Text('Mis Reservas'),
              onTap: () {
                Navigator.pop(context);
                // Navigator.pushNamed(context, '/my-reservations');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Funcionalidad en desarrollo')),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Configuración'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Funcionalidad en desarrollo')),
                );
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
                _showLogoutDialog(context);
              },
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Saludo personalizado
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¡Hola, ${userName.split(' ')[0]}!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Encuentra la cancha perfecta para tu partido',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Título de sección
            const Text(
              'Canchas Disponibles',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.gray900,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Lista de canchas o mensaje de no disponibles
            Expanded(
              child: canchasDisponibles.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: canchasDisponibles.length,
                      itemBuilder: (context, index) {
                        final cancha = canchasDisponibles[index];
                        return _buildCanchaCard(context, cancha);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sports_soccer_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Canchas no disponibles',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No hay canchas disponibles en este momento.\nIntenta más tarde.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Aquí podrías agregar lógica para recargar
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Actualizar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCanchaCard(BuildContext context, Map<String, dynamic> cancha) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen de la cancha (placeholder)
          Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Icon(
              Icons.sports_soccer,
              size: 60,
              color: AppColors.primaryGreen,
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre y tipo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        cancha['nombre'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        cancha['tipo'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Ubicación
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        cancha['ubicacion'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Precio y botón
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${cancha['precio'].toStringAsFixed(0)}/hora',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _showReservarDialog(context, cancha);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: const Text('Reservar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReservarDialog(BuildContext context, Map<String, dynamic> cancha) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reservar ${cancha['nombre']}'),
        content: const Text('Esta funcionalidad estará disponible próximamente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}
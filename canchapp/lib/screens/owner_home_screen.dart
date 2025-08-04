import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class OwnerHomeScreen extends StatelessWidget {
  const OwnerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Dueño'),
        centerTitle: true,
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            const Text(
              'Resumen de Negocio',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF059669),
              ),
            ),
            const SizedBox(height: 15),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              children: [
                _buildSummaryCard('Reservas Hoy', '12', MdiIcons.calendarCheck, Colors.blue),
                _buildSummaryCard('Ingresos Mensuales', '\$2,450', MdiIcons.cash, Colors.green),
                _buildSummaryCard('Canchas Activas', '4', MdiIcons.soccerField, Colors.orange),
                _buildSummaryCard('Clientes Nuevos', '8', MdiIcons.accountGroup, Colors.purple),
              ],
            ),

            const SizedBox(height: 30),
            const Text(
              'Gestión Rápida',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF059669),
              ),
            ),
            const SizedBox(height: 15),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 0.9,
              children: [
                _buildActionButton(context, 'Agregar Cancha', Icons.add, Colors.blue),
                _buildActionButton(context, 'Reservas', Icons.calendar_today, Colors.green),
                _buildActionButton(context, 'Clientes', Icons.people, Colors.orange),
                _buildActionButton(context, 'Reportes', Icons.bar_chart, Colors.purple),
              ],
            ),

            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Próximas Reservas',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF059669),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Ver Todas',
                    style: TextStyle(color: Color(0xFF059669)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildReservationItem('Cancha 1', 'Juan Pérez', '18:00 - 20:00'),
            _buildReservationItem('Cancha 2', 'Carlos Gómez', '19:00 - 21:00'),
            _buildReservationItem('Cancha 3', 'María Rodríguez', '20:00 - 22:00'),

            const SizedBox(height: 30),
            const Text(
              'Estadísticas Mensuales',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF059669),
              ),
            ),
            const SizedBox(height: 15),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildChartBar(80, 'Lun'),
                        _buildChartBar(120, 'Mar'),
                        _buildChartBar(160, 'Mié'),
                        _buildChartBar(200, 'Jue'),
                        _buildChartBar(180, 'Vie'),
                        _buildChartBar(140, 'Sáb'),
                        _buildChartBar(100, 'Dom'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Ingresos por día (\$)',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF059669),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: const Color(0xFF059669),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Reservas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Canchas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        switch (label) {
          case 'Agregar Cancha':
            Navigator.pushNamed(context, '/create_field');
            break;
          case 'Reservas':
            Navigator.pushNamed(context, '/owner_bookings');
            break;
          case 'Clientes':
            Navigator.pushNamed(context, '/owner_clients');
            break;
          case 'Reportes':
            Navigator.pushNamed(context, '/owner_reports');
            break;
        }
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, size: 30, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationItem(String court, String client, String time) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE6F7F0),
          child: Icon(Icons.sports_soccer, color: Color(0xFF059669)),
        ),
        title: Text(court, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(client),
        trailing: Text(
          time,
          style: const TextStyle(
            color: Color(0xFF059669),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildChartBar(double height, String label) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            height: height / 3,
            width: 20,
            decoration: BoxDecoration(
              color: const Color(0xFF059669),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/field_service.dart';
import '../services/booking_service.dart';
import '../services/statistics_service.dart';

class OwnerHomeScreen extends StatefulWidget {
  const OwnerHomeScreen({super.key});

  @override
  State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen> {
  String? userName;
  String? userEmail;
  int? companyId;
  bool _isLoading = true;
  
  // Variables corregidas con valores por defecto seguros
  Map<String, dynamic> businessSummary = {
    'fieldsReservedToday': 0,
    'dailyIncome': 0.0,
    'activeFields': 0,
    'totalClients': 0,
  };
  String selectedPeriod = 'day';
  
  List<Map<String, dynamic>> upcomingBookings = [];
  List<Map<String, dynamic>> weeklyStats = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        userName = prefs.getString('user_name') ?? 'Usuario';
        userEmail = prefs.getString('user_email') ?? '';
        companyId = prefs.getInt('company_id');
      });

      if (companyId != null) {
        await _loadBusinessData();
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadBusinessData() async {
    if (companyId == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      
      print('🔄 CARGANDO DATOS REALES DEL NEGOCIO');
      print('Token: ${token.length > 20 ? token.substring(0, 20) + '...' : token}');
      print('Company ID: $companyId');
      
      // Cargar datos en paralelo
      await Future.wait([
        _loadDashboardStats(token),
        _loadUpcomingBookings(token),
        _loadWeeklyStats(token),
      ]);
      
    } catch (e) {
      print('Error loading business data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando datos: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _loadDashboardStats(String token) async {
    try {
      print('📊 Cargando estadísticas del dashboard...');
      
      final result = await StatisticsService.getDashboardStats(
        token: token,
        companyId: companyId!,
      );
      
      print('📊 Dashboard result: $result');
      
      if (result['success'] == true) {
        setState(() {
          businessSummary['fieldsReservedToday'] = result['fieldsReservedToday'] ?? 0;
          businessSummary['dailyIncome'] = (result['dailyIncome'] is num) 
            ? (result['dailyIncome'] as num).toDouble() 
            : 0.0;
          businessSummary['activeFields'] = result['activeFields'] ?? 0;
          businessSummary['totalClients'] = result['totalClients'] ?? 0;
        });
        
        print('✅ Dashboard stats cargadas exitosamente');
        print('   - Canchas reservadas hoy: ${businessSummary['fieldsReservedToday']}');
        print('   - Ingresos de hoy: ${businessSummary['dailyIncome']}');
        print('   - Canchas activas: ${businessSummary['activeFields']}');
        print('   - Clientes totales: ${businessSummary['totalClients']}');
      } else {
        print('❌ Error en dashboard stats: ${result['message'] ?? 'Error desconocido'}');
      }
    } catch (e) {
      print('❌ Excepción en _loadDashboardStats: $e');
    }
  }

  Future<void> _loadUpcomingBookings(String token) async {
    try {
      print('📅 Cargando próximas reservas...');
      
      final result = await BookingService.getUpcomingBookings(
        token: token,
        companyId: companyId!,
        limit: 3,
      );
      
      print('📅 Upcoming bookings result: $result');
      
      if (result['success'] == true) {
        setState(() {
          final data = result['data'];
          upcomingBookings = data is List 
            ? List<Map<String, dynamic>>.from(data) 
            : [];
        });
        
        print('✅ Próximas reservas cargadas: ${upcomingBookings.length}');
      } else {
        print('❌ Error en upcoming bookings: ${result['message'] ?? 'Error desconocido'}');
      }
    } catch (e) {
      print('❌ Excepción en _loadUpcomingBookings: $e');
    }
  }

  Future<void> _loadWeeklyStats(String token) async {
    try {
      print('📈 Cargando estadísticas semanales...');
      
      final result = await StatisticsService.getWeeklyStats(
        token: token,
        companyId: companyId!,
      );
      
      if (result['success'] == true) {
        setState(() {
          final chartData = result['chartData'];
          weeklyStats = chartData is List 
            ? List<Map<String, dynamic>>.from(chartData) 
            : [];
        });
        
        print('✅ Estadísticas semanales cargadas: ${weeklyStats.length}');
      } else {
        print('❌ Error en weekly stats: ${result['message'] ?? 'Error desconocido'}');
      }
    } catch (e) {
      print('❌ Error en _loadWeeklyStats: $e');
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sesión cerrada correctamente'),
                    backgroundColor: Colors.green,
                  ),
                );
                
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              }
            },
            child: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF059669),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Hola, ${userName ?? 'Usuario'}'),
        centerTitle: false,
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notificaciones en desarrollo')),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.person),
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  Navigator.pushNamed(context, '/profile');
                  break;
                case 'settings':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Configuración en desarrollo')),
                  );
                  break;
                case 'logout':
                  _logout();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Perfil'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Configuración'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF059669),
        onRefresh: _loadBusinessData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (companyId == null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    border: Border.all(color: Colors.orange),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.warning, color: Colors.orange, size: 32),
                      SizedBox(height: 8),
                      Text(
                        'No tienes una empresa registrada',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Necesitas registrar una empresa para gestionar canchas',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.orange),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
              ],

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
                childAspectRatio: 1.3,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                children: [
                  _buildSummaryCard(
                    'Canchas Reservadas',
                    '${businessSummary['fieldsReservedToday'] ?? 0}',
                    MdiIcons.calendarCheck,
                    Colors.blue,
                  ),
                  _buildSummaryCard(
                    'Ingresos de hoy',
                    '\$${((businessSummary['dailyIncome'] as num?) ?? 0.0).toStringAsFixed(2)}',
                    MdiIcons.cash,
                    Colors.green,
                  ),
                  _buildSummaryCard(
                    'Canchas Activas',
                    '${businessSummary['activeFields'] ?? 0}',
                    MdiIcons.soccerField,
                    Colors.orange,
                  ),
                  _buildSummaryCard(
                    'Clientes Totales',
                    '${businessSummary['totalClients'] ?? 0}',
                    MdiIcons.accountGroup,
                    Colors.purple,
                  ),
                ],
              ),

              const SizedBox(height: 20),
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
                childAspectRatio: 0.8,
                children: [
                  _buildActionButton(context, 'Agregar Cancha', Icons.add, Colors.blue),
                  _buildActionButton(context, 'Reservas', Icons.calendar_today, Colors.green),
                  _buildActionButton(context, 'Clientes', Icons.people, Colors.orange),
                  _buildActionButton(context, 'Reportes', Icons.bar_chart, Colors.purple),
                ],
              ),

              const SizedBox(height: 20),
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
                    onPressed: () {
                      Navigator.pushNamed(context, '/owner_bookings');
                    },
                    child: const Text(
                      'Ver Todas',
                      style: TextStyle(color: Color(0xFF059669)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              
              if (upcomingBookings.isEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.calendar_month,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No hay reservas próximas',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Las reservas aparecerán aquí cuando se hagan',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                ...upcomingBookings.take(3).map((booking) => 
                  _buildReservationItem(
                    booking['field_name']?.toString() ?? 'Cancha',
                    booking['client_name']?.toString() ?? 'Cliente',
                    booking['time_range']?.toString() ?? 'Horario',
                  ),
                ),
              ],

              const SizedBox(height: 20),
              const Text(
                'Estadísticas Semanales',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF059669),
                ),
              ),
              const SizedBox(height: 15),
              Container(
                height: 160,
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
                child: weeklyStats.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bar_chart,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No hay estadísticas disponibles',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Los datos aparecerán cuando tengas reservas',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      )
                    : Column(
  children: [
    Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: weeklyStats.isNotEmpty
          ? weeklyStats.map((stat) {
              final reservations = (stat['reservations'] as num?)?.toDouble() ?? 0.0;
              final day = stat['day']?.toString() ?? '';
              final shortDay = day.length > 3 ? day.substring(0, 3) : day;
              return _buildChartBar(reservations * 10, shortDay);
            }).toList()
          : [
              // Mostrar gráfico vacío o mensaje
              const Expanded(
                child: Center(
                  child: Text(
                    'Sin datos',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
      ),
    ),
    const SizedBox(height: 10),
    Text(
      weeklyStats.isNotEmpty ? 'Reservas por día (últimos 7 días)' : 'No hay reservas esta semana',
      style: const TextStyle(fontSize: 14, color: Colors.grey),
    ),
  ],
)
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/create_field');
        },
        backgroundColor: const Color(0xFF059669),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        selectedItemColor: const Color(0xFF059669),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          switch (index) {
            case 0:
              break;
            case 1:
              Navigator.pushNamed(context, '/owner_bookings');
              break;
            case 2:
              Navigator.pushNamed(context, '/owner_fields');
              break;
            case 3:
              Navigator.pushNamed(context, '/profile');
              break;
          }
        },
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
            icon: Icon(Icons.sports_soccer),
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
            if (companyId == null) {
              _showNoCompanyDialog();
            } else {
              Navigator.pushNamed(context, '/create_field');
            }
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

  void _showNoCompanyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Empresa Requerida'),
        content: const Text(
          'Necesitas registrar una empresa antes de poder agregar canchas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
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
            height: (height / 3).clamp(5.0, 50.0), // Limitar altura entre 5 y 50
            width: 20,
            decoration: BoxDecoration(
              color: const Color(0xFF059669),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
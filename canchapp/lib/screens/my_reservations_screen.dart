import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/reservation_service.dart';
import '../utils/colors.dart';


class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({super.key});

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  List<Map<String, dynamic>> _reservations = [];
  List<Map<String, dynamic>> _filteredReservations = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'Todas';
  
  final List<String> _filterOptions = ['Todas', 'Pendiente', 'Confirmada', 'Rechazada', 'Completada', 'Cancelada'];

  @override
  void initState() {
    super.initState();
    _loadUserReservations();
  }

  Future<void> _loadUserReservations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      
      if (userId == null || userId == 0) {
        setState(() {
          _errorMessage = 'Error: No se encontró información del usuario';
          _isLoading = false;
        });
        return;
      }

      print('🔍 Cargando reservas del usuario $userId');
      
      final result = await ReservationService.getUserReservations(userId);
      
      if (result['success']) {
        setState(() {
          _reservations = List<Map<String, dynamic>>.from(result['data'] ?? []);
          _filteredReservations = _reservations;
          _isLoading = false;
        });
        print('✅ Reservas cargadas: ${_reservations.length}');
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Error cargando reservas';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexión: $e';
        _isLoading = false;
      });
      print('💥 Error cargando reservas: $e');
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      if (filter == 'Todas') {
        _filteredReservations = _reservations;
      } else {
        _filteredReservations = _reservations.where((reservation) {
          return reservation['calendar_state'] == filter;
        }).toList();
      }
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pendiente':
        return Colors.orange;
      case 'Confirmada':
        return Colors.blue;
      case 'Rechazada':
        return Colors.red;
      case 'Completada':
        return Colors.green;
      case 'Cancelada':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Pendiente':
        return Icons.access_time;
      case 'Confirmada':
        return Icons.check_circle;
      case 'Rechazada':
        return Icons.cancel;
      case 'Completada':
        return Icons.check_circle_outline;
      case 'Cancelada':
        return Icons.block;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'Pendiente':
        return 'Tu reserva está siendo revisada por el administrador';
      case 'Confirmada':
        return 'Tu reserva ha sido confirmada. ¡Disfruta tu juego!';
      case 'Rechazada':
        return 'Tu reserva fue rechazada. Revisa el motivo o contacta al soporte';
      case 'Completada':
        return 'Reserva completada. ¡Esperamos que hayas disfrutado!';
      case 'Cancelada':
        return 'Esta reserva fue cancelada';
      default:
        return 'Estado de reserva';
    }
  }

  Map<String, int> _getStatusCounts() {
    return {
      'total': _reservations.length,
      'pendientes': _reservations.where((r) => r['calendar_state'] == 'Pendiente').length,
      'confirmadas': _reservations.where((r) => r['calendar_state'] == 'Confirmada').length,
      'rechazadas': _reservations.where((r) => r['calendar_state'] == 'Rechazada').length,
    };
  }

  @override
  Widget build(BuildContext context) {
    final statusCounts = _getStatusCounts();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Mis Reservas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserReservations,
            tooltip: 'Actualizar reservas',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header con gradiente y estadísticas
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Historial de Reservas',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aquí puedes ver el estado de todas tus reservas',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Estadísticas rápidas
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total',
                          statusCounts['total'].toString(),
                          Icons.sports_soccer,
                          Colors.white.withOpacity(0.2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Pendientes',
                          statusCounts['pendientes'].toString(),
                          Icons.access_time,
                          Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Confirmadas',
                          statusCounts['confirmadas'].toString(),
                          Icons.check_circle,
                          Colors.blue.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Filtros
          Container(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filterOptions.length,
              itemBuilder: (context, index) {
                final filter = _filterOptions[index];
                final isSelected = _selectedFilter == filter;
                
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) _applyFilter(filter);
                    },
                    backgroundColor: Colors.white,
                    selectedColor: AppColors.primaryGreen.withOpacity(0.2),
                    checkmarkColor: AppColors.primaryGreen,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primaryGreen : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppColors.primaryGreen : Colors.grey[300]!,
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Lista de reservas
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primaryGreen,
              onRefresh: _loadUserReservations,
              child: _buildReservationsList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationsList() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primaryGreen),
            SizedBox(height: 16),
            Text(
              'Cargando tus reservas...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Error al cargar reservas',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadUserReservations,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredReservations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _selectedFilter == 'Todas' ? Icons.sports_soccer_outlined : Icons.filter_alt_off,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                _selectedFilter == 'Todas' 
                    ? 'No tienes reservas aún'
                    : 'No tienes reservas $_selectedFilter',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedFilter == 'Todas'
                    ? 'Cuando hagas una reserva, aparecerá aquí'
                    : 'Intenta cambiar el filtro para ver otras reservas',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredReservations.length,
      itemBuilder: (context, index) {
        final reservation = _filteredReservations[index];
        return _buildReservationCard(reservation);
      },
    );
  }

  Widget _buildReservationCard(Map<String, dynamic> reservation) {
    final status = reservation['calendar_state'] ?? 'Desconocido';
    final fieldName = reservation['field_name'] ?? 'Cancha';
    final companyName = reservation['company_name'] ?? 'Empresa';
    final date = reservation['calendar_date'] ?? '';
    final startTime = reservation['calendar_init_time'] ?? '';
    final endTime = reservation['calendar_end_time'] ?? '';
    final price = reservation['field_hour_price'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: _getStatusColor(status).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con estado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    fieldName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _getStatusColor(status).withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(status),
                        size: 16,
                        color: _getStatusColor(status),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(status),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Información de la reserva
            Row(
              children: [
                Icon(Icons.business, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    companyName,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  _formatDate(date),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  '$startTime - $endTime',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(Icons.attach_money, size: 16, color: AppColors.primaryGreen),
                    Text(
                      '\$${price.toString()}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Mensaje de estado
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _getStatusColor(status).withOpacity(0.3)),
              ),
              child: Text(
                _getStatusMessage(status),
                style: TextStyle(
                  fontSize: 13,
                  color: _getStatusColor(status),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            // Mostrar comprobante de pago si existe
            if (reservation['calendar_payment_receipt'] != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.receipt, size: 16, color: Colors.green[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Comprobante de pago enviado',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.green[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      const months = [
        'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
        'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
      ];
      return '${date.day} de ${months[date.month - 1]}, ${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
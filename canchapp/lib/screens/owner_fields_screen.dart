import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/field_service.dart';
import '../services/booking_service.dart';
import '../services/statistics_service.dart';

class OwnerFieldsScreen extends StatefulWidget {
  const OwnerFieldsScreen({super.key});

  @override
  State<OwnerFieldsScreen> createState() => _OwnerFieldsScreenState();
}

class _OwnerFieldsScreenState extends State<OwnerFieldsScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _fields = [];
  bool _isLoading = true;
  String? _token;
  int? _companyId;
  late TabController _tabController;
  
  // Filtros y búsqueda
  String _searchQuery = '';
  String _selectedStatus = 'all'; // all, active, maintenance
  String _selectedType = 'all'; // all, específicos tipos

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');
      _companyId = prefs.getInt('company_id');
      
      if (_token != null && _companyId != null) {
        await _loadFields();
      } else {
        setState(() {
          _isLoading = false;
        });
        _showError('No se encontraron datos de sesión');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Error cargando datos: $e');
    }
  }

  Future<void> _loadFields() async {
    if (_token == null || _companyId == null) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await FieldService.getFieldsByCompany(
        token: _token!,
        companyId: _companyId!,
      );

      if (result['success']) {
        final data = result['data'];
        List<Map<String, dynamic>> fields = [];
        
        if (data is List) {
          fields = List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data.containsKey('data')) {
          fields = List<Map<String, dynamic>>.from(data['data']);
        } else if (data is Map && data.containsKey('fields')) {
          fields = List<Map<String, dynamic>>.from(data['fields']);
        }

        // Cargar estadísticas para cada cancha
        for (var field in fields) {
          await _loadFieldStats(field);
        }

        setState(() {
          _fields = fields;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        _showError(result['message'] ?? 'Error cargando canchas');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Error de conexión: $e');
    }
  }

  Future<void> _loadFieldStats(Map<String, dynamic> field) async {
    try {
      final fieldId = field['field_id'];
      
      // Obtener reservas del último mes para estadísticas
      /*final reservationsResult = await BookingService.getFieldReservations(
        token: _token!,
        fieldId: fieldId,
        startDate: DateTime.now().subtract(const Duration(days: 30)).toIso8601String().split('T')[0],
        endDate: DateTime.now().toIso8601String().split('T')[0],
      );

      if (reservationsResult['success']) {
        final reservations = reservationsResult['data'] as List? ?? [];
        
        field['total_reservations'] = reservations.length;
        field['completed_reservations'] = reservations.where((r) => r['status'] == 'Completada').length;
        field['pending_reservations'] = reservations.where((r) => r['status'] == 'Por Confirmar').length;
        field['monthly_income'] = reservations
            .where((r) => r['status'] == 'Completada')
            .fold(0.0, (sum, r) => sum + (double.tryParse(r['amount']?.toString() ?? '0') ?? 0.0));
      } else {
        field['total_reservations'] = 0;
        field['completed_reservations'] = 0;
        field['pending_reservations'] = 0;
        field['monthly_income'] = 0.0;
      }*/
    } catch (e) {
      print('Error cargando stats para cancha ${field['field_id']}: $e');
      field['total_reservations'] = 0;
      field['completed_reservations'] = 0;
      field['pending_reservations'] = 0;
      field['monthly_income'] = 0.0;
    }
  }

  Future<void> _toggleFieldStatus(int fieldId, bool currentStatus) async {
    if (_token == null) return;

    // CORREGIDO: Solo permite poner en mantenimiento, no activar
    if (currentStatus) {
      // Si está activa, puede ponerla en mantenimiento
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Poner en Mantenimiento'),
          content: const Text('¿Deseas poner esta cancha en mantenimiento?\n\nNota: Solo un administrador puede reactivarla.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Confirmar',
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      _showLoadingDialog('Poniendo en mantenimiento...');

      // Llamar al backend para cambiar a mantenimiento
      /*final result = await FieldService.setFieldMaintenance(
        token: _token!,
        fieldId: fieldId,
      );

      Navigator.pop(context);

      if (result['success']) {
        setState(() {
          final index = _fields.indexWhere((field) => field['field_id'] == fieldId);
          if (index != -1) {
            _fields[index]['field_state'] = false; // En mantenimiento
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cancha puesta en mantenimiento. Un administrador debe reactivarla.'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        _showError(result['message'] ?? 'Error poniendo en mantenimiento');
      }*/
    } else {
      // Si está en mantenimiento, mostrar mensaje de que no puede activar
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cancha en Mantenimiento'),
          content: const Text('Esta cancha está en mantenimiento.\n\nSolo un administrador puede reactivarla.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _deleteField(int fieldId, String fieldName) async {
    if (_token == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Cancha'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Estás seguro de que quieres eliminar "$fieldName"?'),
            const SizedBox(height: 8),
            const Text(
              'Esta acción eliminará:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('• Todas las reservas futuras'),
            const Text('• Horarios configurados'),
            const Text('• Historial de la cancha'),
            const SizedBox(height: 8),
            const Text(
              'Esta acción no se puede deshacer.',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      _showLoadingDialog('Eliminando cancha...');

      /*final result = await FieldService.deleteField(
        token: _token!,
        fieldId: fieldId,
      );

      Navigator.pop(context);

      if (result['success']) {
        setState(() {
          _fields.removeWhere((field) => field['field_id'] == fieldId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cancha eliminada correctamente'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        _showError(result['message'] ?? 'Error eliminando cancha');
      }*/
    } catch (e) {
      Navigator.pop(context);
      _showError('Error: $e');
    }
  }

  Future<void> _editField(Map<String, dynamic> field) async {
    final result = await Navigator.pushNamed(
      context, 
      '/edit_field',
      arguments: field,
    );
    
    if (result == true) {
      _loadFields(); // Recargar si se editó
    }
  }

  Future<void> _viewFieldDetails(Map<String, dynamic> field) async {
    await Navigator.pushNamed(
      context,
      '/field_details',
      arguments: field,
    );
  }

  Future<void> _viewFieldReservations(Map<String, dynamic> field) async {
    await Navigator.pushNamed(
      context,
      '/field_reservations',
      arguments: field,
    );
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredFields() {
    return _fields.where((field) {
      final matchesSearch = _searchQuery.isEmpty ||
          field['field_name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          field['field_type'].toString().toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus = _selectedStatus == 'all' ||
          (_selectedStatus == 'active' && (field['field_state'] ?? true)) ||
          (_selectedStatus == 'maintenance' && !(field['field_state'] ?? true));

      final matchesType = _selectedType == 'all' ||
          field['field_type'].toString() == _selectedType;

      return matchesSearch && matchesStatus && matchesType;
    }).toList();
  }

  List<String> _getAvailableTypes() {
    final types = _fields.map((field) => field['field_type'].toString()).toSet().toList();
    types.sort();
    return types;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Canchas'),
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
            tooltip: 'Buscar',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filtros',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFields,
            tooltip: 'Actualizar',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Todas', icon: Icon(Icons.list)),
            Tab(text: 'Activas', icon: Icon(Icons.check_circle)),
            Tab(text: 'Estadísticas', icon: Icon(Icons.bar_chart)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF059669),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFieldsList(),
                _buildActiveFieldsList(),
                _buildStatisticsView(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/create_field');
          if (result == true) {
            _loadFields();
          }
        },
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Cancha'),
      ),
    );
  }

  Widget _buildFieldsList() {
    final filteredFields = _getFilteredFields();
    
    if (filteredFields.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: const Color(0xFF059669),
      onRefresh: _loadFields,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredFields.length,
        itemBuilder: (context, index) {
          final field = filteredFields[index];
          return _buildFieldCard(field);
        },
      ),
    );
  }

  Widget _buildActiveFieldsList() {
    final activeFields = _fields.where((field) => field['field_state'] ?? true).toList();
    
    if (activeFields.isEmpty) {
      return const Center(
        child: Text(
          'No hay canchas activas',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activeFields.length,
      itemBuilder: (context, index) {
        final field = activeFields[index];
        return _buildCompactFieldCard(field);
      },
    );
  }

  Widget _buildStatisticsView() {
    if (_fields.isEmpty) {
      return const Center(
        child: Text('No hay datos para mostrar estadísticas'),
      );
    }

    final totalFields = _fields.length;
    final activeFields = _fields.where((f) => f['field_state'] ?? true).length;
    final totalIncome = _fields.fold(0.0, (sum, f) => sum + (f['monthly_income'] ?? 0.0));
    final totalReservations = 0;//_fields.fold(0, (sum, f) => sum + (f['total_reservations'] ?? 0));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsHeader(totalFields, activeFields, totalIncome, totalReservations),
          const SizedBox(height: 20),
          _buildFieldPerformanceChart(),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(int total, int active, double income, int reservations) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard('Total', total.toString(), Icons.sports_soccer, Colors.blue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('Activas', active.toString(), Icons.check_circle, Colors.green),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('Ingresos', '\$${income.toStringAsFixed(0)}', Icons.attach_money, Colors.orange),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('Reservas', reservations.toString(), Icons.calendar_today, Colors.purple),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldPerformanceChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rendimiento por Cancha (Último Mes)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._fields.map((field) => _buildPerformanceRow(field)),
        ],
      ),
    );
  }

  Widget _buildPerformanceRow(Map<String, dynamic> field) {
    final name = field['field_name'] ?? 'Sin nombre';
    final reservations = field['total_reservations'] ?? 0;
    final income = field['monthly_income'] ?? 0.0;
    final maxReservations = _fields.fold(0, (max, f) => 
        (f['total_reservations'] ?? 0) > max ? (f['total_reservations'] ?? 0) : max);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 3,
            child: LinearProgressIndicator(
              value: maxReservations > 0 ? reservations / maxReservations : 0,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$reservations',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Text(
            '\$${income.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Color(0xFF059669),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldCard(Map<String, dynamic> field) {
    final bool isActive = field['field_state'] ?? true;
    final String fieldName = field['field_name'] ?? 'Sin nombre';
    final String fieldType = field['field_type'] ?? 'Sin tipo';
    final String fieldSize = field['field_size'] ?? 'Sin tamaño';
    final int capacity = field['field_max_capacity'] ?? 0;
    final double price = double.tryParse(field['field_hour_price'].toString()) ?? 0.0;
    final String description = field['field_description'] ?? 'Sin descripción';
    final int totalReservations = field['total_reservations'] ?? 0;
    final int pendingReservations = field['pending_reservations'] ?? 0;
    final double monthlyIncome = field['monthly_income'] ?? 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildFieldHeader(isActive, fieldName, pendingReservations),
          _buildFieldInfo(fieldName, fieldType, fieldSize, capacity, price, description),
          _buildFieldStats(totalReservations, monthlyIncome),
          _buildFieldActions(field, isActive, fieldName),
        ],
      ),
    );
  }

  Widget _buildCompactFieldCard(Map<String, dynamic> field) {
    final String fieldName = field['field_name'] ?? 'Sin nombre';
    final String fieldType = field['field_type'] ?? 'Sin tipo';
    final double price = double.tryParse(field['field_hour_price'].toString()) ?? 0.0;
    final int pendingReservations = field['pending_reservations'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFF059669),
          child: Icon(Icons.sports_soccer, color: Colors.white),
        ),
        title: Text(fieldName),
        subtitle: Text(fieldType),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF059669),
              ),
            ),
            if (pendingReservations > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$pendingReservations pendientes',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
        onTap: () => _viewFieldDetails(field),
      ),
    );
  }

  Widget _buildFieldHeader(bool isActive, String fieldName, int pendingReservations) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF059669).withOpacity(0.8),
            const Color(0xFF059669),
          ],
        ),
      ),
      child: Stack(
        children: [
          const Center(
            child: Icon(
              Icons.sports_soccer,
              size: 48,
              color: Colors.white,
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildStatusChip(isActive),
                if (pendingReservations > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$pendingReservations pendientes',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(isActive),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(isActive),
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            _getStatusText(isActive),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldInfo(String fieldName, String fieldType, String fieldSize, int capacity, double price, String description) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  fieldName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '\$${price.toStringAsFixed(2)}/hora',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF059669),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.category, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                fieldType,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(width: 16),
              Icon(Icons.aspect_ratio, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                fieldSize,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(width: 16),
              Icon(Icons.people, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '$capacity personas',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFieldStats(int totalReservations, double monthlyIncome) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey[50],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Reservas', '$totalReservations', Icons.calendar_today, Colors.blue),
          _buildStatItem('Ingresos', '\$${monthlyIncome.toStringAsFixed(0)}', Icons.attach_money, Colors.green),
          _buildStatItem('Estado', totalReservations > 0 ? 'Activa' : 'Sin actividad', Icons.trending_up, 
            totalReservations > 0 ? Colors.green : Colors.orange),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildFieldActions(Map<String, dynamic> field, bool isActive, String fieldName) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _viewFieldReservations(field),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.calendar_today, size: 18),
              label: const Text('Reservas', style: TextStyle(fontSize: 12)),
            ),
          ),
          const SizedBox(width: 8),
          // CORREGIDO: Solo mostrar botón de mantenimiento si está activa
          if (isActive) 
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _toggleFieldStatus(field['field_id'], isActive),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.build, size: 18),
                label: const Text('Mantenim.', style: TextStyle(fontSize: 12)),
              ),
            )
          else
            // Mostrar estado de mantenimiento si no está activa
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.admin_panel_settings, size: 18, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      'Requiere Admin',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => _editField(field),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF059669),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Icon(Icons.edit, size: 18),
          ),
          const SizedBox(width: 8),
          // CORREGIDO: Solo permitir eliminar si está en mantenimiento
          OutlinedButton(
            onPressed: isActive ? null : () => _deleteField(field['field_id'], fieldName),
            style: OutlinedButton.styleFrom(
              foregroundColor: isActive ? Colors.grey : Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Icon(Icons.delete, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_soccer,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No tienes canchas registradas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Agrega tu primera cancha para comenzar a recibir reservas',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.pushNamed(context, '/create_field');
                if (result == true) {
                  _loadFields();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Agregar Primera Cancha'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String tempQuery = _searchQuery;
        return AlertDialog(
          title: const Text('Buscar Cancha'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Nombre o tipo de cancha...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              tempQuery = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchQuery = tempQuery;
                });
                Navigator.pop(context);
              },
              child: const Text('Buscar'),
            ),
          ],
        );
      },
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String tempStatus = _selectedStatus;
        String tempType = _selectedType;
        final availableTypes = _getAvailableTypes();

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Filtros'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Estado:', style: TextStyle(fontWeight: FontWeight.bold)),
                  RadioListTile<String>(
                    title: const Text('Todas'),
                    value: 'all',
                    groupValue: tempStatus,
                    onChanged: (value) {
                      setDialogState(() {
                        tempStatus = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Activas'),
                    value: 'active',
                    groupValue: tempStatus,
                    onChanged: (value) {
                      setDialogState(() {
                        tempStatus = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('En Mantenimiento'),
                    value: 'maintenance',
                    groupValue: tempStatus,
                    onChanged: (value) {
                      setDialogState(() {
                        tempStatus = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Tipo:', style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    value: tempType,
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(value: 'all', child: Text('Todos los tipos')),
                      ...availableTypes.map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      )),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        tempType = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedStatus = 'all';
                      _selectedType = 'all';
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Limpiar'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedStatus = tempStatus;
                      _selectedType = tempType;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Aplicar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(bool isActive) {
    return isActive ? Colors.green : Colors.orange;
  }

  String _getStatusText(bool isActive) {
    return isActive ? 'Activa' : 'Mantenimiento';
  }

  IconData _getStatusIcon(bool isActive) {
    return isActive ? Icons.check_circle : Icons.build;
  }
}
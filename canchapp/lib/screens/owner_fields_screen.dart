import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/field_service.dart';

class OwnerFieldsScreen extends StatefulWidget {
  const OwnerFieldsScreen({super.key});

  @override
  State<OwnerFieldsScreen> createState() => _OwnerFieldsScreenState();
}

class _OwnerFieldsScreenState extends State<OwnerFieldsScreen> {
  List<Map<String, dynamic>> _fields = [];
  bool _isLoading = true;
  String? _token;
  int? _companyId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
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

  Future<void> _toggleFieldStatus(int fieldId, bool currentStatus) async {
    if (_token == null) return;

    try {
      // Mostrar diálogo de confirmación
      final newStatus = !currentStatus;
      final statusText = newStatus ? 'activa' : 'en mantenimiento';
      
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cambiar Estado'),
          content: Text('¿Deseas poner esta cancha como $statusText?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Confirmar',
                style: TextStyle(
                  color: newStatus ? Colors.green : Colors.orange,
                ),
              ),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Actualizando estado...'),
            ],
          ),
        ),
      );

      final result = await FieldService.updateFieldStatus(
        token: _token!,
        fieldId: fieldId,
        isActive: newStatus,
      );

      Navigator.pop(context); // Cerrar loading dialog

      if (result['success']) {
        // Actualizar la lista localmente
        setState(() {
          final index = _fields.indexWhere((field) => field['field_id'] == fieldId);
          if (index != -1) {
            _fields[index]['field_state'] = newStatus;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cancha puesta como $statusText'),
            backgroundColor: newStatus ? Colors.green : Colors.orange,
          ),
        );
      } else {
        _showError(result['message'] ?? 'Error actualizando estado');
      }
    } catch (e) {
      Navigator.pop(context); // Cerrar loading dialog si está abierto
      _showError('Error: $e');
    }
  }

  Future<void> _deleteField(int fieldId, String fieldName) async {
    if (_token == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Cancha'),
        content: Text('¿Estás seguro de que quieres eliminar "$fieldName"?'),
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
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Eliminando cancha...'),
            ],
          ),
        ),
      );

      final result = await FieldService.deleteField(
        token: _token!,
        fieldId: fieldId,
      );

      Navigator.pop(context); // Cerrar loading dialog

      if (result['success']) {
        // Remover de la lista localmente
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
      }
    } catch (e) {
      Navigator.pop(context); // Cerrar loading dialog si está abierto
      _showError('Error: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Canchas'),
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFields,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF059669),
              ),
            )
          : RefreshIndicator(
              color: const Color(0xFF059669),
              onRefresh: _loadFields,
              child: _fields.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _fields.length,
                      itemBuilder: (context, index) {
                        final field = _fields[index];
                        return _buildFieldCard(field);
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/create_field');
          if (result == true) {
            _loadFields(); // Recargar lista si se creó una cancha
          }
        },
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Cancha'),
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

  Widget _buildFieldCard(Map<String, dynamic> field) {
    final bool isActive = field['field_state'] ?? true;
    final String fieldName = field['field_name'] ?? 'Sin nombre';
    final String fieldType = field['field_type'] ?? 'Sin tipo';
    final String fieldSize = field['field_size'] ?? 'Sin tamaño';
    final int capacity = field['field_max_capacity'] ?? 0;
    final double price = double.tryParse(field['field_hour_price'].toString()) ?? 0.0;
    final String description = field['field_description'] ?? 'Sin descripción';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header con imagen y estado
          Container(
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
                  child: Container(
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
                  ),
                ),
              ],
            ),
          ),

          // Información de la cancha
          Padding(
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
                const SizedBox(height: 16),

                // Botones de acción
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () => _toggleFieldStatus(
                          field['field_id'],
                          isActive,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getStatusColor(!isActive),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: Icon(_getStatusIcon(!isActive)),
                        label: Text(
                          isActive ? 'Mantenimiento' : 'Activar',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // TODO: Implementar editar cancha
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Editar cancha en desarrollo'),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF059669),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Editar',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => _deleteField(
                        field['field_id'],
                        fieldName,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Icon(Icons.delete, size: 18),
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
}
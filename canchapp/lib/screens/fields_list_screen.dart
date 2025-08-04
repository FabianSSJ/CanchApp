import 'package:flutter/material.dart';
import '../models/field.dart';
import '../services/field_service.dart';

class FieldsListScreen extends StatefulWidget {
  const FieldsListScreen({super.key});

  @override
  State<FieldsListScreen> createState() => _FieldsListScreenState();
}

class _FieldsListScreenState extends State<FieldsListScreen> {
  List<Field> _fields = [];
  List<Field> _filteredFields = [];
  bool _isLoading = true;
  String _selectedFilter = 'Todos';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFields();
    _searchController.addListener(_filterFields);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFields() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await FieldService.getAllFields();
      if (result['success']) {
        final List<dynamic> fieldsData = result['data'];
        setState(() {
          _fields = fieldsData
              .map((json) => Field.fromJson(json))
              .where((field) => !field.fieldDelete) // Solo canchas activas
              .toList();
          _filteredFields = _fields;
          _isLoading = false;
        });
      } else {
        _showErrorSnackbar(result['message']);
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      _showErrorSnackbar('Error al cargar las canchas');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterFields() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredFields = _fields.where((field) {
        bool matchesSearch = field.fieldName.toLowerCase().contains(query) ||
            field.fieldDescription.toLowerCase().contains(query);
        bool matchesType = _selectedFilter == 'Todos' || field.fieldType == _selectedFilter;
        return matchesSearch && matchesType;
      }).toList();
    });
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Canchas Disponibles'),
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFields,
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda y filtros
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              children: [
                // Campo de búsqueda
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar canchas...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                // Filtros por tipo
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Todos'),
                      ...FieldService.getFieldTypes().map((type) => _buildFilterChip(type)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de canchas
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredFields.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadFields,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredFields.length,
                          itemBuilder: (context, index) {
                            return _buildFieldCard(_filteredFields[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    bool isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          setState(() {
            _selectedFilter = selected ? label : 'Todos';
            _filterFields();
          });
        },
        selectedColor: const Color(0xFF059669).withOpacity(0.2),
        checkmarkColor: const Color(0xFF059669),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sports_soccer,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay canchas disponibles',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta cambiar los filtros de búsqueda',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldCard(Field field) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/field_detail',
            arguments: field,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Imagen o icono de la cancha
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: const Color(0xFF059669).withOpacity(0.1),
                ),
                child: field.fieldImg != null && 
                       field.fieldImg!.isNotEmpty && 
                       !field.fieldImg!.contains('default')
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          field.fieldImg!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Text(
                                field.fieldIcon,
                                style: const TextStyle(fontSize: 30),
                              ),
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Text(
                          field.fieldIcon,
                          style: const TextStyle(fontSize: 30),
                        ),
                      ),
              ),
              
              const SizedBox(width: 16),
              
              // Información de la cancha
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      field.fieldName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      field.fieldType,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tamaño: ${field.fieldSize}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          field.formattedRating,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const Spacer(),
                        Text(
                          field.formattedPrice,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Icono de flecha
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
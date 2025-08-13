import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../services/field_service.dart';
import 'package:shared_preferences/shared_preferences.dart';


class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  List<Map<String, dynamic>> _canchas = [];
  List<Map<String, dynamic>> _canchasFiltradas = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  // 🆕 VARIABLES PARA FILTROS
  String _selectedSport = 'Todas';
  String _selectedTimeSlot = 'Cualquier hora';
  String _searchQuery = '';
  String _selectedCity = 'Todas las ciudades';
  DateTime _selectedDate = DateTime.now();

  // 🆕 LISTAS PARA FILTROS
  final List<String> _sports = ['Todas', 'Fútbol 5', 'Fútbol 7', 'Fútbol 11', 'Básquet', 'Vóley', 'Tenis'];
  final List<String> _timeSlots = [
    'Cualquier hora',
    'Mañana (6:00 - 12:00)',
    'Tarde (12:00 - 18:00)', 
    'Noche (18:00 - 24:00)'
  ];
  final List<String> _cities = ['Todas las ciudades', 'Loja', 'Catamayo', 'Malacatos', 'Vilcabamba'];

  @override
  void initState() {
    super.initState();
    _loadCanchas();
  }

  Future<void> _loadCanchas() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('🔍 Cargando canchas disponibles...');
      
      final result = await FieldService.getAllFields();
      
      print('📄 Resultado canchas: $result');
      
      if (result['success']) {
        List<Map<String, dynamic>> allFields = [];
        
        if (result['data'] is List) {
          allFields = List<Map<String, dynamic>>.from(result['data']);
        } else if (result['data'] is Map && result['data']['data'] is List) {
          allFields = List<Map<String, dynamic>>.from(result['data']['data']);
        }

        // Filtrar solo canchas activas (field_delete = false)
        final canchasDisponibles = allFields.where((cancha) {
          return cancha['field_delete'] == false || cancha['field_delete'] == 0;
        }).toList();

        setState(() {
          _canchas = canchasDisponibles;
          _canchasFiltradas = canchasDisponibles;
          _isLoading = false;
        });

        print('✅ Canchas cargadas: ${_canchas.length}');
        
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result['message'] ?? 'Error cargando canchas';
        });
        print('❌ Error: ${result['message']}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error de conexión: $e';
      });
      print('💥 Excepción cargando canchas: $e');
    }
  }

  // 🆕 MÉTODO PARA APLICAR FILTROS
  void _applyFilters() {
    setState(() {
      _canchasFiltradas = _canchas.where((cancha) {
        // Filtro por deporte
        bool matchesSport = _selectedSport == 'Todas' || 
                           cancha['field_type']?.toString().contains(_selectedSport.split(' ')[0]) == true;
        
        // Filtro por búsqueda de texto
        bool matchesSearch = _searchQuery.isEmpty ||
                            cancha['field_name']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) == true ||
                            cancha['company_name']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) == true;
        
        // Filtro por ciudad
        bool matchesCity = _selectedCity == 'Todas las ciudades' ||
                          cancha['city_name']?.toString() == _selectedCity;
        
        return matchesSport && matchesSearch && matchesCity;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Obtener los datos del usuario desde los argumentos
    final Map<String, dynamic>? userData = 
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    // Valores por defecto si no hay argumentos
    final String userName = userData?['userName'] ?? 'Usuario';
    final String userEmail = userData?['userEmail'] ?? 'usuario@email.com';
    final String profilePhoto = userData?['profilePhoto'] ?? '';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.sports_soccer, color: Colors.white),
            const SizedBox(width: 8),
            const Text('CanchApp'),
          ],
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Implementar notificaciones
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCanchas,
            tooltip: 'Actualizar canchas',
          ),
        ],
      ),
      drawer: _buildDrawer(userName, userEmail, profilePhoto, userData, context),
      body: Column(
        children: [
          // 🆕 HEADER CON SALUDO Y UBICACIÓN
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
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white,
                        backgroundImage: profilePhoto.isNotEmpty ? NetworkImage(profilePhoto) : null,
                        child: profilePhoto.isEmpty 
                            ? Text(
                                userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : 'U',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: AppColors.primaryGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '¡Hola, ${userName.split(' ')[0]}! 👋',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Row(
                              children: [
                                Icon(Icons.location_on, color: Colors.white70, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  'Canchas disponibles en Loja',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 🆕 BARRA DE BÚSQUEDA
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                        _applyFilters();
                      },
                      decoration: InputDecoration(
                        hintText: 'Buscar canchas en Loja...',
                        prefixIcon: const Icon(Icons.search, color: AppColors.primaryGreen),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.tune, color: AppColors.primaryGreen),
                          onPressed: _showFilterBottomSheet,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 🆕 FILTROS HORIZONTALES
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip('Todas', _selectedSport, _sports, (value) {
                  setState(() {
                    _selectedSport = value;
                  });
                  _applyFilters();
                }),
                _buildFilterChip('Fútbol', _selectedSport, ['Todas', 'Fútbol 5', 'Fútbol 7', 'Fútbol 11'], (value) {
                  setState(() {
                    _selectedSport = value;
                  });
                  _applyFilters();
                }),
                _buildFilterChip('Básquet', _selectedSport, ['Todas', 'Básquet'], (value) {
                  setState(() {
                    _selectedSport = value;
                  });
                  _applyFilters();
                }),
                _buildFilterChip('Tenis', _selectedSport, ['Todas', 'Tenis'], (value) {
                  setState(() {
                    _selectedSport = value;
                  });
                  _applyFilters();
                }),
                _buildFilterChip('Vóley', _selectedSport, ['Todas', 'Vóley'], (value) {
                  setState(() {
                    _selectedSport = value;
                  });
                  _applyFilters();
                }),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 🆕 SECCIÓN DE RESULTADOS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getResultsTitle(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gray900,
                  ),
                ),
                if (!_isLoading && _canchasFiltradas.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_canchasFiltradas.length} canchas',
                      style: const TextStyle(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // CONTENIDO PRINCIPAL
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primaryGreen,
              onRefresh: _loadCanchas,
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  String _getResultsTitle() {
    if (_selectedSport != 'Todas') {
      return 'Canchas de $_selectedSport';
    }
    if (_searchQuery.isNotEmpty) {
      return 'Resultados de búsqueda';
    }
    return 'Canchas cerca de ti';
  }

  Widget _buildFilterChip(String label, String selectedValue, List<String> options, Function(String) onSelected) {
    final isSelected = selectedValue.contains(label) || (label == 'Todas' && selectedValue == 'Todas');
    
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            onSelected(label == 'Todas' ? 'Todas' : label);
          }
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
  }

  void _showFilterBottomSheet() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => StatefulBuilder(  // 🔥 CLAVE: StatefulBuilder para actualizar estado
      builder: (context, setModalState) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filtros',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Filtro por horario
            const Text('Horario preferido', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _timeSlots.map((slot) => FilterChip(
                label: Text(slot),
                selected: _selectedTimeSlot == slot,  // ✅ Estado correcto
                onSelected: (selected) {
                  if (selected) {
                    setModalState(() {  // 🔥 USAR setModalState
                      _selectedTimeSlot = slot;
                    });
                    setState(() {  // 🔥 TAMBIÉN setState principal
                      _selectedTimeSlot = slot;
                    });
                    _applyFilters();
                  }
                },
                backgroundColor: Colors.white,
                selectedColor: AppColors.primaryGreen.withOpacity(0.2),
                checkmarkColor: AppColors.primaryGreen,
                labelStyle: TextStyle(
                  color: _selectedTimeSlot == slot ? AppColors.primaryGreen : Colors.grey[700],
                  fontWeight: _selectedTimeSlot == slot ? FontWeight.w600 : FontWeight.normal,
                ),
                side: BorderSide(
                  color: _selectedTimeSlot == slot ? AppColors.primaryGreen : Colors.grey[300]!,
                ),
              )).toList(),
            ),
            
            const SizedBox(height: 20),
            
            // Filtro por ciudad
            const Text('Ciudad', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _cities.map((city) => FilterChip(
                label: Text(city),
                selected: _selectedCity == city,  // ✅ Estado correcto
                onSelected: (selected) {
                  if (selected) {
                    setModalState(() {  // 🔥 USAR setModalState
                      _selectedCity = city;
                    });
                    setState(() {  // 🔥 TAMBIÉN setState principal
                      _selectedCity = city;
                    });
                    _applyFilters();
                  }
                },
                backgroundColor: Colors.white,
                selectedColor: AppColors.primaryGreen.withOpacity(0.2),
                checkmarkColor: AppColors.primaryGreen,
                labelStyle: TextStyle(
                  color: _selectedCity == city ? AppColors.primaryGreen : Colors.grey[700],
                  fontWeight: _selectedCity == city ? FontWeight.w600 : FontWeight.normal,
                ),
                side: BorderSide(
                  color: _selectedCity == city ? AppColors.primaryGreen : Colors.grey[300]!,
                ),
              )).toList(),
            ),
            
            const SizedBox(height: 30),
            
            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setModalState(() {  // 🔥 USAR setModalState
                        _selectedSport = 'Todas';
                        _selectedTimeSlot = 'Cualquier hora';
                        _selectedCity = 'Todas las ciudades';
                        _searchQuery = '';
                      });
                      setState(() {  // 🔥 TAMBIÉN setState principal
                        _selectedSport = 'Todas';
                        _selectedTimeSlot = 'Cualquier hora';
                        _selectedCity = 'Todas las ciudades';
                        _searchQuery = '';
                      });
                      _applyFilters();
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      side: BorderSide(color: Colors.grey[300]!),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Limpiar filtros'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Aplicar'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primaryGreen),
            SizedBox(height: 16),
            Text(
              'Cargando canchas disponibles...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_canchasFiltradas.isEmpty && _canchas.isNotEmpty) {
      return _buildNoResultsState();
    }

    if (_canchas.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _canchasFiltradas.length,
      itemBuilder: (context, index) {
        final cancha = _canchasFiltradas[index];
        return _buildModernCanchaCard(context, cancha);
      },
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No encontramos canchas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta ajustar los filtros o buscar algo diferente',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedSport = 'Todas';
                  _selectedTimeSlot = 'Cualquier hora';
                  _selectedCity = 'Todas las ciudades';
                  _searchQuery = '';
                });
                _applyFilters();
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Limpiar filtros'),
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

  Widget _buildModernCanchaCard(BuildContext context, Map<String, dynamic> cancha) {
    final String nombre = cancha['field_name'] ?? 'Cancha Sin Nombre';
    final String tipo = cancha['field_type'] ?? 'Fútbol';
    final double precio = double.tryParse(cancha['field_hour_price']?.toString() ?? '0') ?? 0.0;
    final String companyName = cancha['company_name'] ?? 'Empresa';
    final String cityName = cancha['city_name'] ?? 'Ciudad';
    final double rating = 4.8; // Simulado - puedes obtenerlo de la BD

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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen de la cancha con overlay
          Container(
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryGreen.withOpacity(0.8),
                  AppColors.primaryGreen,
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Stack(
              children: [
                // Ícono central
                const Center(
                  child: Icon(
                    Icons.sports_soccer,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                
                // Badge de tipo
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tipo,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                
                // Badge de disponibilidad
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Disponible',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Contenido de la card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre y rating
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        nombre,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 2),
                          Text(
                            rating.toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Ubicación
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '$companyName • $cityName',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '1.2 km',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Precio y botón
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '\$${precio.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                            const Text(
                              '/hora',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _showReservarDialog(context, cancha);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Reservar',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
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

  Widget _buildErrorState() {
    return Center(
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
            'Error al cargar canchas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Ocurrió un error inesperado',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadCanchas,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
            ),
          ),
        ],
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
            'No hay canchas disponibles',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aún no se han registrado canchas en el sistema.\nIntenta más tarde.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadCanchas,
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

  Widget _buildDrawer(String userName, String userEmail, String profilePhoto, Map<String, dynamic>? userData, BuildContext context) {
    return Drawer(
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyReservationsScreen(),
                ),
            
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
    );
  }

  // MÉTODO _showReservarDialog CORREGIDO
  Future <void> _showReservarDialog(BuildContext context, Map<String, dynamic> cancha)async {
    final prefs = await SharedPreferences.getInstance();
    final userData = {
    'user_id': prefs.getInt('user_id') ?? 0,
    'user_name': prefs.getString('user_name') ?? 'Usuario',
    'user_email': prefs.getString('user_email') ?? 'email@ejemplo.com',
    'user_role': prefs.getString('user_role') ?? 'cliente',
    'company_id': prefs.getInt('company_id') ?? 0,
  };
   print('🔍 DEBUG - userData obtenido de SharedPreferences: $userData');
   if (userData['user_id'] == 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚠️ Sesión expirada. Por favor, inicia sesión nuevamente.'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }  
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(
              Icons.sports_soccer,
              color: AppColors.primaryGreen,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Reservar ${cancha['field_name']}',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(Icons.category, 'Tipo:', cancha['field_type'] ?? 'N/A'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.aspect_ratio, 'Tamaño:', cancha['field_size'] ?? 'N/A'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.people, 'Capacidad:', '${cancha['field_max_capacity'] ?? 0} personas'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.attach_money, 'Precio:', '\$${cancha['field_hour_price'] ?? '0'}/hora'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.primaryGreen,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Selecciona fecha, horario y sube tu comprobante de pago',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.pushNamed(
                context, 
                '/field-reservation',
                arguments: {
                  'cancha': cancha,
                  'userData': userData,
                },
              );
            },
            icon: const Icon(Icons.calendar_today),
            label: const Text('Continuar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // MÉTODO _buildInfoRow CORREGIDO
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
            ),
          ),
        ),
      ],
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
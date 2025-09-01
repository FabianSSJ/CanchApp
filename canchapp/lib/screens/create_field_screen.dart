import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/field_service.dart';

class CreateFieldScreen extends StatefulWidget {
  const CreateFieldScreen({super.key});

  @override
  State<CreateFieldScreen> createState() => _CreateFieldScreenState();
}

class _CreateFieldScreenState extends State<CreateFieldScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  
  // Controladores de texto
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  // Variables de estado
  String _selectedFieldType = 'Fútbol 5';
  File? _selectedImage;
  bool _isLoading = false;
  int _currentStep = 0;
  
  // NUEVAS VARIABLES para horarios y reservas
  List<Map<String, dynamic>> _schedules = [];
  List<Map<String, dynamic>> _recurringReservations = [];

  @override
  void initState() {
    super.initState();
    _initializeSchedules();
    _checkSessionStatus();
  }

  void _initializeSchedules() {
    // Generar horarios por defecto
    _schedules = FieldService.generateDefaultSchedules();
  }

  Future<void> _checkSessionStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');
      final int? companyId = prefs.getInt('company_id');
      
      if (token == null || token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ No se detectó sesión activa. Verifica tu login.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error checking session: $e');
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _sizeController.dispose();
    _capacityController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Nueva Cancha'),
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepTapped: (step) {
          setState(() {
            _currentStep = step;
          });
        },
        controlsBuilder: (context, details) {
  return Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Row(
      children: [
        if (details.stepIndex < 2)
          ElevatedButton(
            onPressed: () {
              // 🔥 CAMBIO PRINCIPAL: Lógica propia en lugar de details.onStepContinue
              bool canProceed = true;
              
              if (details.stepIndex == 0) {
                // Validar formulario básico
                canProceed = _formKey.currentState?.validate() ?? false;
              }
              
              if (canProceed) {
                setState(() {
                  _currentStep = details.stepIndex + 1;
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
            ),
            child: const Text('Siguiente'),
          ),
        if (details.stepIndex == 2)
          ElevatedButton(
            onPressed: _isLoading ? null : _createField,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
            ),
            child: _isLoading 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text('Crear Cancha'),
          ),
        const SizedBox(width: 8),
        if (details.stepIndex > 0)
          TextButton(
            onPressed: () {
              // 🔥 CAMBIO: Lógica propia en lugar de details.onStepCancel
              setState(() {
                _currentStep = details.stepIndex - 1;
              });
            },
            child: const Text('Anterior'),
          ),
      ],
    ),
  );
},
        steps: [
          // PASO 1: Información básica
          Step(
            title: const Text('Información Básica'),
            content: _buildBasicInfoStep(),
            isActive: _currentStep == 0,
          ),
          // PASO 2: Horarios disponibles
          Step(
            title: const Text('Horarios Disponibles'),
            content: _buildSchedulesStep(),
            isActive: _currentStep == 1,
          ),
          // PASO 3: Reservas recurrentes
          Step(
            title: const Text('Reservas Fijas'),
            content: _buildRecurringReservationsStep(),
            isActive: _currentStep == 2,
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen de la cancha
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 200,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey[400]!),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.sports_soccer,
                            size: 50,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tocar para agregar imagen',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          
          const SizedBox(height: 30),
          
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nombre de la cancha',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.sports_soccer),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa el nombre de la cancha';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 20),
          
          DropdownButtonFormField<String>(
            value: _selectedFieldType,
            decoration: const InputDecoration(
              labelText: 'Tipo de cancha',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.category),
            ),
            items: FieldService.getFieldTypes().map((String type) {
              return DropdownMenuItem<String>(
                value: type,
                child: Text(type),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedFieldType = newValue!;
              });
            },
          ),
          
          const SizedBox(height: 20),
          
          TextFormField(
            controller: _sizeController,
            decoration: const InputDecoration(
              labelText: 'Tamaño (ej: 40x20)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.aspect_ratio),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa el tamaño de la cancha';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 20),
          
          TextFormField(
            controller: _capacityController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Capacidad máxima',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.people),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa la capacidad máxima';
              }
              if (int.tryParse(value) == null) {
                return 'Por favor ingresa un número válido';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 20),
          
          TextFormField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Precio por hora (\$)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.attach_money),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa el precio por hora';
              }
              if (double.tryParse(value) == null) {
                return 'Por favor ingresa un precio válido';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 20),
          
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Descripción',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description),
              alignLabelWithHint: true,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa una descripción';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Configura los horarios de apertura y cierre para cada día de la semana.',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        ...List.generate(_schedules.length, (index) {
          final schedule = _schedules[index];
          final dayName = FieldService.getDayName(schedule['day_of_week']);
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: schedule['is_available'],
                        onChanged: (value) {
                          setState(() {
                            _schedules[index]['is_available'] = value ?? false;
                          });
                        },
                      ),
                      Text(
                        dayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  
                  if (schedule['is_available']) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTimeSelector(
                            'Apertura',
                            schedule['start_time'],
                            (time) {
                              setState(() {
                                _schedules[index]['start_time'] = time;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTimeSelector(
                            'Cierre',
                            schedule['end_time'],
                            (time) {
                              setState(() {
                                _schedules[index]['end_time'] = time;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTimeSelector(String label, String currentTime, Function(String) onTimeChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final time = await showTimePicker(
              context: context,
              initialTime: _parseTime(currentTime),
            );
            
            if (time != null) {
              final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
              onTimeChanged(timeString);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 8),
                Text(FieldService.formatTime(currentTime)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  Widget _buildRecurringReservationsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.green),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Las reservas fijas son horarios ya ocupados por clientes regulares. Estos slots no aparecerán disponibles para otros usuarios.',
                  style: TextStyle(color: Colors.green),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        ElevatedButton.icon(
          onPressed: _addRecurringReservation,
          icon: const Icon(Icons.add),
          label: const Text('Agregar Reserva Fija'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF059669),
            foregroundColor: Colors.white,
          ),
        ),
        
        const SizedBox(height: 20),
        
        if (_recurringReservations.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.event_busy, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'No hay reservas fijas configuradas',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Las reservas fijas son opcionales',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        else
          ...List.generate(_recurringReservations.length, (index) {
            final reservation = _recurringReservations[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(Icons.event_repeat, color: Color(0xFF059669)),
                title: Text(
                  '${FieldService.getDayName(reservation['day_of_week'])} - ${FieldService.formatTime(reservation['start_time'])} a ${FieldService.formatTime(reservation['end_time'])}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Cliente: ${reservation['client_name']}\nPrecio: \$${reservation['payment_amount']}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _recurringReservations.removeAt(index);
                    });
                  },
                ),
              ),
            );
          }),
      ],
    );
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cámara'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(
                  source: ImageSource.camera,
                  maxWidth: 1024,
                  maxHeight: 1024,
                  imageQuality: 80,
                );
                if (image != null) {
                  setState(() {
                    _selectedImage = File(image.path);
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 1024,
                  maxHeight: 1024,
                  imageQuality: 80,
                );
                if (image != null) {
                  setState(() {
                    _selectedImage = File(image.path);
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addRecurringReservation() {
    showDialog(
      context: context,
      builder: (context) => _RecurringReservationDialog(
        onAdd: (reservation) {
          setState(() {
            _recurringReservations.add(reservation);
          });
        },
      ),
    );
  }

  // REEMPLAZA el método _createField en tu CreateFieldScreen:

Future<void> _createField() async {
  if (!_formKey.currentState!.validate()) {
    setState(() {
      _currentStep = 0;
    });
    return;
  }

  setState(() {
    _isLoading = true;
  });

  try {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');
    final int? companyId = prefs.getInt('company_id');
    
    if (token == null || token.trim().isEmpty) {
      _showErrorDialog('Sesión expirada. Por favor, cierra la app e inicia sesión nuevamente.');
      return;
    }
    
    if (companyId == null || companyId <= 0) {
      _showErrorDialog('No se encontró información de empresa. Reinicia la sesión.');
      return;
    }

    // Filtrar solo horarios habilitados
    final activeSchedules = _schedules.where((schedule) => schedule['is_available'] == true).toList();

    // 🔄 USAR EL NUEVO MÉTODO si hay horarios o reservas configuradas
    Map<String, dynamic> result;
    
    if (activeSchedules.isNotEmpty || _recurringReservations.isNotEmpty) {
      print('🆕 Creando cancha CON horarios y reservas personalizadas');
      result = await FieldService.createFieldWithSchedules(
        token: token.trim(),
        companyId: companyId,
        fieldName: _nameController.text.trim(),
        fieldType: _selectedFieldType,
        fieldSize: _sizeController.text.trim(),
        fieldMaxCapacity: int.parse(_capacityController.text),
        fieldHourPrice: double.parse(_priceController.text),
        fieldDescription: _descriptionController.text.trim(),
        fieldImage: _selectedImage,
        schedules: activeSchedules,
        recurringReservations: _recurringReservations,
      );
    } else {
      print('✅ Creando cancha BÁSICA (sin horarios personalizados)');
      result = await FieldService.createField(
        token: token.trim(),
        companyId: companyId,
        fieldName: _nameController.text.trim(),
        fieldType: _selectedFieldType,
        fieldSize: _sizeController.text.trim(),
        fieldMaxCapacity: int.parse(_capacityController.text),
        fieldHourPrice: double.parse(_priceController.text),
        fieldDescription: _descriptionController.text.trim(),
        fieldImage: _selectedImage,
      );
    }

    if (result['success']) {
      _showSuccessDialog();
    } else {
      _showErrorDialog(result['message'] ?? 'Error desconocido');
    }
    
  } catch (e) {
    String errorMessage = 'Error inesperado: $e';
    
    if (e.toString().contains('FormatException')) {
      errorMessage = 'Error en el formato de los datos. Verifica los números ingresados.';
    } else if (e.toString().contains('SocketException')) {
      errorMessage = 'Error de conexión. Verifica tu internet.';
    } else if (e.toString().contains('TimeoutException')) {
      errorMessage = 'Tiempo de espera agotado. Intenta nuevamente.';
    }
    
    _showErrorDialog(errorMessage);
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

  // REEMPLAZA tu método _showSuccessDialog en CreateFieldScreen:

void _showSuccessDialog() {
  showDialog(
    context: context,
    barrierDismissible: false, // No se puede cerrar tocando fuera
    builder: (context) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 28),
          SizedBox(width: 12),
          Text('¡Cancha Creada!'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tu cancha se ha creado exitosamente y ya está disponible para todos los usuarios.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Los jugadores ya pueden ver y reservar esta cancha.',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 14,
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
          onPressed: () async {
            Navigator.pop(context); // Cerrar dialog
            
            // 🔥 NAVEGAR AL OWNER HOME SIN PERDER DATOS
            final prefs = await SharedPreferences.getInstance();
            final userData = {
              'userName': prefs.getString('user_name') ?? 'Usuario',
              'userEmail': prefs.getString('user_email') ?? 'email@ejemplo.com',
              'userRole': prefs.getString('user_role') ?? 'dueno',
              'userId': prefs.getInt('user_id') ?? 0,
              'companyId': prefs.getInt('company_id') ?? 0,
            };
            
            // Navegar al owner home con datos del usuario
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/owner-home',
              (route) => false, // Limpiar stack de navegación
              arguments: userData, // Pasar datos del usuario
            );
          },
          style: TextButton.styleFrom(
            backgroundColor: const Color(0xFF059669),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Ir al Inicio',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            const Text(
              'Soluciones recomendadas:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Cierra la aplicación completamente'),
            const Text('• Vuelve a iniciar sesión'),
            const Text('• Verifica tu conexión a internet'),
          ],
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
}

// Dialog para agregar reservas recurrentes
class _RecurringReservationDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onAdd;
  
  const _RecurringReservationDialog({required this.onAdd});

  @override
  State<_RecurringReservationDialog> createState() => _RecurringReservationDialogState();
}

class _RecurringReservationDialogState extends State<_RecurringReservationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _clientNameController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  
  int _selectedDay = 1; // Lunes por defecto
  TimeOfDay _startTime = const TimeOfDay(hour: 19, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 20, minute: 0);
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _hasEndDate = false;

  @override
  void dispose() {
    _clientNameController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva Reserva Fija'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nombre del cliente
              TextFormField(
                controller: _clientNameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del cliente',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa el nombre del cliente';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Día de la semana
              DropdownButtonFormField<int>(
                value: _selectedDay,
                decoration: const InputDecoration(
                  labelText: 'Día de la semana',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                items: [
                  const DropdownMenuItem(value: 1, child: Text('Lunes')),
                  const DropdownMenuItem(value: 2, child: Text('Martes')),
                  const DropdownMenuItem(value: 3, child: Text('Miércoles')),
                  const DropdownMenuItem(value: 4, child: Text('Jueves')),
                  const DropdownMenuItem(value: 5, child: Text('Viernes')),
                  const DropdownMenuItem(value: 6, child: Text('Sábado')),
                  const DropdownMenuItem(value: 0, child: Text('Domingo')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedDay = value!;
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // Horarios
              Row(
                children: [
                  Expanded(
                    child: _buildTimeField('Hora inicio', _startTime, (time) {
                      setState(() {
                        _startTime = time;
                      });
                    }),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTimeField('Hora fin', _endTime, (time) {
                      setState(() {
                        _endTime = time;
                      });
                    }),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Precio
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Precio por sesión (\$)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa el precio';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Ingresa un precio válido';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Fecha de inicio
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: const Text('Fecha de inicio'),
                subtitle: Text(_formatDate(_startDate)),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() {
                      _startDate = date;
                    });
                  }
                },
              ),
              
              // Fecha de fin (opcional)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tiene fecha de fin'),
                value: _hasEndDate,
                onChanged: (value) {
                  setState(() {
                    _hasEndDate = value ?? false;
                    if (!_hasEndDate) {
                      _endDate = null;
                    }
                  });
                },
              ),
              
              if (_hasEndDate)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_busy),
                  title: const Text('Fecha de fin'),
                  subtitle: Text(_endDate != null ? _formatDate(_endDate!) : 'Seleccionar fecha'),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? _startDate.add(const Duration(days: 30)),
                      firstDate: _startDate,
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        _endDate = date;
                      });
                    }
                  },
                ),
              
              const SizedBox(height: 16),
              
              // Notas
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _addReservation,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF059669),
            foregroundColor: Colors.white,
          ),
          child: const Text('Agregar'),
        ),
      ],
    );
  }

  Widget _buildTimeField(String label, TimeOfDay time, Function(TimeOfDay) onChanged) {
    return InkWell(
      onTap: () async {
        final selectedTime = await showTimePicker(
          context: context,
          initialTime: time,
        );
        if (selectedTime != null) {
          onChanged(selectedTime);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.access_time),
        ),
        child: Text(time.format(context)),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _addReservation() {
    if (!_formKey.currentState!.validate()) return;
    
    if (_hasEndDate && _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona la fecha de fin')),
      );
      return;
    }

    // Validar que la hora de fin sea después de la hora de inicio
    if (_endTime.hour < _startTime.hour || 
        (_endTime.hour == _startTime.hour && _endTime.minute <= _startTime.minute)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La hora de fin debe ser después de la hora de inicio')),
      );
      return;
    }

    final reservation = {
      'user_id': null, 
      'created_by_owner_id': null,
      'recurring_type': 'semanal',
      'day_of_week': _selectedDay,
      'start_time': '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}:00',
      'end_time': '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}:00',
      'start_date': '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}',
      'end_date': _endDate != null ? '${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}' : null,
      'payment_amount': double.parse(_priceController.text),
      'notes': _notesController.text.isNotEmpty ? _notesController.text : null,
      'client_name': _clientNameController.text, // Para mostrar en la UI
    };

    widget.onAdd(reservation);
    Navigator.pop(context);
  }
}
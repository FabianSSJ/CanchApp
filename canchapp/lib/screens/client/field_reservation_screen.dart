import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../utils/colors.dart';
import '../../services/reservation_service.dart';
import '../../services/field_service.dart';

class FieldReservationScreen extends StatefulWidget {
  const FieldReservationScreen({super.key});

  @override
  State<FieldReservationScreen> createState() => _FieldReservationScreenState();
}

class _FieldReservationScreenState extends State<FieldReservationScreen> {
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  File? _receiptImage;
  bool _isLoading = false;
  
  final ImagePicker _imagePicker = ImagePicker();
  
  // Horarios disponibles (de 6 AM a 12 AM)
  final List<String> _timeSlots = [
    '06:00 - 07:00', '07:00 - 08:00', '08:00 - 09:00', '09:00 - 10:00',
    '10:00 - 11:00', '11:00 - 12:00', '12:00 - 13:00', '13:00 - 14:00',
    '14:00 - 15:00', '15:00 - 16:00', '16:00 - 17:00', '17:00 - 18:00',
    '18:00 - 19:00', '19:00 - 20:00', '20:00 - 21:00', '21:00 - 22:00',
    '22:00 - 23:00', '23:00 - 00:00'
  ];
  
  List<String> _availableTimeSlots = [];
  bool _loadingAvailability = false;

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? arguments = 
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    final Map<String, dynamic> cancha = arguments?['cancha'] ?? {};
    final Map<String, dynamic> userData = arguments?['userData'] ?? {};
    
    final String canchaName = cancha['field_name'] ?? 'Cancha';
    final double precio = double.tryParse(cancha['field_hour_price']?.toString() ?? '0') ?? 0.0;
    final int fieldId = cancha['field_id'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Reservar $canchaName'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header con información de la cancha
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
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.sports_soccer,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                canchaName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                cancha['field_type'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Precio por hora:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '\$${precio.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sección de fecha
                  _buildSectionTitle('1. Selecciona la fecha'),
                  const SizedBox(height: 12),
                  _buildDateSelector(),
                  
                  const SizedBox(height: 24),
                  
                  // Sección de horario
                  _buildSectionTitle('2. Elige tu horario'),
                  const SizedBox(height: 12),
                  _buildTimeSlotSelector(fieldId),
                  
                  const SizedBox(height: 24),
                  
                  // Sección de comprobante
                  _buildSectionTitle('3. Sube tu comprobante de pago'),
                  const SizedBox(height: 12),
                  _buildReceiptUploader(),
                  
                  const SizedBox(height: 32),
                  
                  // Botón de confirmar reserva
                  _buildConfirmButton(cancha, userData),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.gray900,
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.gray300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const Icon(
          Icons.calendar_today,
          color: AppColors.primaryGreen,
        ),
        title: Text(
          _selectedDate != null
              ? 'Fecha: ${_formatDate(_selectedDate!)}'
              : 'Seleccionar fecha',
          style: TextStyle(
            color: _selectedDate != null ? AppColors.gray900 : AppColors.gray600,
            fontWeight: _selectedDate != null ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: _selectDate,
      ),
    );
  }

  Widget _buildTimeSlotSelector(int fieldId) {
    if (_selectedDate == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.gray100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gray300),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.gray600),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Primero selecciona una fecha para ver los horarios disponibles',
                style: TextStyle(
                  color: AppColors.gray600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_loadingAvailability) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(color: AppColors.primaryGreen),
        ),
      );
    }

    if (_availableTimeSlots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.event_busy, color: Colors.red.shade600),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'No hay horarios disponibles para esta fecha',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.gray300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule, color: AppColors.primaryGreen),
                const SizedBox(width: 8),
                Text(
                  'Horarios disponibles (${_availableTimeSlots.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray900,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 8,
              ),
              itemCount: _availableTimeSlots.length,
              itemBuilder: (context, index) {
                final timeSlot = _availableTimeSlots[index];
                final isSelected = _selectedTimeSlot == timeSlot;
                
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedTimeSlot = timeSlot;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryGreen : Colors.white,
                      border: Border.all(
                        color: isSelected ? AppColors.primaryGreen : AppColors.gray300,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        timeSlot,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.gray700,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptUploader() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.gray300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (_receiptImage != null) ...[
            Container(
              width: double.infinity,
              height: 200,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Image.file(
                  _receiptImage!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Comprobante cargado correctamente',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _receiptImage = null;
                      });
                    },
                    child: const Text('Cambiar'),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 48,
                    color: AppColors.gray400,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Sube tu comprobante de pago',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Formatos: JPG, PNG (máx. 5MB)',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.gray500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Cámara'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryGreen,
                            side: const BorderSide(color: AppColors.primaryGreen),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Galería'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryGreen,
                            side: const BorderSide(color: AppColors.primaryGreen),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConfirmButton(Map<String, dynamic> cancha, Map<String, dynamic> userData) {
    final bool isFormComplete = _selectedDate != null && 
                               _selectedTimeSlot != null && 
                               _receiptImage != null;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isFormComplete && !_isLoading 
            ? () => _confirmReservation(cancha, userData)
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isFormComplete ? AppColors.primaryGreen : AppColors.gray300,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: isFormComplete ? 3 : 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Confirmar Reserva',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryGreen,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedTimeSlot = null; // Reset time slot when date changes
      });
      await _loadAvailableTimeSlots();
    }
  }

  Future<void> _loadAvailableTimeSlots() async {
  setState(() {
    _loadingAvailability = true;
    _availableTimeSlots = [];
  });

  try {
    // Obtener datos de la cancha desde los argumentos
    final Map<String, dynamic>? arguments = 
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final Map<String, dynamic> cancha = arguments?['cancha'] ?? {};
    final int fieldId = cancha['field_id'] ?? 0;
    
    if (fieldId == 0) {
      throw Exception('ID de cancha no válido');
    }

    // Formatear la fecha para la API (YYYY-MM-DD)
    final String formattedDate = _formatDateForApi(_selectedDate!);
    
    print('🔍 Obteniendo horarios disponibles para cancha $fieldId en fecha $formattedDate');
    
    // 🔥 LLAMAR A LA API REAL
    final result = await FieldService.getAvailableSlots(fieldId, formattedDate);
    
    print('📄 Resultado horarios: $result');
    
    if (result['success']) {
      List<String> availableSlots = [];
      
      // Procesar los datos de la API
      if (result['data'] is List) {
        final List<dynamic> schedules = result['data'];
        
        for (var schedule in schedules) {
          final String startTime = schedule['start_time'] ?? '';
          final String endTime = schedule['end_time'] ?? '';
          
          if (startTime.isNotEmpty && endTime.isNotEmpty) {
            // Convertir de formato 24h a formato de display
            final String displaySlot = '${_formatTimeDisplay(startTime)} - ${_formatTimeDisplay(endTime)}';
            availableSlots.add(displaySlot);
          }
        }
      }
      
      setState(() {
        _availableTimeSlots = availableSlots;
        _loadingAvailability = false;
      });
      
      print('✅ Horarios cargados: ${_availableTimeSlots.length}');
      
    } else {
      setState(() {
        _loadingAvailability = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Error obteniendo horarios'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
    
  } catch (e) {
    setState(() {
      _loadingAvailability = false;
    });
    
    print('💥 Error cargando horarios: $e');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cargando horarios: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// 🆕 MÉTODO PARA FORMATEAR HORA DE 24H A DISPLAY
String _formatTimeDisplay(String time24) {
  try {
    // time24 viene como "14:00:00" o "14:00"
    final parts = time24.split(':');
    int hour = int.parse(parts[0]);
    final minute = parts[1];
    
    String period = hour >= 12 ? 'PM' : 'AM';
    if (hour == 0) hour = 12;
    if (hour > 12) hour -= 12;
    
    return '$hour:$minute $period';
  } catch (e) {
    return time24; // Si falla, devolver el original
  }
}

// 🆕 MÉTODO PARA CONVERTIR SLOT DISPLAY A FORMATO API
Map<String, String> _parseTimeSlot(String timeSlot) {
  try {
    // timeSlot viene como "2:00 PM - 3:00 PM"
    final parts = timeSlot.split(' - ');
    if (parts.length != 2) throw Exception('Formato inválido');
    
    final startTime = _convertTo24Hour(parts[0]);
    final endTime = _convertTo24Hour(parts[1]);
    
    return {
      'start_time': startTime,
      'end_time': endTime,
    };
  } catch (e) {
    return {
      'start_time': '00:00:00',
      'end_time': '01:00:00',
    };
  }
}

// 🆕 MÉTODO PARA CONVERTIR DE 12H A 24H
String _convertTo24Hour(String time12) {
  try {
    // time12 viene como "2:00 PM"
    final parts = time12.trim().split(' ');
    final timePart = parts[0];
    final period = parts[1];
    
    final timeComponents = timePart.split(':');
    int hour = int.parse(timeComponents[0]);
    final minute = timeComponents[1];
    
    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    
    return '${hour.toString().padLeft(2, '0')}:$minute:00';
  } catch (e) {
    return '00:00:00';
  }
}

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _receiptImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error seleccionando imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmReservation(Map<String, dynamic> cancha, Map<String, dynamic> userData) async {
  if (_selectedDate == null || _selectedTimeSlot == null || _receiptImage == null) {
    return;
  }

  setState(() {
    _isLoading = true;
  });

  try {
    // 🔥 PARSEAR HORARIOS REALES
    final timeData = _parseTimeSlot(_selectedTimeSlot!);
    final startTime = timeData['start_time']!;
    final endTime = timeData['end_time']!;
    
    print('🕐 Horario seleccionado: $_selectedTimeSlot');
    print('🕐 Convertido a: $startTime - $endTime');

    // Llamar al servicio de reservas (cuando lo implementes)
    final result = await ReservationService.createReservation(
      fieldId: cancha['field_id'],
      userId: userData['user_id'],
      date: _formatDateForApi(_selectedDate!),
      startTime: startTime,
      endTime: endTime,
      paymentAmount: double.tryParse(cancha['field_hour_price']?.toString() ?? '0') ?? 0.0,
      receiptImage: _receiptImage!,
    );

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      if (result['success']) {
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Error creando reserva'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  } catch (e) {
    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('¡Reserva Creada!'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tu reserva ha sido enviada exitosamente.'),
            SizedBox(height: 8),
            Text(
              'El administrador revisará tu comprobante de pago y confirmará la reserva.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(); // Regresar a la pantalla anterior
            },
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    
    return '${date.day} de ${months[date.month - 1]}, ${date.year}';
  }

  String _formatDateForApi(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
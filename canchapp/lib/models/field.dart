class Field {
  final int fieldId;
  final int companyId;
  final String fieldName;
  final String fieldType;
  final String fieldSize;
  final int? fieldMaxCapacity;
  final double fieldHourPrice;
  final String fieldDescription;
  final String? fieldImg;
  final double? fieldCalification;
  final bool fieldDelete;

  Field({
    required this.fieldId,
    required this.companyId,
    required this.fieldName,
    required this.fieldType,
    required this.fieldSize,
    this.fieldMaxCapacity,
    required this.fieldHourPrice,
    required this.fieldDescription,
    this.fieldImg,
    this.fieldCalification,
    required this.fieldDelete,
  });

  factory Field.fromJson(Map<String, dynamic> json) {
    return Field(
      fieldId: json['field_id'] ?? 0,
      companyId: json['company_id'] ?? 0,
      fieldName: json['field_name'] ?? '',
      fieldType: json['field_type'] ?? '',
      fieldSize: json['field_size'] ?? '',
      fieldMaxCapacity: json['field_max_capacity'],
      fieldHourPrice: (json['field_hour_price'] ?? 0).toDouble(),
      fieldDescription: json['field_description'] ?? '',
      fieldImg: json['field_img'],
      fieldCalification: json['field_calification']?.toDouble(),
      fieldDelete: json['field_delete'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'field_id': fieldId,
      'company_id': companyId,
      'field_name': fieldName,
      'field_type': fieldType,
      'field_size': fieldSize,
      'field_max_capacity': fieldMaxCapacity,
      'field_hour_price': fieldHourPrice,
      'field_description': fieldDescription,
      'field_img': fieldImg,
      'field_calification': fieldCalification,
      'field_delete': fieldDelete,
    };
  }

  // Getter para obtener el icono según el tipo de cancha
  String get fieldIcon {
    switch (fieldType) {
      case 'Fútbol 5':
      case 'Fútbol 7':
      case 'Fútbol 11':
        return '⚽';
      case 'Basquet 3x3':
      case 'Basquet 5x5':
        return '🏀';
      case 'Tenis':
        return '🎾';
      case 'EcuaVoley':
        return '🏐';
      default:
        return '🏟️';
    }
  }

  // Getter para la calificación formateada
  String get formattedRating {
    if (fieldCalification == null) return 'Sin calificar';
    return fieldCalification!.toStringAsFixed(1);
  }

  // Getter para el precio formateado
  String get formattedPrice {
    return '\$${fieldHourPrice.toStringAsFixed(2)}/hora';
  }
}
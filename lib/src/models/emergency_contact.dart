class EmergencyContact {
  final int id;
  final String name;
  final String phone;
  final String? email;
  final String? fcmToken;
  final String? relationship;
  final bool isActive;
  final int priority;
  final int userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.fcmToken,
    this.relationship,
    required this.isActive,
    required this.priority,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      email: json['email'],
      fcmToken: json['fcmToken'],
      relationship: json['relationship'],
      isActive: json['isActive'] ?? true,
      priority: json['priority'] ?? 1,
      userId: json['userId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'fcmToken': fcmToken,
      'relationship': relationship,
      'isActive': isActive,
      'priority': priority,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  EmergencyContact copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
    String? fcmToken,
    String? relationship,
    bool? isActive,
    int? priority,
    int? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      fcmToken: fcmToken ?? this.fcmToken,
      relationship: relationship ?? this.relationship,
      isActive: isActive ?? this.isActive,
      priority: priority ?? this.priority,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Método para obtener el icono según la relación
  String get relationshipIcon {
    switch (relationship?.toLowerCase()) {
      case 'familia':
        return '👨‍👩‍👧‍👦';
      case 'amigo':
        return '👥';
      case 'trabajo':
        return '💼';
      case 'vecino':
        return '🏠';
      case 'médico':
        return '👨‍⚕️';
      case 'policía':
        return '👮‍♂️';
      default:
        return '📞';
    }
  }

  // Método para obtener el color según la prioridad
  int get priorityColor {
    switch (priority) {
      case 1:
        return 0xFFE53E3E; // Rojo
      case 2:
        return 0xFFDD6B20; // Naranja
      case 3:
        return 0xFFD69E2E; // Amarillo
      case 4:
        return 0xFF38A169; // Verde
      case 5:
        return 0xFF3182CE; // Azul
      default:
        return 0xFF718096; // Gris
    }
  }
} 
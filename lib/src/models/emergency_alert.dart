enum AlertStatus {
  active,
  resolved,
  falseAlarm,
}

enum AlertType {
  panicButton,
  automaticDetection,
  manualTrigger,
}

class EmergencyAlert {
  final int id;
  final AlertType type;
  final AlertStatus status;
  final String? description;
  final double? latitude;
  final double? longitude;
  final String? location;
  final String? videoUrl;
  final String? audioUrl;
  final int duration;
  final Map<String, dynamic>? metadata;
  final String? docHash;
  final String? txHash;
  final String blockchainStatus;
  final String? certificadoUrl;
  final DateTime? resolvedAt;
  final String? resolutionNotes;
  final int userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  EmergencyAlert({
    required this.id,
    required this.type,
    required this.status,
    this.description,
    this.latitude,
    this.longitude,
    this.location,
    this.videoUrl,
    this.audioUrl,
    required this.duration,
    this.metadata,
    this.docHash,
    this.txHash,
    this.blockchainStatus = 'sin_registro',
    this.certificadoUrl,
    this.resolvedAt,
    this.resolutionNotes,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EmergencyAlert.fromJson(Map<String, dynamic> json) {
    return EmergencyAlert(
      id: json['id'],
      type: AlertType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => AlertType.panicButton,
      ),
      status: AlertStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => AlertStatus.active,
      ),
      description: json['description'],
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      location: json['location'],
      videoUrl: json['videoUrl'],
      audioUrl: json['audioUrl'],
      duration: json['duration'] ?? 0,
      metadata: json['metadata'],
      docHash: json['doc_hash'],
      txHash: json['tx_hash'],
      blockchainStatus: json['blockchain_status'] ?? 'sin_registro',
      certificadoUrl: json['certificado_url'],
      resolvedAt: json['resolvedAt'] != null 
          ? DateTime.parse(json['resolvedAt']) 
          : null,
      resolutionNotes: json['resolutionNotes'],
      userId: json['userId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'location': location,
      'videoUrl': videoUrl,
      'audioUrl': audioUrl,
      'duration': duration,
      'metadata': metadata,
      'resolvedAt': resolvedAt?.toIso8601String(),
      'resolutionNotes': resolutionNotes,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  EmergencyAlert copyWith({
    int? id,
    AlertType? type,
    AlertStatus? status,
    String? description,
    double? latitude,
    double? longitude,
    String? location,
    String? videoUrl,
    String? audioUrl,
    int? duration,
    Map<String, dynamic>? metadata,
    DateTime? resolvedAt,
    String? resolutionNotes,
    int? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmergencyAlert(
      id: id ?? this.id,
      type: type ?? this.type,
      status: status ?? this.status,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      location: location ?? this.location,
      videoUrl: videoUrl ?? this.videoUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      duration: duration ?? this.duration,
      metadata: metadata ?? this.metadata,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 
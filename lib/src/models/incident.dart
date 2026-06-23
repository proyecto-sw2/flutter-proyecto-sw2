class Incidentes {
  List<Incidente> incidentes;

  Incidentes({required this.incidentes});

  factory Incidentes.fromJson(Map<String, dynamic> json) => Incidentes(
        incidentes: List<Incidente>.from(
            json["incidentes"].map((x) => Incidente.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "incidentes": List<dynamic>.from(incidentes.map((x) => x.toJson())),
      };
}

class Incidente {
  int idIncidente;
  String tipoIncidente;
  String descripcion;
  String latitudLongitud;
  DateTime fechaIncidente;
  String? docHash;
  String? txHash;
  String? blockchainStatus;

  Incidente({
    required this.idIncidente,
    required this.tipoIncidente,
    required this.descripcion,
    required this.latitudLongitud,
    required this.fechaIncidente,
    this.docHash,
    this.txHash,
    this.blockchainStatus,
  });

  factory Incidente.fromJson(Map<String, dynamic> json) => Incidente(
        idIncidente: json["id_incidente"],
        tipoIncidente: json["tipo_incidente"],
        descripcion: json["descripcion"],
        latitudLongitud: json["latitud_longitud"],
        fechaIncidente: DateTime.parse(json["fecha_incidente"]),
        docHash: json["doc_hash"],
        txHash: json["tx_hash"],
        blockchainStatus: json["blockchain_status"],
      );

  Map<String, dynamic> toJson() => {
        "id_incidente": idIncidente,
        "tipo_incidente": tipoIncidente,
        "descripcion": descripcion,
        "latitud_longitud": latitudLongitud,
        "fecha_incidente": fechaIncidente.toIso8601String(),
        "doc_hash": docHash,
        "tx_hash": txHash,
        "blockchain_status": blockchainStatus,
      };
}

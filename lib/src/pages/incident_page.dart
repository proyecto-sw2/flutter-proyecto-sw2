import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_sw1/main.dart';
import 'package:flutter_sw1/src/models/incident.dart';
import 'package:flutter_sw1/src/models/user.dart';
import 'package:flutter_sw1/src/services/incident_service.dart';
import 'package:flutter_sw1/src/services/notification_service.dart';
import 'package:flutter_sw1/src/services/publications_service.dart';
import 'package:flutter_sw1/src/services/user_service.dart';
import 'package:flutter_sw1/src/theme/app_colors.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IncidentPage extends StatefulWidget {
  final LatLng? initialTarget;
  const IncidentPage({super.key, this.initialTarget});

  @override
  State<IncidentPage> createState() => _IncidentPageState();
}

class _IncidentPageState extends State<IncidentPage> {
  SharedPreferences? _prefs;
  final TextEditingController _descController = TextEditingController();
  String _selectedMarkerType = 'accidente';
  StreamSubscription<Position>? _positionStreamSubscription;
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  LatLng _selectedPosition = const LatLng(-16.5, -68.15);
  LatLng? _currentPosition;
  final Map<String, BitmapDescriptor> _markerIcons = {};
  bool _isPublic = true;
  @override
  void initState() {
    super.initState();
    Future.microtask(() => _initLocation());
    _loadMarkerIcons();
    obneterIncidentes();
  }

  void obneterIncidentes() async {
    _prefs = await SharedPreferences.getInstance();
    final incidentes = await getIncidentes();
    if (incidentes != null) {
      setState(() {
        _markers.clear();
        for (var incidente in incidentes.incidentes) {
          LatLng latLng = stringToLatLng(incidente.latitudLongitud);
          Marker marker = Marker(
            markerId: MarkerId(DateTime.now().toIso8601String()),
            position: latLng,
            icon:
                _markerIcons[incidente.tipoIncidente] ??
                BitmapDescriptor.defaultMarker,
            infoWindow: InfoWindow(
              title: incidente.tipoIncidente.toUpperCase(),
              snippet:
                  incidente.descripcion.isNotEmpty
                      ? incidente.descripcion
                      : 'Sin descripción',
            ),
            onTap: () {
              _mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(latLng, 18.0),
              );
            },
          );
          _markers.add(marker);
        }
      });
    }
  }

  Future<void> _loadMarkerIcons() async {
    final iconNames = {
      'accidente': 'assets/markers/accident.png',
      'bloqueo': 'assets/markers/block.png',
      'trafico': 'assets/markers/traffic.png',
      'otro': 'assets/markers/other.png',
    };

    for (var entry in iconNames.entries) {
      _markerIcons[entry.key] = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(32, 32)),
        entry.value,
      );
    }
  }

  Future<void> _initLocation() async {
    final status = await Permission.locationWhenInUse.request();
    if (status != PermissionStatus.granted) {
      return;
    }
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _selectedPosition = _currentPosition!;
    });

    if (_mapController != null) {
      if (widget.initialTarget != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(widget.initialTarget!, 15),
        );
      } else {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_currentPosition!, 15),
        );
      }
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition!, 15),
      );
    }
    _positionStreamSubscription = Geolocator.getPositionStream().listen((pos) {
      if (!mounted) return;
      setState(() {
        _currentPosition = LatLng(pos.latitude, pos.longitude);
      });
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _showMarkerDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Agregar Incidente',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedMarkerType,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Incidente',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'accidente',
                          child: Text('Accidente'),
                        ),
                        DropdownMenuItem(
                          value: 'bloqueo',
                          child: Text('Bloqueo'),
                        ),
                        DropdownMenuItem(
                          value: 'trafico',
                          child: Text('Tráfico'),
                        ),
                        DropdownMenuItem(value: 'otro', child: Text('Otro')),
                      ],
                      onChanged: (String? value) {
                        if (value != null) {
                          setModalState(() {
                            _selectedMarkerType = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('Publicar'),
                      value: _isPublic,
                      onChanged: (bool? value) {
                        setModalState(() {
                          _isPublic = value ?? false;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        _addMarker();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        'Guardar Incidente',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _addMarker() async {
    final position = _selectedPosition;
    final marker = Marker(
      markerId: MarkerId(DateTime.now().toIso8601String()),
      position: position,
      icon: _markerIcons[_selectedMarkerType] ?? BitmapDescriptor.defaultMarker,
      infoWindow: InfoWindow(
        title: _selectedMarkerType.toUpperCase(),
        snippet:
            _descController.text.isNotEmpty
                ? _descController.text
                : 'Sin descripción',
      ),
      onTap: () {
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(position, 18.0),
        );
      },
    );
    try {
      Incidente? incidente = await crearIncidente(
        _selectedMarkerType,
        _descController.text,
        position,
      );
      if (incidente == null) {
        throw Exception('Error al crear el incidente');
      }
      List<User> users = await obtenerUsuarios();
      if (users.isEmpty) {
        throw Exception('No se encontraron usuarios para notificar');
      }
      // Notificar a los usuarios
      final idUser = _prefs?.getInt('user_id') ?? 0;
      for (User user in users) {
        if (user.id != idUser) {
          try {
            NotificationService(navigatorKey).sendPushNotification(
              deviceToken: user.dispositivo!,
              title: _selectedMarkerType,
              body: _descController.text,
              data: {
                'latitud': position.latitude.toString(),
                'longitud': position.longitude.toString(),
              },
            );
          } catch (e) {
            print('Error al enviar notificación a ${user.name}: $e');
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: const Text(
            'Incidente creado exitosamente',
            textAlign: TextAlign.center,
          ),
        ),
      );
      try {
        if (_isPublic) {
          await PublicationsService.createPubMaps(
            incidente.tipoIncidente,
            incidente.descripcion,
            incidente.idIncidente,
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              'Error al crear la publicación: $e',
              textAlign: TextAlign.center,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Error al crear el incidente: $e',
            textAlign: TextAlign.center,
          ),
        ),
      );
      return;
    }

    setState(() {
      _markers.add(marker);
      _descController.clear();
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _descController.dispose();
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mapa de Incidentes',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              obneterIncidentes();
            },
          ),
        ],
      ),
      body:
          _currentPosition == null
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: widget.initialTarget ?? _currentPosition!,
                  zoom: 17,
                ),
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                mapType: MapType.normal,
                markers: _markers,
                onLongPress: (LatLng position) {
                  setState(() {
                    _selectedPosition = position;
                  });
                  _showMarkerDialog();
                },
              ),
    );
  }
}

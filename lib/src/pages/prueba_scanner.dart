import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AnalizarSenalPage extends StatefulWidget {
  @override
  _AnalizarSenalPageState createState() => _AnalizarSenalPageState();
}

class _AnalizarSenalPageState extends State<AnalizarSenalPage> {
  File? _imageFile;
  String? _descripcion;
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
        _descripcion = null;
      });
      await _enviarImagen(File(picked.path));
    }
  }

  Future<void> _enviarImagen(File imagen) async {
    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse(
      'https://v9k5scrk-8000.brs.devtunnels.ms/analizar',
    ); // Cambia si usas IP real

    final request = http.MultipartRequest('POST', url);
    request.files.add(await http.MultipartFile.fromPath('file', imagen.path));

    try {
      final response = await request.send();
      final respStr = await response.stream.bytesToString();
      final data = json.decode(respStr);

      if (response.statusCode == 200) {
        setState(() {
          _descripcion = data['descripcion'];
        });
      } else {
        setState(() {
          _descripcion = 'Error: ${data['error']}';
        });
      }
    } catch (e) {
      setState(() {
        _descripcion = 'Error al enviar la imagen: $e';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _limpiarEstado() {
    setState(() {
      _imageFile = null;
      _descripcion = null;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // <- Habilita ajuste automático
      appBar: AppBar(title: const Text('Escaneo de Señales')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Escaneo de Señales',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(height: 20),
              if (_imageFile != null)
                Image.file(_imageFile!)
              else
                Container(
                  height: 200,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.image_not_supported,
                        size: 60,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'No hay imagen seleccionada',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              if (_isLoading) const CircularProgressIndicator(),
              if (_descripcion != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    _descripcion!,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Cámara'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galería'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _limpiarEstado,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Limpiar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

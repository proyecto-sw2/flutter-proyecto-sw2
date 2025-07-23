import 'package:flutter/material.dart';
import 'package:flutter_sw1/src/models/emergency_contact.dart';
import 'package:flutter_sw1/src/services/emergency_service.dart';
import 'package:flutter_sw1/src/theme/app_colors.dart';

class EmergencyContactsPage extends StatefulWidget {
  const EmergencyContactsPage({super.key});

  @override
  State<EmergencyContactsPage> createState() => _EmergencyContactsPageState();
}

class _EmergencyContactsPageState extends State<EmergencyContactsPage> {
  List<EmergencyContact> contacts = [];
  bool isLoading = true;
  Map<String, dynamic> stats = {};

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _loadStats();
  }

  Future<void> _loadContacts() async {
    try {
      setState(() => isLoading = true);
      print('🔄 Cargando contactos de emergencia...');
      final loadedContacts = await EmergencyService.getEmergencyContacts();
      setState(() {
        contacts = loadedContacts;
        isLoading = false;
      });
      print('✅ Contactos cargados: ${contacts.length}');
    } catch (e) {
      setState(() => isLoading = false);
      print('❌ Error al cargar contactos: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar contactos: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _loadStats() async {
    try {
      final loadedStats = await EmergencyService.getEmergencyStats();
      setState(() => stats = loadedStats);
    } catch (e) {
      print('Error al cargar estadísticas: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contactos de Emergencia'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadContacts();
              _loadStats();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildStatsCard(),
                Expanded(
                  child: contacts.isEmpty
                      ? _buildEmptyState()
                      : _buildContactsList(),
                ),
              ],
            ),
      floatingActionButton: _buildAddContactButton(),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contactos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${contacts.length}/5 contactos',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: contacts.length >= 5 ? Colors.red : Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              contacts.length >= 5 ? 'Lleno' : 'Disponible',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
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
            Icons.contact_emergency_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No tienes contactos de emergencia',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega contactos para recibir ayuda en emergencias',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddContactDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Agregar Contacto'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        return _buildContactCard(contact);
      },
    );
  }

  Widget _buildContactCard(EmergencyContact contact) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(contact.priorityColor),
          child: Text(
            contact.relationshipIcon,
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          contact.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(contact.phone),
            if (contact.email != null) Text(contact.email!),
            Row(
              children: [
                if (contact.relationship != null)
                  Chip(
                    label: Text(
                      contact.relationship!,
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.grey[200],
                    padding: EdgeInsets.zero,
                  ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Color(contact.priorityColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Prioridad ${contact.priority}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleContactAction(value, contact),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddContactButton() {
    if (contacts.length >= 5) {
      return FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ya tienes el máximo de 5 contactos'),
              backgroundColor: Colors.orange,
            ),
          );
        },
        backgroundColor: Colors.grey,
        child: const Icon(Icons.add, color: Colors.white),
      );
    }

    return FloatingActionButton(
      onPressed: () => _showAddContactDialog(),
      backgroundColor: AppColors.primary,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  void _handleContactAction(String action, EmergencyContact contact) {
    switch (action) {
      case 'edit':
        _showEditContactDialog(contact);
        break;
      case 'delete':
        _showDeleteConfirmation(contact);
        break;
    }
  }

  void _showAddContactDialog() {
    _showContactDialog();
  }

  void _showEditContactDialog(EmergencyContact contact) {
    _showContactDialog(contact: contact);
  }

  void _showContactDialog({EmergencyContact? contact}) {
    final isEditing = contact != null;
    final nameController = TextEditingController(text: contact?.name ?? '');
    final phoneController = TextEditingController(text: contact?.phone ?? '');
    final emailController = TextEditingController(text: contact?.email ?? '');
    final relationshipController = TextEditingController(text: contact?.relationship ?? '');
    int priority = contact?.priority ?? 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'Editar Contacto' : 'Agregar Contacto'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: relationshipController,
                  decoration: const InputDecoration(
                    labelText: 'Relación',
                    border: OutlineInputBorder(),
                    hintText: 'Familia, amigo, trabajo...',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Prioridad: '),
                    Expanded(
                      child: Slider(
                        value: priority.toDouble(),
                        min: 1,
                        max: 5,
                        divisions: 4,
                        label: priority.toString(),
                        onChanged: (value) {
                          setState(() => priority = value.round());
                        },
                      ),
                    ),
                    Text('$priority'),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || phoneController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nombre y teléfono son obligatorios'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  if (isEditing) {
                    await EmergencyService.updateEmergencyContact(
                      id: contact!.id,
                      name: nameController.text,
                      phone: phoneController.text,
                      email: emailController.text.isEmpty ? null : emailController.text,
                      relationship: relationshipController.text.isEmpty ? null : relationshipController.text,
                      priority: priority,
                    );
                  } else {
                    await EmergencyService.createEmergencyContact(
                      name: nameController.text,
                      phone: phoneController.text,
                      email: emailController.text.isEmpty ? null : emailController.text,
                      relationship: relationshipController.text.isEmpty ? null : relationshipController.text,
                      priority: priority,
                    );
                  }

                  Navigator.of(context).pop();
                  _loadContacts();
                  _loadStats();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEditing ? 'Contacto actualizado' : 'Contacto agregado'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text(isEditing ? 'Actualizar' : 'Agregar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(EmergencyContact contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Contacto'),
        content: Text('¿Estás seguro de que quieres eliminar a ${contact.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await EmergencyService.deleteEmergencyContact(contact.id);
                Navigator.of(context).pop();
                _loadContacts();
                _loadStats();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Contacto eliminado'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
} 
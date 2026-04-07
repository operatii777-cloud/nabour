// lib/screens/manage_addresses_screen.dart

import 'package:flutter/material.dart';
import 'package:nabour_app/models/saved_address_model.dart';
import 'package:nabour_app/screens/add_address_screen.dart';
import 'package:nabour_app/services/firestore_service.dart';

class ManageAddressesScreen extends StatefulWidget {
  const ManageAddressesScreen({super.key});

  @override
  State<ManageAddressesScreen> createState() => _ManageAddressesScreenState();
}

class _ManageAddressesScreenState extends State<ManageAddressesScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  void _navigateToAddAddress({SavedAddress? addressToEdit}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddAddressScreen(addressToEdit: addressToEdit),
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(SavedAddress address) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmare Ștergere'),
          content: Text('Sunteți sigur că doriți să ștergeți adresa "${address.label}"?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Anulează'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Șterge', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true && mounted) {
      try {
        await _firestoreService.deleteSavedAddress(address.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Adresa a fost ștearsă.'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Eroare la ștergere: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adresele Mele'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddAddress(),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Adaugă'),
      ),
      body: StreamBuilder<List<SavedAddress>>(
        stream: _firestoreService.getSavedAddresses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('A apărut o eroare: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Nu ai nicio adresă salvată. Apasă pe butonul "Adaugă" pentru a crea una.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          }

          final addresses = snapshot.data!;
          // Separăm adresele pentru a le afișa în ordine
          final homeAddress = addresses.where((a) => a.label.toLowerCase() == 'acasă').toList();
          final workAddress = addresses.where((a) => a.label.toLowerCase() == 'serviciu').toList();
          final favoriteAddresses = addresses.where((a) => a.label.toLowerCase() != 'acasă' && a.label.toLowerCase() != 'serviciu').toList();
          
          return ListView(
            padding: const EdgeInsets.only(bottom: 80), // Spațiu pentru FloatingActionButton
            children: [
              ...homeAddress.map((addr) => _buildAddressTile(addr, Icons.home_rounded)),
              ...workAddress.map((addr) => _buildAddressTile(addr, Icons.work_rounded)),
              if (favoriteAddresses.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Divider(),
                ),
              ...favoriteAddresses.map((addr) => _buildAddressTile(addr, Icons.star_rounded)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAddressTile(SavedAddress address, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(address.label, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(address.address, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey),
            onPressed: () => _navigateToAddAddress(addressToEdit: address),
            tooltip: 'Editează',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _showDeleteConfirmationDialog(address),
            tooltip: 'Șterge',
          ),
        ],
      ),
    );
  }
}

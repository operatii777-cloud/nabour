import 'package:flutter/material.dart';
import 'package:nabour_app/models/saved_address_model.dart';
import 'package:nabour_app/screens/add_address_screen.dart';
import 'package:nabour_app/screens/edit_address_screen.dart';
import 'package:nabour_app/services/firestore_service.dart';

class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  
  @override
  void initState() {
    super.initState();
    // Inițializăm adresele implicite
    _firestoreService.initializeDefaultAddresses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adresele Mele'),
      ),
      body: StreamBuilder<List<SavedAddress>>(
        stream: _firestoreService.getSavedAddresses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('Eroare: ${snapshot.error}'));
          }
          
          final addresses = snapshot.data ?? [];
          
          // Separăm adresele în categorii
          SavedAddress? homeAddress;
          SavedAddress? workAddress;
          final favoriteAddresses = <SavedAddress>[];
          
          for (final address in addresses) {
            if (address.isHomeCategory) {
              homeAddress = address;
            } else if (address.isWorkCategory) {
              workAddress = address;
            } else {
              favoriteAddresses.add(address);
            }
          }
          
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Secțiunea Acasă
              _buildSystemAddressSection(
                title: 'Acasă',
                icon: Icons.home,
                address: homeAddress,
                color: Colors.blue,
              ),
              
              const SizedBox(height: 16),
              
              // Secțiunea Serviciu
              _buildSystemAddressSection(
                title: 'Serviciu',
                icon: Icons.work,
                address: workAddress,
                color: Colors.green,
              ),
              
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              
              // Secțiunea Favorite
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Adrese Favorite',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddAddressScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_circle, color: Colors.amber),
                    tooltip: 'Adaugă adresă favorită',
                  ),
                ],
              ),
              
              if (favoriteAddresses.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.star_border, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Nu aveți adrese favorite salvate',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddAddressScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Adaugă prima adresă favorită'),
                      ),
                    ],
                  ),
                )
              else
                ...favoriteAddresses.map((address) => _buildFavoriteAddressTile(address)),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildSystemAddressSection({
    required String title,
    required IconData icon,
    required SavedAddress? address,
    required Color color,
  }) {
    final bool isEmpty = address == null || address.address.isEmpty;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isEmpty ? Colors.orange.shade200 : Colors.transparent,
          width: isEmpty ? 2 : 0,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha:0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          isEmpty ? 'Adresă necompletată' : address.address,
          style: TextStyle(
            color: isEmpty ? Colors.orange.shade700 : null,
            fontStyle: isEmpty ? FontStyle.italic : null,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: Icon(
            isEmpty ? Icons.add_circle_outline : Icons.edit,
            color: isEmpty ? Colors.orange : Colors.grey,
          ),
          onPressed: () {
            if (address != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditAddressScreen(address: address),
                ),
              );
            }
          },
          tooltip: isEmpty ? 'Completează adresa' : 'Editează',
        ),
      ),
    );
  }
  
  Widget _buildFavoriteAddressTile(SavedAddress address) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha:0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.star, color: Colors.amber),
        ),
        title: Text(
          address.label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          address.address,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.grey),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditAddressScreen(address: address),
                  ),
                );
              },
              tooltip: 'Editează',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _confirmDelete(address),
              tooltip: 'Șterge',
            ),
          ],
        ),
      ),
    );
  }
  
  void _confirmDelete(SavedAddress address) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmare Ștergere'),
        content: Text(
          'Sigur doriți să ștergeți adresa "${address.label}"?',
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anulează'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _firestoreService.deleteSavedAddress(address.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Adresa a fost ștearsă'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Șterge'),
          ),
        ],
      ),
    );
  }
}
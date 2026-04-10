import 'package:flutter/material.dart';
import 'package:nabour_app/models/saved_address_model.dart';
import 'package:nabour_app/screens/add_address_screen.dart';
import 'package:nabour_app/services/firestore_service.dart';
import 'package:nabour_app/screens/point_navigation_screen.dart';
import 'package:nabour_app/utils/external_maps_launcher.dart';

/// Gestionare adrese favorite (exclusiv Acasă / Serviciu), cu același flux de adăugare ca la destinație.
class FavoriteAddressesScreen extends StatefulWidget {
  const FavoriteAddressesScreen({super.key});

  @override
  State<FavoriteAddressesScreen> createState() => _FavoriteAddressesScreenState();
}

class _FavoriteAddressesScreenState extends State<FavoriteAddressesScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _firestoreService.initializeDefaultAddresses();
  }

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
          title: const Text('Confirmare ștergere'),
          content: Text('Ștergi adresa „${address.label}”?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Anulează'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Șterge', style: TextStyle(color: Colors.red)),
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
            const SnackBar(
              content: Text('Adresa a fost ștearsă.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Eroare: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adrese favorite'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddAddress(),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Adaugă adresă'),
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
          final favoriteAddresses =
              addresses.where((a) => a.isGeneralFavorite).toList();

          if (favoriteAddresses.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Nu ai încă adrese favorite.\n'
                  'Apasă „Adaugă adresă” — poți scrie adresa, alege pe hartă sau folosi vocea, '
                  'ca la introducerea destinației pentru cursă.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: favoriteAddresses.length,
            itemBuilder: (context, index) {
              final addr = favoriteAddresses[index];
              return ListTile(
                leading: Icon(Icons.star_rounded,
                    color: Theme.of(context).colorScheme.primary),
                title: Text(addr.label,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (addr.category != SavedAddressCategory.other)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          addr.category.labelRo,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    Text(
                      addr.address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.navigation_outlined,
                          color: Colors.green),
                      tooltip: 'Navigare',
                      onPressed: () {
                        final lat = addr.coordinates.latitude;
                        final lng = addr.coordinates.longitude;
                        ExternalMapsLauncher.showNavigationChooser(
                          context,
                          lat,
                          lng,
                          onOpenNabour: () async {
                            if (!context.mounted) return;
                            await Navigator.of(context).push<void>(
                              MaterialPageRoute<void>(
                                builder: (ctx) => PointNavigationScreen(
                                  destinationLat: lat,
                                  destinationLng: lng,
                                  destinationLabel: addr.label,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey),
                      tooltip: 'Editează',
                      onPressed: () =>
                          _navigateToAddAddress(addressToEdit: addr),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Șterge',
                      onPressed: () => _showDeleteConfirmationDialog(addr),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

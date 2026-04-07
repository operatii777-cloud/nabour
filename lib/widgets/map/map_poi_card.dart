import 'package:flutter/material.dart';
import 'package:nabour_app/models/poi_model.dart';

class MapPoiCard extends StatelessWidget {
  final PointOfInterest poi;
  final VoidCallback onClose;
  final VoidCallback onSetAsPickup;
  final VoidCallback onSetAsDestination;
  final VoidCallback onAddAsStop;
  final VoidCallback onAddAsFavorite;
  final VoidCallback onNavigateHere;

  const MapPoiCard({
    super.key,
    required this.poi,
    required this.onClose,
    required this.onSetAsPickup,
    required this.onSetAsDestination,
    required this.onAddAsStop,
    required this.onAddAsFavorite,
    required this.onNavigateHere,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header cu imagine și buton închidere
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: Image.network(
                    poi.imageUrl,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 150,
                        color: Colors.grey.shade300,
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 48,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onClose,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color.fromARGB(153, 0, 0, 0),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Conținut
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titlu
                  Text(
                    poi.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Descriere
                  Text(
                    poi.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Butoane de acțiune
                  _buildActions(),
                ],
              ),
            ),
          ],
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        // Prima linie - Plecare și Destinație
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onSetAsPickup,
                icon: const Icon(Icons.my_location, size: 18),
                label: const Text('Plecare'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onSetAsDestination,
                icon: const Icon(Icons.flag, size: 18),
                label: const Text('Destinație'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // A doua linie - Oprire intermediară
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onAddAsStop,
            icon: const Icon(Icons.add_location, size: 18),
            label: const Text('Adaugă ca oprire'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onAddAsFavorite,
                icon: const Icon(Icons.star_outline, size: 18),
                label: const Text('Favorite'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onNavigateHere,
                icon: const Icon(Icons.navigation_outlined, size: 18),
                label: const Text('Navigare'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

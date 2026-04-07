import 'package:flutter/material.dart';
import 'package:nabour_app/models/poi_model.dart';

class MapPoiCategoryChips extends StatelessWidget {
  final void Function(PoiCategory category) onCategoryTapped;

  const MapPoiCategoryChips({super.key, required this.onCategoryTapped});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<PoiCategory> categories = [
      PoiCategory.gasStation,
      PoiCategory.restaurant,
      PoiCategory.parking,
      PoiCategory.hotel,
      PoiCategory.hospital,
      PoiCategory.pharmacy,
      PoiCategory.supermarket,
      PoiCategory.bank,
      PoiCategory.atm,
      PoiCategory.school,
      PoiCategory.university,
      PoiCategory.library,
      PoiCategory.police,
      PoiCategory.postOffice,
      PoiCategory.mall,
      PoiCategory.bakery,
      PoiCategory.barPub,
      PoiCategory.park,
      PoiCategory.museum,
      PoiCategory.cinema,
      PoiCategory.theatre,
      PoiCategory.playground,
      PoiCategory.chargingStation,
      PoiCategory.carWash,
      PoiCategory.carRepair,
      PoiCategory.publicTransport,
      PoiCategory.airport,
      PoiCategory.other,
      PoiCategory.tourism,
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final category in categories) ...[
              ActionChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(category.emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(category.displayName),
                  ],
                ),
                onPressed: () => onCategoryTapped(category),
                backgroundColor: isDark ? Colors.grey.shade800 : Colors.white,
                elevation: 2,
                shadowColor: Colors.black12,
                side: BorderSide(color: isDark ? Colors.grey.shade600 : Colors.grey.shade300),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

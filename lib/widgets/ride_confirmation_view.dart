// lib/widgets/ride_confirmation_view.dart

import 'package:flutter/material.dart';
import 'package:nabour_app/models/ride_model.dart';
import 'package:nabour_app/models/stop_location.dart';
import 'package:nabour_app/services/firestore_service.dart';
import 'package:nabour_app/widgets/enh_price_estimate_widget.dart';

class RideConfirmationView extends StatelessWidget {
  final ScrollController scrollController;
  final Map<RideCategory, Map<String, double>> fares;
  final Map<RideCategory, DriverEtaResult?> etas;
  final double distance;
  final double duration;
  final RideCategory selectedCategory;
  final Function(RideCategory) onCategorySelected;
  final VoidCallback onConfirm;
  final VoidCallback onBack;
  
  // ADĂUGAT: Lista de opriri
  final List<StopLocation> stops;

  const RideConfirmationView({
    super.key,
    required this.scrollController,
    required this.fares,
    required this.etas,
    required this.distance,
    required this.duration,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.onConfirm,
    required this.onBack,
    required this.stops,
  });

  String _getCategoryName(RideCategory category) {
    switch (category) {
      case RideCategory.any: return 'Orice categorie';
      case RideCategory.standard: return 'Standard';
      case RideCategory.family: return 'Familie';
      case RideCategory.energy: return 'Ecologic';
      case RideCategory.best: return 'Premium';
      case RideCategory.utility: return 'Utilitar';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: onBack),
            Expanded(
              child: Text('Alege o cursă', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            ),
            const SizedBox(width: 48),
          ],
        ),
        const Divider(height: 24),
        
        // ✅ ÎMBUNĂTĂȚIT: Widget îmbunătățit pentru estimare preț
        EnhancedPriceEstimateWidget(
          faresByCategory: fares,
          selectedCategory: selectedCategory,
          distanceInKm: distance,
          durationInMinutes: duration,
          onCategorySelected: onCategorySelected,
        ),
        
        const SizedBox(height: 16),
        
        // ADĂUGAT: Afișarea rezumatului rutei cu opriri
        if (stops.isNotEmpty) ...[
          _buildRoutePreview(context),
          const SizedBox(height: 16),
        ],
        
        // ✅ REMOVED: Cardurile vechi au fost eliminate - EnhancedPriceEstimateWidget le înlocuiește

        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: Text(
            stops.isEmpty
              ? 'Confirmă ${_getCategoryName(selectedCategory)}'
              : 'Confirmă cu ${stops.length} opriri',
          ),
        ),
      ],
    );
  }

  // ADĂUGAT: Widget pentru previzualizarea rutei cu opriri
  Widget _buildRoutePreview(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.route_rounded, color: Colors.orange.shade600),
              const SizedBox(width: 8),
              Text(
                'Ruta cu ${stops.length} opriri',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Punctul de start
          _buildRoutePoint(
            context: context,
            icon: Icons.my_location,
            color: Colors.green,
            title: 'Pornire',
            subtitle: 'Locația actuală',
            isFirst: true,
          ),
          
          // Opririle
          ...() {
            final List<Widget> stopWidgets = <Widget>[];
            for (int index = 0; index < stops.length; index++) {
              stopWidgets.add(
                _buildRoutePoint(
                  context: context,
                  icon: Icons.location_on,
                  color: Colors.orange,
                  title: 'Oprirea ${index + 1}',
                  subtitle: stops[index].address,
                  isFirst: false,
                ),
              );
            }
            return stopWidgets;
          }(),
          
          // Destinația finală
          _buildRoutePoint(
            context: context,
            icon: Icons.location_on,
            color: Colors.red,
            title: 'Destinație finală',
            subtitle: 'Conform selecției',
            isFirst: false,
            isLast: true,
          ),
          
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Ajutor între vecini',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.blue.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ADĂUGAT: Widget pentru un punct din rută
  Widget _buildRoutePoint({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool isFirst,
    bool isLast = false,
  }) {
    return Row(
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 14),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 24,
                color: Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ✅ REMOVED: _buildCategoryCard - replaced by EnhancedPriceEstimateWidget
  //   // ✅ REMOVED: _buildCategoryCard - replaced by EnhancedPriceEstimateWidget
  // This method is no longer needed as EnhancedPriceEstimateWidget handles category display
}
import 'dart:async';

import 'package:flutter/material.dart';

import 'package:nabour_app/l10n/app_localizations.dart';
import 'package:nabour_app/services/geocoding_service.dart';
import 'package:nabour_app/utils/external_maps_launcher.dart';

/// Geocoding o singură dată per deschidere sheet — nu re-intră în serviciu la rebuild-uri locale.
class MapTapGeocodeSheetBody extends StatefulWidget {
  const MapTapGeocodeSheetBody({
    super.key,
    required this.lat,
    required this.lng,
    required this.sheetContext,
    required this.mapScreenContext,
    required this.onOpenFavorite,
  });

  final double lat;
  final double lng;
  final BuildContext sheetContext;
  final BuildContext mapScreenContext;
  final Future<void> Function(double lat, double lng, String address)
      onOpenFavorite;

  @override
  State<MapTapGeocodeSheetBody> createState() =>
      _MapTapGeocodeSheetBodyState();
}

class _MapTapGeocodeSheetBodyState extends State<MapTapGeocodeSheetBody> {
  late final Future<String?> _addressFuture =
      GeocodingService().getAddressFromCoordinates(widget.lat, widget.lng);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _addressFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final address =
            snap.data != null && snap.data!.trim().isNotEmpty
                ? snap.data!.trim()
                : 'Locație pe hartă';
        final lat = widget.lat;
        final lng = widget.lng;
        final sheetCtx = widget.sheetContext;
        final mapCtx = widget.mapScreenContext;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              address,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.star_rounded, color: Colors.amber),
              title: Text(
                AppLocalizations.of(context)!.mapAddToFavoriteAddresses,
              ),
              onTap: () {
                Navigator.pop(sheetCtx);
                unawaited(widget.onOpenFavorite(lat, lng, address));
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.navigation_outlined, color: Colors.green),
              title: Text(
                AppLocalizations.of(context)!.mapNavigateWithExternalApps,
              ),
              onTap: () {
                Navigator.pop(sheetCtx);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mapCtx.mounted) return;
                  ExternalMapsLauncher.showNavigationChooser(mapCtx, lat, lng);
                });
              },
            ),
          ],
        );
      },
    );
  }
}

/// Model intern pentru un rând de loc în overlay-ul de căutare universală.
class MapUniversalSearchPlaceRow {
  const MapUniversalSearchPlaceRow(this.suggestion, this.fromLocalBundle);

  final AddressSuggestion suggestion;
  final bool fromLocalBundle;
}

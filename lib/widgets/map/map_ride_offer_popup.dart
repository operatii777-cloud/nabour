import 'package:flutter/material.dart';
import 'package:nabour_app/models/ride_model.dart';

class MapRideOfferPopup extends StatelessWidget {
  final Ride ride;
  final int remainingSeconds;
  final bool isProcessingAccept;
  final bool isProcessingDecline;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const MapRideOfferPopup({
    super.key,
    required this.ride,
    required this.remainingSeconds,
    required this.isProcessingAccept,
    required this.isProcessingDecline,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 100,
      left: 16,
      right: 16,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Cursă nouă',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.black12),
                      child: Text('${remainingSeconds}s', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.place, color: Colors.red, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          ride.destinationAddress,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.trip_origin, color: Colors.green, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          ride.startAddress,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ]),
                  ],
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, c) {
                    final narrow = c.maxWidth < 300;
                    final decline = ElevatedButton.icon(
                      onPressed: isProcessingDecline ? null : onDecline,
                      icon: isProcessingDecline
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.close, size: 18),
                      label: Text(isProcessingDecline ? 'Refuz...' : 'Refuză'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            Colors.red.withValues(alpha: 0.6),
                      ),
                    );
                    final accept = ElevatedButton.icon(
                      onPressed: isProcessingAccept ? null : onAccept,
                      icon: isProcessingAccept
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check, size: 18),
                      label: Text(isProcessingAccept ? 'Accept...' : 'Acceptă'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            Colors.green.withValues(alpha: 0.6),
                      ),
                    );
                    if (narrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          decline,
                          const SizedBox(height: 8),
                          accept,
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: decline),
                        const SizedBox(width: 8),
                        Expanded(child: accept),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

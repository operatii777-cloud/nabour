import 'dart:ui';
import 'package:flutter/material.dart';

class MapVoiceOverlay extends StatelessWidget {
    final VoidCallback onRidePressed;
    final VoidCallback onCallPressed;
    final VoidCallback onMessagePressed;

    const MapVoiceOverlay({
          Key? key,
          required this.onRidePressed,
          required this.onCallPressed,
          required this.onMessagePressed,
    }) : super(key: key);

    @override
    Widget build(BuildContext context) {
          return Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(30),
                                        topRight: Radius.circular(30),
                                      ),
                            child: BackdropFilter(
                                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                                        child: Container(
                                                      padding: const EdgeInsets.all(24),
                                                      decoration: BoxDecoration(
                                                                      color: Colors.black.withOpacity(0.4),
                                                                      borderRadius: const BorderRadius.only(
                                                                                        topLeft: Radius.circular(30),
                                                                                        topRight: Radius.circular(30),
                                                                                      ),
                                                                      border: Border.all(
                                                                                        color: Colors.white.withOpacity(0.1),
                                                                                      ),
                                                                    ),
                                                      child: Column(
                                                                      mainAxisSize: MainAxisSize.min,
                                                                      children: [
                                                                                        // Waveform Animation Placeholder
                                                                                        Container(
                                                                                                            height: 60,
                                                                                                            width: double.infinity,
                                                                                                            decoration: BoxDecoration(
                                                                                                                                  color: Colors.white.withOpacity(0.05),
                                                                                                                                  borderRadius: BorderRadius.circular(15),
                                                                                                                                ),
                                                                                                            child: Center(
                                                                                                                                  child: Text(
                                                                                                                                                          "AI is listening...",
                                                                                                                                                          style: TextStyle(
                                                                                                                                                                                    color: Colors.cyanAccent.withOpacity(0.7),
                                                                                                                                                                                    fontSize: 14,
                                                                                                                                                                                    letterSpacing: 1.2,
                                                                                                                                                                                  ),
                                                                                                                                                        ),
                                                                                                                                ),
                                                                                                          ),
                                                                                        const SizedBox(height: 24),
                                                                                        // Action Buttons
                                                                                        Row(
                                                                                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                                                                            children: [
                                                                                                                                  _buildActionButton(
                                                                                                                                                          icon: Icons.directions_car_rounded,
                                                                                                                                                          label: "Ride",
                                                                                                                                                          color: Colors.blueAccent,
                                                                                                                                                          onPressed: onRidePressed,
                                                                                                                                                        ),
                                                                                                                                  _buildActionButton(
                                                                                                                                                          icon: Icons.phone_rounded,
                                                                                                                                                          label: "Call",
                                                                                                                                                          color: Colors.greenAccent,
                                                                                                                                                          onPressed: onCallPressed,
                                                                                                                                                        ),
                                                                                                                                  _buildActionButton(
                                                                                                                                                          icon: Icons.message_rounded,
                                                                                                                                                          label: "Message",
                                                                                                                                                          color: Colors.orangeAccent,
                                                                                                                                                          onPressed: onMessagePressed,
                                                                                                                                                        ),
                                                                                                                                ],
                                                                                                          ),
                                                                                      ],
                                                                    ),
                                                    ),
                                      ),
                          ),
                );
    }

    Widget _buildActionButton({
          required IconData icon,
          required String label,
          required Color color,
          required VoidCallback onPressed,
    }) {
          return Column(
                  children: [
                            Container(
                                        width: 70,
                                        height: 70,
                                        decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      gradient: LinearGradient(
                                                                      colors: [color.withOpacity(0.6), color.withOpacity(0.2)],
                                                                      begin: Alignment.topLeft,
                                                                      end: Alignment.bottomRight,
                                                                    ),
                                                      boxShadow: [
                                                                      BoxShadow(
                                                                                        color: color.withOpacity(0.3),
                                                                                        blurRadius: 15,
                                                                                        spreadRadius: 2,
                                                                                      ),
                                                                    ],
                                                      border: Border.all(color: color.withOpacity(0.5), width: 1.5),
                                                    ),
                                        child: IconButton(
                                                      icon: Icon(icon, color: Colors.white, size: 32),
                                                      onPressed: onPressed,
                                                    ),
                                      ),
                            const SizedBox(height: 8),
                            Text(
                                        label,
                                        style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                      ),
                          ],
                );
    }
}

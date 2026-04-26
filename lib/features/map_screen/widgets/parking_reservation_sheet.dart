import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:nabour_app/l10n/app_localizations.dart';
import 'package:nabour_app/features/parking_swap/parking_swap_service.dart';

class ParkingReservationSheet extends StatefulWidget {
  final String spotId;
  final VoidCallback onReserved;

  const ParkingReservationSheet({
    super.key,
    required this.spotId,
    required this.onReserved,
  });

  @override
  State<ParkingReservationSheet> createState() => _ParkingReservationSheetState();
}

class _ParkingReservationSheetState extends State<ParkingReservationSheet> {
  bool _isReserving = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Icon(Icons.local_parking_rounded, color: Colors.amber, size: 48),
          const SizedBox(height: 16),
          const Text(
            'LOC DE AUR DETECTAT',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Un vecin eliberează acest loc acum.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isReserving ? null : _reserve,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isReserving
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text(
                      'REZERVĂ LOCUL',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Future<void> _reserve() async {
    setState(() => _isReserving = true);
    final success = await ParkingSwapService().reserveSpot(widget.spotId);
    if (mounted) {
      setState(() => _isReserving = false);
      if (success) {
        widget.onReserved();
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.mapSpotAlreadyReserved),
          ),
        );
      }
    }
  }
}

class RightGlassFloatingPanel extends StatefulWidget {
  final Widget child;
  const RightGlassFloatingPanel({super.key, required this.child});
  @override
  State<RightGlassFloatingPanel> createState() => _RightGlassFloatingPanelState();
}

class _RightGlassFloatingPanelState extends State<RightGlassFloatingPanel> {
  final ScrollController _scrollController = ScrollController();
  bool _showUp = false;
  bool _showDown = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateArrows);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateArrows());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateArrows);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateArrows() {
    if (!mounted || !_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) {
      if (_showUp != false || _showDown != false) {
        setState(() {
          _showUp = false;
          _showDown = false;
        });
      }
      return;
    }

    final up = _scrollController.position.pixels > 3;
    final down = _scrollController.position.pixels < maxScroll - 3;
    if (_showUp != up || _showDown != down) {
      setState(() {
        _showUp = up;
        _showDown = down;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: 64,
          constraints: const BoxConstraints(maxHeight: 244),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: Stack(
            children: [
              SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                child: widget.child,
              ),
              if (_showUp)
                Positioned(
                  top: 4,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Icon(
                      Icons.keyboard_arrow_up_rounded,
                      color: Colors.white.withValues(alpha: 0.95),
                      size: 18,
                    ),
                  ),
                ),
              if (_showDown)
                Positioned(
                  bottom: 4,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white.withValues(alpha: 0.95),
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

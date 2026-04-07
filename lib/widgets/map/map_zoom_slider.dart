import 'package:flutter/material.dart';

/// Slider vertical de zoom pe stânga hărții — stil Bump.
class MapZoomSlider extends StatefulWidget {
  final double minZoom;
  final double maxZoom;
  final double currentZoom;
  final ValueChanged<double> onZoomChanged;

  const MapZoomSlider({
    super.key,
    this.minZoom = 3.0,
    this.maxZoom = 20.0,
    required this.currentZoom,
    required this.onZoomChanged,
  });

  @override
  State<MapZoomSlider> createState() => _MapZoomSliderState();
}

class _MapZoomSliderState extends State<MapZoomSlider> {
  late double _zoom;

  @override
  void initState() {
    super.initState();
    _zoom = widget.currentZoom;
  }

  @override
  void didUpdateWidget(MapZoomSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.currentZoom - widget.currentZoom).abs() > 0.5) {
      _zoom = widget.currentZoom;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () {
              final z = (_zoom + 1).clamp(widget.minZoom, widget.maxZoom);
              setState(() => _zoom = z);
              widget.onZoomChanged(z);
            },
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, size: 18, color: Colors.black87),
            ),
          ),
          Expanded(
            child: RotatedBox(
              quarterTurns: 3,
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 7),
                  activeTrackColor: const Color(0xFF7C3AED),
                  inactiveTrackColor: Colors.grey.shade300,
                  thumbColor: const Color(0xFF7C3AED),
                  overlayShape: SliderComponentShape.noOverlay,
                ),
                child: Slider(
                  value: _zoom.clamp(widget.minZoom, widget.maxZoom),
                  min: widget.minZoom,
                  max: widget.maxZoom,
                  onChanged: (v) {
                    setState(() => _zoom = v);
                    widget.onZoomChanged(v);
                  },
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              final z = (_zoom - 1).clamp(widget.minZoom, widget.maxZoom);
              setState(() => _zoom = z);
              widget.onZoomChanged(z);
            },
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.remove, size: 18, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

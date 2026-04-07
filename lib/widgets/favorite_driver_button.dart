import 'package:flutter/material.dart';
import 'package:nabour_app/services/firestore_service.dart';
import 'package:nabour_app/utils/logger.dart';

/// A heart-shaped toggle button for marking a driver as a favourite.
///
/// Shows a filled red heart when the driver is already a favourite, and an
/// outline heart when not.  Calls [FirestoreService.addFavoriteDriver] or
/// [FirestoreService.removeFavoriteDriver] on tap.
class FavoriteDriverButton extends StatefulWidget {
  final String driverId;

  const FavoriteDriverButton({super.key, required this.driverId});

  @override
  State<FavoriteDriverButton> createState() => _FavoriteDriverButtonState();
}

class _FavoriteDriverButtonState extends State<FavoriteDriverButton> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isFavorite = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavoriteState();
  }

  Future<void> _loadFavoriteState() async {
    try {
      final result = await _firestoreService.isFavoriteDriver(widget.driverId);
      if (mounted) {
        setState(() {
          _isFavorite = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      Logger.error('FavoriteDriverButton load error: $e', error: e);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggle() async {
    final newValue = !_isFavorite;
    setState(() => _isFavorite = newValue);
    try {
      if (newValue) {
        await _firestoreService.addFavoriteDriver(widget.driverId);
      } else {
        await _firestoreService.removeFavoriteDriver(widget.driverId);
      }
    } catch (e) {
      Logger.error('FavoriteDriverButton toggle error: $e', error: e);
      if (mounted) setState(() => _isFavorite = !newValue);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return IconButton(
      icon: Icon(
        _isFavorite ? Icons.favorite : Icons.favorite_border,
        color: _isFavorite ? Colors.red : Colors.grey,
      ),
      tooltip: _isFavorite ? 'Elimină din șoferi preferați' : 'Adaugă la șoferi preferați',
      onPressed: _toggle,
    );
  }
}

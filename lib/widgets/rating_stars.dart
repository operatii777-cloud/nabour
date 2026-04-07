import 'package:flutter/material.dart';
import 'package:nabour_app/services/firestore_service.dart';

// Widget reutilizabil pentru afișarea și selectarea stelelor
class RatingStars extends StatelessWidget {
  final double initialRating;
  final Function(double) onRatingChanged;
  final double size;
  final Color activeColor;
  final Color inactiveColor;

  const RatingStars({
    super.key,
    this.initialRating = 0.0,
    required this.onRatingChanged,
    this.size = 40.0,
    this.activeColor = Colors.amber,
    this.inactiveColor = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: () => onRatingChanged((index + 1).toDouble()),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Icon(
              index < initialRating ? Icons.star : Icons.star_border,
              size: size,
              color: index < initialRating ? activeColor : inactiveColor,
            ),
          ),
        );
      }),
    );
  }
}

class RatingScreen extends StatefulWidget {
  final String rideId;
  final UserRole userRole; // Poate fi UserRole.driver sau UserRole.passenger

  const RatingScreen({
    super.key,
    required this.rideId,
    required this.userRole,
  });

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  double _rating = 0;
  final _commentController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitRating() async {
    if (_rating == 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Te rugăm să selectezi cel puțin o stea.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.userRole == UserRole.passenger) {
        // Pasagerul evaluează șoferul
        await _firestoreService.submitRating(
          rideId: widget.rideId,
          rating: _rating,
          comment: _commentController.text,
        );
      } else {
        // Șoferul evaluează pasagerul
        await _firestoreService.ratePassenger(
          rideId: widget.rideId,
          rating: _rating,
          characterization: _commentController.text,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mulțumim pentru feedback!'),
          backgroundColor: Colors.green,
        ),
      );

      // CERINȚA 1: Navighează direct la ecranul principal (harta)
      Navigator.of(context).popUntil((route) => route.isFirst);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('A apărut o eroare: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _skipRating() {
    // CERINȚA 2: Navighează direct la ecranul principal (harta) fără a trimite evaluare
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.userRole == UserRole.passenger
        ? 'Cum a fost cursa?'
        : 'Evaluează pasagerul';
    final hintText = widget.userRole == UserRole.passenger
        ? 'Lasă un comentariu pentru șofer...'
        : 'Lasă o caracterizare pentru pasager...';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        automaticallyImplyLeading: false, // Eliminăm butonul de back implicit
        actions: [
          // CERINȚA 2: Adaugă butonul de închidere doar pentru pasager
          if (widget.userRole == UserRole.passenger)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _skipRating,
              tooltip: 'Închide',
            ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Aprecierea ta ne ajută să îmbunătățim serviciile.',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              RatingStars(
                initialRating: _rating,
                onRatingChanged: (newRating) {
                  setState(() {
                    _rating = newRating;
                  });
                },
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: hintText,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitRating,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : const Text('Trimite Evaluarea'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
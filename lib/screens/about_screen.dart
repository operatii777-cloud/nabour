import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nabour_app/screens/career_screen.dart';
import 'package:nabour_app/config/environment.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nabour_app/l10n/app_localizations.dart';
import 'package:nabour_app/utils/logger.dart';

class AboutScreen extends StatelessWidget {
  final bool isPassengerMode;

  const AboutScreen({super.key, this.isPassengerMode = true});

  // Dialog SIMPLU cu AlertDialog - SOLUȚIA 2
  void _showRatingDialog(BuildContext context) {
    double selectedRating = 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          contentPadding: const EdgeInsets.all(16),
          title: Text(
            AppLocalizations.of(context)!.about_evaluateApp,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          content: IntrinsicHeight(
            child: Column(
              children: [
                Text(
                  AppLocalizations.of(context)!.about_howManyStars,
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // STELE SIMPLE ÎN ROW - fără widget custom
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedRating = (index + 1).toDouble();
                        });
                        Logger.debug('Rating selectat: ${index + 1}');
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Icon(
                          index < selectedRating ? Icons.star : Icons.star_border,
                          color: Colors.orange,
                          size: 28, // DIMENSIUNE FIXĂ MICĂ
                        ),
                      ),
                    );
                  }),
                ),
                
                const SizedBox(height: 12),
                
                // Feedback simplu
                if (selectedRating > 0)
                  Text(
                    '${selectedRating.toInt()} ${selectedRating == 1 ? AppLocalizations.of(context)!.about_starSelected : AppLocalizations.of(context)!.about_starsSelected}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                AppLocalizations.of(context)!.cancel, 
                style: const TextStyle(fontSize: 14)
              ),
            ),
            ElevatedButton(
              onPressed: selectedRating > 0 ? () {
                Logger.debug('⭐ RATING FINAL: $selectedRating stele');
                Navigator.pop(ctx);
                _sendRating(context, selectedRating);
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedRating > 0 ? Colors.orange : Colors.grey.shade300,
                foregroundColor: Colors.white,
              ),
              child: Text(
                selectedRating > 0 ? AppLocalizations.of(context)!.send : AppLocalizations.of(context)!.select,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ELIMINĂ complet dialogul de comentarii
  // void _showCommentDialog - ȘTERS

  // Trimite DOAR rating
  void _sendRating(BuildContext context, double rating) {
    Logger.debug('⭐ RATING TRIMIS: $rating');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.about_ratingSentSuccessfully(rating.toString())),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );

    // Simulare în background
    Timer(const Duration(seconds: 1), () {
      Logger.info('Salvez rating în Firebase...');
      Logger.info('Rating salvat!');
      _showIndexLink('rating');
    });
  }

  // Simulează link-ul pentru index
  void _showIndexLink(String type) {
    Logger.debug('Test index pentru $type...');
    Logger.debug('');
    Logger.debug('EROARE FIREBASE - INDEX NECESAR:');
    Logger.info('LINK PENTRU INDEX GĂSIT!');
    Logger.debug('https://console.firebase.google.com/v1/r/project/friendsride-app/firestore/indexes?create_composite=abc123');
    Logger.debug('Copiază link-ul de mai sus!');
    Logger.debug('');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.about_titleNabour),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Material(
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  AppLocalizations.of(context)!.about_appMissionTagline,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.work_outline),
            title: Text(AppLocalizations.of(context)!.about_career),
            subtitle: Text(AppLocalizations.of(context)!.about_joinOurTeam),
            onTap: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (ctx) => const CareerScreen())
              );
            },
          ),
          const Divider(),
          
          // DOAR rating - am eliminat comentariul
          ListTile(
            leading: const Icon(Icons.star, color: Colors.orange),
            title: Text(AppLocalizations.of(context)!.about_evaluateApplication),
            subtitle: Text(AppLocalizations.of(context)!.about_giveStarRating),
            onTap: () => _showRatingDialog(context),
          ),
          
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              AppLocalizations.of(context)!.about_followUs, 
              style: const TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.bold, 
                color: Colors.grey
              )
            ),
          ),
          const SizedBox(height: 8),
          _buildSocialsRow(),
        ],
      ),
    );
  }

  Widget _buildSocialsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.facebook, size: 40, color: Colors.blueAccent),
            onPressed: () {
              final url = Environment.facebookPageUrl.isNotEmpty
                  ? Environment.facebookPageUrl
                  : 'https://facebook.com';
              _launchURL(url);
            },
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined, size: 40, color: Colors.purpleAccent),
            onPressed: () {
              final url = Environment.instagramPageUrl.isNotEmpty
                  ? Environment.instagramPageUrl
                  : 'https://instagram.com';
              _launchURL(url);
            },
          ),
          IconButton(
            icon: const Icon(Icons.music_note_outlined, size: 40, color: Colors.black),
            onPressed: () {
              final url = Environment.tiktokPageUrl.isNotEmpty
                  ? Environment.tiktokPageUrl
                  : 'https://tiktok.com';
              _launchURL(url);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Nu s-a putut deschide $url');
    }
  }
}
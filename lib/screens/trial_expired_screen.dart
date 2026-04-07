import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nabour_app/services/movement_history_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Afișat când perioada de trial de 7 zile a expirat.
/// Blochează accesul la aplicație până la activarea unui abonament.
class TrialExpiredScreen extends StatelessWidget {
  const TrialExpiredScreen({super.key});

  static const String _contactEmail = 'contact@nabour.ro';
  static const String _whatsappNumber = '+40700000000'; // înlocuiți cu numărul real

  Future<void> _openEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: _contactEmail,
      queryParameters: {
        'subject': 'Activare abonament Nabour',
        'body':
            'Bună ziua,\n\nDoresc să activez un abonament Nabour.\n\n'
            'UID: ${FirebaseAuth.instance.currentUser?.uid ?? "necunoscut"}',
      },
    );
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _openWhatsApp() async {
    final message = Uri.encodeComponent(
      'Bună ziua, doresc să activez un abonament Nabour. '
      'UID: ${FirebaseAuth.instance.currentUser?.uid ?? "necunoscut"}',
    );
    final uri = Uri.parse('https://wa.me/$_whatsappNumber?text=$message');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _signOut(BuildContext context) async {
    await MovementHistoryService.instance.stopRecorder();
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final creationTime = user?.metadata.creationTime;
    final expiredSince = creationTime != null
        ? DateTime.now().difference(creationTime.add(const Duration(days: 7))).inDays
        : 0;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            children: [
              const Spacer(),

              // Icon
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5A32FA), Color(0xFF9070FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5A32FA).withValues(alpha: 0.45),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 46,
                ),
              ),

              const SizedBox(height: 28),

              // Titlu
              const Text(
                'Perioada de trial a expirat',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Subtitlu
              Text(
                expiredSince > 0
                    ? 'Trial-ul tău de 7 zile s-a încheiat acum $expiredSince ${expiredSince == 1 ? "zi" : "zile"}.'
                    : 'Trial-ul tău de 7 zile s-a încheiat.',
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white60,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Card beneficii
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ce primești cu abonamentul',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildBenefit(Icons.map_rounded, 'Hartă live cu vecini și șoferi'),
                    _buildBenefit(Icons.directions_car_rounded, 'Cereri și oferte de curse'),
                    _buildBenefit(Icons.forum_rounded, 'Chat cartier și chat privat'),
                    _buildBenefit(Icons.campaign_rounded, 'Broadcast cereri de transport'),
                    _buildBenefit(Icons.local_offer_rounded, 'Oferte business locale'),
                    _buildBenefit(Icons.mic_rounded, 'Asistent vocal AI Nabour'),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Pret
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5A32FA), Color(0xFF9070FF)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Abonament',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '10 RON / lună',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Investim totul în funcționarea și inovația platformei.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white38,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 2),

              // Buton principal — contact email
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _openEmail,
                  icon: const Icon(Icons.email_rounded, size: 20),
                  label: const Text(
                    'Activează abonamentul',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A32FA),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Buton secundar — WhatsApp
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _openWhatsApp,
                  icon: const Icon(Icons.chat_rounded, size: 18),
                  label: const Text(
                    'Contactează-ne pe WhatsApp',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Deconectare
              TextButton(
                onPressed: () => _signOut(context),
                child: const Text(
                  'Deconectare',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white38,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefit(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF9070FF), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

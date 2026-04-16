import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nabour_app/l10n/app_localizations.dart';
import 'package:nabour_app/screens/map_screen.dart';

class AppWarmupScreen extends StatefulWidget {
  final VoidCallback? onDismiss;
  final bool edgeToEdge;

  const AppWarmupScreen({super.key, this.onDismiss, this.edgeToEdge = false});

  @override
  State<AppWarmupScreen> createState() => _AppWarmupScreenState();
}

class _AppWarmupScreenState extends State<AppWarmupScreen> {
  late _OfferContent _randomOffer;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    final season = _getCurrentSeason();
    
    final filteredOffers = _offerScenarios.where((o) => o.season == null || o.season == season).toList();
    _randomOffer = filteredOffers[rng.nextInt(filteredOffers.length)];
  }

  _Season _getCurrentSeason() {
    final month = DateTime.now().month;
    if (month >= 3 && month <= 5) return _Season.spring;
    if (month >= 6 && month <= 8) return _Season.summer;
    if (month >= 9 && month <= 11) return _Season.autumn;
    return _Season.winter;
  }

  void _navigateToMap() {
    if (widget.onDismiss != null) {
      widget.onDismiss!();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MapScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Immersive Blur Background
          // 1. Immersive City Blur Background
          Image.asset(
            'assets/images/city_blur_bg.png',
            fit: BoxFit.cover,
          ),
          Container(
            color: Colors.black.withValues(alpha: 0.55),
          ),

          // 2. UI Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  // Top Close Button
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: IconButton(
                        onPressed: _navigateToMap,
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          shape: const CircleBorder(),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Header
                  Text(
                    'Nabour',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.5,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    l10n.warmupSubtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const Spacer(flex: 1),

                  // Dynamic Local Offers Card
                  _StaticGlassCard(
                    icon: _randomOffer.icon,
                    iconBg: _randomOffer.iconBg,
                    title: _randomOffer.title,
                    subtitle: _randomOffer.subtitle,
                    details: _randomOffer.details,
                  ),

                  const SizedBox(height: 20),

                  // Live Animated Community Chat
                  const Expanded(
                    flex: 8,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: SingleChildScrollView(
                        reverse: true,
                        physics: BouncingScrollPhysics(),
                        child: _LiveCommunityChat(),
                      ),
                    ),
                  ),

                  const Spacer(flex: 1),

                  // "Go to map" Button
                  Container(
                    width: double.infinity,
                    height: 68,
                    margin: const EdgeInsets.only(bottom: 40),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(34),
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF3B82F6).withValues(alpha: 0.8),
                          const Color(0xFF1E293B).withValues(alpha: 0.9),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                          blurRadius: 25,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _navigateToMap,
                        borderRadius: BorderRadius.circular(34),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              l10n.warmupCtaOpenMap,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.location_on_rounded, color: Colors.white, size: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveCommunityChat extends StatefulWidget {
  const _LiveCommunityChat();

  @override
  State<_LiveCommunityChat> createState() => _LiveCommunityChatState();
}

class _LiveCommunityChatState extends State<_LiveCommunityChat> {
  late List<_ChatMessage> _scenario;
  final List<_ChatMessage> _visibleMessages = [];
  int _currentIndex = 0;
  bool _isTyping = false;
  String? _typingUser;
  Timer? _typingTimer;
  Timer? _messageTimer;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    final season = _getCurrentSeason();
    
    final filteredScenarios = _scenarios.where((s) => s.any((m) => m.season == null || m.season == season)).toList();
    _scenario = filteredScenarios[rng.nextInt(filteredScenarios.length)];
    _scheduleNextMessage();
  }

  _Season _getCurrentSeason() {
    final month = DateTime.now().month;
    if (month >= 3 && month <= 5) return _Season.spring;
    if (month >= 6 && month <= 8) return _Season.summer;
    if (month >= 9 && month <= 11) return _Season.autumn;
    return _Season.winter;
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _messageTimer?.cancel();
    super.dispose();
  }

  void _scheduleNextMessage() {
    if (_currentIndex >= _scenario.length) return;

    if (mounted) {
      setState(() {
        _isTyping = true;
        _typingUser = _scenario[_currentIndex].sender;
      });
    }

    final readTime = _currentIndex == 0 ? 0 : 600;
    final typeTime = 400 + (_scenario[_currentIndex].text.length * 8);

    _typingTimer = Timer(Duration(milliseconds: readTime + typeTime), () {
      if (!mounted) return;
      
      setState(() {
        _isTyping = false;
        _visibleMessages.add(_scenario[_currentIndex]);
        _currentIndex++;
      });
      
      _messageTimer = Timer(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        _scheduleNextMessage();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _visibleMessages.length; i++)
          AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeIn,
            child: _buildChatBubble(_visibleMessages[i]),
          ),
        
        if (_isTyping && _typingUser != null)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4, bottom: 16),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withValues(alpha: 0.6)),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$_typingUser scrie...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildChatBubble(_ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: msg.isBusiness 
                  ? msg.baseColor.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: msg.isBusiness 
                    ? msg.baseColor.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: msg.baseColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        msg.isBusiness ? Icons.storefront_rounded : Icons.person_rounded,
                        color: msg.baseColor,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      msg.sender,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (msg.role != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          msg.role!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  msg.text,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String sender;
  final String? role;
  final String text;
  final bool isBusiness;
  final Color baseColor;
  final _Season? season;

  const _ChatMessage({
    required this.sender,
    this.role,
    required this.text,
    this.isBusiness = false,
    required this.baseColor,
    this.season,
  });
}

enum _Season { spring, summer, autumn, winter }

final List<List<_ChatMessage>> _scenarios = [
  // Scenario 1: Ride Sharing
  [
    const _ChatMessage(
      sender: "Ștefan",
      role: "Nepotul",
      text: "Merg în centru, vine cineva cu mine? 🚗",
      isBusiness: false,
      baseColor: Color(0xFF60A5FA),
    ),
    const _ChatMessage(
      sender: "Laurențiu",
      role: "Unchiul",
      text: "Vin eu, cobor acum! 🏃‍♂️",
      baseColor: Color(0xFF34D399),
    ),
  ],
  // Extra: Summer Vibe
  [
    const _ChatMessage(
      sender: "Ștefan",
      role: "Nepotul",
      text: "Ieșim la o bere rece diseară? 🍺☀️",
      baseColor: Color(0xFF60A5FA),
      season: _Season.summer,
    ),
    const _ChatMessage(
      sender: "Irina",
      role: "Mama",
      text: "O plimbare în parc cu o înghețată sau clătite sună bine! 🍦🥞",
      baseColor: Color(0xFFF472B6),
      season: _Season.summer,
    ),
    const _ChatMessage(
      sender: "Food Truck",
      role: "Street Food",
      text: "Avem Quesadilla și bere rece la pachet! 🌮🍺",
      isBusiness: true,
      baseColor: Color(0xFFF59E0B),
      season: _Season.summer,
    ),
  ],
  // Extra: Winter Vibe
  [
    const _ChatMessage(
      sender: "Laurențiu",
      role: "Unchiul",
      text: "Cine vine la un vin fiert în piațetă? 🍷❄️",
      baseColor: Color(0xFF34D399),
      season: _Season.winter,
    ),
    const _ChatMessage(
      sender: "Claudia",
      role: "Mătușa",
      text: "Vin eu, e cam frig afară pentru plimbări! 🧣",
      baseColor: Color(0xFFA78BFA),
      season: _Season.winter,
    ),
    const _ChatMessage(
      sender: "Cafenea",
      role: "Business",
      text: "Avem ciocolată caldă din belșug azi! ☕",
      isBusiness: true,
      baseColor: Color(0xFFD97706),
      season: _Season.winter,
    ),
  ],
  // Scenario 2: Airport & Pizza (All-season)
  [
    const _ChatMessage(
      sender: "Irina",
      role: "Mama",
      text: "Are cineva drum la aeroport la 4.30 dimineața? ✈️",
      baseColor: Color(0xFFF472B6),
    ),
    const _ChatMessage(
      sender: "Laurențiu",
      role: "Unchiul",
      text: "Te duc eu, Irina. Fără probleme! 👍",
      baseColor: Color(0xFF34D399),
    ),
  ],
  // Food Truck Focus
  [
    const _ChatMessage(
      sender: "Food Truck",
      role: "Street Food",
      text: "Burger Artizanal și Quesadilla picantă gata de servit! 🍔🌮",
      isBusiness: true,
      baseColor: Color(0xFFF59E0B),
    ),
    const _ChatMessage(
      sender: "Ștefan",
      role: "Nepotul",
      text: "Vin acum pentru o quesadilla! 🏃‍♂️",
      baseColor: Color(0xFF60A5FA),
    ),
  ],
  // Scenario: Emergencies
  [
    const _ChatMessage(
      sender: "Claudia",
      role: "Mătușa",
      text: "Atenție! Inundație la subsolul din bloc. 🌊",
      baseColor: Color(0xFFA78BFA),
    ),
    const _ChatMessage(
      sender: "Laurențiu",
      role: "Unchiul",
      text: "Am sunat la service. Vin în 20 min! ✅",
      baseColor: Color(0xFF34D399),
    ),
  ],
];

class _OfferContent {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String details;
  final _Season? season;

  const _OfferContent({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.details,
    this.season,
  });
}

final List<_OfferContent> _offerScenarios = [
  _OfferContent(
    icon: Icons.coffee_rounded,
    iconBg: const Color(0xFFD97706),
    title: "Căldură în cartier ☕",
    subtitle: "Oferte de iarnă",
    details: "Cafenea: Vin fiert cu scorțișoară 🍷\nBrutărie: Plăcintă caldă cu mere.",
    season: _Season.winter,
  ),
  _OfferContent(
    icon: Icons.icecream_rounded,
    iconBg: const Color(0xFFF43F5E),
    title: "Răcoare de vară 🍦",
    subtitle: "Înghețată & Clătite",
    details: "Gelateria: Sorbet de pepene sosit! 🍉\nRulotă: Clătite uriașe cu finetti & miere. 🥞",
    season: _Season.summer,
  ),
  _OfferContent(
    icon: Icons.restaurant_rounded,
    iconBg: const Color(0xFFEF4444),
    title: "Cină la Food Truck 🍔",
    subtitle: "Burgeri & Quesadilla",
    details: "Meniu complet: Burger + Quesadilla mix!\nLivrări la pachet prin Nabour.",
  ),
  _OfferContent(
    icon: Icons.shopping_bag_rounded,
    iconBg: const Color(0xFF10B981),
    title: "Shopping Local 🛍️",
    subtitle: "Stoc proaspăt sosit",
    details: "Minimarket: Fructe și legume bio sosite azi.\nImobiliare: Vizionări apartamente noi la ora 17.",
    season: _Season.spring,
  ),
  _OfferContent(
    icon: Icons.content_cut_rounded,
    iconBg: const Color(0xFFEC4899),
    title: "Primăvară în cartier 💐",
    subtitle: "Răsfăț și Cadouri",
    details: "Studio Beauty: Reducere 30% la vopsit.\nFlorăria Bloom: Buchete de sezon de la 45 RON.",
    season: _Season.spring,
  ),
];

class _StaticGlassCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String details;

  const _StaticGlassCard({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconBg.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconBg, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                details,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



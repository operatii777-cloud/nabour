part of 'map_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
class _GhostModeSheet extends StatelessWidget {
  const _GhostModeSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text('👥', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          const Text(
            'Cât timp ești vizibil vecinilor?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Vecinii te vor vedea ca bulă pe hartă.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          _DurationTile(
            icon: '⏰',
            label: '1 oră',
            sub: 'Util pentru o ieșire scurtă',
            duration: const Duration(hours: 1),
          ),
          _DurationTile(
            icon: '🕓',
            label: '4 ore',
            sub: 'Util pentru o după-amiază',
            duration: const Duration(hours: 4),
          ),
          _DurationTile(
            icon: '🌙',
            label: 'Până mâine',
            sub: 'Se resetează la miezul nopții',
            duration: Duration(
              hours: 23 - DateTime.now().hour,
              minutes: 59 - DateTime.now().minute,
            ),
          ),
          _DurationTile(
            icon: '♾️',
            label: 'Permanent',
            sub: 'Rămâi vizibil până dezactivezi manual',
            duration: Duration.zero, // sentinel = permanent
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(),
          ),
          _DurationTile(
            icon: '🫥',
            label: 'Invizibil (mod fantomă)',
            sub: 'Nu apari pe hartă; profilul marchează ghostMode în cont (sync între dispozitive).',
            duration: _kInvisibleChoice,
            isDestructive: true,
          ),
        ],
      ),
    );
  }
}

class _DurationTile extends StatelessWidget {
  final String icon;
  final String label;
  final String sub;
  final Duration duration;
  final bool isDestructive;

  const _DurationTile({
    required this.icon,
    required this.label,
    required this.sub,
    required this.duration,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red.shade600 : const Color(0xFF7C3AED);
    return ListTile(
      dense: true,
      leading: Text(icon, style: const TextStyle(fontSize: 22)),
      title: Text(label,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: isDestructive ? Colors.red.shade700 : null)),
      subtitle: Text(sub,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      trailing: Icon(Icons.chevron_right_rounded, color: color),
      onTap: () => Navigator.of(context).pop(duration),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CLASE AUXILIARE (PROFILE SHEETS, OVERLAYS)
// ─────────────────────────────────────────────────────────────────────────────

class _NeighborProfileSheet extends StatefulWidget {
  final NeighborLocation neighbor;
  final double distanceKm;
  final String timeLabel;
  final String? phoneNumber;
  final VoidCallback onMessage;
  final Function(String) onSendReaction;
  final VoidCallback? onCall;
  final VoidCallback onSendEta;
  final VoidCallback onHonk;
  /// Bulă „cerere în cartier” ancorată lângă poziția lor pe hartă.
  final VoidCallback onNeighborhoodRequest;
  /// Emoji vizibil pe hartă la coordonatele lor (nu în chat).
  final void Function(String emoji) onSendMapEmoji;

  const _NeighborProfileSheet({
    required this.neighbor,
    required this.distanceKm,
    required this.timeLabel,
    this.phoneNumber,
    required this.onMessage,
    required this.onSendReaction,
    this.onCall,
    required this.onHonk,
    required this.onSendEta,
    required this.onNeighborhoodRequest,
    required this.onSendMapEmoji,
  });

  @override
  State<_NeighborProfileSheet> createState() => _NeighborProfileSheetState();
}

class _NeighborProfileSheetState extends State<_NeighborProfileSheet> {
  String _address = '';
  bool _etaDismissed = false;

  @override
  void initState() {
    super.initState();
    _fetchAddress();
  }

  Future<void> _fetchAddress() async {
    try {
      final placemarks = await geocoding.placemarkFromCoordinates(
        widget.neighbor.lat,
        widget.neighbor.lng,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        if (mounted) {
          setState(() {
            _address = p.street ?? '';
            if (_address.isEmpty) {
              _address = (p.subLocality ?? p.locality ?? '').trim();
            }
            if (_address.isEmpty) _address = 'Locatie necunoscuta';
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _address = 'Locatie necunoscuta');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtleColor = isDark ? Colors.grey.shade600 : Colors.grey.shade300;
    final labelColor = isDark ? Colors.grey.shade400 : Colors.blueGrey;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 30, spreadRadius: 0),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ──
          Container(
            width: 36, height: 4,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: subtleColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── Header: Street name + action icons ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  _address.isNotEmpty ? _address : '...',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: textColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              _HeaderIconButton(
                icon: Icons.campaign_rounded,
                color: isDark ? Colors.orange.shade300 : Colors.orange.shade800,
                bgColor: isDark ? Colors.orange.shade900.withValues(alpha: 0.3) : Colors.orange.shade50,
                onTap: () {
                  widget.onHonk();
                },
              ),
              const SizedBox(width: 8),
              _HeaderIconButton(
                icon: Icons.phone_rounded,
                color: widget.onCall != null
                    ? (isDark ? Colors.green.shade300 : Colors.green.shade700)
                    : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                bgColor: widget.onCall != null
                    ? (isDark ? Colors.green.shade900.withValues(alpha: 0.4) : Colors.green.shade50)
                    : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
                onTap: widget.onCall ?? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Numar de telefon indisponibil'), duration: Duration(seconds: 2)),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Time label + Avatar ──
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.neighbor.avatar.isNotEmpty ? widget.neighbor.avatar : '🙂',
                  style: const TextStyle(fontSize: 56),
                ),
              ),
              Positioned(
                top: -14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.timeLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: labelColor,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── ETA banner ──
          if (!_etaDismissed)
            GestureDetector(
              onTap: widget.onSendEta,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade700 : const Color(0xFFF1F5F9),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Va vedeti cu cineva? Trimite-ti ETA-ul live',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: labelColor,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _etaDismissed = true),
                      child: Icon(Icons.close, size: 16, color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ),
            ),

          if (!_etaDismissed) const SizedBox(height: 16),

          Text(
            'Contact: ${widget.neighbor.displayName}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 12),

          // ── Message button (green pill) ──
          Row(
            children: [
              // Avatar mic stanga
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.neighbor.avatar.isNotEmpty ? widget.neighbor.avatar : '🙂',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.onMessage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Mesaj privat',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Distance badge dreapta
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.distanceKm < 1
                      ? '${(widget.distanceKm * 1000).round()} m'
                      : '${widget.distanceKm.toStringAsFixed(1)} km',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: labelColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onNeighborhoodRequest,
              icon: Icon(Icons.water_drop_outlined, color: Colors.indigo.shade700),
              label: Text(
                'Cerere în cartier (bulă pe hartă)',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.indigo.shade800,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: Colors.indigo.shade200),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Emoji pe hartă (lângă ei)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: labelColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _kNeighborQuickMapEmojis.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final em = _kNeighborQuickMapEmojis[i];
                return Material(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: () => widget.onSendMapEmoji(em),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Center(
                        child: Text(em, style: const TextStyle(fontSize: 26)),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Sticker-e în chat',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: labelColor,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ── Emoji reactions grid (2 rows of stickers) ──
          SizedBox(
            height: 180,
            child: GridView.count(
              crossAxisCount: 5,
              mainAxisSpacing: 8,
              crossAxisSpacing: 4,
              physics: const BouncingScrollPhysics(),
              children: _kReactions.map((r) {
                return _ReactionItem(
                  emoji: r['emoji']!,
                  label: r['label']!,
                  labelColor: labelColor,
                  bgColor: isDark ? Colors.grey.shade800 : Colors.white,
                  onTap: () => widget.onSendReaction(r['emoji']!),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Emoji rapide plasate pe hartă la poziția contactului (tap pe marker).
const List<String> _kNeighborQuickMapEmojis = [
  '\u2764\uFE0F',
  '👋',
  '🔥',
  '😂',
  '👍',
  '🎉',
  '📍',
  '☕',
];

const List<Map<String, String>> _kReactions = [
  {'emoji': '👍', 'label': 'Thumbs'},
  {'emoji': '🔥', 'label': 'Fire'},
  {'emoji': '😍', 'label': 'Yesssss'},
  {'emoji': '💩', 'label': 'Poop Girl'},
  {'emoji': '🤡', 'label': 'Actooor'},
  {'emoji': '❤️', 'label': 'Inimoare'},
  {'emoji': '💥', 'label': 'Stric'},
  {'emoji': '👀', 'label': 'Ochi'},
  {'emoji': '😭', 'label': 'Cry cry'},
  {'emoji': '👋', 'label': 'Hello!'},
  {'emoji': '🍺', 'label': 'Bei ceva?'},
  {'emoji': '🎉', 'label': 'Party'},
  {'emoji': '💀', 'label': 'Dead'},
  {'emoji': '🤣', 'label': 'LOL'},
  {'emoji': '🙏', 'label': 'Mersi'},
];

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}

class _ReactionItem extends StatelessWidget {
  final String emoji;
  final String label;
  final Color labelColor;
  final Color bgColor;
  final VoidCallback onTap;

  const _ReactionItem({
    required this.emoji,
    required this.label,
    required this.labelColor,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52, // ✅ Redus de la 56 pentru a evita overflow de 8px
            height: 52, // ✅ Redus de la 56
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 28)), // ✅ Redus font de la 32
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 60,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: labelColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Geocoding o singură dată per deschidere sheet — nu re-intră în serviciu la rebuild-uri locale.
class _MapTapGeocodeSheetBody extends StatefulWidget {
  const _MapTapGeocodeSheetBody({
    required this.lat,
    required this.lng,
    required this.sheetContext,
    required this.mapScreenContext,
    required this.onOpenFavorite,
    required this.onStartInAppNav,
  });

  final double lat;
  final double lng;
  final BuildContext sheetContext;
  final BuildContext mapScreenContext;
  final Future<void> Function(double lat, double lng, String address) onOpenFavorite;
  final Future<void> Function(double destLat, double destLng, String label) onStartInAppNav;

  @override
  State<_MapTapGeocodeSheetBody> createState() => _MapTapGeocodeSheetBodyState();
}

class _MapTapGeocodeSheetBodyState extends State<_MapTapGeocodeSheetBody> {
  late final Future<String?> _addressFuture = GeocodingService()
      .getAddressFromCoordinates(widget.lat, widget.lng);

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
        final address = snap.data != null && snap.data!.trim().isNotEmpty
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
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.star_rounded, color: Colors.amber),
              title: const Text('Adaugă la adrese favorite'),
              onTap: () {
                Navigator.pop(sheetCtx);
                unawaited(widget.onOpenFavorite(lat, lng, address));
              },
            ),
            ListTile(
              leading: const Icon(Icons.explore_rounded, color: Color(0xFF7C3AED)),
              title: const Text('Navigare cu Nabour'),
              subtitle: const Text('Traseu pe harta Nabour + instrucțiuni voce'),
              onTap: () {
                Navigator.pop(sheetCtx);
                unawaited(widget.onStartInAppNav(lat, lng, address));
              },
            ),
            ListTile(
              leading: const Icon(Icons.navigation_outlined, color: Colors.green),
              title: const Text('Alte aplicații (Google Maps / Waze)'),
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

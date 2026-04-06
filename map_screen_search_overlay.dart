part of 'map_screen.dart';

/// Overlay căutare universală (contacte + locuri), stil card alb rotunjit peste hartă semi-întunecată.
class MapUniversalSearchOverlay extends StatefulWidget {
  const MapUniversalSearchOverlay({
    super.key,
    required this.onClose,
    required this.contacts,
    required this.friendPeerUids,
    required this.visibleNeighbors,
    required this.neighborEmojiByUid,
    required this.neighborPhotoUrlByUid,
    required this.userPosition,
    required this.onPlaceChosen,
    required this.onContactChosen,
    this.onAddFriend,
  });

  final VoidCallback onClose;
  final List<ContactAppUser> contacts;
  final Set<String> friendPeerUids;
  final List<NeighborLocation> visibleNeighbors;
  /// Emoji-uri din fluxul hărții (aceeași sursă ca Sugestii prieteni).
  final Map<String, String> neighborEmojiByUid;
  final Map<String, String> neighborPhotoUrlByUid;
  final geolocator.Position? userPosition;

  final void Function(double lat, double lng, String label) onPlaceChosen;
  final void Function(String uid) onContactChosen;
  final Future<void> Function(String uid)? onAddFriend;

  @override
  State<MapUniversalSearchOverlay> createState() =>
      _MapUniversalSearchOverlayState();
}

class _MapUniversalSearchPlaceRow {
  const _MapUniversalSearchPlaceRow(this.suggestion, this.fromLocalBundle);

  final AddressSuggestion suggestion;
  final bool fromLocalBundle;
}

class _MapUniversalSearchOverlayState extends State<MapUniversalSearchOverlay> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  Timer? _debounce;
  List<_MapUniversalSearchPlaceRow> _placeRows = [];
  bool _placesLoading = false;
  bool _peopleExpanded = false;
  Map<String, int> _friendCountByUid = {};
  Map<String, int> _mutualFriendPeersByUid = {};
  bool _metricsLoading = true;
  StreamSubscription<List<SavedAddress>>? _savedAddressesSub;
  List<SavedAddress> _savedAddresses = <SavedAddress>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
    unawaited(_loadPeopleMetrics());
    _savedAddressesSub = FirestoreService().getSavedAddresses().listen((list) {
      if (mounted) setState(() => _savedAddresses = list);
    });
  }

  Future<void> _loadPeopleMetrics() async {
    final uids = <String>{
      ...widget.contacts.map((c) => c.uid),
      ...widget.visibleNeighbors.map((n) => n.uid),
    };
    if (uids.isEmpty) {
      if (mounted) setState(() => _metricsLoading = false);
      return;
    }
    final m = await MapUniversalSearchMetricsService.instance.loadPeopleMetrics(
      candidateUids: uids,
      myFriendPeerUids: widget.friendPeerUids,
    );
    if (!mounted) return;
    setState(() {
      _friendCountByUid = m.friendCountByUid;
      _mutualFriendPeersByUid = m.mutualFriendPeersByUid;
      _metricsLoading = false;
    });
  }

  @override
  void dispose() {
    _savedAddressesSub?.cancel();
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  List<AddressSuggestion> _savedAddressSuggestions(
    String trimmed,
    geolocator.Position pos,
  ) {
    final qn = normalizeRomanianTextForSearch(trimmed);
    if (qn.length < 2) return [];
    final scored = <({SavedAddress a, double sc})>[];
    for (final addr in _savedAddresses) {
      final sc = savedAddressMatchScoreNormalized(qn, addr);
      if (sc > 0) scored.add((a: addr, sc: sc));
    }
    scored.sort((x, y) => y.sc.compareTo(x.sc));
    return scored.map((e) {
      final addr = e.a;
      final dist = geolocator.Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        addr.coordinates.latitude,
        addr.coordinates.longitude,
      );
      return AddressSuggestion(
        description: savedAddressDisplayLine(addr),
        latitude: addr.coordinates.latitude,
        longitude: addr.coordinates.longitude,
        score: (100 * e.sc).round().clamp(1, 999),
        distanceMeters: dist,
      );
    }).toList();
  }

  List<_MapUniversalSearchPlaceRow> _mergePlaceRowsWithSaved(
    List<AddressSuggestion> saved,
    List<AddressSuggestion> local,
    List<AddressSuggestion> remote,
  ) {
    final out = <_MapUniversalSearchPlaceRow>[];
    bool isDup(AddressSuggestion s) {
      return out.any((row) {
        final o = row.suggestion;
        return geolocator.Geolocator.distanceBetween(
              o.latitude,
              o.longitude,
              s.latitude,
              s.longitude,
            ) <
            85;
      });
    }

    void addAll(List<AddressSuggestion> list, bool fromLocalBundle) {
      for (final s in list) {
        if (!isDup(s)) {
          out.add(_MapUniversalSearchPlaceRow(s, fromLocalBundle));
        }
      }
    }

    addAll(saved, true);
    addAll(local, true);
    addAll(remote, false);
    return out.take(16).toList();
  }

  bool _nameMatches(String name, String q) {
    if (q.trim().isEmpty) return true;
    return name.toLowerCase().contains(q.toLowerCase().trim());
  }

  void _schedulePlacesSearch(String q) {
    _debounce?.cancel();
    final trimmed = q.trim();
    if (trimmed.length < 2) {
      setState(() {
        _placeRows = [];
        _placesLoading = false;
      });
      return;
    }
    final pos = widget.userPosition;
    if (pos == null) {
      setState(() {
        _placeRows = [];
        _placesLoading = false;
      });
      return;
    }
    setState(() => _placesLoading = true);
    _debounce = Timer(const Duration(milliseconds: 380), () async {
      List<_MapUniversalSearchPlaceRow> rows;
      try {
        final saved = _savedAddressSuggestions(trimmed, pos);
        final local = await LocalAddressDatabase().search(trimmed, pos);
        final remote = await GeocodingService().fetchSuggestions(trimmed, pos);
        rows = _mergePlaceRowsWithSaved(saved, local, remote);
      } catch (_) {
        rows = [];
      }
      if (!mounted) return;
      setState(() {
        _placeRows = rows;
        _placesLoading = false;
      });
    });
  }

  String _placeInitials(String name) {
    final t = name.trim();
    if (t.isEmpty) return '?';
    final parts =
        t.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.length >= 2) {
      return (parts[0].substring(0, 1) + parts[1].substring(0, 1))
          .toUpperCase();
    }
    final one = parts.isNotEmpty ? parts[0] : t;
    if (one.length >= 3) return one.substring(0, 3).toUpperCase();
    return one.toUpperCase();
  }

  Widget _placeLeading(String title, {bool fromLocal = false}) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF3949AB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          _placeInitials(title),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _contactLeading(String uid, String displayName) {
    final url = widget.neighborPhotoUrlByUid[uid];
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(backgroundImage: NetworkImage(url));
    }
    final em = widget.neighborEmojiByUid[uid];
    if (em != null && em.isNotEmpty && em.length <= 8) {
      return CircleAvatar(
        backgroundColor: Colors.grey.shade200,
        child: Text(em, style: const TextStyle(fontSize: 22)),
      );
    }
    return CircleAvatar(
      backgroundColor: const Color(0xFF3949AB),
      child: Text(
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  String _personSubtitle(String uid) {
    final isFriend = widget.friendPeerUids.contains(uid);
    final mutual = _mutualFriendPeersByUid[uid] ?? 0;
    final fc = _friendCountByUid[uid] ?? 0;

    if (mutual > 0) {
      return 'Cunoaște $mutual ${mutual == 1 ? 'prieten' : 'prieteni'}';
    }
    if (fc > 0) {
      if (fc > 50) {
        return isFriend ? 'Prieten în Nabour · 50+ prieteni' : '50+ prieteni';
      }
      return isFriend ? 'Prieten în Nabour · $fc prieteni' : '$fc prieteni';
    }
    if (isFriend) return 'Prieten în Nabour';
    if (widget.visibleNeighbors.any((n) => n.uid == uid)) {
      return 'Pe hartă acum';
    }
    return 'În agendă (Nabour)';
  }

  String _neighborRowSubtitle(NeighborLocation n) {
    final social = _personSubtitle(n.uid);
    final diffMin = DateTime.now().difference(n.lastUpdate).inMinutes;
    final time = diffMin <= 1 ? 'acum' : 'acum $diffMin min';
    if (!_metricsLoading &&
        (social.contains('prieteni') || social.contains('Cunoaște'))) {
      return '$social · pe hartă $time';
    }
    if (diffMin <= 1) return 'Pe hartă · actualizat acum';
    return 'Pe hartă · actualizat $time';
  }

  List<ContactAppUser> _matchingContacts(String q) {
    final out =
        widget.contacts.where((c) => _nameMatches(c.displayName, q)).toList();
    out.sort((a, b) {
      final ma = _mutualFriendPeersByUid[a.uid] ?? 0;
      final mb = _mutualFriendPeersByUid[b.uid] ?? 0;
      if (ma != mb) return mb.compareTo(ma);
      final fa = widget.friendPeerUids.contains(a.uid);
      final fb = widget.friendPeerUids.contains(b.uid);
      if (fa != fb) return fa ? -1 : 1;
      final ca = _friendCountByUid[a.uid] ?? 0;
      final cb = _friendCountByUid[b.uid] ?? 0;
      if (ca != cb) return cb.compareTo(ca);
      return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
    });
    return out;
  }

  List<NeighborLocation> _neighborOnlyMatches(String q) {
    if (q.trim().isEmpty) return [];
    final contactUids = widget.contacts.map((c) => c.uid).toSet();
    final list = widget.visibleNeighbors
        .where(
          (n) =>
              _nameMatches(n.displayName, q) && !contactUids.contains(n.uid),
        )
        .toList();
    list.sort((a, b) {
      final ma = _mutualFriendPeersByUid[a.uid] ?? 0;
      final mb = _mutualFriendPeersByUid[b.uid] ?? 0;
      if (ma != mb) return mb.compareTo(ma);
      final ca = _friendCountByUid[a.uid] ?? 0;
      final cb = _friendCountByUid[b.uid] ?? 0;
      if (ca != cb) return cb.compareTo(ca);
      return a.displayName
          .toLowerCase()
          .compareTo(b.displayName.toLowerCase());
    });
    return list;
  }

  String _formatDistanceKm(double? meters) {
    if (meters == null) return '';
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    final q = _controller.text;

    final contactsShown = _matchingContacts(q);
    final neighborsShown = _neighborOnlyMatches(q);
    final peopleCap = _peopleExpanded ? 24 : 5;
    final peopleTotal = contactsShown.length + neighborsShown.length;
    final takeContacts = peopleCap.clamp(0, contactsShown.length);
    final remaining = peopleCap - takeContacts;
    final takeNeighbors = remaining.clamp(0, neighborsShown.length);

    return Material(
      color: Colors.black45,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onClose,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            top: MediaQuery.of(context).padding.top + 6,
            bottom: 96 + bottomSafe + bottomInset,
            child: GestureDetector(
              onTap: () {},
              child: Material(
                elevation: 12,
                shadowColor: Colors.black38,
                borderRadius: BorderRadius.circular(22),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focus,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Caută prieteni și locuri...',
                          border: InputBorder.none,
                          isDense: true,
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                          suffixIcon: q.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded,
                                      color: Colors.black54),
                                  onPressed: () {
                                    _controller.clear();
                                    setState(() {
                                      _placeRows = [];
                                      _placesLoading = false;
                                    });
                                    _focus.requestFocus();
                                  },
                                )
                              : const Icon(Icons.search_rounded,
                                  color: Colors.black38),
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                        onChanged: (v) {
                          setState(() {});
                          _schedulePlacesSearch(v);
                        },
                      ),
                    ),
                    Divider(height: 1, color: Colors.grey.shade200),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 12),
                        children: [
                          if (q.trim().isEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  16, 14, 16, 6),
                              child: Text(
                                'Sugerat',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.grey.shade600,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ] else ...[
                            if (contactsShown.isNotEmpty ||
                                neighborsShown.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    16, 12, 16, 6),
                                child: Text(
                                  'Utilizatori',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.grey.shade600,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                          ],
                          for (final c in contactsShown.take(takeContacts))
                            _userTile(
                              leading:
                                  _contactLeading(c.uid, c.displayName),
                              title: c.displayName,
                              subtitle: _personSubtitle(c.uid),
                              uid: c.uid,
                              mutualBadge:
                                  _mutualFriendPeersByUid[c.uid] ?? 0,
                              showAdd: !widget.friendPeerUids.contains(c.uid),
                            ),
                          for (final n in neighborsShown.take(takeNeighbors))
                            _userTile(
                              leading: n.photoURL != null &&
                                      n.photoURL!.isNotEmpty
                                  ? CircleAvatar(
                                      backgroundImage:
                                          NetworkImage(n.photoURL!),
                                    )
                                  : _contactLeading(n.uid, n.displayName),
                              title: n.displayName,
                              subtitle: _neighborRowSubtitle(n),
                              uid: n.uid,
                              mutualBadge:
                                  _mutualFriendPeersByUid[n.uid] ?? 0,
                              showAdd:
                                  !widget.friendPeerUids.contains(n.uid),
                            ),
                          if (peopleTotal > peopleCap)
                            TextButton(
                              onPressed: () => setState(
                                  () => _peopleExpanded = !_peopleExpanded),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _peopleExpanded
                                        ? 'Mai puțini utilizatori'
                                        : 'VEZI MAI MULȚI UTILIZATORI',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Icon(
                                    _peopleExpanded
                                        ? Icons.expand_less_rounded
                                        : Icons.expand_more_rounded,
                                  ),
                                ],
                              ),
                            ),
                          if (q.trim().length >= 2 &&
                              widget.userPosition != null) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  16, 8, 16, 6),
                              child: Text(
                                'Locuri',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.grey.shade600,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            if (_placesLoading)
                              const Padding(
                                padding: EdgeInsets.all(20),
                                child: Center(
                                  child: SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.5),
                                  ),
                                ),
                              )
                            else if (_placeRows.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16),
                                child: Text(
                                  'Nu am găsit locuri pentru „$q”.',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ),
                            for (final row in _placeRows.take(12))
                              ListTile(
                                leading: _placeLeading(
                                  row.suggestion.description
                                      .split(',')
                                      .first
                                      .trim(),
                                  fromLocal: row.fromLocalBundle,
                                ),
                                title: Text(
                                  row.suggestion.description
                                      .split(',')
                                      .first
                                      .trim(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                subtitle: Text(
                                  [
                                    _formatDistanceKm(
                                        row.suggestion.distanceMeters),
                                    if (row.fromLocalBundle)
                                      'În datele Nabour',
                                    row.suggestion.description,
                                  ].where((e) => e.isNotEmpty).join(' · '),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                onTap: () {
                                  widget.onPlaceChosen(
                                    row.suggestion.latitude,
                                    row.suggestion.longitude,
                                    row.suggestion.description,
                                  );
                                  widget.onClose();
                                },
                              ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _userTile({
    required Widget leading,
    required String title,
    required String subtitle,
    required String uid,
    required int mutualBadge,
    required bool showAdd,
  }) {
    return ListTile(
      leading: leading,
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
          if (mutualBadge > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$mutualBadge ${mutualBadge == 1 ? 'comun' : 'comuni'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        subtitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      trailing: showAdd && widget.onAddFriend != null
          ? Material(
              color: const Color(0xFF3949AB),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () async {
                  await widget.onAddFriend!(uid);
                  if (mounted) setState(() {});
                },
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(Icons.add_rounded, color: Colors.white),
                ),
              ),
            )
          : null,
      onTap: () {
        widget.onContactChosen(uid);
        widget.onClose();
      },
    );
  }
}

class _ParkingReservationSheet extends StatefulWidget {
  final String spotId;
  final VoidCallback onReserved;

  const _ParkingReservationSheet({required this.spotId, required this.onReserved});

  @override
  _ParkingReservationSheetState createState() => _ParkingReservationSheetState();
}

class _ParkingReservationSheetState extends State<_ParkingReservationSheet> {
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
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Icon(Icons.local_parking_rounded, color: Colors.amber, size: 48),
          const SizedBox(height: 16),
          const Text(
            'LOC DE AUR DETECTAT',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isReserving 
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text('REZERVĂ LOCUL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
          const SnackBar(content: Text('Ne pare rău, locul a fost deja rezervat.')),
        );
      }
    }
  }
}

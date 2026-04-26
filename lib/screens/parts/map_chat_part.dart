// ignore_for_file: invalid_use_of_protected_member
part of '../map_screen.dart';

// ── Map Chat extension ────────────────────────────────────────────────────────
//
// Gestionează toată logica "speech bubble" și monitorul de chat pe hartă.
// Variabilele de stare sunt declarate în _MapScreenState (map_screen.dart).
//
// UX DESIGN:
//  • Bulele apar automat deasupra avatarelor FĂRĂ ca userul să apese nimic.
//  • Când cineva îți trimite un mesaj, bula lui apare pe harta ta pasiv.
//  • Monitorul se deschide DOAR dacă apeși "Chat pe hartă" — e opțional.
//

extension _MapChatMethods on _MapScreenState {
  // ─── Listeners pasivi: detectare automată mesaje primite ─────────────────
  //
  // Se apelează din map_neighbor_part.dart după orice update al _neighborData.
  // Pornește un listener pentru fiecare vecin nou; anulează pentru cei dispăruți.

  void _syncPassiveListeners() {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    // Pornește listener pentru vecini noi
    for (final nUid in _neighborData.keys) {
      if (nUid == myUid) continue;
      if (_passiveBubbleSubs.containsKey(nUid)) continue;
      _startPassiveListenerForNeighbor(nUid, myUid);
    }

    // Anulează listeners pentru vecini care au dispărut de pe hartă
    final gone = _passiveBubbleSubs.keys
        .where((uid) => !_neighborData.containsKey(uid))
        .toList();
    for (final uid in gone) {
      _passiveBubbleSubs.remove(uid)?.cancel();
      if (mounted) {
        setState(() {
          _mapChatBubbleTexts.remove(uid);
          _mapChatBubblePositions.remove(uid);
        });
      }
    }
  }

  void _startPassiveListenerForNeighbor(String nUid, String myUid) {
    final chatId = MapChatMessage.chatIdFor1to1(myUid, nUid);
    _passiveBubbleSubs[nUid] = MapChatService.instance
        .latestBubbleForUser(chatId: chatId, userId: nUid)
        .listen((msg) {
      if (!mounted) return;
      if (msg == null) {
        if (_mapChatBubbleTexts.containsKey(nUid)) {
          setState(() {
            _mapChatBubbleTexts.remove(nUid);
            _mapChatBubblePositions.remove(nUid);
          });
        }
        return;
      }
      setState(() => _mapChatBubbleTexts[nUid] = msg.text);
      _ensureBubblePositionTimer();

      // UX Improvement: Auto-open chat monitor on first received message (if fresh)
      // Acest lucru facilitează conversația instantanee fără a cere receptorului un tap manual.
      if (!_mapChatMonitorVisible || _mapChatActivePeerUid != nUid) {
        final age = DateTime.now().difference(msg.timestamp);
        if (age.inSeconds < 15) {
          _openMapChat(nUid);
        }
      }
    });
  }

  // ─── Deschide monitorul de chat (opțional, la cererea explicită) ──────────

  void _openMapChat(String peerUid) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    final chatId = MapChatMessage.chatIdFor1to1(myUid, peerUid);
    final myDisplayName =
        FirebaseAuth.instance.currentUser?.displayName ?? 'Tu';
    final myAvatar = _neighborAvatarCache[myUid] ?? '🙂';

    setState(() {
      _mapChatActivePeerUid = peerUid;
      _mapChatActiveChatId = chatId;
      _mapChatMonitorVisible = true;
      _mapChatMyName = myDisplayName;
      _mapChatMyEmoji = myAvatar;
    });

    // Typing indicator — activ doar cât monitorul e deschis
    _mapChatTypingBubbleSub?.cancel();
    _mapChatTypingBubbleSub = MapChatService.instance
        .typingStream(chatId: chatId, userId: peerUid)
        .listen((isTyping) {
      if (!mounted) return;
      setState(() {
        if (isTyping) {
          _mapChatBubbleTyping[peerUid] = true;
        } else {
          _mapChatBubbleTyping.remove(peerUid);
        }
      });
    });

    _ensureBubblePositionTimer();
  }

  // ─── Închide monitorul (bulele rămân active via passive listeners) ────────

  void _closeMapChat() {
    _mapChatTypingBubbleSub?.cancel();
    _mapChatTypingBubbleSub = null;
    if (mounted) {
      final myUid = FirebaseAuth.instance.currentUser?.uid;
      setState(() {
        _mapChatActivePeerUid = null;
        _mapChatActiveChatId = null;
        _mapChatMonitorVisible = false;
        _mapChatBubbleTyping.clear();
        // Bula proprie dispare la închidere monitor
        if (myUid != null) {
          _mapChatBubbleTexts.remove(myUid);
          _mapChatBubblePositions.remove(myUid);
        }
      });
    }
  }

  // ─── Position timer ────────────────────────────────────────────────────────

  void _ensureBubblePositionTimer() {
    if (_mapChatBubblePosTimer?.isActive ?? false) return;
    _mapChatBubblePosTimer =
        Timer.periodic(const Duration(milliseconds: 300), (_) {
      if (!mounted) {
        _mapChatBubblePosTimer?.cancel();
        _mapChatBubblePosTimer = null;
        return;
      }
      unawaited(_updateBubblePositions());
    });
  }

  // ─── Actualizarea pozițiilor bulelor (pentru TOȚI, nu doar peer activ) ────

  Future<void> _updateBubblePositions() async {
    final map = _mapboxMap;
    if (map == null) return;
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    final allUids = <String>{
      ..._mapChatBubbleTexts.keys,
      ..._mapChatBubbleTyping.keys,
    };

    if (allUids.isEmpty) {
      _mapChatBubblePosTimer?.cancel();
      _mapChatBubblePosTimer = null;
      return;
    }

    for (final uid in allUids) {
      double? lat, lng;
      if (uid == myUid) {
        final pos = _currentPositionObject;
        if (pos == null) continue;
        lat = pos.latitude;
        lng = pos.longitude;
      } else {
        final neighbor = _neighborData[uid];
        if (neighbor == null) continue;
        lat = neighbor.lat;
        lng = neighbor.lng;
      }

      final sc = await _projectLatLngToScreen(lat, lng);
      if (!mounted) return;
      if (sc != null) {
        if (_mapChatBubblePositions[uid] != sc) {
          setState(() => _mapChatBubblePositions[uid] = sc);
        }
      }
    }
  }

  // ─── Construiește overlay-urile de chat ────────────────────────────────────

  List<Widget> _buildMapChatOverlays() {
    final widgets = <Widget>[];
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    // Bule pentru TOȚI participanții (vecini + eu) — nu doar peer-ul activ
    final allUids = <String>{
      ..._mapChatBubbleTexts.keys,
      ..._mapChatBubbleTyping.keys,
    };

    for (final uid in allUids) {
      final pos = _mapChatBubblePositions[uid];
      final text = _mapChatBubbleTexts[uid];
      final isTyping = _mapChatBubbleTyping[uid] ?? false;

      if (pos == null) continue;
      if (!isTyping && (text == null || text.isEmpty)) continue;

      final String name;
      final String emoji;
      if (uid == myUid) {
        name = _mapChatMyName.isNotEmpty
            ? _mapChatMyName
            : FirebaseAuth.instance.currentUser?.displayName ?? 'Tu';
        emoji = _mapChatMyEmoji;
      } else {
        name = _neighborDisplayNameCache[uid] ??
            _neighborData[uid]?.displayName ??
            'Vecin';
        emoji = _neighborAvatarCache[uid] ?? '🙂';
      }

      widgets.add(
        PositionedSpeechBubble(
          key: ValueKey('bubble_$uid'),
          screenOffset: pos,
          text: text ?? '',
          senderName: name,
          avatarEmoji: emoji,
          isTyping: isTyping,
          onDismissed: () {
            if (mounted) setState(() => _mapChatBubbleTexts.remove(uid));
          },
        ),
      );
    }

    // Monitor de chat (draggable mini-panel) — opțional
    if (_mapChatMonitorVisible &&
        _mapChatActiveChatId != null &&
        _mapChatActivePeerUid != null) {
      final pUid = _mapChatActivePeerUid!;
      final cId = _mapChatActiveChatId!;
      final peerName = _neighborDisplayNameCache[pUid] ??
          _neighborData[pUid]?.displayName ??
          'Vecin';
      final peerEmoji = _neighborAvatarCache[pUid] ?? '🙂';

      widgets.add(
        MapChatMonitor(
          key: ValueKey('monitor_$cId'),
          chatId: cId,
          myUid: myUid ?? '',
          myName: _mapChatMyName,
          myAvatarEmoji: _mapChatMyEmoji,
          peerUid: pUid,
          peerName: peerName,
          peerAvatarEmoji: peerEmoji,
          onClose: _closeMapChat,
          onMessageSent: (msg) {
            if (myUid == null) return;
            setState(() {
              _mapChatBubbleTexts[myUid] = msg.text;
              _mapChatBubbleTyping.remove(myUid);
            });
            _ensureBubblePositionTimer();
          },
        ),
      );
    }

    return widgets;
  }

  // ─── Cleanup complet (apelat din dispose) ─────────────────────────────────

  void _disposeMapChat() {
    _mapChatTypingBubbleSub?.cancel();
    _mapChatBubblePosTimer?.cancel();
    for (final sub in _passiveBubbleSubs.values) {
      sub.cancel();
    }
    _passiveBubbleSubs.clear();
  }
}

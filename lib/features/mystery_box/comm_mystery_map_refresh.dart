/// Map refresh bus for community box pins.
class CommunityMysteryMapRefresh {
  CommunityMysteryMapRefresh._();
  static final CommunityMysteryMapRefresh instance = CommunityMysteryMapRefresh._();

  final List<void Function()> _listeners = [];

  void addListener(void Function() fn) => _listeners.add(fn);

  void removeListener(void Function() fn) {
    _listeners.remove(fn);
  }

  void notify() {
    for (final fn in List<void Function()>.from(_listeners)) {
      fn();
    }
  }
}

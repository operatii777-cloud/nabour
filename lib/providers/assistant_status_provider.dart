import 'package:flutter/foundation.dart';

enum AssistantWorkStatus { idle, working }

class AssistantStatusProvider extends ChangeNotifier {
  bool _overlayEnabled = false;
  AssistantWorkStatus _status = AssistantWorkStatus.idle;

  bool get overlayEnabled => _overlayEnabled;
  AssistantWorkStatus get status => _status;

  void setOverlayEnabled(bool enabled) {
    if (_overlayEnabled == enabled) return;
    _overlayEnabled = enabled;
    notifyListeners();
  }

  void setStatus(AssistantWorkStatus newStatus) {
    if (_status == newStatus) return;
    _status = newStatus;
    notifyListeners();
  }
}




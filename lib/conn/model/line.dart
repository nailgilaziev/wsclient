import 'package:flutter/foundation.dart';

enum LineStatus {
  disconnected,
  waiting,
  searching,
  connecting,
  authorising,
  fetching,
  idle,
  disconnecting,
}

/// if modeOffline = false - status describes current state
/// if modeOffline = true - status is null
/// lastSync is null - if no synced data before, otherwise date
/// err is filled for some LineStatuses for help to understand whats
/// going on with device connection
class Line with ChangeNotifier {
  Line({bool initialModeOffline = true}) {
    modeOffline = initialModeOffline;
  }

  bool _modeOffline = true;

  bool get modeOffline => _modeOffline;

  set modeOffline(bool v) {
    _modeOffline = v;
    if (_modeOffline) {
      _status = null;
      _err = null;
    } else {
      _status = LineStatus.disconnected;
    }
    notifyListeners();
  }

  LineStatus _status;

  LineStatus get status => _status;

  dynamic _err;

  dynamic get err => _err;

  DateTime lastSync;

  static const _manualConnectStatuses = [
    LineStatus.disconnected,
    LineStatus.waiting
  ];

  bool get manualConnectAvailable =>
      !modeOffline && _manualConnectStatuses.contains(status);

  static const _manualCloseStatuses = [
    LineStatus.authorising,
    LineStatus.fetching,
    LineStatus.idle
  ];

  bool get manualCloseAvailable {
    return !modeOffline && _manualCloseStatuses.contains(status);
  }

  void statusChangedTo(LineStatus newStatus, {dynamic withEx}) {
    if (_modeOffline) return;
    if (_status == newStatus && err == withEx) return;
    _status = newStatus;
    //if error not specified it will be null. new status by default without error. move to doc section
    _err = withEx;
    notifyListeners();
  }
}

class ConLine {}

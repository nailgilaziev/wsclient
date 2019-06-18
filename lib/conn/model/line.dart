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

/// lastSync is null - if no synced data before, otherwise date
/// err is filled for some LineStatuses for help to understand whats
/// going on with device connection
class Line with ChangeNotifier {
  LineStatus _status = LineStatus.disconnected;

  LineStatus get status => _status;

  dynamic _err;

  dynamic get err => _err;

  DateTime lastSync;

  static const _manualConnectStatuses = [
    LineStatus.disconnected,
    LineStatus.waiting
  ];

  bool get manualConnectAvailable => _manualConnectStatuses.contains(status);

  static const _manualCloseStatuses = [
    LineStatus.authorising,
    LineStatus.fetching,
    LineStatus.idle
  ];

  bool get manualCloseAvailable => _manualCloseStatuses.contains(status);

  /// new status by default without error.
  /// last error will be overridden with null value
  void statusChangedTo(LineStatus newStatus, {dynamic withEx}) {
    // ignore: always_put_control_body_on_new_line
    if (_status == newStatus && err == withEx) return;

    /// if error not specified it will be null.
    _err = withEx;
    _status = newStatus;
    notifyListeners();
  }
}

class ConLine {}

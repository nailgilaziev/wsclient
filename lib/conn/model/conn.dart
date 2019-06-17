import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:wsclient/conn/model/line.dart';
import 'package:wsclient/utils/mem_logs.dart';

class AutoReconnectConf with ChangeNotifier {
  bool _state;

  bool get state => _state;

  set state(bool value) {
    _state = value;
    notifyListeners();
  }

  int _immediatelyAttempts;
  int _waitingSecs;

  int get immediatelyAttempts => _immediatelyAttempts;

  set immediatelyAttempts(int value) {
    _immediatelyAttempts = value;
    notifyListeners();
  }

  int get waitingSecs => _waitingSecs;

  set waitingSecs(int value) {
    _waitingSecs = value;
    notifyListeners();
  }

// TODO(nail): fill from map via code generation
/*
    _autoReconnect = (defConf['autoReconnect.state'] ?? true) as bool ;
    // ignore: avoid_as
    _secsBeforeReconnect = Duration(seconds: (defConf['autoReconnect.waitingSecs'] ?? 10) as int);
    // ignore: avoid_as
    _reconnectImmediatelyAttempts = Duration(seconds: (defConf['autoReconnect.immediatelyAttempts'] ?? 10) as int);
*/

}

String _wsurl() {
  final urls = {
    'echo': 'ws://echo.websocket.org',
    'heroku': 'ws://hidden-everglades-91369.herokuapp.com/chat',
    'local': 'ws://10.18.7.70:8080/chat',
  };
  return urls['local'];
}

class Conn with ChangeNotifier {
  Conn(this._line, this._streamController, this.autoReconnectConf) {
    _backendUrl = _wsurl();
  }

  final MemLogs _l = MemLogs('CONN');

  MemLogs get memLogs => _l;

  String _backendUrl;

  String get backendUrl => _backendUrl;

  set backendUrl(String value) {
    _backendUrl = value;
    // TODO(nail): maybe need to initialise current connection close in future?
    notifyListeners();
  }

  final Line _line;
  final StreamController<dynamic> _streamController;

  AutoReconnectConf autoReconnectConf;

  int _connectAttemptsAfterFail = 0;

  int _secsBeforeReconnect;

  /// when reconnecting started this variable eq to reconnectDuration
  /// every sec decrementing and when become 0 - reconnecting started
  /// only makes sense in LineStatus.waiting
  int get secsBeforeReconnect => _secsBeforeReconnect;

  void _changeSecsBeforeReconnect(int v) {
    _secsBeforeReconnect = v;
    notifyListeners();
  }

  Timer _secsDecreaserTimer;

  Future<WebSocket> _wsFuture;
  WebSocket _ws;

  void _initws() {
    if (_wsFuture != null) {
      throw 'Prev WS must be clossed before init ws';
    }
    _line.statusChangedTo(LineStatus.connecting);
    _wsFuture = WebSocket.connect(backendUrl)
        .timeout(Duration(seconds: 15))
        .then(_configureWsAfterConnecting);
    _wsFuture.catchError((Object e) {
      _l.e('ERROR catched on future connect: \n$e');
      _handleFailedConnection(causeEx: e);
    });
    _l.l('connect to $backendUrl inited');
  }

  FutureOr<WebSocket> _configureWsAfterConnecting(WebSocket ws) {
    _l.l('connection established. .then on connect future called');
    // ws successfully reconnected after fail so drop this counter to zero
    _connectAttemptsAfterFail = 0;
    _ws = ws;
    ws.pingInterval = Duration(seconds: 140);
    ws.handleError((Exception e) {
      // TODO(nail): what to do here? what the errors come here
      _l.e(
          'handle error occur. NOT REPORTED TO LINE! INSPECT THIS SITUATION IN CODE!!!',
          e: e);
    });
    ws.done.then((dynamic v) {
      // TODO(nail): encapsulate to func in same in other lambdas
      _l.l('ws.done called with payload', payload: v.toString());
      _line.statusChangedTo(LineStatus.disconnected, withEx: Exception(v));
    });
    //it returns subscription, maybe need to close it?
    ws.listen((dynamic json) {
      _l.l('data received', payload: json.toString());
      _streamController.add(json);
      _mimicFetching();
    }, onError: (Object e) {
      // TODO(nail): what to do here? what the errors come here
      _l.e(
          'error occur. NOT REPORTED TO LINE! INSPECT THIS SITUATION IN CODE!!!',
          payload: e.toString());
    }, onDone: () {
      _l.l('DONE ON LISTEN');
      _line.statusChangedTo(LineStatus.disconnected, withEx: Exception('no v'));
    }, cancelOnError: false);
    return ws;
  }

  void _mimicFetching() {
    _line.statusChangedTo(LineStatus.fetching);
    Future<void>.delayed(Duration(seconds: 1), () {
      _line.statusChangedTo(LineStatus.idle);
    });
  }

  void _handleFailedConnection({Object causeEx}) {
    if (autoReconnectConf.state) {
      _l.l('handle failed connection',
          payload: {
            'connectAttemptsAfterFail': _connectAttemptsAfterFail,
            'autoReconnectConf.immediatelyAttempts':
                autoReconnectConf.immediatelyAttempts,
            'autoReconnectConf.waitingSecs': autoReconnectConf.waitingSecs,
          }.toString());
      if (_connectAttemptsAfterFail++ < autoReconnectConf.immediatelyAttempts) {
        _checkAndReconnect();
      } else {
        _line.statusChangedTo(LineStatus.waiting, withEx: causeEx);
        _changeSecsBeforeReconnect(autoReconnectConf.waitingSecs);
        // for reinsurance сфдсуд ешьук ша ше учшы
        _secsDecreaserTimer?.cancel();
        _secsDecreaserTimer = Timer.periodic(Duration(seconds: 1), (t) {
          _changeSecsBeforeReconnect(secsBeforeReconnect - 1);
          // ignore: always_put_control_body_on_new_line
          if (secsBeforeReconnect <= 0) _checkAndReconnect();
        });
      }
    } else {
      _line.statusChangedTo(LineStatus.disconnected, withEx: causeEx);
    }
  }

  /// this method can be called by user tapping on reconnect now button,
  /// if LineStatus is waiting or autoReconnect disabled
  void manualConnect() {
    // delayed for UI smoothness illusion and status changed for illusion (real status will be settled soon)
    _line.statusChangedTo(LineStatus.connecting);
    Future<void>.delayed(Duration(seconds: 1), () {
      _checkAndReconnect();
    });
  }

  void _checkAndReconnect() {
    _secsDecreaserTimer?.cancel();
    _changeSecsBeforeReconnect(0);
    // TODO(nail): check network availability and change state to connecting directly if it possible (without searching and then immideatly connecting)
    if (DateTime.now().second % 2 == 0) {
      _line.statusChangedTo(LineStatus.searching);
      Future<void>.delayed(Duration(seconds: 2), () {
        _clearRefs();
        _initws();
      });
    } else {
      _clearRefs();
      _initws();
    }
  }

  Future<void> close({String reason}) {
    _line.statusChangedTo(LineStatus.disconnecting);
    return _ws.close(WebSocketStatus.normalClosure, reason).then((dynamic r) {
      // TODO(nail): what type is r?
      _line.statusChangedTo(LineStatus.disconnected);
    }).catchError((Object e) {
      // how this can happen?
      // and if happen how app must react on it?
      _l.e(
          ''
          'Attention! Exception catched on ws close.'
          'Figure out why and recheck handling code:'
          'Is it sufficient for this situation?',
          payload: e.toString());
      _line.statusChangedTo(LineStatus.disconnected, withEx: e);
    }).then((_) {
      //no matter successful close or not, clear obj references
      _clearRefs();
    });
  }

  void _clearRefs() {
    _ws = null;
    _wsFuture = null;
  }
}

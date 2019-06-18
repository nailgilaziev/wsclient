import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:wsclient/conn/model/line.dart';
import 'package:wsclient/utils/mem_logs.dart';

class AutoReconnect with ChangeNotifier {
  AutoReconnect(this._l);

  MemLogs _l;
  bool _state;

  bool get on => _state;

  set on(bool value) {
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

  int _connectAttemptsAfterFail = 0;

  int _secsBeforeReconnect;

  /// when reconnecting started this variable eq to reconnectDuration
  /// every sec decrementing and when become 0 - reconnecting started
  /// only makes sense in LineStatus.waiting
  int get secsBeforeReconnect => _secsBeforeReconnect;

  void _updateSecsBeforeReconnectTo(int v) {
    _secsBeforeReconnect = v;
    notifyListeners();
  }

  Timer _secsDecreaserTimer;

  /// returns true if it schedules
  bool schedule(VoidCallback reconnect) {
    if (_connectAttemptsAfterFail++ < immediatelyAttempts) {
      /// using delayed future to avoid cycling like while(true)
      /// connecting -> fail -> reconnecting can happen fast without delays
      /// it is protection from network card abusing
      Future.delayed(Duration(milliseconds: 400), () => reconnect());

      /// doesn't schedule reconnect for a long time with timer so return false
      return false;
    } else {
      _updateSecsBeforeReconnectTo(waitingSecs);

      /// for reinsurance cancel timer if it exist
      if (_secsDecreaserTimer != null) {
        _l.e('secsDecreaserTimer isn\'t null. THIS IS A CODE FLOW ERROR.');
        _secsDecreaserTimer.cancel();
      }
      _secsDecreaserTimer = Timer.periodic(Duration(seconds: 1), (t) {
        _updateSecsBeforeReconnectTo(secsBeforeReconnect - 1);
        if (secsBeforeReconnect <= 0) {
          _secsDecreaserTimer?.cancel();
          _updateSecsBeforeReconnectTo(0);
          reconnect();
        }
      });

      /// we schedule reconnect with timer, so return true
      return true;
    }
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
  return urls['heroku'];
}

class Conn with ChangeNotifier {
  Conn(this._line, this._streamController, this.autoReconnect, this._l) {
    _backendUrl = _wsurl();
  }

  final MemLogs _l;

  String _backendUrl;

  String get backendUrl => _backendUrl;

  set backendUrl(String value) {
    _backendUrl = value;
    notifyListeners();
  }

  final Line _line;
  final StreamController<String> _streamController;
  AutoReconnect autoReconnect;

  Future<WebSocket> _wsFuture;
  WebSocket _ws;

  // TODO(n): wrap this situation to a human readable exteption
  // TODO(n): collect situations like this
  // WebSocketException: Connection to 'http://hidden-everglades-91369.herokuapp.com:0/chat#' was not upgraded to websocket
  // because HTTP/1.1 503 Service Unavailable\r\n
  void _initws() {
    if (_wsFuture != null) {
      throw 'Prev WS must be clossed before init ws';
    }
    //TODO sequential reconnect warning (is it now not necessary? second reconnect will be with error filled)
//    if (_line.status == LineStatus.connecting) {
//      _line.err
//    }
    _line.statusChangedTo(LineStatus.connecting);
    _wsFuture = WebSocket.connect(backendUrl)
        .timeout(Duration(seconds: 15))
        .then(_configureWsAfterConnecting);
    _wsFuture.catchError((Object e) {
      _l.e('error catched on future connect: \n$e');
      _handleDownConnection(causeEx: e);
    });
    _l.l('connect to $backendUrl inited');
  }

  // TODO(n): if you find new code behaviour, append this notice below:
  // ws.done and ws.listen(onError, onDone) behaviour notice: (with conf: ping 25 and timeout 15)
  // user drop connection by switching to airplane mode, switch off wifi or network connectivity
  //  - after ~ 50 sec together ws.done[closecode null] firstly and listen onDone secondly called
  // 100% loss profile or network badly broken
  //  - after ~ 1 min called ws.done[closeCode null/state1] and plus ~ 5 minute after listen onDone called
  // server reset connection because heroku rebooted (TCP FIN,ACK packed received)
  //  - immediately called together firstly listen onDone and secondly ws.done[closeCode 1005/state3] (sequence differs from other types)
  // server normally close connection by sending close frame
  //  - immediately called together firstly listen onDone and secondly ws.done[closeCode 1005/state3] (sequence differs from other types)

  FutureOr<WebSocket> _configureWsAfterConnecting(WebSocket ws) {
    _l.l('connection established. .then on connect future called');

    /// ws successfully reconnected after fail so drop this counter to zero
    autoReconnect._connectAttemptsAfterFail = 0;
    _ws = ws;
    ws.pingInterval = Duration(seconds: 125);
    ws.handleError((Exception e) {
      /// There is no known situation that needs to be handled here.
      _l.e('ws.handleError called. INSPECT THIS SITUATION IN CODE!!!', e: e);
    });
    // ignore: avoid_annotating_with_dynamic
    ws.done.then((dynamic d) {
      // ignore: avoid_as
      final ws = d as WebSocket;

      /// closeCodes specified here https://tools.ietf.org/html/rfc6455#section-7.4
      final details =
          'closecode ${ws.closeCode} closeReason ${ws
          .closeReason} readyState ${ws.readyState}';
      _l.l('ws.done called', payload: details);
      // TODO(n): if closeCode specified from server do different things (do not call reconnect for example)
//      _line.statusChangedTo(LineStatus.disconnected); // behaviour like this in _wsFuture.catchError method
      _handleDownConnection(causeEx: details);
    });
    // TODO(n): it returns subscription, maybe need to close it?
    /// listen param can be String | List<int>, so it annotated dynamic
    // ignore: avoid_annotating_with_dynamic
    ws.listen((dynamic json) {
      _l.l('data received', payload: json.toString());
      _streamController.add(json.toString());

      /// need to send anything to this stream after connecting due to the issue https://github.com/dart-lang/sdk/issues/33379
      // TODO(n): don't forget to workaround this issue
//      ws.add('hi to server');
      _mimicFetching();
    }, onError: (Object e) {
      // TODO(nail): what to do here? what the errors come here. cancelOnError set to true and clear refs?
      _l.e(
          'listen onError called. NOTHING TO DO HERE, because [done.then] must be called.  INSPECT THIS SITUATION IN CODE!!!s',
          payload: e.toString());
      // TODO(n): this e isnt used! line.err not accessible directly
    }, onDone: () {
      _l.l(
          'listen onDone called. NOTHING TO DO HERE, because [done.then] must be called');
    }, cancelOnError: true);
    return ws;
  }

  void _mimicFetching() {
    // ignore: always_put_control_body_on_new_line
    if (_line.status != LineStatus.connecting) return;
    _line.statusChangedTo(LineStatus.fetching);
    Future<void>.delayed(Duration(milliseconds: 700), () {
      _line.statusChangedTo(LineStatus.idle);
    });
  }

  void _handleDownConnection({Object causeEx}) {
    if (_line.status == LineStatus.disconnecting) {
      /// user initiate connection closing, no need to auto reconnect and report error
      _line.statusChangedTo(LineStatus.disconnected, withEx: null);
      return;
    }
    if (!autoReconnect.on) {
      _line.statusChangedTo(LineStatus.disconnected, withEx: causeEx);
      return;
    }
    _l.l('handle failed connection',
        payload: {
          'connectAttemptsAfterFail': autoReconnect._connectAttemptsAfterFail,
          'immediatelyAttempts': autoReconnect.immediatelyAttempts,
          'waitingSecsBeforeReconnect': autoReconnect.waitingSecs,
        }.toString());
    if (autoReconnect.schedule(_checkAndReconnect))
      _line.statusChangedTo(LineStatus.waiting, withEx: causeEx);
  }

  /// this method can be called by user tapping on reconnect now button,
  /// if LineStatus is waiting or autoReconnect disabled
  void manualConnect() {
    // TODO(n): When reachibility involved maybe no need to simulate this pause
    // delayed for UI smoothness illusion and status changed for illusion (real status will be settled soon)
    _line.statusChangedTo(LineStatus.connecting);
    Future<void>.delayed(Duration(seconds: 1), () {
      _checkAndReconnect();
    });
  }

  void _checkAndReconnect() {
    // TODO(nail): check network availability and change state to connecting directly if it possible (without searching and then immediately connecting)
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

  // TODO(n): событие ручного отключения не должно вызывать авто реконнект
  // удалить оффлайн mode - вместо него disconnected
  // сделать статусы стримом, чтобы другие bloc могли слушать его
  Future<void> close({String reason}) {
    _line.statusChangedTo(LineStatus.disconnecting);
    return _ws.close(WebSocketStatus.normalClosure, reason).then((dynamic r) {
      // TODO(nail): what type is r?
      _line.statusChangedTo(LineStatus.disconnected);
      _l.l('line disconnected with r', payload: r.toString());
    }).catchError((Object e) {
      // TODO(n): how this can happen?
      // and if happen how app must react on it?
      _l.e(
          ''
          'Attention! Exception catched on ws close.'
          'Figure out why and recheck handling code:'
          'Is it sufficient for this situation?',
          payload: e.toString());
      _line.statusChangedTo(LineStatus.disconnected, withEx: e);
    }).then((_) {
      /// no matter successful close or not, clear obj references
      _clearRefs();
    });
  }

  void _clearRefs() {
    _ws = null;
    _wsFuture = null;
  }
}

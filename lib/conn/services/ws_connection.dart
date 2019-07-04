import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:wsclient/conn/services/line.dart';
import 'package:wsclient/conn/services/worker.dart';
import 'package:wsclient/utils/mem_logs.dart';

class AutoReconnect with ChangeNotifier {
  AutoReconnect(this._l);

  final MemLogs _l;
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

  int _failedConnections = 0;

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

  /// by pressing manually connect we can accelerate connecting
  /// in this case scheduled reconnect task must be stopped
  void _interruptIfSchedulled() {
    if (_secsDecreaserTimer != null) {
      _secsDecreaserTimer.cancel();
      _secsDecreaserTimer = null;
      _l.i('schedulled timer interrupted because of manual connect');
    }
  }

  /// returns true if it schedules
  bool schedule(VoidCallback reconnect, {bool forceSchedule = false}) {
    if (_failedConnections++ < immediatelyAttempts && !forceSchedule) {
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
        _l.e('secsDecreaserTimer isn\'t null. CODE FLOW ERROR, CHECK IT!');
        _secsDecreaserTimer.cancel();
      }
      _secsDecreaserTimer = Timer.periodic(Duration(seconds: 1), (t) {
        _updateSecsBeforeReconnectTo(secsBeforeReconnect - 1);
        if (secsBeforeReconnect <= 0) {
          _secsDecreaserTimer?.cancel();
          _secsDecreaserTimer = null;
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

class WsConnectionService with ChangeNotifier {
  WsConnectionService(this._line, this._worker, this._autoReconnect, this._l) {
    _backendUrl = _wsurl();
    _uploaderSubscription = _worker.uploader.stream.listen((d) {
      // TODO(n): debug mechanics, go deeper in debug
      _l.i('↑', payload: d);
      _ws.add(d);
    }, onError: (Object e) {
      _l.e('error on uploader', e: e);
    });
    _worker.uploader.stream.handleError((Object e) {
      _l.e('handle error on uploader', e: e);
    });
    _pauseUploadingData();
  }

  void _pauseUploadingData() {
    if (!_uploaderSubscription.isPaused) {
      _l.i('uploaderSubscription paused');
      _uploaderSubscription.pause();
    }
  }

  void _resumeUploadingData() {
    _l.i('uploaderSubscription resumed');
    _uploaderSubscription.resume();
  }

  StreamSubscription<String> _uploaderSubscription;

  final WsWorker _worker;

  final MemLogs _l;

  String _backendUrl;

  String get backendUrl => _backendUrl;

  set backendUrl(String value) {
    _backendUrl = value;
    notifyListeners();
  }

  final LineConnectivityStatus _line;
  AutoReconnect _autoReconnect;

  Future<WebSocket> _wsFuture;
  StreamSubscription<dynamic> _wsSubscription;
  WebSocket _ws;

  // All received data pass through this func that filled by PipeWorker
  ValueSetter<String> _dataReceiver;

  // TODO(n): wrap this situation to a human readable exteption
  // TODO(n): collect situations like this
  // WebSocketException: Connection to 'http://hidden-everglades-91369.herokuapp.com:0/chat#' was not upgraded to websocket
  // because HTTP/1.1 503 Service Unavailable\r\n
  void _connectToWs() {
    if (_wsFuture != null) {
      throw 'Prev WS must be clossed before init ws';
    }
    _wsFuture = WebSocket.connect(backendUrl)
        .timeout(Duration(seconds: 15))
        .then(_configureWsAfterConnecting);
    _wsFuture.catchError((Object e) {
      _l.e('error catched on future connect', e: e);
      _handleDownConnection(causeEx: e);
    });
    _l.i('connect to $backendUrl inited');
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
  // switch off mobile network (wifi netwerk enabled moment ago)
  // - closecode 1002 closeReason null readyState 1 (PROTOCOL ERROR)
  // reset heroku service with new version
  // - closecode 1005 closeReason  readyState 3
  // if pingpong disabled - writing to close socket fails after ~ 4 min
  FutureOr<WebSocket> _configureWsAfterConnecting(WebSocket ws) {
    _l.i('connection established. .then on connect future called');

    /// ws successfully reconnected after fail so drop this counter to zero
    _autoReconnect._failedConnections = 0;
    _ws = ws;
    ws.pingInterval = Duration(seconds: 10);
    ws.handleError((Object e) {
      /// There is no known situation that needs to be handled here.
      _l.e('ws.handleError called. INSPECT THIS SITUATION IN CODE!!!', e: e);
    });
    // ignore: avoid_annotating_with_dynamic
    ws.done.then((dynamic d) {
      // ignore: avoid_as
      final ws = d as WebSocket;

      /// closeCodes specified here https://tools.ietf.org/html/rfc6455#section-7.4
      final details = _wsDetails(ws);
      _l.i('ws.done called', payload: details);
      if (ws.closeCode == WebSocketStatus.internalServerError)
        _handleDownConnection(
            causeEx: 'InternalServerError: ${ws.closeReason}',
            forceShowError: true);
      else
        _handleDownConnection(causeEx: details);
    });
    // TODO(n): pinger sometimes failing. why?
    /// listen param can be String | List<int>, so it annotated dynamic
    // ignore: avoid_annotating_with_dynamic
    _wsSubscription = ws.listen((dynamic json) {
      _l.i('↓', payload: json.toString());
      _dataReceiver(json.toString());
    }, onError: (Object e) {
      // TODO(nail): what to do here? what the errors come here. cancelOnError set to true and clear refs?
      // cancelOnError false because we handling subscription
      // errors that happen in listen closure cause call this onError
      _l.e('listen onError called. skip. [done.then] must be called', e: e);
      // TODO(n): this e isnt used! line.err not accessible directly
      // if error occur in listen, we doesn't see this error
    }, onDone: () {
      _l.i('listen onDone called. skip. [done.then] must be called',
          payload: _wsDetails(ws));
    }, cancelOnError: false);

    /// decorated in func to further reuse
    final onIdleStart = () {
      _dataReceiver = _worker.onListening;
      _line.statusChangedTo(LineStatus.idle);
    };
    _resumeUploadingData();

    /// need to send anything to this stream after connecting due to the issue
    /// https://github.com/dart-lang/sdk/issues/33379
    _worker.onConnectStartConversation();
    if (_worker.needFetching()) {
      _worker.requestFetching();
      _dataReceiver = (d) => _worker.onFetching(d, () => onIdleStart());
      _line.statusChangedTo(LineStatus.fetching);
    } else
      onIdleStart();
    return ws;
  }

  void _handleDownConnection({Object causeEx, bool forceShowError = false}) {
    if (_line.status == LineStatus.disconnecting) {
      /// user initiate connection closing, no need to auto reconnect and report error
      _line.statusChangedTo(LineStatus.disconnected, withEx: null);
      return;
    }
    _pauseUploadingData();
    _clearRefs();
    if (!_autoReconnect.on) {
      _line.statusChangedTo(LineStatus.disconnected, withEx: causeEx);
      return;
    }
    _l.i('handle failed connection',
        payload: {
          'failedConnections': _autoReconnect._failedConnections,
          'immediatelyAttempts': _autoReconnect.immediatelyAttempts,
          'waitingSecsBeforeReconnect': _autoReconnect.waitingSecs,
        }.toString());

    if (_autoReconnect.schedule(_checkAndReconnect,
        forceSchedule: forceShowError)) {
      /// autoReconnect scheduled to reconnect sooner after pause
      _line.statusChangedTo(LineStatus.waiting, withEx: causeEx);
    } else {
      /// autoReconnect will be executed almost immediately
      /// set connecting state here to preserve causeEx reason why previous connection down
      /// this causeEx preserved in _checkAndReconnect function too
      _line.statusChangedTo(LineStatus.connecting, withEx: causeEx);
    }
  }

  /// this method can be called by user tapping on reconnect now button,
  /// if LineStatus is waiting or autoReconnect disabled
  void manualConnect() {
    // TODO(n): When reachibility involved maybe no need to simulate this pause
    // delayed for UI smoothness illusion and status changed for illusion (real status will be settled soon)
    _worker.connectionInitiated();
    _autoReconnect._interruptIfSchedulled();
    _line.statusChangedTo(LineStatus.connecting);
    Future<void>.delayed(Duration(seconds: 1), () {
      _checkAndReconnect();
    });
  }

  void _checkAndReconnect() {
    // TODO(nail): check network availability and change state to connecting directly if it possible (without searching and then immediately connecting)
    if (DateTime
        .now()
        .second % 9 == 0) {
      _line.statusChangedTo(LineStatus.searching);
      Future<void>.delayed(Duration(seconds: 2), () {
        _reconnect();
      });
    } else {
      _reconnect();
    }
  }

  void _reconnect() {
    /// if previous state is connecting, we preserve causeEx object and
    /// didn't override it by this check when sequential reconnect happen
    /// why: if first connecting was unsuccessful, _handleDownConnection will fill causeEx object and
    /// set state to connecting if reconnect will be scheduled immediately
    /// second connecting will have causeEx object and user can see, that problem exist
    if (_line.status != LineStatus.connecting) {
      _line.statusChangedTo(LineStatus.connecting);
    }
    _clearRefs();
    _connectToWs();
  }

  // TODO(n): сделать статусы стримом, чтобы другие bloc могли слушать его (а есть ли потребность?)

  Future<void> manualClose({String reason}) async {
    _line.statusChangedTo(LineStatus.disconnecting);

    /// only when normal (manual or by server?) close happens
    _worker.disconnectInitiated();

    /// allow _worker(func above) sendData to server to avoid strange subscription pausing behaviour
    /// if subscription paused momentally after writing to stream, then data already written
    /// will be stuck in stream before next resume. This cause next strange behaviour:
    /// if you resume subscription and momentally try write the data to it by checking isPaused
    /// it will be still paused!!, because of stucked data in it. if no one stuck inside, is paused return false
    await Future<void>.delayed(Duration(milliseconds: 0));
    _pauseUploadingData();
    // ignore: avoid_annotating_with_dynamic
    return _ws.close(WebSocketStatus.normalClosure, reason).then((dynamic ws
        /*WebSocket*/) {
      _line.statusChangedTo(LineStatus.disconnected);
      _l.i('ws closed successfully');
    }).catchError((Object e) {
      // TODO(n): how this can happen?
      // and if happen how app must react on it?
      _l.e(
          ''
          'Attention! Exception catched on ws close.'
          'Figure out why and recheck handling code:'
          'Is it sufficient for this situation?',
          e: e);
      _line.statusChangedTo(LineStatus.disconnected, withEx: e);
    }).then((_) {
      /// only when normal (manual or by server?) close happens
      _worker.onDisconnected();

      /// no matter successful close or not, clear obj references
      _clearRefs();
    });
  }

  void _clearRefs() {
    // ignore: avoid_annotating_with_dynamic
    _wsSubscription?.cancel()?.then((dynamic paramIsNull) {
      _l.i('wsSubscription closed successfully');
    })?.catchError((Object e) {
      _l.e('error catched on wsSubscription close', e: e);
    });
    _wsSubscription = null;
    _ws = null;
    _wsFuture = null;
  }

  String _wsDetails(WebSocket ws) =>
      'readyState:${ws.readyState} closeCode:${ws.closeCode} closeReason:${ws
          .closeReason}';
}

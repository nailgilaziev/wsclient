import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:wsclient/conn/services/worker.dart';
import 'package:wsclient/matrix_tester/models/model.dart';
import 'package:wsclient/utils/mem_logs.dart';

class MatrixBloc extends WsWorker with ChangeNotifier {
  MatrixBloc(this.l) {
    _broadcastStream = _numbersSc.stream.asBroadcastStream();
  }

  var started = false;

  String myname;

  bool _masterMode = false;

  bool get masterMode => _masterMode;

  set masterMode(bool value) {
    _masterMode = value;
    notifyListeners();
  }

  Matrix x;

  final MemLogs l;

  final userId = DateTime.now().millisecondsSinceEpoch;

  StreamController<PixelDataWrapper> _numbersSc = StreamController();
  Stream<PixelDataWrapper> _broadcastStream;

  Stream<Matrix> get stream {
    return _broadcastStream.map((w) {
      if (w != null) {
        x.lastReceived = w.n;
        final i = w.n % 400;
        x.blocks[i].pixels[w.pd.id] = w.pd;
      }
      return x;
    });
  }

  int counter = 0;

  Timer t;

  final queue = <int>[];

  @override
  void connectionInitiated() {
    x = Matrix();
    counter = 0;
    _numbersSc.add(null);
    myname = null;
  }

  @override
  void onConnectStartConversation() {
    started = true;
    notifyListeners();

    var hi = masterMode ? 'm${myname ?? ''}' : 's';

    l.i('trySend $hi writed?${trySend('$hi')}');
  }

  @override
  bool needFetching() {
    return !masterMode;
  }

  @override
  void requestFetching() {
    final data = 'f${x.lastReceived}';
    l.i('trySend $data writed?${trySend(data)}');
  }

  @override
  void onFetching(String data, VoidCallback endedCallback) {
    if (data == 'fend') {
      endedCallback();
      return;
    }
    parse(data, true);
  }

  void parse(String data, bool isFetching) {
    final arr = data.split('-');
    int n = int.parse(arr[0]);
    int id = int.parse(arr[1]);
    _numbersSc.add(PixelDataWrapper(n, id, isFetching));
  }

  @override
  void onListening(String data) {
    if (masterMode) {
      int n = int.parse(data);
      myname = n.toString();
      notifyListeners();
      if (t == null) runTimer();
    } else
      parse(data, false);
  }

  void runTimer() {
    t = Timer.periodic(Duration(milliseconds: 1000), (t) {
      queue.add(counter);
      counter++;
      for (int i = 0; i < queue.length; i++) {
        final nu = queue[i];
        if (!trySend(nu.toString()))
          break;
        else
          queue[i] = -1;
        parse('$nu-$myname', false);
      }
      queue.removeWhere((v) => v == -1);
      if (counter == 400) t.cancel();
    });
  }

  @override
  void disconnectInitiated() {
    //l.l('trySend reset writed?${trySend('reset')}');
  }

  @override
  void onDisconnected() {
    started = false;
    t?.cancel();
    t = null;
    notifyListeners();
  }
}

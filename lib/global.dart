import 'dart:async';

import 'package:wsclient/conn/model/conn.dart';
import 'package:wsclient/conn/model/line.dart';

class Rep {
  Rep() {
    var arc = AutoReconnectConf()
      ..state = true
      ..immediatelyAttempts = 1
      ..waitingSecs = 6;
    _conn = Conn(line, sc, arc);
  }

  final Line line = Line(initialModeOffline: false);
  Conn _conn;

  Conn get conn => _conn;

  final sc = StreamController<dynamic>();
}

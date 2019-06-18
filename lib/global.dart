import 'dart:async';

import 'package:wsclient/conn/model/conn.dart';
import 'package:wsclient/conn/model/line.dart';
import 'package:wsclient/utils/mem_logs.dart';

class Rep {
  Rep() {
    var arc = AutoReconnect(memLogs)
      ..on = true
      ..immediatelyAttempts = 1
      ..waitingSecs = 6;
    _conn = Conn(line, sc, arc, memLogs);
  }

  final MemLogs memLogs = MemLogs('CONN');
  final Line line = Line();
  final sc = StreamController<String>();

  Conn _conn;

  Conn get conn => _conn;

}

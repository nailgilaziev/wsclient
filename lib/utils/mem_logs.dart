import 'dart:collection';

import 'package:intl/intl.dart';

class MemLogs {
  MemLogs(this._tag);

  final String _tag;

  // TODO(nail): different queues for l / e / i msgs if one of them overflows fast
  final DoubleLinkedQueue<String> _lru = DoubleLinkedQueue();

  DateFormat f = DateFormat('HH:mm:ss.S');

  String _s(String msg, Object e, String p) {
    final n = DateTime.now();
    return '${f.format(n)} - $msg ${e == null ? '' : '\n$e'} ${p == null
        ? ''
        : '${p.length > 40 ? '\n$p' : p}'}';
  }

  void _save(String s) {
    if (_lru.length > 1000) _lru.removeFirst();
    _lru.add(s);
    print(s);
  }

  void i(String msg, {Object e, String payload}) {
    _save('[LOG/$_tag] ${_s(msg, e, payload)}');
  }

  void e(String msg, {Object e, String payload}) {
    _save('[ERR/$_tag] ${_s(msg, e, payload)}');
  }

  // TODO(n): do via streams
  String report() {
    return _lru
        .toList()
        .reversed
        .join('\n\n');
  }
}

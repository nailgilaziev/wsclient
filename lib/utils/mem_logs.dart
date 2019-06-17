class MemLogs {
  MemLogs(this._tag);

  final String _tag;
  final List<String> _lru = [];

  String _s(String msg, Exception e, String p) {
    return '${DateTime.now()} - $msg ${e == null ? '' : '\n$e'} ${p == null ? '' : '\n$p'}';
  }

  void _save(String s) {
    if (_lru.length > 100) _lru.removeRange(50, 100);
    _lru.add(s);
    print(s);
  }

  void l(String msg, {Exception e, String payload}) {
    _save('[LOG/$_tag] ${_s(msg, e, payload)}');
  }

  void e(String msg, {Exception e, String payload}) {
    _save('[ERR/$_tag] ${_s(msg, e, payload)}');
  }

  String report() {
    return _lru.join('\n\n');
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';

///Implement in BLoC's that need to utilize ws Conn
abstract class WsWorker {
  WsWorker();

  // TODO(n): make private after !part of! refactoring
  /// between reconnects streamSubscription may pause and resumes
  final uploader = StreamController<String>();

  bool trySend(String data) {
    // TODO(n): logging here?
    if (uploader.isPaused) return false;
    uploader.add(data);
    return true;
  }

  /// prepare your bloc - connection initiated by hand or because startup
  void connectionInitiated();

  /// need to send anything to this stream after connecting due to the issue https://github.com/dart-lang/sdk/issues/33379
  /// if need wait function ending return future
  void onConnectStartConversation();

  bool needFetching();

  void requestFetching();

  // TODO(n): bad method separation - server can send listening data and it will be processed like fetching. But is it a bad?
  void onFetching(String data, VoidCallback endedCallback);

  void onListening(String data);

  /// finish bloc work - connection close requested by user
  void disconnectInitiated();

  void onDisconnected();
}

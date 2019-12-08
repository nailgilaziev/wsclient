import 'package:app_logs/app_logs.dart';
import 'package:conn_core/conn_core.dart';
import 'package:flutter/material.dart';
import 'package:wsclient/matrix_tester/mngrs/matrix_bloc.dart';

class Rep {
  Rep(TargetPlatform platform) {
    matrixBloc = MatrixBloc(connLogger);
    setLogger(connLogger);
    autoReconnect = AutoReconnect()
      ..on = true
      ..immediatelyAttempts = 1
      ..waitingSecs = 20;
    conn = WsConnectionService(line, matrixBloc, autoReconnect, platform);
  }

  AutoReconnect autoReconnect;

  // TODO(n): create MemLogsFabric
  final AppLogger connLogger = AppLogger.forTag('CONN');

  final LineConnectivityStatus line = LineConnectivityStatus();

  WsConnectionService conn;

  MatrixBloc matrixBloc;
}

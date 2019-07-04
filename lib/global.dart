import 'package:wsclient/conn/services/line.dart';
import 'package:wsclient/conn/services/ws_connection.dart';
import 'package:wsclient/matrix_tester/mngrs/matrix_bloc.dart';
import 'package:wsclient/utils/mem_logs.dart';

class Rep {
  Rep() {
    matrixBloc = MatrixBloc(memLogs);
    autoReconnect = AutoReconnect(memLogs)
      ..on = true
      ..immediatelyAttempts = 1
      ..waitingSecs = 20;
    conn = WsConnectionService(line, matrixBloc, autoReconnect, memLogs);
  }

  AutoReconnect autoReconnect;

  // TODO(n): create MemLogsFabric
  final MemLogs memLogs = MemLogs('CONN');

  final LineConnectivityStatus line = LineConnectivityStatus();

  WsConnectionService conn;

  MatrixBloc matrixBloc;
}

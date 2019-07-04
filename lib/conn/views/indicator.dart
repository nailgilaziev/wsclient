import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wsclient/conn/services/line.dart';
import 'package:wsclient/conn/services/ws_connection.dart';
import 'package:wsclient/utils/texts.dart';

class ConnIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<LineConnectivityStatus>(
        builder: (BuildContext context, LineConnectivityStatus line,
            Widget child) {

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          if (line.err != null)
            IconButton(
                icon: const Icon(Icons.warning),
                onPressed: () {
                  _showMsg(context, line.err.toString());
                }),
          if (line.status == LineStatus.searching)
            IconButton(
                icon: const Icon(
                    Icons.signal_cellular_connected_no_internet_4_bar),
                onPressed: () {
                  // TODO(n): reachibility must SHOW SYSTEM STATE on/off wifi / net /airplane mode / restrictions
                  _showMsg(
                    context,
                    '''нет wifi или network соединения. 
Обеспечьте что-нибудь одно.
Выключите airplane mode.
Включите и подключитесь к wifi
Разрешите мобильное соединение и уберите ограничения его использования''',
                  );
                }),
          line.status == LineStatus.waiting
              ? _ReconnectWaitingIndicator()
              : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(
              line.status.toString().substring(11),
              style: TextStyle(fontSize: 18),
            ),
            if (line.status == LineStatus.disconnected)
              Text(
                'Last sync date: ${line.lastSync}',
                style: TextStyle(fontSize: 14),
              ),
          ]),
          if (line.status != LineStatus.idle)
            [LineStatus.waiting, LineStatus.disconnected].contains(line.status)
                ? Consumer<WsConnectionService>(
              builder: (BuildContext context, WsConnectionService conn,
                  Widget child) =>
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => conn.manualConnect(),
                  ),
            )
                : Container(
              width: 32,
              height: 16,
              padding: const EdgeInsets.only(left: 16),
              child: const CircularProgressIndicator(
                strokeWidth: 1.6,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
        ],
      );
    });
  }

  void _showMsg(BuildContext context, String msg) =>
      showDialog<String>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              content: SingleChildScrollView(
                child: Text(
                  msg,
                  textScaleFactor: 0.8,
                ),
              ),
            );
          });
}

class _ReconnectWaitingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AutoReconnect>(builder:
        (BuildContext context, AutoReconnect autoReconnect, Widget child) {
      final t = Provider.of<Texts>(context);
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            t.connection['problemsTitle'],
            style: TextStyle(fontSize: 16),
          ),
          Text(
            '${t.connection[LineStatus.waiting.toString()]} ${autoReconnect
                .secsBeforeReconnect}',
            style: TextStyle(fontSize: 12),
          ),
        ],
      );
    });
  }
}

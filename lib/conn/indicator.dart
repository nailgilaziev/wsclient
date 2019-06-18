import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wsclient/conn/model/conn.dart';
import 'package:wsclient/conn/model/line.dart';
import 'package:wsclient/texts.dart';

class ConnIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<Line>(
        builder: (BuildContext context, Line line, Widget child) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          if (line.status != LineStatus.idle)
            [LineStatus.waiting, LineStatus.disconnected].contains(line.status)
                ? Consumer<Conn>(
                    builder: (BuildContext context, Conn conn, Widget child) =>
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () => conn.manualConnect(),
                        ),
                  )
                : Container(
                    width: 24,
                    height: 16,
                    padding: const EdgeInsets.only(right: 8),
                    child: const CircularProgressIndicator(
                      strokeWidth: 1.6,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
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
      return InkWell(
        child: Column(
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
        ),
        onTap: () => Provider.of<Conn>(context).manualConnect(),
      );
    });
  }
}

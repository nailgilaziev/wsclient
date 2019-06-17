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
      if (line.modeOffline)
        return Column(children: [
          Text(
            'Offline mode',
            style: TextStyle(fontSize: 20),
          ),
          Text(
            'Last sync date: ${line.lastSync}',
            style: TextStyle(fontSize: 14),
          ),
        ]);
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
              : Text(
                  line.status.toString().substring(11),
                  style: TextStyle(fontSize: 20),
                ),
          if (line.err != null)
            IconButton(icon: const Icon(Icons.warning), onPressed: () {}),
          if (line.status == LineStatus.searching)
            IconButton(
                icon: const Icon(
                    Icons.signal_cellular_connected_no_internet_4_bar),
                onPressed: () {}),
        ],
      );
    });
  }
}

class _ReconnectWaitingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<Conn>(
        builder: (BuildContext context, Conn conn, Widget child) {
      var t = Provider.of<Texts>(context);
      return InkWell(
        child: Column(
          children: <Widget>[
            Text(
              t.connection['problemsTitle'],
              style: TextStyle(fontSize: 20),
            ),
            Text(
              '${t.connection[LineStatus.waiting.toString()]} ${conn.secsBeforeReconnect}',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        onTap: () => conn.manualConnect(),
      );
    });
  }
}

import 'package:conn_core/conn_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wsclient/utils/texts.dart';
import 'package:wsclient/utils/time.dart';

class ConnIndicator extends StatelessWidget {
  const ConnIndicator({this.idleTitle});

  final String idleTitle;

  @override
  Widget build(BuildContext context) {
    // TODO(n): move to generic place
    String lineStatusToString(LineStatus ls) {
      switch (ls) {
        case LineStatus.connecting:
          return txt.lineStatus.connecting;
        case LineStatus.disconnected:
          return txt.lineStatus.disconnected;
        case LineStatus.waiting:
          return txt.lineStatus.problemsTitle;
        case LineStatus.searching:
          return txt.lineStatus.searchingTitle;
        case LineStatus.fetching:
          return txt.lineStatus.fetching;
        case LineStatus.idle:
          return txt.lineStatus.idle;
        case LineStatus.disconnecting:
          return txt.lineStatus.disconnecting;
      }
      return 'no way';
    }

    String mapLineStatus(LineStatus ls) {
      if (ls == LineStatus.idle && idleTitle != null) return idleTitle;
      return lineStatusToString(ls);
    }

    return Consumer<LineConnectivityStatus>(builder:
        (BuildContext context, LineConnectivityStatus line, Widget child) {
      Widget central() {
        if (line.status == LineStatus.waiting)
          return const _ReconnectWaitingLabel();
        if (line.status == LineStatus.searching)
          return _SearchingLabel();
        return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(
            mapLineStatus(line.status),
            style: const TextStyle(fontSize: 18),
          ),
          if (line.status != LineStatus.idle) LastSyncTextLabel()
        ]);
      }

      final iconPlaceholder = Container(
        width: 48,
        height: 48,
      );

      Widget leftWidget() {
        if (line.err != null)
          return IconButton(
              icon: const Icon(Icons.warning),
              onPressed: () {
                _showMsg(context, line.err.toString());
              });
        if (line.status == LineStatus.searching)
          return IconButton(
              icon:
              const Icon(Icons.signal_cellular_connected_no_internet_4_bar),
              onPressed: () {
                // TODO(n): reachibility must SHOW SYSTEM STATE on/off wifi / net /airplane mode / restrictions
                _showMsg(
                  context,
                  txt.lineStatus.searchingExplanation,
                );
              });
        return iconPlaceholder;
      }

      Widget rightWidget() {
        if ([LineStatus.waiting, LineStatus.disconnected].contains(line.status))
          return IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final conn = Provider.of<WsConnectionService>(context);
              conn.manualConnect();
            },
          );
        else
          return Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(15),
            child: const CircularProgressIndicator(
              strokeWidth: 1.8,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          );
      }

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          if (line.status != LineStatus.idle) leftWidget(),
          central(),
          if (line.status != LineStatus.idle) rightWidget()
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

class _SearchingLabel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ThreeRowWidget(
      title: txt.lineStatus.searchingTitle,
      subtitle: txt.lineStatus.searchingSubtitle,
      lastSyncWidget: LastSyncTextLabel(),
    );
  }
}

class _ReconnectWaitingLabel extends StatelessWidget {
  const _ReconnectWaitingLabel({Key key, this.line}) : super(key: key);
  final LineConnectivityStatus line;

  @override
  Widget build(BuildContext context) {
    return Consumer<AutoReconnect>(
      builder: (context, ar, child) {
        final title = ar.waitingForMaintenance
            ? txt.lineStatus.maintenanceTitle
            : txt.lineStatus.problemsTitle;
        final time = beautyTime(ar.secsBeforeReconnect);
        final subtitle = '${txt.lineStatus.secsBeforeReconnect} $time';

        return ThreeRowWidget(
            title: title, subtitle: subtitle, lastSyncWidget: child);
      },
      child: LastSyncTextLabel(),
    );
  }
}

class ThreeRowWidget extends StatelessWidget {
  const ThreeRowWidget({Key key,
    @required this.title,
    @required this.subtitle,
    this.lastSyncWidget})
      : super(key: key);
  final String title;
  final String subtitle;
  final Widget lastSyncWidget;

  @override
  Widget build(BuildContext context) =>
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 1),
          lastSyncWidget,
          const SizedBox(height: 3),
        ],
      );
}

class LastSyncTextLabel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<LineConnectivityStatus>(builder: (context, line, _) {
      if (line.lastSync == null) return Container();
      final s = formattedDateTime(line.lastSync, adaptiveToNow: true);
      return Text(
        '${txt.lineStatus.lastSyncPrefix}: $s',
        style: const TextStyle(fontSize: 9),
      );
    });
  }
}

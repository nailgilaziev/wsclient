import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wsclient/conn/services/line.dart';
import 'package:wsclient/conn/services/ws_connection.dart';
import 'package:wsclient/utils/labeled_checkbox.dart';
import 'package:wsclient/utils/mem_logs.dart';

class ConnManagePanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<LineConnectivityStatus>(
      builder: (BuildContext context, LineConnectivityStatus line,
          Widget child) {
        return Consumer<WsConnectionService>(
          builder: (context, conn, _) {
            final connectCallback = !line.manualConnectAvailable
                ? null
                : () => conn.manualConnect();
            final closeCallback =
            !line.manualCloseAvailable ? null : () => conn.manualClose();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextFormField(
                  initialValue: conn.backendUrl,
                  decoration: InputDecoration(
                      labelText: 'ws/wss url',
                      helperText: 'changes will be applied after reconnect',
                      hintText: 'wss://host.domain/events'),
                  onFieldSubmitted: (t) => conn.backendUrl = t,
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _AutoReconnectParamsPanel(),
                    ),
                    IntrinsicWidth(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          RaisedButton(
                            child: const Text('connect'),
                            onPressed: connectCallback,
                          ),
                          const SizedBox(width: 8),
                          RaisedButton(
                              child: const Text('disconnect'),
                              onPressed: closeCallback),
                          const SizedBox(width: 8),
                          RaisedButton(
                              child: const Text('logs'),
                              onPressed: () => _showConnectionLogs(context)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showConnectionLogs(BuildContext rootContext) =>
      showDialog<String>(
        context: rootContext,
        builder: (BuildContext context) {
          final memLogs = Provider.of<MemLogs>(rootContext);
          return AlertDialog(
            content: SingleChildScrollView(
              child: Text(
                memLogs.report(),
                textScaleFactor: 0.8,
              ),
            ),
          );
        });
}

class _AutoReconnectParamsPanel extends StatefulWidget {
  @override
  __AutoReconnectParamsPanelState createState() =>
      __AutoReconnectParamsPanelState();
}

class __AutoReconnectParamsPanelState extends State<_AutoReconnectParamsPanel> {
  final controllerAttemptsCount = TextEditingController();
  final controllerSecs = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Consumer<AutoReconnect>(
      builder: (BuildContext context, AutoReconnect conf, Widget child) {
        controllerAttemptsCount.text = conf.immediatelyAttempts.toString();
        controllerSecs.text = conf.waitingSecs.toString();
        return Column(
          children: <Widget>[
            LabeledCheckbox(
              value: conf.on,
              onChanged: (bool v) => conf.on = v,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const SizedBox(width: 8),
                Container(
                  width: 32,
                  child: TextField(
                    textAlign: TextAlign.center,
                    controller: controllerAttemptsCount,
                    onChanged: (t) => conf.immediatelyAttempts = int.parse(t),
                    keyboardType: const TextInputType.numberWithOptions(),
                  ),
                ),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text('reconnect immediately attempts count'),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const SizedBox(width: 8),
                Container(
                  width: 32,
                  child: TextField(
                    textAlign: TextAlign.center,
                    controller: controllerSecs,
                    onChanged: (t) => conf.waitingSecs = int.parse(t),
                    keyboardType: const TextInputType.numberWithOptions(),
                  ),
                ),
                const SizedBox(width: 8),
                const Flexible(child: Text('waiting secs before reconnect')),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    controllerSecs.dispose();
    controllerAttemptsCount.dispose();
    super.dispose();
  }
}

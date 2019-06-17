import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wsclient/conn/model/conn.dart';
import 'package:wsclient/conn/model/line.dart';
import 'package:wsclient/utils/labeled_checkbox.dart';

class ConnManagePanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<Line>(
      builder: (BuildContext context, Line line, Widget child) {
        return Consumer<Conn>(
          builder: (context, conn, _) {
            final connectCallback = !line.manualConnectAvailable
                ? null
                : () => conn.manualConnect();
            final closeCallback =
                !line.manualCloseAvailable ? null : () => conn.close();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Text('Connection Mode: '),
                    const SizedBox(width: 16),
                    const Text('offline'),
                    Switch(
                      value: !line.modeOffline,
                      onChanged: (bool v) => line.modeOffline = !v,
                    ),
                    const Text('online'),
                  ],
                ),
                TextFormField(
                  enabled: !line.modeOffline,
                  initialValue: conn.backendUrl,
                  decoration: InputDecoration(
                      labelText: 'ws/wss url',
                      helperText: 'changes will be applied after reconnect',
                      hintText: 'wss://host.domain/events'),
                  onFieldSubmitted: (t) => conn.backendUrl = t,
                ),
                Row(
                  children: <Widget>[
                    Flexible(
                      flex: 5,
                      child: Consumer<AutoReconnectConf>(
                        builder: (BuildContext context, AutoReconnectConf conf,
                            Widget child) {
                          final autoReconnectCallback = line.modeOffline
                              ? null
                              : (bool v) => conf.state = v;
                          return Column(
                            children: <Widget>[
                              LabeledCheckbox(
                                value: conf.state,
                                onChanged: autoReconnectCallback,
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  const SizedBox(width: 16),
                                  Flexible(
                                    flex: 1,
                                    child: TextFormField(
                                      enabled: !line.modeOffline,
                                      initialValue:
                                          conf.immediatelyAttempts.toString(),
                                      decoration:
                                          InputDecoration(hintText: 'ex: 1'),
                                      onFieldSubmitted: (t) => conf
                                          .immediatelyAttempts = int.parse(t),
                                      keyboardType: const TextInputType
                                          .numberWithOptions(),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Flexible(
                                    flex: 6,
                                    child: Text(
                                        'reconnect immediately attempts count'),
                                  ),
                                ],
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  const SizedBox(width: 16),
                                  Flexible(
                                    flex: 1,
                                    child: TextFormField(
                                      enabled: !line.modeOffline,
                                      initialValue: conf.waitingSecs.toString(),
                                      decoration:
                                          InputDecoration(hintText: 'ex: 15'),
                                      onFieldSubmitted: (t) =>
                                          conf.waitingSecs = int.parse(t),
                                      keyboardType: const TextInputType
                                          .numberWithOptions(),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Flexible(
                                      flex: 6,
                                      child: Text(
                                          'waiting secs before reconnect')),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    Flexible(
                      flex: 3,
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

  void _showConnectionLogs(BuildContext rootContext) {
    showDialog<String>(
        context: rootContext,
        builder: (BuildContext context) {
          final conn = Provider.of<Conn>(rootContext);
          return AlertDialog(
            content: SingleChildScrollView(
              child: Text(
                conn.memLogs.report(),
                textScaleFactor: 0.8,
              ),
            ),
          );
        });
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wsclient/chat/page.dart';
import 'package:wsclient/global.dart';
import 'package:wsclient/texts.dart';
import 'package:wsclient/utils/mem_logs.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WSCLIENT',
      home: Provider<Rep>(
        builder: (_) => Rep(),
        child: Consumer<Rep>(
          builder: (context, rep, child) {
            return MultiProvider(
              providers: [
                ChangeNotifierProvider.value(value: rep.line),
                ChangeNotifierProvider.value(value: rep.conn),
                ChangeNotifierProvider.value(value: rep.conn.autoReconnect),
                Provider<MemLogs>.value(value: rep.memLogs),
                StreamProvider<String>.value(value: rep.sc.stream),
                Provider<Texts>(builder: (BuildContext context) => Texts()),
              ],
              child: MyHomePage(),
            );
          },
        ),
      ),
    );
  }
}

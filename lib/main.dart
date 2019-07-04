import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wsclient/global.dart';
import 'package:wsclient/matrix_tester/models/model.dart';
import 'package:wsclient/matrix_tester/views/page.dart';
import 'package:wsclient/utils/mem_logs.dart';
import 'package:wsclient/utils/texts.dart';

void main() {
  print('main called');
  runApp(MyApp());
}



class MyApp extends StatelessWidget {
  static const ansiEsc = '\x1B[';
  static const ansiDefault = "${ansiEsc}0m";


  @override
  Widget build(BuildContext context) {
    print('MyAPP build called');
    return MaterialApp(
      title: 'WSCLIENT',
      home: Provider<Rep>(
        builder: (_) {
          print('REP is BUILDED!!!!!');
          return Rep();
        },
        child: Consumer<Rep>(
          builder: (context, rep, child) {
            print('Consumer<Rep> builder called with rep = $rep');
            return MultiProvider(
              providers: [
                ChangeNotifierProvider.value(value: rep.line),
                ChangeNotifierProvider.value(value: rep.conn),
                ChangeNotifierProvider.value(value: rep.autoReconnect),
                ChangeNotifierProvider.value(value: rep.matrixBloc),
                Provider<MemLogs>.value(value: rep.memLogs),
                Provider<Rep>.value(value: rep),
                StreamProvider<Matrix>.value(
                    updateShouldNotify: (previous, current) => true,
                    value: rep.matrixBloc.stream),
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

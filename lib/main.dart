import 'package:app_logs/app_logs.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wsclient/global.dart';
import 'package:wsclient/matrix_tester/models/model.dart';
import 'package:wsclient/matrix_tester/views/page.dart';

void main() {
  print('main called');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
//    print('MyAPP build called');
    return MaterialApp(
      title: 'WSCLIENT',
      home: Provider<Rep>(
        builder: (_) {
//          print('REP is BUILDED!!!!!');
          return Rep(Theme
              .of(context)
              .platform);
        },
        child: Consumer<Rep>(
          builder: (context, rep, child) {
//            print('Consumer<Rep> builder called with rep = $rep');
            return MultiProvider(
              providers: [
                ChangeNotifierProvider.value(value: rep.line),
                ChangeNotifierProvider.value(value: rep.conn),
                ChangeNotifierProvider.value(value: rep.autoReconnect),
                ChangeNotifierProvider.value(value: rep.matrixBloc),
                Provider<Logger>.value(value: rep.connLogger),
                Provider<Rep>.value(value: rep),
                StreamProvider<Matrix>.value(
                    updateShouldNotify: (previous, current) => true,
                    value: rep.matrixBloc.stream),
              ],
              child: MyHomePage(),
            );
          },
        ),
      ),
    );
  }
}

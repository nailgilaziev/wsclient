import 'package:conn_views/indicator.dart';
import 'package:conn_views/manage_panel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wsclient/matrix_tester/mngrs/matrix_bloc.dart';
import 'package:wsclient/matrix_tester/views/matrix.dart';

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const ConnIndicator(idleTitle: 'Есть связь'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              color: Colors.lightBlueAccent[100],
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: ConnManagePanel(),
              ),
            ),
            Consumer<MatrixBloc>(
              builder: (BuildContext context, MatrixBloc bloc, Widget child) {
                return Row(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('My ID:', textScaleFactor: 2),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(bloc.myname ?? '-', textScaleFactor: 2),
                        ),
                      ],
                    ),
                    Flexible(
                      child: CheckboxListTile(
                          onChanged: bloc.started
                              ? null
                              : (bool v) => bloc.masterMode = v,
                          value: bloc.masterMode,
                          title: const Text('SENDER MODE')),
                    ),
                  ],
                );
              },
            ),
            IntrinsicWidth(
              child: Container(
                  color: Colors.black12,
                  padding: const EdgeInsets.all(1),
                  child: MatrixView()),
            )
          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';


void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final title = 'WebSocket Demo';
    return new MaterialApp(
      title: title,
      home: new MyHomePage(
        title: title,
//        wsurl: 'ws://echo.websocket.org',
//        wsurl: 'wss://afternoon-sierra-23732.herokuapp.com/events',
        wsurl: 'ws://hidden-everglades-91369.herokuapp.com/chat',
//        wsurl: 'ws://10.18.8.73:8080/events',
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;
  final String wsurl;

  MyHomePage({Key key, @required this.title, @required this.wsurl})
      : super(key: key);

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController _controller = new TextEditingController();
  Future<WebSocket> wsFuture;
  WebSocket ws;
  Exception ex;
  String transferredData;



  initws() {
    transferredData = null;
    ex = null;
    ws = null;
    wsFuture = WebSocket
        .connect(widget.wsurl)
        .timeout(new Duration(seconds: 15))
        .then((v) {
      setState(() {
        ws = v;
        ws.pingInterval = new Duration(seconds: 240);
        ws.handleError((e, s) {
          timeprint("ERROR HANDLED $e");
        });
        ws.done.then((v) {
          setState(() {
            ex = new Exception("Connection is done with v=$v");
            timeprint("DONE");
          });
        });
        ws.listen((d) {
          setState(() {
            transferredData = d;
            timeprint("DATA RECEIVED");
          });
        }, onError: (e, stack) {
          setState(() {
            ex = e;
            timeprint("ERROR ON LISTEN");
          });
        }, onDone: () {
          setState(() {
            ex = new Exception("Connection is done with v=$v");
            timeprint("DONE ON LISTEN");
          });
        });
      });
    }, onError: (e, stack) {
      timeprint("onerror $e");
      setState(() {
        ex = e;
      });
    });
    timeprint("inited");
  }

  timeprint(msg){
    print(new DateTime.now().toString() + "    " +  msg);
  }

  Widget getUI() {
    if (ex != null) {
      return new Text("err " + ex.toString(),
          style: new TextStyle(color: Colors.red));
    }
    if (ws == null) {
      return new CircularProgressIndicator();
    }
    if (transferredData != null) {
      return new Text(transferredData);
    }
  }

  @override
  void initState() {
    initws();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      body: new Padding(
        padding: const EdgeInsets.all(20.0),
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            new Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: getUI()),
            new Form(
              child: new TextFormField(
                controller: _controller,
                decoration: new InputDecoration(labelText: 'Send a message'),
              ),
            ),
            new Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: new Row(
                children: <Widget>[
                  new RaisedButton(
                    onPressed: () {
                      setState(() {
                        initws();
                      });
                    },
                    child: new Text("Reconnect"),
                  ),
                  new SizedBox(
                    width: 8.0,
                  ),
                  new RaisedButton(
                    onPressed: () {
                      if (ws == null) {
                        print("ws is not inited yet");
                        return;
                      }
                      print("ready state ${ws.readyState}");
                      print("close code ${ws.closeCode}");
                      print("close reason ${ws.closeReason}");
                      print("extensions ${ws.extensions}");
                      print("protocol ${ws.protocol}");
                    },
                    child: new Text("check state"),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: _sendMessage,
        tooltip: 'Send message',
        child: new Icon(Icons.send),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void _sendMessage() {
    if (ws != null) {
      if (_controller.text.isNotEmpty) {
        ws.add(_controller.text);
        _controller.text = "";
        timeprint("Sended");
      }
    } else {
      print("WS IS NOT FILLED!!!!");
    }
  }

  @override
  void dispose() {
//    wsChannel.sink.close();
    super.dispose();
  }
}
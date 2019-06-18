import 'package:flutter/material.dart';
import 'package:wsclient/conn/indicator.dart';
import 'package:wsclient/conn/manage_panel.dart';

class MyHomePage extends StatelessWidget {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ConnIndicator(),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              color: Colors.lightBlueAccent[100],
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: ConnManagePanel(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Form(
                child: TextFormField(
                  controller: _controller,
                  decoration: InputDecoration(labelText: 'Send a message'),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _sendMessage,
        tooltip: 'Send message',
        child: const Icon(Icons.send),
      ),
    );
  }

  void _sendMessage() {
//    if (ws != null) {
//      if (_controller.text.isNotEmpty) {
//        ws.add(_controller.text);
//        _controller.text = "";
//        timeprint("Sended");
//      }
//    } else {
//      print("WS IS NOT FILLED!!!!");
//    }
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wsclient/matrix_tester/models/model.dart';

class MatrixView extends StatelessWidget {
  Color colorFor(PixelData p) {
    if (p == null) return Colors.white;
    final t = p.fetched ? 300 : 600;
    switch (p.id) {
      case 0:
        return Colors.blue[t];
      case 1:
        return Colors.deepPurple[t];
      case 2:
        return Colors.orange[t];
      case 3:
        return Colors.green[t];
    }
    return Colors.red[t];
  }

  Widget matrix(Matrix x) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Row>.generate(
        x.size,
        (n) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List<Widget>.generate(x.size, (m) {
              final i = n * x.size + m;
              final b = x.blocks[i];
              return Padding(
                padding: const EdgeInsets.all(0.6),
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          width: 8,
                          height: 8,
                          color: colorFor(b.pixels[0]),
                        ),
                        Container(
                          width: 8,
                          height: 8,
                          color: colorFor(b.pixels[1]),
                        ),
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        Container(
                          width: 8,
                          height: 8,
                          color: colorFor(b.pixels[2]),
                        ),
                        Container(
                          width: 8,
                          height: 8,
                          color: colorFor(b.pixels[3]),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    //print('CALLED WIDJET BUILDER');
    return Consumer<Matrix>(
        builder: (BuildContext context, Matrix x, Widget child) {
      if (x == null) return const Text('waiting');
      return matrix(x);
    });
  }
}

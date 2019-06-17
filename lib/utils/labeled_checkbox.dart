import 'package:flutter/material.dart';

class LabeledCheckbox extends StatelessWidget {
  const LabeledCheckbox({Key key, this.value, this.onChanged})
      : super(key: key);

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Checkbox(
          value: value,
          onChanged: onChanged,
        ),
        const Expanded(
          child: Text(
            'auto reconnect on failure',
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

Widget signInButton(title, uri, [color = Colors.white]) {
  return Container(
    width: 200.0,
    child: Center(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Image.asset(
            uri,
            width: 25.0,
          ),
          Padding(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Roboto',
                color: color,
              ),
            ),
            padding: new EdgeInsets.only(left: 15.0),
          ),
        ],
      ),
    ),
  );
}

Widget buildDialog(BuildContext context, String text) {
  return new AlertDialog(
    content: new Text(text),
    actions: <Widget>[
      new FlatButton(
        child: const Text('CLOSE'),
        onPressed: () {
          Navigator.pop(context, false);
        },
      ),
      new FlatButton(
        child: const Text('SHOW'),
        onPressed: () {
          Navigator.pop(context, true);
        },
      ),
    ],
  );
}
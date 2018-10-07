import 'package:flutter/material.dart';

Widget futureBuilder = FutureBuilder(
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done) {
        if (snapshot.hasError) {
          return Text('Something wrong');
        }
        return Text('Future loaded');
      } else {
        return CircularProgressIndicator();
      }
    }
);


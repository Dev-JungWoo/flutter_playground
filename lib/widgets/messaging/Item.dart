import 'dart:async';

import 'package:flutter/material.dart';

import 'PushMessagingExample.dart';

class Item {
  Item({this.itemId});
  final String itemId;

  StreamController<Item> _controller = new StreamController<Item>.broadcast();
  Stream<Item> get onChanged => _controller.stream;

  String _status;
  String get status => _status;
  set status(String value) {
    _status = value;
    _controller.add(this);
  }

  static final Map<String, Route<Null>> routes = <String, Route<Null>>{};
  Route<Null> get route {
    final String routeName = '/detail/$itemId';
    routes.remove(routeName);
    return routes.putIfAbsent(
      routeName,
      () => new MaterialPageRoute<Null>(
            settings: new RouteSettings(name: routeName),
            builder: (BuildContext context) => new DetailPage(itemId),
          ),
    );
  }
}

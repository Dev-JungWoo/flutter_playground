// Copyright 2017 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_playgrounds/widgets/Widgets.dart';

import 'Item.dart';

final Map<String, Item> _items = <String, Item>{};

Item _itemForMessage(Map<String, dynamic> message) {
  if (message['notification'] != null) { // real notification
    final String itemId = 'TestNoficiationId';
    final Item item = _items.putIfAbsent(itemId, () => new Item(itemId: itemId))
      ..status = message['notification']['body'];
    return item;
  } else { // test with button
    final String itemId = message['id'];
    final Item item = _items.putIfAbsent(itemId, () => new Item(itemId: itemId))
      ..status = message['status'];
    return item;
  }
}

class PushMessagingExample extends StatefulWidget {
  @override
  _PushMessagingExampleState createState() => new _PushMessagingExampleState();
}

class _PushMessagingExampleState extends State<PushMessagingExample> {
  String _homeScreenText = "Waiting for token...";
  bool _topicButtonsDisabled = false;

  final FirebaseMessaging _firebaseMessaging = new FirebaseMessaging();
  final TextEditingController _topicController =
      new TextEditingController(text: 'topic');

  void _showItemDialog(Map<String, dynamic> message) {
    showDialog<bool>(
      context: context,
      builder: (_) => buildDialog(
          context, "Item ${_itemForMessage(message).itemId} has been updated"),
    ).then((bool shouldNavigate) {
      if (shouldNavigate == true) {
        _navigateToItemDetail(message);
      }
    });
  }

  void _navigateToItemDetail(Map<String, dynamic> message) {
    final Item item = _itemForMessage(message);

    if (!item.route.isCurrent) {
      Navigator.push(context, item.route);
    }
  }

  @override
  void initState() {
    super.initState();
    _firebaseMessaging.configure(
      //{notification: {title: null, body: Test Message}, data: {}}
      onMessage: (Map<String, dynamic> message) async {
        print("onMessage: $message");
        _showItemDialog(message);
      },
      onLaunch: (Map<String, dynamic> message) async {
        print("onLaunch: $message");
        _navigateToItemDetail(message);
      },
      onResume: (Map<String, dynamic> message) async {
        print("onResume: $message");
        _navigateToItemDetail(message);
      },
    );
    _firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(sound: true, badge: true, alert: true));
    _firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {
      print("Settings registered: $settings");
    });
    _firebaseMessaging.getToken().then((String token) {
      assert(token != null);
      setState(() {
        _homeScreenText = "Push Messaging token: $token";
      });
      print(_homeScreenText);
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: const Text('Push Messaging Demo'),
        ),
        // For testing -- simulate a message being received
        floatingActionButton: new FloatingActionButton(
          onPressed: () => _showItemDialog(<String, dynamic>{
                "id": "2",
                "status": "out of stock",
              }),
          tooltip: 'Simulate Message',
          child: const Icon(Icons.message),
        ),
        body: new Material(
          child: new Column(
            children: <Widget>[
              new Center(
                child: new Text(_homeScreenText),
              ),
              new Row(children: <Widget>[
                new Expanded(
                  child: new TextField(
                      controller: _topicController,
                      onChanged: (String v) {
                        setState(() {
                          _topicButtonsDisabled = v.isEmpty;
                        });
                      }),
                ),
                new FlatButton(
                  child: const Text("subscribe"),
                  onPressed: _topicButtonsDisabled
                      ? null
                      : () {
                          _firebaseMessaging
                              .subscribeToTopic(_topicController.text);
                          _clearTopicText();
                        },
                ),
                new FlatButton(
                  child: const Text("unsubscribe"),
                  onPressed: _topicButtonsDisabled
                      ? null
                      : () {
                          _firebaseMessaging
                              .unsubscribeFromTopic(_topicController.text);
                          _clearTopicText();
                        },
                ),
              ])
            ],
          ),
        ));
  }

  void _clearTopicText() {
    setState(() {
      _topicController.text = "";
      _topicButtonsDisabled = true;
    });
  }
}

class DetailPage extends StatefulWidget {
  DetailPage(this.itemId);
  final String itemId;
  @override
  _DetailPageState createState() => new _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  Item _item;
  StreamSubscription<Item> _subscription;

  @override
  void initState() {
    super.initState();
    _item = _items[widget.itemId];
    _subscription = _item.onChanged.listen((Item item) {
      if (!mounted) {
        _subscription.cancel();
      } else {
        setState(() {
          _item = item;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Item ${_item.itemId}"),
      ),
      body: new Material(
        child: new Center(child: new Text("Item status: ${_item.status}")),
      ),
    );
  }
}

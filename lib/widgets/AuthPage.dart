// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_playgrounds/widgets/SignInButton.dart';
import 'package:google_sign_in/google_sign_in.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: <String>[
    'email',
    'https://www.googleapis.com/auth/contacts.readonly',
  ],
);

class AuthPage extends StatefulWidget {
  AuthPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _AuthPageState createState() => new _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  Future<String> _message = new Future<String>.value('');
  TextEditingController _smsCodeController = new TextEditingController();
  String verificationId;
  final String testSmsCode = '888888';
  final String testPhoneNumber = '+1 408-555-6969';

  FirebaseUser user;

  _AuthPageState() {
    _auth.currentUser().then((user) => setState(() {
          this.user = user;
        }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: _getLoginButtons());
  }

  Widget _getLoginButtons() {
    if (user != null) {
      return Center(child: Text('User logged in as ${user.displayName}'));
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          MaterialButton(
            elevation: 5.0,
            child: signInButton('Sign in with Google', 'images/google.png',
                Color.fromRGBO(68, 68, 76, 0.8)),
            onPressed: () {},
            color: Colors.white,
          ),
          Padding(padding: EdgeInsets.all(5.0)),
          MaterialButton(
            elevation: 5.0,
            child: signInButton(
                'Sign in with Facebook', 'images/facebook.png', Colors.white),
            onPressed: () {},
            color: Color.fromRGBO(58, 89, 152, 1.0),
          ),
        ],
      ),
    );
  }

  Widget _getOriginalBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        new MaterialButton(
            child: const Text('Test signInAnonymously'),
            onPressed: () {
              setState(() {
                _message = _testSignInAnonymously();
              });
            }),
        new MaterialButton(
            child: const Text('Test signInWithGoogle'),
            onPressed: () {
              setState(() {
                _message = _testSignInWithGoogle();
              });
            }),
        new MaterialButton(
            child: const Text('Test verifyPhoneNumber'),
            onPressed: () {
              _testVerifyPhoneNumber();
            }),
        new Container(
          margin: const EdgeInsets.only(
            top: 8.0,
            bottom: 8.0,
            left: 16.0,
            right: 16.0,
          ),
          child: new TextField(
            controller: _smsCodeController,
            decoration: const InputDecoration(
              hintText: 'SMS Code',
            ),
          ),
        ),
        new MaterialButton(
            child: const Text('Test signInWithPhoneNumber'),
            onPressed: () {
              if (_smsCodeController.text != null) {
                setState(() {
                  _message =
                      _testSignInWithPhoneNumber(_smsCodeController.text);
                });
              }
            }),
        new FutureBuilder<String>(
            future: _message,
            builder: (_, AsyncSnapshot<String> snapshot) {
              return new Text(snapshot.data ?? '',
                  style:
                      const TextStyle(color: Color.fromARGB(255, 0, 155, 0)));
            }),
      ],
    );
  }

  Future<String> _testSignInAnonymously() async {
    final FirebaseUser user = await _auth.signInAnonymously();
    assert(user != null);
    assert(user.isAnonymous);
    assert(!user.isEmailVerified);
    assert(await user.getIdToken() != null);
    if (Platform.isIOS) {
      // Anonymous auth doesn't show up as a provider on iOS
      assert(user.providerData.isEmpty);
    } else if (Platform.isAndroid) {
      // Anonymous auth does show up as a provider on Android
      assert(user.providerData.length == 1);
      assert(user.providerData[0].providerId == 'firebase');
      assert(user.providerData[0].uid != null);
      assert(user.providerData[0].displayName == null);
      assert(user.providerData[0].photoUrl == null);
      assert(user.providerData[0].email == null);
    }

    final FirebaseUser currentUser = await _auth.currentUser();
    assert(user.uid == currentUser.uid);

    return 'signInAnonymously succeeded: $user';
  }

  Future<String> _testSignInWithGoogle() async {
    GoogleSignInAccount googleUser; //await _googleSignIn.signIn();
    try {
      googleUser = await _googleSignIn.signIn();
    } catch (error) {
      print(error);
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final FirebaseUser user = await _auth.signInWithGoogle(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    assert(user.email != null);
    assert(user.displayName != null);
    assert(!user.isAnonymous);
    assert(await user.getIdToken() != null);

    final FirebaseUser currentUser = await _auth.currentUser();
    assert(user.uid == currentUser.uid);

    return 'signInWithGoogle succeeded: $user';
  }

  Future<void> _testVerifyPhoneNumber() async {
    final PhoneVerificationCompleted verificationCompleted =
        (FirebaseUser user) {
      setState(() {
        _message =
            Future<String>.value('signInWithPhoneNumber auto succeeded: $user');
      });
    };

    final PhoneVerificationFailed verificationFailed =
        (AuthException authException) {
      setState(() {
        _message = Future<String>.value(
            'Phone number verification failed. Code: ${authException.code}. Message: ${authException.message}');
      });
    };

    final PhoneCodeSent codeSent =
        (String verificationId, [int forceResendingToken]) async {
      this.verificationId = verificationId;
      _smsCodeController.text = testSmsCode;
    };

    final PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout =
        (String verificationId) {
      this.verificationId = verificationId;
      _smsCodeController.text = testSmsCode;
    };

    await _auth.verifyPhoneNumber(
        phoneNumber: testPhoneNumber,
        timeout: const Duration(seconds: 5),
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout);
  }

  Future<String> _testSignInWithPhoneNumber(String smsCode) async {
    final FirebaseUser user = await _auth.signInWithPhoneNumber(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    final FirebaseUser currentUser = await _auth.currentUser();
    assert(user.uid == currentUser.uid);

    _smsCodeController.text = '';
    return 'signInWithPhoneNumber succeeded: $user';
  }
}

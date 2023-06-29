import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:manssanger/screens/wrapper.dart';
import 'package:manssanger/services/auth.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  FirebaseMessaging firebaseMessaging =
      FirebaseMessaging.instance; // Change here
  firebaseMessaging.getToken().then((token) {
    debugPrint("token is $token");
  });
  firebaseMessaging.subscribeToTopic("all");

  var status = await Permission.notification.status;

  if (status.isDenied) {
    await Permission.notification.request();
  }
  if (await Permission.notification.isRestricted) {
    await Permission.notification.request();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return OverlaySupport(
      child: StreamProvider.value(
        value: AuthService().user,
        initialData: null,
        child: MaterialApp(
            title: 'mANSsenger',
            theme: ThemeData(
              primarySwatch: Colors.green,
            ),
            home: const Wrapper()),
      ),
    );
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Firebase Messaging firebase is initialized");
  //await Firebase.initializeApp();
}

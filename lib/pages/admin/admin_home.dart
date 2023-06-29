import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:manssanger/pages/login.dart';
import 'package:manssanger/services/auth.dart';
import 'package:overlay_support/overlay_support.dart';
import '../../globals.dart' as globals;
import 'package:shared_preferences/shared_preferences.dart';

import 'admin_home_content.dart';
import 'admin_notifications.dart';
import 'admin_settings_content.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _selectedIndex = 0;

  final AuthService _auth = AuthService();
  var routes = [
    const AdminHomeContent(),
    const AdminNotifications(),
    const AdminSettingsContent()
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  storeNotificationToken() async {
    String? token = await FirebaseMessaging.instance.getToken();

    FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .set({
      'tokens': FieldValue.arrayUnion([token])
    }, SetOptions(merge: true));
//ustawienie w bazie powiadomień push jako aktywne, ze względu na działającą aplikację
    FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .set({
      'settings': {'push': true}
    }, SetOptions(merge: true));
  }

  @override
  void initState() {
    super.initState();
    FirebaseMessaging.onMessage.listen((RemoteMessage event) => {
          showOverlayNotification((context) {
            RemoteNotification notification = event.notification!;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: SafeArea(
                child: ListTile(
                  leading: SizedBox.fromSize(
                      size: const Size(40, 40),
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: Colors.green,
                      )),
                  title: Text(notification.title!),
                  subtitle: Text(notification.body!),
                  trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        OverlaySupportEntry.of(context)?.dismiss();
                      }),
                ),
              ),
            );
          }, duration: const Duration(milliseconds: 4000))
        });
    storeNotificationToken();
  }

  Future<bool> _onWillPop() async {
    return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Ostrzeżenie'),
            content: const Text('Czy na pewno chcesz zmknąć aplikację?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Nie'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Tak'),
              ),
            ],
          ),
        )) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: routes[_selectedIndex],
        appBar: AppBar(
          title: Image.asset(
            'asset/logo2.png',
            width: 250,
          ),
          automaticallyImplyLeading: false,
          actions: <Widget>[
            Padding(
                padding: const EdgeInsets.only(right: 20.0),
                child: GestureDetector(
                  onTap: () => showDialog<String>(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                      title: const Text('Wylogowanie z aplikacji'),
                      content: const Text('Czy na pewno chcesz się wylogować?'),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.pop(context, 'Cancel'),
                          child: const Text('Anuluj'),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const Login()));
                            _auth.signOut();
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.remove('uid');
                            await prefs.remove('firstname');
                            await prefs.remove('lastname');
                            await prefs.remove('email');
                            await prefs.remove('haveData');
                            globals.isLoggedIn = false;
                            globals.user.haveData = false;
                          },
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.logout,
                    size: 26.0,
                  ),
                )),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Strona główna',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notification_add),
              label: 'Powiadom',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Ustawienia',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.green,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}

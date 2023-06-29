import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:manssanger/pages/admin/admin_home_content.dart';
import 'package:manssanger/pages/admin/admin_notifications.dart';
import 'package:manssanger/pages/admin/admin_settings_content.dart';
import 'package:manssanger/pages/employee/home_content.dart';
import 'package:manssanger/pages/employee/notifications.dart';
import 'package:manssanger/pages/login.dart';
import 'package:manssanger/pages/employee/settings_content.dart';
import 'package:manssanger/services/auth.dart';
import 'package:overlay_support/overlay_support.dart';
import '../../globals.dart' as globals;
import 'package:shared_preferences/shared_preferences.dart';

class Home extends StatefulWidget {
  final User? user;

  const Home({super.key, required this.user});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;

  final AuthService _auth = AuthService();
  var routes = [
    const HomeContent(),
    const Notifications(),
    const SettingsContent()
  ];
  var routes2 = [
    const AdminHomeContent(),
    const AdminNotifications(),
    const Notifications(),
    const AdminSettingsContent()
  ];
  late Stream<DocumentSnapshot> _userStream;
  String? _userType;

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
    _userStream = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user?.uid)
        .snapshots();
    _userStream.listen((event) {
      setState(() {
        _userType = (event.data() as Map<String, dynamic>)['type'];
      });
    });
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
      child: _userType == null
          ? Scaffold(
              appBar: AppBar(
                title: Image.asset(
                  'asset/logo2.png',
                  width: 250,
                ),
              ),
              body: const Center(child: CircularProgressIndicator()))
          : Scaffold(
              body: _userType == "admin"
                  ? routes2[_selectedIndex]
                  : routes[_selectedIndex],
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
                            content: const Text(
                                'Czy na pewno chcesz się wylogować?'),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, 'Cancel'),
                                child: const Text('Anuluj'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  _auth.removeToken().then(
                                        (value) => _auth.signOut(),
                                      );
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.remove('uid');
                                  await prefs.remove('firstname');
                                  await prefs.remove('lastname');
                                  await prefs.remove('email');
                                  await prefs.remove('haveData');
                                  globals.isLoggedIn = false;
                                  globals.user.haveData = false;

                                  // ignore: use_build_context_synchronously
                                  Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => const Login()));
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
              bottomNavigationBar:
                  _userType == "admin" ? adminMenu() : userMenu()),
    );
  }

  Widget adminMenu() {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Strona główna',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notification_add),
          label: 'Zawiadom',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications),
          label: 'Powiadomienia',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Ustawienia',
        ),
      ],
      currentIndex: _selectedIndex,
      selectedItemColor: Colors.green,
      unselectedItemColor: Colors.grey,
      onTap: _onItemTapped,
    );
  }

  Widget userMenu() {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Strona główna',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications),
          label: 'Powiadomienia',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Ustawienia',
        ),
      ],
      currentIndex: _selectedIndex,
      selectedItemColor: Colors.green,
      onTap: _onItemTapped,
    );
  }
}

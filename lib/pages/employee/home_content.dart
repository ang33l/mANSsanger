import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/my_user.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Container(
          decoration: const BoxDecoration(boxShadow: <BoxShadow>[
            BoxShadow(
                color: Colors.black54,
                blurRadius: 15.0,
                offset: Offset(0.0, 0.75))
          ], color: Colors.lightGreen),
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Flex(
              direction: Axis.horizontal,
              children: [
                Flexible(
                  flex: 3,
                  child: CircleAvatar(
                      radius: (52),
                      backgroundColor: Colors.white,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Image.asset('asset/avatar.png'),
                      )),
                ),
                const Spacer(flex: 1),
                const UserInfo()
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(15.0),
          child: Text(
              style: TextStyle(fontSize: 18),
              "Witaj w aplikacji mobilnej do powiadamiania o dokumentach Akademii Nauk Stosowanych w Nowym Sączu."),
        ),
        Flex(
          direction: Axis.horizontal,
          children: [
            Flexible(
              flex: 30,
              child: Container(
                decoration: const BoxDecoration(boxShadow: <BoxShadow>[
                  BoxShadow(
                      color: Colors.black54,
                      blurRadius: 15.0,
                      offset: Offset(0.0, 0.75))
                ], color: Colors.lightGreen),
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 15, top: 15, bottom: 15, right: 7.5),
                  child: Flex(direction: Axis.vertical, children: const [
                    Text(
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18),
                      "Przejrzyj ostatnie powiadomienia klikając w pozycję menu:",
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Icon(Icons.notifications),
                    ),
                    Text("Powiadomienia")
                  ]),
                ),
              ),
            ),
            Flexible(
                flex: 30,
                child: Container(
                  decoration: const BoxDecoration(boxShadow: <BoxShadow>[
                    BoxShadow(
                        color: Colors.black54,
                        blurRadius: 15.0,
                        offset: Offset(0.0, 0.75))
                  ], color: Colors.lightGreen),
                  child: Padding(
                    padding: const EdgeInsets.only(
                        right: 15, top: 15, bottom: 15, left: 7.5),
                    child: Flex(
                      direction: Axis.vertical,
                      children: const [
                        Text(
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                            ),
                            "Zarządzaj ustawieniami powiadomień w ustawieniach: "),
                        Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Icon(Icons.settings),
                        ),
                        Text("Ustawienia"),
                      ],
                    ),
                  ),
                )),
          ],
        ),
        Container(
          decoration: const BoxDecoration(boxShadow: <BoxShadow>[
            BoxShadow(
                color: Colors.black54,
                blurRadius: 15.0,
                offset: Offset(0.0, 0.75))
          ], color: Color.fromARGB(255, 255, 112, 112)),
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                      style: TextStyle(color: Colors.white, fontSize: 18),
                      text: 'Aby się wylogować kliknij ikonę: '),
                  WidgetSpan(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2.0),
                      child: Icon(
                        Icons.logout,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  TextSpan(
                      style: TextStyle(color: Colors.white, fontSize: 18),
                      text: ' w prawym górnym rogu aplikacji.'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class UserInfo extends StatefulWidget {
  const UserInfo({
    super.key,
  });

  @override
  State<UserInfo> createState() => _UserInfoState();
}

class _UserInfoState extends State<UserInfo> {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  var collection = FirebaseFirestore.instance.collection('users');
  late Future _future;

  Future<MyUser> returnUser() async {
    final prefs = await SharedPreferences.getInstance();
    final bool? haveData = prefs.getBool('haveData');

    if (haveData == null) {
      final user = FirebaseAuth.instance.currentUser;
      var uid = user?.uid;
      var email = user?.email;
      final docRef = FirebaseFirestore.instance.collection("users").doc(uid);
      docRef.get().then(
        (DocumentSnapshot doc) async {
          final data = doc.data() as Map<String, dynamic>;

          await prefs.setString('uid', uid!);
          await prefs.setString('firstname', data['firstname']);
          await prefs.setString('lastname', data['lastname']);
          await prefs.setString('email', email!);
          await prefs.setBool('haveData', true);
        },
        onError: (e) => debugPrint("Error getting document: $e"),
      );
    }
    final String? uid = prefs.getString('uid');
    final String? firstname = prefs.getString('firstname');
    final String? lastname = prefs.getString('lastname');
    final String? email = prefs.getString('email');
    final bool? haveData2 = prefs.getBool('haveData');
    if (firstname == null || lastname == null || email == null) {
      setState(() {});
      return MyUser();
    }
    return MyUser(
        uid: uid,
        firstname: firstname,
        lastname: lastname,
        email: email,
        haveData: haveData2);
  }

  @override
  void initState() {
    super.initState();
    _future = returnUser();
  }

  @override
  Widget build(BuildContext context) {
    _future = returnUser();
    return FutureBuilder(
        future: _future,
        builder: (_, AsyncSnapshot snapshot) {
          if (snapshot.hasError) return Text('${snapshot.error}');
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.data == null) {
              return const Center(child: CircularProgressIndicator());
            } else {
              var user = snapshot.data;
              return Flexible(
                flex: 9,
                child: Flex(
                  direction: Axis.vertical,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.firstname ?? "Imię",
                      style: const TextStyle(color: Colors.black, fontSize: 25),
                      softWrap: false,
                      overflow: TextOverflow.ellipsis, // new
                    ),
                    Text(
                      user.lastname ?? "Nazwisko",
                      style: const TextStyle(color: Colors.black, fontSize: 25),
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(user.email ?? "e-mail")
                  ],
                ),
              );
            }
          }
          return const Center(child: CircularProgressIndicator());
        });
  }
}

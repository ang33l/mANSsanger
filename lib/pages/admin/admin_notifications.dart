import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdminNotifications extends StatefulWidget {
  const AdminNotifications({super.key});

  @override
  State<AdminNotifications> createState() => _AdminNotificationsState();
}

class Cuser {
  late String? uid;
  late String? name;

  Cuser({this.uid, this.name});
}

class _AdminNotificationsState extends State<AdminNotifications> {
  late TextEditingController textController;
  bool duplicateCreated = false;
  late var users;
  var duplicatedUsers = <Cuser>[];
  @override
  void initState() {
    super.initState();
    textController = TextEditingController(text: '');
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  void createDuplicateUsers() {
    List<Cuser> temp = [];
    for (int i = 0; i < users.length; i++) {
      Cuser tempUser = Cuser(
          name: users.elementAt(i)['name'], uid: users.elementAt(i)['uid']);
      temp.add(tempUser);
    }

    duplicatedUsers = temp;
  }

  void filterSearchResults(String query) {
    List<Cuser> temp = [];
    for (int i = 0; i < users.length; i++) {
      if (users
          .elementAt(i)['name']
          .toLowerCase()
          .contains(query.toLowerCase())) {
        Cuser tempUser = Cuser(
            name: users.elementAt(i)['name'], uid: users.elementAt(i)['uid']);
        temp.add(tempUser);
      }
    }
    setState(() {
      duplicatedUsers = temp;
    });
  }

  Future<String> getServerUrl() async {
    final DocumentSnapshot<Map<String, dynamic>> doc = await FirebaseFirestore
        .instance
        .collection('admins')
        .doc('local_server')
        .get();
    final String host = doc.data()!['host'] as String;
    final String port = doc.data()!['port'] as String;
    final String protocol = doc.data()!['protocol'] as String;
    return "$protocol://$host:$port";
  }

  Future<http.Response> broadcastNotificationQuery(message) async {
    String? token = await FirebaseMessaging.instance.getToken();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final String server = await getServerUrl();
    return http.post(Uri.parse('$server/api/app/broadcastNotification'),
        body: {"admin-uid": uid, "admin-token": token, "message": message});
  }

  Future<http.Response> singleNotificationQuery(uid) async {
    String? token = await FirebaseMessaging.instance.getToken();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final String server = await getServerUrl();
    return http.post(Uri.parse('$server/api/app/singleNotification'),
        body: {"admin-uid": uid, "admin-token": token, "user-id": uid});
  }

  String message = "";
  String errorMessage = "";
  bool isError = false;
  @override
  Widget build(BuildContext context) {
    setState(() {});
    return Column(
      children: [
        Padding(
            padding: const EdgeInsets.only(left: 15.0, right: 15, bottom: 5),
            child: ElevatedButton.icon(
                onPressed: () {
                  showDialog<String>(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                      title: const Text('Masowe powiadomienie'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                                border: Border.all(color: Colors.red),
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(8),
                                )),
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                  "Wiadomość masowa może być źródłem spamu! Ostrożnie używaj tej funkcjonalności."),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 15),
                            child: Text(isError
                                ? errorMessage
                                : "Podaj treść wiadomości:"),
                          ),
                          TextFormField(
                            validator: (val) =>
                                val!.isEmpty ? "Wpisz e-mail" : null,
                            decoration: const InputDecoration(
                                hintText: "Treść wiadomości"),
                            onChanged: (val) {
                              setState(() => message = val);
                            },
                          )
                        ],
                      ),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.pop(context, 'Cancel'),
                          child: const Text('Anuluj'),
                        ),
                        TextButton(
                          onPressed: () {
                            if (message == "") {
                              final snackBar = SnackBar(
                                content: const Text(
                                    'Błąd: Wiadomość musi mieć treść!'),
                                action: SnackBarAction(
                                  label: 'Zamknij',
                                  onPressed: () {},
                                ),
                              );

                              ScaffoldMessenger.of(context)
                                  .showSnackBar(snackBar);
                              Navigator.pop(context, 'Cancel');
                            } else {
                              broadcastNotificationQuery(message).then((value) {
                                http.Response r = value;
                                if (r.statusCode == 200) {
                                  Map json = jsonDecode(r.body);
                                  final snackBar = SnackBar(
                                    content: Text(json['message']),
                                    action: SnackBarAction(
                                      label: 'Zamknij',
                                      onPressed: () {},
                                    ),
                                  );
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(snackBar);
                                } else {
                                  Map json = jsonDecode(r.body);
                                  final snackBar = SnackBar(
                                    content: Text(
                                        'Błąd: ${r.statusCode} | ${json['message']}'),
                                    action: SnackBarAction(
                                      label: 'Zamknij',
                                      onPressed: () {},
                                    ),
                                  );

                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(snackBar);
                                }
                              });
                              Navigator.pop(context, 'Cancel');
                            }
                          },
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
                label: const Text("Masowe powiadomienie"),
                icon: const Icon(Icons.campaign))),
        Padding(
          padding: const EdgeInsets.only(left: 15.0, right: 15),
          child: CupertinoSearchTextField(
            controller: textController,
            placeholder: "Wyszukaj pracownika",
            onChanged: (value) => filterSearchResults(value),
          ),
        ),
        futureUsers(),
      ],
    );
  }

  Widget futureUsers() {
    return FutureBuilder(
      future: FirebaseFirestore.instance.collection('users').get(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Text('${snapshot.error}');
        if (snapshot.hasData) {
          if (snapshot.data == null) {
            return const Center(
              child: Text("Nie ma żadnego użytkownika w bazie."),
            );
          } else {
            users = snapshot.data!.docs.map((e) {
              String name = e.data()['firstname'] + " " + e.data()['lastname'];
              var obj = {'uid': e.id, 'name': name};
              return obj;
            });
            if (duplicatedUsers.isEmpty && !duplicateCreated) {
              createDuplicateUsers();
              duplicateCreated = true;
            }
            return Expanded(
              child: listBuild(duplicatedUsers),
            );
          }
        }
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  void sendNotification(uid) async {
    final response = singleNotificationQuery(uid);
    response.then((value) {
      http.Response r = value;
      if (r.statusCode == 200) {
        Map json = jsonDecode(r.body);
        final snackBar = SnackBar(
          content: Text(json['message']),
          action: SnackBarAction(
            label: 'Zamknij',
            onPressed: () {},
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      } else {
        Map json = jsonDecode(r.body);
        final snackBar = SnackBar(
          content: Text('Błąd: ${r.statusCode} | ${json['message']}'),
          action: SnackBarAction(
            label: 'Zamknij',
            onPressed: () {},
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    });
  }

  Widget listBuild(data) {
    return data.length != 0
        ? ListView.separated(
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemCount: data.length,
            itemBuilder: (context, index) {
              return ListTile(
                  title: Text(data[index].name),
                  onTap: () {
                    var uid = data[index].uid;
                    showDialog(
                        context: context,
                        builder: (context) => SimpleDialog(
                              title: const Text('Wybierz typ powiadomienia'),
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 25.0, right: 20),
                                  child: Text(
                                      "Osoba, którą chcesz powiadomić:\n${data[index].name}"),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 20.0, right: 20),
                                  child: ElevatedButton(
                                      onPressed: () {
                                        sendNotification(uid);
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text(
                                          "Dokumenty do podpisania/odbioru")),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 20.0, right: 20, top: 20),
                                  child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey),
                                      onPressed: () =>
                                          {Navigator.of(context).pop()},
                                      child: const Text("Anuluj")),
                                )
                              ],
                            ));
                  },
                  trailing: Container(
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "Powiadom",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ));
            },
            separatorBuilder: (BuildContext context, int index) {
              return const Divider(color: Colors.black);
            },
          )
        : const Text("Brak wyników");
  }
}

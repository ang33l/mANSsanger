import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AllNotifications extends StatefulWidget {
  const AllNotifications({super.key});

  @override
  State<AllNotifications> createState() => _AllNotificationsState();
}

class _AllNotificationsState extends State<AllNotifications> {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  var collection = FirebaseFirestore.instance.collection('users');
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Wszystkie powiadomienia"),
        ),
        body: FutureBuilder(
          future: collection.doc(uid).get(),
          builder: (_, snapshot) {
            if (snapshot.hasError) return Text('${snapshot.error}');

            if (snapshot.hasData) {
              var data = snapshot.data!.data();
              if (data?['notifications'] == null) {
                return const Padding(
                  padding: EdgeInsets.all(15.0),
                  child:
                      Center(child: Text("Nie posiadasz żadnych powiadomień.")),
                );
              }
              List n = data?['notifications'];

              n.sort((a, b) => b['date'].compareTo(a['date']));
              var length = n.length;
              if (length == 0) {
                return const Padding(
                  padding: EdgeInsets.all(15.0),
                  child:
                      Center(child: Text("Nie posiadasz żadnych powiadomień.")),
                );
              }
              return ListView.builder(
                itemCount: n.length,
                itemBuilder: (context, index) {
                  var ts = n[index]['date'].seconds * 1000 + 3600000;
                  DateTime dt = DateTime.fromMillisecondsSinceEpoch(ts);
                  DateFormat formatter = DateFormat('HH:m dd.MM.yyyy');
                  String formatted = formatter.format(dt);
                  return n[index]['enabled']
                      ? Container(
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                  width: 1.5,
                                  color: Color.fromARGB(255, 196, 196, 196)),
                            ),
                          ),
                          child: Row(children: <Widget>[
                            const Expanded(
                              flex: 1,
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Icon(
                                  Icons.notifications_outlined,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 5,
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 8.0, top: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      n[index]['topic'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18),
                                    ),
                                    Text(
                                      formatted,
                                      style: const TextStyle(
                                          fontStyle: FontStyle.italic),
                                    )
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Colors.black.withOpacity(0),
                                      shadowColor: Colors.black.withOpacity(0),
                                    ),
                                    onPressed: () => showDialog<String>(
                                          context: context,
                                          builder: (BuildContext context) =>
                                              AlertDialog(
                                            title: const Text('Ostrzeżenie'),
                                            content: const Text(
                                                'Czy na pewno chcesz oznaczyć to powiadomienie jako zakończone?'),
                                            actions: <Widget>[
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, 'Cancel'),
                                                child: const Text('Anuluj'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  var temp = data;
                                                  temp!['notifications'][index]
                                                      ['enabled'] = false;
                                                  temp['notifications'][index]
                                                          ['readingDate'] =
                                                      DateTime.now();
                                                  collection
                                                      .doc(uid)
                                                      .update(
                                                          temp) // <-- Updated data
                                                      .then((_) =>
                                                          debugPrint('Success'))
                                                      .catchError((error) =>
                                                          debugPrint(
                                                              'Failed: $error'));
                                                  Navigator.pop(
                                                      context, 'Cancel');
                                                  setState(() {
                                                    collection =
                                                        FirebaseFirestore
                                                            .instance
                                                            .collection(
                                                                'users');
                                                  });
                                                },
                                                child: const Text('OK'),
                                              ),
                                            ],
                                          ),
                                        ),
                                    child: const Align(
                                        alignment: Alignment.topLeft,
                                        child: Icon(Icons.check,
                                            color: Colors.green))),
                              ),
                            )
                          ]),
                        )
                      : Container(
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                  width: 1.5,
                                  color: Color.fromARGB(255, 196, 196, 196)),
                            ),
                          ),
                          child: Row(children: <Widget>[
                            const Expanded(
                              flex: 1,
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Icon(
                                  Icons.notifications_outlined,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 5,
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 8.0, top: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      n[index]['topic'],
                                      style: const TextStyle(
                                          fontSize: 18, color: Colors.grey),
                                    ),
                                    Text(
                                      formatted,
                                      style: const TextStyle(
                                          fontStyle: FontStyle.italic,
                                          color: Colors.grey),
                                    )
                                  ],
                                ),
                              ),
                            ),
                            Expanded(flex: 1, child: Container())
                          ]),
                        );
                },
              );
            }

            return const Center(child: CircularProgressIndicator());
          },
        ));
  }
}

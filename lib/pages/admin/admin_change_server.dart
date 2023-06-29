import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminChangeServer extends StatefulWidget {
  const AdminChangeServer({super.key});

  @override
  State<AdminChangeServer> createState() => _AdminChangeServerState();
}

class _AdminChangeServerState extends State<AdminChangeServer> {
  final _formKey = GlobalKey<FormState>();
  var collection = FirebaseFirestore.instance.collection('admins');
  String hostController = "";
  String portController = "";
  String protocolController = "";
  bool isEmpty = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ustawienia serwera"),
      ),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(boxShadow: <BoxShadow>[
              BoxShadow(
                  color: Colors.black54,
                  blurRadius: 15.0,
                  offset: Offset(0.0, 0.75))
            ], color: Colors.lightGreen),
            child: const Padding(
              padding: EdgeInsets.all(15.0),
              child: Text(
                  "Zmiana tych ustawień jest globalna - wszyscy użytkownicy z uprawnieniami pracownika dziekanatu otrzymają te zmiany!"),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: FutureBuilder(
                future: collection.doc("local_server").get(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Text('${snapshot.error}');
                  if (snapshot.hasData) {
                    if (snapshot.data == null) {
                      return const Center(
                        child: Text("Błąd wczytywania danych."),
                      );
                    } else {
                      var data = snapshot.data!.data();
                      if (isEmpty) {
                        protocolController = data!['protocol'];
                        hostController = data['host'];
                        portController = data['port'];
                        isEmpty = false;
                      }

                      return Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            TextFormField(
                              decoration:
                                  const InputDecoration(hintText: "Protokół"),
                              onChanged: (value) => setState(() {
                                protocolController = value;
                              }),
                              initialValue: data!['protocol'],
                              // The validator receives the text that the user has entered.
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'To pole nie może być puste';
                                }
                                return null;
                              },
                            ),
                            TextFormField(
                              decoration:
                                  const InputDecoration(hintText: "Host"),
                              onChanged: (value) => setState(() {
                                hostController = value;
                              }),
                              initialValue: data['host'],
                              // The validator receives the text that the user has entered.
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'To pole nie może być puste';
                                }
                                return null;
                              },
                            ),
                            TextFormField(
                              decoration:
                                  const InputDecoration(hintText: "Port"),

                              onChanged: (value) => setState(() {
                                portController = value;
                              }),
                              initialValue: data['port'],
                              // The validator receives the text that the user has entered.
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'To pole nie może być puste';
                                }
                                return null;
                              },
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16.0),
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (_formKey.currentState!.validate()) {
                                    FirebaseFirestore.instance
                                        .collection('admins')
                                        .doc('local_server')
                                        .update({
                                          "port": portController,
                                          "host": hostController,
                                          "protocol": protocolController,
                                        })
                                        .then((_) => debugPrint('Success'))
                                        .catchError((error) =>
                                            debugPrint('Failed: $error'));
                                    Navigator.pop(context);
                                  }
                                },
                                child: const Text('Zmień ustawienia'),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  }
                  return const Center(child: CircularProgressIndicator());
                }),
          ),
        ],
      ),
    );
  }
}

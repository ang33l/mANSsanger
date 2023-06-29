import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:settings_ui/settings_ui.dart';

class SettingsContent extends StatefulWidget {
  const SettingsContent({super.key});

  @override
  State<SettingsContent> createState() => _SettingsState();
}

Future<bool> getPermissions() async {
  var status = await Permission.notification.status;
  return status.isGranted ? true : false;
}

class _SettingsState extends State<SettingsContent> {
  var switches = [false, false, false];
  String changePassMessage = "Otrzymasz e-mail z linkiem do zmiany hasła";
  final uid = FirebaseAuth.instance.currentUser?.uid;
  var collection = FirebaseFirestore.instance.collection('users');
  bool permissions = false;

  @override
  Widget build(BuildContext context) {
    getPermissions().then((bool result) => permissions = result);
    return FutureBuilder(
      future: collection.doc(uid).get(),
      builder: (_, snapshot) {
        if (snapshot.hasError) return Text('${snapshot.error}');

        if (snapshot.hasData) {
          var data = snapshot.data!.data();
          var n = data?['settings'];
          var temp = data;
          return SettingsList(
            sections: [
              SettingsSection(
                title: const Text('Powiadomienia'),
                tiles: <SettingsTile>[
                  SettingsTile(
                    leading: const Icon(Icons.notifications_active),
                    title: const Text('przez aplikację'),
                    description: Text(permissions
                        ? "Aplikacja posiada uprawnienia do wyświetlania powiadomień"
                        : "Aplikacja nie posiada uprawnień - kliknij tutaj aby dodać uprawnienia"),
                    onPressed: (context) {
                      if (!permissions) {
                        openAppSettings().then((bool value) => setState(() {
                              getPermissions()
                                  .then((bool result) => permissions = result);
                            }));
                      }
                    },
                  ),
                  SettingsTile.switchTile(
                    onToggle: (value) {
                      temp!['settings']['sms'] = value;
                      collection
                          .doc(uid)
                          .update(temp) // <-- Updated data
                          .then((_) => debugPrint('Success'))
                          .catchError((error) => debugPrint('Failed: $error'));

                      setState(() {
                        collection =
                            FirebaseFirestore.instance.collection('users');
                      });
                    },
                    initialValue: n['sms'],
                    leading: const Icon(Icons.sms),
                    title: const Text('wiadomość tekstowa (SMS)'),
                  ),
                  SettingsTile.switchTile(
                    onToggle: (value) {
                      temp!['settings']['email'] = value;
                      collection
                          .doc(uid)
                          .update(temp) // <-- Updated data
                          .then((_) => debugPrint('Success'))
                          .catchError((error) => debugPrint('Failed: $error'));

                      setState(() {
                        collection =
                            FirebaseFirestore.instance.collection('users');
                      });
                    },
                    initialValue: n['email'],
                    leading: const Icon(Icons.alternate_email),
                    title: const Text('na adres e-mail'),
                  ),
                ],
              ),
              SettingsSection(
                title: const Text('Konto'),
                tiles: [
                  SettingsTile(
                    title: const Text('Zmień hasło'),
                    description: Text(changePassMessage),
                    leading: const Icon(Icons.lock),
                    onPressed: (context) {
                      showDialog<String>(
                        context: context,
                        builder: (BuildContext context) => AlertDialog(
                          title: const Text('Ostrzeżenie'),
                          content: const Text(
                              'Czy na pewno chcesz wysłać prośbę o zmianę hasła?'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.pop(context, 'Cancel'),
                              child: const Text('Anuluj'),
                            ),
                            TextButton(
                              onPressed: () {
                                String? email =
                                    FirebaseAuth.instance.currentUser?.email;
                                FirebaseAuth.instance
                                    .sendPasswordResetEmail(email: email!)
                                    .then((value) => setState(
                                          () => changePassMessage =
                                              "Pomyślnie wysłano e-mail",
                                        ))
                                    .catchError((e) => setState(
                                          () => changePassMessage =
                                              "Błąd podczas wysyłania e-maila",
                                        ));
                                Navigator.pop(context, 'Cancel');
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
    /*return FutureBuilder(
      
      child: SettingsList(
        sections: [
          SettingsSection(
            title: Text('Powiadomienia'),
            tiles: <SettingsTile>[
              SettingsTile.switchTile(
                onToggle: (value) {
                  setState(() {
                    switches[0] = value;
                  });
                },
                initialValue: switches[0],
                leading: Icon(Icons.notifications_active),
                title: Text('PUSH'),
              ),
              SettingsTile.switchTile(
                onToggle: (value) {
                  setState(() {
                    switches[1] = value;
                  });
                },
                initialValue: switches[1],
                leading: Icon(Icons.sms),
                title: Text('SMS'),
              ),
              SettingsTile.switchTile(
                onToggle: (value) {
                  setState(() {
                    switches[2] = value;
                  });
                },
                initialValue: switches[2],
                leading: Icon(Icons.alternate_email),
                title: Text('E-MAIL'),
              ),
            ],
          ),
          SettingsSection(
            title: Text('Konto'),
            tiles: [
              SettingsTile(
                title: Text('Zmień hasło'),
                leading: Icon(Icons.lock),
                onPressed: (BuildContext context) {},
              ),
            ],
          ),
        ],
      ),
    );*/
  }
}

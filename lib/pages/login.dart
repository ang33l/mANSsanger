import 'package:flutter/material.dart';
import 'package:manssanger/pages/employee/home.dart';
import 'package:manssanger/services/auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../globals.dart' as globals;

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';

  String error = '';
  _phoneCaller() async {
    Uri url = Uri.parse("tel:+48185472908");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  _emailCaller() async {
    Uri url = Uri.parse("mailto:wi@ans-ns.edu.pl");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
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
        body: Padding(
          padding: const EdgeInsets.all(30),
          child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  Image.asset('asset/full-logo.png'),
                  const Text(
                      "Zaloguj się do systemu powiadomień o dokumentach ANS w Nowym Sączu"),
                  TextFormField(
                    validator: (val) => val!.isEmpty ? "Wpisz e-mail" : null,
                    decoration: const InputDecoration(hintText: "Login"),
                    onChanged: (val) {
                      setState(() => email = val);
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(hintText: "Hasło"),
                    obscureText: true,
                    enableSuggestions: false,
                    autocorrect: false,
                    onChanged: (val) {
                      setState(() => password = val);
                    },
                    validator: (val) => val!.length < 6
                        ? "Hasło musi się składać przynajmniej z 6 znaków"
                        : null,
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        dynamic result = await _auth.signIn(email, password);
                        if (result == null) {
                          setState(
                              () => error = 'Nieprawidłowy email lub hasło!');
                        } else {
                          final user = FirebaseAuth.instance.currentUser;
                          // ignore: use_build_context_synchronously
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => Home(user: user)));
                          globals.isLoggedIn = true;
                        }
                      }
                    },
                    child: const Text(
                      'Zaloguj się',
                      style: TextStyle(color: Colors.white, fontSize: 25),
                    ),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  Text(error,
                      style: const TextStyle(color: Colors.red, fontSize: 14)),
                  Container(
                      margin: const EdgeInsets.only(top: 40),
                      child: Column(
                        children: [
                          const Text(
                              "Nie posiadasz konta? Skontaktuj się z sekretariatem:"),
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed: _phoneCaller,
                                  child: const Icon(
                                    Icons.phone,
                                    size: 60,
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Colors.black.withOpacity(0),
                                    shadowColor: Colors.black.withOpacity(0),
                                  ),
                                  onPressed: _emailCaller,
                                  child: const Icon(Icons.mail,
                                      size: 60, color: Colors.green),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ))
                ],
              )),
        ),
      ),
    );
  }
}

/*class Login extends StatelessWidget {
  const Login({super.key});

  final loginController = TextEditingController();
  final passwordController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Form(
            child: Column(
          children: [
            TextFormField(
              decoration: InputDecoration(hintText: "Login"),
              controller: loginController,
            ),
            TextFormField(
              decoration: InputDecoration(hintText: "Hasło"),
              controller: passwordController,
            ),
          ],
        )),
      ),
    );
  }
}*/

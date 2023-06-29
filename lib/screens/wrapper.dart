import 'package:firebase_auth/firebase_auth.dart';
import 'package:manssanger/services/auth.dart';
import 'package:flutter/material.dart';
import '../pages/employee/home.dart';
import '../pages/login.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: AuthService().user,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final user = FirebaseAuth.instance.currentUser;
            return Home(
              user: user,
            );
          } else {
            return const Login();
          }
        });
  }
}

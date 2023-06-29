import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:manssanger/globals.dart' as globals;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  Future checkSignState() async {
    _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        globals.isLoggedIn = false;
      } else {
        globals.isLoggedIn = true;
      }
    });
  }

  User? get currentUser => _auth.currentUser;

  Future<void> removeToken() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentReference userRef = _db.collection('users').doc(user.uid);
      DocumentSnapshot snapshot = await userRef.get();
      List<dynamic> tokensList =
          (snapshot.data() as Map<String, dynamic>)['tokens'] ?? [];
      List<String> tokens = tokensList.cast<String>();
      String? token = await _fcm.getToken();
      if (token != null) {
        tokens.remove(token);
        await userRef.update({'tokens': tokens});
      }
    }
  }

  Stream<User?> get user {
    return _auth.authStateChanges();
  }

  Future signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;
      return user;
    } catch (e) {
      return null;
    }
  }

  Future signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      return null;
    }
  }
}

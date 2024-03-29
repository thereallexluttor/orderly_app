import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:orderly_app/HomePage/HomePage.dart';
import 'package:orderly_app/Personal_information/PersonalInformation.dart';
import 'package:orderly_app/signin_signup/1stscreen_logandsign.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadePageRoute({required this.page})
      : super(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              page,
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        );
}

class logincontroller extends StatefulWidget {
  const logincontroller({Key? key});

  @override
  State<logincontroller> createState() => _logincontrollerState();
}

class _logincontrollerState extends State<logincontroller> {
  bool _personalInfoCompleted = false;
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _loadPersonalInfoCompletedStatus();
  }

  void _loadPersonalInfoCompletedStatus() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _personalInfoCompleted = _prefs.getBool('personalInfoCompleted') ?? false;
    });
  }

  void _setPersonalInfoCompleted() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _personalInfoCompleted = true;
      _prefs.setBool('personalInfoCompleted', true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          
          if (snapshot.hasData) {
            final User? user = snapshot.data;
            if (user != null) {
              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance.collection('Orderly').doc('Users').collection('users').doc(user.uid).get(),
                builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot) {
                  
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }

                  if (snapshot.hasData && snapshot.data!.exists) {
                    Map<String, dynamic>? userData = snapshot.data!.data();
                    if (userData != null) {
                      bool basicInfoCompleted = userData.containsKey('email') &&
                          userData.containsKey('name') &&
                          userData.containsKey('photo');
                      bool personalInfoCompleted = userData.containsKey('gender') &&
                          userData.containsKey('birthdate') &&
                          userData.containsKey('phoneNumber') &&
                          userData.containsKey('latitude') &&
                          userData.containsKey('longitude');
                      
                      if (basicInfoCompleted && personalInfoCompleted) {
                        _setPersonalInfoCompleted();
                        return HomePage();
                      } else {
                        return PersonalInformation();
                      }
                    }
                  }

                  if (_personalInfoCompleted) {
                    return HomePage();
                  }

                  return logandsign();
                },
              );
            }
          }
          return logandsign();
        },
      ),
    );
  }
}

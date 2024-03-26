import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:orderly_app/signin_signup/1stscreen_logandsign.dart';

class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadePageRoute({required this.page})
      : super(
          transitionDuration: const Duration(milliseconds: 500), // Duración de la animación
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
  const logincontroller({super.key});

  @override
  State<logincontroller> createState() => _logincontrollerState();
}

class _logincontrollerState extends State<logincontroller> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if(snapshot.hasData){
            return  const logandsign();
          }
          else {
            return logandsign();
          }
        },

      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:orderly_app/HomePage/HomePage.dart';
import 'package:orderly_app/Personal_information/PersonalInformation.dart';
import 'package:orderly_app/signin_signup/1stscreen_logandsign.dart';
import 'package:permission_handler/permission_handler.dart'; // Importa el paquete de manejo de permisos

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

  @override
  void initState() {
    super.initState();
    checkPermissions(); // Llama a la función para verificar los permisos al inicializar el widget
  }

  Future<void> checkPermissions() async {
    // Verifica si el permiso de ubicación está concedido
    if (await Permission.location.isGranted) {
      // Si está concedido, continúa con la lógica de autenticación
      setState(() {
        _personalInfoCompleted = true;
      });
    } else {
      // Si no está concedido, solicita el permiso
      await Permission.location.request();
    }
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

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }

                  if (snapshot.hasData && snapshot.data!.exists) {
                    // El usuario existe en Firestore, por lo que puede ir a HomePage
                    return HomePage();
                  } else {
                    // El usuario no existe en Firestore, por lo que necesita completar su información personal
                    if (_personalInfoCompleted) {
                      // Si los permisos están concedidos, muestra la pantalla de PersonalInformation
                      return PersonalInformation();
                    } else {
                      // Si los permisos no están concedidos, muestra una pantalla de carga o un mensaje de espera
                      return CircularProgressIndicator(); // Puedes personalizar esto según tu diseño
                    }
                  }
                },
              );
            }
          }
          // No hay usuario autenticado
          return logandsign();
        },
      ),
    );
  }
}

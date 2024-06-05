// ignore_for_file: use_key_in_widget_constructors, library_private_types_in_public_api, camel_case_types, avoid_print

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

class logandsign extends StatelessWidget {
  const logandsign({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 150),
              const Center(
                child: Image(
                  image: AssetImage("lib/images/logos/orderly_splash.png"),
                  height: 140,
                  width: 140,
                ),
              ),
              const SizedBox(height: 150),
              const TextChangingWidget(),
              const Padding(
                padding: EdgeInsets.only(left: 22.0),
                child: Text(
                  'Hoy podrás ordenar, sin filas y muy facil. 😎',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontFamily: "Poppins-L",
                  ),
                ),
              ),
              const SizedBox(height: 90),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 25.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(
                        thickness: 1,
                        color: Colors.grey,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.0),
                      child: Text(
                        'Ingresa aquí:',
                        style: TextStyle(
                          color: Colors.grey,
                          fontFamily: "Poppins-L",
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        thickness: 1,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      // Solicitar permiso de ubicación y luego iniciar sesión
                      if (await Permission.location.isGranted) {
                        await signInWithGoogle();
                      } else {
                        await Permission.location.request();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      fixedSize: const Size(300, 33),
                      elevation: 0,
                      side: const BorderSide(color: Color.fromARGB(255, 218, 218, 218)),
                      surfaceTintColor: Colors.white,
                    ),
                    child: const Stack(
                      alignment: Alignment.center,
                      children: [
                        Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: 0.0), // Ajusta el valor según sea necesario
                              child: Image(
                                image: AssetImage('lib/images/icons/google.png'),
                                width: 20, // Ajusta el tamaño según sea necesario
                                height: 25,
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: 10.0),
                          child: Center(
                            child: Text(
                              'Iniciar sesión con Google',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                                fontFamily: "Poppins-L",
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Método para iniciar sesión con Google
  Future<void> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    final googleAuth = await googleUser?.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
    // Imprimir el nombre del usuario para fines de depuración
    print(userCredential.user?.displayName);
  }
}

class TextChangingWidget extends StatefulWidget {
  const TextChangingWidget({super.key});

  @override
  _TextChangingWidgetState createState() => _TextChangingWidgetState();
}

class _TextChangingWidgetState extends State<TextChangingWidget> {
  int _index = 0;
  final List<String> _textList = ['Bienvenido!', 'Welcome!', '¡Salut!', 'Benvenuto!'];

  @override
  void initState() {
    super.initState();
    Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _index = (_index + 1) % _textList.length;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 22.0),
      child: Text(
        _textList[_index],
        textAlign: TextAlign.left,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 25,
          fontFamily: "Poppins-Bold",
        ),
      ),
    );
  }
}

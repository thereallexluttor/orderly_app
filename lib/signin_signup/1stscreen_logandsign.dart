import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart'; // Importa el paquete de manejo de permisos
import 'dart:async';

class logandsign extends StatelessWidget {
  const logandsign({Key? key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 100),
              const Center(
                child: Image(
                  image: AssetImage("lib/images/logos/orderly_icon3.png"),
                  height: 200,
                  width: 200,
                ),
              ),
              const SizedBox(height: 100),
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
              const SizedBox(height: 43),
              const SizedBox(height: 30),
              const SizedBox(height: 3),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 25.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(
                        thickness: 0.5,
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
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        thickness: 0.5,
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
                      // Solicitar permiso de ubicación
                      if (await Permission.location.isGranted) {
                        signInWithGoogle();
                      } else {
                        await Permission.location.request();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      fixedSize: const Size(260, 33),
                      elevation: 0,
                      side: const BorderSide(color: Color.fromARGB(255, 165, 165, 165)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center, // Centra el texto horizontalmente
                      children: [
                        // Agrega un padding a la izquierda de la imagen
                        Padding(
                          padding: const EdgeInsets.only(left: 5.0), // Ajusta el valor según sea necesario
                          child: Image(
                            image: AssetImage('lib/images/icons/google.png'),
                            width: 17, // Ajusta el tamaño según sea necesario
                            height: 25,
                          ),
                        ),
                        // Agrega un espacio entre la imagen y el texto
                        const SizedBox(width: 5), // Ajusta el valor según sea necesario
                        // El texto que deseas agregar al botón
                        Text(
                          'Iniciar sesión con Google',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.black,
                            fontFamily: "Poppins-L",
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  signInWithGoogle() async {
    GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

    AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken, idToken: googleAuth?.idToken);

    UserCredential userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);
    // ignore: avoid_print
    print(userCredential.user?.displayName);

  
   
  }
}

class TextChangingWidget extends StatefulWidget {
  const TextChangingWidget({Key? key});

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
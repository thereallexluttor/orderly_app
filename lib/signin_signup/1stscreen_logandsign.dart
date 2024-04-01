import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
                    onPressed: () {
                      signInWithGoogle();
                    },
                    style: ElevatedButton.styleFrom(
                      fixedSize: const Size(260, 33),
                      elevation: 0,
                      side:
                          const BorderSide(color: Color.fromARGB(255, 165, 165, 165)),
                    ),
                    child: const Row(
                      children: [
                        // La imagen del botón
                        Image(
                          image: AssetImage('lib/images/icons/google.png'),
                          width: 17, // Ajusta el tamaño según sea necesario
                          height: 25,
                        ),

                        // Agrega un espacio entre la imagen y el texto

                        // El texto que deseas agregar al botón
                        Center(
                          child: Text(
                            'Iniciar sesión con Google',
                            style: TextStyle(
                              // Define el estilo del texto según tus preferencias
                              fontSize: 11,
                              color: Colors.black,
                              fontFamily: "Poppins-L",
                            ),
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

    // Crear un usuario en Firestore
    if (userCredential.user != null) {
      FirebaseFirestore.instance
          .collection('Orderly')
          .doc('Users')
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'displayName': userCredential.user!.displayName,
        'email': userCredential.user!.email,
        // Puedes agregar más campos aquí si lo deseas
      });
    }
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

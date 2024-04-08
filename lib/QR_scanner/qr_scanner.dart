// ignore_for_file: camel_case_types, use_super_parameters, non_constant_identifier_names, avoid_print, unused_element, prefer_interpolation_to_compose_strings, must_be_immutable, use_key_in_widget_constructors, prefer_const_constructors, sized_box_for_whitespace
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:orderly_app/Menu/menu.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: QR_Scanner(),
    );
  }
}

class QR_Scanner extends StatefulWidget {
  const QR_Scanner({Key? key}) : super(key: key);

  @override
  State<QR_Scanner> createState() => _QR_ScannerState();
}

class _QR_ScannerState extends State<QR_Scanner> {
  String result = "";
  String useruid = "";
  String photoUrl = "";
  String ResDescription = "";

  @override
  void initState() {
    super.initState();
    _startQRScan2();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Icon(Icons.arrow_back),
                  ),
                  Row(
                    children: [
                      Image(
                        image: AssetImage("lib/images/logos/orderly_icon3.png"),
                        height: 50,
                        width: 80,
                      ),
                      SizedBox(width: 16),
                      CircleAvatar(
                        backgroundImage: photoUrl.isNotEmpty
                            ? NetworkImage(photoUrl)
                            : const AssetImage("lib/images/logos/default_avatar.png") as ImageProvider,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startQRScan2() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData =
          await FirebaseFirestore.instance.collection('Orderly').doc('Users').collection('users').doc(user.uid).get();
      photoUrl = userData['photo'] as String;
      useruid = user.uid;
    }
    setState(() {
      result = "/Orderly/restaurantes/restaurantes/El corral/mesas/1/participantes/participantes";
      List<String> parts = _processQR(result);
      String rutaHastaMenu = parts[0];
      String rutaHastaMesas = parts[1];
      String itemDespuesDeMesas = parts[2];
      String RestaurantName = parts[3];
      _addNewFieldToMesa(rutaHastaMesas, itemDespuesDeMesas, useruid, photoUrl);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MENU(result, photoUrl, rutaHastaMenu, RestaurantName, ResDescription)));
    });
  }

  List<String> _processQR(String qrText) {
    List<String> parts = qrText.split("mesas");
    List<String> parts2 = qrText.split("/");
    String rutaMenu = parts[0] + "menu";
    String rutaHastaMesas = parts[0] + "mesas";
    int indexRestaurants = parts2.indexOf("restaurantes");
    int indexMesas = parts2.indexOf("mesas");
    String RestaurantName = parts2.sublist(indexRestaurants + 2, indexMesas).join(" ");
    String itemDespuesDeMesas = parts.length > 1 ? parts[1] : "";
    return [rutaMenu, rutaHastaMesas, itemDespuesDeMesas, RestaurantName, ResDescription];
  }

  void _addNewFieldToMesa(String rutaHastaMesas, String itemDespuesDeMesas, String nuevoCampo, String valor) async {
    await FirebaseFirestore.instance.collection(rutaHastaMesas).doc(itemDespuesDeMesas).update({
      nuevoCampo: valor,
    }).then((_) {
      print("Nuevo campo agregado correctamente a la mesa $itemDespuesDeMesas");
    }).catchError((error) {
      print("Error al agregar el nuevo campo: $error");
    });
  }
}


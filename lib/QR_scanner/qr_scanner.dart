// ignore_for_file: camel_case_types, use_super_parameters, non_constant_identifier_names, avoid_print, unused_element, prefer_interpolation_to_compose_strings, must_be_immutable, use_key_in_widget_constructors, prefer_const_constructors, sized_box_for_whitespace

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      appBar: AppBar(
        title: const Text('QR Scanner'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Resultado del código de barras: $result"),
          ],
        ),
      ),
    );
  }

  void _startQRScan2() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData = await FirebaseFirestore.instance.collection('Orderly').doc('Users').collection('users').doc(user.uid).get();
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
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MENU(result, photoUrl, rutaHastaMenu, RestaurantName,ResDescription)));
    });
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

  bool _isValidQR(String qrText) {
    return qrText.split("/").length >= 6;
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
}

class MENU extends StatelessWidget {
  final String MenuUrl;
  final String scannedResult;
  final String photoUrl;
  final String RestaurantName;
  String ResDescription;

   MENU(this.scannedResult, this.photoUrl, this.MenuUrl, this.RestaurantName, this.ResDescription);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: () {
                Navigator.pop(context); // Volver a la página anterior
              },
              child: const Icon(Icons.arrow_back), // Icono de flecha hacia atrás
            ),
            const Padding(
              padding: EdgeInsets.only(left: 17.0),
              child: Image(
                image: AssetImage("lib/images/logos/orderly_icon3.png"),
                height: 50,
                width: 80,
              ),
            ),
            CircleAvatar(
              backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : const AssetImage("lib/images/logos/default_avatar.png") as ImageProvider,
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 250,
            child: Center(
              child: Card(
                elevation: 0,
                
                child: StreamBuilder(
                  stream: FirebaseFirestore.instance.collection('Orderly').doc('restaurantes').collection('restaurantes').doc(RestaurantName).snapshots(),
                  builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    final imageUrl = data['url'] as String;
                    ResDescription = data['descripcion'] as String;

                    return Image.network(
                        imageUrl,
                        width: 350,
                        height: 250,
                        fit: BoxFit.scaleDown,
                      );

                    
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(0.0),
            child: Text(
              RestaurantName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.normal, fontFamily: "Poppins-l"),
            ),
          ),

          
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection(MenuUrl).orderBy('pos').snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final docs = snapshot.data!.docs;
                final tipoProductos = _extractTipoProductos(docs);

                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    children: tipoProductos.map((tipoProducto){
                      final productos = _filterProductosByTipo(docs, tipoProducto);
                      return _buildTipoProductoColumn(tipoProducto, productos);
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

Widget _buildTipoProductoColumn(String tipoProducto, List<QueryDocumentSnapshot> productos) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          tipoProducto,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: "Poppins-l", color: Color.fromARGB(255, 193, 43, 212)),
        ),
      ),
      Column(
        children: productos.map((producto) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1.0)),
              ),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20.0),
                              border: Border.all(color: Color.fromARGB(255, 235, 235, 235)),
                            ),
                            child: SizedBox(
                              width: 180,
                              height: 180,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20.0),
                                child: Image.network(
                                  producto['url'] as String,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  producto['NOMBRE_DEL_PRODUCTO'] as String,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: "Poppins-l", fontSize: 11),
                                ),
                                SizedBox(height: 0),
                                Container(
                                  width: 180, // Establece el ancho máximo del texto
                                  child: Text(
                                    producto['descripcion'] as String,
                                    style: const TextStyle(fontSize: 10, fontFamily: "Poppins-l", color: Colors.grey),
                                    overflow: TextOverflow.ellipsis, // Trunca el texto si es demasiado largo
                                    maxLines: 3, // Máximo de 3 líneas de texto
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 0),
                          Text(
                            '\$${producto['precio']}',
                            style: const TextStyle(fontSize: 10, fontFamily: "Poppins-l", fontWeight: FontWeight.bold, color: Colors.purple),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 170,
                      child: Container(
                        padding: const EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                          color: Color.fromARGB(255, 249, 255, 248),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Icon(Icons.add, color: Colors.green[800]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ],
  );
}

  List<String> _extractTipoProductos(List<QueryDocumentSnapshot> docs) {
    final tipoProductosSet = <String>{};
    for (final doc in docs) {
      tipoProductosSet.add(doc['TIPO_PRODUCTO'] as String);
    }
    return tipoProductosSet.toList();
  }

  List<QueryDocumentSnapshot> _filterProductosByTipo(
    List<QueryDocumentSnapshot> docs,
    String tipoProducto,
  ) {
    return docs.where((doc) => doc['TIPO_PRODUCTO'] == tipoProducto).toList();
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      home: const QR_Scanner(),
    );
  }
}
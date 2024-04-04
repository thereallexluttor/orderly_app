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

  @override
  void initState() {
    super.initState();
    _startQRScan2();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QR Scanner'),
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
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MENU(result, photoUrl, rutaHastaMenu, RestaurantName)));
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
    return [rutaMenu, rutaHastaMesas, itemDespuesDeMesas, RestaurantName];
  }
}

class MENU extends StatelessWidget {
  final String MenuUrl;
  final String scannedResult;
  final String photoUrl;
  final String RestaurantName;

  MENU(this.scannedResult, this.photoUrl, this.MenuUrl, this.RestaurantName);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Image(
              image: AssetImage("lib/images/logos/orderly_icon3.png"),
              height: 60,
              width: 110,
            ),
            CircleAvatar(
              backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : AssetImage("lib/images/logos/default_avatar.png") as ImageProvider,
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 150,
            child: Center(
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(70),
                ),
                child: StreamBuilder(
                  stream: FirebaseFirestore.instance.collection('Orderly').doc('restaurantes').collection('restaurantes').doc(RestaurantName).snapshots(),
                  builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    final imageUrl = data['url'] as String;

                    return ClipOval(
                      child: Image.network(
                        imageUrl,
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(
              RestaurantName,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, fontFamily: "Poppins-l"),
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection(MenuUrl).snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final docs = snapshot.data!.docs;
                final tipoProductos = _extractTipoProductos(docs);

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: tipoProductos.map((tipoProducto){
                      final productos = _filterProductosByTipo(docs, tipoProducto);
                      return _buildTipoProductoColumn(tipoProducto, productos);
                    }).toList()

                  )
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipoProductoColumn(String tipoProducto, List<QueryDocumentSnapshot> productos) {
    return SizedBox(
      width: 300,
      child: Card(
        margin: EdgeInsets.all(10),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tipoProducto,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, fontFamily: 'Poppins', color: Color.fromARGB(255, 193, 43, 212)),
              ),
              SizedBox(height: 10),
              Column(
                children: productos.map((producto) {
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          producto['url'] as String,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(producto['NOMBRE_DEL_PRODUCTO'] as String, style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                      subtitle: Text('\$${producto['precio']}', style: TextStyle(fontFamily: 'Poppins', fontSize: 11)),
                      onTap: () {
                        // Implementa la lógica para manejar el tap en el producto si es necesario
                      },
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
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
      home: QR_Scanner(),
    );
  }
}
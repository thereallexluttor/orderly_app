import 'package:flutter/material.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QR_Scanner extends StatefulWidget {
  const QR_Scanner({Key? key}) : super(key: key);

  @override
  State<QR_Scanner> createState() => _QR_ScannerState();
}

class _QR_ScannerState extends State<QR_Scanner> {
  String result = "";

  @override
  void initState() {
    super.initState();
    // Iniciar la exploración de QR al cargar la pantalla
    //_startQRScan();
    _startQRScan2();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

  void _startQRScan2() async{
    setState(() {
      result = "/Orderly/restaurantes/restaurantes/El corral/mesas/1";
      List<String> parts = _processQR(result);
            String rutaHastaMesas = parts[0];
            String itemDespuesDeMesas = parts[1];
            // Agregar un nuevo campo a la mesa con algún valor
            _addNewFieldToMesa(rutaHastaMesas, itemDespuesDeMesas, "nuevo_campo", "valooorr");
            // Navegar a la pantalla MENU() y pasar el resultado escaneado como parámetro
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MENU(result)));
    });
  }

  // Método para iniciar la exploración de QR----- MEter luego en cell fijo.
  void _startQRScan() async {
    // Verificar si ya se han concedido los permisos
    var status = await Permission.camera.status;
    if (status.isGranted) {
      // Si ya se concedieron los permisos, abrir el escáner de códigos QR
      var res = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SimpleBarcodeScannerPage(),
        ),
      );
      setState(() {
        if (res is String) {
          result = res; // Guardar el resultado escaneado en la variable result
          if (_isValidQR(res)) {
            // Si el código QR es válido, procesar la ruta y el ítem después de "mesas"
            List<String> parts = _processQR(res);
            String rutaHastaMesas = parts[0];
            String itemDespuesDeMesas = parts[1];
            // Agregar un nuevo campo a la mesa con algún valor
            _addNewFieldToMesa(rutaHastaMesas, itemDespuesDeMesas, "nuevo_campo", "valor");
            // Navegar a la pantalla MENU() y pasar el resultado escaneado como parámetro
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MENU(result)));
          } else {
            // Si el código QR no es válido, mostrar un mensaje
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('El código QR no es válido. Debe contener al menos 6 "/".'),
              ),
            );
          }
        }
      });
    } 
  }

  // Método para agregar un nuevo campo a la mesa en la base de datos Firestore
  void _addNewFieldToMesa(String rutaHastaMesas, String itemDespuesDeMesas, String nuevoCampo, String valor) async {
    await FirebaseFirestore.instance.collection(rutaHastaMesas).doc(itemDespuesDeMesas).update({
      nuevoCampo: valor,
    }).then((_) {
      print("Nuevo campo agregado correctamente a la mesa $itemDespuesDeMesas");
    }).catchError((error) {
      print("Error al agregar el nuevo campo: $error");
    });
  }

  // Método para verificar si el código QR es válido (contiene al menos 6 "/")
  bool _isValidQR(String qrText) {
    return qrText.split("/").length >= 6;
  }

  // Método para procesar el código QR y dividir el texto hasta "mesas"
  List<String> _processQR(String qrText) {
    List<String> parts = qrText.split("mesas");
    String rutaHastaMesas = parts[0] + "mesas";
    String itemDespuesDeMesas = parts.length > 1 ? parts[1] : "";
    return [rutaHastaMesas, itemDespuesDeMesas];
  }
}

class MENU extends StatelessWidget {
  final String scannedResult;

  MENU(this.scannedResult);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Menú'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection("/Orderly/restaurantes/restaurantes/El corral/menu").snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          final docs = snapshot.data?.docs ?? [];
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
      )
    );
  }

  // Construir una columna para un tipo de producto
  Widget _buildTipoProductoColumn(String tipoProducto, List<QueryDocumentSnapshot> productos) {
    return SizedBox(
      width: 300, // Ancho fijo para la columna
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tipoProducto,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Column(
            children: productos.map((producto) {
              return ListTile(
                leading: Image.network(producto['url'] as String),
                title: Text(producto['NOMBRE_DEL_PRODUCTO'] as String),
                subtitle: Text('\$${producto['precio']}'),
                onTap: () {
                  // Implementa la lógica para manejar el tap en el producto si es necesario
                },
              );
            }).toList(),
          ),
          SizedBox(height: 20),
        ],
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

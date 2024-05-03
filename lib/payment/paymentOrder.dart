import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Importar para formatear números

class PaymentOrder extends StatefulWidget {
  final Stream<Map<String, dynamic>> invoiceProductsStream;
  final String scannedResult;

  const PaymentOrder(this.invoiceProductsStream, this.scannedResult, {super.key});

  @override
  State<PaymentOrder> createState() => _PaymentOrderState();
}

class _PaymentOrderState extends State<PaymentOrder> {
  double totalToPay = 0.0;
  double percentage = 0.0; // Valor porcentual que será obtenido de Firestore
  NumberFormat formatter = NumberFormat("#,##0", "es_ES");

  @override
  void initState() {
    super.initState();
    _fetchPercentageFromFirestore();
    widget.invoiceProductsStream.listen(
      (data) {
        print(data);
        _processData(data);
      },
      onError: (error) {
        print("Error received from stream: $error");
      },
    );
  }

void _fetchPercentageFromFirestore() async {
  String path = "${widget.scannedResult}/pagos/pagar";
  DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance.doc(path).get();
  var managerPay = documentSnapshot.data() as Map<String, dynamic>? ?? {};
  List<dynamic> payments = managerPay['ManagerPay'] ?? [];

  // Filtra los pagos donde el porcentaje no es "0%" y luego busca el primer pago válido si existe
  var validPayments = payments.where((payment) {
    return (payment['Percentage'] as String).replaceAll('%', '') != '0';
  }).toList();

  if (validPayments.isNotEmpty) {
    Map<String, dynamic> firstValidPayment = validPayments.first as Map<String, dynamic>;
    String percentageString = firstValidPayment['Percentage'].replaceAll('%', '');
    setState(() {
      percentage = double.parse(percentageString) / 100; // Convirtiendo el porcentaje a un valor decimal
    });
  } else {
    setState(() {
      percentage = 0.0; // Asume 0.0 si no hay pagos válidos
    });
  }
}


  void _processData(Map<String, dynamic> data) {
    double newTotalToPay = 0.0;
    data.forEach((key, itemList) {
      if (itemList is Iterable) {
        for (var item in itemList) {
          if (item is Map<String, dynamic>) {
            newTotalToPay += item['price'] + (item['selectedAdditionals'] as List<dynamic>).fold(0.0, (sum, additional) => sum + additional['price']);
          }
        }
      }
    });
    newTotalToPay *= percentage;
    setState(() {
      totalToPay = newTotalToPay;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('Página de Pago', style: TextStyle(fontFamily: "Poppins-l")),
          backgroundColor: Colors.blue,
          automaticallyImplyLeading: false, // Esto elimina el botón de retroceso
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Total a pagar: \$${formatter.format(totalToPay)}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Poppins-l",
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                icon: Icon(Icons.account_balance_wallet, size: 24),
                label: Text("Nequi"),
                onPressed: () => print("Pago por Nequi"),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Colors.blue,
                  textStyle: TextStyle(fontFamily: "Poppins-l", fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              ElevatedButton.icon(
                icon: Icon(Icons.money_off, size: 24),
                label: Text("Efectivo"),
                onPressed: () => print("Pago en Efectivo"),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Colors.green,
                  textStyle: TextStyle(fontFamily: "Poppins-l", fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              ElevatedButton.icon(
                icon: Icon(Icons.credit_card, size: 24),
                label: Text("Datafono"),
                onPressed: () => print("Pago por Datafono"),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Colors.purple,
                  textStyle: TextStyle(fontFamily: "Poppins-l", fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              ElevatedButton.icon(
                icon: Icon(Icons.business, size: 24),
                label: Text("Bancolombia"),
                onPressed: () => print("Pago por Bancolombia"),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Colors.red,
                  textStyle: TextStyle(fontFamily: "Poppins-l", fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

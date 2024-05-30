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
        print("Error recibido del stream: $error");
      },
    );
  }

  void _fetchPercentageFromFirestore() async {
    String path = "${widget.scannedResult}/pagos/pagar";
    DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance.doc(path).get();
    var managerPay = documentSnapshot.data() as Map<String, dynamic>? ?? {};
    List<dynamic> payments = managerPay['ManagerPay'] ?? [];

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
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 40), // Espacio superior
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back),
                      onPressed: () {
                        // Maneja la acción de retroceso
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 50),
                const Padding(
                  padding: EdgeInsets.all(15.0),
                  child: Text(
                    'Selecciona tu metodo de pago! 😎',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.normal,
                      fontFamily: "Poppins",
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 60),
                Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        
                      ),
                      child: Column(
                        children: [
                          _buildPaymentButton("lib/images/icons/nequi.png", "Nequi, Bancolombia, PSE...", "lib/images/animations/wompi.png", () => print("Pago por Nequi")),
                          _buildPaymentButton("lib/images/icons/cash.jpg", "Efectivo", "lib/images/animations/dinero.gif", () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const PaymentMessageScreen()),
                            );
                          }),
                          _buildPaymentButton("lib/images/icons/datafono.png", "Datafono", "lib/images/animations/datafono.gif", () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const PaymentMessageScreen()),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 150),
                
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentButton(String imagePath, String label, String? trailingImagePath, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          elevation: 0,
          shadowColor: Colors.grey.shade200,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: "Poppins",
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            if (trailingImagePath != null)
              Image.asset(
                trailingImagePath,
                width: 38,
                height: 38,
                fit: BoxFit.scaleDown,
              ),
          ],
        ),
      ),
    );
  }
}

class PaymentMessageScreen extends StatelessWidget {
  const PaymentMessageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Tu mesero esta en camino! 😉',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.normal,
                fontFamily: "Poppins",
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            Image.asset(
              'lib/images/animations/mesero.gif',
              width: 150,
              height: 150,
            ),
          ],
        ),
      ),
    );
  }
}

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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Total a pagar: \$${formatter.format(totalToPay)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Poppins-l",
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 550, // Adjust height as needed
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(
                        image: AssetImage('lib/images/icons/card.png'),
                        fit: BoxFit.scaleDown,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 210,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        _buildPaymentButton("lib/images/icons/nequi.png", "Nequi", () => print("Pago por Nequi")),
                        _buildPaymentButton("lib/images/icons/cash.jpg", "Efectivo", () => print("Pago en Efectivo")),
                        _buildPaymentButton("lib/images/icons/datafono.png", "Datafono", () => print("Pago por Datafono")),
                        _buildPaymentButton("lib/images/icons/bancolombia.png", "Bancolombia", () => print("Pago por Bancolombia")),
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

 Widget _buildPaymentButton(String imagePath, String label, VoidCallback onPressed) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 0), // Adjust vertical margin for better spacing
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        padding: EdgeInsets.zero, // Remove padding to maintain fixed size
        fixedSize: const Size(230, 20), // Set fixed size for smaller and thinner button
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          //side: const BorderSide(color: Color.fromARGB(255, 231, 231, 231), width: 1), // Add grey border
        ),
        elevation: 0,
        shadowColor: const Color.fromARGB(255, 230, 230, 230).withOpacity(0.1),
      ),
      child: Row(
        children: [
          const SizedBox(width: 5),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              //border: Border.all(color: const Color.fromARGB(255, 241, 241, 241), width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                imagePath,
                width: 32, // Reduce image size to fit the button
                height: 32,
                fit: BoxFit.fill, // Reduce image size to fit the button
              ),
            ),
          ),
          const SizedBox(width: 5), // Adjust spacing to fit the button
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: "Poppins",
                fontWeight: FontWeight.bold,
                fontSize: 10, // Reduce font size to fit the button
                color: Colors.black,
              ),
            ),
          ),
          SizedBox(width: 5),
          Container(
            
            child: Checkbox(
              value: false, // Replace with your state variable
              onChanged: (bool? newValue) {
                // Handle checkbox state change
              },
              activeColor: Colors.transparent,
              checkColor: Colors.black,
            ),
          ),
          const SizedBox(width: 5),
        ],
      ),
    ),
  );
}

}

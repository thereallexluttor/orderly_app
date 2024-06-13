import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:orderly_app/payment/waiting.dart';

class PaymentOrder extends StatefulWidget {
  final Stream<Map<String, dynamic>> invoiceProductsStream;
  final String scannedResult;

  const PaymentOrder(this.invoiceProductsStream, this.scannedResult, {super.key});

  @override
  State<PaymentOrder> createState() => _PaymentOrderState();
}

class _PaymentOrderState extends State<PaymentOrder> {
  double totalToPay = 0.0;
  double percentage = 0.0;
  NumberFormat formatter = NumberFormat("#,##0", "es_ES");
  Map<String, dynamic> currentData = {};

  @override
  void initState() {
    super.initState();
    _fetchPercentageFromFirestore();
    widget.invoiceProductsStream.listen(
      (data) {
        print(data);
        _processData(data);
        currentData = data;
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
        percentage = double.parse(percentageString) / 100;
      });
    } else {
      setState(() {
        percentage = 0.0;
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

  void _saveDataToFirestore(Map<String, dynamic> data, String paymentMethod) async {
    String path = "${widget.scannedResult}/pagos/pagar";
    try {
      String userUid = FirebaseAuth.instance.currentUser!.uid;
      if (userUid != null) {
        data[userUid][0]['Paymentmethod'] = paymentMethod;
        await FirebaseFirestore.instance.doc(path).update({
          'data.$userUid': data[userUid],
        });
        print('Data saved successfully to Firestore.');
        _navigateToWaitingPage();
      } else {
        print('No se encontró el UID del usuario en los datos.');
      }
    } catch (e) {
      print('Error saving data to Firestore: $e');
    }
  }

  void _navigateToWaitingPage() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const WaitingPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          automaticallyImplyLeading: false,  // Oculta el botón de retroceso
          title: Image.asset(
            'lib/images/logos/orderly_icon4.png',
            height: 30,
          ),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 40),
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.all(15.0),
                  child: Text(
                    'Elige tu método de pago favorito! 😊',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.normal,
                      fontFamily: "Insanibu",
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 80),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.normal,
                        fontFamily: "Poppins",
                        color: Colors.black,
                      ),
                      children: [
                        const TextSpan(
                          text: 'Total a pagar: ',
                        ),
                        const TextSpan(
                          text: '\$',
                          style: TextStyle(
                            color: Colors.purple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: '${formatter.format(totalToPay)}',
                          style: const TextStyle(
                            color: Colors.purple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 0),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildPaymentButton("Nequi, Bancolombia, PSE", "lib/images/animations/wompi.png", () {
                        _navigateToWaitingPage();
                        print("Pago por Nequi");
                      }),
                      _buildPaymentButton("Efectivo", "lib/images/animations/dinero.gif", () {
                        _saveDataToFirestore(currentData, 'Efectivo');
                        _navigateToWaitingPage();
                      }),
                      _buildPaymentButton("Datafono", "lib/images/animations/datafono.gif", () {
                        _saveDataToFirestore(currentData, 'Datafono');
                        _navigateToWaitingPage();
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 150),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentButton(String label, String? trailingImagePath, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.purple),
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
                    fontSize: 16,
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

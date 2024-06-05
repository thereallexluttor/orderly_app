import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class paymentOrderPos extends StatefulWidget {
  final double totalAmount;
  final List<Map<String, dynamic>> itemsForUser;
  final String firestorepath1;
  final String firestorepath2;

  const paymentOrderPos(this.totalAmount, this.itemsForUser, this.firestorepath1, this.firestorepath2, {super.key});

  @override
  State<paymentOrderPos> createState() => _paymentOrderPosState();
}

// ignore: camel_case_types
class _paymentOrderPosState extends State<paymentOrderPos> {
   
 void _saveDataToFirestore(List<Map<String, dynamic>> data, String paymentMethod) async {
  // Obtener el UID del usuario autenticado
  User? user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    print('No user is signed in.');
    return;
  }
  String uid = user.uid;

  // Construir la ruta usando el UID del usuario
  String path = "${widget.firestorepath1}/participantes/pagos/pagar";
  try {
    await FirebaseFirestore.instance.doc(path).update({
      uid: data, // Utilizar el UID como clave
    });
    print('Data saved successfully to Firestore.');
  } catch (e) {
    print('Error saving data to Firestore: $e');
  }
}
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => true, // Permitir la navegación hacia atrás
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
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        Navigator.pop(context); // Navegar hacia atrás
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 50),
                const Padding(
                  padding: EdgeInsets.all(15.0),
                  child: Text(
                    'Selecciona Wompi para procesar tu pago! 😎',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.normal,
                      fontFamily: "Poppins",
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Total Amount: \$${widget.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: "Poppins",
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Firestore Path 1: ${widget.firestorepath1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: "Poppins",
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Firestore Path 2: ${widget.firestorepath2}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: "Poppins",
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 120),
                Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _buildPaymentButton("lib/images/icons/nequi.png", "Nequi, Bancolombia, PSE...", "lib/images/animations/wompi.png", (){
                                _saveDataToFirestore(widget.itemsForUser, 'Efectivo');
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
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
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


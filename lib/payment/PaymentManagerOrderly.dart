import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentManagerOrderly extends StatefulWidget {
  final Map<String, List<Map<String, dynamic>>> itemsForUser;
  final String photoUrl; // URL de la foto de perfil
  final String firestorePath1;
  final String firestorePath2;
  final String scannedResult;

  PaymentManagerOrderly(this.itemsForUser, this.photoUrl, this.firestorePath1, this.firestorePath2, this.scannedResult, {Key? key}) : super(key: key);

  @override
  _PaymentManagerOrderlyState createState() => _PaymentManagerOrderlyState();
}

class _PaymentManagerOrderlyState extends State<PaymentManagerOrderly> {
  List<String> selectedKeys = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String calculatePercentage() {
    if (selectedKeys.isNotEmpty) {
      final percentage = 100 / selectedKeys.length;
      return '${percentage.toStringAsFixed(2)}%';  // Mostrar con dos decimales
    }
    return '0%';  // Devuelve 0% si nadie está seleccionado
  }

  List<Map<String, dynamic>> getUserPayments() {
    List<Map<String, dynamic>> userPayments = [];
    // Calcula el porcentaje aquí para usarlo en el bucle
    String selectedPercentage = calculatePercentage();

    // Incluye todos los usuarios, seleccionados o no
    widget.itemsForUser.forEach((key, users) {
      users.forEach((user) {
        userPayments.add({
            'UserId': user['UserId'] as String,
            'Percentage': selectedKeys.contains(key) ? selectedPercentage : '0%',  // Asigna 0% si no está seleccionado
            'WillPay': selectedKeys.contains(key)  // Verdadero si está seleccionado, falso de lo contrario
        });
      });
    });

    return userPayments;
  }

  void resetAndSetFirestoreData(List<Map<String, dynamic>> userPayments) async {
    String direction = "${widget.scannedResult}/pagos/pagar";
    DocumentReference documentRef = _firestore.doc(direction);
    await documentRef.set({
      'ManagerPay': FieldValue.arrayUnion(userPayments.map((e) => {
        "UserId": e['UserId'], 
        "Percentage": e['Percentage'],
        "WillPay": e['WillPay']
      }).toList())
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Payment Manager', style: TextStyle(fontFamily: "Poppins-l", fontSize: 13)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: CircleAvatar(
              backgroundImage: NetworkImage(widget.photoUrl),
            ),
          ),
        ],
      ),
      body: widget.itemsForUser.isEmpty
          ? const Center(
              child: Text('No items to display.'),
            )
          : Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                  child: Text(
                    'Elige quién paga: puedes seleccionar una o más opciones, ¡o dividir la cuenta entre todos!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: "Poppins-l",
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: MediaQuery.of(context).size.height * 0.5,
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Color.fromARGB(255, 184, 184, 184), width: 1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 1 / 1.1,
                          ),
                          itemCount: widget.itemsForUser.keys.length,
                          itemBuilder: (BuildContext context, int index) {
                            String imageUrl = widget.itemsForUser.keys.elementAt(index);
                            List<Map<String, dynamic>>? userInfo = widget.itemsForUser[imageUrl];
                            bool isSelected = selectedKeys.contains(imageUrl);

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    selectedKeys.remove(imageUrl);
                                  } else {
                                    selectedKeys.add(imageUrl);
                                  }
                                });
                              },
                              child: GridTile(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 500),
                                      curve: Curves.easeInOut,
                                      margin: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: const Color.fromARGB(255, 196, 68, 255).withOpacity(0.5),
                                                  spreadRadius: 3,
                                                  blurRadius: 5,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ]
                                            : [],
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color.fromARGB(255, 165, 68, 255)
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: FadeInImage.assetNetwork(
                                          placeholder: 'assets/placeholder.png',
                                          image: imageUrl,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Positioned(
                                        right: 8,
                                        top: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color.fromARGB(255, 171, 68, 255),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            calculatePercentage(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: ElevatedButton(
                    onPressed: selectedKeys.isNotEmpty ? () async {
                      List<Map<String, dynamic>> userPayments = getUserPayments();
                      resetAndSetFirestoreData(userPayments);
                    } : null,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, backgroundColor: const Color.fromARGB(255, 158, 49, 177),
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                    ),
                    child: const Text('Ir a Pagar!', style: TextStyle(fontFamily: "Poppins-l", fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
    );
  }
}

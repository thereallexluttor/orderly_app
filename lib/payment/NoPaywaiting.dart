import 'package:flutter/material.dart';

class NoPayWaiting extends StatelessWidget {
  const NoPayWaiting({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Fondo blanco
      body: Center(
        child: Text(
          "Esperando que se termine de realizar el pago",
          style: TextStyle(
            fontSize: 20, // Tamaño de la fuente
            fontWeight: FontWeight.bold, // Grosor de la fuente
            color: Colors.black, // Color del texto
          ),
          textAlign: TextAlign.center, // Alineación del texto
        ),
      ),
    );
  }
}

// ignore_for_file: must_be_immutable, non_constant_identifier_names, use_key_in_widget_constructors, library_private_types_in_public_api, prefer_const_constructors, avoid_print, unused_field, prefer_final_fields, no_leading_underscores_for_local_identifiers, sort_child_properties_last, deprecated_member_use, unnecessary_to_list_in_spreads, prefer_interpolation_to_compose_strings

import 'dart:async';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_expanded_tile/flutter_expanded_tile.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:orderly_app/payment/NoPaywaiting.dart';
import 'package:orderly_app/payment/PaymentManagerOrderly.dart';
import 'package:orderly_app/payment/paymentOrder.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OrderDetails {
  final String firebaseuid;
  final String orderUrl;
  final String photoUser;
  final String productName;
  final String description;
  final String imageUrl;
  final int price;
  final List<AdditionalItem> selectedAdditionals;

  OrderDetails({
    required this.firebaseuid,
    required this.orderUrl,
    required this.photoUser,
    required this.productName,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.selectedAdditionals,
  });
}

class AdditionalItem {
  final String name;
  final int price;
  final String photo;

  AdditionalItem({
    required this.name,
    required this.price,
    required this.photo,
  });
}

class ProductItem {
  int quantity;
  double price;
  String imageUrl;
  String additionals;

  ProductItem({
    required this.quantity,
    required this.price,
    required this.imageUrl,
    required this.additionals,
  });
}

class ShoppingCart {
  final Map<String, ProductItem> _selectedProducts = {};
  double _totalAmount = 0;

  Map<String, ProductItem> get selectedProducts => _selectedProducts;
  double get totalAmount => _totalAmount;

  // Añadir producto al carrito
  void addToCart(String productName, double productPrice, String imageUrl, String additionals) {
    if (_selectedProducts.containsKey(productName)) {
      _selectedProducts[productName]!.quantity += 1;
    } else {
      _selectedProducts[productName] = ProductItem(
        quantity: 1,
        price: productPrice,
        imageUrl: imageUrl,
        additionals: additionals,
      );
    }
    _totalAmount += productPrice;
  }

  // Eliminar producto del carrito
  void removeFromCart(String productName, double productPrice) {
    if (_selectedProducts.containsKey(productName)) {
      final currentQuantity = _selectedProducts[productName]!.quantity;
      if (currentQuantity > 1) {
        _selectedProducts[productName]!.quantity -= 1;
        _totalAmount -= productPrice;
      } else {
        _selectedProducts.remove(productName);
        _totalAmount -= productPrice;
      }
    }
  }

  // Vaciar el carrito
  void clearCart() {
    _selectedProducts.clear();
    _totalAmount = 0;
  }
}

class MenuHomePage extends StatefulWidget {
  final String menuUrl;

  const MenuHomePage({required this.menuUrl});

  @override
  _MenuHomePageState createState() => _MenuHomePageState();
}

class _MenuHomePageState extends State<MenuHomePage> {
  final ShoppingCart _shoppingCart = ShoppingCart();
  late Future<QuerySnapshot> _menuDataFuture;
  late Future<DocumentSnapshot> _restaurantDataFuture;
  late List<QueryDocumentSnapshot> _menuData; // Variable para almacenar los datos del menú
  int _cartItemCount = 0;
  late List<ExpandedTileController> _controllers; // Cambio a lista de controladores
  int total_obligatoriox = 0;

  // Definir _selectedAdditionals para almacenar los adicionales seleccionados
  List<String> _selectedAdditionals = [];
  int totalSelected = 0;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(10, (_) => ExpandedTileController(isExpanded: true));
    _restaurantDataFuture = _fetchRestaurantData();
    _menuDataFuture = _fetchMenuData().then((snapshot) {
      _menuData = snapshot.docs; // Almacenar los datos del menú cuando estén disponibles
      return snapshot;
    });
  }

  // Funciones para obtener datos de Firestore
  Future<DocumentSnapshot> _fetchRestaurantData() async {
    return FirebaseFirestore.instance
        .doc(widget.menuUrl)
        .get();
  }

  Future<QuerySnapshot> _fetchMenuData() async {
    return FirebaseFirestore.instance
        .collection(widget.menuUrl + "/menu")
        .orderBy('pos')
        .get();
  }

  // Construcción de la interfaz de usuario
  @override
  Widget build(BuildContext context) {
    // Initialize categoryGroups to group products by category
    Map<String, List<QueryDocumentSnapshot>> categoryGroups = {};

    // Use FutureBuilder to wait for data to load
    return FutureBuilder(
      future: Future.wait([_restaurantDataFuture, _menuDataFuture]),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        // Check if the data has loaded
        if (!snapshot.hasData) {
          return  Center(
            child: LoadingAnimationWidget.twistingDots(
                          leftDotColor: const Color(0xFF1A1A3F),
                          rightDotColor: Color.fromARGB(255, 198, 55, 234),
                          size: 50,
                        ),
          );
        }

        final List<dynamic>? data = snapshot.data;
        if (data == null || data.isEmpty) {
          return const Center(
            child: Text('No data available'),
          );
        }

        final restaurantData = data[0] as DocumentSnapshot;
        final menuData = data[1] as QuerySnapshot;

        // Assign data to _menuData
        _menuData = menuData.docs;

        // Group products by category
        for (final producto in _menuData) {
          String categoria = producto['TIPO_PRODUCTO'] as String;
          if (!categoryGroups.containsKey(categoria)) {
            categoryGroups[categoria] = [];
          }
          categoryGroups[categoria]!.add(producto);
        }

        // Get the screen width
        double screenWidth = MediaQuery.of(context).size.width;
        int gridCount = screenWidth < 600 ? 2 : 4; // Adjust grid column count based on screen width

        return DefaultTabController(
          length: categoryGroups.length, // Set the number of tabs based on the number of categories
          child: Scaffold(
            backgroundColor: Color.fromARGB(255, 255, 255, 255),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // Alinea los elementos a la izquierda
                  children: [
                    Stack(
  children: <Widget>[
    // Imagen principal dentro de un Container y ClipRRect
    Container(
      margin: EdgeInsets.only(bottom: 20, left: 0),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        child: Image.network(restaurantData['banner'] as String),
      ),
    ),
    // Posicionar el CircleAvatar en la esquina inferior izquierda
    Positioned(
      left: 10,
      bottom: 0,
      child: Row(
        children: [
          CircleAvatar(
            radius: 30.0,
            backgroundImage: NetworkImage(restaurantData['url'] as String),
            backgroundColor: Color.fromARGB(255, 255, 255, 255),
          ),
          SizedBox(width: 210),

          // Fotos de usuarios en línea
        ],
      ),
    ),

    Positioned(
      top: 8, // Ajusta la posición según tus necesidades
      left: 8,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
        },
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.white, // Fondo blanco
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Icon(
            Icons.arrow_back,
            size: 20,
            color: Colors.black, // Icono negro
          ),
        ),
      ),
    ),
  ],
),

// Información del restaurante debajo del Stack
// Mueve todo el contenido de la columna hacia arriba
Container(
  margin: EdgeInsets.only(top: 7, left: 0),
  color: const Color.fromARGB(0, 255, 255, 255),
  padding: const EdgeInsets.all(0.0),
  child: Column(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(width: 15),
          // Foto del restaurante
          // Columna para Nombre y detalles del restaurante
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre del restaurante
                Row(
                  children: [
                    SizedBox(height: 14),
                    Text(
                      restaurantData['nombre_restaurante'] as String,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 17.9,
                        fontFamily: "Poppins-Bold",
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    SizedBox(width: MediaQuery.of(context).size.width * 0.2),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0), // Ajusta el padding para un mejor aspecto
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2), // Color dorado tenue
                        borderRadius: BorderRadius.circular(20), // Hace que el container sea ovalado
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 10.8), // Icono de estrella en dorado
                          SizedBox(width: 0),
                          Text(
                            "${restaurantData['calificacion']}",
                            style: TextStyle(
                              fontFamily: "Poppins",
                              fontWeight: FontWeight.bold,
                              fontSize: 10.8,
                              color: Color.fromARGB(255, 116, 116, 116),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 10), // Espacio entre calificación y entrega
                    // Tiempo de entrega
                    Icon(Icons.access_time, color: Color.fromARGB(255, 116, 116, 116), size: 10.8, weight: 200), // Icono de reloj en gris
                    SizedBox(width: 2),
                    Text(
                      '${restaurantData['tiempo_entrega']} min',
                      style: TextStyle(
                        color: Color.fromARGB(255, 116, 116, 116),
                        fontSize: 10.8,
                        fontFamily: "Poppins",
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '${restaurantData['descripcion']}',
                      style: TextStyle(
                        color: Color.fromARGB(255, 116, 116, 116),
                        fontSize: 13.5,
                        fontFamily: "Poppins",
                      ),
                    ),
                    SizedBox(height: 10),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ],
  ),
),


                    const SizedBox(height: 20),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                    ),

                    TabBar(
                      tabAlignment: TabAlignment.center,
                      isScrollable: true,
                      labelPadding: EdgeInsets.symmetric(horizontal: 10), // Space between tabs
                      indicatorPadding: EdgeInsets.zero, // Asegúrate de que no hay padding en el indicador
                      padding: EdgeInsets.zero, // Elimina cualquier padding del TabBar
                      tabs: categoryGroups.keys.map((String category) {
                        return Tab(
                          text: category,
                        );
                      }).toList(),
                      labelStyle: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                        fontFamily: 'Poppins-Bold',
                      ),
                      unselectedLabelStyle: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.normal,
                        color: Colors.grey,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: categoryGroups.entries.map((entry) {
                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(), // Asegura que la lista no sea desplazable si no es necesario
                              itemCount: entry.value.length,
                              itemBuilder: (context, index) {
                                return _buildProductoItem(entry.value[index]);
                              },
                            ),
                            SizedBox(height: 80),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
            floatingActionButton: StreamBuilder<int>(
              stream: countTotalOrderedProductsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data! > 0) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        margin: EdgeInsets.only(top: 190, left: 0),
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            onTap: _showCart,
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.9,
                                maxHeight: 49,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                color: Colors.purple, // Cambia el color a púrpura
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.purple.withOpacity(0.3), // Ajusta el color de la sombra
                                    spreadRadius: 5,
                                    blurRadius: 8,
                                    offset: const Offset(0.3, 0.9),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Icon(Icons.shopping_cart, color: Colors.white, size: 15), // Icono del carrito
                                  const Text(
                                    "Ver tu orden",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: "Poppins",
                                      fontSize: 13,
                                    ),
                                  ),
                                  CircleAvatar(
                                    radius: 10,
                                    backgroundColor: Colors.white,
                                    child: Text(
                                      '${snapshot.data!.toString()}',
                                      style: TextStyle(
                                        color: Colors.purple, // Ajusta el color del texto del contador
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  return SizedBox.shrink(); // No muestra nada si no hay productos
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductoItem(QueryDocumentSnapshot producto) {
    // Define un formato para el dinero con separador de miles
    final NumberFormat currencyFormat = NumberFormat('#,##0', 'es_CO');
    ScreenUtil.init(
      context,
      designSize: Size(360, 690),
      minTextAdapt: true,
    );
    // Modificado el padding para desplazar un poco a la derecha la tarjeta
    return Padding(
      padding: const EdgeInsets.fromLTRB(15.0, 8.0, 13.0, 8.0), // Ajuste de espacios uniforme
      child: InkWell(
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white, // Color de fondo del contenedor
                borderRadius: BorderRadius.circular(10.0), // Borde redondeado
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 0.05,
                    blurRadius: 1,
                    offset: const Offset(0, 0), // Sombra para profundidad
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 10),
                          Text(
                            producto['NOMBRE_DEL_PRODUCTO'] as String,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: "Poppins-Bold", fontSize: 13.5),
                          ),
                          Text(
                            producto['descripcion'] as String,
                            style: const TextStyle(fontSize: 10.7, fontFamily: "Poppins", fontWeight: FontWeight.bold, color: Color.fromARGB(255, 116, 116, 116)),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                          SizedBox(height: 5),
                          Text(
                            '\$${currencyFormat.format(producto['precio'])}',
                            style: const TextStyle(fontSize: 10.7, fontFamily: "Poppins", fontWeight: FontWeight.w600, color: Color.fromARGB(255, 122, 122, 122)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(10.0),
                      bottomRight: Radius.circular(10.0),
                    ),
                    child: Image.network(
                      producto['url'] as String,
                      width: 120, // Ancho ajustado para hacerlo más estrecho
                      height: 109, // Altura igualada
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 5,
              right: 5,
              child: Container(
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('+', style: TextStyle(fontSize: 15, color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCart() {
    // Lógica para mostrar el carrito de compras
  }

  TextStyle myTextStyle() {
    return TextStyle(
      fontFamily: "Poppins-l",
      fontSize: 13.sp, // 'sp' escala automáticamente el tamaño del texto según la pantalla
      color: Colors.white,
      overflow: TextOverflow.ellipsis,
    );
  }

  Stream<int> countTotalOrderedProductsStream() {
    return FirebaseFirestore.instance.collection('orders').doc('orderId').snapshots().map((snapshot) {
      if (snapshot.exists) {
        final orderData = snapshot.data() as Map<String, dynamic>;
        int totalCount = 0;

        // Count each product
        orderData.forEach((key, items) {
          if (items is List) {
            for (var item in items) {
              if (item is Map<String, dynamic> && item.containsKey('productName')) {
                totalCount++;
              }
            }
          }
        });

        return totalCount; // Returning the total count of products
      } else {
        return 0; // Return 0 if no data exists
      }
    });
  }
}

void main() {
  runApp(MaterialApp(
    home: MenuHomePage(menuUrl: 'Orderly/restaurantes/restaurantes/El corral'),
  ));
}

// ignore_for_file: must_be_immutable, non_constant_identifier_names, use_key_in_widget_constructors, library_private_types_in_public_api, prefer_const_constructors, avoid_print, unused_field, prefer_final_fields, no_leading_underscores_for_local_identifiers, sort_child_properties_last, deprecated_member_use, unnecessary_to_list_in_spreads, prefer_interpolation_to_compose_strings

import 'dart:async';
import 'dart:math';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

class MENU extends StatefulWidget {
  final String menuUrl;
  final String scannedResult;
  final String photoUrl;
  final String restaurantName;
  final String resDescription;

  const MENU(
    this.scannedResult,
    this.photoUrl,
    this.menuUrl,
    this.restaurantName,
    this.resDescription,
  );

  @override
  _MENUState createState() => _MENUState();
}

class _MENUState extends State<MENU> {
  final ShoppingCart _shoppingCart = ShoppingCart();
  late Timer _timer;
  late Future<DocumentSnapshot> _restaurantDataFuture;
  late Future<DocumentSnapshot> _bannersDataFuture;
  late Future<QuerySnapshot> _menuDataFuture;
  late List<QueryDocumentSnapshot> _menuData; // Variable para almacenar los datos del menú
  int _cartItemCount = 0;
  bool _isFirstTimeOpen = true;

  // Definir _selectedAdditionals para almacenar los adicionales seleccionados
  List<String> _selectedAdditionals = [];

  @override
  void initState() {
    super.initState();
    _restaurantDataFuture = _fetchRestaurantData();
    _bannersDataFuture = _fetchBannersData();
    _menuDataFuture = _fetchMenuData().then((snapshot) {
      _menuData = snapshot.docs; // Almacenar los datos del menú cuando estén disponibles
      return snapshot;
    });
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  // Funciones para obtener datos de Firestore
  Future<DocumentSnapshot> _fetchRestaurantData() async {
    return FirebaseFirestore.instance
        .collection('Orderly')
        .doc('restaurantes')
        .collection('restaurantes')
        .doc(widget.restaurantName)
        .get();
  }

  Future<DocumentSnapshot> _fetchBannersData() async {
    return FirebaseFirestore.instance
        .collection('Orderly')
        .doc('restaurantes')
        .collection('restaurantes')
        .doc('El corral')
        .collection('banners')
        .doc('banners')
        .get();
  }

  Future<QuerySnapshot> _fetchMenuData() async {
    return FirebaseFirestore.instance
        .collection(widget.menuUrl)
        .orderBy('pos')
        .get();
  }

  // Iniciar temporizador para actualizar los datos de banners periódicamente
  void _startTimer() {
    const tenMinutes = Duration(minutes: 10);
    _timer = Timer.periodic(tenMinutes, (Timer timer) {
      _fetchBannersData();
    });
  }
// Construcción de la interfaz de usuario
@override
Widget build(BuildContext context) {
  // Initialize categoryGroups to group products by category
  Map<String, List<QueryDocumentSnapshot>> categoryGroups = {};

  // Use FutureBuilder to wait for data to load
  return FutureBuilder(
      future: Future.wait([_restaurantDataFuture, _bannersDataFuture, _menuDataFuture]),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          // Check if the data has loaded
          if (!snapshot.hasData) {
              return const Center(
                  child: CircularProgressIndicator(),
              );
          }

          final List<dynamic>? data = snapshot.data;
          if (data == null || data.isEmpty) {
              return const Center(
                  child: Text('No data available'),
              );
          }

          // Get the data from the snapshot
          final restaurantData = data[0] as DocumentSnapshot;
          final bannersData = data[1] as DocumentSnapshot;
          final menuData = data[2] as QuerySnapshot;

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

          // Create the UI
          return DefaultTabController(
              length: categoryGroups.length, // Set the number of tabs based on the number of categories
              child: Scaffold(
                  backgroundColor: Colors.white,
                  body: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                          const SizedBox(height: 30),
                          
                          Column(
  crossAxisAlignment: CrossAxisAlignment.start, // Alinea los elementos a la izquierda
  children: [
    Stack(
      children: [
        // Banner Scroll
        CarouselSlider(
          items: [
            // Aquí puedes agregar los elementos del banner scroll
            Image.network(bannersData['url1'] as String),
            Image.network(bannersData['url2'] as String),
            Image.network(bannersData['url3'] as String),
          ],
          options: CarouselOptions(
            enlargeFactor: 0,
            height: 110,
            enlargeCenterPage: false,
            autoPlay: true,
            aspectRatio: 5.5,
            autoPlayCurve: Curves.fastOutSlowIn,
            enableInfiniteScroll: true,
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            viewportFraction: 0.8,
          ),
        ),

        // Botón de retroceso y foto de usuario de Google
        Positioned(
          top: 8, // Ajusta la posición según tus necesidades
          left: 8,
          child: InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white, // Cambio de color a blanco
                  width: 0.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 4,
                    offset: Offset(0, 2), // Cambia la posición de la sombra según tus necesidades
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back,
                size: 25,
                color: Colors.white, // Cambio de color a blanco
              ),
            ),
          ),
        ),
        Positioned(
          top: 8, // Ajusta la posición según tus necesidades
          right: 8,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 4,
                  offset: Offset(0, 2), // Cambia la posición de la sombra según tus necesidades
                ),
              ],
            ),
            child: CircleAvatar(
              backgroundImage: widget.photoUrl.isNotEmpty ? NetworkImage(widget.photoUrl) : const AssetImage("lib/images/logos/default_avatar.png") as ImageProvider,
            ),
          ),
        ),
      ],
    ),

    // Información del restaurante debajo del Stack
    Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
  mainAxisAlignment: MainAxisAlignment.end,
  children: [
    // Foto del restaurante
    SizedBox(
      width: 60,
      height: 60,
      child: Image.network(
        restaurantData['url'] as String,
        fit: BoxFit.contain,
      ),
    ),
    const SizedBox(width: 7),
    // Nombre del restaurante
    Text(
      restaurantData['nombre_restaurante'] as String,
      style: TextStyle(
        color: Colors.black,
        fontSize: 16,
        fontFamily: "Poppins",
        fontWeight: FontWeight.bold,
      ),
    ),

    const SizedBox(height: 10, width: 110,),
    // Fotos de usuarios en línea
    Expanded(
  child: Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      SizedBox(
        height: 50,
        child: _showOnlineUsers(),
      ),
    ],
  ),
),

  ],
),

          
        ],
      ),
    ),
  ],
),



Center(
  child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Calificación:',
            style: TextStyle(
              color: Color.fromARGB(255, 175, 175, 175),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              fontFamily: "Poppins-l",
            ),
          ),
          Text(
            ' ${restaurantData['calificacion']} ★',
            style: TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.normal,
              fontSize: 11,
            ),
          ),
        ],
      ),
      SizedBox(width: 16), // Ajusta el espaciado según sea necesario
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Entrega:',
            style: TextStyle(
              color: Color.fromARGB(255, 175, 175, 175),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              fontFamily: "Poppins-l",
            ),
          ),
          Text(
            ' ${restaurantData['tiempo_entrega']} min',
            style: TextStyle(
              color: Colors.purple, // Usando purple como un aproximado al morado
              fontWeight: FontWeight.normal,
              fontSize: 11,
            ),
          ),
        ],
      ),
    ],
  ),
),




                          const SizedBox(height: 0),

                          
                          
                          // TabBar with tabs
                          TabBar(
  isScrollable: true,
  indicatorPadding: EdgeInsets.all(2), 
 
  tabs: categoryGroups.keys.map((String category) {
    return Tab(
      text: category,
    );
  }).toList(),
  // Set the text style of the tabs
  labelStyle: TextStyle(
    fontSize: screenWidth * 0.03,
    fontWeight: FontWeight.bold,
    color: Colors.purple,
    fontFamily: 'Poppins-l',
  ),
  unselectedLabelStyle: TextStyle(
    fontSize: screenWidth * 0.0305,
    fontWeight: FontWeight.normal,
    color: Colors.grey,
    fontFamily: 'Poppins',
  ),
),

                          // TabBarView to display content for each category
                          Expanded(
                              child: TabBarView(
                                  children: categoryGroups.entries.map((entry) {
                                      return SingleChildScrollView(
                                          child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                  Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
                                                  ),
                                                  // Display products of the category in a 2-column grid layout
                                                  // Adjust GridView.builder
                                                  GridView.builder(
                                                      shrinkWrap: true,
                                                      physics: const NeverScrollableScrollPhysics(),
                                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                                          crossAxisCount: gridCount,
                                                          childAspectRatio: 0.65,
                                                          crossAxisSpacing: 0.0,
                                                          mainAxisSpacing: 1.0,
                                                      ),
                                                      itemCount: entry.value.length,
                                                      itemBuilder: (context, index) {
                                                          return _buildProductoItem(entry.value[index]);
                                                      },
                                                  ),

                                              ],
                                          ),
                                      );
                                  }).toList(),
                              ),
                          ),
                      ],
                  ),
                  floatingActionButton: Padding(
    padding: EdgeInsets.all(1), // Adds padding to the right to move the button to the left
    child: InkWell(
        onTap: () {
            _showCart();
        },
        child: Container(
            constraints: BoxConstraints(
                maxWidth: 380, // Set a maximum width for the container
                minHeight: 48, // Set a minimum height for the container
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.purple,
                boxShadow: [
                    BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                    ),
                ],
            ),
            child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                    const Icon(Icons.shopping_cart, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                        "Ver tu orden",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: "Poppins-l"),
                    ),
                    StreamBuilder<int>(
                        stream: countTotalOrderedProductsStream(),
                        builder: (context, snapshot) {
                            Widget indicator = snapshot.hasData && snapshot.data! > 0 ?
                                Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                    ),
                                    constraints: BoxConstraints(
                                        minWidth: 20,
                                        minHeight: 20,
                                    ),
                                    child: Text(
                                        snapshot.data!.toString(),
                                        style: const TextStyle(color: Colors.purple, fontSize: 12),
                                        textAlign: TextAlign.center,
                                    ),
                                ) : SizedBox(width: 20, height: 20); // Use a fixed-size empty box to keep layout consistent

                            return indicator;
                        }
                    ),
                ],
            ),
        ),
    )
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
        padding: const EdgeInsets.fromLTRB(30.0, 8.0, 8.0, 8.0),  // Aumentado el espacio a la izquierda
        child: Stack(
            children: [
                Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20.0),
                                border: Border.all(color: const Color.fromARGB(255, 235, 235, 235)),
                            ),
                            child: SizedBox(
                                width: 130,
                                height: 160,
                                child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20.0),
                                    child: Image.network(
                                        producto['url'] as String,
                                        fit: BoxFit.cover,
                                    ),
                                ),
                            ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                            width: 150,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    Text(
                                        producto['NOMBRE_DEL_PRODUCTO'] as String,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: "Poppins-l", fontSize: 11),
                                    ),
                                    const SizedBox(height: 0),
                                    SizedBox(
                                        width: 150,
                                        child: Text(
                                            producto['descripcion'] as String,
                                            style: const TextStyle(fontSize: 10, fontFamily: "Poppins", color: Colors.grey),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 3,
                                        ),
                                    ),
                                ],
                            ),
                        ),
                        const SizedBox(height: 0),
                        // Formatea el precio usando el formato definido
                        Text(
                            '\$${currencyFormat.format(producto['precio'])}',
                            style: const TextStyle(fontSize: 12, fontFamily: "Poppins-l", fontWeight: FontWeight.bold, color: Colors.purple),
                        ),
                    ],
                ),
                Positioned(
                    top: 0,
                    right: 10,
                    child: InkWell(
                        onTap: () {
                            _showAditionalsScreen(producto['adiciones'], producto);
                        },
                        child: Container(
                            padding: const EdgeInsets.all(6.0),
                            decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 247, 253, 246),
                                borderRadius: BorderRadius.circular(25.0),
                                border: Border.all(
                                    color: Colors.green, // Color del contorno igual al del icono '+'
                                    width: 5.0 // Grosor del borde
                                ),
                                boxShadow: [
                                    BoxShadow(
                                        color: Colors.grey.withOpacity(0.5),
                                        spreadRadius: 1,
                                        blurRadius: 3,
                                        offset: const Offset(0,0),
                                    ),
                                ],
                            ),
                            child: const Icon(Icons.add, color: Colors.green,),
                        )

                                            ),
                                        ),
                                    ],
                                ),
                            );
                        }

                        List<OrderDetails> orders = [];

void _showAditionalsScreen(String producto, QueryDocumentSnapshot orden) {
                            String nombreOrden = orden['NOMBRE_DEL_PRODUCTO'] as String;
                            String descripcionOrden = orden['descripcion'] as String;
                            int precioOrden = orden['precio'] as int;
                            String urlOrden = orden['url'] as String;
                            Map<String, bool> firstItemSelected = {};

                            // Formateador para los números con separador de miles
                            final formatter = NumberFormat('#,###', 'es_ES');

                            // Inicializar el precio total con el precio base de la orden
                            double precioTotal = precioOrden.toDouble();

                            // Variable específica para cada pantalla para almacenar los elementos seleccionados
                            Set<String> _selectedAditionals = {};

                            FirebaseFirestore.instance.collection(producto).get().then((querySnapshot) {
                                Map<String, List<DocumentSnapshot>> categorias = {};
                                for (var doc in querySnapshot.docs) {
                                    String status = doc['status'];
                                    if (!categorias.containsKey(status)) {
                                        categorias[status] = [];
                                    }
                                    categorias[status]!.add(doc);
                                    if (status.toLowerCase().contains("obligatorio") && (firstItemSelected[status] == null || !firstItemSelected[status]!)) {
        firstItemSelected[status] = true;  // Marcar que ya se ha preseleccionado un item para esta categoría
        _selectedAditionals.add(doc['nombre']);  // Añadir a los seleccionados
        precioTotal += doc['precio'];  // Añadir su precio al total
      }
                                }

                                showModalBottomSheet<void>(
                                    context: context,
                                    isScrollControlled: true,
                                    builder: (BuildContext context) {
                                        return StatefulBuilder(
                                            builder: (BuildContext context, StateSetter setState) {
                                                return Stack(
                                                    children: [
                                                        SingleChildScrollView(
                                                            child: Container(
                                                                padding: EdgeInsets.all(10),
                                                                decoration: BoxDecoration(
                                                                    borderRadius: BorderRadius.only(
                                                                        topLeft: Radius.circular(20),
                                                                        topRight: Radius.circular(20),
                                                                    ),
                                                                    color: Colors.white,
                                                                ),
                                                                child: Column(
                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                    children: [
                                                                        
                                                                        Container(
                          
                          width: MediaQuery.of(context).size.width * 0.95, // Ancho del contenedor, ajustable según necesidades
                          margin: EdgeInsets.all(8.0), // Margen alrededor del contenedor para separación
                          decoration: BoxDecoration(
                            color: Colors.white,
                            
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center, // Alinea los elementos en el centro horizontalmente
                            children: [
  // Stack para la imagen, precio y botón de cierre
  Stack(
    children: [
      // Imagen del producto
      Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.width * 0.45,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          image: DecorationImage(
            image: NetworkImage(urlOrden),
            fit: BoxFit.cover,
          ),
        ),
      ),
      // Botón de cierre en la esquina superior izquierda
      Positioned(
        top: 16,
        left: 16,
        child: GestureDetector(
          onTap: () {
            Navigator.pop(context); // Cerrar el modal actual o widget
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white, // Fondo blanco para mejor visibilidad
              borderRadius: BorderRadius.circular(10), // Bordes redondeados
            ),
            child: Icon(
              Icons.close, // Icono de cierre
              color: Colors.black,
            ),
            padding: EdgeInsets.all(4), // Padding alrededor del icono
          ),
        ),
      ),
      // Precio en la esquina superior derecha
      Positioned(
        top: 16,
        right: 16,
        child: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            '\$${formatter.format(precioOrden)}',
            style: TextStyle(
              fontSize: 12 * MediaQuery.of(context).textScaleFactor,
              fontFamily: "Poppins-l",
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
        ),
      ),
    ],
  ),
  SizedBox(height: 8), // Espacio entre la imagen y la descripción
  // Descripción de la orden
  Container(
  width: double.infinity, // Asegura que el contenedor ocupe todo el ancho disponible
  alignment: Alignment.centerLeft, // Alinea el texto a la izquierda
  child: Text(
    nombreOrden,
    style: TextStyle(
      fontSize: 16 * MediaQuery.of(context).textScaleFactor,
      fontFamily: "Poppins",
      fontWeight: FontWeight.bold
    ),
  ),
),



SizedBox(height: 8),
  Text(
    descripcionOrden,
    textAlign: TextAlign.left,
    style: TextStyle(
      fontSize: 11 * MediaQuery.of(context).textScaleFactor,
      fontFamily: "Poppins",
    ),
  ),
  SizedBox(height: 10), // Espacio adicional
],

                          ),
                        ),

                                                SizedBox(height: 0),
                                                // Selección de productos adicionales
                                                Text(
                                                    '  Personaliza tu orden:',
                                                    style: TextStyle(
                                                        fontSize: 14 * MediaQuery.of(context).textScaleFactor,
                                                        fontWeight: FontWeight.bold,
                                                        fontFamily: "Poppins-l",
                                                    ),
                                                ),
                                                SizedBox(height: 5),
                                                SizedBox(
                                                  height: 290,
                                                // Envuelve la Columna generada dentro de un SingleChildScrollView
child:SingleChildScrollView(
  child: Column(
    
    children: categorias.entries.map((category) => Container(
      margin: EdgeInsets.only(top: 10, bottom: 5),
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight, // Alinea el Container a la derecha
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 1), // Espacio interno para el texto
              decoration: BoxDecoration(
                color: Colors.black, // Fondo negro para el contenedor del texto
                borderRadius: BorderRadius.circular(10), // Bordes ligeramente redondeados
              ),
              child: Text(
                category.key,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Poppins-l",
                  color: Colors.white, // Texto en color blanco
                ),
              ),
            ),
          ),
          ...category.value.map((adicional) {
            bool isSelected = _selectedAditionals.contains(adicional['nombre']);
            return _buildAdditionalTile(adicional, (int precioAdicional, bool selected) {
              setState(() {
                if (selected) {
                  precioTotal += precioAdicional;
                  _selectedAditionals.add(adicional['nombre']);
                } else {
                  precioTotal -= precioAdicional;
                  _selectedAditionals.remove(adicional['nombre']);
                }
              });
            },  isSelected);
          }).toList(),
        ],
      ),
    )).toList(),
  ),
)
,
                                                ),
                                                SizedBox(height: 50),
                                            ],
                                        ),
                                    ),
                                ),
                                Positioned(
                                    bottom: 10,
                                    left: 20,
                                    right: 20,
                                    child: GestureDetector(
                                        onTap: () async {
  // Generar un ID único para la orden
  String orderId = Uuid().v4();

  // Lógica para agregar la orden a Firestore
  List<String> urlSegments = widget.scannedResult.split("/");
  String firestorepath1 = "/"+urlSegments[1] +"/"+urlSegments[2] +"/"+ urlSegments[3]+"/"+urlSegments[4] +"/"+urlSegments[5]+"/"+urlSegments[6] +"/"+urlSegments[7];
  String firestorepath2 = urlSegments[8];
  String firebaseuid = FirebaseAuth.instance.currentUser!.uid;
  final userOrderRef = FirebaseFirestore.instance.collection(firestorepath1).doc(firestorepath2);

  // Mapa de datos para la orden con el ID único
  Map<String, dynamic> orderData = {
    'orderId': orderId, // Agregar el campo de ID único
    'OrderUrl': widget.scannedResult,
    'photouser': widget.photoUrl,
    'productName': nombreOrden,
    'description': descripcionOrden,
    'imageUrl': urlOrden,
    'price': precioTotal,
    'selectedAdditionals': _selectedAditionals.map((ad) {
      return {
        'name': ad,
        'price': categorias.values.expand((el) => el).firstWhere((item) => item['nombre'] == ad)['precio'],
        'photo': categorias.values.expand((el) => el).firstWhere((item) => item['nombre'] == ad)['url'] as String,
      };
    }).toList(),
  };

  // Guardar la orden en Firestore
  userOrderRef.update({
    firebaseuid: FieldValue.arrayUnion([orderData])
  }).then((_) {
    print('La orden se ha guardado correctamente en Firestore.');
  }).catchError((error) {
    print('Error al guardar la orden en Firestore: $error');
  });

  // Limpiar elementos seleccionados y precio total
  setState(() {
    _selectedAditionals.clear();
    precioTotal = precioOrden.toDouble();
  });

  // Cerrar la pantalla de selección de adicionales
  Navigator.pop(context);
},

                                        child: Container(
  width: MediaQuery.of(context).size.width * 0.5,
  padding: EdgeInsets.symmetric(horizontal: 2, vertical: 12),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(22),
    color: Colors.purple,
    boxShadow: [
      BoxShadow(
        color: Colors.grey.withOpacity(0.5),
        spreadRadius: 2,
        blurRadius: 5,
        offset: Offset(0, 3),
      ),
    ],
  ),
  child: Center(
    child: Row(
      mainAxisSize: MainAxisSize.min,  // Usa el espacio mínimo necesario para los hijos
      mainAxisAlignment: MainAxisAlignment.start,  // Alinea los widgets al inicio del Row
      children: [
        Text(
          'Agregar a la orden',
          style: myTextStyle(),
        ),
        SizedBox(width: 8),  // Controla este espacio para ajustar la cercanía de los textos
        Text(
          '\$${formatter.format(precioTotal)}',
          style: TextStyle(
            fontFamily: "Poppins-l",
            fontSize: 14 * MediaQuery.of(context).textScaleFactor,
            fontWeight: FontWeight.bold,
            color: Colors.white,
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
                    },
                );
            },
        );
    });
}

TextStyle myTextStyle() {
  return TextStyle(
    fontFamily: "Poppins-l",
    fontSize: 13.sp, // 'sp' escala automáticamente el tamaño del texto según la pantalla
    color: Colors.white,
    overflow: TextOverflow.ellipsis,
  );
}

Widget _buildAdditionalTile(DocumentSnapshot adicional, Function(int, bool) onSelectionChanged, bool isSelected) {
  return Container(
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1)),
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
    ),
    child: ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 1),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          adicional['url'] as String,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
        ),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              adicional['nombre'] as String,
              style: TextStyle(
                fontFamily: "Poppins-l",
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            '\$${adicional['precio']}',
            style: TextStyle(
              fontFamily: "Poppins",
              fontSize: 11,
              color: Colors.grey[800],
            ),
          ),
          Icon(
            isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isSelected ? Colors.green : Colors.grey,
          ),
        ],
      ),
      onTap: () => onSelectionChanged(adicional['precio'], !isSelected),
    ),
  );
}



void _showCart() {
    List<String> urlSegments = widget.scannedResult.split("/");

    String firestorepath1 = "/${urlSegments[1]}/${urlSegments[2]}/${urlSegments[3]}/${urlSegments[4]}/${urlSegments[5]}/${urlSegments[6]}/${urlSegments[7]}";
    String firestorepath2 = urlSegments[8];

    String firebaseuid = FirebaseAuth.instance.currentUser!.uid;

    NumberFormat formatter = NumberFormat("#,##0", "es_ES");

    showModalBottomSheet<void>(
    context: context,
    builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (context, setState) {
                return Container(
                    height: MediaQuery.of(context).size.height * 0.5, // Establece la altura a la mitad de la pantalla
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(25),
                            topRight: Radius.circular(25),
                        ),
                        boxShadow: [
                            BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 5,
                                blurRadius: 7,
                                offset: Offset(0, 3),
                            ),
                        ],
                    ),
                    child: StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance.collection(firestorepath1).doc(firestorepath2).snapshots(),
                        builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                                return Center(child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                                return Center(child: Text('Error: ${snapshot.error}'));
                            } else if (!snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
                                return Center(child: Text('No se encontraron datos'));
                            } else {
                                final orderData = snapshot.data!.data() as Map<String, dynamic>;

                                Map<String, List<Map<String, dynamic>>> groupedItems = {};

                                for (String key in orderData.keys) {
                                    final itemList = orderData[key];
                                    if (itemList is Iterable) {
                                        for (var item in itemList) {
                                            if (item is Map<String, dynamic>) {
                                                String photouser = item['photouser'];
                                                if (groupedItems.containsKey(photouser)) {
                                                    groupedItems[photouser]?.add(item);
                                                } else {
                                                    groupedItems[photouser] = [item];
                                                }
                                            }
                                        }
                                    }
                                }

                                return Container(
                                    padding: EdgeInsets.all(10),
                                    child: ListView.builder(
                                        itemCount: groupedItems.length,
                                        itemBuilder: (context, index) {
                                            final photouserKey = groupedItems.keys.elementAt(index);
                                            final itemsForUser = groupedItems[photouserKey];
                                            double totalPrice = itemsForUser!.fold(0.0, (sum, item) => sum + item['price'] + (item['selectedAdditionals'] as List<dynamic>).fold(0.0, (sum, additional) => sum + additional['price']));

                                            return Card(
                                                elevation: 0.0,
                                                color: Colors.white,
                                                margin: EdgeInsets.symmetric(vertical: 8.0),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(15.0),
                                                    side: BorderSide(color: const Color.fromARGB(255, 238, 238, 238)),
                                                ),
                                                child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                        Padding(
                                                            padding: EdgeInsets.all(8.0),
                                                            child: Row(
                                                                children: [
                                                                    if (photouserKey != null)
                                                                        CircleAvatar(
                                                                            radius: 15,
                                                                            backgroundImage: NetworkImage(photouserKey),
                                                                            backgroundColor: Colors.transparent,
                                                                        ),
                                                                    SizedBox(width: 10),
                                                                    Text(
                                                                        'Total a pagar: \$${formatter.format(totalPrice)}',
                                                                        style: TextStyle(fontFamily: "Poppins-l", fontSize: 12, fontWeight: FontWeight.bold),
                                                                    ),
                                                                    Spacer(),
                                                                    IconButton(
                                                                        icon: Icon(Icons.close),
                                                                        onPressed: () {
                                                                            setState(() {
                                                                                groupedItems.remove(photouserKey);
                                                                                FirebaseFirestore.instance.collection(firestorepath1).doc(firestorepath2).update({
                                                                                    firebaseuid: FieldValue.arrayRemove(itemsForUser),
                                                                                }).then((_) {
                                                                                    print('Item eliminado correctamente de Firebase.');
                                                                                }).catchError((error) {
                                                                                    print('Error al eliminar item de Firebase: $error');
                                                                                });
                                                                            });
                                                                        },
                                                                    ),
                                                                ],
                                                            ),
                                                        ),
                                                        ...itemsForUser.map((item) {
                                                            return ListTile(
                                                                leading: Container(
                                                                    decoration: BoxDecoration(
                                                                        borderRadius: BorderRadius.circular(8.0),
                                                                        border: Border.all(color: Color.fromARGB(255, 241, 241, 241)),
                                                                    ),
                                                                    child: ClipRRect(
                                                                        borderRadius: BorderRadius.circular(8.0),
                                                                        child: Image.network(
                                                                            item['imageUrl'],
                                                                            height: 50,
                                                                            width: 50,
                                                                            fit: BoxFit.fill,
                                                                        ),
                                                                    ),
                                                                ),
                                                                title: Text(
                                                                    item['productName'],
                                                                    style: TextStyle(fontFamily: "Poppins-l", fontSize: 13, fontWeight: FontWeight.bold),
                                                                ),
                                                                subtitle: Column(
                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                    children: [
                                                                        Text(
                                                                            'Precio: \$${formatter.format(item['price'])}',
                                                                            style: TextStyle(fontFamily: "Poppins-l", fontSize: 11, fontWeight: FontWeight.bold),
                                                                        ),
                                                                        if (item['selectedAdditionals'] != null && item['selectedAdditionals'] is Iterable)
                                                                            ...item['selectedAdditionals'].map<Widget>((additional) {
                                                                                return Row(
                                                                                    children: [
                                                                                        Container(
                                                                                            decoration: BoxDecoration(
                                                                                                borderRadius: BorderRadius.circular(8.0),
                                                                                                border: Border.all(color: Colors.grey.shade300),
                                                                                            ),
                                                                                            child: ClipRRect(
                                                                                                borderRadius: BorderRadius.circular(8.0),
                                                                                                child: Image.network(
                                                                                                    additional['photo'],
                                                                                                    height: 30,
                                                                                                    width: 30,
                                                                                                    fit: BoxFit.cover,
                                                                                                ),
                                                                                            ),
                                                                                        ),
                                                                                        SizedBox(width: 10),
                                                                                        Column(
                                                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                                                            children: [
                                                                                                Text(
                                                                                                    'Adicional: ${additional['name']}',
                                                                                                    style: TextStyle(fontFamily: "Poppins-l", fontSize: 11, fontWeight: FontWeight.bold),
                                                                                                ),
                                                                                                Text(
                                                                                                    'Precio: \$${formatter.format(additional['price'])}',
                                                                                                    style: TextStyle(fontFamily: "Poppins-l", fontSize: 11, fontWeight: FontWeight.bold),
                                                                                                ),
                                                                                            ],
                                                                                        ),
                                                                                    ],
                                                                                );
                                                                            }).toList(),
                                                                    ],
                                                                ),
                                                            );
                                                        }).toList(),
                                                    ],
                                                ),
                                            );
                                        },
                                    ),
                                );
                            }
                        },
                    ),
                );
            },
        );
    },
);

}

Stream<int> countTotalOrderedProductsStream() {
    List<String> urlSegments = widget.scannedResult.split("/");

    String firestorePath1 = "/${urlSegments[1]}/${urlSegments[2]}/${urlSegments[3]}/${urlSegments[4]}/${urlSegments[5]}/${urlSegments[6]}/${urlSegments[7]}";
    String firestorePath2 = urlSegments[8];

    return FirebaseFirestore.instance.collection(firestorePath1).doc(firestorePath2).snapshots().map((snapshot) {
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



Widget _showOnlineUsers() {
  List<String> urlSegments = widget.scannedResult.split("/");

  String firestorepath1 = "/${urlSegments[1]}/${urlSegments[2]}/${urlSegments[3]}/${urlSegments[4]}/${urlSegments[5]}/${urlSegments[6]}/${urlSegments[7]}";
  String firestorepath2 = urlSegments[8];

  return StreamBuilder<DocumentSnapshot>(
    stream: FirebaseFirestore.instance.collection(firestorepath1).doc(firestorepath2).snapshots(),
    builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return CircularProgressIndicator();
      } else if (snapshot.hasError) {
        return Text('Error: ${snapshot.error}');
      } else if (!snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
        return Text('No se encontraron datos');
      } else {
        final orderData = snapshot.data!.data() as Map<String, dynamic>;

        Set<String> uniqueUserPhotos = Set<String>();

        for (String key in orderData.keys) {
          final itemList = orderData[key];

          if (itemList is Iterable) {
            for (var item in itemList) {
              if (item is Map<String, dynamic>) {
                String photouser = item['photouser'];
                if (photouser != null && photouser.contains("google")) {
                  uniqueUserPhotos.add(photouser);
                }
              }
            }
          }
        }

        List<String> googleUsers = uniqueUserPhotos.toList();

        // Invierte el orden de la lista googleUsers
        googleUsers = googleUsers.reversed.toList();

        if (googleUsers.length >= 4) {
          // Mostrar círculo con símbolo "+" y número de personas adicionales
          return Row(
            children: [
              // Muestra los primeros 4 usuarios
              for (int i = 0; i < 4; i++)
                Padding(
                  padding: const EdgeInsets.all(0.0),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(googleUsers[i]),
                    backgroundColor: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color.fromARGB(255, 241, 241, 241)),
                      ),
                    ),
                  ),
                ),
              // Círculo con símbolo "+" y número de personas adicionales
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey, // Cambia el color según tus necesidades
                ),
                child: Center(
                  child: Text(
                    "+${googleUsers.length - 4}",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          );
        } else {
          // Mostrar las fotos de los usuarios
          return Row(
            children: [
              for (String userPhoto in googleUsers)
                Padding(
                  padding: const EdgeInsets.all(0.5),
                  child: CircleAvatar(
                    radius: 15,
                    backgroundImage: NetworkImage(userPhoto),
                    backgroundColor: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color.fromARGB(255, 241, 241, 241)),
                      ),
                    ),
                  ),
                ),
            ],
          );
        }
      }
    },
  );
}


}

void main() {
  runApp(MaterialApp(
    home: MENU(
      'menu',
      'photoUrl',
      'MenuUrl',
      'RestaurantName',
      'ResDescription',
    ),
  ));
}

// ignore_for_file: must_be_immutable, non_constant_identifier_names, use_key_in_widget_constructors, library_private_types_in_public_api, prefer_const_constructors, avoid_print, unused_field, prefer_final_fields, no_leading_underscores_for_local_identifiers, sort_child_properties_last, deprecated_member_use, unnecessary_to_list_in_spreads, prefer_interpolation_to_compose_strings

import 'dart:async';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  late List<ExpandedTileController> _controllers; // Cambio a lista de controladores
  int total_obligatoriox = 0;
 

  // Definir _selectedAdditionals para almacenar los adicionales seleccionados
  List<String> _selectedAdditionals = [];
  int totalSelected = 0;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(10, (_) => ExpandedTileController(isExpanded: true));
     // Inicializa la lista de controladores
    
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
          return StreamBuilder<DocumentSnapshot> (
            stream: managerPayStream(),
            builder: ( context, streamSnapshot) {
              if (streamSnapshot.hasError) {
                print("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA");
                return Text("Error: ${streamSnapshot.error}");
              }
              if (streamSnapshot.connectionState == ConnectionState.waiting) {
                return LoadingAnimationWidget.twistingDots(
                          leftDotColor: const Color(0xFF1A1A3F),
                          rightDotColor: Color.fromARGB(255, 198, 55, 234),
                          size: 50,
                        );
              }

              // Actualizar la UI basado en los cambios en tiempo real
              List<dynamic> managerPay = (streamSnapshot.data?.data() as Map<String, dynamic>)['ManagerPay'] ?? [];
              print("ManagerPay actualizado con ${managerPay.length} elementos");
              print(managerPay);

              bool userInList = managerPay.any((item) => item['UserId'] == FirebaseAuth.instance.currentUser!.uid && item['WillPay'] == true);
              bool usernotInList = managerPay.any((item) => item['UserId'] == FirebaseAuth.instance.currentUser!.uid && item['WillPay'] == false);

              if (userInList) {
                  // Usando Future.microtask para evitar excepciones de modificación de estado durante la construcción
                  Future.microtask(() =>
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => PaymentOrder(InvoiceProductsStream(), widget.scannedResult)))
                  );
              } 

              if (usernotInList) {
                  // Usando Future.microtask para evitar excepciones de modificación de estado durante la construcción
                  Future.microtask(() =>
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => NoPayWaiting()))
                  );
              } 
              

              // if (managerPay.contains(FirebaseAuth.instance.currentUser!.uid)) {
              //   // Usando Future.microtask para evitar excepciones de modificación de estado durante la construcción
              //     Future.microtask(() =>
              //     Navigator.of(context).push(MaterialPageRoute(builder: (context) => PaymentOrder(InvoiceProductsStream())))
              //   );
              // }




              return DefaultTabController(
              length: categoryGroups.length, // Set the number of tabs based on the number of categories
              child: Scaffold(
                  backgroundColor: Color.fromARGB(255, 255, 255, 255),
                  body: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                          
                          Column(
  crossAxisAlignment: CrossAxisAlignment.start, // Alinea los elementos a la izquierda
  children: [

Stack(
  children: <Widget>[
    // Imagen principal dentro de un Container y ClipRRect
   Container(
  margin: EdgeInsets.only(bottom: 20, left: 0),
  decoration: BoxDecoration(
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.2), // Color de la sombra
        spreadRadius: 2, // Radio de expansión
        blurRadius: 7, // Radio de desenfoque
        offset: Offset(0, 3), // Desplazamiento de la sombra
      ),
    ],
  ),
  child: ClipRRect(
    borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
    child: Image.network(restaurantData['banner'] as String),
  ),
),

    // Posicionar el CircleAvatar en la esquina inferior izquierda
    Positioned(
  left: 15,
  bottom: 0,
  child: Row(
    children: [
      Container(
        width: 64.0,
        height: 64.0,
        decoration: BoxDecoration(
          color: Colors.white, // Fondo blanco
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white, // Color del borde
            width: 2.0, // Ancho del borde
          ),
        ),
        child: CircleAvatar(
          radius: 30.0,
          backgroundImage: NetworkImage(restaurantData['url'] as String),
          backgroundColor: Colors.transparent, // Fondo transparente
        ),
      ),
      SizedBox(width: 210,),
    ],
  ),
),


    
        Positioned(
          top: 25, // Ajusta la posición según tus necesidades
          left: 15,
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
        margin: EdgeInsets.only(top: 7,left: 0),
        color: const Color.fromARGB(0, 255, 255, 255),
        padding: const EdgeInsets.all(0.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(width: 15,),
                // Foto del restaurante
                

                
                Container(
                  padding: EdgeInsets.all(9), // Espacio interno de la caja
                  decoration: BoxDecoration(
                    color: Colors.white, // Color de fondo de la caja
                    borderRadius: BorderRadius.circular(12), // Bordes redondeados
                    border: Border.all(color: Color.fromARGB(255, 224, 224, 224), width: 1), // Borde negro
                  ),
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
                              fontSize: 19.9,
                              fontFamily: "Insanibc",
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                          Row(
                            children: [
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
                                        color: Color.fromARGB(255, 53, 53, 53),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 10), // Espacio entre calificación y entrega
                              // Tiempo de entrega
                              Image.asset("lib/images/animations/clock.gif", height: 20, width: 20),
                              SizedBox(width: 2),
                              Text(
                                '${restaurantData['tiempo_entrega']} min',
                                style: TextStyle(
                                  color: Color.fromARGB(255, 53, 53, 53),
                                  fontSize: 10.8,
                                  fontFamily: "Poppins",
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            '${restaurantData['descripcion']}',
                            style: TextStyle(
                              color: Color.fromARGB(255, 53, 53, 53),
                              fontSize: 13.5,
                              fontFamily: "Poppins",
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          SizedBox(height: 10),
                        ],
                      ),
                    ],
                  ),
                )
                                
              ],
            ),

            
            

                    TabBar(
              tabAlignment: TabAlignment.center,
              indicatorColor: Colors.purple,
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

        
      ),
  
  ],
),
//AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAa
                          
                          
                       // TabBar with tabs
                        // Asegurándote de que el TabBar no tenga padding innecesario
    


                              // TabBarView to display content for each category
                              Expanded(
                                  child: TabBarView(
                                      children: categoryGroups.entries.map((entry) {
                                          return SingleChildScrollView(
                                              child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                      
                                                      // Display products of the category in a 2-column grid layout
                                                      // Adjust GridView.builder
                                                      ListView.builder(
                                                        
                                                      shrinkWrap: true,
                                                      physics: const NeverScrollableScrollPhysics(), // Asegura que la lista no sea desplazable si no es necesario
                                                      itemCount: entry.value.length,
                                                      itemBuilder: (context, index) {
                                                        return _buildProductoItem(entry.value[index]);
                                                      },
                                                    ),
                                                     SizedBox( height: 80,)


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
                    maxWidth: MediaQuery.of(context).size.width * 0.88,
                    minHeight: 45,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.purple, // Cambia el color a púrpura
                    // boxShadow: [
                    //   BoxShadow(
                    //     color: Colors.purple.withOpacity(0.3), // Ajusta el color de la sombra
                    //     spreadRadius: 5,
                    //     blurRadius: 8,
                    //     offset: const Offset(0.3, 0.9),
                    //   ),
                    // ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(Icons.shopping_cart, color: Colors.white, size: 18), // Icono del carrito
                      
                        const
                          
                          Text(
                            "Ver tu orden",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontFamily: "Poppins",
                              fontSize: 14,
                            ),
                          ),
                          
                        
                      
                      CircleAvatar(
                        radius: 11,
                        backgroundColor: Colors.white,
                        child: Text(
                          '${snapshot.data!.toString()}',
                          style: TextStyle(
                            color: Colors.purple, // Ajusta el color del texto del contador
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
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

            }
          
          
          );
          // Create the UI
          
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
    padding: const EdgeInsets.fromLTRB(15.0, 8.0, 13.0, 8.0),  // Ajuste de espacios uniforme
    child: InkWell(
      onTap: () {
        _showAditionalsScreen(producto['adiciones'], producto);
      },
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white, // Color de fondo del contenedor
              borderRadius: BorderRadius.circular(10.0), // Borde redondeado
              boxShadow: [
                BoxShadow(
                  color: Color.fromARGB(255, 172, 172, 172).withOpacity(1.0),
                  spreadRadius: 0,
                  blurRadius: 1,
                  offset: const Offset(0, 0),  // Sombra para profundidad
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
                        SizedBox(height: 10,),
                        Text(
                          producto['NOMBRE_DEL_PRODUCTO'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: "Poppins-Bold", fontSize: 13.5),
                        ),
                        //SizedBox(height: 4),
                        Text(
                          producto['descripcion'] as String,
                          style: const TextStyle(fontSize: 10.7, fontFamily: "Poppins", fontWeight: FontWeight.bold, color: Color.fromARGB(255, 116, 116, 116)),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        SizedBox(height: 5),
                        Text(
                          '\$${currencyFormat.format(producto['precio'])}',
                          style: const TextStyle(fontSize: 10.5, fontFamily: "Poppins", fontWeight: FontWeight.w600, color: Color.fromARGB(255, 199, 35, 191)),
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
                    width: 120,  // Ancho ajustado para hacerlo más estrecho
                    height: 109,  // Altura igualada
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
                //border: Border.all(color: Color.fromARGB(255, 43, 43, 43), width: 0.7),
              ),
              child: Center(
  child: ClipRRect(
    borderRadius: BorderRadius.circular(50), // Ajusta el radio para redondear los bordes
    child: Image.asset(
      "lib/images/animations/plus.gif",
      width: 15, // Ajusta el tamaño de la imagen según sea necesario
      height: 15, // Ajusta el tamaño de la imagen según sea necesario
      fit: BoxFit.cover, // Ajusta la imagen para que cubra completamente el área
    ),
  ),
)

            ),
          ),
        ],
      ),
    ),
  );
}


                        List<OrderDetails> orders = [];

void _showAditionalsScreen(String producto, QueryDocumentSnapshot orden) {
  String nombreOrden = orden['NOMBRE_DEL_PRODUCTO'] as String;
  String descripcionOrden = orden['descripcion'] as String;
  int precioOrden = orden['precio'] as int;
  String urlOrden = orden['url'] as String;
  List<Map<String, bool>> categoryStates = [];
  Map<String, bool> _expandedStates = {};
  bool agregar_orden = false;
  _controllers = List.generate(10, (_) => ExpandedTileController(isExpanded: true));

  final formatter = NumberFormat('#,###', 'es_ES');
  double precioTotal2 = precioOrden.toDouble();
  Set<String> _selectedAditionals = {};

  FirebaseFirestore.instance.collection(producto).get().then((querySnapshot) {
    Map<String, List<DocumentSnapshot>> categorias = {};
    for (var doc in querySnapshot.docs) {
      String status = doc['status'];
      if (!categorias.containsKey(status)) {
        categorias[status] = [];
      }
      categorias[status]!.add(doc);
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
                    padding: EdgeInsets.all(0),
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
                        _buildOrderHeader(nombreOrden, descripcionOrden, urlOrden),
                        Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Text(
                            'Personaliza tu orden:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: "Poppins-Bold",
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 390,
                          child: SingleChildScrollView(
                            child: Column(
                              children: categorias.entries.map((category) {
                                Map<String, List<dynamic>> subcategorias = {};
                                Set<String> _expandedSubcategories = Set<String>();
                                Map<String, String> _selectedSubcategoryItem = {};
                                Map<String, bool> categoryMap = {category.key: false};
                                categoryStates.add(categoryMap);
                                int total_obligatorio = 0;
                                int total_opcional = 0;

                                for (var adicional in category.value) {
                                  String subcategoria = adicional['categoria'] ?? 'Sin categoría';
                                  if (!subcategorias.containsKey(subcategoria)) {
                                    subcategorias[subcategoria] = [];
                                    total_obligatorio++;
                                    _expandedSubcategories.add(subcategoria);
                                  }
                                  subcategorias[subcategoria]?.add(adicional);
                                  total_opcional++;
                                }

                                List<Widget> categoryWidgets = subcategorias.entries.map((subcategoriaEntry) {
                                  String subcategoriaKey = subcategoriaEntry.key;
                                  List<dynamic> subcategoriaValue = subcategoriaEntry.value;
                                  bool isExpanded = true;
                                  int maxSelect = subcategoriaValue.fold<int>(0, (max, adicional) => adicional['maxselect']);
                                  int CatGoria = subcategoriaValue.fold<int>(0, (max, adicional) => adicional['pos']);
                                  List<Widget> additionalTiles = subcategoriaValue.map<Widget>((adicional) {
                                    bool isSelected = _selectedAditionals.contains(adicional['nombre']);

                                    return _buildAdditionalTile(adicional, (int precioAdicional, bool selected) {
                                      setState(() {
                                        int totalSelected = _selectedAditionals.where((element) => subcategorias[subcategoriaKey]!.any((adicional) => adicional['nombre'] == element)).length;

                                        if (selected) {
                                          if (totalSelected >= maxSelect) {
                                            if (maxSelect == 1) {
                                              String previousSelection = _selectedSubcategoryItem[subcategoriaKey]!;
                                              var previousAdicional = subcategorias[subcategoriaKey]!.firstWhere((element) => element['nombre'] == previousSelection);
                                              precioTotal2 -= previousAdicional['precio'];
                                              _selectedAditionals.remove(previousSelection);
                                              _selectedSubcategoryItem.remove(subcategoriaKey);
                                            } else {
                                              return;
                                            }
                                          }
                                          _selectedSubcategoryItem[subcategoriaKey] = adicional['nombre'];
                                          precioTotal2 += precioAdicional;
                                          _selectedAditionals.add(adicional['nombre']);
                                        } else {
                                          precioTotal2 -= precioAdicional;
                                          _selectedAditionals.remove(adicional['nombre']);
                                          if (_selectedSubcategoryItem[subcategoriaKey] == adicional['nombre']) {
                                            _selectedSubcategoryItem.remove(subcategoriaKey);
                                          }
                                        }

                                        if (category.key == "obligatorio" || maxSelect == 1) {
                                          _expandedStates[subcategoriaKey] = selected && _selectedSubcategoryItem.containsKey(subcategoriaKey);
                                          agregar_orden = subcategorias.keys.every((subcatKey) {
                                            return _expandedStates[subcatKey] ?? false;
                                          });
                                        }

                                        if (totalSelected + 1 == maxSelect && selected) {
                                          _controllers[CatGoria - 1].collapse();
                                        }
                                      });
                                    }, isSelected);
                                  }).toList();

                                  return Container(
                                    margin: EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        ExpandedTile(
                                          expansionAnimationCurve: Easing.emphasizedAccelerate,
                                          expansionDuration: const Duration(milliseconds: 500),
                                          theme: const ExpandedTileThemeData(
                                            headerColor: Color.fromARGB(255, 255, 255, 255),
                                            headerRadius: 8.0,
                                            headerPadding: EdgeInsets.only(left: 0.0, top: 0.0, bottom: 8.0, right: 0.0),
                                            headerSplashColor: Color.fromARGB(255, 240, 240, 240),
                                            contentBackgroundColor: Color.fromARGB(255, 255, 255, 255),
                                            contentPadding: EdgeInsets.all(0.0),
                                            contentRadius: 12.0,
                                          ),
                                          title: Center(
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  subcategoriaKey,
                                                  textAlign: TextAlign.right,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    fontFamily: "Poppins",
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                Container(
                                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: (category.key == "obligatorio")
                                                        ? (_expandedStates[subcategoriaKey] == true ? Colors.green : Colors.white)
                                                        : (_expandedStates[subcategoriaKey] == true ? Colors.white : Colors.white),
                                                    borderRadius: BorderRadius.circular(10),
                                                    border: Border.all(color: const Color.fromARGB(255, 235, 235, 235)),
                                                  ),
                                                  child: Text(
                                                    (category.key == "obligatorio")
                                                        ? (_expandedStates[subcategoriaKey] == true ? "Ok!" : "Obligatorio")
                                                        : (_expandedStates[subcategoriaKey] == true ? "Opcional" : "Opcional"),
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.normal,
                                                      fontFamily: "Poppins-SB",
                                                      color: (category.key == "obligatorio")
                                                          ? (_expandedStates[subcategoriaKey] == true ? Colors.white : Colors.black)
                                                          : (_expandedStates[subcategoriaKey] == true ? Colors.black : Colors.black),
                                                    ),
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                          content: Container(
                                            color: Colors.white,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: additionalTiles,
                                            ),
                                          ),
                                          controller: _controllers[CatGoria - 1],
                                        ),
                                        SizedBox(height: 8),
                                        Divider(
                                          color: Color.fromARGB(255, 202, 202, 202),
                                          height: 1,
                                          thickness: 1.3,
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList();

                                return Container(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Column(
                                    children: categoryWidgets,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        SizedBox(height: 75),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 30,
                  left: 20,
                  right: 20,
                  child: GestureDetector(
                    onTap: agregar_orden
                        ? () async {
                            // Generar un ID único para la orden
                            String orderId = Uuid().v4();

                            // Lógica para agregar la orden a Firestore
                            List<String> urlSegments = widget.scannedResult.split("/");
                            String firestorepath1 = "/" + urlSegments[1] + "/" + urlSegments[2] + "/" + urlSegments[3] + "/" + urlSegments[4] + "/" + urlSegments[5] + "/" + urlSegments[6] + "/" + urlSegments[7];
                            String firestorepath2 = urlSegments[8];
                            String firebaseuid = FirebaseAuth.instance.currentUser!.uid;
                            final userOrderRef = FirebaseFirestore.instance.collection(firestorepath1).doc(firestorepath2);

                            // Mapa de datos para la orden con el ID único
                            Map<String, dynamic> orderData = {
                              'UserId': firebaseuid,
                              'orderId': orderId, // Agregar el campo de ID único
                              'OrderUrl': widget.scannedResult,
                              'OrdenPago': 0,
                              'photouser': widget.photoUrl,
                              'productName': nombreOrden,
                              'description': descripcionOrden,
                              'imageUrl': urlOrden,
                              'price': precioTotal2,
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
                              precioTotal2 = precioOrden.toDouble();
                            });

                            // Cerrar la pantalla de selección de adicionales
                            Navigator.pop(context);
                          }
                        : null,
                    child: Container(
                      height: 45,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: agregar_orden ? Colors.purple : Colors.grey[400],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Agregar a mi orden                  \$${formatter.format(precioTotal2)}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: "Poppins-SemiBold",
                          ),
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

Widget _buildOrderHeader(String nombreOrden, String descripcionOrden, String urlOrden) {
  return Container(
    padding: EdgeInsets.all(15),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
      color: Colors.purple,
    ),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.network(
            urlOrden,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          ),
        ),
        SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nombreOrden,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Insanibc",
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 5),
              Text(
                descripcionOrden,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: "Poppins-Medium",
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
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
    margin: EdgeInsets.symmetric(vertical: 8), // Agrega espacio vertical entre cada tile
    child: Material(
      elevation: isSelected ? 3 : 0, // Define la elevación de la sombra según el estado de selección
      borderRadius: BorderRadius.circular(12), // Esquinas redondeadas
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Color.fromARGB(255, 196, 196, 196)!, width: 0.2), // Borde gris claro alrededor del contenedor
          borderRadius: BorderRadius.circular(12), // Esquinas redondeadas
          color: Color.fromARGB(255, 255, 255, 255), // Fondo blanco
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0), // Ajuste del padding interno
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
              adicional['precio'] > 0
                  ? Text(
                      '\$${adicional['precio']}',
                      style: TextStyle(
                        fontFamily: "Poppins",
                        fontSize: 11,
                        color: Colors.grey[800],
                      ),
                    )
                  : SizedBox.shrink(),
              Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected ? Colors.green : Colors.grey,
                size: 17,
              ),
            ],
          ),
          onTap: () => onSelectionChanged(adicional['precio'], !isSelected),
        ),
      ),
    ),
  );
}



void _showCart() {
  List<String> urlSegments = widget.scannedResult.split("/");

  String firestorepath1 = "/${urlSegments[1]}/${urlSegments[2]}/${urlSegments[3]}/${urlSegments[4]}/${urlSegments[5]}/${urlSegments[6]}/${urlSegments[7]}";
  String firestorepath2 = urlSegments[8];
  bool flag = false;
  final aux;
  Map<String, bool> isChecked = {}; // Estado para cada checkbox
  bool EnableButton = true;
  String firebaseuid = FirebaseAuth.instance.currentUser!.uid;

  NumberFormat formatter = NumberFormat("#,##0", "es_ES");

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          Map<String, List<Map<String, dynamic>>> groupedItems = {};

          return Container(
  height: MediaQuery.of(context).size.height * 0.97, // Establece la altura a la mitad de la pantalla
  padding: EdgeInsets.all(20),
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
  child: Column(
    children: [
      // AppBar
      AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(firebaseuid).get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: LoadingAnimationWidget.twistingDots(
                    leftDotColor: const Color(0xFF1A1A3F),
                    rightDotColor: Color.fromARGB(255, 198, 55, 234),
                    size: 50,
                  ),
                );
              } else if (snapshot.hasError) {
                return Icon(Icons.error);
              } else if (!snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
                return Icon(Icons.error);
              } else {
                final userDoc = snapshot.data!.data() as Map<String, dynamic>;
                final profileUrl = userDoc['profileUrl'];
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundImage: NetworkImage(profileUrl),
                  ),
                );
              }
            },
          ),
        ],
      ),
      Center(
        child: Container(
          margin: const EdgeInsets.all(30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Center(
                child: Text(
                  'Se ha generado tu orden!',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Aquí puedes ver toda tu orden y verificar tu pedido 😋.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ),
      Expanded(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection(firestorepath1).doc(firestorepath2).snapshots(),
          builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: LoadingAnimationWidget.twistingDots(
                  leftDotColor: const Color(0xFF1A1A3F),
                  rightDotColor: Color.fromARGB(255, 198, 55, 234),
                  size: 50,
                ),
              );
            } else if (snapshot.hasError) {
              print("Error: ${snapshot.error}");
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
              print("No se encontraron datos");
              return Center(child: Text('No se encontraron datos'));
            } else {

              
              final orderData = snapshot.data!.data() as Map<String, dynamic>;
              //print(snapshot.data!.data());
              // print(orderData);
              // print(orderData.keys);
              bool allValuesAreIterable(Map<String, dynamic> orderData) {
                for (var value in orderData.values) {
                  if (value is! Iterable) {
                    return false;
                  }
                }
                return true;
              }

              EnableButton = allValuesAreIterable(orderData);

              


              groupedItems = {};

              for (String key in orderData.keys) {
                final itemList = orderData[key];
                
                if (itemList is Iterable) {
                  print(itemList);
                  for (var item in itemList) {
                    if (item is Map<String, dynamic>) {
                      String photouser = item['photouser'];
                      if (!isChecked.containsKey(photouser)) {
                        isChecked[photouser] = flag; // Inicializa la checkbox en falso si es la primera vez
                      }
                      if (groupedItems.containsKey(photouser)) {
                        groupedItems[photouser]?.add(item);
                      } else {
                        groupedItems[photouser] = [item];
                      }
                    }
                  }
                }
              }

              // Calcular la suma total
              double totalAmount = groupedItems.values.fold(0.0, (sum, itemsForUser) {
                return sum + itemsForUser.fold(0.0, (sum, item) {
                  return sum + item['price'] + (item['selectedAdditionals'] as List<dynamic>).fold(0.0, (sum, additional) => sum + additional['price']);
                });
              });

              return Column(
                children: [

                  //aqui
                  Expanded(
  child: ListView.builder(
    itemCount: groupedItems.length,
    itemBuilder: (context, index) {
      final photouserKey = groupedItems.keys.elementAt(index);
      final itemsForUser = groupedItems[photouserKey];

      double totalPrice = itemsForUser!.fold(0.0, (sum, item) => sum + item['price'] + (item['selectedAdditionals'] as List<dynamic>).fold(0.0, (sum, additional) => sum + additional['price']));

      return Container(
        margin: EdgeInsets.symmetric(horizontal: 20.0), // Ajusta el margen horizontal para hacer la tarjeta más angosta
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2), // Color de la sombra
              spreadRadius: 1, // Radio de expansión
              blurRadius: 20, // Radio de desenfoque
              offset: Offset(0, 15), // Desplazamiento de la sombra
            ),
          ],
        ),
        child: Card(
          elevation: 0.0,
          shadowColor: Colors.black.withOpacity(0.888), // Ajusta el color de la sombra
          color: Colors.white,
          margin: EdgeInsets.symmetric(vertical: 8.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
            side: BorderSide(color: Color.fromARGB(255, 255, 255, 255)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundImage: NetworkImage(photouserKey),
                      backgroundColor: Colors.transparent,
                    ),
                    SizedBox(width: 10),
                    Row(
                      children: [
                        Text(
                          'Total a pagar: \$${formatter.format(totalPrice)}',
                          style: TextStyle(fontFamily: "Poppins-l", fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () {
                        setState(() {
  groupedItems.remove(firebaseuid);
  
  FirebaseFirestore.instance.collection(firestorepath1).doc(firestorepath2).update({
    firebaseuid: FieldValue.delete(), // Elimina el campo completo del documento
  }).then((_) {
    print('Campo eliminado correctamente de Firebase.');

    // Ahora crea un nuevo campo con el firebaseuid y un valor de tipo string
    FirebaseFirestore.instance.collection(firestorepath1).doc(firestorepath2).update({
      firebaseuid: firebaseuid, // Aquí puedes agregar el valor de tipo string que desees
    }).then((_) {
      print('Campo creado correctamente en Firebase.');
    }).catchError((error) {
      print('Error al crear campo en Firebase: $error');
    });
  }).catchError((error) {
    print('Error al eliminar campo de Firebase: $error');
  });
});

                      },
                    ),
                  ],
                ),
              ),
              Divider(
                color: Color.fromARGB(255, 241, 241, 241),
                thickness: 5,
              ),
              ...itemsForUser.map<Widget>((item) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8.0),
                              border: Border.all(color: Color.fromARGB(255, 241, 241, 241)),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.network(
                                item['imageUrl'],
                                height: 40,
                                width: 40,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['productName'],
                                  style: TextStyle(
                                    fontFamily: "Poppins-SB",
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  formatter.format(item['price']),
                                  style: TextStyle(
                                    fontFamily: "Poppins",
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...item['selectedAdditionals'].map<Widget>((additional) {
                      return Padding(
                        padding: EdgeInsets.only(top: 0.0, bottom: 0.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8.0),
                                      border: Border.all(color: Color.fromARGB(255, 243, 243, 243)),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: Image.network(
                                        additional['photo'],
                                        height: 40,
                                        width: 40,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${additional['name']}',
                                      style: TextStyle(
                                        fontFamily: "Poppins",
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (additional['price'] > 0)
                                      Text(
                                        formatter.format(additional['price']),
                                        style: TextStyle(
                                          fontFamily: "Poppins",
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.purple,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            Divider(
                              color: Color.fromARGB(255, 241, 241, 241),
                              thickness: 1,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                );
              }).toList(),
            ],
          ),
        ),
      );
    },
  ),
),

                  ElevatedButton(
                    onPressed: EnableButton ? () {
                      final itemsForUser = groupedItems;
                      print(itemsForUser);
                  
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentManagerOrderly(
                            itemsForUser,
                            widget.photoUrl,
                            firestorepath1,
                            firestorepath2,
                            widget.scannedResult,
                          ),
                        ),
                      );
                    }: null,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, // Text color
                      backgroundColor: Colors.purple,
                      padding: EdgeInsets.symmetric(vertical: 12), // Ajusta el padding para mayor altura si necesario
                      //minimumSize: Size(double.infinity, 30), // Hace el botón tan ancho como su contenedor y 50px de alto
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Pasar al pago',
                            style: TextStyle(
                              fontSize: 14, // Tamaño de la fuente
                              fontWeight: FontWeight.bold, // Grosor de la fuente
                              color: Colors.white, // Color del texto
                              fontFamily: 'Poppins', // Tipo de fuente
                            ),
                          ),
                          SizedBox(width: 120), // Añade un espacio entre los textos
                          Text(
                            '\$${formatter.format(totalAmount)}',
                            style: TextStyle(
                              fontSize: 15, // Tamaño de la fuente
                              fontWeight: FontWeight.bold, // Grosor de la fuente
                              color: Colors.white, // Color del texto
                              fontFamily: 'Poppins-Bold', // Tipo de fuente
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    ],
  ),
);



         //AQUIIII
        },
      );
    },
  );
}


Stream<DocumentSnapshot> managerPayStream() {
  String direction = "${widget.scannedResult}/pagos/pagar";
  return FirebaseFirestore.instance.doc(direction).snapshots();
}

Stream <Map<String, dynamic>> InvoiceProductsStream() {
    List<String> urlSegments = widget.scannedResult.split("/");

    String firestorePath1 = "/${urlSegments[1]}/${urlSegments[2]}/${urlSegments[3]}/${urlSegments[4]}/${urlSegments[5]}/${urlSegments[6]}/${urlSegments[7]}";
    String firestorePath2 = urlSegments[8];

    return FirebaseFirestore.instance.collection(firestorePath1).doc(firestorePath2).snapshots().map((snapshot) {
        if (snapshot.exists) {
            final orderData = snapshot.data() as Map<String, dynamic>;
            return orderData;
        } else {
            // Devuelve un mapa vacío o un mapa con un mensaje de error
            return {"error": "No data available"};
        }
        
    });
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
        return LoadingAnimationWidget.twistingDots(
                          leftDotColor: const Color(0xFF1A1A3F),
                          rightDotColor: Color.fromARGB(255, 198, 55, 234),
                          size: 50,
                        );
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
                if (photouser.contains("google")) {
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
void fetchAndPrintManagerPay() async {
  String direction = "${widget.scannedResult}/pagos/pagar";
  DocumentReference documentRef = FirebaseFirestore.instance.doc(direction);

  try {
    DocumentSnapshot snapshot = await documentRef.get();
    if (snapshot.exists) {
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      List<dynamic> managerPay = data['ManagerPay'];
      if (managerPay.isNotEmpty) {
        print("Elementos en ManagerPay:");
        for (var userId in managerPay) {
          print(userId);  // Imprimir cada ID del usuario
        }
      } else {
        print("ManagerPay está vacío.");
      }
    } else {
      print("No se encontró el documento en la ruta: $direction");
    }
  } catch (e) {
    print("Error al obtener datos de Firestore: $e");
  }
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

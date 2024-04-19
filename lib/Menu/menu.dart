// ignore_for_file: must_be_immutable, non_constant_identifier_names, use_key_in_widget_constructors, library_private_types_in_public_api, prefer_const_constructors, avoid_print

import 'dart:async';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OrderDetails {
  final String firebaseuid;
  final String OrderUrl;
  final String photouser;
  final String productName;
  final String description;
  final String imageUrl;
  final int price;
  final List<AdditionalItem> selectedAdditionals;

  OrderDetails({
    required this.firebaseuid,
    required this.OrderUrl,
    required this.photouser,
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
    required this.photo
  });
}


class ProductItem {
  int quantity;
  double price;
  String imageUrl;
  String aditionals;

  ProductItem({required this.quantity, required this.price, required this.imageUrl, required this.aditionals});
}

class ShoppingCart {
  final Map<String, ProductItem> _selectedProducts = {};
  double _totalAmount = 0;

  Map<String, ProductItem> get selectedProducts => _selectedProducts;
  double get totalAmount => _totalAmount;

  void addToCart(String productName, double productPrice, String imageUrl, String aditionals) {
    if (_selectedProducts.containsKey(productName)) {
      _selectedProducts[productName]!.quantity += 1;
    } else {
      _selectedProducts[productName] = ProductItem(quantity: 1, price: productPrice, imageUrl: imageUrl, aditionals: aditionals);
    }
    _totalAmount += productPrice;
  }

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

  void clearCart() {
    _selectedProducts.clear();
    _totalAmount = 0;
  }
}

class MENU extends StatefulWidget {
  final String MenuUrl;
  final String scannedResult;
  final String photoUrl;
  final String RestaurantName;
  String ResDescription;

  MENU(this.scannedResult, this.photoUrl, this.MenuUrl, this.RestaurantName, this.ResDescription);

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

  // Definir _selectedAdicionals para almacenar los adicionales seleccionados
  List<String> _selectedAdicionals = [];

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

  Future<DocumentSnapshot> _fetchRestaurantData() async {
    return FirebaseFirestore.instance.collection('Orderly').doc('restaurantes').collection('restaurantes').doc(widget.RestaurantName).get();
  }

  Future<DocumentSnapshot> _fetchBannersData() async {
    return FirebaseFirestore.instance.collection('Orderly').doc('restaurantes').collection('restaurantes').doc('El corral').collection('banners').doc('banners').get();
  }

  Future<QuerySnapshot> _fetchMenuData() async {
    return FirebaseFirestore.instance.collection(widget.MenuUrl).orderBy('pos').get();
  }

  void _startTimer() {
    const tenMinutes = Duration(minutes: 10);
    _timer = Timer.periodic(tenMinutes, (Timer timer) {
      _fetchBannersData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder(
        future: Future.wait([_restaurantDataFuture, _bannersDataFuture, _menuDataFuture]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
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

          final restaurantData = data[0] as DocumentSnapshot;
          final bannersData = data[1] as DocumentSnapshot;
          final menuData = data[2] as QuerySnapshot;

          final imageUrl = restaurantData['url'] as String;
          widget.ResDescription = restaurantData['descripcion'] as String;

          final url1 = bannersData['url1'] as String;
          final url2 = bannersData['url2'] as String;
          final url3 = bannersData['url3'] as String;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.black,
                            width: 0.2,
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          size: 25,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const Image(
                          image: AssetImage("lib/images/logos/orderly_icon3.png"),
                          height: 50,
                          width: 80,
                        ),
                        const SizedBox(width: 16),
                        Image.network(
                          imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                    CircleAvatar(
                      backgroundImage: widget.photoUrl.isNotEmpty ? NetworkImage(widget.photoUrl) : const AssetImage("lib/images/logos/default_avatar.png") as ImageProvider,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 0),
              CarouselSlider(
                items: [
                  Image.network(url1),
                  Image.network(url2),
                  Image.network(url3),
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
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(decelerationRate: ScrollDecelerationRate.fast),
                  itemCount: 1,
                  itemBuilder: (context, index) {
                    return _buildProductoCard();
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showCart();
        },
        child: Stack(
          children: [
            const Icon(Icons.shopping_cart),
            if (_cartItemCount > 0)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    _cartItemCount.toString(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductoCard() {
    Map<String, List<QueryDocumentSnapshot>> categoryGroups = {};
    for (final producto in _menuData) {
      String categoria = producto['TIPO_PRODUCTO'] as String;
      if (!categoryGroups.containsKey(categoria)) {
        categoryGroups[categoria] = [];
      }
      categoryGroups[categoria]!.add(producto);
    }

    return Column(
      children: categoryGroups.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  entry.key,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    fontFamily: "Poppins-l"
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: entry.value.map((producto) => _buildProductoItem(producto)).toList(),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProductoItem(QueryDocumentSnapshot producto) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
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
                  width: 150,
                  height: 180,
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
              Text(
                '\$${producto['precio']}',
                style: const TextStyle(fontSize: 12, fontFamily: "Poppins-l", fontWeight: FontWeight.bold, color: Colors.purple),
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: InkWell(
              onTap: () {
                _showAditionalsScreen(producto['adiciones'], producto);
              },
              child: Container(
                padding: const EdgeInsets.all(4.0),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 247, 253, 246),
                  borderRadius: BorderRadius.circular(20.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.green),
              ),
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

    // Inicializar el precio total con el precio base de la orden
    double precioTotal = precioOrden.toDouble();

    // Variable específica para cada pantalla para almacenar los elementos seleccionados
    Set<String> _selectedAditionals = {};

    FirebaseFirestore.instance.collection(producto).get().then((querySnapshot) {
        Map<String, List<DocumentSnapshot>> categorias = {};
        querySnapshot.docs.forEach((doc) {
            String status = doc['status'];
            if (!categorias.containsKey(status)) {
                categorias[status] = [];
            }
            categorias[status]!.add(doc);
        });

        showModalBottomSheet<void>(
            context: context,
            builder: (BuildContext context) {
                return StatefulBuilder(
                    builder: (BuildContext context, StateSetter setState) {
                        return Stack(
                            children: [
                                SingleChildScrollView(
                                    child: Container(
                                        padding: EdgeInsets.all(20),
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
                                                SizedBox(height: 10),
                                                // Detalles de la orden
                                                Text(
                                                    'Detalles de la orden:',
                                                    style: TextStyle(
                                                        fontSize: 14 * MediaQuery.of(context).textScaleFactor,
                                                        fontWeight: FontWeight.bold,
                                                        fontFamily: "Poppins-l",
                                                    ),
                                                ),
                                                SizedBox(height: 10),
                                                // Foto de la orden
                                                Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                        Container(
                                                            width: MediaQuery.of(context).size.width * 0.25,
                                                            height: MediaQuery.of(context).size.width * 0.25,
                                                            margin: EdgeInsets.only(right: 10),
                                                            decoration: BoxDecoration(
                                                                borderRadius: BorderRadius.circular(10),
                                                                image: DecorationImage(
                                                                    image: NetworkImage(urlOrden),
                                                                    fit: BoxFit.cover,
                                                                ),
                                                            ),
                                                        ),
                                                        Expanded(
                                                            child: Column(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                    // Descripción de la orden
                                                                    Text(
                                                                        'Descripción: $descripcionOrden',
                                                                        style: TextStyle(
                                                                            fontSize: 11 * MediaQuery.of(context).textScaleFactor,
                                                                            fontFamily: "Poppins",
                                                                        ),
                                                                    ),
                                                                    SizedBox(height: 10),
                                                                    // Precio unitario de la orden
                                                                    Text(
                                                                        'Precio unitario: \$${precioOrden.toStringAsFixed(2)}',
                                                                        style: TextStyle(
                                                                            fontSize: 12 * MediaQuery.of(context).textScaleFactor,
                                                                            fontFamily: "Poppins-l",
                                                                        ),
                                                                    ),
                                                                ],
                                                            ),
                                                        ),
                                                    ],
                                                ),
                                                SizedBox(height: 20),
                                                // Selección de productos adicionales
                                                Text(
                                                    'Selecciona los adicionales para $nombreOrden',
                                                    style: TextStyle(
                                                        fontSize: 14 * MediaQuery.of(context).textScaleFactor,
                                                        fontWeight: FontWeight.bold,
                                                        fontFamily: "Poppins-l",
                                                    ),
                                                ),
                                                SizedBox(height: 20),
                                                Column(
                                                    children: [
                                                        for (final category in categorias.entries)
                                                            Column(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                    SizedBox(height: 10),
                                                                    Text(
                                                                        '${category.key}',
                                                                        style: TextStyle(
                                                                            fontSize: 14 * MediaQuery.of(context).textScaleFactor,
                                                                            fontWeight: FontWeight.bold,
                                                                            fontFamily: "Poppins-l",
                                                                        ),
                                                                    ),
                                                                    SizedBox(height: 5),
                                                                    ...category.value.map((adicional) {
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
                                                                        }, _selectedAditionals.contains(adicional['nombre']));
                                                                    }).toList(),
                                                                ],
                                                            ),
                                                    ],
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
                                            // Lógica para agregar la orden a Firestore
                                            List<String> urlSegments = widget.scannedResult.split("/");

                                            String firestorepath1 = "/"+urlSegments[1] +"/"+urlSegments[2] +"/"+ urlSegments[3]+"/"+urlSegments[4] +"/"+urlSegments[5]+"/"+urlSegments[6] +"/"+urlSegments[7];
                                            String firestorepath2 = urlSegments[8];
                                            String firebaseuid = FirebaseAuth.instance.currentUser!.uid;

                                            final userOrderRef = FirebaseFirestore.instance.collection(firestorepath1).doc(firestorepath2);

                                            Map<String, dynamic> orderData = {
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
                                            width: MediaQuery.of(context).size.width * 0.9,
                                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(12),
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
                                            child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                    Expanded(
                                                        child: Text(
                                                            'Agregar a la orden',
                                                            style: TextStyle(
                                                                fontFamily: "Poppins-l",
                                                                fontSize: 10 * MediaQuery.of(context).textScaleFactor,
                                                                color: Colors.white,
                                                                overflow: TextOverflow.ellipsis, // Para manejar texto largo
                                                            ),
                                                        ),
                                                    ),
                                                    Text(
                                                        '\$${precioTotal.toStringAsFixed(2)}',
                                                        style: TextStyle(
                                                            fontFamily: "Poppins-l",
                                                            fontSize: 10 * MediaQuery.of(context).textScaleFactor,
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.white,
                                                        ),
                                                    ),
                                                ],
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

Widget _buildAdditionalTile(DocumentSnapshot adicional, Function(int, bool) onSelectionChanged, bool isSelected) {
  return Container(
    margin: EdgeInsets.symmetric(vertical: 5),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.5),
          spreadRadius: 2,
          blurRadius: 5,
          offset: Offset(0, 3), // changes position of shadow
        ),
      ],
    ),
    child: ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 1),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          adicional['url'] as String,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
        ),
      ),
      title: Text(
        adicional['nombre'] as String,
        style: TextStyle(
          fontFamily: "Poppins-l",
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '\$${adicional['precio']}',
            style: TextStyle(
              fontFamily: "Poppins-l",
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
          Checkbox(
            value: isSelected,
            onChanged: (value) {
              onSelectionChanged(adicional['precio'], value!);
            },
          ),
        ],
      ),
    ),
  );
}


void _showCart() {
    List<String> urlSegments = widget.scannedResult.split("/");

    String firestorepath1 = "/${urlSegments[1]}/${urlSegments[2]}/${urlSegments[3]}/${urlSegments[4]}/${urlSegments[5]}/${urlSegments[6]}/${urlSegments[7]}";
    String firestorepath2 = urlSegments[8];

    String firebaseuid = FirebaseAuth.instance.currentUser!.uid;

    showModalBottomSheet<void>(
        context: context,
        builder: (BuildContext context) {
            return StatefulBuilder(
                builder: (context, setState) {
                    return Container(
                        height: 400,
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
                        child: FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance.collection(firestorepath1).doc(firestorepath2).get(),
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

                                                double totalPrice = 0.0;
                                                for (var item in itemsForUser!) {
                                                    totalPrice += item['price'];
                                                    if (item['selectedAdditionals'] != null && item['selectedAdditionals'] is Iterable) {
                                                        for (var additional in item['selectedAdditionals']) {
                                                            totalPrice += additional['price'];
                                                        }
                                                    }
                                                }

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
                                                            // Mostrar la imagen de Fotousuario y el precio total
                                                            Padding(
                                                                padding: EdgeInsets.all(8.0),
                                                                child: Row(
                                                                    children: [
                                                                        if (photouserKey != null)
                                                                            CircleAvatar(
                                                                                radius: 15,
                                                                                backgroundImage: NetworkImage(photouserKey),
                                                                                backgroundColor: Colors.transparent,
                                                                                child: Container(
                                                                                    decoration: BoxDecoration(
                                                                                        shape: BoxShape.circle,
                                                                                        border: Border.all(color: const Color.fromARGB(255, 241, 241, 241)),
                                                                                    ),
                                                                                ),
                                                                            ),
                                                                        SizedBox(width: 10),
                                                                        Text(
                                                                            'Total a pagar: \$${totalPrice.toStringAsFixed(0)}',
                                                                            style: TextStyle(fontFamily: "Poppins-l", fontSize: 12, fontWeight: FontWeight.bold),
                                                                        ),
                                                                        // Añadir un espacio entre el total y la X
                                                                        Spacer(),
                                                                        // Icono de eliminación
                                                                        IconButton(
                                                                            icon: Icon(Icons.close),
                                                                            onPressed: () {
                                                                                // Lógica para eliminar el item del carrito y de Firebase
                                                                                setState(() {
                                                                                    // Eliminar el grupo de items para el usuario actual
                                                                                    groupedItems.remove(photouserKey);
                                                                                    // Eliminar los datos de Firebase
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
                                                            // Mostrar cada elemento asociado con el photouser
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
                                                                                'Precio: ${item['price']}',
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
                                                                                                        'Precio: ${additional['price']}',
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

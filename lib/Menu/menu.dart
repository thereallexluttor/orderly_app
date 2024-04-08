// ignore_for_file: must_be_immutable, non_constant_identifier_names, use_key_in_widget_constructors, library_private_types_in_public_api

import 'dart:async';
import 'dart:typed_data';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ShoppingCart {
  final List<Map<String, dynamic>> _selectedProducts = [];
  double _totalAmount = 0;

  List<Map<String, dynamic>> get selectedProducts => _selectedProducts;
  double get totalAmount => _totalAmount;

  void addToCart(Map<String, dynamic> product) {
    _selectedProducts.add(product);
    _totalAmount += (product['precio'] as int).toDouble();
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

  @override
  void initState() {
    super.initState();
    _restaurantDataFuture = _fetchRestaurantData();
    _bannersDataFuture = _fetchBannersData();
    _menuDataFuture = _fetchMenuData();
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
          if (snapshot.data == null) {
  return Center(
    child: CircularProgressIndicator(),
  );
}

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final restaurantData = snapshot.data![0] as DocumentSnapshot;
          final bannersData = snapshot.data![1] as DocumentSnapshot;
          final menuData = snapshot.data![2] as QuerySnapshot;

          // Extraer datos de restaurantes
          final imageUrl = restaurantData['url'] as String;
          widget.ResDescription = restaurantData['descripcion'] as String;

          // Extraer datos de banners
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
                      child: const Icon(Icons.arrow_back),
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
              const SizedBox(height: 10),
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
                  itemCount: menuData.size,
                  itemBuilder: (context, index) {
                    final producto = menuData.docs[index];
                    return _buildProductoCard(producto);
                  },
                ),
              ),
              Text(
                'Total: \$${_shoppingCart.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showCart();
        },
        child: Icon(Icons.shopping_cart),
      ),
    );
  }

  Widget _buildProductoCard(QueryDocumentSnapshot producto) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1.0)),
        ),
        child: Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
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
                      width: double.infinity,
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
                              style: const TextStyle(fontSize: 10, fontFamily: "Poppins-l", color: Colors.grey),
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
                      style: const TextStyle(fontSize: 12, fontFamily: "Poppins", fontWeight: FontWeight.bold, color: Colors.purple),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 190,
                child: InkWell(
                  onTap: () {
                    _shoppingCart.addToCart({
                      'nombre': producto['NOMBRE_DEL_PRODUCTO'] as String,
                      'precio': (producto['precio'] as int),
                    });
                    setState(() {});
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
                    child: Icon(Icons.add, color: Colors.green[800]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCart() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 200,
          color: Colors.white,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total: \$${_shoppingCart.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: () {
                    _shoppingCart.clearCart();
                    Navigator.pop(context);
                    setState(() {});
                  },
                  child: const Text('Clear Cart'),
                ),
              ],
            ),
          ),
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

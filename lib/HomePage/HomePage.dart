// ignore_for_file: file_names, deprecated_member_use, prefer_const_constructors, use_super_parameters, library_private_types_in_public_api, sized_box_for_whitespace, avoid_print

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:orderly_app/QR_scanner/qr_scanner.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MediaQuery(
        data: MediaQueryData.fromWindow(WidgetsBinding.instance.window).copyWith(textScaleFactor: 1.0),
        child: HomePage(),
      ),
    );
  }
}


class RestauranteItem extends StatefulWidget {
  final String nombre;
  final String urlLogo;
  final GeoPoint gpsPoint;
  final String categoria;
  final double distancia;
  final String descripcion;
  final bool isSelected;
  final VoidCallback? onMapOpened;
  final VoidCallback? onMapClosed;
  final Position? currentPosition;

  const RestauranteItem({
    Key? key,
    required this.nombre,
    required this.urlLogo,
    required this.gpsPoint,
    required this.categoria,
    required this.distancia,
    required this.descripcion,
    required this.isSelected,
    this.onMapOpened,
    this.onMapClosed,
    this.currentPosition,
  }) : super(key: key);

  @override
  _RestauranteItemState createState() => _RestauranteItemState();
}

class _RestauranteItemState extends State<RestauranteItem> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Container(
        height: widget.isSelected ? 300 : 75,
        child: Card(
          color: const Color.fromRGBO(255, 255, 255, 1),
          shadowColor: Colors.black,
          margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 5.0),
          elevation: 0.2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Stack(
            children: [
              _buildContent(),
              Positioned(
                top: 5,
                right: 15,
                child: Text(
                  '${widget.distancia.toStringAsFixed(1)} Km',
                  style: const TextStyle(
                    fontFamily: "Poppins",
                    color: Colors.purple,
                    fontWeight: FontWeight.normal,
                    fontSize: 9,
                  ),
                ),
              ),
              Center(
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: _buildLocationButton(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 25,
            height: 25,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [],
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              iconSize: 15,
              icon: const Icon(Icons.location_on, color: Colors.purple),
              onPressed: () {
                _openGoogleMaps();
              },
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Como llegar?',
            style: TextStyle(
              fontFamily: "Poppins",
              color: Colors.purple,
              fontWeight: FontWeight.normal,
              fontSize: 7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(10.0),
              image: DecorationImage(
                image: CachedNetworkImageProvider(widget.urlLogo),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            height: double.infinity,
            width: 2,
            color: const Color.fromARGB(255, 238, 238, 238),
            margin: const EdgeInsets.symmetric(vertical: 10.0),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.nombre,
                  style: const TextStyle(
                    fontFamily: "Poppins-l",
                    color: Color.fromARGB(255, 0, 0, 0),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(right: 80),
                  child: Text(
                    widget.descripcion,
                    style: const TextStyle(
                      fontFamily: "Poppins-l",
                      color: Color.fromARGB(255, 92, 92, 92),
                      fontWeight: FontWeight.bold,
                      fontSize: 8,
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openGoogleMaps() {
    final String destination = '${widget.gpsPoint.latitude},${widget.gpsPoint.longitude}';
    final String origin = '${widget.currentPosition?.latitude},${widget.currentPosition?.longitude}';
    final String url = 'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination';
    launch(url);
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<QueryDocumentSnapshot> _allRestaurantesData = [];
  Position? _currentPosition;
  final ScrollController _scrollController = ScrollController();
  List<QueryDocumentSnapshot> _filteredRestaurantesData = [];
  final TextEditingController _searchController = TextEditingController();
  final List<String> _sliderImages = [
    "https://firebasestorage.googleapis.com/v0/b/orderlyapp-762a8.appspot.com/o/110010101%2Fbanners%2Fbanner.jpg?alt=media&token=402d8f9c-47d6-48a7-80dd-f68447b73c6f",
    "https://firebasestorage.googleapis.com/v0/b/orderlyapp-762a8.appspot.com/o/110010101%2Fbanners%2Fbanner.jpg?alt=media&token=402d8f9c-47d6-48a7-80dd-f68447b73c6f",
    "https://firebasestorage.googleapis.com/v0/b/orderlyapp-762a8.appspot.com/o/110010101%2Fbanners%2Fbanner.jpg?alt=media&token=402d8f9c-47d6-48a7-80dd-f68447b73c6f",
    "https://firebasestorage.googleapis.com/v0/b/orderlyapp-762a8.appspot.com/o/110010101%2Fbanners%2Fbanner.jpg?alt=media&token=402d8f9c-47d6-48a7-80dd-f68447b73c6f",
  ];
  int _selectedButtonIndex = 0;
  RestauranteItem? _currentOpenRestaurant;
  bool _showCategories = true;  // Controla la visibilidad de las categorías

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _fetchRestaurantesData();
    Timer.periodic(const Duration(minutes: 5), (timer) {
      _getCurrentLocation();
    });
  }

  void _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
        _fetchRestaurantesData();
      });
    } catch (e) {
      print("Error al obtener la ubicación: $e");
    }
  }

  Future<void> _fetchRestaurantesData() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Orderly')
        .doc('restaurantes')
        .collection('restaurantes')
        .get();
    setState(() {
      _allRestaurantesData = snapshot.docs;
      _filterRestaurantesByCategory("Burgers");
    });
  }

  void _filterRestaurantesByCategory(String category) {
    setState(() {
      _filteredRestaurantesData = _allRestaurantesData.where((restaurante) {
        return restaurante['categoria'] == category;
      }).toList();
    });
  }

  void _filterRestaurantesByName(String name) {
    setState(() {
      _filteredRestaurantesData = _allRestaurantesData.where((restaurante) {
        return restaurante['nombre_restaurante'].toLowerCase().contains(name.toLowerCase());
      }).toList();
    });
  }

  @override
@override
Widget build(BuildContext context) {
  return SafeArea(
    child: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              "lib/images/logos/orderly_icon3.png",
              height: 100,
              width: 70,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.black),
            onPressed: () {
              _showSettingsMenu(context);
            },
          ),
        ],
        toolbarHeight: 75,
      ),
      
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
             
              CarouselSlider(
                options: CarouselOptions(
                  autoPlay: true,
                  height: 120,
                  autoPlayCurve: Curves.fastOutSlowIn,
                  autoPlayAnimationDuration: const Duration(milliseconds: 800),
                  autoPlayInterval: const Duration(seconds: 4),
                  enlargeCenterPage: false,
                  aspectRatio: 10.0,
                ),
                items: _sliderImages.map((imageUrl) {
                  return Builder(
                    builder: (BuildContext context) {
                      return CachedNetworkImage(
                        imageUrl: imageUrl,
                        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => const Icon(Icons.error),
                        fit: BoxFit.fill,
                      );
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 25),
              Center(
                child: SizedBox(
                  width: 380,
                  child: Material(
                    elevation: 1.5,
                    shadowColor: Colors.grey.withOpacity(0.1),
                    borderRadius: const BorderRadius.all(Radius.circular(30.0)),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filterRestaurantes,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                        hintText: 'Busca opciones cerca de ti',
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10.0)),
                          borderSide: BorderSide(color: Color.fromARGB(131, 230, 230, 230), width: 5.001),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        hintStyle: TextStyle(
                          fontFamily: 'Poppins-L',
                          fontSize: 12,
                          color: Color.fromARGB(255, 150, 150, 150),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Visibility(
                visible: _showCategories,
                child: Center(
                  child: SizedBox(
                    height: 200,
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        return _buildButton(
                          index,
                          _emojis[index],
                          _categories[index],
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              const Padding(
                padding: EdgeInsets.only(left: 10.0),
                child: Text(
                  'Restaurantes cercanos',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: Color.fromARGB(255, 43, 43, 43),
                    fontSize: 12,
                    fontFamily: "Poppins-l",
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).size.height / 1.71,),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filteredRestaurantesData.length,
                  itemBuilder: (context, index) {
                    final Map<String, dynamic> restaurante = _filteredRestaurantesData[index].data() as Map<String, dynamic>;
                    final nombre = restaurante['nombre_restaurante'];
                    final urlLogo = restaurante['url'];
                    final gpsPoint = restaurante['gps_point'] as GeoPoint;
                    final categoria = restaurante['categoria'];
                    final descripcion = restaurante['descripcion'];

                    double distancia = 0.0;
                    if (_currentPosition != null) {
                      distancia = Geolocator.distanceBetween(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                        gpsPoint.latitude,
                        gpsPoint.longitude,
                      ) / 1000;
                    }

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 5.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.09),
                            spreadRadius: 5,
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: RestauranteItem(
                        nombre: nombre,
                        urlLogo: urlLogo,
                        gpsPoint: gpsPoint,
                        categoria: categoria,
                        distancia: distancia,
                        descripcion: descripcion,
                        isSelected: _currentOpenRestaurant?.nombre == nombre,
                        currentPosition: _currentPosition,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const QR_Scanner()),
          );
        },
        backgroundColor: const Color.fromARGB(250, 255, 255, 255),
        foregroundColor: const Color(0xFFB747EB),
        elevation: 7,
        shape: const CircleBorder(eccentricity: 0.5),
        child: const Icon(Icons.qr_code),
      ),
      bottomNavigationBar: BottomAppBar(
        notchMargin: 3,
        shape: const CircularNotchedRectangle(),
        color: const Color.fromARGB(255, 252, 252, 252),
        height: 34,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          mainAxisSize: MainAxisSize.max,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 0.0),
              child: InkWell(
                onTap: () {
                  _scrollController.animateTo(
                    0.0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.ease,
                  );
                },
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 0.0),
              child: InkWell(
                onTap: () {
                  _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.ease,
                  );
                },
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}


  Widget _buildButton(int index, String emoji, String dishName) {
    bool isSelected = index == _selectedButtonIndex;
    double buttonWidth = 20 + dishName.length * 2;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedButtonIndex = index;
          if (index >= 1 && index <= 5) {
            double scrollOffset = index * (buttonWidth + 20);
            _scrollController.animateTo(
              scrollOffset,
              duration: const Duration(milliseconds: 1000),
              curve: Curves.ease,
            );
          }
          _filterRestaurantesByCategory(dishName);
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: buttonWidth,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isSelected ? const Color.fromARGB(255, 183, 71, 235) : Color.fromARGB(255, 243, 243, 243),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ]
              : [],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: Text(
                emoji,
                style: TextStyle(
                  fontSize: 18,
                  color: isSelected ? Color.fromARGB(255, 236, 236, 236) : Color.fromARGB(255, 238, 238, 238),
                ),
              ),
            ),
            const SizedBox(height: 1),
            Text(
              dishName,
              style: TextStyle(
                fontSize: 9,
                color: isSelected ? Colors.white : Colors.black,
                fontFamily: "Poppins-l",
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  static const List<String> _emojis = [
    '🍔', '🍕', '🍗', '🍥', '🌭', '🇮🇹', '🇲🇽', '🐟',
  ];

  static const List<String> _categories = [
    'Burgers', 'Pizza', 'Pollo', 'Sushi', 'HotDog', 'Italiana', 'Mexicana', 'Mar',
  ];

  void _filterRestaurantes(String searchText) {
    setState(() {
      if (searchText.isEmpty) {
        _showCategories = true;  // Mostrar categorías si el campo está vacío
        _filterRestaurantesByCategory(_categories[_selectedButtonIndex]);
      } else {
        _showCategories = false;  // Ocultar categorías si hay texto
        _filterRestaurantesByName(searchText);
      }
    });
  }

  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSettingsMenuItem(Icons.book_sharp, 'Historial de ordenes', () {
                // Implementar acción
              }),
              _buildSettingsMenuItem(Icons.phone, 'Soporte', () {
                // Implementar acción
              }),
              _buildSettingsMenuItem(Icons.person, 'Información personal', () {
                // Implementar acción
              }),
              _buildSettingsMenuItem(Icons.monetization_on, 'Medios de pago', () {
                // Implementar acción
              }),
              _buildSettingsMenuItem(Icons.discount_sharp, 'Cupones', () {
                // Implementar acción
              }),
              _buildSettingsMenuItem(Icons.warning, 'Terminos y condiciones', () {
                // Implementar acción
              }),
              _buildSettingsMenuItem(Icons.exit_to_app, 'Salir de la app', () {
                // Implementar acción
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsMenuItem(IconData icon, String text, Function onTap) {
    return InkWell(
      onTap: () {
        onTap();
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[700]),
            SizedBox(width: 16),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}



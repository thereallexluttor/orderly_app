
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:url_launcher/url_launcher.dart';

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
      onTap: () {
        
      },
      child: Container(
        height: widget.isSelected ? 300 : 120,
        child: Card(
          color: const Color.fromRGBO(255, 255, 255, 1),
          shadowColor: Colors.black,
          margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal:5.0),
          elevation: 0.3,
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
                    fontSize: 11,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: _buildLocationButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

 Widget _buildLocationButton() {
  return Padding(
    padding: const EdgeInsets.only(right: 10), // Ajusta el padding a tu preferencia
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 2,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            iconSize: 20,
            icon: Icon(Icons.location_on, color: Colors.purple),
            onPressed: () {
              _openGoogleMaps();
            },
          ),
        ),
        const SizedBox(height: 0),
        Text(
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
            width: 4,
            color: Color.fromARGB(255, 238, 238, 238),
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
                    fontSize: 13,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(right: 80), // Agrega margen solo a la derecha
                  child: Text(
                    widget.descripcion,
                    style: const TextStyle(
                      fontFamily: "Poppins-l",
                      color: Color.fromARGB(255, 92, 92, 92),
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
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
    "https://firebasestorage.googleapis.com/v0/b/orderly-33eb6.appspot.com/o/1.png?alt=media&token=0b010f6f-1709-4837-a852-199f0cd08a20",
    "https://firebasestorage.googleapis.com/v0/b/orderly-33eb6.appspot.com/o/2.png?alt=media&token=e5087d6e-f3e4-4a69-a9ac-ad7105b04e9a",
    "https://firebasestorage.googleapis.com/v0/b/orderly-33eb6.appspot.com/o/3.png?alt=media&token=524372db-78a1-4f4d-aaf8-5566ca76cbee",
    'https://firebasestorage.googleapis.com/v0/b/orderly-33eb6.appspot.com/o/4.png?alt=media&token=5de7a562-8f6d-4732-930f-fe780b465cda',
  ];
  int _selectedButtonIndex = 0;
  RestauranteItem? _currentOpenRestaurant;
  Map<String, bool> _restaurantSelectionState = {};

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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.only(left: 5),
                child: Image(
                  image: AssetImage("lib/images/logos/orderly_icon3.png"),
                  height: 40,
                  width: 120,
                ),
              ),
              CarouselSlider(
                options: CarouselOptions(
                  autoPlay: true,
                  height: 200,
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
                        fit: BoxFit.scaleDown,
                      );
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 5),
              Center(
                child: SizedBox(
                  width: 320,
                  child: Material(
                    elevation: 5.0,
                    borderRadius: const BorderRadius.all(Radius.circular(30.0)),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 50.0),
                        hintText: '       Busca Opciones cerca de ti',
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Image.asset('lib/images/icons/magnifying-glass.png', width: 5, height: 5,),
                        ),
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(30.0)),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: const Color.fromARGB(255, 255, 255, 255),
                        hintStyle: const TextStyle(
                          fontFamily: 'Poppins-L',
                          fontSize: 13,
                          color: Color.fromARGB(255, 87, 87, 87),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Center(
                child: SizedBox(
                  height: 40,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 0.0),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        const SizedBox(width: 10),
                        _buildButton(0, '🍔', 'Burgers'),
                        const SizedBox(width: 10),
                        _buildButton(1, '🍕', 'Pizza'),
                        const SizedBox(width: 10),
                        _buildButton(2, '🍗', 'Pollo'),
                        const SizedBox(width: 10),
                        _buildButton(3, '🍥', 'Sushi'),
                        const SizedBox(width: 10),
                        _buildButton(4, '🌭', 'HotDog'),
                        const SizedBox(width: 10),
                        _buildButton(5, '🇮🇹', 'Italiana'),
                        const SizedBox(width: 10),
                        _buildButton(6, '🇲🇽', 'Mexicana'),
                        const SizedBox(width: 10),
                        _buildButton(7, '🐟', 'Comida de mar'),
                        const SizedBox(width: 10),
                      ],
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
                    fontSize: 15,
                    fontFamily: "Poppins-l",
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Lista de restaurantes
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
                    if (_currentPosition != null && gpsPoint != null) {
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
                        borderRadius: BorderRadius.circular(15.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 10,
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
                        currentPosition: _currentPosition, // Agregado: pasar la posición actual
                      ),
                    );
                  },
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
    double buttonWidth = 90 + dishName.length * 2;
    return ElevatedButton(
      onPressed: () {
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
      style: ElevatedButton.styleFrom(
        fixedSize: Size(buttonWidth, 40),
        elevation: 1,
        side: const BorderSide(color: Color.fromARGB(255, 236, 236, 236)),
        backgroundColor: isSelected ? Color.fromARGB(255, 183, 71, 235) : Color.fromARGB(255, 134, 134, 134),
        padding: EdgeInsets.zero,
        alignment: Alignment.centerLeft,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(left: 10),
            height: 25,
            width: 25,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Center(
              child: Text(
                emoji,
                style: TextStyle(
                  fontSize: 17,
                  color: isSelected ? const Color.fromARGB(255, 158, 158, 158) : Color.fromARGB(255, 168, 168, 168),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              dishName,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontFamily: "Poppins_l",
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.start,
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: HomePage(),
  ));
}
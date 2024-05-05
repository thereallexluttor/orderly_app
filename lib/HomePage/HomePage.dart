// ignore_for_file: file_names, deprecated_member_use, prefer_const_constructors, use_super_parameters, library_private_types_in_public_api, sized_box_for_whitespace, avoid_print

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
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
  final String urlbanner;
  final GeoPoint gpsPoint;
  final String categoria;
  final double distancia;
  final String descripcion;
  final double calificacion;
  final int tiempo_entrega;
  final bool isSelected;
  final VoidCallback? onMapOpened;
  final VoidCallback? onMapClosed;
  final Position? currentPosition;

  const RestauranteItem({
    Key? key,
    required this.nombre,
    required this.urlLogo,
    required this.urlbanner,
    required this.gpsPoint,
    required this.categoria,
    required this.distancia,
    required this.descripcion,
    required this.calificacion,
    required this.tiempo_entrega,
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
        height: widget.isSelected ? 250 : 175, // Ajusta la altura según sea necesario
        child: Card(
          color: const Color.fromRGBO(255, 255, 255, 1),
          shadowColor: Colors.black,
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15.0),
          elevation: 0.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  _buildBanner(), // Método para construir el banner
                  Expanded(child: _buildContent()),
                   Divider(color: Colors.grey[300], thickness: 1, height: 1), 
                  
                ],
              ),
              Positioned(
                top: 85, // Ajusta esto según la altura del banner y el tamaño del logo
                left: 16, // Ajusta para alinear correctamente el logo desde el borde izquierdo
                child: _buildLogo(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              width: 50,
              height: 10, // Nota: Este Container parece ser un placeholder; considera ajustar su propósito o eliminarlo si no es necesario.
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(25.0),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.nombre,
                    style: TextStyle(
                      fontFamily: "Poppins",
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontWeight: FontWeight.bold,
                      fontSize: 10, // Ajustado para mejorar la legibilidad
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    widget.descripcion,
                    style: TextStyle(
                      fontFamily: "Poppins-l",
                      color: Color.fromARGB(255, 92, 92, 92),
                      fontWeight: FontWeight.bold,
                      fontSize: 8, // Ajustado para mejorar la legibilidad
                    ),
                  ),
                  SizedBox(height: 3),
                  Row(
  children: [
    Container(
      
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2), // Ajusta el padding para un mejor aspecto
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.2), // Color dorado tenue
        borderRadius: BorderRadius.circular(20), // Hace que el container sea ovalado
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          
          Icon(Icons.star, color: Colors.amber, size: 11), // Icono de estrella en dorado
          SizedBox(width: 0),
          Text(
            "${widget.calificacion}",
            style: TextStyle(
              fontFamily: "Poppins",
              fontWeight: FontWeight.bold,
              fontSize: 8,
              color: const Color.fromARGB(255, 0, 0, 0),
            ),
          ),
        ],
      ),
    ),
    SizedBox(width: 10),
    Icon(Icons.access_time, color: Color.fromARGB(255, 0, 0, 0), size: 15, weight:200,), // Icono de reloj en gris
    SizedBox(width: 1),
    Text(
      "${widget.tiempo_entrega} min",
      style: TextStyle(
        fontFamily: "Poppins-l",
        fontWeight: FontWeight.bold,
        fontSize: 8,
        color: Color.fromARGB(255, 105, 105, 105),
      ),
    ),

    SizedBox(width: 10),
    Icon(Icons.run_circle_outlined, color: Color.fromARGB(255, 0, 0, 0), size: 15, weight:200,), // Icono de reloj en gris
    SizedBox(width: 1),
    Text(
                  '${widget.distancia.toStringAsFixed(1)} Km',
                  style: const TextStyle(
                    fontFamily: "Poppins",
                    color: Color.fromARGB(255, 0, 0, 0),
                    fontWeight: FontWeight.normal,
                    fontSize: 9,
                  ),
                ),
  ],
)

                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}



  Widget _buildLogo() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle, // Opción estética: círculo para hacerlo destacar más
        image: DecorationImage(
          image: CachedNetworkImageProvider(widget.urlLogo),
          fit: BoxFit.cover,
        ),
        border: Border.all(color: Colors.white, width: 2), // Borde para destacar sobre fondos complejos
        
      ),
    );
  }

  Widget _buildBanner() {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(15.0)),
      child: CachedNetworkImage(
        imageUrl: widget.urlbanner,
        height: 95, // Altura del banner
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) => const Icon(Icons.error),
      ),
    );
  }


  //   Widget _buildLocationButton() {
  //   return Padding(
  //     padding: const EdgeInsets.only(right: 10),
  //     child: Column(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         Container(
  //           width: 25,
  //           height: 25,
  //           decoration: const BoxDecoration(
  //             shape: BoxShape.circle,
  //             color: Colors.white,
  //             boxShadow: [
  //               BoxShadow(
  //                 color: Colors.grey,
  //                 blurRadius: 2,
  //                 offset: Offset(0, 2), // Cambios de sombra
  //               )
  //             ],
  //           ),
  //           child: IconButton(
  //             padding: EdgeInsets.zero,
  //             iconSize: 15,
  //             icon: const Icon(Icons.location_on, color: Colors.purple),
  //             onPressed: () {
  //               _openGoogleMaps();
  //             },
  //           ),
  //         ),
  //         const SizedBox(height: 2),
  //         const Text(
  //           'Cómo llegar?',
  //           style: TextStyle(
  //             fontFamily: "Poppins",
  //             color: Colors.purple,
  //             fontWeight: FontWeight.normal,
  //             fontSize: 7,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }


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
    "https://firebasestorage.googleapis.com/v0/b/orderlyapp-762a8.appspot.com/o/3.png?alt=media&token=587092b5-970d-40cf-a991-0477d4e731e0",
    "https://firebasestorage.googleapis.com/v0/b/orderlyapp-762a8.appspot.com/o/2.png?alt=media&token=a4d736e2-836d-4806-81bf-fca03b6097ed",
    "https://firebasestorage.googleapis.com/v0/b/orderlyapp-762a8.appspot.com/o/4.png?alt=media&token=bee1b206-a091-4ebc-be3b-148eadd5f6b1"
  ];
  int _selectedButtonIndex = 0;
  RestauranteItem? _currentOpenRestaurant;
  bool _showCategories = true;  // Controla la visibilidad de las categorías
  int _current = 0;  // Index del slider actual
  final CarouselController _carouselController = CarouselController();  // Controlador para CarouselSlider
  final ScrollController _scrollController2 = ScrollController();
  final ScrollController _scrollController3 = ScrollController();
  bool _isCarouselVisible = true;

  
  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _fetchRestaurantesData();
    _scrollController2.addListener(_scrollListener);
    _scrollController3.addListener(_scrollListener);
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
  @override
  void dispose() {
    _scrollController2.removeListener(_scrollListener);
    _scrollController2.dispose();
    _scrollController3.removeListener(_scrollListener);
    _scrollController3.dispose();
    super.dispose();
  }
  void _scrollListener() {
  const thresholddown = 10;  // Establece un umbral de scroll para ocultar/mostrar el carrusel
  bool shouldHide = _scrollController3.offset > thresholddown;
  const thresholdup = 30;  // Establece un umbral de scroll para ocultar/mostrar el carrusel
  bool shouldHide2 = _scrollController3.offset > thresholdup;
  const thresholdup2 = 10;  // Establece un umbral de scroll para ocultar/mostrar el carrusel
  bool shouldHide3 = _scrollController2.offset < thresholdup2;


  if (shouldHide) {
    setState(() {
      _scrollController2.animateTo(_scrollController2.position.maxScrollExtent, duration: Duration(milliseconds: 400), curve: Curves.fastOutSlowIn,);
      _isCarouselVisible = false;
      
    });
  } else if (shouldHide3 ) {
    setState(() {
      _scrollController2.animateTo(0, duration: Duration(milliseconds: 400), curve: Curves.fastOutSlowIn,);
      _isCarouselVisible = true;
      
    });
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
        
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.black),
            onPressed: () {
              _showSettingsMenu(context);
            },
          ),
        ],
        toolbarHeight: 45,
      ),
      
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0.0),
        child: SingleChildScrollView(
          
          
          controller: _scrollController2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
             
              CarouselSlider(
  options: CarouselOptions(
    autoPlay: true,
    height: 120,
    autoPlayCurve: Curves.linear,
    autoPlayAnimationDuration: const Duration(milliseconds: 800),
    autoPlayInterval: const Duration(seconds: 4),
    enlargeCenterPage: false, // Hace que la imagen central sea más grande
    aspectRatio: 10.0,
    viewportFraction: 0.7, // Cubre todo el viewport
    onPageChanged: (index, reason) {
      setState(() {
        _current = index; // Actualiza el índice actual
      });
    },
  ),
  items: _sliderImages.map((imageUrl) {
    return Builder(
      builder: (BuildContext context) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(20.0), // Ajusta el radio aquí para obtener la curvatura deseada
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
            errorWidget: (context, url, error) => const Icon(Icons.error),
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }).toList(),
),
            
// Agrega indicadores debajo del CarouselSlider

   Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: _sliderImages.asMap().entries.map((entry) {
      return GestureDetector(
        onTap: () => _carouselController.animateToPage(entry.key),
        child: Container(
          width: 12.0,
          height: 2.0,
          margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: (Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black).withOpacity(_current == entry.key ? 0.9 : 0.4),
          ),
        ),
      );
    }).toList(),
  ),


              Padding(
  padding: const EdgeInsets.all(8.0),
  child: Center(
    child: SizedBox(
      width: 380,
      child: Material(
        elevation: 3, // Aumenta la elevación para una sombra más prominente
        borderRadius: const BorderRadius.all(Radius.circular(30.0)), // Mantiene el borde redondeado
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Color.fromARGB(255, 235, 235, 235).withOpacity(0.5), // Ajusta la opacidad para controlar la visibilidad de la sombra
                spreadRadius: 1, // Expande la sombra
                blurRadius: 6, // Suaviza el borde de la sombra
                offset: Offset(0, -3), // Mueve la sombra hacia arriba
              )
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _filterRestaurantes,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(vertical: 8.0),
              hintText: 'Busca opciones cerca de ti',
              prefixIcon: Icon(Icons.search, color: Color.fromARGB(255, 173, 67, 187)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10.0)),
                borderSide: BorderSide.none, // Elimina el borde visible
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
  ),
),
const SizedBox(height: 5),

             

              

              const SizedBox(height: 5),
              Padding(
  padding: const EdgeInsets.all(8.0),
  
    child: Center(
      child: SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: _buildButton(
                index,
                _categories[index], // Enviar el nombre de la categoría en lugar del emoji
              ),
            );
          },
        ),
      ),
    ),
 
),

              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.only(left: 10.0),
                child: Text(
                  'Restaurantes cercanos',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: Color.fromARGB(255, 43, 43, 43),
                    fontSize: 12,
                    fontFamily: "Poppins",
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 0),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).size.height / 1.9,),
                  child: ListView.builder(
                    controller: _scrollController3,
                    shrinkWrap: true,
                    itemCount: _filteredRestaurantesData.length,
                    itemBuilder: (context, index) {
                      final Map<String, dynamic> restaurante = _filteredRestaurantesData[index].data() as Map<String, dynamic>;
                      final nombre = restaurante['nombre_restaurante'];
                      final urlLogo = restaurante['url'];
                      final gpsPoint = restaurante['gps_point'] as GeoPoint;
                      final categoria = restaurante['categoria'];
                      final descripcion = restaurante['categoria'];
                      final urlbanner = restaurante['banner'];
                      final calificacion = restaurante['calificacion'];
                      final tiempo_entrega = restaurante['tiempo_entrega'];
                
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
                          // boxShadow: [
                          //   BoxShadow(
                          //     color: Colors.black.withOpacity(0.09),
                          //     spreadRadius: 5,
                          //     blurRadius: 5,
                          //     offset: const Offset(0, 2),
                          //   ),
                          // ],
                        ),
                        child: RestauranteItem(
                          nombre: nombre,
                          urlLogo: urlLogo,
                          urlbanner: urlbanner,
                          gpsPoint: gpsPoint,
                          categoria: categoria,
                          distancia: distancia,
                          descripcion: descripcion,
                          isSelected: _currentOpenRestaurant?.nombre == nombre,
                          currentPosition: _currentPosition,
                          calificacion: calificacion,
                          tiempo_entrega: tiempo_entrega
                        ),
                      );
                    },
                  ),
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
        elevation: 1,
        shape: const CircleBorder(eccentricity: .5),
        child: const Icon(Icons.qr_code),
      ),
      bottomNavigationBar: BottomAppBar(
        notchMargin: 0.5,
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


Widget _buildButton(int index, String dishName) {
  bool isSelected = index == _selectedButtonIndex;
  double buttonSize = 80.0; // Tamaño deseado de las cajas

  // Lista de rutas de las imágenes correspondientes a cada categoría
  List<String> categoryImages = [
    'lib/images/food_categories/burguer.png',
    'lib/images/food_categories/pizza.jpg',
    'lib/images/food_categories/pollo.png',
    'lib/images/food_categories/sushi.jpg',
    'lib/images/food_categories/hotdog.jpg',
    'lib/images/food_categories/italiana.jpg',
    'lib/images/food_categories/mexicana.jpg',
    'lib/images/food_categories/mar.jpg',
  ];

  return GestureDetector(
    onTap: () {
      setState(() {
        _selectedButtonIndex = index;
        if (index >= 1 && index <= 5) {
          double scrollOffset = index * (buttonSize + 20);
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
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        color: isSelected ? const Color.fromARGB(255, 183, 71, 235) : Color.fromARGB(255, 243, 243, 243),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
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
      padding: const EdgeInsets.only(bottom: 10), // Ajuste el padding para empujar el texto hacia abajo
      margin: const EdgeInsets.symmetric(horizontal: 1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start, // Alinea el contenido al final del contenedor
        children: [
          ClipRRect( // ClipRRect para redondear solo la parte superior de la imagen
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: Image.asset(
              categoryImages[index], // Ruta de la imagen correspondiente a la categoría
              width: 100, // Ancho de la imagen
              height: 70, // Altura ajustada de la imagen
              fit: BoxFit.cover, // Asegura que la imagen cubra el espacio disponible
            ),
          ),
          const SizedBox(height: 1), // Espacio entre imagen y texto
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



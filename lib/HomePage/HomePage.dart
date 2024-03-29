import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:orderly_app/QR_scanner/qr_scanner.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();
  final bool _scrollEnabled = false;
  final TextEditingController _searchController = TextEditingController();
  final List<String> _sliderImages = [
    "https://firebasestorage.googleapis.com/v0/b/orderly-33eb6.appspot.com/o/1.png?alt=media&token=0b010f6f-1709-4837-a852-199f0cd08a20",
    "https://firebasestorage.googleapis.com/v0/b/orderly-33eb6.appspot.com/o/2.png?alt=media&token=e5087d6e-f3e4-4a69-a9ac-ad7105b04e9a",
    "https://firebasestorage.googleapis.com/v0/b/orderly-33eb6.appspot.com/o/3.png?alt=media&token=524372db-78a1-4f4d-aaf8-5566ca76cbee",
    'https://firebasestorage.googleapis.com/v0/b/orderly-33eb6.appspot.com/o/4.png?alt=media&token=5de7a562-8f6d-4732-930f-fe780b465cda',
  ];
  int _selectedButtonIndex = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          controller: _scrollController,
          physics: _scrollEnabled ? null : const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 15),
              const Center(
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
            Center(
                child: SizedBox(
                  width: 320,
                  child: Material(
                    elevation: 5.0,
                    borderRadius: const BorderRadius.all(Radius.circular(30.0)),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(vertical: 7.0, horizontal: 50.0),
                        hintText: '       Busca Opciones cerca de ti',
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Image.asset('lib/images/icons/magnifying-glass.png', width: 5, height: 5,), // Reemplaza 'assets/tu_imagen.png' con la ruta de tu imagen
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
                      controller: _scrollController,
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
                        _buildButton(4, '🇮🇹', 'Italiana'),
                        const SizedBox(width: 10),
                        _buildButton(5, '🇲🇽', 'Mexicana'),
                        const SizedBox(width: 10),
                        _buildButton(6, '🐟', 'Comida de mar'),
                      ],
                    ),
                  ),
                ),
              ),
              
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: Container(
          margin: const EdgeInsets.only(top: 0.0),
          child: FloatingActionButton(
            onPressed: () {
             // Navegar a la página QR al presionar el botón flotante
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => QR_Scanner()),
      );
            },
            backgroundColor: const Color.fromARGB(250, 255, 255, 255),
            foregroundColor: const Color(0xFFB747EB),
            elevation: 7,
            shape: const CircleBorder(eccentricity: 0.5),
            child: const Icon(Icons.qr_code),
          ),
        ),
        bottomNavigationBar: BottomAppBar(
          notchMargin: 7.0,
          shape: const CircularNotchedRectangle(),
          color: Color.fromARGB(255, 252, 252, 252),
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
                    children: [
                      
                    ],
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
    double buttonWidth = 90 + dishName.length * 2; // Ajusta el tamaño del botón basado en la longitud del texto del plato
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedButtonIndex = index;
          if (index >= 1 && index <= 4) { // Si el botón seleccionado es a partir del cuarto
            _scrollController.animateTo(index * (buttonWidth + 7), duration: const Duration(milliseconds: 1000), curve: Curves.ease); // Mueve la posición de desplazamiento al botón seleccionado
          }
        });
      },
      style: ElevatedButton.styleFrom(
        fixedSize: Size(buttonWidth, 40),
        elevation: 1,
        side: const BorderSide(color: Color.fromARGB(255, 236, 236, 236)),
        backgroundColor: isSelected ? Color.fromARGB(255, 183, 71, 235) : Color.fromARGB(255, 134, 134, 134),
        padding: EdgeInsets.zero, // Elimina el relleno interno del botón
        alignment: Alignment.centerLeft, // Alinea el contenido del botón a la izquierda
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start, // Alinea los elementos a la izquierda del botón
        children: [
          Container(
            // Ajusta el margen izquierdo del emoji y el círculo blanco
            margin: const EdgeInsets.only(left: 10),
            height: 32, // Altura del círculo blanco
            width: 32, // Ancho del círculo blanco
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white, // Color blanco para el círculo
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
          const SizedBox(width: 8), // Añade un espacio entre el emoji y el texto
          Expanded(
            child: Text(
              dishName,
              style: const TextStyle(
                fontSize: 11,
                color:  Colors.white,
                fontFamily: "Poppins_l",
                fontWeight: FontWeight.bold
              ),
              textAlign: TextAlign.start, // Alinea el texto a la izquierda del botón
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

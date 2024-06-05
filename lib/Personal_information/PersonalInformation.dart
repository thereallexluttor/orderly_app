// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:orderly_app/HomePage/HomePage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class PersonalInformation extends StatefulWidget {
  const PersonalInformation({Key? key}) : super(key: key);

  @override
  _PersonalInformationState createState() => _PersonalInformationState();
}

class _PersonalInformationState extends State<PersonalInformation> {
  String? gender;
  double? latitude;
  double? longitude;
  DateTime? birthdate;
  String? phoneNumber;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    _getUserLocation();
  }

  void _requestLocationPermission() async {
    if (await Permission.location.isGranted) {
      return;
    }
    final status = await Permission.location.request();
    if (status != PermissionStatus.granted) {
      // Handle the situation when the user doesn't grant permission
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                const Center(
                  child: Image(
                    image: AssetImage("lib/images/logos/orderly_icon3.png"),
                    height: 100,
                    width: 100,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Información Personal',
                  style: TextStyle(
                    fontSize: 22,
                    fontFamily: "Poppins-Bold",
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 26),
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Color.fromARGB(255, 223, 223, 223)),
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Selecciona tu género:',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: "Poppins-L",
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            'lib/images/animations/man.gif',
                            width: 20,
                            height: 20,
                          ),
                          Radio<String>(
                            activeColor: Colors.black,
                            value: 'Hombre',
                            groupValue: gender,
                            onChanged: (value) {
                              setState(() {
                                gender = value;
                              });
                            },
                          ),
                          const Text(
                            'Hombre',
                            style: TextStyle(
                              fontSize: 15,
                              fontFamily: "Poppins-L",
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: Colors.grey,
                      ),
                      Row(
                        children: [
                          Image.asset(
                            'lib/images/animations/woman.gif',
                            width: 25,
                            height: 25,
                          ),
                          Radio<String>(
                            activeColor: Colors.black,
                            value: 'Mujer',
                            groupValue: gender,
                            onChanged: (value) {
                              setState(() {
                                gender = value;
                              });
                            },
                          ),
                          const Text(
                            'Mujer',
                            style: TextStyle(
                              fontSize: 15,
                              fontFamily: "Poppins-L",
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                ],
                ),
              ),
                const SizedBox(height: 29),
                Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color.fromARGB(255, 221, 221, 221)),
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (birthdate == null)
                      const Padding(
                        padding: EdgeInsets.only(left: 16.0, top: 8.0, right: 16.0),
                        child: Text(
                          'La fecha de nacimiento debe ser seleccionada para avanzar',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: FormBuilderDateTimePicker(
                        name: 'Fecha de nacimiento',
                        initialValue: birthdate ?? DateTime(2001),
                        inputType: InputType.date,
                        decoration: InputDecoration(
                          labelText: 'Fecha de nacimiento',
                          border: InputBorder.none,
                        ),
                        onChanged: (value) {
                          setState(() {
                            birthdate = value;
                          });
                        },
                      ),
                    ),
                    Divider(
                      color: Colors.grey[400],
                      height: 0,
                    ),
                  ],
                ),
              ),
                SizedBox(height: 29),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Color.fromARGB(255, 221, 221, 221)),
                    borderRadius: BorderRadius.circular(15.0),
                    // boxShadow: [
                    //   BoxShadow(
                    //     color: Colors.grey.withOpacity(0.3),
                    //     spreadRadius: 2,
                    //     blurRadius: 5,
                    //     offset: const Offset(0, 3),
                    //   ),
                    // ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        InternationalPhoneNumberInput(
                          onInputChanged: (PhoneNumber number) {
                            setState(() {
                              phoneNumber = number.phoneNumber;
                            });
                          },
                          selectorConfig: const SelectorConfig(
                            selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                          ),
                          textStyle: const TextStyle(fontSize: 16),
                          inputDecoration: const InputDecoration(
                            labelText: 'Número de teléfono',
                            border: InputBorder.none,
                          ),
                          initialValue: PhoneNumber(isoCode: 'CO'),
                        ),
                        Divider(
                          color: Colors.grey[400],
                          height: 0,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 56),
                ElevatedButton(
  onPressed: isInformationComplete() ? () => savePersonalInformation() : null,
  style: ElevatedButton.styleFrom(
    foregroundColor: Colors.white, backgroundColor: Colors.purple, // Color del texto
    textStyle: const TextStyle(
      fontFamily: 'Poppins-Bold', // Fuente del texto
      fontSize: 16, // Tamaño del texto
    ),
  ),
  child: const Text('Guardar información'),
)

              ],
            ),
          ),
        ),
      ),
    );
  }

  bool isInformationComplete() {
    return gender != null && birthdate != null && phoneNumber != null;
  }

  void _getUserLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
      });
    } catch (e) {
      print('Error getting user location: $e');
    }
  }

  void savePersonalInformation() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await FirebaseFirestore.instance.collection('Orderly').doc('Users').collection('users').doc(user.uid).set({
        'email': user.email,
        'name': user.displayName,
        'photo': user.photoURL,
        'gender': gender,
        'latitude': latitude,
        'longitude': longitude,
        'birthdate': birthdate,
        'phoneNumber': phoneNumber,
      }).then((value) {
        _setPersonalInfoCompleted();
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage()));
      }).catchError((error) {
        print('Error saving personal information: $error');
      });
    }
  }

  void _setPersonalInfoCompleted() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('personalInfoCompleted', true);
  }
}

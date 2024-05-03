// ignore_for_file: unused_field, unused_import, unused_local_variable, avoid_print, use_build_context_synchronously

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:comar_insurance/pages/retrieve.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart' hide Location;

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MapPage> {
  final Location _locationController = Location();
  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();
  static const LatLng _pGooglePlex = LatLng(37.4223, -122.0848);
  static const LatLng _pApplePark = LatLng(37.3346, -122.0090);
  LatLng? _currentP;

  final TextEditingController _currentLocationController =
      TextEditingController();

  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _peopleTrappedController =
      TextEditingController();

  bool isLoading = false;
  bool _isAccidentChecked = false;
  bool _isMalfunctionChecked = false;
  String? _selectedIssue = 'Battery failure';

  CollectionReference users = FirebaseFirestore.instance.collection('asuré');

  Future<String> getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String address = [
          if (place.street != null) place.street!,
          if (place.subLocality != null) place.subLocality!,
          if (place.locality != null) place.locality!,
          if (place.postalCode != null) place.postalCode!,
          if (place.country != null) place.country!,
        ].join(", ");
        print(
            "Address: $address"); // Ajoutez ceci pour voir l'adresse formatée.
        return address;
      } else {
        return "No address available";
      }
    } catch (e) {
      print("Failed to retrieve the address: $e");
      return "Error retrieving address"; // Retour en cas d'erreur
    }
  }

  confirmInfo() async {
    final user =
        FirebaseAuth.instance.currentUser; // Récupérer l'utilisateur actuel
    if (user != null) {
      // Si un utilisateur est connecté, obtenez son UID
      String uid = user.uid;
      CollectionReference users =
          FirebaseFirestore.instance.collection('assuré');
      return users
          .doc(uid)
          .set({
            'currentLoc': _currentLocationController.text,
            'phoneNumbr': _phoneNumberController.text,
            'peopleTrap': _peopleTrappedController.text,
            'accident': _isAccidentChecked,
            'malfunction': _isMalfunctionChecked,
            'issueType': _isMalfunctionChecked ? _selectedIssue : null,
          })
          .then((value) => print("information confirmed!"))
          .catchError(
              (error) => print("Failed to confirm information: $error"));
    } else {
      // Gérer le cas où aucun utilisateur n'est connecté
      print("No confirmed information");
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    _currentLocationController.dispose();
    _phoneNumberController.dispose();
    _peopleTrappedController.dispose();
    super.dispose();
  }

  Future<void> _confirmDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible:
          false, // L'utilisateur doit appuyer sur un bouton pour fermer la boîte de dialogue.
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmation'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to confirm these informations?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Ferme la boîte de dialogue
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () async {
                await confirmInfo();
                Navigator.of(context).pop(); // Ferme la boîte de dialogue
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) =>
                          const Retrieve()), // Navigue vers l'interface Retrieve
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    getLocationUpdates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _currentP == null
              ? const Center(
                  child: Text("loading..."),
                )
              : GoogleMap(
                  onMapCreated: ((GoogleMapController controller) =>
                      _mapController.complete(controller)),
                  initialCameraPosition: const CameraPosition(
                    target: _pGooglePlex,
                    zoom: 13,
                  ),
                  markers: {
                    Marker(
                        markerId: const MarkerId("_currentLocation"),
                        icon: BitmapDescriptor.defaultMarker,
                        position: _currentP!),
                    const Marker(
                        markerId: MarkerId("_sourceLocation"),
                        icon: BitmapDescriptor.defaultMarker,
                        position: _pGooglePlex),
                    const Marker(
                        markerId: MarkerId("_destinationLocation"),
                        icon: BitmapDescriptor.defaultMarker,
                        position: _pApplePark)
                  },
                ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      controller: _currentLocationController,
                      readOnly: true, // Empêcher la modification manuelle
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Current Location :',
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Colors.indigo[900]!), // Bordure en focus
                        ),
                        floatingLabelStyle:
                            TextStyle(color: Colors.indigo[900]!),
                        prefixIcon: const Icon(Icons.location_on),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 13.0),

                    TextField(
                      controller: _phoneNumberController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Phone Number :',
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Colors.indigo[900]!), // Bordure en focus
                        ),
                        floatingLabelStyle:
                            TextStyle(color: Colors.indigo[900]!),
                        prefixIcon: const Icon(Icons.phone),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 13.0),
                    TextField(
                      controller: _peopleTrappedController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'People Trapped :',
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Colors.indigo[900]!), // Bordure en focus
                        ),
                        floatingLabelStyle:
                            TextStyle(color: Colors.indigo[900]!),
                        prefixIcon: const Icon(Icons.people),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    CheckboxListTile(
                      title: const Text('Accident'),
                      value: _isAccidentChecked,
                      onChanged: (bool? value) {
                        setState(() {
                          _isAccidentChecked = value ?? false;
                          if (_isAccidentChecked) {
                            _isMalfunctionChecked = false;
                          }
                        });
                      },
                      activeColor: Colors.indigo[900]!,
                      checkColor: Colors.white,
                    ),
                    CheckboxListTile(
                      title: const Text('Malfunction'),
                      value: _isMalfunctionChecked,
                      onChanged: (bool? value) {
                        setState(() {
                          _isMalfunctionChecked = value ?? false;
                          if (_isMalfunctionChecked) {
                            _isAccidentChecked = false;
                          }
                        });
                      },
                      activeColor: Colors.indigo[900]!,
                      checkColor: Colors.white,
                    ),
                    // Afficher le DropdownButton seulement si 'Malfunction' est coché
                    if (_isMalfunctionChecked)
                      DropdownButton<String>(
                        value: _selectedIssue,
                        items: <String>[
                          'Battery failure',
                          'Mechanical failure',
                          'Electrical issues',
                          'Flat tire',
                          'Engine overheating',
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedIssue = newValue;
                          });
                        },
                      ),
                    const SizedBox(height: 13.0),

                    ElevatedButton(
                      onPressed: () async {
                        await _confirmDialog();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.indigo[800], // Couleur de fond du bouton
                      ),
                      child: const Text(
                        'Confirm Information',
                        style: TextStyle(
                          fontWeight: FontWeight.bold, // Rendre le texte gras
                          color: Colors.white, // Définir la couleur du texte
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cameraToPosition(LatLng pos) async {
    final GoogleMapController controller = await _mapController.future;
    CameraPosition newCameraPosition = CameraPosition(
      target: pos,
      zoom: 13,
    );
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(newCameraPosition),
    );
  }

  Future<void> getLocationUpdates() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await _locationController.serviceEnabled();
    if (serviceEnabled) {
      serviceEnabled = await _locationController.requestService();
    } else {
      return;
    }

    permissionGranted = await _locationController.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationController.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationController.onLocationChanged
        .listen((LocationData currentLocation) async {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        setState(() {
          _currentP =
              LatLng(currentLocation.latitude!, currentLocation.longitude!);
          _cameraToPosition(_currentP!);
          //_currentLocationController.text =
          //  '${currentLocation.latitude}, ${currentLocation.longitude}';
        });

        // Convertir les coordonnées en une adresse
        String address = await getAddressFromLatLng(_currentP!);
        setState(() {
          _currentLocationController.text = address;
        });
      }
    });
  }
}

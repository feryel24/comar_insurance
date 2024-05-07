// ignore_for_file: unused_field, unused_import, unused_local_variable, avoid_print, use_build_context_synchronously, invalid_return_type_for_catch_error

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:comar_insurance/pages/retrieve.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart' hide Location;
import 'package:intl/intl.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MapPage> {
  TimeOfDay? _selectedTime;

  static const LatLng _fsegnLocation =
      LatLng(36.43506845297947, 10.690172016620606);
  final Location _locationController = Location();
  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();
  static const LatLng _pGooglePlex = LatLng(37.4223, -122.0848);
  static const LatLng _pApplePark = LatLng(37.3346, -122.0090);
  LatLng? _currentP = _fsegnLocation;

  final TextEditingController _currentLocationController =
      TextEditingController();

  bool isLoading = false;
  bool _isAccidentChecked = false;
  bool _isMalfunctionChecked = false;
  String? _selectedIssue = 'Battery failure';

  CollectionReference users = FirebaseFirestore.instance.collection('insured');

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
          FirebaseFirestore.instance.collection('insured');
      String formattedTime = _selectedTime != null
          ? formatTimeOfDay(_selectedTime!)
          : 'No time selected';
      DocumentReference docRef =
          users.doc(uid); // Récupère la référence du document
      String documentId = docRef.id; // Récupère l'ID du document
      return users.doc(uid).set({
        'currentLoc': _currentLocationController.text,
        'selectedTime': formattedTime,
        'accident': _isAccidentChecked,
        'malfunction': _isMalfunctionChecked,
        'issueType': _isMalfunctionChecked ? _selectedIssue : null,
        'insured_id': documentId
      }).then((value) {
        print("Information confirmed!");
        Navigator.of(context).push(
          MaterialPageRoute(
              builder: (context) =>
                  const Retrieve()), // Naviguez vers l'interface Retrieve après la confirmation
        );
      }).catchError((error) => print("Failed to confirm information: $error"));
    } else {
      // Gérer le cas où aucun utilisateur n'est connecté
      print("No confirmed information");
    }
    setState(() {
      isLoading = false;
    });
  }

  void _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  String formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    final format = DateFormat.jm(); // ou 'HH:mm' pour le format 24 heures
    return format.format(dt);
  }

  @override
  void dispose() {
    _currentLocationController.dispose();
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
              onPressed: () {
                Navigator.of(context).pop(); // Ferme la boîte de dialogue
                confirmInfo(); // Appel de la méthode pour sauvegarder les informations
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
    _currentLocationController.text = 'Error retrieving address';
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
                    ListTile(
                      title: Text(
                          'Selected Time: ${_selectedTime?.format(context) ?? 'No time selected.'}'),
                      trailing: Icon(Icons.keyboard_arrow_down),
                      onTap: () => _selectTime(context),
                    ),
                    ElevatedButton(
                      onPressed: () => _selectTime(context),
                      child: Text('Select Time'),
                    ),

                    const SizedBox(height: 13.0),
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
                    const SizedBox(height: 13.0),
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
                      onPressed: _confirmDialog,
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

    // Définir une localisation par défaut au lancement de l'application
    LatLng defaultLocation = const LatLng(36.8065, 10.1815); // Exemple: Tunis
    _cameraToPosition(
        defaultLocation); // Positionne la carte sur la localisation par défaut

    serviceEnabled = await _locationController.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationController.requestService();
      if (!serviceEnabled) {
        _cameraToPosition(_fsegnLocation);
        return;
      }
    }

    permissionGranted = await _locationController.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationController.requestPermission();
      if (permissionGranted == PermissionStatus.granted) {
        // Permission accordée, on change le texte pour simuler le succès.
        setState(() {
          _currentLocationController.text =
              'Faculty of Economics and Management of Nabeul, Nabeul';
        });
      } else {
        // Permission refusée, on laisse le message d'erreur.
        setState(() {
          _currentLocationController.text = 'Error retrieving address';
        });
      }
    } else if (permissionGranted == PermissionStatus.granted) {
      // Permission déjà accordée avant, on met directement l'adresse.
      setState(() {
        _currentLocationController.text =
            'Faculty of Economics and Management of Nabeul, Nabeul';
      });
    }

    _currentP = _fsegnLocation;
    _cameraToPosition(_fsegnLocation);
  }

  void setDefaultLocation() {
    setState(() {
      _currentP = _fsegnLocation;
      _cameraToPosition(_currentP!);
    });
  }
}

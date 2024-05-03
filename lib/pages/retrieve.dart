// ignore_for_file: unused_field, unused_import, unused_local_variable, avoid_print

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Retrieve extends StatefulWidget {
  const Retrieve({super.key});

  @override
  State<Retrieve> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<Retrieve> {
  BitmapDescriptor? customIcon;
  static const LatLng _fsegnLocation =
      LatLng(36.43506845297947, 10.690172016620606);
  final Location _locationController = Location();
  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();
  static const LatLng _pGooglePlex = LatLng(37.4223, -122.0848);
  static const LatLng _pApplePark = LatLng(37.3346, -122.0090);
  LatLng? _currentP = _fsegnLocation;

  // Ajoutez une liste de conducteurs pour la démo
  final List<Map<String, dynamic>> drivers = [
    {'name': 'Driver 1', 'details': '15 min', 'image': 'images/car.PNG'},
    {'name': 'Driver 2', 'details': '20 min', 'image': 'images/car.PNG'},
    {'name': 'Driver 3', 'details': '25 min', 'image': 'images/car.PNG'},
  ];

  String _buttonText = 'Select Driver'; // Texte initial du bouton
  int _selectedDriverIndex = -1; // -1 signifie aucun conducteur sélectionné

  @override
  void initState() {
    super.initState();
    createMarkerIcon();
    getLocationUpdates();
  }

  void createMarkerIcon() async {
    final icon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/images/remorquage.png',
    );
    setState(() {
      customIcon = icon;
    });
  }

  @override
  Widget build(BuildContext context) {
    Set<Marker> markers = (_currentP != null && customIcon != null)
        ? createMarkersAroundLocation(_currentP!)
        : {};

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _currentP ??
                  _pGooglePlex, // Utilisez la position actuelle ici
              zoom: 18,
            ),
            markers: markers,
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
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: drivers.length,
                      itemBuilder: (context, index) {
                        bool isSelected = index == _selectedDriverIndex;
                        return Container(
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue[50] : Colors.white,
                            border: Border(
                                bottom: BorderSide(
                                    width: 1.0, color: Colors.grey[300]!)),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: Colors.blue[100]!,
                                  spreadRadius: 1,
                                  blurRadius: 3,
                                ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20.0, vertical: 10.0),
                            leading: CircleAvatar(
                              // Ici, nous utilisons Image.asset pour charger des images locales

                              backgroundColor: Colors.grey[200],
                              backgroundImage:
                                  const AssetImage('assets/images/car.PNG'),
                              radius: 30.0,
                            ),
                            title: Text(
                              drivers[index]['name'],
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              drivers[index]['details'],
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            onTap: () {
                              setState(() {
                                _selectedDriverIndex = index;
                                _buttonText =
                                    'Select ${drivers[index]['name']}';
                              });
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 13.0),
                    ElevatedButton(
                      onPressed: () async {
                        // Ajoutez la logique de sélection du conducteur
                      },
                      // ... styles du bouton
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.indigo[800], // Couleur de fond du bouton
                      ),
                      child: Text(
                        _buttonText,
                        // ... styles du texte
                        style: const TextStyle(
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

  void _onMapCreated(GoogleMapController controller) {
    _mapController.complete(controller);
  }

  Set<Marker> createMarkersAroundLocation(LatLng currentLocation) {
    double offset = 0.002; // Augmenté l'offset pour plus de distance

    return {
      Marker(
        markerId: const MarkerId("location"),
        position: currentLocation,
        icon: BitmapDescriptor.defaultMarker,
      ),
      Marker(
        markerId: const MarkerId("remorquage_1"),
        position: LatLng(
            currentLocation.latitude + offset, currentLocation.longitude),
        icon: customIcon ?? BitmapDescriptor.defaultMarker,
      ),
      Marker(
        markerId: const MarkerId("remorquage_2"),
        position: LatLng(
            currentLocation.latitude, currentLocation.longitude + offset),
        icon: customIcon ?? BitmapDescriptor.defaultMarker,
      ),
      Marker(
        markerId: const MarkerId("remorquage_3"),
        position: LatLng(
            currentLocation.latitude - offset, currentLocation.longitude),
        icon: customIcon ?? BitmapDescriptor.defaultMarker,
      ),
      // Vous pouvez ajouter d'autres marqueurs si nécessaire, en ajustant leurs positions de manière similaire
    };
  }

  Future<void> _cameraToPosition(LatLng position) async {
    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
          CameraPosition(target: position, zoom: 17)),
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
        _cameraToPosition(
            _fsegnLocation); // Centre sur FSEGN Nabeul si le service n'est pas activé
        return;
      }
    }

    permissionGranted = await _locationController.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationController.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        _cameraToPosition(
            _fsegnLocation); // Centre sur FSEGN Nabeul si la permission n'est pas accordée
        return;
      }
    }

    // Si la permission est accordée, centrez immédiatement sur FSEGN Nabeul
    _currentP = _fsegnLocation;
    _cameraToPosition(_fsegnLocation);
    createMarkersAroundLocation(
        _fsegnLocation); // Assurez-vous que cette méthode ajuste correctement les marqueurs
  }

  void setDefaultLocation() {
    // Cette fonction définira la caméra sur la localisation de la FSEGN
    setState(() {
      _currentP = _fsegnLocation;
      _cameraToPosition(_currentP!);
    });
  }
}

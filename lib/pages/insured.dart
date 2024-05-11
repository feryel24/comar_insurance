// ignore_for_file: unused_field, unused_import, unused_local_variable, avoid_print, use_build_context_synchronously, invalid_return_type_for_catch_error

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:comar_insurance/pages/retrieve.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  File? _image;
  final picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, dynamic>? _userProfile;
  TimeOfDay? _selectedTime;
  Location _location = Location();
  StreamSubscription<LocationData>? _locationSubscription;
  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();
  Set<Marker> _markers = {};

  LatLng _currentPosition =
      LatLng(36.43506845297947, 10.690172016620606); // Position initiale
  final TextEditingController _currentLocationController =
      TextEditingController();

  bool _isAccidentChecked = false;
  bool _isMalfunctionChecked = false;
  String? _selectedIssue = 'Battery failure';
  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future uploadImage(String userId) async {
    if (_image == null) {
      print('No image selected to upload.');
      return;
    }

    String fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    FirebaseStorage storage = FirebaseStorage.instance;

    try {
      // Upload image to Firebase Storage
      TaskSnapshot snapshot =
          await storage.ref().child(fileName).putFile(_image!);
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // Log the URL to check if it's retrieved successfully
      print('Download URL: $downloadUrl');

      // Store download URL in Firestore
      await FirebaseFirestore.instance
          .collection('userss')
          .doc(userId)
          .update({'image': downloadUrl});

      print('Image URL updated in Firestore.');
    } catch (e) {
      // Log any errors that occur
      print('Error uploading image or updating Firestore: $e');
    }
  }

  Future getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
        // Retrieve the user ID from Firebase Authentication
        String? userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId != null) {
          uploadImage(userId);
        } else {
          print('User ID is null');
        }
      } else {
        print('No image selected.');
      }
    });
  }

  Future<void> _fetchUserProfile() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      print('Current User Email: ${currentUser.email}');
      var snapshot = await _firestore
          .collection('userss')
          .where('email', isEqualTo: currentUser.email)
          .where('insured', isEqualTo: true)
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _userProfile = snapshot.docs.first.data();
          print('User Profile Loaded: $_userProfile');
        });
      } else {
        print('No matching user profile found in Firestore.');
      }
    } else {
      print('No authenticated user found.');
    }
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _mapController.complete(controller);
    await _startLocationUpdates();
  }

  Future<String> getAddressFromLatLng(double latitude, double longitude) async {
    String apiKey =
        'AIzaSyBD7dFSfZdBDi9LWAQmKjqQqyarmWw8AKM'; // Replace with your actual Google Maps API key
    String url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        // Assuming the response format is correct
        if (data['results'].isNotEmpty) {
          String address = data['results'][0]['formatted_address'];
          return address;
        }
        return "No address available";
      } else {
        return "Failed to retrieve address";
      }
    } catch (e) {
      return "Error retrieving address: $e";
    }
  }

  Future<void> _startLocationUpdates() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationSubscription?.cancel();
    _locationSubscription = _location.onLocationChanged
        .listen((LocationData currentLocation) async {
      String address = await getAddressFromLatLng(
          currentLocation.latitude!, currentLocation.longitude!);
      setState(() {
        _currentPosition =
            LatLng(currentLocation.latitude!, currentLocation.longitude!);
        _updateMarkers(_currentPosition);
        _currentLocationController.text = address;
      });
      _updateCameraPosition(_currentPosition);
    });
  }

  void _updateMarkers(LatLng newPosition) {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId("currentPosition"),
          position: newPosition,
          icon: BitmapDescriptor.defaultMarker,
        ),
      };
    });
  }

  Future<void> _updateCameraPosition(LatLng newPosition) async {
    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target: newPosition,
      zoom: 15.0,
    )));
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _currentLocationController.dispose();
    super.dispose();
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

  void confirmInfo() async {
    // Ici, vous pouvez ajouter votre logique pour sauvegarder les informations
    // comme la création ou la mise à jour d'un document dans Firestore.
    print("Confirming information...");

    // Exemple de navigation vers une autre page après confirmation.
    // Remplacez 'RetrievePage' par le nom de votre page de destination.
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            const Retrieve(), // Assurez-vous que la classe Retrieve est bien définie dans votre projet.
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('COMAR')),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Column(
                children: [
                  Text(
                    'User Profile',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                  SizedBox(height: 10), // Space between text and avatar
                  GestureDetector(
                    onTap: getImage,
                    child: CircleAvatar(
                      backgroundImage:
                          _image != null ? FileImage(_image!) : null,
                      radius: 40,
                      child: _image == null
                          ? Icon(Icons.add_a_photo, color: Colors.white)
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            if (_userProfile != null) ...[
              ListTile(
                leading: Icon(Icons.email),
                title: Text(_userProfile?['email'] ?? 'No email'),
              ),
              ListTile(
                leading: Icon(Icons.phone),
                title: Text(_userProfile?['phoneNumbr'] ?? 'No phone number'),
              ),
              ListTile(
                leading: Icon(Icons.person),
                title: Text(_userProfile?['username'] ?? 'No username'),
              ),
            ] else
              ListTile(
                title: Text('No user profile loaded.'),
              ),
          ],
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 13.0,
            ),
            markers: _markers,
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
                    TextFormField(
                      controller: _currentLocationController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Current Location :',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your location';
                        }
                        return null;
                      },
                    ),
                    ListTile(
                      title: Text(
                          'Selected Time: ${_selectedTime?.format(context) ?? 'No time selected.'}'),
                      onTap: () => _selectTime(context),
                    ),
                    CheckboxListTile(
                      title: const Text('Accident'),
                      value: _isAccidentChecked,
                      onChanged: (bool? value) {
                        setState(() {
                          _isAccidentChecked = value ?? false;
                          _isMalfunctionChecked = !value!;
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Malfunction'),
                      value: _isMalfunctionChecked,
                      onChanged: (bool? value) {
                        setState(() {
                          _isMalfunctionChecked = value ?? false;
                          _isAccidentChecked = !value!;
                        });
                      },
                    ),
                    if (_isMalfunctionChecked)
                      DropdownButtonFormField<String>(
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select an issue';
                          }
                          return null;
                        },
                      ),
                    ElevatedButton(
                      onPressed: confirmInfo,
                      child: const Text('Confirm Information'),
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
}

// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously, unused_local_variable
//import 'dart:html';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:comar_insurance/shared/snackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Welcome extends StatefulWidget {
  const Welcome({super.key});

  @override
  State<Welcome> createState() => _WelcomeState();
}

class _WelcomeState extends State<Welcome> {
  bool isVisible = true;
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> signIn(BuildContext context) async {
    final username = usernameController.text;
    final password = passwordController.text;

    // Assurez-vous que les champs ne sont pas vides
    if (username.isEmpty || password.isEmpty) {
      showSnackBar(context, "Please retry with valid informations!");
      return;
    }

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('userss')
          .where('username', isEqualTo: username)
          .get();

      if (querySnapshot.docs.isEmpty) {
        showSnackBar(context, "Please retry with valid informations!");
        return;
      }

      final userDoc = querySnapshot.docs.first;
      final email = userDoc.data()['email'] as String;

      // Une autre vérification d'erreur pourrait être ici pour l'email null

      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      Navigator.pushNamed(context, '/insured');
    } catch (e) {
      // Vous pouvez affiner la gestion des exceptions en fonction du type d'erreur
      print(e); // Pour le débogage
      Navigator.pushNamed(context, '/register');
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //definition des couleurs personnalise
    Color focusColor =
        Colors.indigo[900]!; // Couleur lorsqu'un TextField est sélectionné
    Color buttonColor = Colors.indigo[800]!; // Couleur de fond pour les boutons

    // Utiliser un widget Theme pour définir le style des enfants
    return Theme(
      data: ThemeData(
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: focusColor),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
              foregroundColor: buttonColor, backgroundColor: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor, // Couleur de fond pour ElevatedButton
            foregroundColor:
                Colors.grey, // Couleur du texte pour ElevatedButton
          ),
        ),
      ),
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            // Ajout du SingleChildScrollView
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Container(
                  margin: const EdgeInsets.only(
                      top:
                          68.0), // Ajustez la valeur en fonction de vos besoins
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      "assets/images/img1.png",
                      fit: BoxFit.cover,
                      height: 100,
                    ),
                  ),
                ),
                const SizedBox(height: 38.0),
                const Text(
                  'Welcome to COMAR application!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Color.fromARGB(255, 247, 9, 9),
                      fontSize: 34.0,
                      fontFamily: "myfont"),
                ),
                const SizedBox(height: 48.0),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: <Widget>[
                      TextField(
                        controller: usernameController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Username : ',
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors.indigo[900]!), // Bordure en focus
                          ),
                          floatingLabelStyle:
                              TextStyle(color: Colors.indigo[900]!),
                          prefixIcon: const Icon(Icons.person),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 13.0),
                      TextField(
                        controller: passwordController,
                        obscureText: isVisible ? true : false,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors.indigo[900]!), // Bordure en focus
                          ),
                          floatingLabelStyle:
                              TextStyle(color: Colors.indigo[900]!),
                          labelText: 'Password : ',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                isVisible = !isVisible;
                              });
                            },
                            icon: isVisible
                                ? const Icon(Icons.visibility)
                                : const Icon(Icons.visibility_off),
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24.0),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.indigo[800], // Couleur de fond du bouton
                        ),
                        onPressed: () => signIn(context),
                        child: const Text(
                          'Sign in',
                          style: TextStyle(
                            fontWeight: FontWeight.bold, // Rendre le texte gras
                            color: Colors.white, // Définir la couleur du texte
                          ),
                        ),
                      ),
                      TextButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                              255, 190, 204, 214), // Couleur de fond du bouton
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, '/Forgotten_password');
                        },
                        child: const Text(
                          'Did you forget your password?',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

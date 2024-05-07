// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously, unused_local_variable, avoid_print
//import 'dart:html';

//import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:comar_insurance/shared/snackbar.dart';
import 'package:comar_insurance/pages/insured.dart';
import 'package:comar_insurance/pages/register.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Welcome extends StatefulWidget {
  const Welcome({super.key});

  @override
  State<Welcome> createState() => _WelcomeState();
}

class _WelcomeState extends State<Welcome> {
  bool usingStandardPassword = false;

  bool isVisible = true;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void showSnackbar(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  String handleError(FirebaseAuthException e) {
    switch (e.code) {
      case 'auth/user-not-found':
        return 'User not found, please contact our agency! THANKS.';
      case 'auth/wrong-password':
        return 'Incorrect password, try again.';
      case 'auth/invalid-email':
        return 'The email address is badly formatted.';
      case 'auth/invalid-credential':
        return 'User not found, please contact our agency! THANKS..';
      default:
        return 'An error occurred: ${e.message}';
    }
  }

  Future<void> signIn(BuildContext context) async {
    String enteredEmail = emailController.text.trim();
    String enteredPassword = passwordController.text.trim();

    if (enteredEmail.isEmpty || enteredPassword.isEmpty) {
      showSnackbar(context, 'Please enter email and password');
      return;
    }

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: enteredEmail,
        password: enteredPassword,
      );

      // Vérifier si le mot de passe utilisé est le mot de passe standard
      if (enteredPassword == "123456") {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Register(usingStandardPassword: true),
          ),
        );
      } else {
        // Redirigez vers MapPage si l'utilisateur a déjà mis à jour son mot de passe
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  MapPage()), // Assurez-vous que MapPage est correctement défini
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        showSnackbar(context, 'Incorrect password, try again.');
      } else {
        // Gérer les autres erreurs potentielles
        showSnackbar(context, handleError(e));
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
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
                      TextFormField(
                        //we return "null" when something is valid
                        validator: (email) {
                          return email!.contains(RegExp(
                                  r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+"))
                              ? null
                              : "Enter a valid email";
                        },
                        autovalidateMode: AutovalidateMode.onUserInteraction,

                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Enter Your Email : ',
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors.indigo[900]!), // Bordure en focus
                          ),
                          floatingLabelStyle:
                              TextStyle(color: Colors.indigo[900]!),
                          prefixIcon: const Icon(Icons.email),
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

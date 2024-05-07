import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:comar_insurance/pages/welcome.dart';
import 'package:comar_insurance/shared/snackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Register extends StatefulWidget {
  //modification du constructeur
  final bool usingStandardPassword;
  // ignore: use_super_parameters
  const Register({Key? key, required this.usingStandardPassword})
      : super(key: key);

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  bool isVisible = true;

  bool _isInsuredChecked = false;
  bool _isDriverChecked = false;

  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  final emailController = TextEditingController();
  final newPasswordController = TextEditingController();
  final usernameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();

  bool isPassword8char = false;
  bool isPasswordHasNumber = false;
  bool hasUppercase = false;
  bool hasLowercase = false;
  bool hasSpecialCharacters = false;

  onPasswordChanged(String password) {
    isPassword8char = false;
    isPasswordHasNumber = false;
    hasUppercase = false;
    hasLowercase = false;
    hasSpecialCharacters = false;
    setState(() {
      if (password.contains(RegExp(r'.{8,}'))) {
        isPassword8char = true;
      }

      if (password.contains(RegExp(r'[0-9]'))) {
        isPasswordHasNumber = true;
      }

      if (password.contains(RegExp(r'[A-Z]'))) {
        hasUppercase = true;
      }

      if (password.contains(RegExp(r'[a-z]'))) {
        hasLowercase = true;
      }

      if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
        hasSpecialCharacters = true;
      }
    });
  }

  bool validatePassword(String password) {
    return password.length >= 8 &&
        password.contains(RegExp(r'[0-9]')) &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[a-z]')) &&
        password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  }

  register() async {
    setState(() {
      isLoading = true;
    });

    String newPassword = newPasswordController.text;

    if (!widget.usingStandardPassword) {
      showSnackBar(context, "This page is for updating passwords only.");
      setState(() {
        isLoading = false;
      });
      return;
    }

    if (newPassword.isEmpty || !validatePassword(newPassword)) {
      showSnackBar(context, "Please enter a valid password.");
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      User? user = FirebaseAuth.instance.currentUser;
      await user?.updatePassword(newPassword);

      // Utiliser set avec merge pour créer ou mettre à jour les informations de l'utilisateur
      FirebaseFirestore.instance.collection('userss').doc(user?.uid).set({
        'username': usernameController.text,
        'phoneNumbr': _phoneNumberController.text,
        'email': emailController.text,
        'insured': _isInsuredChecked,
        'driver': _isDriverChecked,
      }, SetOptions(merge: true));

      showSnackBar(context, "Password updated successfully!");
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => Welcome()));
    } catch (e) {
      showSnackBar(context, "An error occurred: ${e.toString()}");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    emailController.dispose();
    newPasswordController.dispose();
    usernameController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Register",
          style: TextStyle(
            color: Colors.white, // Couleur du texte
            fontWeight: FontWeight.bold, // Texte en gras
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.indigo[800],
      ),
      body: SingleChildScrollView(
          //scrollDirection: Axis.horizontal,
          scrollDirection: Axis.vertical,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 28.0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextField(
                        controller: usernameController,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Enter Your Username : ',
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
                      const SizedBox(height: 15.0),
                      //utilisation du textFormField for validation(controle de saisie)

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
                      const SizedBox(height: 15.0),

                      TextFormField(
                        onChanged: (password) {
                          onPasswordChanged(password);
                        },
                        //we return "null" when something is valid
                        validator: (value) {
                          return value!.length < 8
                              ? "Enter a strong password "
                              : null;
                        },
                        autovalidateMode: AutovalidateMode.onUserInteraction,

                        controller: newPasswordController,
                        obscureText: isVisible ? true : false,
                        textInputAction: TextInputAction.done,
                        keyboardType: TextInputType.visiblePassword,
                        decoration: InputDecoration(
                          labelText: 'Enter Your New Password : ',
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors.indigo[900]!), // Bordure en focus
                          ),
                          floatingLabelStyle:
                              TextStyle(color: Colors.indigo[900]!),
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
                      const SizedBox(height: 15.0),
                      Row(
                        children: [
                          Container(
                            height: 20,
                            width: 20,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isPassword8char
                                    ? Colors.green
                                    : Colors.white,
                                border:
                                    Border.all(color: Colors.grey.shade400)),
                            child: const Icon(Icons.check,
                                color: Colors.white, size: 15),
                          ),
                          const SizedBox(width: 11.0),
                          const Text("At least 8 characters "),
                        ],
                      ),
                      const SizedBox(height: 15.0),
                      Row(
                        children: [
                          Container(
                            height: 20,
                            width: 20,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isPasswordHasNumber
                                    ? Colors.green
                                    : Colors.white,
                                border:
                                    Border.all(color: Colors.grey.shade400)),
                            child: const Icon(Icons.check,
                                color: Colors.white, size: 15),
                          ),
                          const SizedBox(width: 11.0),
                          const Text("At least 1 number "),
                        ],
                      ),
                      const SizedBox(height: 15.0),
                      Row(
                        children: [
                          Container(
                            height: 20,
                            width: 20,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    hasUppercase ? Colors.green : Colors.white,
                                border:
                                    Border.all(color: Colors.grey.shade400)),
                            child: const Icon(Icons.check,
                                color: Colors.white, size: 15),
                          ),
                          const SizedBox(width: 11.0),
                          const Text("Has Uppercase "),
                        ],
                      ),
                      const SizedBox(height: 15.0),
                      Row(
                        children: [
                          Container(
                            height: 20,
                            width: 20,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    hasLowercase ? Colors.green : Colors.white,
                                border:
                                    Border.all(color: Colors.grey.shade400)),
                            child: const Icon(Icons.check,
                                color: Colors.white, size: 15),
                          ),
                          const SizedBox(width: 11.0),
                          const Text("Has Lowercase "),
                        ],
                      ),
                      const SizedBox(height: 15.0),
                      Row(
                        children: [
                          Container(
                            height: 20,
                            width: 20,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: hasSpecialCharacters
                                    ? Colors.green
                                    : Colors.white,
                                border:
                                    Border.all(color: Colors.grey.shade400)),
                            child: const Icon(Icons.check,
                                color: Colors.white, size: 15),
                          ),
                          const SizedBox(width: 11.0),
                          const Text("Has Special characters"),
                        ],
                      ),
                      const SizedBox(height: 15.0),
                      CheckboxListTile(
                        title: const Text('Insured'),
                        value: _isInsuredChecked,
                        onChanged: (bool? value) {
                          setState(() {
                            _isInsuredChecked = value ?? false;
                            if (value == true) {
                              _isDriverChecked = false;
                            }
                          });
                        },
                        activeColor: Colors.indigo[900]!,
                        checkColor: Colors.white,
                      ),
                      CheckboxListTile(
                        title: const Text('Driver'),
                        value: _isDriverChecked,
                        onChanged: (bool? value) {
                          setState(() {
                            _isDriverChecked = value ??
                                false; // Affecte la valeur ou false si null
                            if (value == true) {
                              // Si Driver est coché, Insured doit être décoché
                              _isInsuredChecked = false;
                            }
                          });
                        },
                        activeColor: Colors.indigo[900]!,
                        checkColor: Colors.white,
                      ),
                      const SizedBox(height: 24.0),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.indigo[800], // Couleur de fond du bouton
                        ),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            await register();
                            if (!mounted) return;
                            //showSnackBar(context, "Done.");
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  // ignore: prefer_const_constructors
                                  builder: (context) => Welcome()),
                            );
                          } else {
                            showSnackBar(context,
                                "Please retry with valid informations!");
                          }
                        },
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Register',
                                style: TextStyle(
                                  fontWeight:
                                      FontWeight.bold, // Rendre le texte gras
                                  color: Colors
                                      .white, // Définir la couleur du texte
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          )),
    );
  }
}

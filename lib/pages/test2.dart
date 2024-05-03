import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:comar_insurance/pages/welcome.dart';
import 'package:comar_insurance/shared/snackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  bool isVisible = true;
  final FocusNode passwordFocusNode = FocusNode();

  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  final emailController = TextEditingController();
  final newPasswordController = TextEditingController();
  final usernameController = TextEditingController();

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

  register() async {
    setState(() {
      isLoading = true;
    });

    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text,
        password: newPasswordController.text,
      );

      print(credential.user!.uid);

//userss : name of ur collection
//users : name of variable
      CollectionReference users =
          FirebaseFirestore.instance.collection('userss');
      users
          .doc(credential.user!.uid)
          .set({
            'username': usernameController.text,
            'email': emailController.text,
            'password': newPasswordController.text
          })
          .then((value) => print("User Added"))
          .catchError((error) => print("Failed to add user: $error"));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        showSnackBar(context, "The password provided is too weak.");
      } else if (e.code == 'email-already-in-use') {
        showSnackBar(context, "The account already exists for that email.");
      } else {
        showSnackBar(context, "ERRO - Please try again late!");
      }
    } catch (err) {
      showSnackBar(context, err.toString());
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    // Ajoutez le listener sur le FocusNode
    passwordFocusNode.addListener(() {
      final hasFocus = passwordFocusNode.hasFocus;
      final isCriteriaMet = isPasswordCriteriaMet();
      setState(() {
        // isVisible devrait être vrai si le champ a le focus ou si les critères ne sont pas remplis
        isVisible = hasFocus || !isCriteriaMet;
      });
    });
  }

  bool isPasswordCriteriaMet() {
    return isPassword8char &&
        isPasswordHasNumber &&
        hasUppercase &&
        hasLowercase &&
        hasSpecialCharacters;
  }

  @override
  void dispose() {
    // TODO: implement dispose
    emailController.dispose();
    newPasswordController.dispose();
    usernameController.dispose();
    passwordFocusNode.dispose();
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
                      const SizedBox(height: 15.0),
                      TextFormField(
                        focusNode: passwordFocusNode,
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
                      Visibility(
                        visible: isVisible,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  height: 20,
                                  width: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: hasUppercase
                                        ? Colors.green
                                        : Colors.transparent,
                                    border: Border.all(
                                        color: hasUppercase
                                            ? Colors.green
                                            : Colors.grey.shade400),
                                  ),
                                  child: hasUppercase
                                      ? const Icon(Icons.check,
                                          color: Colors.white, size: 15)
                                      : null,
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
                                    color: hasLowercase
                                        ? Colors.green
                                        : Colors.transparent,
                                    border: Border.all(
                                        color: hasLowercase
                                            ? Colors.green
                                            : Colors.grey.shade400),
                                  ),
                                  child: hasLowercase
                                      ? const Icon(Icons.check,
                                          color: Colors.white, size: 15)
                                      : null,
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
                                        : Colors.transparent,
                                    border: Border.all(
                                        color: hasSpecialCharacters
                                            ? Colors.green
                                            : Colors.grey.shade400),
                                  ),
                                  child: hasSpecialCharacters
                                      ? const Icon(Icons.check,
                                          color: Colors.white, size: 15)
                                      : null,
                                ),
                                const SizedBox(width: 11.0),
                                const Text("Has Special characters"),
                              ],
                            ),
                            // Ajoutez ici d'autres lignes pour les autres critères si nécessaire
                          ],
                        ),
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
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(top: 10),

                // Ajustez la valeur en fonction de vos besoins
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    "assets/images/img3.PNG",
                    fit: BoxFit.cover,
                    height: 300,
                  ),
                ),
              ),
            ],
          )),
    );
  }
}

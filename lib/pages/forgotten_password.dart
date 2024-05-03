import 'package:flutter/material.dart';

class Forgotten_password extends StatelessWidget {
  const Forgotten_password({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Reset Password",
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
              Container(
                margin: const EdgeInsets.only(
                    top: 0.0), // Ajustez la valeur en fonction de vos besoins
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    "assets/images/img2.PNG",
                    fit: BoxFit.cover,
                    height: 290,
                  ),
                ),
              ),
              const SizedBox(height: 15.0),
              const Text(
                'Enter your email please to reset your password!',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Color.fromARGB(255, 247, 9, 9),
                    fontSize: 30.0,
                    fontFamily: "myfont"),
              ),
              const SizedBox(height: 30.0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    TextField(
                      textInputAction: TextInputAction.done,
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
                    const SizedBox(height: 24.0),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.indigo[800], // Couleur de fond du bouton
                      ),
                      onPressed: () async {},
                      child: const Text(
                        'Reset password',
                        style: TextStyle(
                          fontWeight: FontWeight.bold, // Rendre le texte gras
                          color: Colors.white, // Définir la couleur du texte
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )),
    );
  }
}

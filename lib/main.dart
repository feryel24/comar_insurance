import 'package:comar_insurance/firebase_options.dart';
import 'package:comar_insurance/pages/forgotten_password.dart';
import 'package:comar_insurance/pages/insured.dart';
import 'package:comar_insurance/pages/register.dart';
import 'package:comar_insurance/pages/retrieve.dart';
import 'package:comar_insurance/pages/welcome.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp()); // Ceci lance votre application.
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(useMaterial3: true),
      initialRoute: '/',
      routes: {
        '/': (context) => const Retrieve(),
        '/insured': (context) => const MapPage(),
        '/Forgotten_password': (context) => const Forgotten_password(),
        '/register': (context) => const Register(),
        '/retrieve': (context) => const Retrieve(),
      },
    );
  }
}

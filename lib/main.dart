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
      // utilisé pour gérer les routes dynamiquement
      onGenerateRoute: (settings) {
        if (settings.name == '/register') {
          final bool usingStandardPassword =
              settings.arguments as bool? ?? false;
          return MaterialPageRoute(
            builder: (context) =>
                Register(usingStandardPassword: usingStandardPassword),
          );
        }
        // Ajouter ici d'autres gestionnaires de route si nécessaire
        return null;
      },
      routes: {
        '/': (context) => const Welcome(),
        '/insured': (context) => const MapPage(),
        '/Forgotten_password': (context) => const Forgotten_password(),
        '/retrieve': (context) => const Retrieve(),
      },
    );
  }
}

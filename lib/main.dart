import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart'; // Importa la función de inicialización
import 'package:testeo_base/home.dart';
import 'package:testeo_base/login_screen.dart';
import 'package:testeo_base/registro.dart'; // Importa la pantalla de registro

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeDateFormatting('es', null); // Inicializa la localización para el español

  // Verificar si el usuario ya está autenticado
  User? user = FirebaseAuth.instance.currentUser;
  runApp(MyApp(initialRoute: user == null ? '/' : '/home'));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bienestar Estudiantil',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      initialRoute: initialRoute,
      routes: {
        '/home': (context) => const HomeScreen(),
        '/': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
      },
    );
  }
}

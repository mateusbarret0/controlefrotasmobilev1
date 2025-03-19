import 'package:controlefrotasmobilev1/src/login.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle de Frotas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0075FF), // Cor terciária
          primary: const Color.fromRGBO(43, 43, 43, 1), // Cor principal
          secondary: const Color.fromRGBO(66, 66, 66, 1), // Cor secundária
          onPrimary: Colors.white,
          onSecondary: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF2A2A2A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF424242), // Cor secundária
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF0075FF), // Cor terciária
        ),
      ),
      // home: Menu(),
      home: Login(),
    );
  }
}

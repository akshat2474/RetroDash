import 'package:flutter/material.dart';
import 'widgets/homepage.dart'; 

void main() {
  runApp(RetroDashApp());
}

class RetroDashApp extends StatelessWidget {
  const RetroDashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Retro Dash',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'RetroFont', 
        primarySwatch: Colors.amber,
      ),
      home: AnimatedHomePage(),
    );
  }
}






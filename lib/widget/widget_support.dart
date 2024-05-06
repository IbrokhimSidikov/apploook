import 'package:flutter/material.dart';

class AppWidget {
  static TextStyle boldTextFieldStyle() {
    return const TextStyle(
        color: Colors.black,
        fontSize: 20.0,
        fontWeight: FontWeight.bold,
        fontFamily: 'Poppins');
  }

  static TextStyle HeadlineTextFieldStyle() {
    return const TextStyle(
        color: Color.fromARGB(255, 205, 205, 0),
        fontSize: 24.0,
        fontWeight: FontWeight.bold,
        fontFamily: 'Poppins');
  }

  static TextStyle LightTextFieldStyle() {
    return const TextStyle(
        color: Color.fromARGB(255, 50, 45, 45),
        fontSize: 15.0,
        fontWeight: FontWeight.w500,
        fontFamily: 'Poppins');
  }

  static TextStyle semiboldTextFieldStyle() {
    return const TextStyle(
        color: Colors.black,
        fontSize: 18.0,
        fontWeight: FontWeight.bold,
        fontFamily: 'Poppins');
  }

  static TextStyle titleTextFieldStyle() {
    return const TextStyle(
      color: Colors.black,
      fontSize: 24.0,
      fontWeight: FontWeight.bold,
      fontFamily: 'Poppins',
      shadows: [
        Shadow(
          // Add a single shadow here
          offset: Offset(2.0, 2.0), // Offset the shadow slightly
          blurRadius: 3.0, // Blur the shadow for a smoother effect
          color: Color.fromARGB(
              128, 0, 0, 0), // Set the shadow color (semi-transparent black)
        ),
      ],
    );
  }
}

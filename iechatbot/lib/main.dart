import 'package:flutter/material.dart';
import '../screens/login_page.dart';
import '../screens/register_page.dart'; // Import your register page

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Chatbot',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: LoginPage(),
      routes: {
        '/register': (context) => RegisterPage(), // Define your RegisterPage route
      },
    );
  }
}

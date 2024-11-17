import 'package:flutter/material.dart';
import 'screens/login_page.dart';
import 'screens/register_page.dart';
import 'screens/home_page.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/login': (context) => LoginPage(),
    '/register': (context) => RegisterPage(),
    '/home': (context) => HomePage(),
  };
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'database_helper.dart';
import 'dart:io';
import 'self_signed_override.dart';
import 'login.dart'; // Assuming LoginPage is in a separate file

void main() async {
  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();

  bool isDarkTheme = await DatabaseHelper().getTheme();

  runApp(MyApp(isDarkTheme: isDarkTheme));
}

class MyApp extends StatelessWidget {
  final bool isDarkTheme;

  MyApp({required this.isDarkTheme});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeProvider(isDarkTheme: isDarkTheme),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Theme Switcher App',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              brightness: Brightness.light,
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              primarySwatch: Colors.blue,
            ),
            themeMode: themeProvider.isDarkTheme
                ? ThemeMode.dark
                : ThemeMode.light, // Use the selected theme
            home: LoginPage(), // Default starting page
          );
        },
      ),
    );
  }
}

class MainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Main Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                // Navigate to LoginPage
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
              child: Text('Go to Login Page'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Toggle theme when the button is pressed
          Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
        },
        child: Icon(Icons.brightness_6), // Theme change icon
        tooltip: 'Toggle Theme',
      ),
    );
  }
}

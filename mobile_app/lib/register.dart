import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/global.dart';
import 'dart:convert';
import 'login.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  String sanitizeUsername(String username) {
  username = username.trim();

  final RegExp usernameRegExp = RegExp(r'^[a-zA-Z0-9_-]+$');
  
  if (!usernameRegExp.hasMatch(username)) {
    _showMessage("Username contains invalid characters. Only letters, numbers, underscores, and dashes are allowed.");
    throw Exception("Username contains invalid characters. Only letters, numbers, underscores, and dashes are allowed.");
  }

  username = username.toLowerCase();

  if (username.length < 3 || username.length > 30) {
    _showMessage("Username must be between 3 and 30 characters long.");
    throw Exception("Username must be between 3 and 30 characters long.");
  }

  return username;
}

  Future<void> _registerUser() async {
    final String username = _usernameController.text;
    final String password = _passwordController.text;

    sanitizeUsername(username);

    if (username.isEmpty || password.isEmpty) {
      _showMessage('Please enter both username and password.');
      return;
    }

    final Uri url = Uri.parse('$GLOB_host/register');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      } else {
        _showMessage('Registration failed, user already exists.');
      }
    } catch (e) {
      _showMessage('An error occurred. Please check your connection.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _registerUser,
              child: Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}

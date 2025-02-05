import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login.dart'; // Ensure you have this page for navigation

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  String sanitizeUsername(String username) {
  // Trim any leading or trailing whitespace
  username = username.trim();

  // Regular expression to allow only letters, digits, underscores, and dashes
  final RegExp usernameRegExp = RegExp(r'^[a-zA-Z0-9_-]+$');
  
  // Check if username matches the allowed pattern
  if (!usernameRegExp.hasMatch(username)) {
    _showMessage("Username contains invalid characters. Only letters, numbers, underscores, and dashes are allowed.");
    throw Exception("Username contains invalid characters. Only letters, numbers, underscores, and dashes are allowed.");
  }

  // Optionally, ensure the username is lowercase to normalize
  username = username.toLowerCase();

  // Ensure that the username has a minimum and maximum length (e.g., 3 to 30 characters)
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
      // Show a message if fields are empty
      _showMessage('Please enter both username and password.');
      return;
    }

    // Set the URL of your API
    final Uri url = Uri.parse('https://192.168.1.138:5000/register');

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
        // Successful registration, navigate to EmptyPage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      } else {
        // Handle unsuccessful registration
        _showMessage('Registration failed, user already exists.');
      }
    } catch (e) {
      // Handle error
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

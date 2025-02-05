import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'register.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'logged_in.dart';
import 'global.dart';
import 'key_generator.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}


class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final DatabaseHelper _dbHelper = DatabaseHelper();

  void _printEncryptedName(String username) async {
    String? encryptedName = await _dbHelper.fetchEncryptedName(0);
    print("Encrypted Name: $encryptedName");
    if (encryptedName != null) {
        print("Decrypted Name: ${KeyGenerator.decryptData(encryptedName, username)}");
    }
  }

  Future<void> login() async {
    String username = _emailController.text.trim();
    String password = _passwordController.text.trim();

    String cry = KeyGenerator.encryptData("dada", username);
    await _dbHelper.insertEncryptedName(KeyGenerator.encryptData('logged in with user $username', username));

    _printEncryptedName(username);

    if (username.isEmpty || password.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Username and password cannot be empty'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final Uri url = Uri.parse('$GLOB_host/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        String jwt_token = responseData['token'];

        if (jwt_token != null) {
          GLOB_JWT = jwt_token;
          print(GLOB_JWT);
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoggedIn(jwtToken: jwt_token)),
        );
      } else {

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text('Invalid login credentials'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
    
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Network Error'),
          content: Text('Could not connect to the server.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _showDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _goToRegisterPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RegisterPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: login,
              child: Text('Login'),
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: _goToRegisterPage,
              child: Text('Don\'t have an account? Register'),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
        
          Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
        },
        child: Icon(Icons.brightness_6),
        tooltip: 'Toggle Theme',
      )
    );
  }
}

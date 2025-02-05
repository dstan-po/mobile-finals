import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/global.dart';
import 'login.dart';
import 'dart:convert';

class LoggedIn extends StatefulWidget {
  final String jwtToken;

  LoggedIn({required this.jwtToken});

  @override
  _LoggedInState createState() => _LoggedInState();
}

class _LoggedInState extends State<LoggedIn> {
  List<Map<String, dynamic>> notes = [];
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchNotes();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> fetchNotes() async {
    final response = await http.get(
      Uri.parse('$GLOB_host/notes'),  // Updated to use $GLOB_host
      headers: {
        'Authorization': 'Bearer ${widget.jwtToken}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        notes = List<Map<String, dynamic>>.from(data['notes']);
      });
    }
  }

  String sanitizeNoteContent(String content) {
  // Step 1: Trim whitespace from the start and end
  content = content.trim();
  
  // Step 2: Remove potentially harmful characters (HTML tags, JS scripts, etc.)
  content = removeHtmlTags(content);
  
  // Step 3: Limit the length of the note (optional, e.g., max 500 characters)
  content = sanitizeLength(content, 500);
  
  return content;
}

String sanitizeLength(String input, int maxLength) {
  if (input.length > maxLength) {
    _showErrorDialog("Note exceeds maximum length of $maxLength characters.");
    throw Exception("Note exceeds maximum length of $maxLength characters.");
  }
  return input;
}

String removeHtmlTags(String input) {
  final RegExp htmlTagPattern = RegExp(r'<[^>]*>|&[^;]+;');
  return input.replaceAll(htmlTagPattern, '');
}

  Future<void> addNote() async {
  
    String content = _noteController.text.trim(); 

    if (content.isEmpty) {
      _showErrorDialog("Note content cannot be empty!");
      return;
    }

    content = content.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '');

    sanitizeNoteContent(content);

    final response = await http.post(
      Uri.parse('$GLOB_host/add_note'), 
      headers: {
        'Authorization': 'Bearer ${widget.jwtToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'content': content}),
    );

    if (response.statusCode == 201) {
      _noteController.clear(); // Clear input field after adding
      fetchNotes(); // Refresh notes after adding
    } else {
      _showErrorDialog("Failed to add note. Please try again.");
      fetchNotes();
    }
  }

  Future<void> deleteNote(int id) async {
    final response = await http.delete(
      Uri.parse('$GLOB_host/delete_note'),
      headers: {
        'Authorization': 'Bearer ${widget.jwtToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'note_id': id}),
    );

    if (response.statusCode == 200) {
      fetchNotes();
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Error"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void showAddNoteDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add New Note'),
          content: TextField(
            controller: _noteController,
            decoration: InputDecoration(
              hintText: 'Enter note content...',
            ),
            maxLines: null, // Allow multiline input
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                addNote(); // Call addNote after sanitizing
              },
              child: Text("Add"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notes'),
        actions: [
          TextButton(
            onPressed: () {
              // Navigate to LoginPage
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
            child: Text(
              'Log Out',
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: notes.map((note) {
              return Container(
                width: MediaQuery.of(context).size.width * 0.8,
                margin: EdgeInsets.symmetric(vertical: 8),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blueGrey,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note['content'],
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => deleteNote(note['id']), // Call delete function
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddNoteDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}

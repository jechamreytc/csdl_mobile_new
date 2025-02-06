import 'dart:convert';

import 'package:csdl_mobile/advisor/advisor.dart';
import 'package:csdl_mobile/session_storage.dart';
import 'package:csdl_mobile/student/student.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      // home: Advisor(advisor_id: "02-1617-00627"),
      // home: Student(student_id: "02-1234-56789"), //SF
      // home: AdvisorScholarList(advisor_id: "02-1617-00627"),
      // home: StudentProfile(),
      // home: Student(student_id: "02-2425-23321"), //Office
      // home: AdvisorEvaluation(
      //   advisor_id: '02-1617-00627',
      //   student_id: '02-2425-23321',
      // ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _passwordVisible = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background color
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade800, Colors.blue.shade600],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'HK SMS',
                    style: TextStyle(
                      fontSize: 80,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Subtitle (HK Scholars Management System)
                  Text(
                    'HK Scholars',
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 1),
                  // Subtitle (HK Scholars Management System)
                  Text(
                    'Management System',
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  // Login Card Container with Rounded Corners and Shadow
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black
                          .withOpacity(0.7), // Dark background for the card
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(0, 5),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Title (Sign in)
                        const Text(
                          'Sign in',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Subtitle (Sign in your account)
                        Text(
                          'Sign in your account',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 30),
                        // Login field
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey[700],
                            labelText: 'Login',
                            labelStyle: const TextStyle(color: Colors.white),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 20),
                        // Password field
                        TextFormField(
                          controller: _passwordController,
                          obscureText:
                              !_passwordVisible, // Password visibility toggle
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey[700],
                            labelText: 'Password',
                            labelStyle: const TextStyle(color: Colors.white),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            // Suffix icon to toggle password visibility
                            suffixIcon: IconButton(
                              icon: Icon(
                                _passwordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                setState(() {
                                  _passwordVisible =
                                      !_passwordVisible; // Toggle password visibility
                                });
                              },
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 10),
                        // Remember me checkbox
                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.start,
                        //   children: [
                        //     Checkbox(
                        //       value: true,
                        //       onChanged: (val) {},
                        //       checkColor: Colors.white,
                        //       activeColor: Colors.green,
                        //     ),
                        //     Text(
                        //       'Remember me',
                        //       style: TextStyle(color: Colors.white),
                        //     ),
                        //   ],
                        // ),
                        const SizedBox(height: 20),
                        // Login Button
                        SizedBox(
                          width: double.infinity, // Full width button
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.green, // Green color as in the design
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Login',
                                style: TextStyle(fontSize: 18)),
                            onPressed: () {
                              login();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Footer (Powered by something)
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void login() async {
    try {
      var url = Uri.parse("${SessionStorage.url}user.php");

      // Construct the request body
      Map<String, dynamic> jsonData = {
        "username": _usernameController.text,
        "password": _passwordController.text
      };

      Map<String, String> requestBody = {
        "operation": "login",
        "json": jsonEncode(jsonData),
      };

      print(jsonData);
      // Make the HTTP POST request
      var response = await http.post(url, body: requestBody);

      if (response.statusCode == 200) {
        var res = jsonDecode(response.body);

        // Check if login was successful
        if (res != 0 && res is Map<String, dynamic>) {
          // Check if the user is a student or an advisor
          if (res.containsKey('supM_id')) {
            // Navigate to the Advisor screen
            String advisorId = res['supM_id'];
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => Advisor(
                        advisor_id: advisorId,
                      )),
            );
          } else if (res.containsKey('stud_id')) {
            // Navigate to the Student screen
            String userId = res['stud_id'];
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Student(
                  student_id: userId, // Pass the userId to the Student widget
                ),
              ),
            );
          } else {
            // Show a snack bar if the response format is unexpected
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Invalid response from server")),
            );
          }
        } else {
          // Show a snack bar if the login credentials are invalid
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Invalid username or password")),
          );
        }
      } else {
        // Show a snack bar if there is an issue with the server response
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Server error: ${response.statusCode}")),
        );
      }
    } catch (e) {
      // Print the error for debugging and show a snack bar for the user
      print("ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred: $e")),
      );
    }
  }
}

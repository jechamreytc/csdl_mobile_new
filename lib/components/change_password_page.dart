import 'dart:convert';
import 'package:csdl_mobile/main.dart';
import 'package:csdl_mobile/session_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChangePasswordPage extends StatefulWidget {
  final String userId;
  final bool isAdvisor;

  const ChangePasswordPage(
      {super.key, required this.userId, required this.isAdvisor});

  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isPasswordValid = true;
  bool _isConfirmPasswordValid = true;

  bool _hasNumber = false;
  bool _hasLetter = false;
  bool _hasSymbol = false;
  bool _hasUpperAndLower = false;

  // Password validation checks
  void _validatePassword() {
    String password = _newPasswordController.text;

    // Check for number
    _hasNumber = password.contains(RegExp(r'[0-9]'));
    // Check for letter
    _hasLetter = password.contains(RegExp(r'[a-zA-Z]'));
    // Check for symbol
    _hasSymbol = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    // Check for both upper and lower case
    _hasUpperAndLower = password.contains(RegExp(r'[a-z]')) &&
        password.contains(RegExp(r'[A-Z]'));

    setState(() {});
  }

  Future<void> _changePassword() async {
    setState(() {
      _isPasswordValid = _newPasswordController.text.isNotEmpty;
      _isConfirmPasswordValid = _confirmPasswordController.text.isNotEmpty;
    });

    if (!_isPasswordValid || !_isConfirmPasswordValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All fields are required!")),
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match!")),
      );
      return;
    }

    if (!_hasNumber || !_hasLetter || !_hasSymbol || !_hasUpperAndLower) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Password does not meet all requirements!")),
      );
      return;
    }

    try {
      var url = Uri.parse("${SessionStorage.url}transaction.php");

      Map<String, dynamic> jsonData = {
        "username": widget.userId, // Matches the API's expected field
        widget.isAdvisor ? "supM_id" : "stud_id": widget.userId,
        widget.isAdvisor ? "supM_password" : "stud_password":
            _newPasswordController.text
      };

      print(widget.isAdvisor ? "supM_id" : "stud_id");
      print(widget.isAdvisor ? "supM_password" : "stud_password");
      print(_newPasswordController.text);

      Map<String, String> requestBody = {
        "operation": "updatePassword",
        "json": jsonEncode(jsonData),
      };

      var response = await http.post(url, body: requestBody);

      print("API Raw Response: ${response.body}");

      if (response.statusCode == 200) {
        try {
          var res = jsonDecode(response.body);

          print("API Decoded Response: $res");

          if (res["success"] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text(res["message"] ?? "Password changed successfully!")),
            );

            // Redirect back to login/home
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(res["message"] ?? "Password update failed.")),
            );
          }
        } catch (e) {
          print("Failed to decode JSON: $e");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("Invalid server response: ${response.body}")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Server error: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if all conditions are met to enable the button
    bool isPasswordValidToSubmit =
        _hasNumber && _hasLetter && _hasSymbol && _hasUpperAndLower;

    return Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(50), // Set the height of the AppBar
          child: AppBar(
            backgroundColor:
                Colors.transparent, // Make the AppBar background transparent
            elevation: 0, // Remove the shadow of the AppBar
            flexibleSpace: Image.asset(
              'assets/images/coc_logo.png', // Path to your background image
              height: 50,
              width: 50, // Ensure the image covers the entire area
            ),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade50, Colors.green.shade200],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Create New Password",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // New Password
                      TextFormField(
                        controller: _newPasswordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: "New Password",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(_isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          errorText:
                              _isPasswordValid ? null : "Password is required",
                        ),
                        onChanged: (value) => _validatePassword(),
                      ),

                      const SizedBox(height: 15),

                      // Confirm Password
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: !_isConfirmPasswordVisible,
                        decoration: InputDecoration(
                          labelText: "Confirm Password",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(_isConfirmPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: () {
                              setState(() {
                                _isConfirmPasswordVisible =
                                    !_isConfirmPasswordVisible;
                              });
                            },
                          ),
                          errorText: _isConfirmPasswordValid
                              ? null
                              : "Confirm Password is required",
                        ),
                      ),

                      const SizedBox(height: 15),

                      // Password validation criteria
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildValidationItem(
                                "At least one number", _hasNumber),
                            _buildValidationItem(
                                "At least one letter", _hasLetter),
                            _buildValidationItem(
                                "At least one symbol", _hasSymbol),
                            _buildValidationItem(
                                "Both uppercase and lowercase letters",
                                _hasUpperAndLower),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              isPasswordValidToSubmit ? _changePassword : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isPasswordValidToSubmit
                                ? Colors.green
                                : Colors.grey,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Change Password",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ));
  }

  Widget _buildValidationItem(String text, bool isValid) {
    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.cancel,
          color: isValid ? Colors.green : Colors.red,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: isValid ? Colors.green : Colors.red,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

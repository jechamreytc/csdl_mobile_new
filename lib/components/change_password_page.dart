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

      Map<String, String> requestBody = {
        "operation": "updatePassword",
        "json": jsonEncode(jsonData),
      };

      var response = await http.post(url, body: requestBody);

      if (response.statusCode == 200) {
        var res = jsonDecode(response.body);
        if (res == 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    "Password changed successfully! Please log in again.")),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => HomePage()), // Redirect to login page
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Failed to change password. Please try again.")),
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
      appBar: AppBar(
          title: const Text("Change Password"), backgroundColor: Colors.green),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextFormField(
              controller: _newPasswordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelText: "New Password",
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
                errorText: _isPasswordValid ? null : "Password is required",
              ),
              onChanged: (value) => _validatePassword(),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: !_isConfirmPasswordVisible,
              decoration: InputDecoration(
                labelText: "Confirm Password",
                suffixIcon: IconButton(
                  icon: Icon(_isConfirmPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    });
                  },
                ),
                errorText: _isConfirmPasswordValid
                    ? null
                    : "Confirm Password is required",
              ),
            ),
            const SizedBox(height: 10),
            // Password validation criteria
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildValidationItem("At least one number", _hasNumber),
                _buildValidationItem("At least one letter", _hasLetter),
                _buildValidationItem("At least one symbol", _hasSymbol),
                _buildValidationItem(
                    "Both uppercase and lowercase letters", _hasUpperAndLower),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isPasswordValidToSubmit ? _changePassword : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isPasswordValidToSubmit ? Colors.green : Colors.grey,
              ),
              child: const Text("Change Password"),
            ),
          ],
        ),
      ),
    );
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

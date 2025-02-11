import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EmailVerification extends StatefulWidget {
  const EmailVerification({Key? key}) : super(key: key);

  @override
  _EmailVerificationState createState() => _EmailVerificationState();
}

class _EmailVerificationState extends State<EmailVerification> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String _message = '';

  Future<void> sendVerificationEmail() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      String email = _emailController.text.trim();
      if (email.isEmpty) {
        setState(() {
          _message = "Please enter an email.";
          _isLoading = false;
        });
        return;
      }

      // Create user without password (Anonymous)
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: "TemporaryPassword123!", // Required to create a user
      );

      User? user = userCredential.user;

      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        setState(() {
          _message = "Verification email sent! Check your inbox.";
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _message = "Error: ${e.message}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Email Verification")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: "Enter your email",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : sendVerificationEmail,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Send Verification Email"),
            ),
            const SizedBox(height: 20),
            Text(
              _message,
              style: TextStyle(
                  color:
                      _message.contains("Error") ? Colors.red : Colors.green),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

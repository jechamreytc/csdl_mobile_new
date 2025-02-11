import 'dart:math';
import 'package:flutter/material.dart';

class Captcha extends StatefulWidget {
  const Captcha({Key? key}) : super(key: key);

  @override
  _CaptchaState createState() => _CaptchaState();
}

class _CaptchaState extends State<Captcha> {
  String generatedCaptcha = "";
  final TextEditingController _captchaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    generateCaptcha();
  }

  void generateCaptcha() {
    Random random = Random();
    generatedCaptcha =
        List.generate(5, (_) => random.nextInt(10).toString()).join();
    setState(() {}); // Refresh UI
  }

  void verifyCaptcha() {
    if (_captchaController.text == generatedCaptcha) {
      print("Successfully logged in!");
    } else {
      print("Wrong Captcha! Try again.");
    }
  }

  // Function to generate random colors
  Color getRandomColor() {
    Random random = Random();
    return Color.fromRGBO(
      random.nextInt(256), // Red
      random.nextInt(256), // Green
      random.nextInt(256), // Blue
      1, // Full opacity
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300], // Neutral background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Captcha Card
            Container(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.green[700], // 75% green background for the card
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 5,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize:
                    MainAxisSize.min, // Adjusts width based on content
                children: List.generate(
                  generatedCaptcha.length,
                  (index) {
                    Random random = Random();
                    double rotation =
                        (random.nextDouble() - 0.5) * 0.6; // Random rotation
                    double opacity = random.nextDouble() * 0.5 +
                        0.5; // Random opacity (50%-100%)
                    double fontSize = random.nextDouble() * 8 +
                        25; // Random font size (25-33)
                    double verticalShift =
                        random.nextInt(10) - 5.0; // Random vertical shift

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Transform.rotate(
                        angle: rotation,
                        child: Transform.translate(
                          offset: Offset(0, verticalShift),
                          child: Opacity(
                            opacity: opacity,
                            child: Text(
                              generatedCaptcha[index],
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.bold,
                                color:
                                    getRandomColor(), // Each number gets a different color
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Input Field
            SizedBox(
              width: 200,
              child: TextField(
                controller: _captchaController,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: "Enter Captcha",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Verify Button
            ElevatedButton(
              onPressed: verifyCaptcha,
              child: const Text("Verify"),
            ),
          ],
        ),
      ),
    );
  }
}

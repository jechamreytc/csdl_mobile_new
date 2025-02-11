import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:csdl_mobile/advisor/advisor.dart';
import 'package:csdl_mobile/components/change_password_page.dart';
import 'package:csdl_mobile/session_storage.dart';
import 'package:csdl_mobile/student/student.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
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
  final TextEditingController _captchaController = TextEditingController();

  final TextInputFormatter _usernameInputFormatter =
      FilteringTextInputFormatter.allow(
    RegExp(r'[A-Za-z0-9-@]'),
  );

  bool _passwordVisible = false;
  int _failedAttempts = 0;
  bool _isLocked = false;
  int _remainingSeconds = 0;
  Timer? _cooldownTimer;
  String generatedCaptcha = "";
  bool _isLoadingCaptcha = false;
  bool _isCaptchaVisible = false;
  bool _isCaptchaChecked = false;
  bool _isUsernameValid = true;
  bool _isPasswordValid = true;
  bool _isCaptchaValid = true;

  @override
  void initState() {
    super.initState();
    generateCaptcha();
    _loadCooldownState();
  }

  void generateCaptcha() {
    Random random = Random();
    generatedCaptcha =
        List.generate(5, (_) => random.nextInt(10).toString()).join();
    setState(() {});
  }

  void verifyCaptcha() {
    if (_captchaController.text != generatedCaptcha) {
      setState(() {
        _isCaptchaValid = false;
      });

      generateCaptcha();
      setState(() {
        _isCaptchaChecked = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Incorrect Captcha! Try again.")),
      );

      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _isCaptchaValid = true;
        });
      });
    }
  }

  Future<void> _loadCooldownState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? lockTimestamp = prefs.getInt('lockTime');

    if (lockTimestamp != null) {
      int elapsedSeconds = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(lockTimestamp))
          .inSeconds;

      if (elapsedSeconds < 90) {
        setState(() {
          _isLocked = true;
          _remainingSeconds = 90 - elapsedSeconds;
        });

        startCooldown();
      } else {
        prefs.remove('lockTime');
      }
    }
  }

  void startCooldown() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lockTime', DateTime.now().millisecondsSinceEpoch);

    setState(() {
      _isLocked = true;
      _remainingSeconds = 90;
    });

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) {
          _isLocked = false;
          _failedAttempts = 0;
          _cooldownTimer?.cancel();
          prefs.remove('lockTime');
        }
      });
    });
  }

  void login() async {
    if (_isLocked) return;

    setState(() {
      _isUsernameValid = _usernameController.text.isNotEmpty;
      _isPasswordValid = _passwordController.text.isNotEmpty;
    });

    if (!_isUsernameValid || !_isPasswordValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Username and Password are required!")),
      );
      return;
    }

    if (_captchaController.text != generatedCaptcha) {
      verifyCaptcha();
      return;
    }

    try {
      var url = Uri.parse("${SessionStorage.url}user.php");

      Map<String, dynamic> jsonData = {
        "username": _usernameController.text,
        "password": _passwordController.text
      };

      Map<String, String> requestBody = {
        "operation": "login",
        "json": jsonEncode(jsonData),
      };

      var response = await http.post(url, body: requestBody);

      if (response.statusCode == 200) {
        var res = jsonDecode(response.body);
        print(res);
        print(jsonData);

        if (res != 0 && res is Map<String, dynamic>) {
          _failedAttempts = 0;

          if (res.containsKey('supM_id')) {
            String advisorId = res['supM_id'];
            bool isDefaultPassword = res['is_default_password'];

            if (isDefaultPassword) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ChangePasswordPage(userId: advisorId, isAdvisor: true),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => Advisor(advisor_id: advisorId)),
              );
            }
          } else if (res.containsKey('stud_id')) {
            String studentId = res['stud_id'];
            bool isDefaultPassword = res['is_default_password'];

            if (isDefaultPassword) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ChangePasswordPage(userId: studentId, isAdvisor: false),
                ),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => Student(student_id: studentId),
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade800, Colors.green.shade600],
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
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'HK Scholars Management System',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          offset: const Offset(0, 3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Sign in',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.green[50],
                            labelText: 'Login',
                            labelStyle: const TextStyle(color: Colors.green),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            errorText: _isUsernameValid
                                ? null
                                : 'Username is required',
                          ),
                          style: const TextStyle(color: Colors.black),
                          inputFormatters: [_usernameInputFormatter],
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_passwordVisible,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.green[50],
                            labelText: 'Password',
                            labelStyle: const TextStyle(color: Colors.green),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            errorText: _isPasswordValid
                                ? null
                                : 'Password is required',
                          ),
                          style: const TextStyle(color: Colors.black),
                        ),
                        const SizedBox(height: 15),
                        Visibility(
                          visible: _isCaptchaVisible,
                          child: Column(
                            children: [
                              _isLoadingCaptcha
                                  ? const CircularProgressIndicator()
                                  : Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 15),
                                      decoration: BoxDecoration(
                                        color: Colors.green[700],
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: List.generate(
                                          generatedCaptcha.length,
                                          (index) {
                                            Random random = Random();
                                            double rotation =
                                                (random.nextDouble() - 0.5) *
                                                    0.6;
                                            double opacity =
                                                random.nextDouble() * 0.5 + 0.5;
                                            double fontSize =
                                                random.nextDouble() * 8 + 25;
                                            double verticalShift =
                                                random.nextInt(10) - 5.0;

                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 5),
                                              child: Transform.rotate(
                                                angle: rotation,
                                                child: Transform.translate(
                                                  offset:
                                                      Offset(0, verticalShift),
                                                  child: Opacity(
                                                    opacity: opacity,
                                                    child: Text(
                                                      generatedCaptcha[index],
                                                      style: TextStyle(
                                                        fontSize: fontSize,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: getRandomColor(),
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
                              const SizedBox(height: 15),
                              SizedBox(
                                width: double.infinity,
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
                                    errorText: _isCaptchaValid
                                        ? null
                                        : 'Incorrect Captcha',
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
                        Visibility(
                          visible: !_isCaptchaVisible,
                          child: Row(
                            children: [
                              Checkbox(
                                value: _isCaptchaChecked,
                                onChanged: (value) async {
                                  setState(() {
                                    _isCaptchaChecked = value!;
                                    _isCaptchaVisible = true;
                                  });

                                  if (_isCaptchaChecked) {
                                    setState(() {
                                      _isLoadingCaptcha = true;
                                    });

                                    await Future.delayed(
                                        const Duration(seconds: 2));

                                    setState(() {
                                      _isCaptchaVisible = true;
                                      _isLoadingCaptcha = false;
                                    });
                                  }
                                },
                              ),
                              const Text(
                                "I'm not a robot",
                                style: TextStyle(color: Colors.green),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          child: _isLocked
                              ? const Text(
                                  "Your account is Locked",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.red,
                                  ),
                                )
                              : ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        _isLocked ? Colors.grey : Colors.green,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                  child: Text(
                                    _isLocked
                                        ? "Locked ($_remainingSeconds s)"
                                        : "Login",
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  onPressed: _isLocked ? null : login,
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color getRandomColor() {
    Random random = Random();
    return Color.fromARGB(
      255,
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
    );
  }
}

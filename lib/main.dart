import 'dart:convert';
import 'dart:async';
import 'dart:math';
// import 'package:csdl_mobile/advisor/advisor.dart';
import 'package:csdl_mobile/advisor/advisor.dart';
import 'package:csdl_mobile/advisor/advisor_qr_code.dart';
// import 'package:csdl_mobile/advisor/advisor_evaluation_office.dart';
// import 'package:csdl_mobile/advisor/advisor_evalution.dart';
// import 'package:csdl_mobile/advisor/advisor_hidden_drawer.dart';
import 'package:csdl_mobile/advisor/advisor_scholar_list.dart';
import 'package:csdl_mobile/components/change_password_page.dart';
import 'package:csdl_mobile/entry_point.dart';
import 'package:csdl_mobile/fresh_student/fresh_student.dart';
import 'package:csdl_mobile/fresh_student/fresh_student_add_referral_component.dart';
import 'package:csdl_mobile/fresh_student/fresh_student_referral_list.dart';
import 'package:csdl_mobile/scholarship_request_form.dart';
import 'package:csdl_mobile/student/student.dart';
// import 'package:csdl_mobile/student/student_hidden_drawer.dart';
import 'package:csdl_mobile/session_storage.dart';
import 'package:csdl_mobile/student/student_dashboard.dart';
import 'package:csdl_mobile/student/student_ocr.dart';
import 'package:csdl_mobile/student/student_qr_duty_registration.dart';
// import 'package:csdl_mobile/student/student.dart';
import 'package:csdl_mobile/marketing/marketing_drawer.dart';
import 'package:csdl_mobile/marketing/marketing.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (FlutterErrorDetails details) {
    print('Flutter error: ${details.exception}');
  };
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadApp(
      builder: (context, theme) => GetMaterialApp(
        // theme: theme,
        builder: (context, child) {
          return ShadToaster(child: child!);
        },
        debugShowCheckedModeBanner: false,
        // home: StudentQrDutyRegistration(student_id: "02-2223-07626"),
        // home: AdvisorQrCode(supM_id: "02-2223-06742"),
        // home: ScholarshipRequestForm(),
        home: const EntryPoint(),
        // home: const HomePage(),
        // home: Student(
        //   student_id: "02-1234-56789",
        // ),
        // home: StudentDashboard(
        //   student_id: "02-1234-00066",
        // ),
        // home: const Advisor(
        //   advisor_id: "02-1213-00123",
        // ),
        // home: const AdvisorScholarList(
        //   advisor_id: "02-1617-00627",
        // ),
        // home: const AdvisorEvaluationOffice(
        //     advisor_id: "02-1213-00123", scholar_id: "02-1234-56789"),
        // home: FreshStudent(student_id: "02-1234-56789"),
        // home: FreshStudentReferralList(
        //   student_id: '02-2425-23321',
        // ),
        // home: FreshStudentAddReferralComponent(
        //   student_id: '02-1234-56789',
        // ),
        // home: StudentOcr(student_id: '02-1617-00627'),
        routes: {
          "/home": (context) => const HomePage(),
        },
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late TextEditingController emailController;
  String userEmail = "";
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _captchaController = TextEditingController();
  final TextInputFormatter _usernameInputFormatter =
      FilteringTextInputFormatter.allow(
    RegExp(
        r'[A-Za-z0-9-@.]'), // Added the period (".") to the regular expression
  );

  bool _passwordVisible = false;
  int _failedAttempts = 0;
  bool _isLocked = false;
  String generatedCaptcha = "";
  bool _isLoadingCaptcha = false;
  bool _isCaptchaVisible = false;
  bool _isCaptchaChecked = false;
  bool _isUsernameValid = true;
  bool _isPasswordValid = true;
  bool _isCaptchaValid = true;
  bool userIsStudent = false;
  bool userIsSupervisor = false;
  bool userIsSupervisorAuthentication = false;

  //PROFILE

  String student_id = "";
  String studName = "";
  String studEmail = "";

  //Supervisor PROFILE

  String advisor_id = "";
  String advName = "";
  String advEmail = "";
  String supervisor_id1 = "";

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController(text: userEmail);
    generateCaptcha();
  }

  void generateCaptcha() {
    Random random = Random();
    generatedCaptcha =
        List.generate(5, (_) => random.nextInt(10).toString()).join();
    setState(() {});
  }

  bool verifyCaptcha() {
    if (_captchaController.text.trim() != generatedCaptcha.trim()) {
      _failedAttempts++;
      generateCaptcha();

      // Clear input fields when captcha verification fails
      _usernameController.clear();
      _passwordController.clear();
      _captchaController.clear();

      if (_failedAttempts == 5) {
        setState(() {
          _isLocked = true;
        });
        updateLoginAttempt();
      }

      Get.snackbar(
        "Alert",
        "CAPTCHA does not match. Try again.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      return false;
    }

    return true;
  }

  void login() async {
    if (_isLocked) return;

    setState(() {
      _isUsernameValid = _usernameController.text.isNotEmpty;
      _isPasswordValid = _passwordController.text.isNotEmpty;
    });

    if (!_isUsernameValid || !_isPasswordValid) {
      _usernameController.clear();
      _passwordController.clear();
      _captchaController.clear();

      Get.snackbar(
        "Alert",
        "Username and Password are Empty!",
        backgroundColor: Colors.red,
        snackPosition: SnackPosition.BOTTOM,
        colorText: Colors.white,
        icon: const Icon(Icons.warning, color: Colors.white),
        margin: const EdgeInsets.only(top: 5),
      );
      return;
    }

    if (!verifyCaptcha()) return;

    try {
      String username = _usernameController.text.trim();
      String password = _passwordController.text;

      // Always use "login" operation to let backend identify user type
      String operation = "login";

      var url = Uri.parse("${SessionStorage.url}user.php");

      Map<String, String> requestBody = {
        "operation": operation,
        "json": jsonEncode({"username": username, "password": password}),
      };
      print("jsondata" + jsonEncode(requestBody));

      var response = await http.post(url, body: requestBody);
      var res = jsonDecode(response.body);
      print("🔵 Raw response: ${response.body}");

      // Account doesn't exist or invalid credentials
      if (res == 0 || res == -1) {
        generateCaptcha();
        _usernameController.clear();
        _passwordController.clear();
        _captchaController.clear();

        Get.snackbar(
          "Alert",
          "Account doesn't exist or invalid credentials",
          backgroundColor: Colors.red,
          snackPosition: SnackPosition.BOTTOM,
          colorText: Colors.white,
          icon: const Icon(Icons.warning, color: Colors.white),
          margin: const EdgeInsets.only(top: 5),
        );
        return;
      }

      // Handle incorrect password responses
      if (res is Map<String, dynamic> &&
          res.containsKey("status") &&
          res["status"] == 2) {
        generateCaptcha();
        _usernameController.clear();
        _passwordController.clear();
        _captchaController.clear();

        Get.snackbar(
          "Alert",
          "Incorrect password",
          backgroundColor: Colors.red,
          snackPosition: SnackPosition.BOTTOM,
          colorText: Colors.white,
          icon: const Icon(Icons.warning, color: Colors.white),
          margin: const EdgeInsets.only(top: 5),
        );
        return;
      }

      _failedAttempts = 0;

      // -------------------
      // Admin login
      // -------------------
      if (res is Map<String, dynamic> && res.containsKey("adm_email")) {
        int userLevel = int.tryParse(res["adm_user_level"].toString()) ?? 0;

        if (userLevel == 5) {
          String email = res["adm_email"];
          String name = res["adm_name"];

          Get.snackbar(
            "Success",
            "Welcome $name",
            backgroundColor: Colors.green,
            snackPosition: SnackPosition.BOTTOM,
            colorText: Colors.white,
            icon: const Icon(Icons.check, color: Colors.white),
            margin: const EdgeInsets.only(top: 5),
          );

          SessionStorage.setItem("admin_email", email);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MarketingDashboard(adminEmail: email),
            ),
          );
          return;
        } else {
          // User level not 5, show error and clear inputs
          _usernameController.clear();
          _passwordController.clear();
          _captchaController.clear();

          Get.snackbar(
            "Access Denied",
            "You do not have permission to login as admin.",
            backgroundColor: Colors.red,
            snackPosition: SnackPosition.BOTTOM,
            colorText: Colors.white,
            icon: const Icon(Icons.block, color: Colors.white),
            margin: const EdgeInsets.only(top: 5),
          );
          return;
        }
      }
      // -------------------
      // Supervisor login
      // -------------------
      else if (res.containsKey("supM_email")) {
        String advisorEmail = res['supM_email'];
        String supervisor_id = res['supM_id'].toString();
        bool isDefaultPassword = res['is_default_password'];

        setState(() {
          userIsSupervisor = true;
          advName = res['supM_name'];
          emailController.text = advisorEmail;
          supervisor_id1 = supervisor_id;
        });
        print(supervisor_id1);

        if (res['supM_login_attempts'] == 1) {
          Get.snackbar(
            "Message",
            "Account is Locked please Contact CSDL",
            backgroundColor: Colors.red,
            snackPosition: SnackPosition.BOTTOM,
            colorText: Colors.white,
            icon: const Icon(Icons.warning, color: Colors.white),
            margin: const EdgeInsets.only(top: 5),
          );
          setState(() {
            _isLocked = true;
            _isCaptchaVisible = false;
            _usernameController.clear();
            _passwordController.clear();
          });
        } else if (isDefaultPassword) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ChangePasswordPage(
                userId: advisorEmail, // Use email
                isAdvisor: true,
              ),
            ),
          );
        } else {
          int authStatus = res['supM_authentication_status'];
          if (authStatus == 1) {
            setState(() {
              userIsSupervisorAuthentication = true;
            });
            _showOtpDialog();
          } else {
            SessionStorage.setItem("advisor_email", advisorEmail);
            Get.snackbar(
              "Success",
              "Welcome ${res['supM_name']}",
              backgroundColor: Colors.green,
              snackPosition: SnackPosition.BOTTOM,
              colorText: Colors.white,
              icon: const Icon(Icons.check, color: Colors.white),
              margin: const EdgeInsets.only(top: 5),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => AdvisorScholarList(
                        advisor_id: advisorEmail,
                        supervisor_id: supervisor_id1,
                      )),
            );
          }
        }
      }
      // -------------------
      // Student login
      // -------------------
      else if (res.containsKey("stud_id")) {
        String studentId = res['stud_id'];
        bool isDefaultPassword = res['is_default_password'];

        setState(() {
          userIsStudent = true;
          student_id = studentId;
          studName = res['stud_name'];
          emailController.text = res['stud_email'] ?? "";
        });

        if (res['stud_login_attempts'] == 1) {
          Get.snackbar(
            "Message",
            "Account is Locked please Contact CSDL",
            backgroundColor: Colors.red,
            snackPosition: SnackPosition.BOTTOM,
            colorText: Colors.white,
            icon: const Icon(Icons.warning, color: Colors.white),
            margin: const EdgeInsets.only(top: 5),
          );
          setState(() {
            _isLocked = true;
            _isCaptchaVisible = false;
            _usernameController.clear();
            _passwordController.clear();
          });
        } else if (isDefaultPassword) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ChangePasswordPage(
                userId: studentId,
                isAdvisor: false,
              ),
            ),
          );
        } else {
          int authStatus = res['stud_authentication_status'];
          if (authStatus == 1) {
            _showOtpDialog();
          } else {
            Get.snackbar(
              "Success",
              "Welcome ${res['stud_name']}",
              backgroundColor: Colors.green,
              snackPosition: SnackPosition.BOTTOM,
              colorText: Colors.white,
              icon: const Icon(Icons.check, color: Colors.white),
              margin: const EdgeInsets.only(top: 5),
            );

            String yearName = res['year_name'] ?? '';
            String yearLevel =
                yearName.length >= 2 ? yearName.substring(0, 2) : '';

            SessionStorage.setItem("student_id", studentId);
            SessionStorage.setItem("is_fresh", yearLevel == 'Y1' ? "1" : "0");

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => yearLevel == 'Y1'
                    ? FreshStudent(student_id: studentId)
                    : StudentDashboard(student_id: studentId),
              ),
            );
          }
        }
      } else {
        // If response doesn't match any user type
        Get.snackbar(
          "Alert",
          "Invalid login response",
          backgroundColor: Colors.red,
          snackPosition: SnackPosition.BOTTOM,
          colorText: Colors.white,
          icon: const Icon(Icons.warning, color: Colors.white),
          margin: const EdgeInsets.only(top: 5),
        );
        _usernameController.clear();
        _passwordController.clear();
        _captchaController.clear();
      }
    } catch (e) {
      print("❌ Error: $e");
      _usernameController.clear();
      _passwordController.clear();
      _captchaController.clear();

      Get.snackbar(
        "Error",
        "An error occurred during login. Please try again.",
        backgroundColor: Colors.red,
        snackPosition: SnackPosition.BOTTOM,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
        margin: const EdgeInsets.only(top: 5),
      );
    }
  }

  void _showOtpDialog() {
    final otpController = TextEditingController(); // OTP input controller
    String generatedOtp = ''; // Store generated OTP

    // Function to generate a random OTP
    String generateOtp() {
      Random random = Random();
      return (random.nextInt(90000) + 10000).toString();
    }

    // Send OTP via API
    void sendOtp(String email, String otp) async {
      try {
        var url = Uri.parse("${SessionStorage.url}transaction.php");

        Map<String, dynamic> jsonData = {
          "emailToSent": email,
          "emailBody": otp, // Send OTP
        };

        Map<String, String> requestBody = {
          "operation": "sendEmail", // Trigger OTP sending
          "json": jsonEncode(jsonData),
        };

        var response = await http.post(url, body: requestBody);
        print(response.headers);
        var res = jsonDecode(response.body);

        if (res != 0) {
          // Success: OTP sent
          Get.snackbar(
            "OTP Sent",
            "OTP has been sent to your $emailController",
            backgroundColor: Colors.green,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );
        } else {
          // Failure: Show error
          Get.snackbar(
            "Error",
            "Failed to send OTP. Please try again.",
            backgroundColor: Colors.red,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      } catch (e) {
        print("Error: $e");
        Get.snackbar(
          "Error",
          "An error occurred while sending the OTP. Please try again.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }

    // Show OTP dialog
    showShadDialog(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(30.0),
        child: ShadDialog(
          title: const Text('Enter OTP', style: TextStyle(color: Colors.white)),
          actions: [
            ShadButton(
              backgroundColor: Color(0xFF104038),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.pop(context); // Close dialog on cancel
              },
            ),
            ShadButton(
              backgroundColor: Color(0xFF104038),
              child: const Text('Verify OTP',
                  style: TextStyle(color: Colors.white)),
              onPressed: () {
                // Verify OTP entered by user
                if (otpController.text == generatedOtp) {
                  if (userIsSupervisorAuthentication) {
                    Navigator.pop(context); // Close OTP dialog

                    Get.snackbar(
                      "Success",
                      "Welcome $advName",
                      backgroundColor: Colors.green,
                      snackPosition: SnackPosition.BOTTOM,
                      colorText: Colors.white,
                      icon: const Icon(Icons.check, color: Colors.white),
                      margin: const EdgeInsets.only(top: 5),
                    );
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Advisor(
                          advisor_id: advisor_id,
                          supervisor_id: supervisor_id1,
                        ),
                      ),
                    );
                  } else {
                    Navigator.pop(context); // Close OTP dialog
                    Get.snackbar(
                      "Success",
                      "Welcome $studName",
                      backgroundColor: Colors.green,
                      snackPosition: SnackPosition.BOTTOM,
                      colorText: Colors.white,
                      icon: const Icon(Icons.check, color: Colors.white),
                      margin: const EdgeInsets.only(top: 5),
                    );
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              StudentDashboard(student_id: student_id)),
                    );
                  }
                } else {
                  Get.snackbar(
                    "Error",
                    "Incorrect OTP. Please try again.",
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                    snackPosition: SnackPosition.BOTTOM,
                  );
                }
              },
            ),
          ],
          child: Container(
            width: 280,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShadInput(
                  controller:
                      emailController, // Bind email input to the controller
                  obscureText: false,
                  placeholder: Text(userEmail),
                ),
                const SizedBox(height: 8),
                ShadInput(
                  controller: otpController,
                  obscureText: false,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  placeholder: Text("Enter OTP"),
                ),
                const SizedBox(height: 8),
                ShadButton(
                  child: const Text('Send OTP'),
                  onPressed: () {
                    generatedOtp = generateOtp(); // Generate OTP
                    sendOtp(emailController.text, generatedOtp); // Send OTP
                  },
                  backgroundColor: Color(0xFF104038),
                ),
                // Display message after OTP is sent
                if (generatedOtp.isNotEmpty) ...[
                  Text(
                    'OTP is being sent to: $emailController',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void updateLoginAttempt() async {
    try {
      var url = Uri.parse("${SessionStorage.url}transaction.php");

      // Declare jsonData outside of the if-else block so it's available for the whole function
      Map<String, dynamic> jsonData = {
        "username": _usernameController.text, // Use the username (email or ID)
        "login_attempts": 1
      };

      // Build the request body
      Map<String, String> requestBody = {
        "operation": "updateLoginAttempts",
        "json": jsonEncode(jsonData), // Encode JSON data properly
      };

      // Send the request
      var response = await http.post(url, body: requestBody);

      if (response.statusCode == 200) {
        var res = jsonDecode(response.body);

        // Check the response from the backend
        if (res['success'] != null) {
          print("Success: ${res['success']}");
          // Optionally show a dialog or notification to the user about success
        } else if (res == 0) {
          print("No matching user found!");
          // Optionally notify the user that no matching user was found
        } else {
          print("Error: $res");
          // Handle error if backend sends an error message
        }
      } else {
        print(
            "Error: Failed to send request. Status code: ${response.statusCode}");
        // Handle HTTP errors, maybe show a message to the user
      }
    } catch (e) {
      print("Error: $e");
      // Handle any exceptions thrown during the request
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Image.asset(
            'assets/images/csdl_background.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment.topLeft,
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromRGBO(255, 255, 255, 0.9),
                  Color.fromRGBO(255, 255, 255, 0.9),
                ],
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
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 12, 94, 15),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'HK Scholars',
                    style: TextStyle(
                      fontSize: 20,
                      color: Color.fromARGB(255, 12, 94, 15),
                      height: 1,
                    ),
                  ),
                  const Text(
                    'Management System',
                    style: TextStyle(
                      fontSize: 20,
                      color: Color.fromARGB(255, 12, 94, 15),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(162, 0, 0, 0),
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
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 5, horizontal: 10),
                            filled: true,
                            fillColor: Colors.green[50],
                            labelText: 'Username',
                            labelStyle: const TextStyle(
                              color: Colors.black,
                              fontSize: 13,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            errorText: _isUsernameValid
                                ? null
                                : 'Username is required',
                          ),
                          style: const TextStyle(
                              color: Colors.black, fontSize: 13),
                          inputFormatters: [_usernameInputFormatter],
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_passwordVisible,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 5, horizontal: 10),
                            filled: true,
                            fillColor: Colors.green[50],
                            labelText: 'Password',
                            labelStyle: const TextStyle(
                                color: Colors.black, fontSize: 13),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            errorText: _isPasswordValid
                                ? null
                                : 'Password is required',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _passwordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _passwordVisible = !_passwordVisible;
                                });
                              },
                            ),
                          ),
                          style: const TextStyle(
                              color: Colors.black, fontSize: 13),
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
                                          vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 5,
                                            offset: Offset(2, 2),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: List.generate(
                                            generatedCaptcha.length,
                                            (index) {
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 5),
                                                child: Text(
                                                  generatedCaptcha[index],
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                              const SizedBox(height: 15),
                              SizedBox(
                                width: 150,
                                child: TextField(
                                  controller: _captchaController,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 15),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,
                                    hintText: "Enter Captcha",
                                    contentPadding:
                                        const EdgeInsets.symmetric(vertical: 5),
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
                              GestureDetector(
                                onTap: () async {
                                  setState(() {
                                    _isCaptchaChecked = !_isCaptchaChecked;
                                    _isCaptchaVisible = true;
                                  });

                                  if (_isCaptchaChecked) {
                                    setState(() {
                                      _isLoadingCaptcha = true;
                                    });

                                    await Future.delayed(Duration(seconds: 2));

                                    setState(() {
                                      _isCaptchaVisible = true;
                                      _isLoadingCaptcha = false;
                                    });
                                  }
                                },
                                child: Visibility(
                                  visible: !_isLocked,
                                  child: Row(
                                    children: [
                                      Container(
                                        height: 24,
                                        width: 24,
                                        decoration: BoxDecoration(
                                          color: _isCaptchaChecked
                                              ? Colors.green
                                              : Colors.grey,
                                          borderRadius:
                                              BorderRadius.circular(5),
                                        ),
                                        child: _isCaptchaChecked
                                            ? Icon(Icons.check,
                                                size: 20, color: Colors.white)
                                            : null,
                                      ),
                                      const SizedBox(width: 10),
                                      const Text(
                                        "I'm not a robot",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
                        Visibility(
                          visible: !_isLocked,
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.withOpacity(0.5),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                              child: const Text(
                                "Login",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                              onPressed: () {
                                login();
                              },
                            ),
                          ),
                        ),
                        Visibility(
                          visible: !_isLocked,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {},
                                child: Text(
                                  "Forgot Password?",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontStyle: FontStyle.italic,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Visibility(
                          visible: _isLocked,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'Your account is Locked',
                              style: TextStyle(color: Colors.red, fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 90),
                  const Text(
                    "Powered by: PHINMA-COC",
                    style: TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
          ),

          // 🔽 ICON BUTTON MUST BE AT THE END OF Stack children 🔽
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 10,
            child: IconButton(
              icon: Icon(Icons.info_outline,
                  color: Color.fromARGB(255, 12, 94, 15)),
              tooltip: 'Request Info',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Notice'),
                      content: const Text(
                        'This request is for students that are Returnee or Continuing.',
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('I understand'),
                          onPressed: () {
                            Navigator.of(context).pop(); // Close dialog
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ScholarshipRequestForm(),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

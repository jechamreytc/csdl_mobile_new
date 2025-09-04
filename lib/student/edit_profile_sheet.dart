import 'dart:convert';
import 'dart:math';
import 'package:csdl_mobile/session_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:http/http.dart' as http;

class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({
    Key? key,
    required this.side,
    required this.student_id,
  }) : super(key: key);

  final String student_id;
  final ShadSheetSide side;

  @override
  _EditProfileSheetState createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  String studentName = '';
  String studentId = '';
  String courseName = '';
  String scholarshipType = '';

  int remainingTime = 5; // 5 minutes in seconds
  String contactNumber = '';
  String email = '';
  int authenticationStatus = 0;
  String currentPassword = '';
  bool isButtonDisabled = false;
  bool isTwoFactorEnabled = false; // Track the state of the switch
  // Define TextEditingControllers for each field
  late TextEditingController contactNumberController;
  late TextEditingController emailController;

  @override
  void initState() {
    super.initState();
    contactNumberController = TextEditingController();
    emailController = TextEditingController();
    getStudentProfile();
  }

  @override
  void dispose() {
    contactNumberController.dispose();
    emailController.dispose();
    super.dispose();
  }

  void getStudentProfile() async {
    try {
      var url = Uri.parse("${SessionStorage.url}transaction.php");
      Map<String, dynamic> jsonData = {
        "stud_id": widget.student_id,
      };
      Map<String, String> requestBody = {
        "operation": "getStudentProfile",
        "json": jsonEncode(jsonData),
      };

      var response = await http.post(url, body: requestBody);
      var res = jsonDecode(response.body);

      if (res != 0) {
        setState(() {
          studentId = res['stud_id'];
          studentName = res['stud_name'];
          courseName = res['course_name'];
          scholarshipType = res['type_name'];
          contactNumber = res['stud_contactNumber'] ?? 'N/A';
          email = res['stud_email'] ?? 'N/A';
          contactNumberController.text = contactNumber;
          emailController.text = email;
          currentPassword = res['stud_password'] ?? '';
          authenticationStatus = res['stud_authentication_status'];
        });
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  void updateScholarsProfile() async {
    try {
      var url = Uri.parse("${SessionStorage.url}transaction.php");
      Map<String, dynamic> jsonData = {
        "stud_id": widget.student_id,
        "stud_contactNumber": contactNumberController.text,
        "stud_email": emailController.text,
      };
      Map<String, String> requestBody = {
        "operation": "updateScholarsProfile",
        "json": jsonEncode(jsonData),
      };

      var response = await http.post(url, body: requestBody);
      if (response.statusCode == 200) {
        var res = jsonDecode(response.body);
        if (res != 0) {
          Get.snackbar(
            "Success",
            "Profile updated successfully",
            backgroundColor: Colors.green,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return ShadSheet(
      backgroundColor: Colors.green.shade50,
      constraints: widget.side == ShadSheetSide.left ||
              widget.side == ShadSheetSide.right
          ? const BoxConstraints(maxWidth: 400) // Adjusted for mobile
          : null,
      title: Text('Edit Profile',
          style:
              TextStyle(color: Color(0xFF104038), fontWeight: FontWeight.bold)),
      description: Text(
          "Make changes to your profile here. Click save when you're done.",
          style: TextStyle(color: Color(0xFF104038))),
      actions: [
        ShadButton(
          backgroundColor: Color(0xFF104038),
          child:
              const Text('Save changes', style: TextStyle(color: Colors.white)),
          onPressed: () {
            updateScholarsProfile();
            Navigator.pop(context);
          },
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Data in a Single Card
          _buildProfileCard(),
          const SizedBox(height: 16),

          // Contact Number (Editable)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Contact Number",
                  style: theme.textTheme.small,
                ),
                const SizedBox(height: 8),
                ShadInput(controller: contactNumberController),
              ],
            ),
          ),

          // Email (Editable)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Email",
                  style: theme.textTheme.small,
                ),
                const SizedBox(height: 8),
                ShadInput(controller: emailController),
              ],
            ),
          ),

          // 2FA (Two-Factor Authentication) Switch
          // Padding(
          //   padding: const EdgeInsets.only(bottom: 16),
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //     children: [
          //       Flexible(
          //         child: Text(
          //           "Enable 2FA", // Shortened text
          //           style: theme.textTheme.small,
          //           overflow: TextOverflow.ellipsis, // Handle overflow
          //         ),
          //       ),
          //       ShadSwitch(
          //         value: authenticationStatus == 1, // 2FA switch is on when 1
          //         onChanged: (bool v) {
          //           setState(() {
          //             authenticationStatus = v ? 1 : 0;
          //           });
          //         },
          //       ),
          //     ],
          //   ),
          // ),

          // // Change Password Button
          // Padding(
          //   padding: const EdgeInsets.only(bottom: 16),
          //   child: ShadButton(
          //     child: const Text('Change Password'),
          //     onPressed: () {
          //       _showOtpDialog(isForPasswordChange: true);
          //     },
          //   ),
          // ),
          Card(
            color: Colors.white,
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Shortened text with a smaller font and overflow handling
                      Flexible(
                        child: Text(
                          "Enable 2-Factor Authentication", // Shortened text
                          style: TextStyle(
                              color: Color(0xFF104038),
                              fontWeight: FontWeight.w600),
                          overflow: TextOverflow
                              .ellipsis, // Handle overflow with ellipsis
                        ),
                      ),
                      // Using ShadSwitch
                      ShadSwitch(
                        value: authenticationStatus ==
                            1, // Switch is on when authenticationStatus is 1
                        onChanged: (bool v) {
                          setState(() {
                            // Set the authenticationStatus based on the switch state
                            authenticationStatus = v
                                ? 1
                                : 0; // Update authenticationStatus to 1 or 0

                            // Update the isTwoFactorEnabled flag accordingly
                            isTwoFactorEnabled = v;
                          });

                          if (v) {
                            // If 2FA is turned on, show OTP dialog for verification
                            _showOtpDialog(
                                isForPasswordChange:
                                    false); // Pass false for enabling 2FA
                          } else {
                            // If 2FA is turned off, show OTP dialog and verify OTP before disabling 2FA
                            _showOtpDialog(
                                isForPasswordChange: false,
                                isForDisabling2FA:
                                    true); // Pass true for disabling 2FA
                          }
                        },
                        thumbColor: Color(0xFF104038),
                        // thumbColor: Colors.green.shade200,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ShadButton(
                      backgroundColor: Color(0xFF104038),
                      child: const Text('Change Password',
                          style: TextStyle(color: Colors.white)),
                      onPressed: () {
                        // Show OTP dialog before changing password
                        _showOtpDialog(
                            isForPasswordChange:
                                true); // Pass flag to indicate it's for password change
                      },
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

// Helper function to build the profile card with all data
  Widget _buildProfileCard() {
    final theme = ShadTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.green.shade100],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student Name
          _buildProfileInfo("Name", studentName),
          const SizedBox(height: 16),

          // Student ID
          _buildProfileInfo("Student ID", studentId),
          const SizedBox(height: 16),

          // Course Name (Flexible to adjust)
          _buildProfileInfoFlexible("Course", courseName),
          const SizedBox(height: 16),

          // Scholarship Type
          _buildProfileInfo("Scholarship Type", scholarshipType),
        ],
      ),
    );
  }

// Helper function to build individual profile info
  Widget _buildProfileInfo(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

// Flexible version for Course Name to fit dynamically
  Widget _buildProfileInfoFlexible(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis, // Handles text overflow
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ),
      ],
    );
  }

  // OTP Dialog to confirm the changes for 2FA or password change
  void _showOtpDialog(
      {bool isForPasswordChange = false, bool isForDisabling2FA = false}) {
    final otpController = TextEditingController();
    String generatedOtp = '';
    String emailToSendOtp = emailController.text;
    bool isOtpSent = false;

    String generateOtp() {
      Random random = Random();
      return (random.nextInt(90000) + 10000).toString();
    }

    void sendOtp(String email, String otp) async {
      try {
        var url = Uri.parse("${SessionStorage.url}transaction.php");

        Map<String, dynamic> jsonData = {
          "emailToSent": email,
          "emailBody": otp, // Send OTP
        };

        Map<String, String> requestBody = {
          "operation": "sendEmail",
          "json": jsonEncode(jsonData),
        };

        var response = await http.post(url, body: requestBody);
        var res = jsonDecode(response.body);

        if (res != 0) {
          setState(() {
            var isButtonDisabled = true;
          });
          Get.snackbar(
            "OTP Sent",
            "OTP has been sent to your $emailToSendOtp",
            backgroundColor: Colors.green,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );
        } else {
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
                Navigator.pop(context);
              },
            ),
            ShadButton(
              backgroundColor: Color(0xFF104038),
              child: const Text('Verify OTP',
                  style: TextStyle(color: Colors.white)),
              onPressed: () {
                if (!isOtpSent) {
                  Get.snackbar(
                    "Error",
                    "Please send OTP first.",
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                    snackPosition: SnackPosition.BOTTOM,
                  );
                  return;
                }

                if (otpController.text.isEmpty) {
                  Get.snackbar(
                    "Error",
                    "OTP cannot be empty.",
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                    snackPosition: SnackPosition.BOTTOM,
                  );
                  return;
                }

                if (otpController.text == generatedOtp) {
                  Navigator.pop(context);
                  if (isForPasswordChange) {
                    _showChangePasswordDialog();
                  } else if (isForDisabling2FA) {
                    disable2FA();
                  } else {
                    enable2fa();
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
                const Text('Enter OTP', style: TextStyle(color: Colors.white)),
                const SizedBox(height: 4),
                ShadInput(controller: otpController, obscureText: false),
                const SizedBox(height: 8),
                if (!isOtpSent)
                  ShadButton(
                    backgroundColor: Color(0xFF104038),
                    child: const Text('Send OTP'),
                    onPressed: () {
                      generatedOtp = generateOtp();
                      sendOtp(emailToSendOtp, generatedOtp);
                      setState(() {
                        isOtpSent = true;
                      });
                    },
                  ),
                if (isOtpSent) ...[
                  Text(
                    'OTP is being sent to: $emailToSendOtp',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Functions for enabling and disabling 2FA and logout
  void enable2fa() async {
    try {
      var url = Uri.parse("${SessionStorage.url}transaction.php");

      Map<String, dynamic> jsonData = {
        "stud_id": widget.student_id,
        "stud_authentication_status": 1,
      };

      Map<String, String> requestBody = {
        "operation": "updateTwoFactorAuthenticationStudent",
        "json": jsonEncode(jsonData),
      };

      var response = await http.post(url, body: requestBody);

      if (response.statusCode == 200) {
        var res = jsonDecode(response.body);
        if (res != 0) {
          Get.snackbar(
            "Success",
            "Two-Factor Authentication enabled successfully.",
            backgroundColor: Colors.green,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );
        } else {
          Get.snackbar(
            "Error",
            "Failed to enable Two-Factor Authentication.",
            backgroundColor: Colors.red,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      }
    } catch (e) {
      print("Error: $e");
      Get.snackbar(
        "Error",
        "An error occurred while enabling 2FA.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void disable2FA() async {
    try {
      var url = Uri.parse("${SessionStorage.url}transaction.php");

      Map<String, dynamic> jsonData = {
        "stud_id": widget.student_id,
        "stud_authentication_status": 0,
      };

      Map<String, String> requestBody = {
        "operation": "updateTwoFactorAuthenticationStudent",
        "json": jsonEncode(jsonData),
      };

      var response = await http.post(url, body: requestBody);

      if (response.statusCode == 200) {
        var res = jsonDecode(response.body);
        if (res != 0) {
          Get.snackbar(
            "Success",
            "Two-Factor Authentication disabled successfully.",
            backgroundColor: Colors.green,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );
        } else {
          Get.snackbar(
            "Error",
            "Failed to disable Two-Factor Authentication.",
            backgroundColor: Colors.red,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      }
    } catch (e) {
      print("Error: $e");
      Get.snackbar(
        "Error",
        "An error occurred while disabling 2FA.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _logout() async {
    Navigator.pushReplacementNamed(context, '/home');
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    bool hasNumber = false;
    bool hasLetter = false;
    bool hasSymbol = false;
    bool hasUpperAndLower = false;

    void validatePassword(
        String password, void Function(void Function()) setState) {
      hasNumber = password.contains(RegExp(r'[0-9]'));
      hasLetter = password.contains(RegExp(r'[a-zA-Z]'));
      hasSymbol = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
      hasUpperAndLower = password.contains(RegExp(r'[a-z]')) &&
          password.contains(RegExp(r'[A-Z]'));
      setState(() {});
    }

    showShadDialog(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(30.0),
        child: StatefulBuilder(
          builder: (context, setState) {
            return ShadDialog(
              title: const Text(
                'Change Password',
                style: TextStyle(color: Colors.white),
              ),
              actions: [
                ShadButton(
                  backgroundColor: const Color(0xFF104038),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                ShadButton(
                  backgroundColor: const Color(0xFF104038),
                  child:
                      const Text('Save', style: TextStyle(color: Colors.white)),
                  onPressed: () async {
                    if (currentPasswordController.text.isEmpty ||
                        newPasswordController.text.isEmpty ||
                        confirmPasswordController.text.isEmpty) {
                      Get.snackbar("Error", "All fields are required!",
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                          snackPosition: SnackPosition.BOTTOM);
                      return;
                    }

                    if (newPasswordController.text.length < 8 ||
                        newPasswordController.text.length > 20) {
                      Get.snackbar(
                          "Error", "Password must be 8–20 characters long.",
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                          snackPosition: SnackPosition.BOTTOM);
                      return;
                    }

                    if (!hasNumber ||
                        !hasLetter ||
                        !hasSymbol ||
                        !hasUpperAndLower) {
                      Get.snackbar("Error",
                          "Password must include: number, letter, symbol, uppercase & lowercase.",
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                          snackPosition: SnackPosition.BOTTOM);
                      return;
                    }

                    try {
                      var url =
                          Uri.parse("${SessionStorage.url}transaction.php");
                      Map<String, dynamic> jsonData = {
                        "username": widget.student_id,
                        "stud_id": widget.student_id,
                        "stud_currentPassword":
                            currentPasswordController.text, // ✅ FIXED
                        "stud_password": newPasswordController.text,
                      };

                      Map<String, String> requestBody = {
                        "operation": "verifyAndUpdatePassword",
                        "json": jsonEncode(jsonData),
                      };

                      var response = await http.post(url, body: requestBody);

                      if (response.statusCode == 200) {
                        var res = jsonDecode(response.body);
                        if (res == 1) {
                          Get.snackbar(
                            "Success",
                            "Password updated successfully.",
                            backgroundColor: Colors.green,
                            colorText: Colors.white,
                            snackPosition: SnackPosition.BOTTOM,
                          );
                          Navigator.pop(context);
                        } else if (res == 2) {
                          Get.snackbar(
                            "Notice",
                            "Password already updated before.",
                            backgroundColor: Colors.orange,
                            colorText: Colors.white,
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        } else {
                          Get.snackbar(
                            "Error",
                            "Failed to update password.",
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        }
                      } else {
                        Get.snackbar(
                          "Error",
                          "Server error: ${response.statusCode}",
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      }
                    } catch (e) {
                      Get.snackbar("Error", "An error occurred: $e",
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                          snackPosition: SnackPosition.BOTTOM);
                    }
                  },
                ),
              ],
              child: Container(
                width: 300,
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Change Password",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    // Current Password
                    ShadInput(
                      controller: currentPasswordController,
                      placeholder: const Text("Current Password"),
                      obscureText: obscureCurrent,
                      leading: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(Icons.lock),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          obscureCurrent
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() => obscureCurrent = !obscureCurrent);
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // New Password
                    ShadInput(
                      controller: newPasswordController,
                      placeholder: const Text("New Password"),
                      obscureText: obscureNew,
                      leading: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(Icons.lock_outline),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          obscureNew ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() => obscureNew = !obscureNew);
                        },
                      ),
                      onChanged: (val) => validatePassword(val, setState),
                    ),
                    const SizedBox(height: 12),

                    // Confirm New Password
                    ShadInput(
                      controller: confirmPasswordController,
                      placeholder: const Text("Confirm New Password"),
                      obscureText: obscureConfirm,
                      leading: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(Icons.lock_outline),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          obscureConfirm
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() => obscureConfirm = !obscureConfirm);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password validation list
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildValidationItem("At least 8 characters",
                              newPasswordController.text.length >= 8),
                          _buildValidationItem(
                              "Max 20 characters",
                              newPasswordController.text.length <= 20 &&
                                  newPasswordController.text.isNotEmpty),
                          _buildValidationItem(
                              "At least one number", hasNumber),
                          _buildValidationItem(
                              "At least one letter", hasLetter),
                          _buildValidationItem(
                              "At least one symbol", hasSymbol),
                          _buildValidationItem(
                              "Both uppercase and lowercase letters",
                              hasUpperAndLower),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

// Helper for validation list
  Widget _buildValidationItem(String text, bool isValid) {
    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.cancel,
          color: isValid ? Colors.green : Colors.red,
          size: 18,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: isValid ? Colors.green : Colors.red,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

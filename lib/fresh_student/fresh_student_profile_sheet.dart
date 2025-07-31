import 'dart:convert';
import 'dart:math';
import 'package:csdl_mobile/session_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:http/http.dart' as http;

class FreshStudentProfileSheet extends StatefulWidget {
  const FreshStudentProfileSheet({
    Key? key,
    required this.side,
    required this.student_id,
  }) : super(key: key);

  final String student_id;
  final ShadSheetSide side;

  @override
  _FreshStudentProfileSheetState createState() =>
      _FreshStudentProfileSheetState();
}

class _FreshStudentProfileSheetState extends State<FreshStudentProfileSheet> {
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
    // Initialize the controllers
    contactNumberController = TextEditingController(text: contactNumber);
    emailController = TextEditingController(text: email);
    // passwordController = TextEditingController(text: "password123");
    getStudentProfile();
  }

  @override
  void dispose() {
    // Clean up the controllers when the widget is disposed
    contactNumberController.dispose();
    emailController.dispose();
    super.dispose();
  }

  // Function to start the countdown timer

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return ShadSheet(
      constraints: widget.side == ShadSheetSide.left ||
              widget.side == ShadSheetSide.right
          ? const BoxConstraints(maxWidth: 400) // Adjusted for mobile
          : null,
      title: const Text('Edit Profile'),
      description: const Text(
          "Make changes to your profile here. Click save when you're done."),
      actions: [
        ShadButton(
          child: const Text('Save changes'),
          onPressed: () {
            updateScholarsProfile();
            Navigator.pop(context);
          },
        ),
      ],
      child: SingleChildScrollView(
        // Added scroll view for better handling of the keyboard
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 8), // Reduced padding for mobile
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start, // Align the text to the left
          children: [
            // Contact Number Input
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start, // Aligning the text to the left
                children: [
                  Text(
                    "Contact Number",
                    style: theme.textTheme.small,
                  ),
                  const SizedBox(height: 8), // Space between label and input
                  ShadInput(controller: contactNumberController),
                ],
              ),
            ),

            // Email Input
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start, // Aligning the text to the left
                children: [
                  Text(
                    "Email",
                    style: theme.textTheme.small,
                  ),
                  const SizedBox(height: 8), // Space between label and input
                  ShadInput(controller: emailController),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Shortened text with a smaller font and overflow handling
                  Flexible(
                    child: Text(
                      "Enable 2FA", // Shortened text
                      style: theme.textTheme.small,
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
                        authenticationStatus =
                            v ? 1 : 0; // Update authenticationStatus to 1 or 0

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
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ShadButton(
                child: const Text('Change Password'),
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
    );
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
        print(res);
        if (mounted) {
          // Check if the widget is still mounted
          setState(() {
            contactNumberController.text = res['stud_contactNumber'] ?? 'NULL';
            emailController.text = res['stud_email'] ?? 'NULL';
            currentPassword =
                res['stud_password'] ?? ''; // Save current password
            authenticationStatus = res['stud_authentication_status'];
          });
          print(authenticationStatus);
        }
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

      // Check if the response is valid JSON
      if (response.statusCode == 200) {
        try {
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
        } catch (e) {
          print("Error parsing response as JSON: $e");
        }
      } else {
        print("Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  void _showOtpDialog(
      {bool isForPasswordChange = false, bool isForDisabling2FA = false}) {
    final otpController = TextEditingController(); // OTP input controller
    String generatedOtp = ''; // Store generated OTP
    String emailToSendOtp = emailController.text; // Email for OTP
    bool isOtpSent = false; // Track if OTP is sent

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
        var res = jsonDecode(response.body);

        if (res != 0) {
          // Success: OTP sent
          setState(() {
            isButtonDisabled = true; // Disable button after OTP sent
          });
          Get.snackbar(
            "OTP Sent",
            "OTP has been sent to your $emailToSendOtp",
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
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.black)),
              onPressed: () {
                Navigator.pop(context); // Close dialog on cancel
              },
            ),
            ShadButton(
              child: const Text('Verify OTP',
                  style: TextStyle(color: Colors.black)),
              onPressed: () {
                // Verify OTP entered by user
                if (otpController.text == generatedOtp) {
                  Navigator.pop(context); // Close OTP dialog

                  if (isForPasswordChange) {
                    _showChangePasswordDialog(); // Show password change dialog
                  } else if (isForDisabling2FA) {
                    disable2FA(); // Disable 2FA after OTP verification
                  } else {
                    enable2fa(); // Enable 2FA after OTP validation
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
                    child: const Text('Send OTP'),
                    onPressed: () {
                      generatedOtp = generateOtp(); // Generate OTP
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
                  // Display countdown
                  Text(
                    'Time remaining: ${remainingTime ~/ 60}:${remainingTime % 60}',
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

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    // Validation function for the fields
    bool validateFields() {
      if (currentPasswordController.text.isEmpty) {
        Get.snackbar(
          "Error",
          "Current Password cannot be empty.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      } else if (newPasswordController.text.isEmpty) {
        Get.snackbar(
          "Error",
          "New Password cannot be empty.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      } else if (confirmPasswordController.text.isEmpty) {
        Get.snackbar(
          "Error",
          "Confirm Password cannot be empty.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      } else if (newPasswordController.text != confirmPasswordController.text) {
        Get.snackbar(
          "Error",
          "New Password and Confirm Password do not match.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }
      return true;
    }

    // Show the Change Password dialog
    showShadDialog(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(30.0),
        child: ShadDialog(
          title: const Text('Change Password',
              style: TextStyle(color: Colors.white)),
          actions: [
            ShadButton(
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.black)),
              onPressed: () {
                Navigator.pop(
                    context); // Close the dialog without changing the password
              },
            ),
            ShadButton(
              child: const Text('Save Changes',
                  style: TextStyle(color: Colors.black)),
              onPressed: () {
                // Validate fields before proceeding
                if (validateFields()) {
                  _updatePassword(currentPasswordController.text,
                      newPasswordController.text);
                  Navigator.pop(context); // Close the dialog
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
                // Current Password Field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Current Password',
                        style: TextStyle(color: Colors.white)),
                    const SizedBox(height: 4),
                    ShadInput(
                        controller: currentPasswordController,
                        obscureText: true),
                  ],
                ),
                const SizedBox(height: 12),
                // New Password Field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('New Password',
                        style: TextStyle(color: Colors.white)),
                    const SizedBox(height: 4),
                    ShadInput(
                        controller: newPasswordController, obscureText: true),
                  ],
                ),
                const SizedBox(height: 12),
                // Confirm New Password Field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Confirm New Password',
                        style: TextStyle(color: Colors.white)),
                    const SizedBox(height: 4),
                    ShadInput(
                        controller: confirmPasswordController,
                        obscureText: true),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _updatePassword(String currentPassword, String newPassword) async {
    // Ensure the current password field is not empty
    if (currentPassword.isEmpty || newPassword.isEmpty) {
      Get.snackbar(
        "Error",
        "Please fill in both current and new password",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    var url = Uri.parse("${SessionStorage.url}transaction.php");
    Map<String, dynamic> jsonData = {
      "stud_id": widget.student_id,
      "stud_currentPassword":
          currentPassword, // Send current password to verify
      "stud_password": newPassword, // New password for update
    };

    Map<String, String> requestBody = {
      "operation": "verifyAndUpdatePassword", // Updated operation name
      "json": jsonEncode(jsonData),
    };

    print(jsonData);

    try {
      var response = await http.post(url, body: requestBody);
      var res = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (res == 1) {
          if (mounted) {
            // Check if the widget is still mounted
            Get.snackbar(
              "Success",
              "Password changed successfully",
              backgroundColor: Colors.green,
              colorText: Colors.white,
              snackPosition: SnackPosition.BOTTOM,
            );
            Navigator.pop(context);
            _logout(); // Logout after successful password change
          }
        } else if (res == 0) {
          if (mounted) {
            // Check if the widget is still mounted
            Get.snackbar(
              "Error",
              "Current password is incorrect",
              backgroundColor: Colors.red,
              colorText: Colors.white,
              snackPosition: SnackPosition.BOTTOM,
            );
          }
        } else {
          if (mounted) {
            // Check if the widget is still mounted
            Get.snackbar(
              "Error",
              "Failed to change password. Please try again.",
              backgroundColor: Colors.red,
              colorText: Colors.white,
              snackPosition: SnackPosition.BOTTOM,
            );
          }
        }
      }
    } catch (e) {
      print("Error: $e");
      if (mounted) {
        // Check if the widget is still mounted
        Get.snackbar(
          "Error",
          "An error occurred while changing password.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

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

// Logout Function
  void _logout() async {
    Navigator.pushReplacementNamed(context, '/home');
  }
}

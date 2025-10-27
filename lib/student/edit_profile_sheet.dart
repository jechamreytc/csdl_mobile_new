import 'dart:convert';
import 'dart:math';
import 'package:csdl_mobile/session_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  
  // Validation error messages
  String? contactNumberError;
  String? emailError;
  
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

  // Validation methods
  bool validateContactNumber(String value) {
    if (value.isEmpty) {
      contactNumberError = "Contact number is required";
      return false;
    }
    
    // Check if it contains only numbers
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      contactNumberError = "Contact number must contain only numbers";
      return false;
    }
    
    // Check if it has exactly 11 digits
    if (value.length != 11) {
      contactNumberError = "Contact number must be exactly 11 digits";
      return false;
    }
    
    contactNumberError = null;
    return true;
  }

  bool validateEmail(String value) {
    if (value.isEmpty) {
      emailError = "Email is required";
      return false;
    }
    
    // Email validation regex
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      emailError = "Please enter a valid email address";
      return false;
    }
    
    emailError = null;
    return true;
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
      // print("Error: $e");
    }
  }

  Future<void> _logActivity({
    required String userId,
    required int userTypeId,
    required String action,
    required String module,
    required String operation,
    Map<String, dynamic>? details,
    String status = "success",
    String? errorMessage,
  }) async {
    try {
      var url = Uri.parse("${SessionStorage.url}activity_log.php");

      Map<String, dynamic> payload = {
        "user_id": userId,
        "user_type_id": userTypeId,
        "action": action,
        "module": module,
        "operation": operation,
        "details": details,
        "status": status,
        "error_message": errorMessage,
      };

      var response = await http.post(url, body: {
        "operation": "logActivity", // âœ… this matches your PHP
        "json": jsonEncode(payload),
      });

      if (response.statusCode == 200) {
        // print(
        //     "âœ… Activity logged: $action on $module ($operation) â†’ ${response.body}");
      } else {
        // print("âš ï¸ Failed to log activity: ${response.body}");
      }
    } catch (e) {
      // print("âŒ Error logging activity: $e");
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
          _logActivity(
            userId: widget.student_id,
            userTypeId: 1,
            action: "UPDATE",
            module: "scholars",
            operation: "updateScholarsProfile",
            details: {
              "stud_contactNumber": contactNumberController.text,
              "stud_email": emailController.text,
            },
          );
        }
      }
    } catch (e) {
      // print("Error: $e");
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
            // Validate fields before saving
            bool isContactValid = validateContactNumber(contactNumberController.text);
            bool isEmailValid = validateEmail(emailController.text);
            
            if (isContactValid && isEmailValid) {
              updateScholarsProfile();
              Navigator.pop(context);
            } else {
              setState(() {}); // Refresh to show error messages
              Get.snackbar(
                "Validation Error",
                "Please fix the errors before saving",
                backgroundColor: Colors.red,
                colorText: Colors.white,
                snackPosition: SnackPosition.BOTTOM,
              );
            }
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
                ShadInput(
                  controller: contactNumberController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  onChanged: (value) {
                    setState(() {
                      validateContactNumber(value);
                    });
                  },
                ),
                if (contactNumberError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      contactNumberError!,
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
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
                ShadInput(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (value) {
                    setState(() {
                      validateEmail(value);
                    });
                  },
                ),
                if (emailError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      emailError!,
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
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
                            _showOtpDialog();
                          } else {
                            // If 2FA is turned off, show OTP dialog and verify OTP before disabling 2FA
                            _showOtpDialog(isForDisabling2FA: true);
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
                        // Open change password first, then OTP will be sent
                        _showChangePasswordDialog();
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

    void validatePassword(String password, void Function(void Function()) setState) {
      hasNumber = password.contains(RegExp(r'[0-9]'));
      hasLetter = password.contains(RegExp(r'[a-zA-Z]'));
      hasSymbol = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
      hasUpperAndLower = password.contains(RegExp(r'[a-z]')) && password.contains(RegExp(r'[A-Z]'));
      setState(() {});
    }

    showShadDialog(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(30.0),
        child: StatefulBuilder(
          builder: (context, setState) {
            return ShadDialog(
              title: const Text('Change Password', style: TextStyle(color: Colors.white)),
              actions: [
                ShadButton(
                  backgroundColor: const Color(0xFF104038),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                  onPressed: () => Navigator.pop(context),
                ),
                ShadButton(
                  backgroundColor: const Color(0xFF104038),
                  child: const Text('Save', style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    if (currentPasswordController.text.isEmpty ||
                        newPasswordController.text.isEmpty ||
                        confirmPasswordController.text.isEmpty) {
                      Get.snackbar('Error', 'All fields are required!', backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
                      return;
                    }
                    if (newPasswordController.text != confirmPasswordController.text) {
                      Get.snackbar('Error', 'New password and confirm password must match.', backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
                      return;
                    }
                    if (newPasswordController.text.length < 8 || newPasswordController.text.length > 20) {
                      Get.snackbar('Error', 'Password must be 8â€“20 characters long.', backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
                      return;
                    }
                    if (!hasNumber || !hasLetter || !hasSymbol || !hasUpperAndLower) {
                      Get.snackbar('Error', 'Password must include: number, letter, symbol, uppercase & lowercase.', backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
                      return;
                    }
                    Navigator.pop(context);
                    _showOtpDialogForPasswordChange(currentPasswordController.text, newPasswordController.text);
                  },
                ),
              ],
              child: Container(
                width: 300,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShadInput(
                      controller: currentPasswordController,
                      placeholder: const Text('Current Password'),
                      obscureText: obscureCurrent,
                      leading: const Padding(padding: EdgeInsets.all(4.0), child: Icon(Icons.lock)),
                      trailing: IconButton(
                        icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => obscureCurrent = !obscureCurrent),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ShadInput(
                      controller: newPasswordController,
                      placeholder: const Text('New Password'),
                      obscureText: obscureNew,
                      leading: const Padding(padding: EdgeInsets.all(4.0), child: Icon(Icons.lock_outline)),
                      trailing: IconButton(
                        icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => obscureNew = !obscureNew),
                      ),
                      onChanged: (val) => validatePassword(val, setState),
                    ),
                    const SizedBox(height: 12),
                    ShadInput(
                      controller: confirmPasswordController,
                      placeholder: const Text('Confirm New Password'),
                      obscureText: obscureConfirm,
                      leading: const Padding(padding: EdgeInsets.all(4.0), child: Icon(Icons.lock_outline)),
                      trailing: IconButton(
                        icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => obscureConfirm = !obscureConfirm),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    // Live password policy checklist
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildValidationItem('At least 8 characters', newPasswordController.text.length >= 8),
                          _buildValidationItem('Max 20 characters', newPasswordController.text.isNotEmpty && newPasswordController.text.length <= 20),
                          _buildValidationItem('At least one number', hasNumber),
                          _buildValidationItem('At least one letter', hasLetter),
                          _buildValidationItem('At least one symbol', hasSymbol),
                          _buildValidationItem('Uppercase and lowercase letters', hasUpperAndLower),
                          _buildValidationItem('Matches confirm password', newPasswordController.text.isNotEmpty && newPasswordController.text == confirmPasswordController.text),
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

  // Toggle 2FA: enable
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
          setState(() => authenticationStatus = 1);
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
      Get.snackbar(
        "Error",
        "An error occurred while enabling 2FA: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Toggle 2FA: disable
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
          setState(() => authenticationStatus = 0);
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
      Get.snackbar(
        "Error",
        "An error occurred while disabling 2FA: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
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

  // OTP Dialog for 2FA: Step 1 (email) -> Step 2 (OTP)
  void _showOtpDialog({bool isForDisabling2FA = false}) {
    final emailStepController = TextEditingController(text: emailController.text);
    final otpController = TextEditingController();
    String generatedOtp = '';
    int resendCooldown = 0; // seconds (resend cooldown)
    int expireSeconds = 0; // seconds (code expiry)
    bool isOtpSent = false;
    int step = 1; // 1 = email, 2 = otp
    bool dialogAlive = true; // guard for async timers

    String maskedEmail(String email) {
      final parts = email.split('@');
      if (parts.length != 2) return email;
      final name = parts[0];
      final domain = parts[1];
      final maskedName = name.length <= 2 ? '*' * name.length : name.substring(0, 2) + '*' * (name.length - 2);
      return '$maskedName@$domain';
    }

    String generateOtp() {
      final r = Random();
      return (r.nextInt(900000) + 100000).toString();
    }

    Future<void> sendOtp(String email, String otp) async {
      try {
        final url = Uri.parse("${SessionStorage.url}transaction.php");
        final jsonData = {
          "emailToSent": email,
          "emailSubject": "Verification Code",
          "emailBody": "Your verification code is: <b>$otp</b>",
        };
        final body = { "operation": "sendEmail", "json": jsonEncode(jsonData) };
        await http.post(url, body: body);
      } catch (_) {}
    }

    void open2FADialog() {
      showShadDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(30.0),
              child: ShadDialog(
                title: Text(
                  step == 1 ? 'Two-Factor Authentication' : 'Enter Verification Code',
                  style: const TextStyle(color: Colors.white),
                ),
                actions: [
                  ShadButton(
                    backgroundColor: const Color(0xFF104038),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      dialogAlive = false;
                      Navigator.pop(context);
                    },
                  ),
                  if (step == 1)
                    ShadButton(
                      backgroundColor: const Color(0xFF104038),
                      child: const Text('Send Code', style: TextStyle(color: Colors.white)),
                      onPressed: () async {
                        final email = emailStepController.text.trim();
                        if (email.isEmpty) {
                          Get.snackbar("Error", "Please enter your email",
                              backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
                          return;
                        }
                        generatedOtp = generateOtp();
                        await sendOtp(email, generatedOtp);
                        setState(() {
                          isOtpSent = true;
                          step = 2;
                          resendCooldown = 30;
                          expireSeconds = 300; // 5 minutes expiry
                        });
                        // Start cooldown timer
                        Future.doWhile(() async {
                          await Future.delayed(const Duration(seconds: 1));
                          if (!dialogAlive || resendCooldown <= 0) return false;
                          setState(() => resendCooldown -= 1);
                          return resendCooldown > 0;
                        });
                        // Start expiry timer
                        Future.doWhile(() async {
                          await Future.delayed(const Duration(seconds: 1));
                          if (!dialogAlive || expireSeconds <= 0) return false;
                          if (context.mounted) setState(() => expireSeconds -= 1);
                          return expireSeconds > 0;
                        });
                      },
                    ),
                  if (step == 2)
                    ShadButton(
                      backgroundColor: const Color(0xFF104038),
                      child: const Text('Verify', style: TextStyle(color: Colors.white)),
                      onPressed: () {
                        if (!isOtpSent) {
                          Get.snackbar("Error", "Please request a code first",
                              backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
                          return;
                        }
                        if (otpController.text.trim().isEmpty) {
                          Get.snackbar("Error", "Please enter the code",
                              backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
                          return;
                        }
                        if (expireSeconds <= 0) {
                          Get.snackbar("Error", "Code expired. Please resend a new code.",
                              backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
                          return;
                        }
                        if (otpController.text.trim() == generatedOtp) {
                          dialogAlive = false;
                          Navigator.pop(context);
                          if (isForDisabling2FA) {
                            disable2FA();
                          } else {
                            enable2fa();
                          }
                        } else {
                          Get.snackbar("Error", "Incorrect code. Try again.",
                              backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
                        }
                      },
                    ),
                ],
                child: Container(
                  width: 360,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (step == 1) ...[
                        const Text(
                          'Enter your email to receive a verification code',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        ShadInput(
                          controller: emailStepController,
                          placeholder: const Text('your@email.com'),
                        ),
                        const SizedBox(height: 8),
                        const Text('We will send a 6-digit code to your email.',
                            style: TextStyle(color: Colors.white54, fontSize: 12)),
                      ] else ...[
                        // Header icon
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: const Icon(Icons.shield_outlined, color: Color(0xFF104038)),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Enter Verification Code',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF104038),
                          ),
                        ),
                        const SizedBox(height: 6),
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(color: Colors.white),
                            children: [
                              const TextSpan(text: "We've sent a 6-digit code to\n"),
                              TextSpan(
                                text: emailStepController.text,
                                style: const TextStyle(
                                  color: Color(0xFF86EFAC), // light green on dark bg
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Code expires in: ${Duration(seconds: expireSeconds).toString().substring(2,7)}',
                          style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 14),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Verification Code', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF86EFAC), width: 2),
                          ),
                          child: ShadInput(
                            controller: otpController,
                            placeholder: const Text('Enter 6-digit code'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text('Enter the 6-digit code sent to your email',
                            style: TextStyle(color: Colors.black45, fontSize: 12)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Didn't receive the code? ",
                                style: TextStyle(color: Colors.black54, fontSize: 12)),
                            if (resendCooldown > 0)
                              Text('Resend in ${resendCooldown}s',
                                  style: const TextStyle(color: Colors.black45, fontSize: 12))
                            else
                              TextButton(
                                onPressed: () async {
                                  generatedOtp = generateOtp();
                                  await sendOtp(emailStepController.text.trim(), generatedOtp);
                                  setState(() {
                                    resendCooldown = 30;
                                    expireSeconds = 300; // reset expiry
                                  });
                                  Future.doWhile(() async {
                                    await Future.delayed(const Duration(seconds: 1));
                                    if (!dialogAlive || resendCooldown <= 0) return false;
                                    setState(() => resendCooldown -= 1);
                                    return resendCooldown > 0;
                                  });
                                  Future.doWhile(() async {
                                    await Future.delayed(const Duration(seconds: 1));
                                    if (!dialogAlive || expireSeconds <= 0) return false;
                                    if (context.mounted) setState(() => expireSeconds -= 1);
                                    return expireSeconds > 0;
                                  });
                                },
                                child: const Text('Resend Code', style: TextStyle(color: Color(0xFF0F9D58), fontWeight: FontWeight.w700)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () {
                              setState(() { step = 1; });
                            },
                            child: const Text('â† Back', style: TextStyle(color: Colors.white70)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    open2FADialog();
  }

  void _showOtpDialogForPasswordChange(String currentPassword, String newPassword) {
    final emailStepController = TextEditingController(text: emailController.text);
    final otpController = TextEditingController();
    String generatedOtp = '';
    int resendCooldown = 0; // seconds (resend cooldown)
    int expireSeconds = 0; // seconds (code expiry countdown)
    bool isOtpSent = false;
    int step = 1; // 1=email, 2=otp
    bool dialogAlive = true; // guard for async timers

    String generateOtp() {
      final rand = Random();
      return (rand.nextInt(900000) + 100000).toString(); // 6-digit OTP
    }

    Future<void> sendOtpEmail(String email, String otp) async {
      try {
        var url = Uri.parse("${SessionStorage.url}transaction.php");
        Map<String, dynamic> jsonData = {
          "emailToSent": email,
          "emailSubject": "Password Change Verification Code",
          "emailBody": "Your verification code is: <b>$otp</b>",
        };
        Map<String, String> requestBody = {
          "operation": "sendEmail",
          "json": jsonEncode(jsonData),
        };
        var response = await http.post(url, body: requestBody);
        if (response.statusCode == 200) {
          final res = jsonDecode(response.body);
          if (res is Map && res['success'] == true) {
            Get.snackbar(
              "OTP Sent",
              "A verification code was sent to ${emailController.text}",
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
        Get.snackbar(
          "Error",
          "An error occurred while sending OTP: $e",
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
        child: StatefulBuilder(
          builder: (context, setState) {
            return ShadDialog(
              title: Text(step == 1 ? 'Verify Email' : 'Verify Code', style: const TextStyle(color: Colors.white)),
              actions: [
                if (step == 1) ...[
                  ShadButton(
                    backgroundColor: const Color(0xFF104038),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      dialogAlive = false;
                      Navigator.pop(context);
                    },
                  ),
                  ShadButton(
                    backgroundColor: const Color(0xFF104038),
                    child: const Text('Send Code', style: TextStyle(color: Colors.white)),
                    onPressed: () async {
                      final email = emailStepController.text.trim();
                      if (email.isEmpty) {
                        Get.snackbar('Error', 'Please enter your email', backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
                        return;
                      }
                      generatedOtp = generateOtp();
                      await sendOtpEmail(email, generatedOtp);
                      setState(() {
                        isOtpSent = true;
                        step = 2;
                        resendCooldown = 30;
                        expireSeconds = 300; // 5 minutes
                      });
                      Future.doWhile(() async {
                        await Future.delayed(const Duration(seconds: 1));
                        if (!dialogAlive || resendCooldown <= 0) return false;
                        setState(() => resendCooldown -= 1);
                        return resendCooldown > 0;
                      });
                      // start expiry timer
                      Future.doWhile(() async {
                        await Future.delayed(const Duration(seconds: 1));
                        if (!dialogAlive || expireSeconds <= 0) return false;
                        if (context.mounted) {
                          setState(() => expireSeconds -= 1);
                        }
                        return expireSeconds > 0;
                      });
                    },
                  ),
                ] else ...[
                  ShadButton(
                    backgroundColor: const Color(0xFF104038),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      dialogAlive = false;
                      Navigator.pop(context);
                    },
                  ),
                  ShadButton(
                    backgroundColor: const Color(0xFF1F2937), // dark navy for Verify
                    child: const Text('Verify', style: TextStyle(color: Colors.white)),
                    onPressed: () async {
                      if (!isOtpSent) {
                        Get.snackbar('Error', 'Please send the code first', backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
                        return;
                      }
                      if (otpController.text.trim().isEmpty) {
                        Get.snackbar('Error', 'Please enter the code', backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
                        return;
                      }
                      if (expireSeconds <= 0) {
                        Get.snackbar('Error', 'Code expired. Please resend a new code.', backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
                        return;
                      }
                      if (otpController.text.trim() != generatedOtp) {
                        Get.snackbar('Error', 'Incorrect code. Try again.', backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
                        return;
                      }
                      try {
                        var url = Uri.parse("${SessionStorage.url}transaction.php");
                        Map<String, dynamic> jsonData = {
                          "username": widget.student_id,
                          "stud_id": widget.student_id,
                          "stud_currentPassword": currentPassword,
                          "stud_password": newPassword,
                        };
                        Map<String, String> requestBody = {
                          "operation": "verifyAndUpdatePassword",
                          "json": jsonEncode(jsonData),
                        };
                        var response = await http.post(url, body: requestBody);
                        if (response.statusCode == 200) {
                          var res = jsonDecode(response.body);
                          if (res == 1) {
                            Get.snackbar('Success', 'Password updated successfully.', backgroundColor: Colors.green, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
                            _logActivity(
                              userId: widget.student_id,
                              userTypeId: 1,
                              action: 'UPDATE',
                              module: 'scholars',
                              operation: 'updatePassword',
                              details: {"message": "Password changed"},
                            );
                            dialogAlive = false;
                            Navigator.pop(context);
                          } else if (res == 2) {
                            Get.snackbar('Notice', 'Password already updated before.', backgroundColor: Colors.orange, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
                          } else {
                            Get.snackbar('Error', 'Failed to update password.', backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
                          }
                        } else {
                          Get.snackbar('Error', 'Server error: ${response.statusCode}', backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
                        }
                      } catch (e) {
                        Get.snackbar('Error', 'An error occurred: $e', backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
                      }
                    },
                  ),
                ],
              ],
              child: Container(
                width: 360,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (step == 1) ...[
                      ShadInput(
                        controller: emailStepController,
                        placeholder: const Text('your@email.com'),
                      ),
                    ] else ...[
                      // Header icon
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: const Icon(Icons.shield_outlined, color: Color(0xFF104038)),
                      ),
                      const SizedBox(height: 12),
                      // Title
                      const Text(
                        'Enter Verification Code',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF104038),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Sent to email
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: const TextStyle(color: Colors.black87),
                          children: [
                            const TextSpan(text: "We've sent a 6-digit code to\n"),
                            TextSpan(
                              text: emailStepController.text,
                              style: const TextStyle(
                                color: Color(0xFF0F9D58),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Expiry timer
                      Text(
                        'Code expires in: ${Duration(seconds: expireSeconds).toString().substring(2,7)}',
                        style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 14),
                      // Label
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Verification Code',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 6),
                      // OTP input (single field styled)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF0F9D58), width: 2),
                        ),
                        child: ShadInput(
                          controller: otpController,
                          placeholder: const Text('Enter 6-digit code'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Enter the 6-digit code sent to your email',
                          style: TextStyle(color: Colors.black45, fontSize: 12)),
                      const SizedBox(height: 8),
                      // Resend link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Didn't receive the code? ",
                              style: TextStyle(color: Colors.black54, fontSize: 12)),
                          if (resendCooldown > 0)
                            Text('Resend in ${resendCooldown}s',
                                style: const TextStyle(color: Colors.black45, fontSize: 12))
                          else
                            TextButton(
                              onPressed: () async {
                                generatedOtp = generateOtp();
                                await sendOtpEmail(emailStepController.text.trim(), generatedOtp);
                                setState(() {
                                  resendCooldown = 30;
                                  expireSeconds = 300; // reset expiry to 5 minutes on resend
                                });
                                Future.doWhile(() async {
                                  await Future.delayed(const Duration(seconds: 1));
                                  if (!dialogAlive || resendCooldown <= 0) return false;
                                  setState(() => resendCooldown -= 1);
                                  return resendCooldown > 0;
                                });
                                // restart expiry timer
                                Future.doWhile(() async {
                                  await Future.delayed(const Duration(seconds: 1));
                                  if (!dialogAlive || expireSeconds <= 0) return false;
                                  if (context.mounted) {
                                    setState(() => expireSeconds -= 1);
                                  }
                                  return expireSeconds > 0;
                                });
                              },
                              child: const Text('Resend',
                                  style: TextStyle(color: Color(0xFF0F9D58), fontWeight: FontWeight.w700))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Back link
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () {
                            // back to email step (do not close dialog)
                            setState(() {
                              step = 1;
                            });
                          },
                          child: const Text('â† Back', style: TextStyle(color: Colors.black54)),
                        ),
                      ),
                    ],
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

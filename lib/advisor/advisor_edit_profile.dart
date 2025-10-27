import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:csdl_mobile/session_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:http/http.dart' as http;

class AdvisorEditProfileSheet extends StatefulWidget {
  const AdvisorEditProfileSheet({
    Key? key,
    required this.side,
    required this.advisor_id,
  }) : super(key: key);

  final String advisor_id;
  final ShadSheetSide side;

  @override
  _AdvisorEditProfileSheetState createState() =>
      _AdvisorEditProfileSheetState();
}

class _AdvisorEditProfileSheetState extends State<AdvisorEditProfileSheet> {
  int remainingTime = 5; // 5 minutes in seconds
  String email = '';
  String fullName = '';
  int authenticationStatus = 0;
  String currentPassword = '';
  String supervisorId = '';
  bool isButtonDisabled = false;
  bool isTwoFactorEnabled = false; // Track the state of the switch
  List<dynamic> assignments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getSupervisorProfile();
    getSupervisorAssignments();
  }

  @override
  void dispose() {
    super.dispose(); // Always cancel the timer when the widget is disposed
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return ShadSheet(
      constraints: widget.side == ShadSheetSide.left ||
              widget.side == ShadSheetSide.right
          ? const BoxConstraints(maxWidth: 500) // Increased for more content
          : null,
      title: const Text('Supervisor Profile'),
      description: const Text(
          "View your complete profile information and current assignments."),
      actions: [
        ShadButton(
          child: const Text('Close'),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ],
      child: isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                  // Profile Information Section
                  _buildInfoSection(
                    "Profile Information",
                    Icons.person,
                    [
                      _buildInfoRow("Full Name", fullName.isNotEmpty ? fullName : 'Not available'),
                      _buildInfoRow("Email Address", email.isNotEmpty ? email : 'Not available'),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Current Assignments Section
                  _buildInfoSection(
                    "Current Assignments",
                    Icons.assignment,
                    assignments.isEmpty
                        ? [
                            _buildInfoRow("Status", "No current assignments", isHighlight: true),
                          ]
                        : assignments.map((assignment) => _buildAssignmentInfo(assignment)).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Security Settings Section
                  _buildInfoSection(
                    "Security Settings",
                    Icons.security,
                    [
                      _buildInfoRow("Two-Factor Authentication", 
                          authenticationStatus == 1 ? "Enabled" : "Disabled", 
                          isHighlight: authenticationStatus == 1),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ShadButton(
                          child: const Text('Change Password'),
                          onPressed: () {
                            _showChangePasswordDialog();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ShadButton(
                          child: Text(authenticationStatus == 1 ? 'Disable 2FA' : 'Enable 2FA'),
                          onPressed: () {
                            _showOtpDialogForTwoFactor(enable: authenticationStatus != 1);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoSection(String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
              child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
                children: [
              Icon(icon, size: 20, color: Colors.grey.shade700),
              const SizedBox(width: 8),
                  Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
                children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
                    child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: isHighlight ? Colors.green.shade700 : Colors.black87,
                fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
                  ),
                ],
              ),
    );
  }

  Widget _buildAssignmentInfo(Map<String, dynamic> assignment) {
    String assignmentType = assignment['assignment_name']?.toString() ?? 'Unknown';
    bool isOffice = assignmentType == 'Office';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOffice ? Colors.blue.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isOffice ? Colors.blue.shade200 : Colors.green.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isOffice ? Icons.business : Icons.school,
                color: isOffice ? Colors.blue.shade700 : Colors.green.shade700,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                assignmentType,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isOffice ? Colors.blue.shade700 : Colors.green.shade700,
              ),
            ),
          ],
        ),
          const SizedBox(height: 6),
          if (isOffice) ...[
            _buildInfoRow('Department', assignment['dept_name']?.toString() ?? 'N/A'),
            _buildInfoRow('Building', assignment['build_name']?.toString() ?? 'N/A'),
          ] else ...[
            _buildInfoRow('Subject', assignment['sub_code']?.toString() ?? 'N/A'),
            _buildInfoRow('Title', assignment['sub_descriptive_title']?.toString() ?? 'N/A'),
            _buildInfoRow('Section', assignment['sub_section']?.toString() ?? 'N/A'),
            _buildInfoRow('Time', assignment['sub_time']?.toString() ?? 'N/A'),
            _buildInfoRow('Room', assignment['sub_room']?.toString() ?? 'N/A'),
          ],
        ],
      ),
    );
  }

  void getSupervisorProfile() async {
    try {
      var url = Uri.parse("${SessionStorage.url}transaction.php");
      Map<String, dynamic> jsonData = {
        "supM_email": widget.advisor_id,
      };
      Map<String, String> requestBody = {
        "operation": "getSupervisorProfile",
        "json": jsonEncode(jsonData),
      };

      var response = await http.post(url, body: requestBody);
      
      var res = jsonDecode(response.body);
      
      if (res is Map && res['success'] == true && res['data'] != null) {
        var data = res['data'];
        if (mounted) {
          setState(() {
            // Basic profile information - only name and email
            fullName = data['supM_name']?.toString() ?? '';
            email = data['supM_email']?.toString() ?? '';
            supervisorId = data['supM_id']?.toString() ?? '';
            currentPassword = data['supM_password']?.toString() ?? ''; // Save current password
            
            // Security information
            authenticationStatus = data['supM_authentication_status'] is int ? data['supM_authentication_status'] : int.tryParse(data['supM_authentication_status']?.toString() ?? '0') ?? 0;
            
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
    }
  }

  void getSupervisorAssignments() async {
    try {
      var url = Uri.parse("${SessionStorage.url}transaction.php");
      Map<String, dynamic> jsonData = {
        "supM_email": widget.advisor_id,
      };
      Map<String, String> requestBody = {
        "operation": "getAssignedScholars",
        "json": jsonEncode(jsonData),
      };

      var response = await http.post(url, body: requestBody);
      
      if (response.statusCode == 200) {
        var res = jsonDecode(response.body);
        
        if (mounted) {
          setState(() {
            if (res != 0) {
              
              // Remove duplicates based on unique combination of assignment details
              List<dynamic> uniqueAssignments = [];
              Set<String> seenAssignments = {};
              
              for (var assignment in res) {
                // Create a unique key based on assignment details
                String uniqueKey = "${assignment['assignment_name']}_${assignment['dept_name']}_${assignment['build_name']}_${assignment['dutyH_name']}";
                
                if (!seenAssignments.contains(uniqueKey)) {
                  seenAssignments.add(uniqueKey);
                  uniqueAssignments.add(assignment);
                } else {
                }
              }
              
              assignments = uniqueAssignments;
            } else {
              assignments = [];
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          assignments = [];
        });
      }
    }
  }


  void _showOtpDialog(
      {bool isForPasswordChange = false, bool isForDisabling2FA = false}) {
    final otpController = TextEditingController(); // OTP input controller
    String generatedOtp = ''; // Store generated OTP
    String emailToSendOtp = email; // Email for OTP
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
                ShadInput(
                  controller: otpController,
                  obscureText: false,
                  placeholder: Text(
                    "Enter OTP",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                if (!isOtpSent)
                  ShadButton(
                    child: const Text('Send OTP'),
                    onPressed: () {
                      generatedOtp = generateOtp(); // Generate OTP
                      sendOtp(emailToSendOtp, generatedOtp); // Send OTP
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
      hasSymbol = password.contains(RegExp(r'[!@#\$%\^&\*(),.?":{}|<>]'));
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
                ShadButton(
                  backgroundColor: const Color(0xFF104038),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                  onPressed: () => Navigator.pop(context),
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

  Widget _buildValidationItem(String text, bool isValid) {
    return Row(
      children: [
        Icon(isValid ? Icons.check_circle : Icons.cancel, size: 16, color: isValid ? Colors.green : Colors.red),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: isValid ? Colors.green : Colors.red, fontSize: 12)),
      ],
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
      "supM_id": supervisorId,
      "supM_currentPassword":
          currentPassword, // Send current password to verify
      "supM_password": newPassword, // New password for update
    };

    Map<String, String> requestBody = {
      "operation": "verfityAndUpdateAdvisorPassword",
      "json": jsonEncode(jsonData),
    };

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

  Future<void> enable2fa() async {
    try {
      var url = Uri.parse("${SessionStorage.url}transaction.php");

      Map<String, dynamic> jsonData = {
        "supM_id": supervisorId,
        "supM_authentication_status": 1,
      };

      Map<String, String> requestBody = {
        "operation": "updateTwoFactorAuthenticationAdvisor",
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
      Get.snackbar(
        "Error",
        "An error occurred while enabling 2FA.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> disable2FA() async {
    try {
      var url = Uri.parse("${SessionStorage.url}transaction.php");

      Map<String, dynamic> jsonData = {
        "supM_id": supervisorId,
        "supM_authentication_status": 0,
      };

      Map<String, String> requestBody = {
        "operation": "updateTwoFactorAuthenticationAdvisor",
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

  Future<void> sendOtpEmail(String email, String otp) async {
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

  void _showOtpDialogForPasswordChange(String currentPwd, String newPwd) {
    final otpController = TextEditingController();
    final emailController = TextEditingController(text: email);
    String generatedOtp = '';
    int resendCooldown = 0; // seconds
    int codeExpires = 0; // seconds
    Timer? tick;
    bool stepVerify = false; // false: enter email, true: verify

    void startTimers(void Function(void Function()) setState) {
      resendCooldown = 30; // 30s before resend
      codeExpires = 300; // 5 minutes
      tick?.cancel();
      tick = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() {
          if (resendCooldown > 0) resendCooldown--;
          if (codeExpires > 0) codeExpires--;
          if (codeExpires == 0 && stepVerify) {
            // auto-expire
          }
        });
      });
    }

    void sendCode(void Function(void Function()) setState) async {
      generatedOtp = _generateOtp();
      await sendOtpEmail(emailController.text.trim(), generatedOtp);
      setState(() => stepVerify = true);
      startTimers(setState);
    }

    showShadDialog(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(30.0),
        child: StatefulBuilder(
          builder: (context, setState) {
            return ShadDialog(
              title: Text(stepVerify ? 'Verify Code' : 'Verify Email', style: const TextStyle(color: Colors.white)),
              actions: [
                if (!stepVerify) ...[
                  ShadButton(
                    backgroundColor: const Color(0xFF104038),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      tick?.cancel();
                      Navigator.pop(context);
                    },
                  ),
                  // ShadButton(
                  //   backgroundColor: const Color(0xFF104038),
                  //   child: const Text('Send Code', style: TextStyle(color: Colors.white)),
                  //   onPressed: () => sendCode(setState),
                  // ),
                ] else ...[
                  ShadButton(
                    backgroundColor: const Color(0xFF104038),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      tick?.cancel();
                      Navigator.pop(context);
                    },
                  ),
                  ShadButton(
                    backgroundColor: const Color(0xFF1F2937),
                    child: const Text('Verify', style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      if (otpController.text.trim() == generatedOtp && codeExpires > 0) {
                        Navigator.pop(context);
                        tick?.cancel();
                        _updatePassword(currentPwd, newPwd);
                      } else {
                        Get.snackbar('Error', codeExpires == 0 ? 'Code expired. Resend and try again.' : 'Incorrect code. Please try again.', backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
                      }
                    },
                  ),
                ],
              ],
              child: Container(
                width: 320,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                child: stepVerify
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF104038)),
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
                                  text: emailController.text,
                                  style: const TextStyle(color: Color(0xFF0F9D58), fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Expiry timer
                          Text(
                            'Code expires in: ${Duration(seconds: codeExpires).toString().substring(2,7)}',
                            style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 14),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Verification Code', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Color(0xFF0F9D58), width: 2),
                            ),
                            child: ShadInput(
                              controller: otpController,
                              placeholder: const Text('Enter 6-digit code'),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text('Enter the 6-digit code sent to your email', style: TextStyle(color: Colors.black45, fontSize: 12)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Didn't receive the code? ", style: TextStyle(color: Colors.black54, fontSize: 12)),
                              if (resendCooldown > 0)
                                Text('Resend in ${resendCooldown}s', style: const TextStyle(color: Colors.black45, fontSize: 12))
                              else
                                TextButton(
                                  onPressed: () => sendCode(setState),
                                  child: const Text('Resend', style: TextStyle(color: Color(0xFF0F9D58), fontWeight: FontWeight.w700)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: () => setState(() => stepVerify = false),
                              child: const Text('â† Back', style: TextStyle(color: Colors.black54)),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ShadInput(
                            controller: emailController,
                            placeholder: const Text('Email'),
                            readOnly: true,
                          ),
                          const SizedBox(height: 12),
                          ShadButton(
                            backgroundColor: const Color(0xFF104038),
                            child: const Text('Send Code', style: TextStyle(color: Colors.white)),
                            onPressed: () => sendCode(setState),
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

  void _showOtpDialogForTwoFactor({required bool enable}) {
    final otpController = TextEditingController();
    final emailController = TextEditingController(text: email);
    String generatedOtp = '';
    int resendCooldown = 0;
    int codeExpires = 0;
    Timer? tick;
    bool stepVerify = false;

    void startTimers(void Function(void Function()) setState) {
      resendCooldown = 30;
      codeExpires = 300;
      tick?.cancel();
      tick = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() {
          if (resendCooldown > 0) resendCooldown--;
          if (codeExpires > 0) codeExpires--;
        });
      });
    }

    void sendCode(void Function(void Function()) setState) async {
      generatedOtp = _generateOtp();
      await sendOtpEmail(emailController.text.trim(), generatedOtp);
      setState(() => stepVerify = true);
      startTimers(setState);
    }

    showShadDialog(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(30.0),
        child: StatefulBuilder(
          builder: (context, setState) {
            return ShadDialog(
              title: Text(stepVerify ? 'Verify Code' : 'Verify Email', style: const TextStyle(color: Colors.white)),
              actions: [
                if (!stepVerify) ...[
                  ShadButton(
                    backgroundColor: const Color(0xFF104038),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      tick?.cancel();
                      Navigator.pop(context);
                    },
                  ),
                  // ShadButton(
                  //   backgroundColor: const Color(0xFF104038),
                  //   child: const Text('Send Code', style: TextStyle(color: Colors.white)),
                  //   onPressed: () => sendCode(setState),
                  // ),
                ] else ...[
                  ShadButton(
                    backgroundColor: const Color(0xFF104038),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      tick?.cancel();
                      Navigator.pop(context);
                    },
                  ),
                  ShadButton(
                    backgroundColor: const Color(0xFF1F2937),
                    child: const Text('Verify', style: TextStyle(color: Colors.white)),
                    onPressed: () async {
                      if (otpController.text.trim() == generatedOtp && codeExpires > 0) {
                        Navigator.pop(context);
                        tick?.cancel();
                        if (enable) {
                          await enable2fa();
                        } else {
                          await disable2FA();
                        }
                      } else {
                        Get.snackbar('Error', codeExpires == 0 ? 'Code expired. Resend and try again.' : 'Incorrect code. Please try again.', backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
                      }
                    },
                  ),
                ],
              ],
              child: Container(
                width: 320,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                child: stepVerify
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF104038)),
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
                                  text: emailController.text,
                                  style: const TextStyle(color: Color(0xFF0F9D58), fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Expiry timer
                          Text(
                            'Code expires in: ${Duration(seconds: codeExpires).toString().substring(2,7)}',
                            style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 14),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Verification Code', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Color(0xFF0F9D58), width: 2),
                            ),
                            child: ShadInput(
                              controller: otpController,
                              placeholder: const Text('Enter 6-digit code'),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text('Enter the 6-digit code sent to your email', style: TextStyle(color: Colors.black45, fontSize: 12)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Didn't receive the code? ", style: TextStyle(color: Colors.black54, fontSize: 12)),
                              if (resendCooldown > 0)
                                Text('Resend in ${resendCooldown}s', style: const TextStyle(color: Colors.black45, fontSize: 12))
                              else
                                TextButton(
                                  onPressed: () => sendCode(setState),
                                  child: const Text('Resend', style: TextStyle(color: Color(0xFF0F9D58), fontWeight: FontWeight.w700)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: () => setState(() => stepVerify = false),
                              child: const Text('â† Back', style: TextStyle(color: Colors.black54)),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ShadInput(
                            controller: emailController,
                            placeholder: const Text('Email'),
                            readOnly: true,
                          ),
                          const SizedBox(height: 12),
                          ShadButton(
                            backgroundColor: const Color(0xFF104038),
                            child: const Text('Send Code', style: TextStyle(color: Colors.white)),
                            onPressed: () => sendCode(setState),
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

  String _generateOtp() {
    final r = Random();
    return (r.nextInt(900000) + 100000).toString();
  }
}

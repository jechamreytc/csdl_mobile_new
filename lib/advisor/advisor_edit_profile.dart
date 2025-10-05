import 'dart:convert';
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
                            _showOtpDialog(isForPasswordChange: true);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ShadButton(
                          child: Text(authenticationStatus == 1 ? 'Disable 2FA' : 'Enable 2FA'),
                          onPressed: () {
                            if (authenticationStatus == 1) {
                              _showOtpDialog(isForPasswordChange: false, isForDisabling2FA: true);
                            } else {
                              _showOtpDialog(isForPasswordChange: false);
                            }
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
      print("API Response Status: ${response.statusCode}");
      print("API Response Body: ${response.body}");
      
      var res = jsonDecode(response.body);
      print("Parsed Response: $res");
      
      if (res is Map && res['success'] == true && res['data'] != null) {
        print("Success response with data, processing...");
        var data = res['data'];
        if (mounted) {
          setState(() {
            // Basic profile information - only name and email
            fullName = data['supM_name']?.toString() ?? '';
            email = data['supM_email']?.toString() ?? '';
            currentPassword = data['supM_password']?.toString() ?? ''; // Save current password
            
            // Security information
            authenticationStatus = data['supM_authentication_status'] is int ? data['supM_authentication_status'] : int.tryParse(data['supM_authentication_status']?.toString() ?? '0') ?? 0;
            
            isLoading = false;
          });
          print("Set state completed. Full Name: $fullName, Email: $email");
        }
      } else {
        print("No data found or error in response");
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error: $e");
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
      print("Assignments API Response Status: ${response.statusCode}");
      print("Assignments API Response Body: ${response.body}");
      
      if (response.statusCode == 200) {
        var res = jsonDecode(response.body);
        print("Raw assignments data: $res");
        
        if (mounted) {
          setState(() {
            if (res != 0) {
              print("Total assignments before deduplication: ${res.length}");
              
              // Remove duplicates based on unique combination of assignment details
              List<dynamic> uniqueAssignments = [];
              Set<String> seenAssignments = {};
              
              for (var assignment in res) {
                // Create a unique key based on assignment details
                String uniqueKey = "${assignment['assignment_name']}_${assignment['dept_name']}_${assignment['build_name']}_${assignment['dutyH_name']}";
                print("Assignment key: $uniqueKey");
                
                if (!seenAssignments.contains(uniqueKey)) {
                  seenAssignments.add(uniqueKey);
                  uniqueAssignments.add(assignment);
                } else {
                  print("Duplicate assignment found: $uniqueKey");
                }
              }
              
              print("Unique assignments after deduplication: ${uniqueAssignments.length}");
              assignments = uniqueAssignments;
            } else {
              assignments = [];
            }
          });
        }
      }
    } catch (e) {
      print("Error fetching supervisor assignments: $e");
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
      "supM_id": widget.advisor_id,
      "supM_currentPassword":
          currentPassword, // Send current password to verify
      "supM_password": newPassword, // New password for update
    };

    Map<String, String> requestBody = {
      "operation": "verifyAndUpdateAdvisorPassword", // Updated operation name
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
        "supM_id": widget.advisor_id,
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
        "supM_id": widget.advisor_id,
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

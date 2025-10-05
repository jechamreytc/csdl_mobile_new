import 'dart:convert';
import 'dart:math';
import 'package:csdl_mobile/session_storage.dart';
import 'package:csdl_mobile/marketing/marketing_drawer.dart';
import 'package:csdl_mobile/marketing/marketing_edit_profile.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';

class MarketingSettings extends StatefulWidget {
  final String adminEmail;

  const MarketingSettings({
    Key? key,
    required this.adminEmail,
  }) : super(key: key);

  @override
  _MarketingSettingsState createState() => _MarketingSettingsState();
}

class _MarketingSettingsState extends State<MarketingSettings> {
  String adminName = "";
  String adminEmail = "";
  String adminId = "";
  String contactNumber = '';
  String email = '';
  int authenticationStatus = 0;
  String currentPassword = '';
  bool isButtonDisabled = false;
  bool isTwoFactorEnabled = false;
  bool isLoading = true;
  
  // TextEditingControllers
  late TextEditingController contactNumberController;
  late TextEditingController emailController;

  @override
  void initState() {
    super.initState();
    contactNumberController = TextEditingController();
    emailController = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    contactNumberController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      isLoading = true;
    });

    try {
      var url = Uri.parse("${SessionStorage.url}transaction.php");
      var response = await http.post(url, body: {
        "operation": "getMarketingProfile",
        "json": jsonEncode({"admin_email": widget.adminEmail}),
      });

      if (response.statusCode == 200) {
        var res = jsonDecode(response.body);
        if (res['success'] == true) {
          var data = res['data'];
          setState(() {
            adminName = data['adm_name'] ?? '';
            adminEmail = data['adm_email'] ?? '';
            adminId = data['adm_id'].toString();
            // contactNumber = data['adm_contactNumber'] ?? 'N/A';
            email = data['adm_email'] ?? 'N/A';
            // contactNumberController.text = contactNumber;
            emailController.text = email;
            currentPassword = data['adm_password'] ?? '';
            authenticationStatus = data['adm_authentication_status'] ?? 0;
            isTwoFactorEnabled = authenticationStatus == 1;
          });
        }
      }
    } catch (e) {
      print("Error loading profile: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Image.asset(
            'assets/images/coc_logo.png',
            height: 50,
            width: 50,
          ),
        ),
      ),
      drawer: MarketingDrawer(adminEmail: widget.adminEmail, currentIndex: 2),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.green.shade200],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    
                    // Profile Card (Student Style)
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Color(0xFF104038),
                              child: Icon(Icons.person, size: 30, color: Colors.white),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    adminName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF104038),
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Email: $adminEmail",
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "ID: $adminId",
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Profile Information Card
                    Card(
                      color: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _buildProfileInfo("Name", adminName),
                            const SizedBox(height: 16),
                            _buildProfileInfo("Email", adminEmail),
                            const SizedBox(height: 16),
                            _buildProfileInfo("ID", adminId),
                            // const SizedBox(height: 16),
                            // _buildProfileInfo("Contact Number", contactNumber),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 2FA and Password Card (Student Style)
                    Card(
                      color: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    "Enable 2-Factor Authentication",
                                    style: TextStyle(
                                      color: Color(0xFF104038),
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                ShadSwitch(
                                  value: authenticationStatus == 1,
                                  onChanged: (bool v) {
                                    setState(() {
                                      authenticationStatus = v ? 1 : 0;
                                      isTwoFactorEnabled = v;
                                    });

                                    if (v) {
                                      _showOtpDialog(isForPasswordChange: false);
                                    } else {
                                      _showOtpDialog(isForPasswordChange: false, isForDisabling2FA: true);
                                    }
                                  },
                                  thumbColor: Color(0xFF104038),
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
                                child: const Text('Change Password', style: TextStyle(color: Colors.white)),
                                onPressed: () {
                                  _showOtpDialog(isForPasswordChange: true);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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

  // OTP Dialog
  void _showOtpDialog({required bool isForPasswordChange, bool isForDisabling2FA = false}) {
    final otpController = TextEditingController();
    String generatedOtp = _generateOtp();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isForPasswordChange ? "Change Password" : "2FA Verification"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Enter the OTP sent to your email: $email"),
            const SizedBox(height: 16),
            TextField(
              controller: otpController,
              decoration: InputDecoration(
                labelText: "OTP",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            Text("Generated OTP for testing: $generatedOtp", style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              if (otpController.text == generatedOtp) {
                Navigator.pop(context);
                if (isForPasswordChange) {
                  _showChangePasswordDialog();
                } else if (isForDisabling2FA) {
                  _disable2FA();
                } else {
                  _enable2FA();
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
            child: Text("Verify"),
          ),
        ],
      ),
    );
  }

  // Generate OTP
  String _generateOtp() {
    Random random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // Enable 2FA
  void _enable2FA() async {
    try {
      var url = Uri.parse("${SessionStorage.url}transaction.php");
      Map<String, dynamic> jsonData = {
        "admin_email": widget.adminEmail,
        "authentication_status": 1,
      };
      Map<String, String> requestBody = {
        "operation": "updateMarketing2FA",
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
          setState(() {
            authenticationStatus = 1;
            isTwoFactorEnabled = true;
          });
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

  // Disable 2FA
  void _disable2FA() async {
    try {
      var url = Uri.parse("${SessionStorage.url}transaction.php");
      Map<String, dynamic> jsonData = {
        "admin_email": widget.adminEmail,
        "authentication_status": 0,
      };
      Map<String, String> requestBody = {
        "operation": "updateMarketing2FA",
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
          setState(() {
            authenticationStatus = 0;
            isTwoFactorEnabled = false;
          });
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

  // Change Password Dialog
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

    void validatePassword(String password) {
      setState(() {
        hasNumber = password.contains(RegExp(r'[0-9]'));
        hasLetter = password.contains(RegExp(r'[a-zA-Z]'));
        hasSymbol = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
        hasUpperAndLower = password.contains(RegExp(r'[A-Z]')) && password.contains(RegExp(r'[a-z]'));
      });
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text("Change Password"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  decoration: InputDecoration(
                    labelText: "Current Password",
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(obscureCurrent ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => obscureCurrent = !obscureCurrent),
                    ),
                  ),
                  obscureText: obscureCurrent,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  decoration: InputDecoration(
                    labelText: "New Password",
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(obscureNew ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => obscureNew = !obscureNew),
                    ),
                  ),
                  obscureText: obscureNew,
                  onChanged: validatePassword,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: "Confirm New Password",
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(obscureConfirm ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => obscureConfirm = !obscureConfirm),
                    ),
                  ),
                  obscureText: obscureConfirm,
                ),
                const SizedBox(height: 16),
                // Password requirements
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Password Requirements:", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _buildRequirement("At least 8 characters", newPasswordController.text.length >= 8),
                      _buildRequirement("Contains a number", hasNumber),
                      _buildRequirement("Contains a letter", hasLetter),
                      _buildRequirement("Contains a symbol", hasSymbol),
                      _buildRequirement("Has uppercase and lowercase", hasUpperAndLower),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                if (currentPasswordController.text != currentPassword) {
                  Get.snackbar(
                    "Error",
                    "Current password is incorrect.",
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                    snackPosition: SnackPosition.BOTTOM,
                  );
                  return;
                }

                if (newPasswordController.text != confirmPasswordController.text) {
                  Get.snackbar(
                    "Error",
                    "New passwords do not match.",
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                    snackPosition: SnackPosition.BOTTOM,
                  );
                  return;
                }

                if (newPasswordController.text.length < 8 || !hasNumber || !hasLetter || !hasSymbol || !hasUpperAndLower) {
                  Get.snackbar(
                    "Error",
                    "Password does not meet requirements.",
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                    snackPosition: SnackPosition.BOTTOM,
                  );
                  return;
                }

                _updatePassword(newPasswordController.text);
                Navigator.pop(context);
              },
              child: Text("Change Password"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirement(String text, bool isValid) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check : Icons.close,
            size: 16,
            color: isValid ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: isValid ? Colors.green : Colors.red,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Update Password
  void _updatePassword(String newPassword) async {
    try {
      var url = Uri.parse("${SessionStorage.url}transaction.php");
      Map<String, dynamic> jsonData = {
        "admin_email": widget.adminEmail,
        "new_password": newPassword,
      };
      Map<String, String> requestBody = {
        "operation": "updateMarketingPassword",
        "json": jsonEncode(jsonData),
      };

      var response = await http.post(url, body: requestBody);

      if (response.statusCode == 200) {
        var res = jsonDecode(response.body);
        if (res != 0) {
          Get.snackbar(
            "Success",
            "Password updated successfully.",
            backgroundColor: Colors.green,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );
          setState(() {
            currentPassword = newPassword;
          });
        } else {
          Get.snackbar(
            "Error",
            "Failed to update password.",
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
        "An error occurred while updating password.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}

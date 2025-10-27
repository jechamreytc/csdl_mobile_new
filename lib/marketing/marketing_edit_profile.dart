import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../session_storage.dart';

class MarketingEditProfile extends StatefulWidget {
  final String adminEmail;

  const MarketingEditProfile({Key? key, required this.adminEmail})
      : super(key: key);

  @override
  State<MarketingEditProfile> createState() => _MarketingEditProfileState();
}

class _MarketingEditProfileState extends State<MarketingEditProfile> {
  String name = '';
  String email = '';
  String adminId = '';
  bool isLoading = false;
  int authenticationStatus = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
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
            name = data['adm_name'] ?? '';
            email = data['adm_email'] ?? '';
            adminId = data['adm_id'].toString();
            final rawAuth = data['adm_authentication_status'];
            authenticationStatus = rawAuth is int
                ? rawAuth
                : int.tryParse((rawAuth ?? '0').toString()) ?? 0;
          });
        }
      }
    } catch (e) {
      // print("Error loading profile: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Marketing Profile"),
        backgroundColor: const Color(0xFF104038),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Admin ID: $adminId",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text("Name: $name",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text("Email: $email",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  Card(
                    color: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
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
                                  style: const TextStyle(
                                      color: Color(0xFF104038),
                                      fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              ShadSwitch(
                                value: authenticationStatus == 1,
                                onChanged: (bool v) {
                                  setState(() {
                                    authenticationStatus = v ? 1 : 0;
                                  });
                                  _showOtpDialogForTwoFactor(enable: v);
                                },
                                thumbColor: const Color(0xFF104038),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ShadButton(
                              backgroundColor: const Color(0xFF104038),
                              child: const Text('Change Password',
                                  style: TextStyle(color: Colors.white)),
                              onPressed: _showChangePasswordDialog,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _sendOtpEmail(String to, String otp) async {
    try {
      final url = Uri.parse("${SessionStorage.url}transaction.php");
      final jsonData = {
        "emailToSent": to,
        "emailSubject": "Verification Code",
        "emailBody": "Your verification code is: <b>$otp</b>",
      };
      await http.post(url, body: {"operation": "sendEmail", "json": jsonEncode(jsonData)});
    } catch (_) {}
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
      hasSymbol = password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
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
                    if (currentPasswordController.text.isEmpty || newPasswordController.text.isEmpty || confirmPasswordController.text.isEmpty) {
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
                    _showOtpDialogForPasswordChange(newPasswordController.text);
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

  Widget _buildValidationItem(String label, bool valid) {
    return Row(
      children: [
        Icon(valid ? Icons.check_circle : Icons.close, color: valid ? Colors.green : Colors.red, size: 16),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: valid ? Colors.black87 : Colors.red, fontSize: 12)),
      ],
    );
  }

  void _showOtpDialogForPasswordChange(String newPwd) {
    final otpController = TextEditingController();
    String generatedOtp = '';
    int resendCooldown = 0;
    int expireSeconds = 0;
    bool isOtpSent = false;
    int step = 1;
    bool dialogAlive = true;

    String generateOtp() {
      final r = Random();
      return (r.nextInt(900000) + 100000).toString();
    }

    showShadDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: const EdgeInsets.all(30.0),
            child: ShadDialog(
              title: Text(step == 1 ? 'Verify Email' : 'Enter Verification Code', style: const TextStyle(color: Colors.white)),
              actions: [
                ShadButton(
                  backgroundColor: const Color(0xFF104038),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                  onPressed: () { dialogAlive = false; Navigator.pop(context); },
                ),
                if (step == 1)
                  ShadButton(
                    backgroundColor: const Color(0xFF104038),
                    child: const Text('Send Code', style: TextStyle(color: Colors.white)),
                    onPressed: () async {
                      final to = email.trim();
                      if (to.isEmpty) {
                        Get.snackbar('Error', 'Email is required', backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
                        return;
                      }
                      generatedOtp = generateOtp();
                      await _sendOtpEmail(to, generatedOtp);
                      setState(() {
                        isOtpSent = true;
                        step = 2;
                        resendCooldown = 30;
                        expireSeconds = 300;
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
                        setState(() => expireSeconds -= 1);
                        return expireSeconds > 0;
                      });
                    },
                  ),
                if (step == 2)
                  ShadButton(
                    backgroundColor: const Color(0xFF104038),
                    child: const Text('Verify', style: TextStyle(color: Colors.white)),
                    onPressed: () async {
                      if (!isOtpSent) { Get.snackbar('Error', 'Please request a code first', backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM); return; }
                      if (otpController.text.trim().isEmpty) { Get.snackbar('Error', 'Please enter the code', backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM); return; }
                      if (expireSeconds <= 0) { Get.snackbar('Error', 'Code expired. Please resend a new code.', backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM); return; }
                      if (otpController.text.trim() != generatedOtp) { Get.snackbar('Error', 'Incorrect code. Try again.', backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM); return; }
                      try {
                        final url = Uri.parse("${SessionStorage.url}transaction.php");
                        final jsonData = { "admin_email": email, "new_password": newPwd };
                        final body = { "operation": "updateMarketingPassword", "json": jsonEncode(jsonData) };
                        final resp = await http.post(url, body: body);
                        if (resp.statusCode == 200) {
                          final res = jsonDecode(resp.body);
                          if (res == 1) {
                            Get.snackbar('Success', 'Password updated successfully.', backgroundColor: Colors.green, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
                            Navigator.pop(context);
                          } else {
                            Get.snackbar('Error', 'Failed to update password.', backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
                          }
                        } else {
                          Get.snackbar('Error', 'Server error: ${resp.statusCode}', backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
                        }
                      } catch (e) {
                        Get.snackbar('Error', 'An error occurred: $e', backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
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
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Text(email, style: const TextStyle(color: Colors.black87)),
                      ),
                    ] else ...[
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle, border: Border.all(color: Colors.green.shade200)),
                        child: const Icon(Icons.shield_outlined, color: Color(0xFF104038)),
                      ),
                      const SizedBox(height: 12),
                      const Text('Enter Verification Code', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF104038))),
                      const SizedBox(height: 6),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(style: const TextStyle(color: Colors.black87), children: [
                          const TextSpan(text: "We've sent a 6-digit code to\n"),
                          TextSpan(text: email, style: const TextStyle(color: Color(0xFF0F9D58), fontWeight: FontWeight.w700)),
                        ]),
                      ),
                      const SizedBox(height: 4),
                      Text('Code expires in: ${Duration(seconds: expireSeconds).toString().substring(2,7)}', style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 14),
                      const Align(alignment: Alignment.centerLeft, child: Text('Verification Code', style: TextStyle(fontWeight: FontWeight.w600))),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF0F9D58), width: 2)),
                        child: ShadInput(controller: otpController, placeholder: const Text('Enter 6-digit code'), keyboardType: TextInputType.number),
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
                              onPressed: () async {
                                generatedOtp = generateOtp();
                                await _sendOtpEmail(email.trim(), generatedOtp);
                                setState(() { resendCooldown = 30; expireSeconds = 300; });
                              },
                              child: const Text('Resend', style: TextStyle(color: Color(0xFF0F9D58), fontWeight: FontWeight.w700)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(onPressed: () { setState(() { step = 1; }); }, child: const Text('â† Back', style: TextStyle(color: Colors.black54))),
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

  void _showOtpDialogForTwoFactor({required bool enable}) {
    final otpController = TextEditingController();
    String generatedOtp = '';
    int resendCooldown = 0;
    int expireSeconds = 0;
    bool isOtpSent = false;
    int step = 1;
    bool dialogAlive = true;

    String generateOtp() {
      final r = Random();
      return (r.nextInt(900000) + 100000).toString();
    }

    showShadDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: const EdgeInsets.all(30.0),
            child: ShadDialog(
              title: Text(step == 1 ? 'Two-Factor Authentication' : 'Enter Verification Code', style: const TextStyle(color: Colors.white)),
              actions: [
                ShadButton(
                  backgroundColor: const Color(0xFF104038),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                  onPressed: () { dialogAlive = false; Navigator.pop(context); },
                ),
                if (step == 1)
                  ShadButton(
                    backgroundColor: const Color(0xFF104038),
                    child: const Text('Send Code', style: TextStyle(color: Colors.white)),
                    onPressed: () async {
                      final to = email.trim();
                      if (to.isEmpty) {
                        Get.snackbar('Error', 'Email is required', backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
                        return;
                      }
                      generatedOtp = generateOtp();
                      await _sendOtpEmail(to, generatedOtp);
                      setState(() {
                        isOtpSent = true;
                        step = 2;
                        resendCooldown = 30;
                        expireSeconds = 300;
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
                        setState(() => expireSeconds -= 1);
                        return expireSeconds > 0;
                      });
                    },
                  ),
                if (step == 2)
                  ShadButton(
                    backgroundColor: const Color(0xFF104038),
                    child: const Text('Verify', style: TextStyle(color: Colors.white)),
                    onPressed: () async {
                      if (!isOtpSent) { Get.snackbar('Error', 'Please request a code first', backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM); return; }
                      if (otpController.text.trim().isEmpty) { Get.snackbar('Error', 'Please enter the code', backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM); return; }
                      if (expireSeconds <= 0) { Get.snackbar('Error', 'Code expired. Please resend a new code.', backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM); return; }
                      if (otpController.text.trim() != generatedOtp) { Get.snackbar('Error', 'Incorrect code. Try again.', backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM); return; }
                      try {
                        final url = Uri.parse("${SessionStorage.url}transaction.php");
                        final jsonData = { "admin_email": email, "authentication_status": enable ? 1 : 0 };
                        final body = { "operation": "updateMarketing2FA", "json": jsonEncode(jsonData) };
                        final resp = await http.post(url, body: body);
                        if (resp.statusCode == 200) {
                          final res = jsonDecode(resp.body);
                          if (res == 1) {
                            Get.snackbar('Success', enable ? 'Two-Factor Authentication enabled.' : 'Two-Factor Authentication disabled.', backgroundColor: Colors.green, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
                            Navigator.pop(context);
                          } else {
                            Get.snackbar('Error', 'Failed to update Two-Factor Authentication.', backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
                          }
                        } else {
                          Get.snackbar('Error', 'Server error: ${resp.statusCode}', backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
                        }
                      } catch (e) {
                        Get.snackbar('Error', 'An error occurred: $e', backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
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
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Text(email, style: const TextStyle(color: Colors.black87)),
                      ),
                    ] else ...[
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle, border: Border.all(color: Colors.green.shade200)),
                        child: const Icon(Icons.shield_outlined, color: Color(0xFF104038)),
                      ),
                      const SizedBox(height: 12),
                      const Text('Enter Verification Code', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF104038))),
                      const SizedBox(height: 6),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(style: const TextStyle(color: Colors.black87), children: [
                          const TextSpan(text: "We've sent a 6-digit code to\n"),
                          TextSpan(text: email, style: const TextStyle(color: Color(0xFF0F9D58), fontWeight: FontWeight.w700)),
                        ]),
                      ),
                      const SizedBox(height: 4),
                      Text('Code expires in: ${Duration(seconds: expireSeconds).toString().substring(2,7)}', style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 14),
                      const Align(alignment: Alignment.centerLeft, child: Text('Verification Code', style: TextStyle(fontWeight: FontWeight.w600))),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF0F9D58), width: 2)),
                        child: ShadInput(controller: otpController, placeholder: const Text('Enter 6-digit code'), keyboardType: TextInputType.number),
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
                              onPressed: () async {
                                generatedOtp = generateOtp();
                                await _sendOtpEmail(email.trim(), generatedOtp);
                                setState(() { resendCooldown = 30; expireSeconds = 300; });
                              },
                              child: const Text('Resend', style: TextStyle(color: Color(0xFF0F9D58), fontWeight: FontWeight.w700)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(onPressed: () { setState(() { step = 1; }); }, child: const Text('â† Back', style: TextStyle(color: Colors.black54))),
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
}

import 'dart:convert';

import 'package:csdl_mobile/fresh_student/fresh_student_drawer.dart';
import 'package:csdl_mobile/session_storage.dart';
import 'package:csdl_mobile/student/student_drawer.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:csdl_mobile/fresh_student/fresh_student_announcement.dart';
// import 'package:qr_bar_code/qr/src/qr_code.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb

class FreshStudent extends StatefulWidget {
  final String student_id;
  const FreshStudent({
    Key? key,
    required this.student_id,
  }) : super(key: key);

  @override
  _FreshStudentState createState() => _FreshStudentState();
}

class _FreshStudentState extends State<FreshStudent> {
  GlobalKey globalKey = GlobalKey();
  late String studentIdNumber;
  int totalReferrals = 0;
  int approvedReferrals = 0;
  int referralGoal = 5;
  String freshStudentName = '';
  String statusText = '';
  Map<String, dynamic>? certificate;
  String programAndYear = '';
  String scholarshipName = '';
  String sessionName = '';

  Color getProgressColor(int count) {
    if (count >= referralGoal) return const Color(0xFF104038);
    if (count >= 4) return Colors.teal;
    if (count >= 3) return Colors.blue;
    if (count >= 2) return Colors.orange;
    return Colors.red;
  }

  // int remainingHours = 0;
  // int renderedHours = 0;
  // int totalDutyHours = 1;
  // double percent = 0.0;
// Prevent division by zero
  bool isLoading = true;

  Color warningColor = Colors.transparent;
  String warningText = "";

  @override
  void initState() {
    super.initState();
    getTotalReferrals();
    getApprovedReferralsCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50), // Set the height of the AppBar
        child: AppBar(
          backgroundColor:
              Colors.transparent, // Make the AppBar background transparent
          elevation: 0, // Remove the shadow of the AppBar
          flexibleSpace: Image.asset(
            'assets/images/coc_logo.png', // Path to your background image
            height: 50,
            width: 50, // Ensure the image covers the entire area
          ),
        ),
      ),
      drawer: FreshStudentDrawer(
        student_id: widget.student_id,
        currentIndex: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.green.shade200],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ListView(
              children: [
                const SizedBox(height: 10),
                const Text(
                  "DASHBOARD",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF104038),
                    fontSize: 40,
                  ),
                ),
                const SizedBox(height: 20),

                // Profile row
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
                          child:
                              Icon(Icons.person, size: 30, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                freshStudentName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF104038),
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "ID: ${widget.student_id}",
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (warningText.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 4, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: warningColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: warningColor, width: 1),
                                  ),
                                  child: Text(
                                    warningText,
                                    style: TextStyle(
                                      color: warningColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Status (if any) for renewal, else Referral Progress
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statusText.isNotEmpty ? "Status" : "Referral Progress",
                          style: const TextStyle(
                            color: Color(0xFF104038),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (statusText.isNotEmpty) ...[
                          Text(statusText,
                              style: const TextStyle(
                                  color: Color(0xFF104038),
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          if (certificate != null)
                            ElevatedButton.icon(
                              onPressed: () => _showCertificateDialog(context),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF104038)),
                              icon: const Icon(Icons.verified, color: Colors.white),
                              label: const Text("View Certificate",
                                  style: TextStyle(color: Colors.white)),
                            ),
                        ] else
                          LinearPercentIndicator(
                          lineHeight: 20.0,
                          percent:
                              (approvedReferrals / referralGoal).clamp(0.0, 1.0),
                          center: Text(
                            approvedReferrals >= referralGoal
                                ? "Completed"
                                : "$approvedReferrals / $referralGoal",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          animation: true,
                          animateFromLastPercent: true,
                          animationDuration: 2500,
                          progressColor: getProgressColor(approvedReferrals),
                          backgroundColor: Colors.grey.shade300,
                          barRadius: const Radius.circular(10),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "Approved Leads: $approvedReferrals",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "Total Referrals: $totalReferrals",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // View full details button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF104038),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AnnouncementsPage(student_id: widget.student_id),
                      ),
                    );
                  },
                  child: const Text("View Announcements",
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void getTotalReferrals() async {
    try {
      var url = Uri.parse("${SessionStorage.url}transaction.php");
      Map<String, dynamic> jsonData = {
        "stud_active_id": widget.student_id,
      };
      Map<String, String> requestBody = {
        // Reuse getStudentRemainingHours to also fetch renewal status
        "operation": "getStudentRemainingHours",
        "json": jsonEncode(jsonData),
      };

      var response = await http.post(url, body: requestBody);
      var res = jsonDecode(response.body);

      if (response.statusCode == 200 && res is Map<String, dynamic>) {
        setState(() {
          // Keep original referral fields when available; else default to 0
          totalReferrals = int.tryParse(res["total_referrals"]?.toString() ?? "0") ?? 0;
          freshStudentName = res["StudentFullname"] ?? freshStudentName;
          statusText = (res['status_text'] ?? '').toString();
          certificate = res['certificate'];
          programAndYear = (res['program_and_year'] ?? '').toString();
          scholarshipName = (res['scholarship_name'] ?? '').toString();
          sessionName = (res['session_name'] ?? '').toString();
        });
      }

      print("Total Referrals: $res");
    } catch (e) {
      print("Error fetching total referrals: $e");
    }
  }

  void _showCertificateDialog(BuildContext context) {
    final approvedBy = (certificate?['approved_by_name'] ?? '').toString();
    final approvedOn = (certificate?['approved_on'] ?? '').toString();
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          width: 520,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Renewal Certificate',
                style: TextStyle(
                  color: Color(0xFF1E6F50),
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'HK RENEWAL APPROVED',
                style: TextStyle(
                  color: Color(0xFF1E6F50),
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      freshStudentName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    if (programAndYear.isNotEmpty)
                      Text(programAndYear, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.5),
                    children: [
                      const TextSpan(text: 'We are pleased to inform you that your application for renewal of your Hawak-Kamay Scholarship - '),
                      TextSpan(text: scholarshipName.isNotEmpty ? scholarshipName : 'HK10', style: const TextStyle(fontWeight: FontWeight.w700)),
                      const TextSpan(text: ', has been successfully verified and approved for the '),
                      TextSpan(text: sessionName.isNotEmpty ? sessionName : '', style: const TextStyle(fontWeight: FontWeight.w700)),
                      const TextSpan(text: ' of School Year.'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Congratulations on your continued dedication and hard work!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF1E6F50),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Approved on: $approvedOn', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    Text('Approved by: $approvedBy', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void getApprovedReferralsCount() async {
    try {
      var url = Uri.parse("${SessionStorage.url}transaction.php");
      Map<String, dynamic> jsonData = {
        "stud_active_id": widget.student_id,
      };
      Map<String, String> requestBody = {
        "operation": "getApprovedReferralsCount",
        "json": jsonEncode(jsonData),
      };

      var response = await http.post(url, body: requestBody);
      var res = jsonDecode(response.body);

      if (response.statusCode == 200 && res['success'] == true) {
        setState(() {
          approvedReferrals = res['approved_count'] ?? 0;
        });
      }
    } catch (e) {
      print("Error fetching approved referrals count: $e");
    }
  }
}

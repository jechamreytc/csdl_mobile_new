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
  int referralGoal = 5;
  String freshStudentName = '';

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

                // Progress bar
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
                          "Referral Progress",
                          style: const TextStyle(
                            color: Color(0xFF104038),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        LinearPercentIndicator(
                          lineHeight: 20.0,
                          percent:
                              (totalReferrals / referralGoal).clamp(0.0, 1.0),
                          center: Text(
                            totalReferrals >= referralGoal
                                ? "Completed"
                                : "$totalReferrals / $referralGoal",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          animation: true,
                          animateFromLastPercent: true,
                          animationDuration: 2500,
                          progressColor: getProgressColor(totalReferrals),
                          backgroundColor: Colors.grey.shade300,
                          barRadius: const Radius.circular(10),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            "Total Referrals: $totalReferrals",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
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
        "operation": "getTotalReferrals",
        "json": jsonEncode(jsonData),
      };

      var response = await http.post(url, body: requestBody);
      var res = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          totalReferrals = int.tryParse(res["total_referrals"].toString()) ?? 0;
          freshStudentName = res["FreshmenName"] ?? "";
        });
      }

      print("Total Referrals: $res");
    } catch (e) {
      print("Error fetching total referrals: $e");
    }
  }
}

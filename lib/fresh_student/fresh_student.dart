import 'dart:convert';

import 'package:csdl_mobile/fresh_student/fresh_student_drawer.dart';
import 'package:csdl_mobile/session_storage.dart';
import 'package:csdl_mobile/student/student_drawer.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      drawer: FreshStudentDrawer(
        student_id: widget.student_id,
      ),
      body: SafeArea(
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
              Row(
                children: [
                  // Profile image
                  // const CircleAvatar(
                  //   radius: 30,
                  //   backgroundImage:
                  //       AssetImage('assets/images/csdl_background.jpg'),
                  // ),
                  // const SizedBox(
                  //   width: 40,
                  // ),

                  // Name & ID with green pills
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(0xFF104038),
                        ),
                        child: Text(
                          "NAME : $freshStudentName",
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "ID:    ${widget.student_id}",
                        style: TextStyle(
                          color: Color(0xFF104038),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 5),
                      if (warningText.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 3, horizontal: 8),
                          decoration: BoxDecoration(
                            color: warningColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            warningText,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 30),

              // Progress bar
              LinearPercentIndicator(
                lineHeight: 20.0,
                percent: (totalReferrals / referralGoal).clamp(0.0, 1.0),
                center: Text(
                  totalReferrals >= referralGoal
                      ? "Completed"
                      : "$totalReferrals / $referralGoal",
                  style: const TextStyle(color: Colors.white),
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
                alignment: Alignment.centerLeft,
                child: Text(
                  "Total Referrals: $totalReferrals",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF104038),
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
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 4,
                ),
                onPressed: () {
                  // handle navigation
                },
                child: const Text("View the full Details",
                    style: TextStyle(color: Colors.white)),
              ),

              const SizedBox(height: 20),
            ],
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

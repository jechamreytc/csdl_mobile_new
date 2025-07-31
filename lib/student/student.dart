import 'dart:convert';
// import 'package:csdl_mobile/components/alert_dialog_dtr.dart';
// import 'package:csdl_mobile/components/app_bar.dart';
// import 'package:csdl_mobile/components/drawer_main.dart';
import 'package:csdl_mobile/session_storage.dart';
// import 'package:csdl_mobile/student/edit_profile_sheet.dart';
// import 'package:csdl_mobile/student/request_schedule(not%20included).dart';
// import 'package:csdl_mobile/student/student_account_settings(not%20included).dart';
import 'package:csdl_mobile/student/student_drawer.dart';
// import 'package:csdl_mobile/student/student_dtr.dart';
import 'package:flutter/material.dart';
// import 'package:hidden_drawer_menu/hidden_drawer_menu.dart';
// import 'package:qr_bar_code/qr/src/qr_code.dart';
// import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:http/http.dart' as http;

class Student extends StatefulWidget {
  final String student_id;
  const Student({
    super.key,
    required this.student_id,
  });

  @override
  _StudentState createState() => _StudentState();
}

class _StudentState extends State<Student> {
  String studentIdNumber = "";
  String studentFullName = "";

  String dutySubjectCode = "";
  String dutySubjectName = "";
  String dutySubjectSection = "";
  String dutyRoomNumber = "";
  String dutyBuildingNumber = "";
  String dutyAdvisorFullName = "";
  String dutyRemainingTime = "";
  String f2fDay = "";
  String rcDay = "";
  String f2fDayOffice = "";
  String dutyOfficeName = "";
  String dutyOfficeTime = "";
  String scheduledTime = "";
  String totalDutyHours = "";
  String remainingHours = "";
  String timeRendered = "";
  String learningModalities = "";
  bool isLoading = true;
  bool isScholarAssigned =
      false; // Track whether the scholar is assigned or not

  String dutyDay = '';

  @override
  void initState() {
    super.initState();
    getStudentsDetailsAndStudentDutyAssign();
    scholarAssignedChecker(); // Check if the scholar is assigned
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      drawer: StudentDrawer(student_id: widget.student_id),
      body: Stack(
        children: [
          // Image.asset(
          //   'assets/images/csdl_background.jpg',
          //   fit: BoxFit.cover,
          //   width: double.infinity,
          //   height: double.infinity,
          //   alignment: Alignment.topLeft,
          // ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromRGBO(
                      255, 255, 255, 0.85), // White with 50% transparency
                  Color.fromRGBO(
                      255, 255, 255, 0.85), // White with 50% transparency
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          const Column(
            children: [
              // Row(
              //   children: [
              //     Text(
              //       "Monitoring Sheet",
              //       style: TextStyle(
              //         color: Colors.green,
              //         fontSize: 27,
              //         height: 0.9,
              //       ),
              //     ),
              //   ],
              // ),
            ],
          ),
          Center(
            child: isLoading
                ? const CircularProgressIndicator()
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "DUTY ASSIGNMENT",
                            style: TextStyle(
                              fontSize: 35,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 35, 84, 37),
                            ),
                          ),
                          SizedBox(height: 40),
                          // Header and Student Information
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // const CircleAvatar(
                                  //   radius: 35,
                                  //   backgroundImage:
                                  //       AssetImage('assets/images/sakana.jpg'),
                                  // ),
                                  // const SizedBox(height: 15),
                                  // Text(
                                  //   'Advisor: $dutyAdvisorFullName',
                                  //   style: const TextStyle(
                                  //     fontSize: 12,
                                  //     color: Colors.white,
                                  //   ),
                                  // ),
                                ],
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Facilitator Name: $dutyAdvisorFullName",
                                      style: TextStyle(
                                        color: Colors.black,
                                      ),
                                    ),
                                    _infoBox("NAME: $studentFullName"),
                                    // Padding(
                                    //   padding: const EdgeInsets.only(
                                    //     left: 20,
                                    //   ),
                                    //   child: Text(
                                    //     "ID: $studentIdNumber",
                                    //     style: const TextStyle(
                                    //       color: Colors.black,
                                    //       fontSize: 12,
                                    //     ),
                                    //   ),
                                    // ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () async {
                                  final studentId =
                                      widget.student_id; // Replace with real ID
                                  final dtrData =
                                      await fetchStudentDtr(studentId);

                                  if (context.mounted) {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return Dialog(
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20)),
                                          backgroundColor: Colors.transparent,
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade800,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                const Center(
                                                  child: Text(
                                                    "Current DTR",
                                                    style: TextStyle(
                                                      fontSize: 20,
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                Container(
                                                  margin: const EdgeInsets
                                                      .symmetric(vertical: 6),
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                    boxShadow: const [
                                                      BoxShadow(
                                                          color: Colors.black26,
                                                          blurRadius: 3)
                                                    ],
                                                  ),
                                                  child: Text(
                                                    "Semester: ${dtrData.isNotEmpty ? dtrData[0]['session_name'] : 'N/A'}",
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                      color: Colors.green,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(10),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: SingleChildScrollView(
                                                    scrollDirection:
                                                        Axis.horizontal,
                                                    child: DataTable(
                                                      columnSpacing: 20,
                                                      headingRowHeight: 40,
                                                      headingRowColor:
                                                          WidgetStateProperty
                                                              .all(
                                                                  Colors.white),
                                                      columns: const [
                                                        DataColumn(
                                                          label: Text(
                                                            "Date",
                                                            style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                          ),
                                                        ),
                                                        DataColumn(
                                                          label: Text(
                                                            "Actions",
                                                            style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                          ),
                                                        ),
                                                      ],
                                                      rows: dtrData.map(
                                                        (data) {
                                                          return DataRow(
                                                            cells: [
                                                              DataCell(Text(
                                                                  data['record_date'] ??
                                                                      'N/A')),
                                                              DataCell(
                                                                IconButton(
                                                                  icon: Icon(
                                                                      Icons
                                                                          .remove_red_eye,
                                                                      color: Colors
                                                                          .grey
                                                                          .shade600),
                                                                  onPressed:
                                                                      () {
                                                                    showDialog(
                                                                      context:
                                                                          context,
                                                                      builder:
                                                                          (_) =>
                                                                              AlertDialog(
                                                                        backgroundColor: Colors
                                                                            .green
                                                                            .shade50, // light green background
                                                                        shape:
                                                                            RoundedRectangleBorder(
                                                                          borderRadius:
                                                                              BorderRadius.circular(12),
                                                                        ),
                                                                        title:
                                                                            Text(
                                                                          "Details for ${data['record_date']}",
                                                                          style:
                                                                              TextStyle(
                                                                            color:
                                                                                Colors.green.shade700,
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                            fontSize:
                                                                                20,
                                                                          ),
                                                                        ),
                                                                        content:
                                                                            Padding(
                                                                          padding: const EdgeInsets
                                                                              .symmetric(
                                                                              horizontal: 20,
                                                                              vertical: 8),
                                                                          child:
                                                                              Column(
                                                                            mainAxisSize:
                                                                                MainAxisSize.min,
                                                                            crossAxisAlignment:
                                                                                CrossAxisAlignment.start,
                                                                            children: [
                                                                              Text(
                                                                                "Time In: ${data['dtr_time_in'] ?? 'N/A'}",
                                                                                style: TextStyle(color: Colors.green.shade800, fontSize: 16),
                                                                              ),
                                                                              SizedBox(height: 8),
                                                                              Text(
                                                                                "Time Out: ${data['dtr_time_out'] ?? 'N/A'}",
                                                                                style: TextStyle(color: Colors.green.shade800, fontSize: 16),
                                                                              ),
                                                                              SizedBox(height: 8),
                                                                              Text(
                                                                                "Rendered Hours: ${data['TotalRendered'] ?? 'N/A'}",
                                                                                style: TextStyle(color: Colors.green.shade800, fontSize: 16),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                        actions: [
                                                                          TextButton(
                                                                            onPressed: () =>
                                                                                Navigator.pop(context),
                                                                            child:
                                                                                Text(
                                                                              "Close",
                                                                              style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    );
                                                                  },
                                                                ),
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      ).toList(),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                Align(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(context),
                                                    child: const Text(
                                                      "Close",
                                                      style: TextStyle(
                                                          color: Colors.white),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  }
                                },
                                icon: const Icon(
                                  Icons.assignment,
                                  color: Color.fromARGB(255, 35, 84, 37),
                                  size: 17,
                                ),
                                label: const Text(
                                  "View Data Sheets",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color.fromARGB(255, 35, 84, 37),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),

                          // First Info Row
                          // _infoBox(
                          //     "Learning Modalities: $learningModalities"),

                          _infoBox("Duty Day: $dutyDay"),

                          _infoBox("Assigned Hours: $totalDutyHours"),
                          _infoBox("Room: $dutyRoomNumber"),

                          // Second Info Row
                          _infoBox(scheduledTime.isNotEmpty
                              ? "Duty Time: $scheduledTime"
                              : "Office Time: $dutyOfficeTime"),
                          _infoBox(dutySubjectCode.isNotEmpty
                              ? "Subject Code: $dutySubjectCode"
                              : "Office: $dutyOfficeName"),
                          _infoBox(dutySubjectName.isNotEmpty
                              ? "Subject Name: $dutySubjectName"
                              : "Building: $dutyBuildingNumber"),
                          // _infoBox("Time Rendered: $timeRendered"),
                          // _infoBox("Time Remaining: $dutyRemainingTime"),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // Outside the class
  Widget buildStudentDtrDialogContent(
    List<dynamic> dtrData,
    Function(Map<String, dynamic>) onDetailTap,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text("Date")),
          DataColumn(label: Text("Actions")),
        ],
        rows: dtrData.map((data) {
          return DataRow(cells: [
            DataCell(Text(data['record_date'] ?? 'N/A')),
            DataCell(
              ElevatedButton(
                onPressed: () => onDetailTap(data),
                child: const Text("View Details"),
              ),
            ),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _infoBox(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: const BoxDecoration(
          color: Color(0xFF104038),
          // borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Future<List<dynamic>> fetchStudentDtr(String studentId) async {
    try {
      var url = Uri.parse("${SessionStorage.url}transaction.php");
      Map<String, dynamic> jsonData = {
        "stud_active_id": studentId,
      };
      Map<String, String> requestBody = {
        "operation": "getStudentDtr",
        "json": jsonEncode(jsonData),
      };

      var response = await http.post(url, body: requestBody);
      var res = jsonDecode(response.body);
      if (res != 0) {
        return res;
      }
    } catch (e) {
      print("Error fetching DTR: $e");
    }
    return [];
  }

  void getStudentsDetailsAndStudentDutyAssign() async {
    try {
      var url = Uri.parse("${SessionStorage.url}transaction.php");
      Map<String, dynamic> jsonData = {
        "stud_active_id": widget.student_id,
      };
      Map<String, String> requestBody = {
        "operation": "getStudentsDetailsAndStudentDutyAssign",
        "json": jsonEncode(jsonData),
      };

      var response = await http.post(url, body: requestBody);

      if (response.statusCode == 200) {
        var res = jsonDecode(response.body);

        if (res != 0) {
          setState(() {
            studentIdNumber = res['stud_active_id'] ?? "";
            studentFullName = res['StudentFullname'] ?? "";
            dutySubjectCode = res['sub_code'] ?? "";
            dutySubjectName = res['sub_descriptive_title'] ?? "";
            dutySubjectSection = res['sub_section'] ?? "";
            scheduledTime = res['sub_time'] ?? "";
            dutyRoomNumber = res['sub_room'] ?? "";
            f2fDay = res['F2F_Day'] ?? "";
            rcDay = res['RC_Day'] ?? "";
            f2fDayOffice = res['F2F_Day_Office'] ?? "";
            dutyBuildingNumber = res['build_name'] ?? "";
            dutyOfficeName = res['dept_name'] ?? "";
            dutyOfficeTime = res['offT_time'] ?? "";
            dutyAdvisorFullName = res['AdvisorFullname'] ?? "";
            totalDutyHours = res['TotalDutyHours']?.toString() ?? "";
            dutyRemainingTime = res['RemainingHours']?.toString() ?? "";
            timeRendered = res['TotalRenderedHours']?.toString() ?? "";
            learningModalities = res['learning_name'] ?? "";
            isLoading = false;

            dutyDay = (f2fDay).isNotEmpty
                ? f2fDay
                : (rcDay).isNotEmpty
                    ? rcDay
                    : (f2fDayOffice).isNotEmpty
                        ? f2fDayOffice
                        : "N/A";
          });
        } else {
          setState(() {
            isLoading = false;
          });
        }
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void scholarAssignedChecker() async {
    try {
      var url = Uri.parse("${SessionStorage.url}transaction.php");
      Map<String, dynamic> jsonData = {
        "stud_active_id": widget.student_id,
      };
      Map<String, String> requestBody = {
        "operation": "scholarAssignedChecker",
        "json": jsonEncode(jsonData),
      };
      var response = await http.post(url, body: requestBody);
      var res = jsonDecode(response.body);
      if (res["COUNT(*)"] != 0) {
        setState(() {
          isScholarAssigned = true;
        });
      } else {
        setState(() {
          isScholarAssigned = false;
        });
      }
    } catch (e) {
      print(e);
    }
  }
}

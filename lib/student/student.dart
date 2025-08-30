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
      drawer: StudentDrawer(student_id: widget.student_id),
      body: Stack(
        children: [
          // Soft light background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromRGBO(255, 255, 255, 0.85),
                  Color.fromRGBO(255, 255, 255, 0.85),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          Center(
            child: isLoading
                ? const CircularProgressIndicator()
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Page Title
                        SizedBox(height: 20),
                        const Text(
                          "DUTY ASSIGNMENT",
                          textAlign: TextAlign.justify,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: Color.fromARGB(255, 35, 84, 37),
                            letterSpacing: 0.5,
                          ),
                        ),
//                         const Text(
//                           "Your current assigned schedule and details.",
//                           textAlign: TextAlign.center,
//                           style: TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.w500,
//                             color: Colors.black54,
//                           ),
//                         ),

//                         const SizedBox(height: 8),

// // Section heading before container
//                         const Text(
//                           "Assignment Information",
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.black87,
//                           ),
//                         ),

//                         const SizedBox(height: 8),

// // Small helper text under section heading
//                         const Text(
//                           "Please review your details carefully.",
//                           style: TextStyle(
//                             fontSize: 13,
//                             fontWeight: FontWeight.w400,
//                             color: Colors.black54,
//                           ),
//                         ),
                        const SizedBox(height: 8),
                        // Centered white card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0xFF0F172A),
                                blurRadius: 12,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Header subtext (optional branding lines)
                              // Text(
                              //   "Facilitator Name: $dutyAdvisorFullName",
                              //   textAlign: TextAlign.center,
                              //   style: const TextStyle(
                              //     fontSize: 13,
                              //     color: Colors.black87,
                              //   ),
                              // ),
                              const SizedBox(height: 14),

                              // Green info area
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 16),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade900,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.green.shade900, width: 2),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Name
                                    _kvLine("NAME", studentFullName),

                                    const SizedBox(height: 6),
                                    _kvLine("Duty Day", dutyDay),
                                    const SizedBox(height: 6),
                                    _kvLine("Assigned Hours", totalDutyHours),
                                    const SizedBox(height: 6),
                                    _kvLine("Room", dutyRoomNumber),
                                    const SizedBox(height: 6),
                                    _kvLine(
                                      scheduledTime.isNotEmpty
                                          ? "Duty Time"
                                          : "Office Time",
                                      scheduledTime.isNotEmpty
                                          ? scheduledTime
                                          : dutyOfficeTime,
                                    ),

                                    _kvLine(
                                      dutySubjectCode.isNotEmpty
                                          ? "Subject Code"
                                          : "Office",
                                      dutySubjectCode.isNotEmpty
                                          ? dutySubjectCode
                                          : dutyOfficeName,
                                    ),

                                    _kvLine(
                                      dutySubjectName.isNotEmpty
                                          ? "Subject Name"
                                          : "Building",
                                      dutySubjectName.isNotEmpty
                                          ? dutySubjectName
                                          : dutyBuildingNumber,
                                    ),

                                    const SizedBox(height: 14),

                                    // View Data Sheets button INSIDE green card
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor:
                                              Colors.green.shade900,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        onPressed: () async {
                                          final studentId = widget.student_id;
                                          final dtrData =
                                              await fetchStudentDtr(studentId);

                                          if (context.mounted) {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return Dialog(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                  ),
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            16),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Colors.green.shade900,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                    ),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .stretch,
                                                      children: [
                                                        const Center(
                                                          child: Text(
                                                            "Current DTR",
                                                            style: TextStyle(
                                                              fontSize: 20,
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 10),
                                                        Container(
                                                          margin:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  vertical: 6),
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                            horizontal: 12,
                                                            vertical: 6,
                                                          ),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors.white,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        20),
                                                            boxShadow: const [
                                                              BoxShadow(
                                                                color: Colors
                                                                    .black26,
                                                                blurRadius: 3,
                                                              )
                                                            ],
                                                          ),
                                                          // child: Text(
                                                          //   "Semester: ${dtrData.isNotEmpty ? dtrData[0]['session_name'] : 'N/A'}",
                                                          //   textAlign: TextAlign
                                                          //       .center,
                                                          //   style:
                                                          //       const TextStyle(
                                                          //     color:
                                                          //         Colors.green,
                                                          //     fontWeight:
                                                          //         FontWeight
                                                          //             .bold,
                                                          //   ),
                                                          // ),
                                                        ),
                                                        const SizedBox(
                                                            height: 10),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(10),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors.white,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                          ),
                                                          child:
                                                              SingleChildScrollView(
                                                            scrollDirection:
                                                                Axis.horizontal,
                                                            child: DataTable(
                                                              columnSpacing: 20,
                                                              headingRowHeight:
                                                                  40,
                                                              headingRowColor:
                                                                  WidgetStateProperty
                                                                      .all(Colors
                                                                          .white),
                                                              columns: const [
                                                                DataColumn(
                                                                  label: Text(
                                                                    "Date",
                                                                    style: TextStyle(
                                                                        fontWeight:
                                                                            FontWeight.bold),
                                                                  ),
                                                                ),
                                                                DataColumn(
                                                                  label: Text(
                                                                    "Actions",
                                                                    style: TextStyle(
                                                                        fontWeight:
                                                                            FontWeight.bold),
                                                                  ),
                                                                ),
                                                              ],
                                                              rows: dtrData
                                                                  .map((data) {
                                                                return DataRow(
                                                                  cells: [
                                                                    DataCell(Text(
                                                                        data['record_date'] ??
                                                                            'N/A')),
                                                                    DataCell(
                                                                      IconButton(
                                                                        icon:
                                                                            Icon(
                                                                          Icons
                                                                              .remove_red_eye,
                                                                          color: Colors
                                                                              .grey
                                                                              .shade600,
                                                                        ),
                                                                        onPressed:
                                                                            () {
                                                                          showDialog(
                                                                            context:
                                                                                context,
                                                                            builder: (_) =>
                                                                                AlertDialog(
                                                                              backgroundColor: Colors.green.shade50,
                                                                              shape: RoundedRectangleBorder(
                                                                                borderRadius: BorderRadius.circular(12),
                                                                              ),
                                                                              title: Text(
                                                                                "Details for ${data['record_date']}",
                                                                                style: TextStyle(
                                                                                  color: Colors.green.shade700,
                                                                                  fontWeight: FontWeight.bold,
                                                                                  fontSize: 20,
                                                                                ),
                                                                              ),
                                                                              content: Padding(
                                                                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                                                                child: Column(
                                                                                  mainAxisSize: MainAxisSize.min,
                                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                                  children: [
                                                                                    Text(
                                                                                      "Time In: ${data['dtr_time_in'] ?? 'N/A'}",
                                                                                      style: TextStyle(color: Colors.green.shade800, fontSize: 16),
                                                                                    ),
                                                                                    const SizedBox(height: 8),
                                                                                    Text(
                                                                                      "Time Out: ${data['dtr_time_out'] ?? 'N/A'}",
                                                                                      style: TextStyle(color: Colors.green.shade800, fontSize: 16),
                                                                                    ),
                                                                                    const SizedBox(height: 8),
                                                                                    Text(
                                                                                      "Rendered Hours: ${data['TotalRendered'] ?? 'N/A'}",
                                                                                      style: TextStyle(color: Colors.green.shade800, fontSize: 16),
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                              actions: [
                                                                                TextButton(
                                                                                  onPressed: () => Navigator.pop(context),
                                                                                  child: Text(
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
                                                              }).toList(),
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 10),
                                                        Align(
                                                          alignment: Alignment
                                                              .centerRight,
                                                          child: TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                    context),
                                                            child: const Text(
                                                              "Close",
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .white),
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
                                        icon: const Icon(Icons.assignment,
                                            size: 18),
                                        label: const Text(
                                          "View Data Sheets",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Reminder Text outside the card, at the bottom
                        const SizedBox(height: 22),
                        const Text(
                          "Reminder:\n"
                          "● Be on time and follow your assigned schedule\n"
                          "● Wear your uniform and your student ID.\n"
                          "● Be respectful and courteous at all times.\n"
                          "● Complete tasks properly and ask if unsure.\n"
                          "● Inform your supervisor if you can’t report.\n"
                          "● Follow office rules and Guidelines.\n",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "If you do not follow your duty assignment schedule, we will not allow you to transfer or reschedule your duty.",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),

                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // Key-Value line inside the green card (white text)
  Widget _kvLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // (kept for compatibility if you still call it elsewhere)
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

  // Original _infoBox retained (unused in new design but kept intact)
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

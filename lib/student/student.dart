import 'dart:convert';
import 'package:csdl_mobile/components/alert_dialog_dtr.dart';
import 'package:csdl_mobile/components/app_bar.dart';
import 'package:csdl_mobile/components/drawer_main.dart';
import 'package:csdl_mobile/session_storage.dart';
import 'package:csdl_mobile/student/student_dtr.dart';
import 'package:flutter/material.dart';
import 'package:qr_bar_code/qr/src/qr_code.dart';
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

  @override
  void initState() {
    super.initState();
    getStudentsDetailsAndStudentDutyAssign();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarMain(
        title: '',
        backgroundColor: Color(0xFF006400), // Dark Green
      ),
      drawer: DrawerMain(
        headerColor: const Color(0xFF006400), // Dark Green
        headerTitle: 'Student',
        listTiles: [
          ListTile(
            leading: const Icon(
              Icons.assignment_outlined,
              color: Colors.white,
            ),
            title: const Text("Duty Assignment",
                style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudentDtr(
                    student_id: widget.student_id,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.file_copy,
              color: Colors.white,
            ),
            title: const Text("DTR", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StudentDtr(
                    student_id: "02-2425-23390",
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.logout,
              color: Colors.white,
            ),
            title: const Text("Logout", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFF006400), // Dark Green
        child: Center(
          child: isLoading
              ? const CircularProgressIndicator()
              : Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Column(
                          children: [
                            Row(
                              children: [
                                Text(
                                  "SCHOLARS \nDUTY",
                                  style: TextStyle(
                                    fontSize: 45,
                                    fontWeight: FontWeight.bold,
                                    height: 0.9,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  "Monitoring Sheet",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 27,
                                    height: 0.9,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        // Header and Student Information
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const CircleAvatar(
                                  radius: 35,
                                  backgroundImage:
                                      AssetImage('assets/images/sakana.jpg'),
                                ),
                                const SizedBox(height: 15),
                                Text(
                                  'Advisor: $dutyAdvisorFullName',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "NAME: $studentFullName",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    'ID: $studentIdNumber',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Duty Information - Side by Side Layout
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Learning Modalities: $learningModalities',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    f2fDay.isNotEmpty
                                        ? 'Duty Day: $f2fDay'
                                        : 'Duty Day: $rcDay',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Assigned Hours: $totalDutyHours',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Room: $dutyRoomNumber',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Duty Information - Side by Side Layout
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dutySubjectCode.isNotEmpty
                                        ? 'Subject Code: $dutySubjectCode'
                                        : 'Office: $dutyOfficeName',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    scheduledTime.isNotEmpty
                                        ? 'Duty Time: $scheduledTime'
                                        : 'Office Time: $dutyOfficeTime',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Time Rendered: $timeRendered',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    dutySubjectName.isNotEmpty
                                        ? 'Subject Name: $dutySubjectName'
                                        : 'Building: $dutyBuildingNumber',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Time Remaining: $dutyRemainingTime',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        // Centered QR Code Card
                        Center(
                          child: Card(
                            color: const Color.fromARGB(255, 242, 245, 242),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 5,
                            shadowColor: Colors.blueAccent,
                            child: Padding(
                              padding: const EdgeInsets.all(13),
                              child: SizedBox(
                                width: 150,
                                height: 150,
                                child: QRCode(
                                  data: studentIdNumber.isNotEmpty
                                      ? studentIdNumber
                                      : "No ID",
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        // Show DTR button
                        Center(
                          child: SizedBox(
                            height: 40,
                            width: 150,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 18, 165, 23),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return showAlertDialog(
                                      context,
                                      'DTR SHEETS',
                                      '',
                                      '',
                                      [],
                                    );
                                  },
                                );
                              },
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.assignment,
                                    color: Colors.white,
                                    size: 17,
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    "View Data Sheets",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
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
}

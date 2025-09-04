import 'dart:convert';

import 'package:csdl_mobile/session_storage.dart';
import 'package:csdl_mobile/student/student_drawer.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
// import 'package:qr_bar_code/qr/src/qr_code.dart';
import 'package:http/http.dart' as http;

//
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:csdl_mobile/student/student.dart';
import 'package:csdl_mobile/student/student_announcement.dart';
import 'dart:html' as html;

class StudentDashboard extends StatefulWidget {
  final String student_id;
  const StudentDashboard({super.key, required this.student_id});

  @override
  _StudentDashboardState createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  GlobalKey globalKey = GlobalKey();
  late String studentIdNumber;
  String studentFullName = "";

  double remainingHours = 0;
  double renderedHours = 0;
  double totalDutyHours = 1;
  double percent = 0.0;
// Prevent division by zero
  bool isLoading = true;

  Color warningColor = Colors.transparent;
  String warningText = "";

  @override
  void initState() {
    super.initState();
    studentIdNumber = widget.student_id;
    studentRemainingHoursChecker();
    getStudentComplaints();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: StudentDrawer(student_id: widget.student_id),
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
                const SizedBox(height: 20),
                // const Text(
                //   "DASHBOARD",
                //   textAlign: TextAlign.center,
                //   style: TextStyle(
                //     fontWeight: FontWeight.bold,
                //     color: Color(0xFF104038),
                //     fontSize: 32,
                //     letterSpacing: 1.5,
                //   ),
                // ),
                // const SizedBox(height: 20),

                // Profile Card
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
                                studentFullName,
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

                // Progress bar Card
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
                          "Duty Hours Progress",
                          style: TextStyle(
                            color: Color(0xFF104038),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        LinearPercentIndicator(
                          lineHeight: 22.0,
                          percent: percent.clamp(0.0, 1.0),
                          center: Text(
                            '${(percent * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          animation: true,
                          animateFromLastPercent: true,
                          animationDuration: 2500,
                          progressColor: const Color(0xFF104038),
                          backgroundColor: Colors.grey.shade300,
                          barRadius: const Radius.circular(12),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            "${renderedHours.toStringAsFixed(1)} / ${totalDutyHours.toStringAsFixed(1)} hours",
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

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

                const SizedBox(height: 30),

                // QR Code Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  color: Color(0xFF104038),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: RepaintBoundary(
                            key: globalKey,
                            child: QrImageView(
                              data: studentIdNumber.isNotEmpty
                                  ? studentIdNumber
                                  : "No ID",
                              version: QrVersions.auto,
                              size: 175.0,
                              backgroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                RenderRepaintBoundary boundary =
                                    globalKey.currentContext!.findRenderObject()
                                        as RenderRepaintBoundary;
                                ui.Image image =
                                    await boundary.toImage(pixelRatio: 3.0);
                                ByteData? byteData = await image.toByteData(
                                    format: ui.ImageByteFormat.png);
                                Uint8List pngBytes =
                                    byteData!.buffer.asUint8List();

                                if (kIsWeb) {
                                  // WEB: Download using anchor element
                                  final base64Data = base64Encode(pngBytes);
                                  final anchor = html.AnchorElement(
                                    href: 'data:image/png;base64,$base64Data',
                                  )
                                    ..download =
                                        'student_qr_${DateTime.now().millisecondsSinceEpoch}.png'
                                    ..target = 'blank';
                                  html.document.body!.append(anchor);
                                  anchor.click();
                                  anchor.remove();

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text("QR Code downloaded on web.")),
                                  );
                                } else {
                                  // MOBILE/APP: Request permission and save
                                  final status =
                                      await Permission.storage.request();
                                  if (status.isGranted) {
                                    final directory =
                                        await getExternalStorageDirectory();
                                    final path = directory!.path;
                                    final file = File(
                                        '$path/student_qr_${DateTime.now().millisecondsSinceEpoch}.png');
                                    await file.writeAsBytes(pngBytes);

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              "QR Code saved successfully!")),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              "Storage permission denied.")),
                                    );
                                  }
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text("Error saving QR: $e")),
                                );
                              }
                            },
                            icon:
                                const Icon(Icons.download, color: Colors.white),
                            label: const Text(
                              "Download QR Code",
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF104038),
                              side: const BorderSide(color: Color(0xFF104038)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void studentRemainingHoursChecker() async {
    try {
      var url = Uri.parse("${SessionStorage.url}transaction.php");
      Map<String, dynamic> jsonData = {
        "stud_active_id": widget.student_id,
      };
      Map<String, String> requestBody = {
        "operation": "getStudentRemainingHours",
        "json": jsonEncode(jsonData),
      };

      var response = await http.post(url, body: requestBody);
      var res = jsonDecode(response.body);

      print("API Response: $res");

      if (res != null && res is Map<String, dynamic>) {
        setState(() {
          // Removed: remainingHours (no longer returned by API)

          renderedHours =
              double.tryParse(res["TotalRenderedHours"].toString()) ?? 0;
          totalDutyHours =
              double.tryParse(res["TotalDutyHours"].toString()) ?? 1;

          // Compute percent progress
          percent = renderedHours / totalDutyHours;

          studentFullName = res['StudentFullname'] ?? "";
        });
      } else {
        print("Invalid response format: $res");
      }
    } catch (e) {
      print("Error fetching remaining hours: $e");
    }
  }

  void getStudentComplaints() async {
    try {
      var url = Uri.parse("${SessionStorage.url}transaction.php");
      Map<String, dynamic> jsonData = {
        "stud_active_id": widget.student_id,
      };
      Map<String, String> requestBody = {
        "operation": "getStudentComplaints",
        "json": jsonEncode(jsonData),
      };

      var response = await http.post(url, body: requestBody);
      var res = jsonDecode(response.body);

      int count = int.tryParse(res['complaint_count'].toString()) ?? 0;

      setState(() {
        if (count >= 2) {
          warningText = "Warning 2";
          warningColor = Colors.red;
        } else if (count == 1) {
          warningText = "Warning 1";
          warningColor = Colors.yellow;
        } else {
          warningText = "";
          warningColor = Colors.transparent;
        }
      });
    } catch (e) {
      print("Error fetching complaints: $e");
    }
  }
}

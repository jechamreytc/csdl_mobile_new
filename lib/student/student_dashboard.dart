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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
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
                          "NAME : $studentFullName",
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

                      // Container(
                      //   padding: const EdgeInsets.symmetric(
                      //       horizontal: 30, vertical: 4),
                      //   decoration: BoxDecoration(
                      //     color: Color(0xFF104038),
                      //   ),
                      //   child: const Text(
                      //     "ID:    02-2223-008904",
                      //     style: TextStyle(color: Colors.white, fontSize: 12),
                      //   ),
                      // ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 30),

              // Progress bar
              LinearPercentIndicator(
                lineHeight: 20.0,
                percent: percent.clamp(0.0, 1.0),
                center: Text(
                  '${(percent * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                animation: true,
                animateFromLastPercent: true,
                animationDuration: 2500,
                progressColor: const Color(0xFF104038),
                backgroundColor: Colors.grey.shade300,
                barRadius: const Radius.circular(10),
              ),

              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Duty Hours",
                  style: TextStyle(color: Colors.black54),
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

              const SizedBox(height: 30),

              // QR Code with RepaintBoundary
              Center(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: const Color(0xFF104038),
                  ),
                  child: Card(
                    color: const Color.fromARGB(255, 242, 245, 242),
                    elevation: 5,
                    shadowColor: Colors.blueAccent,
                    child: Padding(
                      padding: const EdgeInsets.all(13),
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
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Download Button
              Center(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      RenderRepaintBoundary boundary = globalKey.currentContext!
                          .findRenderObject() as RenderRepaintBoundary;
                      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
                      ByteData? byteData = await image.toByteData(
                          format: ui.ImageByteFormat.png);
                      Uint8List pngBytes = byteData!.buffer.asUint8List();

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
                              content: Text("QR Code downloaded on web.")),
                        );
                      } else {
                        // MOBILE/APP: Request permission and save
                        final status = await Permission.storage.request();
                        if (status.isGranted) {
                          final directory = await getExternalStorageDirectory();
                          final path = directory!.path;
                          final file = File(
                              '$path/student_qr_${DateTime.now().millisecondsSinceEpoch}.png');
                          await file.writeAsBytes(pngBytes);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("QR Code saved successfully!")),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Storage permission denied.")),
                          );
                        }
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error saving QR: $e")),
                      );
                    }
                  },
                  icon: const Icon(Icons.download, color: Colors.white),
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

              const SizedBox(height: 30),
            ],
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

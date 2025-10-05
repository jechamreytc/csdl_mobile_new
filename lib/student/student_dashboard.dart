import 'dart:convert';

import 'package:csdl_mobile/session_storage.dart';
import 'package:csdl_mobile/student/student_drawer.dart';
import 'package:csdl_mobile/components/sf_duty_status.dart';
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
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:open_filex/open_filex.dart';
import 'package:google_fonts/google_fonts.dart';

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
  String uiMode = "bar"; // 'bar' or 'text'
  String statusText = "";
  Map<String, dynamic>? certificate;
  String programAndYear = '';
  String scholarshipName = '';
  String sessionName = '';

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
      drawer: StudentDrawer(student_id: widget.student_id, currentIndex: 0),
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

                // Progress / Status Card
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
                          uiMode == "text" ? "Status" : "Duty Hours Progress",
                          style: TextStyle(
                            color: Color(0xFF104038),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (uiMode == "bar") ...[
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
                        ] else ...[
                          Text(
                            statusText.isNotEmpty ? statusText : "",
                            style: const TextStyle(
                              color: Color(0xFF104038),
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (certificate != null)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  _showCertificateDialog();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF104038),
                                ),
                                icon: const Icon(Icons.verified,
                                    color: Colors.white),
                                label: const Text(
                                  "View Certificate",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                        ],
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
          uiMode = (res['ui_mode'] ?? 'bar').toString();
          statusText = (res['status_text'] ?? '').toString();
          certificate = res['certificate'];
          programAndYear = (res['program_and_year'] ?? '').toString();
          scholarshipName = (res['scholarship_name'] ?? '').toString();
          sessionName = (res['session_name'] ?? '').toString();
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

  void _showCertificateDialog() {
    final cert = certificate ?? {};
    final approvedBy = (cert['approved_by_name'] ?? '').toString();
    final approvedOn = (cert['approved_on'] ?? '').toString();
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
                const SizedBox(height: 4),
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
                        studentFullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      if (programAndYear.isNotEmpty)
                        Text(
                          programAndYear,
                          style: const TextStyle(fontSize: 13),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Dear Mr./Ms. $studentFullName,',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                          color: Colors.black87, fontSize: 13, height: 1.5),
                      children: [
                        const TextSpan(
                            text:
                                'We are pleased to inform you that your application for renewal of your '),
                        TextSpan(
                            text: scholarshipName.isNotEmpty
                                ? scholarshipName
                                : 'HK10',
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        const TextSpan(
                            text:
                                ' Scholarship, has been successfully verified and approved for the '),
                        TextSpan(
                            text: sessionName.isNotEmpty ? sessionName : '',
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        // const TextSpan(text: ' of School Year.'),
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
                      Text('Approved on: $approvedOn',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black54)),
                      Text('Approved by: $approvedBy',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                ),
                 const SizedBox(height: 20),
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     ElevatedButton.icon(
                       onPressed: () async {
                         await _downloadCertificate();
                       },
                       style: ElevatedButton.styleFrom(
                         backgroundColor: const Color(0xFF1E6F50),
                         padding: const EdgeInsets.symmetric(
                           horizontal: 20,
                           vertical: 12,
                         ),
                         shape: RoundedRectangleBorder(
                           borderRadius: BorderRadius.circular(8),
                         ),
                       ),
                       icon: const Icon(
                         Icons.download,
                         color: Colors.white,
                         size: 18,
                       ),
                       label: const Text(
                         'Download Certificate',
                         style: TextStyle(
                           color: Colors.white,
                           fontWeight: FontWeight.w600,
                         ),
                       ),
                     ),
                     TextButton(
                       onPressed: () => Navigator.of(context).pop(),
                       child: const Text(
                         'Close',
                         style: TextStyle(
                           color: Color(0xFF1E6F50),
                           fontWeight: FontWeight.w600,
                         ),
                       ),
                     ),
                   ],
                 ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _downloadCertificate() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E6F50)),
          ),
        ),
      );

      // Create PDF document
      final PdfDocument document = PdfDocument();
      final PdfPage page = document.pages.add();
      final Size pageSize = page.getClientSize();

      // Get certificate data
      final cert = certificate ?? {};
      final approvedBy = (cert['approved_by_name'] ?? '').toString();
      final approvedOn = (cert['approved_on'] ?? '').toString();

      // Create graphics
      final PdfGraphics graphics = page.graphics;

      // Add background color
      graphics.drawRectangle(
        brush: PdfSolidBrush(PdfColor(240, 248, 255)),
        bounds: Rect.fromLTWH(0, 0, pageSize.width, pageSize.height),
      );

      // Add border
      graphics.drawRectangle(
        pen: PdfPen(PdfColor(30, 111, 80), width: 3),
        bounds: Rect.fromLTWH(20, 20, pageSize.width - 40, pageSize.height - 40),
      );

      // Title
      final PdfFont titleFont = PdfStandardFont(PdfFontFamily.helvetica, 28, style: PdfFontStyle.bold);
      final PdfStringFormat titleFormat = PdfStringFormat(alignment: PdfTextAlignment.center);
      graphics.drawString(
        'RENEWAL CERTIFICATE',
        titleFont,
        format: titleFormat,
        bounds: Rect.fromLTWH(0, 50, pageSize.width, 40),
        brush: PdfSolidBrush(PdfColor(30, 111, 80)),
      );

      // Subtitle
      final PdfFont subtitleFont = PdfStandardFont(PdfFontFamily.helvetica, 18, style: PdfFontStyle.bold);
      graphics.drawString(
        'HK RENEWAL APPROVED',
        subtitleFont,
        format: titleFormat,
        bounds: Rect.fromLTWH(0, 100, pageSize.width, 30),
        brush: PdfSolidBrush(PdfColor(30, 111, 80)),
      );

      // Student Information
      final PdfFont infoFont = PdfStandardFont(PdfFontFamily.helvetica, 14);
      graphics.drawString(
        'Student Information:',
        PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold),
        bounds: Rect.fromLTWH(50, 160, pageSize.width - 100, 20),
        brush: PdfSolidBrush(PdfColor(30, 111, 80)),
      );

      graphics.drawString(
        studentFullName,
        PdfStandardFont(PdfFontFamily.helvetica, 16, style: PdfFontStyle.bold),
        bounds: Rect.fromLTWH(50, 185, pageSize.width - 100, 20),
        brush: PdfSolidBrush(PdfColor(0, 0, 0)),
      );

      if (programAndYear.isNotEmpty) {
        graphics.drawString(
          programAndYear,
          infoFont,
          bounds: Rect.fromLTWH(50, 210, pageSize.width - 100, 20),
          brush: PdfSolidBrush(PdfColor(0, 0, 0)),
        );
      }

      // Greeting
      graphics.drawString(
        'Dear Mr./Ms. $studentFullName,',
        infoFont,
        bounds: Rect.fromLTWH(50, 250, pageSize.width - 100, 20),
        brush: PdfSolidBrush(PdfColor(0, 0, 0)),
      );

      // Main content
      final String mainContent = 'We are pleased to inform you that your application for renewal of your ${scholarshipName.isNotEmpty ? scholarshipName : 'HK10'} Scholarship, has been successfully verified and approved for the ${sessionName.isNotEmpty ? sessionName : ''}.';
      
      final PdfStringFormat contentFormat = PdfStringFormat(
        alignment: PdfTextAlignment.justify,
        lineSpacing: 10,
        wordWrap: PdfWordWrapType.word,
      );
      
      // Use a larger text area to prevent cutoff
      graphics.drawString(
        mainContent,
        infoFont,
        format: contentFormat,
        bounds: Rect.fromLTWH(50, 280, pageSize.width - 100, 150),
        brush: PdfSolidBrush(PdfColor(0, 0, 0)),
      );

      // Congratulations
      graphics.drawString(
        'Congratulations on your continued dedication and hard work!',
        PdfStandardFont(PdfFontFamily.helvetica, 16, style: PdfFontStyle.bold),
        format: PdfStringFormat(
          alignment: PdfTextAlignment.center,
          wordWrap: PdfWordWrapType.word,
        ),
        bounds: Rect.fromLTWH(50, 450, pageSize.width - 100, 50),
        brush: PdfSolidBrush(PdfColor(30, 111, 80)),
      );

      // Approval details
      graphics.drawString(
        'Approval Details:',
        PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold),
        bounds: Rect.fromLTWH(50, 520, pageSize.width - 100, 20),
        brush: PdfSolidBrush(PdfColor(30, 111, 80)),
      );

      graphics.drawString(
        'Approved on: $approvedOn',
        infoFont,
        bounds: Rect.fromLTWH(50, 545, pageSize.width - 100, 20),
        brush: PdfSolidBrush(PdfColor(0, 0, 0)),
      );

      graphics.drawString(
        'Approved by: $approvedBy',
        infoFont,
        bounds: Rect.fromLTWH(50, 570, pageSize.width - 100, 20),
        brush: PdfSolidBrush(PdfColor(0, 0, 0)),
      );

      // Add signature line using rectangle
      graphics.drawRectangle(
        pen: PdfPen(PdfColor(30, 111, 80), width: 1),
        bounds: Rect.fromLTWH(50, 610, pageSize.width - 100, 0),
      );

      graphics.drawString(
        'Authorized Signature',
        PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.italic),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
        bounds: Rect.fromLTWH(50, 620, pageSize.width - 100, 20),
        brush: PdfSolidBrush(PdfColor(30, 111, 80)),
      );

      // Save PDF
      final List<int> bytes = await document.save();
      document.dispose();

      // Close loading dialog
      Navigator.of(context).pop();

      if (kIsWeb) {
        // For web, download using blob
        final base64Data = base64Encode(bytes);
        final anchor = html.AnchorElement(
          href: 'data:application/pdf;base64,$base64Data',
        )
          ..download = 'HK_Renewal_Certificate_${studentFullName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf'
          ..target = 'blank';
        html.document.body!.append(anchor);
        anchor.click();
        anchor.remove();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Certificate downloaded successfully!"),
            backgroundColor: Color(0xFF1E6F50),
          ),
        );
      } else {
        // For mobile, save to device storage
        final status = await Permission.storage.request();
        if (status.isGranted) {
          final directory = await getExternalStorageDirectory();
          final path = directory!.path;
          final file = File('$path/HK_Renewal_Certificate_${studentFullName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf');
          await file.writeAsBytes(bytes);

          // Open the file
          await OpenFilex.open(file.path);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Certificate saved and opened successfully!"),
              backgroundColor: Color(0xFF1E6F50),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Storage permission denied."),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error generating certificate: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

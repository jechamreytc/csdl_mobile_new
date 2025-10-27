import 'dart:convert';
import 'package:csdl_mobile/session_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';

class AdvisorQrCode extends StatefulWidget {
  final String supM_id;

  const AdvisorQrCode({
    super.key,
    required this.supM_id,
  });

  @override
  State<AdvisorQrCode> createState() => _AdvisorQrCodeState();
}

class _AdvisorQrCodeState extends State<AdvisorQrCode> {
  List<Map<String, dynamic>> subjectList = [];

  @override
  void initState() {
    super.initState();
    fetchSupervisorSubjects();
  }

  Future<void> fetchSupervisorSubjects() async {
    try {
      var url = Uri.parse("${SessionStorage.url}transaction.php");

      Map<String, dynamic> jsonData = {
        "supM_id": widget.supM_id,
      };

      Map<String, String> requestBody = {
        "operation": "getSupervisorAssignedSubjects",
        "json": jsonEncode(jsonData),
      };

      var response = await http.post(url, body: requestBody);
      var res = jsonDecode(response.body);

      print(res);

      if (res != 0 && res is List) {
        setState(() {
          subjectList = List<Map<String, dynamic>>.from(res);
        });
      } else {
        print("No subjects or invalid response");
      }
    } catch (e) {
      print("Error fetching subjects: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Advisor QR Codes')),
      body: subjectList.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: subjectList.length,
              itemBuilder: (context, index) {
                final subject = subjectList[index];
                final qrData = jsonEncode({
                  "sub_code": subject['sub_code'],
                  "sub_section": subject['sub_section'],
                  "session_name": subject['session_name'],
                  "supM_id": widget.supM_id,
                });

                return Card(
                  margin: const EdgeInsets.all(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "${subject['sub_code']} - ${subject['sub_section']}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          size: 200.0,
                        ),
                        const SizedBox(height: 5),
                        Text("Session: ${subject['session_name']}"),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

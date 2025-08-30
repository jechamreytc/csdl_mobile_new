import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:csdl_mobile/session_storage.dart';
import 'package:csdl_mobile/student/student_drawer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class StudentJobType extends StatefulWidget {
  final String student_id;
  const StudentJobType({
    super.key,
    required this.student_id,
  });

  @override
  _StudentJobTypeState createState() => _StudentJobTypeState();
}

class _StudentJobTypeState extends State<StudentJobType> {
  bool isLoading = true;
  bool isUploading = false;
  String? selectedJobType;

  File? selectedFile;
  Uint8List? selectedFileBytes;
  String? selectedFileName;

  @override
  void initState() {
    super.initState();
    fetchReferrals();
  }

  /// FETCH REFERRALS
  Future<void> fetchReferrals() async {
    final url = Uri.parse("${SessionStorage.url}transaction.php");

    try {
      final response = await http.post(
        url,
        body: {'operation': 'getReferrals', 'json': '{}'},
      );

      print("Response Code: ${response.statusCode}");
      print("Raw Response: ${response.body}");

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        setState(() {
          isLoading = false;
        });
      } else {
        print("API returned error: ${data['error']}");
      }
    } catch (e, stackTrace) {
      print('❌ fetchReferrals Exception: $e');
      print('🧾 StackTrace:\n$stackTrace');
    }
  }

  /// FILE PICKER
  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image, // Make sure to select images
    );

    if (result != null) {
      setState(() {
        selectedFileName = result.files.single.name;
        if (kIsWeb) {
          selectedFileBytes = result.files.single.bytes;
        } else {
          selectedFile = File(result.files.single.path!);
        }
      });
    }
  }

  /// UPLOAD JOB TYPE
  Future<void> uploadJobType() async {
    if (selectedJobType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a job type")),
      );
      return;
    }

    if ((kIsWeb && selectedFileBytes == null) ||
        (!kIsWeb && selectedFile == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a file to upload")),
      );
      return;
    }

    setState(() => isUploading = true);

    try {
      var request = http.MultipartRequest(
        "POST",
        Uri.parse("${SessionStorage.url}transaction.php"),
      );

      request.fields['operation'] = "uploadJobType";
      request.fields['json'] = jsonEncode({
        "job_stud_id": widget.student_id,
        "job_name": selectedJobType,
      });

      if (kIsWeb) {
        request.files.add(http.MultipartFile.fromBytes(
          'job_image_file',
          selectedFileBytes!,
          filename: selectedFileName!,
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
          'job_image_file',
          selectedFile!.path,
        ));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("Response Code: ${response.statusCode}");
      print("Raw Response: ${response.body}");

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Uploaded successfully")),
        );
        setState(() {
          selectedFile = null;
          selectedFileBytes = null;
          selectedJobType = null;
          selectedFileName = null;
        });
      } else {
        print("API returned error: ${data['message']}");
      }
    } catch (e, stackTrace) {
      print('❌ uploadJobType Exception: $e');
      print('🧾 StackTrace:\n$stackTrace');
    }

    setState(() => isUploading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Job Type"),
        backgroundColor: Colors.green.shade700, // Green color for AppBar
      ),
      drawer: StudentDrawer(student_id: widget.student_id),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Note: This form is only available for **SBO** or **Working Student**.",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      "Select Job Type:",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Radio button options for job type selection
                    Card(
                      color: Colors.green.shade50, // Light green background
                      child: Column(
                        children: [
                          RadioListTile<String>(
                            title: const Text("SBO"),
                            value: "SBO",
                            groupValue: selectedJobType,
                            onChanged: (value) =>
                                setState(() => selectedJobType = value),
                          ),
                          RadioListTile<String>(
                            title: const Text("Working Student"),
                            value: "Working Student",
                            groupValue: selectedJobType,
                            onChanged: (value) =>
                                setState(() => selectedJobType = value),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // File picker
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: pickFile,
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(
                                Colors.green.shade700),
                            foregroundColor:
                                MaterialStateProperty.all(Colors.white),
                          ),
                          child: const Text("Select File"),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            selectedFileName ?? "No file selected",
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Show the "View Image" button only if the file is selected
                    if (selectedFile != null || selectedFileBytes != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              // Show the image in an AlertDialog when clicked
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text("Preview Image"),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      kIsWeb
                                          ? Image.memory(
                                              selectedFileBytes!,
                                              height: 300,
                                              width: 300,
                                              fit: BoxFit.cover,
                                            )
                                          : Image.file(
                                              selectedFile!,
                                              height: 300,
                                              width: 300,
                                              fit: BoxFit.cover,
                                            ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(
                                          context), // Close the dialog
                                      child: const Text("Close"),
                                    ),
                                  ],
                                ),
                              );
                            },
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all(
                                  Colors.green.shade700),
                              foregroundColor:
                                  MaterialStateProperty.all(Colors.white),
                            ),
                            child: const Text("View Image"),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),

                    // Upload Button
                    ElevatedButton(
                      onPressed: isUploading ? null : uploadJobType,
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(Colors.green.shade700),
                        foregroundColor:
                            MaterialStateProperty.all(Colors.white),
                      ),
                      child: isUploading
                          ? const CircularProgressIndicator()
                          : const Text("Upload Job Type"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

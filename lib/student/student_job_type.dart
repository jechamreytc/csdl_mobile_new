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
    fetchJobType();
  }

  /// FETCH JOB TYPE DATA
  Future<void> fetchJobType() async {
    final url = Uri.parse("${SessionStorage.url}transaction.php");

    try {
      final response = await http.post(
        url,
        body: {
          'operation': 'getJobType', 
          'json': jsonEncode({"job_stud_id": widget.student_id})
        },
      );

      print("Response Code: ${response.statusCode}");
      print("Raw Response: ${response.body}");

      final data = jsonDecode(response.body);
      if (data != null) {
        print("Job type data: $data");
      }
      
      setState(() {
        isLoading = false;
      });
    } catch (e, stackTrace) {
      print('❌ fetchJobType Exception: $e');
      print('🧾 StackTrace:\n$stackTrace');
      setState(() {
        isLoading = false;
      });
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
          SnackBar(
            content: Text(data['message'] ?? "Uploaded successfully"),
            backgroundColor: Colors.green,
          ),
        );
        
        // Show file URL if available
        if (data['file_url'] != null) {
          print("File uploaded successfully: ${data['file_url']}");
        }
        
        setState(() {
          selectedFile = null;
          selectedFileBytes = null;
          selectedJobType = null;
          selectedFileName = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? "Upload failed"),
            backgroundColor: Colors.red,
          ),
        );
        print("API returned error: ${data['message']}");
      }
    } catch (e, stackTrace) {
      print('❌ uploadJobType Exception: $e');
      print('🧾 StackTrace:\n$stackTrace');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Upload failed: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => isUploading = false);
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F8),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50), // Set the height of the AppBar
        child: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
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
      // appBar: AppBar(
      //   title: const Text(""),

      // ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                margin:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade50, Colors.green.shade200],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "SBO / Working Student Document Upload",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Please select your current job type and upload the required document (referral letter).",
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Select Job Type:",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        color: Colors.green.shade50,
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
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: pickFile,
                          icon: const Icon(Icons.attach_file),
                          label: const Text("Select File"),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (selectedFileName != null)
                        Text(
                          "Selected: $selectedFileName",
                          style: const TextStyle(fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 20),
                      if (selectedFile != null || selectedFileBytes != null)
                        ElevatedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text("Preview Document"),
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
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("Close"),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.image),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade600,
                            foregroundColor: Colors.white,
                          ),
                          label: const Text("View Image"),
                        ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isUploading ? null : uploadJobType,
                          icon: const Icon(Icons.cloud_upload),
                          label: isUploading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text("Upload Job Type"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade800,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

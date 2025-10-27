import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:csdl_mobile/session_storage.dart';
import 'package:csdl_mobile/student/student_drawer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:csdl_mobile/student/student_dashboard.dart';
import 'package:csdl_mobile/student/student_ocr.dart';

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
  
  // Upload status tracking
  int? uploadStatus; // 0 = pending, 1 = approved, 2 = declined
  String? declineRemarks;
  bool canUpload = true;
  bool hasUploadedThisSession = false; // Track if user uploaded in current session
  
  // Cross-system validation variables
  int? ocrStatus;
  bool canUploadJobType = true;

  @override
  void initState() {
    super.initState();
    fetchJobType();
    checkUploadStatus();
    _checkOcrStatus(); // Check OCR status for cross-validation
  }

  // Show alert dialog if user has pending or approved upload
  void _showUploadStatusAlert() {
    if (uploadStatus == 0) {
      // Pending status
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Upload Pending"),
            content: const Text("You already have a pending upload. Please wait for admin approval before uploading again."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Go back to previous page
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    } else if (uploadStatus == 1) {
      // Approved status
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Upload Approved"),
            content: const Text("Your upload has been approved. No further uploads are needed."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Go back to previous page
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    }
  }

  /// CHECK UPLOAD STATUS
  Future<void> checkUploadStatus() async {
    // Since getJobTypeUploadStatus doesn't exist, use the existing getJobType operation
    await checkExistingJobType();
  }

  /// Check OCR status for cross-system validation
  Future<void> _checkOcrStatus() async {
    try {
      final url = Uri.parse("${SessionStorage.url}transaction.php");
      final response = await http.post(
        url,
        body: {
          'operation': 'checkOcrEligibility',
          'json': jsonEncode({"stud_active_id": widget.student_id}),
        },
      );

      // print("ðŸ” OCR Status Check for Job Type:");
      // print("ðŸ“Š Response: ${response.body}");

      final data = jsonDecode(response.body);
      
      if (data != null && data['success'] == true) {
        bool hasExistingOcr = data['has_existing_ocr'] ?? false;
        bool requiresApproval = data['requires_approval'] ?? false;
        
        // Determine OCR status: 0 = pending, 1 = approved, -1 = no upload
        int ocrStatusValue = -1;
        if (hasExistingOcr) {
          ocrStatusValue = requiresApproval ? 0 : 1; // pending if requires approval, approved if not
        }
        
        // print("ðŸ“Š OCR Status: $ocrStatusValue");
        
        setState(() {
          ocrStatus = ocrStatusValue;
          // Block job type upload if OCR is pending (0) or approved (1), but NOT declined (2)
          canUploadJobType = !(ocrStatusValue == 0 || ocrStatusValue == 1);
        });
        
        // Show alert if OCR blocks job type upload (but NOT for declined status)
        if (ocrStatusValue == 0 || ocrStatusValue == 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showOcrBlockingAlert(ocrStatusValue);
          });
        }
      } else {
        setState(() {
          ocrStatus = -1; // no OCR upload
          canUploadJobType = true;
        });
      }
    } catch (e) {
      // print('âŒ Error checking OCR status: $e');
      setState(() {
        ocrStatus = -1;
        canUploadJobType = true;
      });
    }
  }

  /// Show alert when OCR status blocks job type upload
  void _showOcrBlockingAlert(int status) {
    String title = status == 0 ? "OCR Upload Pending" : status == 1 ? "OCR Upload Approved" : "OCR Upload Completed";
    String message = status == 0 
        ? "You have a pending OCR upload. Please wait for admin approval before uploading job type."
        : status == 1
            ? "Your OCR upload has been approved. You cannot upload job type until the next session."
            : "Your OCR upload has been completed. You cannot upload job type until the next session.";
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentDashboard(student_id: widget.student_id),
                  ),
                );
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }


  /// Show alert dialog with request button when existing data is found
  void _showExistingDataAlert() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Existing Data Found"),
          content: const Text("You have existing job type or OCR data. Please use the request button below to request a new upload."),
          actions: [
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                // Navigate to OCR page to make request
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentDashboard(student_id: widget.student_id),
                  ),
                );
              },
              icon: const Icon(Icons.request_page),
              label: const Text('Request OCR Upload'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentDashboard(student_id: widget.student_id),
                  ),
                );
              },
              child: const Text("Go to Dashboard"),
            ),
          ],
        );
      },
    );
  }

  /// Check existing job type data for upload status
  Future<void> checkExistingJobType() async {
    final url = Uri.parse("${SessionStorage.url}transaction.php");

    try {
      final response = await http.post(
        url,
        body: {
          'operation': 'getJobType', 
          'json': jsonEncode({"job_stud_id": widget.student_id})
        },
      );

      // print("ðŸ” Job Type Status Response: ${response.body}");
      // print("ðŸ“Š Response Status Code: ${response.statusCode}");

      final data = jsonDecode(response.body);
      // print("ðŸ“‹ Parsed Data: $data");
      // print("ðŸ“‹ Data Type: ${data.runtimeType}");
      // print("ðŸ“‹ Is List: ${data is List}");
      // print("ðŸ“‹ Is Map: ${data is Map}");
      // print("ðŸ“‹ Is Empty: ${data is List ? data.isEmpty : 'Not a list'}");
      
      // Handle both List and Map responses
      var existingData;
      if (data != null && data is List && data.isNotEmpty) {
        existingData = data.first;
        // print("ðŸ“‹ Found data in List format");
      } else if (data != null && data is Map && data.isNotEmpty) {
        existingData = data;
        // print("ðŸ“‹ Found data in Map format");
      } else {
        existingData = null;
        // print("ðŸ“‹ No data found");
      }
      
      if (existingData != null) {
        // print("Existing data found: $existingData");
        
        // Check for job_status field in the response (not 'status')
        int status = int.tryParse(existingData['job_status']?.toString() ?? '0') ?? 0;
        String remarks = existingData['job_remarks']?.toString() ?? '';
        
        // print("ðŸ“Š Job Type Status Check:");
        // print("   - Raw job_status: ${existingData['job_status']}");
        // print("   - Raw job_remarks: ${existingData['job_remarks']}");
        // print("   - Parsed Status: $status");
        // print("   - Remarks: $remarks");
        // print("   - Can Upload: ${status == 2}");
        
        setState(() {
          uploadStatus = status;
          declineRemarks = remarks;
          
          // Determine if user can upload based on status
          if (status == 0 || status == 1) { // pending or approved
            canUpload = false;
            // print("ðŸš« Upload blocked - Status: ${status == 0 ? 'PENDING' : 'APPROVED'}");
          } else if (status == 2) { // declined
            canUpload = true;
            // print("âœ… Upload allowed - Status: DECLINED (can re-upload)");
          } else { // unknown status, assume pending
            canUpload = false;
            // print("ðŸš« Upload blocked - Unknown status: $status");
          }
        });
        
        // Show alert dialog if user has pending or approved upload
        if (status == 0 || status == 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showUploadStatusAlert();
          });
        }
        
        // Use the actual status from the server
        // print("âœ… Using actual server status: $status");
      } else {
        // No existing data, can upload
        // print("ðŸ“‹ No existing upload data found - user can upload");
        setState(() {
          uploadStatus = -1; // no upload
          declineRemarks = '';
          canUpload = true;
        });
      }
    } catch (e) {
      // print('âŒ checkExistingJobType Exception: $e');
      // Default to allowing upload if we can't determine status
      setState(() {
        uploadStatus = -1; // no upload
        declineRemarks = '';
        canUpload = true;
      });
    }
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

      // print("Response Code: ${response.statusCode}");
      // print("Raw Response: ${response.body}");

      final data = jsonDecode(response.body);
      if (data != null) {
        // print("Job type data: $data");
      }
      
      setState(() {
        isLoading = false;
      });
    } catch (e, stackTrace) {
      // print('âŒ fetchJobType Exception: $e');
      // print('ðŸ§¾ StackTrace:\n$stackTrace');
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
    // Debug: Print current status
    // print("ðŸ” Upload attempt - Status: $uploadStatus, CanUpload: $canUpload, OCR Status: $ocrStatus, CanUploadJobType: $canUploadJobType");
    
    // Check cross-system validation first
    if (!canUploadJobType) {
      // print("ðŸš« Upload blocked by OCR status: $ocrStatus");
      _showOcrBlockingAlert(ocrStatus!);
      return;
    }
    
    // Check if user can upload
    if (!canUpload || hasUploadedThisSession) {
      String title = '';
      String message = '';
      
      if (hasUploadedThisSession) {
        title = 'Upload Blocked';
        message = 'You have already uploaded a document in this session. Please wait for review.';
      } else if (uploadStatus == 0) { // pending
        title = 'Upload Pending';
        message = 'Your upload is currently pending review. Please wait for admin approval before uploading again.';
      } else if (uploadStatus == 1) { // approved
        title = 'Upload Approved';
        message = 'Your upload has been approved. No further uploads are needed.';
      }
      
      // print("âŒ Upload blocked: $message");
      
      // Show AlertDialog instead of SnackBar
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
      return;
    }
    
    // print("âœ… Upload allowed, proceeding...");

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

      // print("Response Code: ${response.statusCode}");
      // print("Raw Response: ${response.body}");

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
          // print("File uploaded successfully: ${data['file_url']}");
        }
        
        // Reset form and set status to pending to prevent re-upload
        setState(() {
          selectedFile = null;
          selectedFileBytes = null;
          selectedJobType = null;
          selectedFileName = null;
          uploadStatus = 0; // pending
          canUpload = false;
          hasUploadedThisSession = true; // Mark that user has uploaded in this session
        });
        
        // Also try to refresh upload status from server
        await checkUploadStatus();
        
        // Force status to pending (0) after upload, regardless of server response
        // This ensures the UI shows pending status until admin reviews
        setState(() {
          uploadStatus = 0; // Force to pending
          canUpload = false; // Block further uploads
        });
      } else {
        // Show AlertDialog for API errors instead of SnackBar
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Upload Failed"),
              content: Text(data['message'] ?? "Upload failed. Please try again."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
        // print("API returned error: ${data['message']}");
      }
    } catch (e, stackTrace) {
      // print('âŒ uploadJobType Exception: $e');
      // print('ðŸ§¾ StackTrace:\n$stackTrace');
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Upload Error"),
            content: Text("Upload failed: ${e.toString()}"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              ),
            ],
          );
        },
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
                      
                      // Status Display - Show current upload status
                      if (uploadStatus != null)
                        Card(
                          color: uploadStatus == 1 // approved
                              ? Colors.green.shade50 
                              : uploadStatus == 0 // pending
                                  ? Colors.orange.shade50 
                                  : uploadStatus == 2 // declined
                                      ? Colors.red.shade50
                                      : Colors.blue.shade50, // no upload yet
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Icon(
                                  uploadStatus == 1 // approved
                                      ? Icons.check_circle 
                                      : uploadStatus == 0 // pending
                                          ? Icons.hourglass_empty 
                                          : uploadStatus == 2 // declined
                                              ? Icons.cancel
                                              : Icons.upload, // no upload yet
                                  color: uploadStatus == 1 // approved
                                      ? Colors.green 
                                      : uploadStatus == 0 // pending
                                          ? Colors.orange 
                                          : uploadStatus == 2 // declined
                                              ? Colors.red
                                              : Colors.blue, // no upload yet
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Upload Status: ${uploadStatus == 0 ? 'PENDING' : uploadStatus == 1 ? 'APPROVED' : uploadStatus == 2 ? 'DECLINED' : 'NO UPLOAD'}",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: uploadStatus == 1 // approved
                                              ? Colors.green.shade800 
                                              : uploadStatus == 0 // pending
                                                  ? Colors.orange.shade800 
                                                  : uploadStatus == 2 // declined
                                                      ? Colors.red.shade800
                                                      : Colors.blue.shade800, // no upload yet
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        uploadStatus == 0 
                                          ? "Your upload is under review. Please wait for admin approval."
                                          : uploadStatus == 1
                                              ? "Your upload has been approved. No further action needed."
                                              : uploadStatus == 2
                                                  ? "Your upload was declined. Please address the remarks below and re-upload."
                                                  : "You haven't uploaded any documents yet. Please select your job type and upload the required document.",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      // Show decline remarks if status is declined
                      if (uploadStatus == 2 && declineRemarks != null && declineRemarks!.isNotEmpty)
                        Card(
                          color: Colors.red.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.cancel, color: Colors.red),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Upload Declined",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  "Admin Remarks:",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.red.shade300),
                                  ),
                                  child: Text(
                                    declineRemarks!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.red,
                                    ),
                                  ),

                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "You can upload again after addressing the remarks above.",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 16),
                      const Text(
                        "Select Job Type:",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      
                      // Show disabled message if user has pending/approved upload
                      if (uploadStatus == 0 || uploadStatus == 1)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                uploadStatus == 0 ? Icons.hourglass_empty : Icons.check_circle,
                                color: uploadStatus == 0 ? Colors.orange : Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  uploadStatus == 0 
                                    ? "Your upload is pending review. Please wait for admin approval."
                                    : "Your upload has been approved. No further action needed.",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Only show form if user can upload (no pending/approved status)
                      if (uploadStatus != 0 && uploadStatus != 1) ...[
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
                      ],
                      // Only show file selection info if user can upload
                      if (uploadStatus != 0 && uploadStatus != 1) ...[
                        const SizedBox(height: 12),
                        if (selectedFileName != null)
                          Text(
                            "Selected: $selectedFileName",
                            style: const TextStyle(fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                      // Only show file preview and upload button if user can upload
                      if (uploadStatus != 0 && uploadStatus != 1) ...[
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
                          onPressed: (isUploading || !canUpload || hasUploadedThisSession || !canUploadJobType) ? null : uploadJobType,
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
                              : (!canUpload || hasUploadedThisSession)
                                  ? Text(hasUploadedThisSession 
                                      ? "Uploaded This Session" 
                                      : uploadStatus == 0 
                                          ? "Upload Pending Review" 
                                          : uploadStatus == 1
                                              ? "Upload Approved - No Re-upload Needed"
                                              : "Upload Declined - Can Re-upload")
                                  : const Text("Upload Job Type"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (!canUpload || hasUploadedThisSession)
                                ? Colors.grey.shade400 
                                : Colors.green.shade800,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}


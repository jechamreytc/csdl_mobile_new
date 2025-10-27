import 'dart:convert';
import 'package:csdl_mobile/session_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SFDutyStatus extends StatefulWidget {
  final String studentId;
  
  const SFDutyStatus({Key? key, required this.studentId}) : super(key: key);

  @override
  _SFDutyStatusState createState() => _SFDutyStatusState();
}

class _SFDutyStatusState extends State<SFDutyStatus> {
  Map<String, dynamic>? dutyInfo;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadSFDutyInfo();
  }


  Future<void> _loadSFDutyInfo() async {
    try {
      var url = Uri.parse("${SessionStorage.url}transaction.php");
      Map<String, dynamic> jsonData = {
        "stud_active_id": widget.studentId,
      };
      Map<String, String> requestBody = {
        "operation": "getSFDutyInfo",
        "json": jsonEncode(jsonData),
      };

      var response = await http.post(url, body: requestBody);
      var res = jsonDecode(response.body);

      if (mounted) {
        setState(() {
          if (res is Map<String, dynamic> && res.containsKey('error')) {
            error = res['error'];
            dutyInfo = null;
          } else {
            dutyInfo = res;
            error = null;
          }
          isLoading = false;
        });
        
        // Show duty schedule dialog after data is loaded
        if (dutyInfo != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _showDutyScheduleDialog();
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = "Error loading SF duty information: $e";
          dutyInfo = null;
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF104038)),
            ),
          ),
        ),
      );
    }

    if (error != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.orange,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                error!,
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (dutyInfo == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "No SF duty information available",
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.school,
                  color: const Color(0xFF104038),
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  "SF Duty Status",
                  style: TextStyle(
                    color: Color(0xFF104038),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Duty Schedule
            _buildInfoRow(
              "Duty Schedule",
              "${dutyInfo!['duty_start_time']} - ${dutyInfo!['duty_end_time']}",
              Icons.schedule,
            ),
            
            const SizedBox(height: 12),
            
            // Time In Status
            _buildStatusRow(
              "Time In",
              _getTimeInStatus(),
              _getTimeInIcon(),
              _getTimeInColor(),
            ),
            
            const SizedBox(height: 12),
            
            // Time Out Status
            _buildStatusRow(
              "Time Out",
              _getTimeOutStatus(),
              _getTimeOutIcon(),
              _getTimeOutColor(),
            ),
            
            const SizedBox(height: 16),
            
            // Current Time
            _buildInfoRow(
              "Current Time",
              dutyInfo!['current_time'],
              Icons.access_time,
            ),
            
            if (dutyInfo!['duty_completed'] == true) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Duty Completed for Today",
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Duty Schedule Info Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showDutyScheduleDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF104038),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 18,
                ),
                label: const Text(
                  "View Duty Schedule Details",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF104038),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(String label, String status, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF104038),
          ),
        ),
        Expanded(
          child: Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _getTimeInStatus() {
    if (dutyInfo!['time_in_completed'] == true) {
      return "Completed";
    }
    
    switch (dutyInfo!['time_in_status']) {
      case 'available':
        return "Available Now";
      case 'too_early':
        return "Too Early (Wait until ${dutyInfo!['duty_start_time']})";
      case 'too_late':
        return "Too Late (Deadline: ${dutyInfo!['time_in_deadline']})";
      default:
        return "Not Available";
    }
  }

  String _getTimeOutStatus() {
    if (dutyInfo!['time_out_completed'] == true) {
      return "Completed";
    }
    
    switch (dutyInfo!['time_out_status']) {
      case 'available':
        return "Available Now";
      case 'too_early':
        return "Too Early (Wait until ${dutyInfo!['duty_end_time']})";
      case 'too_late':
        return "Too Late (Deadline: ${dutyInfo!['time_out_deadline']})";
      default:
        return "Not Available";
    }
  }

  IconData _getTimeInIcon() {
    if (dutyInfo!['time_in_completed'] == true) {
      return Icons.check_circle;
    }
    
    switch (dutyInfo!['time_in_status']) {
      case 'available':
        return Icons.play_circle;
      case 'too_early':
        return Icons.schedule;
      case 'too_late':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  IconData _getTimeOutIcon() {
    if (dutyInfo!['time_out_completed'] == true) {
      return Icons.check_circle;
    }
    
    switch (dutyInfo!['time_out_status']) {
      case 'available':
        return Icons.stop_circle;
      case 'too_early':
        return Icons.schedule;
      case 'too_late':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  Color _getTimeInColor() {
    if (dutyInfo!['time_in_completed'] == true) {
      return Colors.green;
    }
    
    switch (dutyInfo!['time_in_status']) {
      case 'available':
        return Colors.blue;
      case 'too_early':
        return Colors.orange;
      case 'too_late':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getTimeOutColor() {
    if (dutyInfo!['time_out_completed'] == true) {
      return Colors.green;
    }
    
    switch (dutyInfo!['time_out_status']) {
      case 'available':
        return Colors.blue;
      case 'too_early':
        return Colors.orange;
      case 'too_late':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showDutyScheduleDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(
                Icons.schedule,
                color: const Color(0xFF104038),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                "SF Duty Schedule",
                style: TextStyle(
                  color: Color(0xFF104038),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange.shade600,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Your duty starts at ${dutyInfo!['duty_start_time']} and ends at ${dutyInfo!['duty_end_time']}",
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Verification Instructions
              const Text(
                "Please verify that:",
                style: TextStyle(
                  color: Color(0xFF104038),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Bullet Points
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBulletPoint("You scan time-in between ${dutyInfo!['duty_start_time']} and ${dutyInfo!['time_in_deadline']}"),
                  _buildBulletPoint("You scan time-out between ${dutyInfo!['duty_end_time']} and ${dutyInfo!['time_out_deadline']}"),
                  _buildBulletPoint("You are present for your entire duty period"),
                  _buildBulletPoint("You complete both time-in and time-out scans"),
                ],
              ),
            ],
          ),
          actions: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  "OK",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildScheduleInfoCard(String title, IconData icon, String description, String note, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            note,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTimeInStatusColor() {
    if (dutyInfo!['time_in_completed'] == true) {
      return Colors.green;
    }
    
    switch (dutyInfo!['time_in_status']) {
      case 'available':
        return Colors.blue;
      case 'too_early':
        return Colors.orange;
      case 'too_late':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getTimeOutStatusColor() {
    if (dutyInfo!['time_out_completed'] == true) {
      return Colors.green;
    }
    
    switch (dutyInfo!['time_out_status']) {
      case 'available':
        return Colors.blue;
      case 'too_early':
        return Colors.orange;
      case 'too_late':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "â€¢ ",
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

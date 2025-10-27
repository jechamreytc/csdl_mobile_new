import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:csdl_mobile/session_storage.dart';
import 'package:excel/excel.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;

class ApprovedLeadsPage extends StatefulWidget {
  final String adminEmail;
  const ApprovedLeadsPage({super.key, required this.adminEmail});

  @override
  State<ApprovedLeadsPage> createState() => _ApprovedLeadsPageState();
}

class _ApprovedLeadsPageState extends State<ApprovedLeadsPage> {
  List<Map<String, dynamic>> approvedLeads = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchApprovedLeads();
  }

  Future<void> fetchApprovedLeads() async {
    final url = Uri.parse("${SessionStorage.url}transaction.php");

    try {
      final response = await http.post(
        url,
        body: {'operation': 'getReferrals', 'json': '{}'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          // Filter only approved leads
          final filtered = (data['data'] as List)
              .where((item) => item['freshmen_ref_status'] == 1)
              .map((item) {
            final cleaned = Map<String, dynamic>.from(item);
            cleaned.remove('freshmen_ref_id');
            cleaned.remove('freshmen_ref_status');
            cleaned.remove('freshmen_ref_scholar_id');
            cleaned.remove('freshmen_ref_academic_session_id');
            return cleaned;
          }).toList();

          setState(() {
            approvedLeads = List<Map<String, dynamic>>.from(filtered);
            isLoading = false;
          });
        }
      }
    } catch (e) {
      // print("âŒ fetchApprovedLeads Error: $e");
    }
  }

  Future<void> exportToExcel() async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Approved Leads'];

      if (approvedLeads.isNotEmpty) {
        // Get all unique keys from the data to ensure we capture all fields
        final allKeys = <String>{};
        for (var lead in approvedLeads) {
          allKeys.addAll(lead.keys);
        }

        // Define the column order and user-friendly headers
        final columnMapping = <String, String>{
          'full_name': 'Full Name', // This will be a combined field
          'freshmen_ref_email_add': 'Email Address',
          'freshmen_ref_contact_number': 'Contact Number',
          'freshmen_ref_address': 'Address',
          'freshmen_ref_shs_school': 'SHS School',
          'referred_by_scholar': 'Referred by Scholar',
          'freshmen_ref_date_created': 'Date Created',
          'freshmen_ref_date_updated': 'Date Updated',
        };

        // Fields to exclude from automatic inclusion since we're handling them specially
        final excludeFields = {
          'freshmen_ref_firstname',
          'freshmen_ref_lastname',
          'freshmen_ref_middlename',
          'freshmen_ref_middle_name', // Handle both possible field names
        };

        // Add any additional fields that might exist in the data
        final orderedKeys = <String>[];

        // First add our predefined columns (full_name will always be first)
        orderedKeys
            .add('full_name'); // Always include full name as first column

        for (var key in columnMapping.keys) {
          if (key != 'full_name' && allKeys.contains(key)) {
            orderedKeys.add(key);
          }
        }

        // Add any remaining keys that weren't in our mapping (excluding name fields)
        for (var key in allKeys) {
          if (!orderedKeys.contains(key) && !excludeFields.contains(key)) {
            orderedKeys.add(key);
            columnMapping[key] = key.replaceAll('_', ' ').toUpperCase();
          }
        }

        // Header row with user-friendly names
        final headers = orderedKeys
            .map((key) => TextCellValue(columnMapping[key]!))
            .toList();
        sheet.appendRow(headers);

        // Data rows - ensure consistent alignment with headers
        for (var lead in approvedLeads) {
          final row = orderedKeys.map((key) {
            var value = lead[key];

            // Handle special formatting for specific fields
            if (key == 'full_name') {
              // Combine first name, middle name, and last name
              final firstName =
                  lead['freshmen_ref_firstname']?.toString().trim() ?? '';
              final middleName =
                  lead['freshmen_ref_middlename']?.toString().trim() ??
                      lead['freshmen_ref_middle_name']?.toString().trim() ??
                      '';
              final lastName =
                  lead['freshmen_ref_lastname']?.toString().trim() ?? '';

              // Build full name with proper spacing
              final nameParts = <String>[];
              if (firstName.isNotEmpty) nameParts.add(firstName);
              if (middleName.isNotEmpty) nameParts.add(middleName);
              if (lastName.isNotEmpty) nameParts.add(lastName);

              value = nameParts.join(' ');
            } else if (key == 'freshmen_ref_email_add') {
              value = value?.toString().toLowerCase().trim() ?? '';
            } else if (key == 'freshmen_ref_contact_number') {
              value =
                  value?.toString().replaceAll(RegExp(r'[^\d+\-\s()]'), '') ??
                      '';
            } else {
              value = value?.toString() ?? '';
            }

            return TextCellValue(value);
          }).toList();

          sheet.appendRow(row);
        }

        // Style the header row
        for (int i = 0; i < headers.length; i++) {
          final cell = sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
          cell.cellStyle = CellStyle(
            bold: true,
            backgroundColorHex: ExcelColor.lightBlue,
          );
        }
      }

      final fileBytes = excel.encode();
      if (fileBytes == null) return;

      if (kIsWeb) {
        // Web download
        final blob = html.Blob([
          fileBytes
        ], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download",
              "approved_leads_${DateTime.now().millisecondsSinceEpoch}.xlsx")
          ..click();
        html.Url.revokeObjectUrl(url);

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Excel file downloaded successfully with ${approvedLeads.length} records'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Mobile/Desktop save
        final directory = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final filePath = '${directory.path}/approved_leads_$timestamp.xlsx';
        final file = File(filePath);
        await file.writeAsBytes(fileBytes as Uint8List);

        // Show success message before opening file
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Excel file saved successfully with ${approvedLeads.length} records'),
              backgroundColor: Colors.green,
            ),
          );
        }

        await OpenFilex.open(filePath);
      }
    } catch (e) {
      // print("âŒ Excel Export Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting Excel: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Approved HK Leads"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: "Export to Excel",
            onPressed: approvedLeads.isEmpty ? null : exportToExcel,
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : approvedLeads.isEmpty
              ? Container(
                  child: const Center(child: Text("No approved leads found")))
              : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade50, Colors.green.shade200],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: ListView.builder(
                    itemCount: approvedLeads.length,
                    itemBuilder: (context, index) {
                      final lead = approvedLeads[index];

                      // Build full name consistently with Excel export
                      final firstName =
                          lead['freshmen_ref_firstname']?.toString().trim() ??
                              '';
                      final middleName = lead['freshmen_ref_middlename']
                              ?.toString()
                              .trim() ??
                          lead['freshmen_ref_middle_name']?.toString().trim() ??
                          '';
                      final lastName =
                          lead['freshmen_ref_lastname']?.toString().trim() ??
                              '';

                      final nameParts = <String>[];
                      if (firstName.isNotEmpty) nameParts.add(firstName);
                      if (middleName.isNotEmpty) nameParts.add(middleName);
                      if (lastName.isNotEmpty) nameParts.add(lastName);

                      final fullName = nameParts.join(' ');

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 10),
                        child: ListTile(
                          title: Text(
                            fullName.isNotEmpty ? fullName : 'No name provided',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "Email: ${lead['freshmen_ref_email_add'] ?? 'No email'}\n"
                            "Contact: ${lead['freshmen_ref_contact_number'] ?? 'No contact'}",
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

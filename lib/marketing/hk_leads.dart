import 'dart:convert';
import 'package:csdl_mobile/marketing/approved_leads.dart';
import 'package:csdl_mobile/marketing/marketing_drawer.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:csdl_mobile/session_storage.dart';

class HKLeadsPage extends StatefulWidget {
  final String adminEmail;
  const HKLeadsPage({super.key, required this.adminEmail});

  @override
  State<HKLeadsPage> createState() => _HKLeadsPageState();
}

class _HKLeadsPageState extends State<HKLeadsPage> {
  List referrals = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchReferrals();
  }

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
        // Filter where freshmen_ref_status == 0
        final filteredData = (data['data'] as List)
            .where((item) => item['freshmen_ref_status'] == 0)
            .toList();

        setState(() {
          referrals = filteredData;
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

  Future<void> updateStatus(int referralId, int status) async {
    final url = Uri.parse("${SessionStorage.url}transaction.php");

    try {
      final response = await http.post(
        url,
        body: {
          'operation': 'updateReferralStatus',
          'json': json.encode({
            'freshmen_ref_id': referralId,
            'freshmen_ref_status': status,
          }),
        },
      );

      print("Update Response: ${response.body}");

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              status == 1 ? 'Approved successfully' : 'Declined successfully'),
        ));

        setState(() {
          referrals.removeWhere((ref) => ref['freshmen_ref_id'] == referralId);
        });
      } else {
        print("Update API error: ${data['error']}");
      }
    } catch (e) {
      print('❌ updateStatus Exception: $e');
    }
  }

  void makePhoneCall(String number) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  // Updated sendTextMessage function with pre-filled message
  void sendTextMessage(String number, String fullName) async {
    // Dynamic pre-filled message using the referral's full name
    final String message = 'Hello $fullName, this is from PHINMA-COC';

    final Uri smsUri =
        Uri(scheme: 'sms', path: number, queryParameters: {'body': message});

    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      print("Could not open SMS app.");
    }
  }

  void showReferralDetailsModal(Map referral) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true, // lets the modal go higher
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8, // 80% height
          minChildSize: 0.5, // Minimum when dragged down
          maxChildSize: 0.95, // Almost full screen when dragged up
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${referral['freshmen_ref_firstname']} ${referral['freshmen_ref_lastname']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Email: ${referral['freshmen_ref_email_add']}'),
                  Text('Contact: ${referral['freshmen_ref_contact_number']}'),
                  Text('Address: ${referral['freshmen_ref_address']}'),
                  Text('SHS School: ${referral['freshmen_ref_shs_school']}'),
                  Text('Referred By: ${referral['referred_by_scholar']}'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => makePhoneCall(
                            referral['freshmen_ref_contact_number']),
                        icon: const Icon(Icons.call),
                        label: const Text("Call"),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () => sendTextMessage(
                          referral['freshmen_ref_contact_number'],
                          '${referral['freshmen_ref_firstname']} ${referral['freshmen_ref_lastname']}',
                        ),
                        icon: const Icon(Icons.sms),
                        label: const Text("Text"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          flexibleSpace: Image.asset(
            'assets/images/coc_logo.png',
            height: 50,
            width: 50,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.bar_chart),
              tooltip: "Show Reports",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ApprovedLeadsPage(
                      adminEmail: widget.adminEmail,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      drawer: MarketingDrawer(adminEmail: widget.adminEmail),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade50, Colors.green.shade200],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: referrals.length,
                  itemBuilder: (context, index) {
                    final referral = referrals[index];
                    final name =
                        '${referral['freshmen_ref_firstname']} ${referral['freshmen_ref_lastname']}';
                    final contact = referral['freshmen_ref_contact_number'];

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => showReferralDetailsModal(referral),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(contact),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      updateStatus(
                                          referral['freshmen_ref_id'], 1);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      minimumSize: const Size(70, 30),
                                    ),
                                    child: const Text('Approve',
                                        style: TextStyle(fontSize: 15)),
                                  ),
                                  const SizedBox(height: 5),
                                  ElevatedButton(
                                    onPressed: () {
                                      updateStatus(
                                          referral['freshmen_ref_id'], 2);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      minimumSize: const Size(70, 30),
                                    ),
                                    child: const Text('Decline',
                                        style: TextStyle(fontSize: 15)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
    );
  }
}

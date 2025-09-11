import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:csdl_mobile/marketing/marketing_drawer.dart';
import 'package:csdl_mobile/session_storage.dart';
import 'approved_leads.dart';

class MarketingDashboard extends StatefulWidget {
  final String adminEmail;

  const MarketingDashboard({super.key, required this.adminEmail});

  @override
  State<MarketingDashboard> createState() => _MarketingDashboardState();
}

class _MarketingDashboardState extends State<MarketingDashboard> {
  String _adminName = "";
  String _adminEmail = "";

  int _totalReferrals = 0;
  int _acceptedReferrals = 0;
  int _declinedReferrals = 0;

  @override
  void initState() {
    super.initState();
    _fetchMarketingProfile();
    _fetchReferralCounts();
  }

  // Fetch Marketing Profile
  Future<void> _fetchMarketingProfile() async {
    try {
      var url = Uri.parse("${SessionStorage.url}transaction.php");
      var response = await http.post(url, body: {
        "operation": "getMarketingProfile",
        "json": jsonEncode({"admin_email": widget.adminEmail}),
      });

      var res = jsonDecode(response.body);

      if (res["success"] == true && res["data"] != null) {
        var data = res["data"];
        setState(() {
          _adminName = data["adm_name"] ?? "Unknown";
          _adminEmail = data["adm_email"] ?? widget.adminEmail;
        });
      } else {
        setState(() {
          _adminName = "Unknown";
          _adminEmail = widget.adminEmail;
        });
      }
    } catch (e) {
      setState(() {
        _adminName = "Unknown";
        _adminEmail = widget.adminEmail;
      });
    }
  }

  // Fetch Counts from DB
  Future<void> _fetchReferralCounts() async {
    try {
      var url = Uri.parse("${SessionStorage.url}transaction.php");
      var response = await http.post(url, body: {
        "operation": "getReferralCounts",
        "json": jsonEncode({}),
      });

      var res = jsonDecode(response.body);
      if (res["success"] == true && res["data"] != null) {
        var data = res["data"];
        setState(() {
          _totalReferrals = data["total"] ?? 0;
          _acceptedReferrals = data["accepted"] ?? 0;
          _declinedReferrals = data["declined"] ?? 0;
        });
      }
    } catch (e) {
      print("Error fetching referral counts: $e");
    }
  }

  // Fetch referral list for list page
  Future<List<dynamic>> _fetchReferralList({String filter = "all"}) async {
    try {
      var url = Uri.parse("${SessionStorage.url}transaction.php");
      var response = await http.post(url, body: {
        "operation": "getReferrals",
        "json": jsonEncode({"filter": filter}),
      });

      var res = jsonDecode(response.body);
      if (res["success"] == true && res["data"] != null) {
        List<dynamic> data = res["data"];
        if (filter == "declined") {
          return data.where((r) => r['freshmen_ref_status'] == 2).toList();
        }
        return data; // all for "all"
      }
    } catch (e) {
      print("Error fetching referrals: $e");
    }
    return [];
  }

  // Reusable Info Card
  Widget _buildInfoCard(
      String title, String value, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Inline Referral List Page
  void _openReferralList(String filter) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text("Referrals ($filter)")),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade50, Colors.green.shade200],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: FutureBuilder<List<dynamic>>(
              future: _fetchReferralList(filter: filter),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text("Error: ${snapshot.error}",
                          style: const TextStyle(color: Colors.red)));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No referrals found."));
                }

                var referrals = snapshot.data!;
                return ListView.builder(
                  itemCount: referrals.length,
                  itemBuilder: (context, index) {
                    var referral = referrals[index];

                    // Build full name
                    String fullName =
                        "${referral['freshmen_ref_firstname']} ${referral['freshmen_ref_middle_name'] ?? ''} ${referral['freshmen_ref_lastname']}"
                            .trim();

                    // Convert status number to text
                    String statusText;
                    switch (referral['freshmen_ref_status']) {
                      case 0:
                        statusText = "Pending";
                        break;
                      case 1:
                        statusText = "Approved";
                        break;
                      case 2:
                        statusText = "Declined";
                        break;
                      default:
                        statusText = "Unknown";
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(fullName),
                        subtitle: Text("Status: $statusText"),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Image.asset(
            'assets/images/coc_logo.png',
            height: 50,
            width: 50,
          ),
        ),
      ),
      drawer: MarketingDrawer(adminEmail: widget.adminEmail),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.green.shade200],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              "Marketing Dashboard",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),

            // Profile Card
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Name: $_adminName",
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Email: $_adminEmail",
                      style:
                          const TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Referral Stats (3 clickable cards)
            Row(
              children: [
                _buildInfoCard(
                  "Total Referrals",
                  _totalReferrals.toString(),
                  Colors.blue,
                  () {
                    _openReferralList("all"); // Show all referrals
                  },
                ),
                const SizedBox(width: 8),
                _buildInfoCard(
                  "Accepted",
                  _acceptedReferrals.toString(),
                  Colors.green,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ApprovedLeadsPage(
                          adminEmail: widget.adminEmail, // Existing page
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _buildInfoCard(
                  "Declined",
                  _declinedReferrals.toString(),
                  Colors.red,
                  () {
                    _openReferralList("declined"); // Only declined
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

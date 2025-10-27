import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:csdl_mobile/marketing/marketing_drawer.dart';
import 'package:csdl_mobile/marketing/marketing_announcement.dart';
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
      // print("Error fetching referral counts: $e");
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
        
        // Filter based on status
        if (filter == "declined") {
          return data.where((r) => r['freshmen_ref_status'] == 2).toList();
        } else if (filter == "pending") {
          return data.where((r) => r['freshmen_ref_status'] == 0).toList();
        } else if (filter == "accepted") {
          return data.where((r) => r['freshmen_ref_status'] == 1).toList();
        }
        return data; // all for "all"
      }
    } catch (e) {
      // print("Error fetching referrals: $e");
    }
    return [];
  }

  // Modern Info Card
  Widget _buildModernInfoCard(
      String title, String value, Color color, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  color: color.withOpacity(0.6),
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Supervisor Style Stat Card
  Widget _buildStatCard(String label, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Legacy Info Card (kept for compatibility)
  Widget _buildInfoCard(
      String title, String value, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
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
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
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
      drawer: MarketingDrawer(adminEmail: widget.adminEmail, currentIndex: 0),
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
            const SizedBox(height: 8),

            // âœ… Marketing Info Card (row layout like supervisor)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: const Color(0xFF104038),
                      child: const Icon(Icons.person, size: 30, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _adminName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _adminEmail,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Announcements Section (matching supervisor style)
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
                    builder: (context) => MarketingAnnouncementPage(
                      adminEmail: widget.adminEmail,
                    ),
                  ),
                );
              },
              child: const Text(
                "View Announcements",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),

            const SizedBox(height: 16),

            // Referral Statistics Section (responsive design)
            LayoutBuilder(
              builder: (context, constraints) {
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header - responsive layout
                        if (constraints.maxWidth < 400)
                          // Mobile: Stack icon and text vertically
                          Column(
                            children: [
                              Icon(
                                Icons.analytics,
                                color: Colors.green[700],
                                size: 24,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Referral Statistics",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          )
                        else
                          // Desktop: Side by side layout
                          Row(
                            children: [
                              Icon(
                                Icons.analytics,
                                color: Colors.green[700],
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  "Referral Statistics",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 16),

                        // Statistics Cards - Supervisor Style Layout
                        Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    "Total Referrals",
                                    _totalReferrals.toString(),
                                    Icons.people,
                                    Colors.blue,
                                    onTap: () => _openReferralList("all"),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildStatCard(
                                    "Accepted",
                                    _acceptedReferrals.toString(),
                                    Icons.check_circle,
                                    Colors.green,
                                    onTap: () => _openReferralList("accepted"),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    "Declined",
                                    _declinedReferrals.toString(),
                                    Icons.cancel,
                                    Colors.red,
                                    onTap: () => _openReferralList("declined"),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildStatCard(
                                    "Pending",
                                    (_totalReferrals - _acceptedReferrals - _declinedReferrals).toString(),
                                    Icons.schedule,
                                    Colors.orange,
                                    onTap: () => _openReferralList("pending"),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

}

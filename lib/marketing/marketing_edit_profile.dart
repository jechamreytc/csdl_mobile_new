import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../session_storage.dart';

class MarketingEditProfile extends StatefulWidget {
  final String adminEmail;

  const MarketingEditProfile({Key? key, required this.adminEmail})
      : super(key: key);

  @override
  State<MarketingEditProfile> createState() => _MarketingEditProfileState();
}

class _MarketingEditProfileState extends State<MarketingEditProfile> {
  String name = '';
  String email = '';
  String adminId = '';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      isLoading = true;
    });

    try {
      var url = Uri.parse("${SessionStorage.url}transaction.php");
      var response = await http.post(url, body: {
        "operation": "getMarketingProfile",
        "json": jsonEncode({"admin_email": widget.adminEmail}),
      });

      if (response.statusCode == 200) {
        var res = jsonDecode(response.body);
        if (res['success'] == true) {
          var data = res['data'];
          setState(() {
            name = data['adm_name'] ?? '';
            email = data['adm_email'] ?? '';
            adminId = data['adm_id'].toString();
          });
        }
      }
    } catch (e) {
      print("Error loading profile: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Marketing Profile"),
        backgroundColor: const Color(0xFF104038),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Admin ID: $adminId",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text("Name: $name",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text("Email: $email",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
    );
  }
}

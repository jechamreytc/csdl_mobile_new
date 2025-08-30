import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:csdl_mobile/session_storage.dart';

class MarketingEditProfile extends StatefulWidget {
  final String adminEmail;

  const MarketingEditProfile({Key? key, required this.adminEmail})
      : super(key: key);

  @override
  _MarketingEditProfileState createState() => _MarketingEditProfileState();
}

class _MarketingEditProfileState extends State<MarketingEditProfile> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

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

    final url = Uri.parse("${SessionStorage.url}transaction.php");

    try {
      final response = await http.post(
        url,
        body: {
          'operation': 'getMarketingProfile',
          'json': json.encode({
            'adminEmail': widget.adminEmail,
          }),
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data.isNotEmpty) {
          setState(() {
            _nameController.text = data['name'] ?? '';
            _emailController.text = data['email'] ?? '';
            _phoneController.text = data['phone'] ?? '';
          });
        }
      } else {
        debugPrint("Failed to load profile: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _saveProfile() async {
    setState(() {
      isLoading = true;
    });

    final url = Uri.parse("${SessionStorage.url}transaction.php");

    try {
      final response = await http.post(
        url,
        body: {
          'operation': 'updateMarketingProfile',
          'json': json.encode({
            'adminEmail': widget.adminEmail,
            'name': _nameController.text,
            'email': _emailController.text,
            'phone': _phoneController.text,
          }),
        },
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Profile updated successfully!")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to update profile.")),
          );
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Profile"),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: "Name"),
                  ),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(labelText: "Email"),
                  ),
                  TextField(
                    controller: _phoneController,
                    decoration: InputDecoration(labelText: "Phone"),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saveProfile,
                    child: Text("Save"),
                  ),
                ],
              ),
            ),
    );
  }
}

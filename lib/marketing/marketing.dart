import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:csdl_mobile/marketing/marketing_drawer.dart';

class MarketingDashboard extends StatelessWidget {
  final String adminEmail; // ✅ Step 1: Add this

  const MarketingDashboard(
      {super.key, required this.adminEmail}); // ✅ Step 2: Required parameter

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50), // Set the height of the AppBar
        child: AppBar(
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
      drawer: MarketingDrawer(adminEmail: adminEmail), // ✅ Step 3: Pass it here
      body: const Center(
        child: Text(
          "Welcome to the Marketing Dashboard!",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

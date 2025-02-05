import 'package:flutter/material.dart';

class DrawerMain extends StatelessWidget {
  final String headerTitle; // Title for the drawer header
  final Color headerColor; // Background color for the header
  final List<Widget> listTiles; // Customizable ListTiles for the drawer

  const DrawerMain({
    super.key,
    this.headerTitle = "Drawer Header", // Default header title
    this.headerColor = Colors.blue, // Default header color
    this.listTiles = const [], // Default empty list of tiles
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF007BFF),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: headerColor,
            ),
            child: Text(
              headerTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
            ),
          ),
          ...listTiles, // Add customizable ListTiles passed from outside
        ],
      ),
    );
  }
}

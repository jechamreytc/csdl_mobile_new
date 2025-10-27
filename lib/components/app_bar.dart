import 'package:flutter/material.dart';

class AppBarMain extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color backgroundColor;
  final Color textColor;

  const AppBarMain({
    super.key,
    this.title = "Flutter Chat", // Default title
    this.backgroundColor = Colors.white, // Default background color
    this.textColor = Colors.black, // Default text color
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(color: textColor, fontSize: 20),
      ),
      centerTitle: true,
      backgroundColor: backgroundColor,
      elevation: 0, // Optional: removes the shadow under the AppBar
      iconTheme: IconThemeData(color: textColor),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(
            Icons.notifications_none,
            color: Colors.white,
          ),
        ),
      ], // Ensures icons match text color
    );
  }

  // Necessary for PreferredSizeWidget
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

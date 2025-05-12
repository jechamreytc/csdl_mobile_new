import 'package:flutter/material.dart';

class ImageBackground extends StatelessWidget {
  final String imagePath;
  final BoxFit fit;
  final double width;
  final double height;
  final Alignment alignment;

  const ImageBackground({
    Key? key,
    this.imagePath = 'assets/images/csdl_background.jpg', // Default image path
    this.fit = BoxFit.cover,
    this.width = double.infinity,
    this.height = double.infinity,
    this.alignment = Alignment.topLeft,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/csdl_background.jpg'),
          fit: BoxFit.cover,
          alignment: Alignment.topLeft,
        ),
        gradient: LinearGradient(
          colors: [
            Color.fromRGBO(255, 255, 255, 0.9), // White with 90% opacity
            Color.fromRGBO(255, 255, 255, 0.9), // White with 90% opacity
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}

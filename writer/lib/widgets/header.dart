import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      "Literature Dashboard",
      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
    );
  }
}

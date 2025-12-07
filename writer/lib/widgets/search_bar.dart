import 'package:flutter/material.dart';

class Search_Bar extends StatelessWidget {
  final Function(String) onChanged;

  Search_Bar({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: "Search literature...",
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.search),
      ),
      onChanged: onChanged,
    );
  }
}

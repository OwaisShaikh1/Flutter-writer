import 'package:flutter/material.dart';

class LiteratureSearchBar extends StatelessWidget {
  final Function(String) onChanged;

  const LiteratureSearchBar({super.key, required this.onChanged});

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

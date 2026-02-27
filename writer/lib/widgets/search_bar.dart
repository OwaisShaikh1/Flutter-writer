import 'package:flutter/material.dart';

class LiteratureSearchBar extends StatelessWidget {
  final Function(String) onChanged;

  const LiteratureSearchBar({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(),
      child: TextField(
        decoration: InputDecoration(
          hintText: "Search works...",
          hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            fontSize: 14,
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 20,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

import 'package:flutter/material.dart';

class LiteratureList extends StatelessWidget {
  final List<Map<String, String>> items;

  LiteratureList({required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: items.map((book) {
        return Card(
          child: ListTile(
            title: Text(book["title"]!),
            subtitle: Text(book["author"]!),
            trailing: Text(book["type"]!),
          ),
        );
      }).toList(),
    );
  }
}

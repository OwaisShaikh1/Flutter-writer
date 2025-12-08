import 'package:flutter/material.dart';
import '../pages/introduction_page.dart';

class LiteratureList extends StatelessWidget {
  final List<Map<String, dynamic>> items;

  const LiteratureList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: items.map((book) {
        return Card(
          child: ListTile(
            title: Text(book["title"]!),
            subtitle: Text(book["author"]!),
            trailing: Text(book["type"]!),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => IntroductionPage(literatureItem: book),
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }
}

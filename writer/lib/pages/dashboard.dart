import 'package:flutter/material.dart';
import '../widgets/header.dart';
import '../widgets/search_bar.dart';
import '../widgets/filter_section.dart';
import '../widgets/literature_list.dart';

class Dashboard extends StatefulWidget {
  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  String searchText = "";
  String selectedFilter = "All";

  List<Map<String, dynamic>> literature = [
    {
      "title": "Hamlet",
      "author": "Shakespeare",
      "type": "Drama",
      "rating": 4.8,
      "chapters": 5,
      "comments": 1234,
      "image": null,
      "description": "The tragedy of Hamlet, Prince of Denmark, is Shakespeare's longest play. It tells the story of Prince Hamlet seeking revenge for his father's murder."
    },
    {
      "title": "Fire and Ice",
      "author": "Robert Frost",
      "type": "Poetry",
      "rating": 4.5,
      "chapters": 1,
      "comments": 567,
      "image": null,
      "description": "A profound nine-line poem that contemplates the end of the world through the metaphors of fire and ice, representing desire and hatred."
    },
    {
      "title": "Pride & Prejudice",
      "author": "Jane Austen",
      "type": "Novel",
      "rating": 4.9,
      "chapters": 61,
      "comments": 3456,
      "image": null,
      "description": "A romantic novel of manners that follows Elizabeth Bennet as she deals with issues of morality, education, and marriage in landed gentry society."
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Header(),
            const SizedBox(height: 20),
            LiteratureSearchBar(
              onChanged: (value) => setState(() => searchText = value),
            ),
            const SizedBox(height: 20),
            FilterSection(
              selected: selectedFilter,
              onSelect: (filter) => setState(() => selectedFilter = filter),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: LiteratureList(
                items: literature.where((item) {
                  final matchesSearch = item["title"]!
                      .toLowerCase()
                      .contains(searchText.toLowerCase());

                  final matchesFilter = selectedFilter == "All" ||
                      item["type"] == selectedFilter;

                  return matchesSearch && matchesFilter;
                }).toList(),
              ),
            )
          ],
        ),
      ),
    );
  }
}

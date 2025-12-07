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

  List<Map<String, String>> literature = [
    {"title": "Hamlet", "author": "Shakespeare", "type": "Drama"},
    {"title": "Fire and Ice", "author": "Robert Frost", "type": "Poetry"},
    {"title": "Pride & Prejudice", "author": "Jane Austen", "type": "Novel"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Header(),
            SizedBox(height: 20),
            Search_Bar(
              onChanged: (value) => setState(() => searchText = value),
            ),
            SizedBox(height: 20),
            FilterSection(
              selected: selectedFilter,
              onSelect: (filter) => setState(() => selectedFilter = filter),
            ),
            SizedBox(height: 20),
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

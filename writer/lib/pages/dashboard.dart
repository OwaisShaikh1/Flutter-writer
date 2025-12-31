import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../widgets/header.dart';
import '../widgets/search_bar.dart';
import '../widgets/filter_section.dart';
import '../widgets/literature_list.dart';

class Dashboard extends StatefulWidget {
  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  // Primary remote URL to fetch the literature JSON from.
  // Replace this placeholder with your real endpoint.
  // Use an endpoint that returns a JSON array of literature objects.
  final String primaryUrl = 'https://jsonplaceholder.typicode.com/posts';

  String searchText = "";
  String selectedFilter = "All";

  // Start with dummy data; fetch will attempt to replace this list.
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

  bool _loadingRemote = false;

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
              child: _loadingRemote
                  ? const Center(child: CircularProgressIndicator())
                  : LiteratureList(
                      items: literature.where((item) {
                        final title = (item["title"] ?? '').toString();
                        final matchesSearch = title
                            .toLowerCase()
                            .contains(searchText.toLowerCase());

                        final matchesFilter = selectedFilter == "All" ||
                            (item["type"] ?? '') == selectedFilter;

                        return matchesSearch && matchesFilter;
                      }).toList(),
                    ),
            )
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Attempt to fetch remote data; keep dummy if fetch fails.
    _fetchRemoteLiterature();
  }

  Future<void> _fetchRemoteLiterature() async {
    setState(() => _loadingRemote = true);
    try {
      final uri = Uri.parse(primaryUrl);
      final resp = await http.get(uri).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);

        List<Map<String, dynamic>> parsed = [];

        // If the remote API returns the jsonplaceholder "posts" structure
        // we map each post to the expected literature shape.
        if (decoded is List) {
          parsed = decoded.map<Map<String, dynamic>>((e) {
            if (e is Map && e.containsKey('title') && e.containsKey('body')) {
              return {
                'title': e['title']?.toString() ?? 'Untitled',
                'author': e['userId'] != null ? 'User ${e['userId']}' : 'Unknown',
                'type': 'Article',
                'rating': 4.0,
                'chapters': 1,
                'comments': e['id'] ?? 0,
                'image': null,
                'description': e['body']?.toString() ?? '',
              };
            }

            // Fallback: if element is already a map with expected keys, keep it
            if (e is Map) return Map<String, dynamic>.from(e);

            return {'title': e.toString(), 'author': 'Unknown'};
          }).toList();
        } else if (decoded is Map && decoded.containsKey('title') && decoded.containsKey('body')) {
          // Single-object response -> wrap into a list
          parsed = [
            {
              'title': decoded['title']?.toString() ?? 'Untitled',
              'author': decoded['userId'] != null ? 'User ${decoded['userId']}' : 'Unknown',
              'type': 'Article',
              'rating': 4.0,
              'chapters': 1,
              'comments': decoded['id'] ?? 0,
              'image': null,
              'description': decoded['body']?.toString() ?? '',
            }
          ];
        }

        if (parsed.isNotEmpty && mounted) setState(() => literature = parsed);
      }
    } catch (e) {
      // Ignore errors and keep dummy data; consider logging or showing user feedback.
    } finally {
      if (mounted) setState(() => _loadingRemote = false);
    }
  }
}

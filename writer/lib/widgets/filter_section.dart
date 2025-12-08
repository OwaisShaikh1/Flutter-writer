import 'package:flutter/material.dart';

class FilterSection extends StatelessWidget {
  final String selected;
  final Function(String) onSelect;

  final List<String> filters = const ["All", "Poetry", "Drama", "Novel"];

  const FilterSection({super.key, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      children: filters.map((filter) {
        return ChoiceChip(
          label: Text(filter),
          selected: selected == filter,
          onSelected: (_) => onSelect(filter),
        );
      }).toList(),
    );
  }
}

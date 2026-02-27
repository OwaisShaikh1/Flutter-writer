import 'package:flutter/material.dart';

class FilterSection extends StatelessWidget {
  final String selected;
  final Function(String) onSelect;

  final List<String> filters = const ["All", "Poems", "Drama", "Novel"];

  const FilterSection({super.key, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = selected == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () => onSelect(filter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    filter,
                    style: TextStyle(
                      color: isSelected 
                        ? Theme.of(context).colorScheme.primary 
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                  if (isSelected)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      height: 2,
                      width: 12,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

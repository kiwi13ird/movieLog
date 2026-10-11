import 'package:flutter/material.dart';

class GenreChip extends StatelessWidget {
  const GenreChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      key: ValueKey('genre-$label'),
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
    );
  }
}

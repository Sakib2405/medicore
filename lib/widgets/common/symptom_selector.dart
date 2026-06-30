import 'package:flutter/material.dart';

class SymptomSelector extends StatefulWidget {
  final List<String> availableSymptoms;
  final Function(List<String>) onSelectionChanged;

  const SymptomSelector({
    super.key,
    required this.availableSymptoms,
    required this.onSelectionChanged,
  });

  @override
  State<SymptomSelector> createState() => _SymptomSelectorState();
}

class _SymptomSelectorState extends State<SymptomSelector> {
  final List<String> _selectedSymptoms = [];

  void _toggleSymptom(String symptom) {
    setState(() {
      if (_selectedSymptoms.contains(symptom)) {
        _selectedSymptoms.remove(symptom);
      } else {
        _selectedSymptoms.add(symptom);
      }
    });
    // Report the change back to the parent screen
    widget.onSelectionChanged(_selectedSymptoms);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: widget.availableSymptoms.map((symptom) {
        final isSelected = _selectedSymptoms.contains(symptom);
        return FilterChip(
          label: Text(symptom),
          selected: isSelected,
          onSelected: (selected) {
            _toggleSymptom(symptom);
          },
        );
      }).toList(),
    );
  }
}

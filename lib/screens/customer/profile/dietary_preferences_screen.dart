import 'package:diet_app/providers/customer_provider.dart';
import 'package:diet_app/utilities/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DietaryPreferencesScreen extends StatefulWidget {
  const DietaryPreferencesScreen({super.key});

  @override
  State<DietaryPreferencesScreen> createState() =>
      _DietaryPreferencesScreenState();
}

class _DietaryPreferencesScreenState extends State<DietaryPreferencesScreen> {
  static const List<String> _allergyOptions = [
    'Gluten',
    'Dairy',
    'Nuts',
    'Eggs',
    'Soy',
    'Shellfish',
    'Fish',
    'Wheat',
    'Sesame',
    'Sulphites',
  ];

  static const List<String> _dietaryOptions = [
    'Vegetarian',
    'Vegan',
    'Halal',
    'Kosher',
    'Keto',
    'Low Carb',
    'High Protein',
    'Low Fat',
    'Dairy Free',
    'Gluten Free',
  ];

  final DefaultColors _colors = DefaultColors();
  final TextEditingController _dislikedController = TextEditingController();

  late Set<String> _selectedAllergies;
  late Set<String> _selectedDietaryPrefs;
  final List<String> _dislikedIngredients = <String>[];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<CustomerProvider>();
    _selectedAllergies = provider.allergies.toSet();
    _selectedDietaryPrefs = provider.dietaryPreferences.toSet();
  }

  @override
  void dispose() {
    _dislikedController.dispose();
    super.dispose();
  }

  Future<void> _savePreferences() async {
    if (_saving) {
      return;
    }

    setState(() => _saving = true);
    final provider = context.read<CustomerProvider>();

    try {
      await provider.saveAllergies(_selectedAllergies.toList()..sort());
      await provider.saveDietaryPreferences(
        _selectedDietaryPrefs.toList()..sort(),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferences saved')),
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _addDislikedIngredient() {
    final ingredient = _dislikedController.text.trim();
    if (ingredient.isEmpty || _dislikedIngredients.contains(ingredient)) {
      _dislikedController.clear();
      return;
    }

    setState(() {
      _dislikedIngredients.add(ingredient);
      _dislikedController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Food Preferences')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Allergies'),
            const SizedBox(height: 10),
            _buildSelectableChips(
              options: _allergyOptions,
              selectedValues: _selectedAllergies,
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Dietary Preferences'),
            const SizedBox(height: 10),
            _buildSelectableChips(
              options: _dietaryOptions,
              selectedValues: _selectedDietaryPrefs,
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Disliked Ingredients'),
            const SizedBox(height: 6),
            Text(
              'Optional',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _dislikedController,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _addDislikedIngredient(),
                    decoration: InputDecoration(
                      hintText: 'Type an ingredient',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: _addDislikedIngredient,
                  child: const Text('Add'),
                ),
              ],
            ),
            if (_dislikedIngredients.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _dislikedIngredients
                    .map(
                      (ingredient) => Chip(
                        label: Text(ingredient),
                        onDeleted: () {
                          setState(() {
                            _dislikedIngredients.remove(ingredient);
                          });
                        },
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: _saving
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _savePreferences,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _colors.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save Preferences',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: _colors.richBlackColor,
      ),
    );
  }

  Widget _buildSelectableChips({
    required List<String> options,
    required Set<String> selectedValues,
  }) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((option) {
        final isSelected = selectedValues.contains(option);

        return FilterChip(
          label: Text(option),
          selected: isSelected,
          selectedColor: _colors.primaryColor.withValues(alpha: 0.18),
          checkmarkColor: _colors.primaryColor,
          side: BorderSide(
            color: isSelected ? _colors.primaryColor : Colors.grey.shade400,
          ),
          labelStyle: TextStyle(
            color: isSelected ? _colors.primaryColor : Colors.grey.shade800,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
          onSelected: (selected) {
            setState(() {
              if (selected) {
                selectedValues.add(option);
              } else {
                selectedValues.remove(option);
              }
            });
          },
        );
      }).toList(growable: false),
    );
  }
}

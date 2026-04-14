import 'package:diet_app/components/loading.dart';
import 'package:diet_app/providers/customer_provider.dart';
import 'package:diet_app/providers/user_provider.dart';
import 'package:diet_app/utilities/constants.dart';
import 'package:diet_app/utilities/tdee_calculator.dart';
import 'package:diet_app/utilities/toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CalorieCalculatorScreen extends StatefulWidget {
  const CalorieCalculatorScreen({super.key});

  @override
  State<CalorieCalculatorScreen> createState() =>
      _CalorieCalculatorScreenState();
}

class _CalorieCalculatorScreenState extends State<CalorieCalculatorScreen> {
  final DefaultColors _colors = DefaultColors();
  late String _gender;
  late String _activityLevel;
  bool _loading = false;
  Map<String, double>? _results;

  @override
  void initState() {
    super.initState();
    final customer = context.read<CustomerProvider>();
    _gender = customer.getGender;
    _activityLevel = customer.getActivityLevel;
    _calculateResults();
  }

  void _calculateResults() {
    final customer = context.read<CustomerProvider>();
    final weight = customer.getWeight?.toDouble() ?? 0;
    final height = customer.getHeight ?? 0;
    final age = customer.getAge ?? 0;
    final targetWeight = customer.getTargetWeight;

    if (weight > 0 && height > 0 && age > 0) {
      _results = TdeeCalculator.calculateAll(
        weightKg: weight,
        heightCm: height,
        age: age,
        isMale: _gender == 'male',
        activityLevel: _activityLevel,
        targetWeight: targetWeight,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final customer = context.watch<CustomerProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Calorie Calculator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Auto-populated stats
            _buildStatsCard(customer),
            const SizedBox(height: 20),

            // Gender selector
            Text('Gender',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _colors.richBlackColor)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildGenderButton(
                      'Male', Icons.male, _gender == 'male'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildGenderButton(
                      'Female', Icons.female, _gender == 'female'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Activity level
            Text('Activity Level',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _colors.richBlackColor)),
            const SizedBox(height: 8),
            ...TdeeCalculator.activityLabels.entries.map(
              (entry) => _buildActivityOption(entry.key, entry.value),
            ),

            const SizedBox(height: 24),

            // Results
            if (_results != null) ...[
              _buildResultsCard(),
              const SizedBox(height: 16),
              _buildMacroCard(),
              const SizedBox(height: 24),
            ],

            // Save button
            SizedBox(
              width: double.infinity,
              child: _loading
                  ? const Center(child: LoadingSpinner())
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _colors.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _saveSettings,
                      child: const Text(
                        'Save as My Daily Target',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(CustomerProvider customer) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Age', '${customer.getAge ?? 0}', Icons.cake),
            _buildStatItem(
                'Height', '${customer.getHeight ?? 0} cm', Icons.height),
            _buildStatItem(
                'Weight', '${customer.getWeight ?? 0} kg', Icons.fitness_center),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: _colors.primaryColor, size: 24),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildGenderButton(String label, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _gender = label.toLowerCase();
          _calculateResults();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? _colors.primaryColor
              : _colors.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? _colors.primaryColor
                : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: isSelected ? Colors.white : _colors.primaryColor),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.black)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityOption(String key, String label) {
    final isSelected = _activityLevel == key;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activityLevel = key;
          _calculateResults();
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? _colors.primaryColor.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? _colors.primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? _colors.primaryColor : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              _colors.primaryColor.withValues(alpha: 0.08),
              _colors.primaryColor.withValues(alpha: 0.02),
            ],
          ),
        ),
        child: Column(
          children: [
            Text('Your Daily Calories',
                style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text(
              '${_results!['goalCalories']!.round()} kcal',
              style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: _colors.primaryColor),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCalorieItem(
                    'BMR', '${_results!['bmr']!.round()} kcal'),
                Container(width: 1, height: 30, color: Colors.grey[300]),
                _buildCalorieItem(
                    'TDEE', '${_results!['tdee']!.round()} kcal'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieItem(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildMacroCard() {
    final protein = _results!['proteinGrams']!.round();
    final carbs = _results!['carbGrams']!.round();
    final fat = _results!['fatGrams']!.round();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Macro Split (30/40/30)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildMacroRow('Protein', protein, 0.30, Colors.red[400]!),
            const SizedBox(height: 10),
            _buildMacroRow('Carbs', carbs, 0.40, Colors.amber[600]!),
            const SizedBox(height: 10),
            _buildMacroRow('Fat', fat, 0.30, Colors.blue[400]!),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroRow(
      String label, int grams, double fraction, Color color) {
    return Row(
      children: [
        SizedBox(
            width: 60,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w500))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              backgroundColor: Colors.grey[200],
              color: color,
              minHeight: 10,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 55,
          child: Text('${grams}g',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Future<void> _saveSettings() async {
    setState(() => _loading = true);
    try {
      final customerId =
          context.read<UserIdProvider>().getUuid.toString();
      final customerProvider = context.read<CustomerProvider>();

      await customerProvider.setActivityLevel(
          activityLevel: _activityLevel, customerId: customerId);
      await customerProvider.setGender(
          gender: _gender, customerId: customerId);

      if (mounted) {
        FlutterToast.showToast('Settings saved!', _colors.lightGreenColor);
        Navigator.of(context).pop();
      }
    } catch (e) {
      FlutterToast.showToast('Error saving settings', _colors.redColor);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

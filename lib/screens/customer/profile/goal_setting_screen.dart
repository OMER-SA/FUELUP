import 'package:diet_app/components/loading.dart';
import 'package:diet_app/providers/customer_provider.dart';
import 'package:diet_app/providers/user_provider.dart';
import 'package:diet_app/utilities/constants.dart';
import 'package:diet_app/utilities/tdee_calculator.dart';
import 'package:diet_app/utilities/toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GoalSettingScreen extends StatefulWidget {
  const GoalSettingScreen({super.key});

  @override
  State<GoalSettingScreen> createState() => _GoalSettingScreenState();
}

class _GoalSettingScreenState extends State<GoalSettingScreen> {
  final DefaultColors _colors = DefaultColors();
  late double _targetWeight;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final customer = context.read<CustomerProvider>();
    _targetWeight = customer.getTargetWeight ??
        (customer.getWeight?.toDouble() ?? 70.0);
  }

  @override
  Widget build(BuildContext context) {
    final customer = context.watch<CustomerProvider>();
    final currentWeight = customer.getWeight?.toDouble() ?? 0;
    final currentHeight = customer.getHeight ?? 0;
    final currentBmi = customer.calculateBmi();

    // Calculate BMI at target weight
    final targetBmi = currentHeight > 0
        ? _targetWeight / ((currentHeight / 100) * (currentHeight / 100))
        : 0.0;

    final weekEstimate =
        TdeeCalculator.estimateWeeksToGoal(currentWeight, _targetWeight);
    final goalDesc =
        TdeeCalculator.getGoalDescription(currentWeight, _targetWeight);

    return Scaffold(
      appBar: AppBar(title: const Text('Set Your Goal')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current vs Target comparison
            Row(
              children: [
                Expanded(
                    child: _buildComparisonCard(
                  'Current',
                  currentWeight,
                  currentBmi,
                  _colors.primaryColor,
                )),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildComparisonCard(
                  'Target',
                  _targetWeight,
                  targetBmi,
                  Colors.blue,
                )),
              ],
            ),
            const SizedBox(height: 24),

            // Target weight slider
            Text('Target Weight (kg)',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _colors.richBlackColor)),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: () => setState(() {
                    if (_targetWeight > 30) _targetWeight -= 0.5;
                  }),
                  icon: Icon(Icons.remove_circle,
                      color: _colors.primaryColor, size: 32),
                ),
                Expanded(
                  child: Slider(
                    min: 30,
                    max: 200,
                    value: _targetWeight.clamp(30, 200),
                    activeColor: _colors.primaryColor,
                    onChanged: (value) =>
                        setState(() => _targetWeight = double.parse(
                              value.toStringAsFixed(1),
                            )),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() {
                    if (_targetWeight < 200) _targetWeight += 0.5;
                  }),
                  icon: Icon(Icons.add_circle,
                      color: _colors.primaryColor, size: 32),
                ),
              ],
            ),
            Center(
              child: Text(
                '${_targetWeight.toStringAsFixed(1)} kg',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _colors.primaryColor),
              ),
            ),
            const SizedBox(height: 24),

            // Goal info card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow(Icons.flag, 'Goal', goalDesc),
                    const Divider(),
                    _buildInfoRow(Icons.calendar_today, 'Estimated Time',
                        weekEstimate > 0 ? '~$weekEstimate weeks' : 'At goal'),
                    const Divider(),
                    _buildInfoRow(
                      Icons.speed,
                      'Target BMI',
                      '${targetBmi.toStringAsFixed(1)} (${_getBmiStatus(targetBmi)})',
                    ),
                    const Divider(),
                    _buildInfoRow(
                      Icons.local_fire_department,
                      'Weekly Change',
                      currentWeight != _targetWeight
                          ? '~0.5 kg/week'
                          : 'Maintain',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

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
                      onPressed: _saveGoal,
                      child: const Text(
                        'Save Goal',
                        style: TextStyle(
                            fontSize: 18,
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

  Widget _buildComparisonCard(
      String label, double weight, double bmi, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('${weight.toStringAsFixed(1)} kg',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text('BMI: ${bmi.toStringAsFixed(1)}',
                style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            Text(_getBmiStatus(bmi),
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _getBmiColor(bmi))),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: _colors.primaryColor),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _getBmiStatus(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25.0) return 'Normal';
    if (bmi < 30.0) return 'Overweight';
    return 'Obese';
  }

  Color _getBmiColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25.0) return _colors.primaryColor;
    if (bmi < 30.0) return Colors.orange;
    return _colors.redColor;
  }

  Future<void> _saveGoal() async {
    setState(() => _loading = true);
    try {
      final customerId =
          context.read<UserIdProvider>().getUuid.toString();
      await context.read<CustomerProvider>().setTargetWeight(
            targetWeight: _targetWeight,
            customerId: customerId,
          );
      if (mounted) {
        FlutterToast.showToast(
            'Goal saved!', _colors.lightGreenColor);
        Navigator.of(context).pop();
      }
    } catch (e) {
      FlutterToast.showToast('Error saving goal', _colors.redColor);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

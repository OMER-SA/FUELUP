import 'package:diet_app/components/loading.dart';
import 'package:diet_app/firebase/bmi_history_service.dart';
import 'package:diet_app/providers/customer_provider.dart';
import 'package:diet_app/providers/user_provider.dart';
import 'package:diet_app/utilities/constants.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class BmiHistoryScreen extends StatefulWidget {
  const BmiHistoryScreen({super.key});

  @override
  State<BmiHistoryScreen> createState() => _BmiHistoryScreenState();
}

class _BmiHistoryScreenState extends State<BmiHistoryScreen> {
  final BmiHistoryService _historyService = BmiHistoryService();
  final DefaultColors _colors = DefaultColors();
  List<Map<String, dynamic>> _readings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final customerId =
        context.read<UserIdProvider>().getUuid.toString();
    final readings = await _historyService.getHistory(
      customerId: customerId,
      months: 12,
    );
    if (mounted) {
      setState(() {
        _readings = readings;
        _isLoading = false;
      });
    }
  }

  Color _getBmiColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25.0) return _colors.primaryColor;
    if (bmi < 30.0) return Colors.orange;
    return _colors.redColor;
  }

  String _getBmiStatus(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25.0) return 'Normal';
    if (bmi < 30.0) return 'Overweight';
    return 'Obese';
  }

  @override
  Widget build(BuildContext context) {
    final customerProvider = context.watch<CustomerProvider>();
    final currentBmi = customerProvider.calculateBmi();
    final targetWeight = customerProvider.getTargetWeight;

    return Scaffold(
      appBar: AppBar(title: const Text('BMI History')),
      body: _isLoading
          ? const Center(child: LoadingSpinner())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current BMI Card
                  _buildCurrentBmiCard(currentBmi),
                  const SizedBox(height: 24),

                  // Chart
                  if (_readings.length >= 2) ...[
                    Text('Progress Chart',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _colors.richBlackColor)),
                    const SizedBox(height: 16),
                    _buildChart(targetWeight),
                    const SizedBox(height: 24),
                  ],

                  // History list
                  Text('Reading History',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _colors.richBlackColor)),
                  const SizedBox(height: 12),
                  if (_readings.isEmpty)
                    _buildEmptyState()
                  else
                    ..._readings.reversed
                        .map((reading) => _buildReadingCard(reading)),
                ],
              ),
            ),
    );
  }

  Widget _buildCurrentBmiCard(double bmi) {
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
              _getBmiColor(bmi).withValues(alpha: 0.1),
              _getBmiColor(bmi).withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Column(
          children: [
            Text('Current BMI',
                style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text(bmi.toStringAsFixed(1),
                style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: _getBmiColor(bmi))),
            Text(_getBmiStatus(bmi),
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: _getBmiColor(bmi))),
            if (_readings.length >= 2) ...[
              const SizedBox(height: 12),
              _buildTrendIndicator(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrendIndicator() {
    final latest = _readings.last['bmi'] as double;
    final previous = _readings[_readings.length - 2]['bmi'] as double;
    final diff = latest - previous;
    final isUp = diff > 0.1;
    final isDown = diff < -0.1;

    IconData icon = Icons.trending_flat;
    Color color = Colors.grey;
    String label = 'Stable';

    if (isUp) {
      icon = Icons.trending_up;
      color = Colors.orange;
      label = '+${diff.toStringAsFixed(1)} since last reading';
    } else if (isDown) {
      icon = Icons.trending_down;
      color = _colors.primaryColor;
      label = '${diff.toStringAsFixed(1)} since last reading';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 13)),
      ],
    );
  }

  Widget _buildChart(double? targetWeight) {
    final spots = _readings.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value['bmi'] as double);
    }).toList();

    final minBmi = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxBmi = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 220,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: LineChart(
            LineChartData(
              minY: (minBmi - 2).clamp(0, 100),
              maxY: maxBmi + 2,
              gridData: FlGridData(
                show: true,
                horizontalInterval: 5,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey[200]!,
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 35,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey[600]),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < _readings.length) {
                        final date =
                            _readings[index]['recordedAt'] as DateTime;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            DateFormat('d/M').format(date),
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey[600]),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                // BMI line
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: _colors.primaryColor,
                  barWidth: 3,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) =>
                        FlDotCirclePainter(
                      radius: 4,
                      color: _getBmiColor(spot.y),
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: _colors.primaryColor.withValues(alpha: 0.1),
                  ),
                ),
              ],
              // Normal BMI range indicator lines
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: 18.5,
                    color: Colors.blue.withValues(alpha: 0.4),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                    label: HorizontalLineLabel(
                      show: true,
                      labelResolver: (_) => 'Underweight',
                      style: TextStyle(
                          fontSize: 9, color: Colors.blue[300]),
                    ),
                  ),
                  HorizontalLine(
                    y: 25.0,
                    color: Colors.orange.withValues(alpha: 0.4),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                    label: HorizontalLineLabel(
                      show: true,
                      labelResolver: (_) => 'Overweight',
                      style: TextStyle(
                          fontSize: 9, color: Colors.orange[300]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReadingCard(Map<String, dynamic> reading) {
    final bmi = reading['bmi'] as double;
    final weight = reading['weight'] as int;
    final date = reading['recordedAt'] as DateTime;
    final note = reading['note'] as String;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getBmiColor(bmi).withValues(alpha: 0.15),
          child: Text(
            bmi.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: _getBmiColor(bmi),
            ),
          ),
        ),
        title: Text(
          '${_getBmiStatus(bmi)} — $weight kg',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          DateFormat('MMM d, yyyy').format(date) +
              (note.isNotEmpty ? ' • $note' : ''),
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.timeline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No readings yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Update your physical info to start tracking your BMI progress.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:diet_app/models/mood_types.dart';
import 'package:flutter/material.dart';

Future<MoodType?> showMoodPickerSheet(
  BuildContext context, {
  MoodType? selectedMood,
}) {
  return showModalBottomSheet<MoodType>(
    context: context,
    isScrollControlled: false,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => MoodPickerSheet(selectedMood: selectedMood),
  );
}

class MoodPickerSheet extends StatefulWidget {
  const MoodPickerSheet({super.key, this.selectedMood});

  final MoodType? selectedMood;

  @override
  State<MoodPickerSheet> createState() => _MoodPickerSheetState();
}

class _MoodPickerSheetState extends State<MoodPickerSheet> {
  MoodType? _selectedMood;

  static const Map<MoodType, String> _descriptions = {
    MoodType.neutral: 'Balanced and steady',
    MoodType.happy: 'Positive and bright',
    MoodType.surprise: 'Spontaneous or alert',
    MoodType.unpleasant: 'Low, tense, or heavy',
  };

  @override
  void initState() {
    super.initState();
    _selectedMood = widget.selectedMood;
  }

  @override
  Widget build(BuildContext context) {
    final moods = MoodType.values;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'How are you feeling?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: moods.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.25,
              ),
              itemBuilder: (context, index) {
                final mood = moods[index];
                return _MoodCard(
                  mood: mood,
                  description: _descriptions[mood] ?? mood.name,
                  selected: _selectedMood == mood,
                  onTap: () {
                    setState(() => _selectedMood = mood);
                    Navigator.of(context).pop(mood);
                  },
                );
              },
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: const Text('No thanks — skip mood'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodCard extends StatelessWidget {
  const _MoodCard({
    required this.mood,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final MoodType mood;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(MoodTypeConfig.colorValues[mood] ?? 0xFF546E7A);
    final label = MoodTypeConfig.displayLabels[mood] ?? mood.name;

    return Semantics(
      label: '$label. $description. Double tap to select.',
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.12) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? color : Colors.grey.withValues(alpha: 0.18),
              width: selected ? 1.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
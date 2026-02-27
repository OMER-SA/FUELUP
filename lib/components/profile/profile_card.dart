import 'package:diet_app/utilities/constants.dart';
import 'package:flutter/material.dart';

class ProfileCard extends StatelessWidget {
  final String name, title;
  final IconData icon;
  final void Function() btnPressed;

  const ProfileCard({
    super.key,
    required this.name,
    required this.title,
    required this.icon,
    required this.btnPressed,
  });

  @override
  Widget build(BuildContext context) {
    final DefaultColors defaultColor = DefaultColors();
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 24, color: defaultColor.primaryColor),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 4),
                  Text(
                    name,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.edit, color: defaultColor.primaryColor),
              onPressed: btnPressed,
            ),
          ],
        ),
      ),
    );
  }
}

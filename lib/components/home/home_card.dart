import 'package:diet_app/utilities/constants.dart';
import 'package:flutter/material.dart';

class HomeCard extends StatelessWidget {
  final String image;
  final String title;
  final String description;
  final Function onClick;

  const HomeCard(
      {super.key,
      required this.image,
      required this.title,
      required this.description,
      required this.onClick});

  @override
  Widget build(BuildContext context) {
    DefaultColors defaultColors = DefaultColors();

    return Card(
      color: defaultColors.secondaryColor,
      elevation: 0.0,
      child: InkWell(
        onTap: () {
          onClick();
        },
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Container(
            alignment: Alignment.center,
            child: Column(
              children: [
                Image.network(
                  image,
                  fit: BoxFit.cover,
                ),
                const SizedBox(
                  height: 15,
                ),
                Column(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                        textAlign: TextAlign.center,
                        style: TextStyle(color: defaultColors.maroonColor),
                        description),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

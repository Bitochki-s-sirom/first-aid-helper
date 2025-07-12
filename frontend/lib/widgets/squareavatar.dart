import 'package:flutter/material.dart';
import '../colors/colors.dart';

class SquareAvatarWithFallback extends StatelessWidget {
  final String imageUrl;
  final String name;
  final double size;

  const SquareAvatarWithFallback({
    Key? key,
    required this.imageUrl,
    required this.name,
    this.size = 70,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: kSidebarActiveColor,
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.hardEdge,
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        },
      ),
    );
  }
}

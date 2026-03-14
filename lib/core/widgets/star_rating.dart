import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  final double rating;
  final double size;
  final Color filledColor;
  final Color emptyColor;
  final void Function(int)? onRatingChanged;
  final bool interactable;

  const StarRating({
    super.key,
    required this.rating,
    this.size = 24.0,
    this.filledColor = const Color(0xFF69F0AE), // Emerald
    this.emptyColor = Colors.white30,
    this.onRatingChanged,
    this.interactable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: interactable
              ? () {
                  if (onRatingChanged != null) {
                    onRatingChanged!(index + 1);
                  }
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.only(right: 2.0),
            child: _buildStar(index),
          ),
        );
      }),
    );
  }

  Widget _buildStar(int index) {
    IconData icon;
    Color iconColor = emptyColor;

    if (index >= rating) {
      icon = Icons.star_border_rounded;
    } else if (index >= rating - 0.75 && index < rating) {
      icon = Icons.star_half_rounded;
      iconColor = filledColor;
    } else {
      icon = Icons.star_rounded;
      iconColor = filledColor;
    }

    return Icon(
      icon,
      color: iconColor,
      size: size,
    );
  }
}

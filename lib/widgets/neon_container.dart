import 'package:flutter/material.dart';

class NeonContainer extends StatelessWidget {
  final Widget child;
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final double shadowIntensity;
  final Color backgroundColor;

  const NeonContainer({
    Key? key,
    required this.child,
    required this.borderColor,
    this.borderWidth = 1.5,
    this.borderRadius = 16.0,
    this.shadowIntensity = 0.6,
    this.backgroundColor = Colors.transparent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(shadowIntensity * 0.2),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius - borderWidth),
        child: child,
      ),
    );
  }
}
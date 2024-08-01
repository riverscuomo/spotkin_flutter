import 'package:flutter/material.dart';
import 'package:spotkin_flutter/widgets/quantity_circle.dart';

class SettingsRowTitle extends StatelessWidget {
  const SettingsRowTitle(
    this.title,
    this.quantity,
  );

  final String title;
  final int quantity;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title),
        const SizedBox(width: 8),
        QuantityCircle(quantity: quantity),
      ],
    );
  }
}

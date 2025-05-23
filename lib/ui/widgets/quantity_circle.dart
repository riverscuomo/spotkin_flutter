import 'package:flutter/material.dart';

class QuantityCircle extends StatelessWidget {
  const QuantityCircle({
    super.key,
    required this.quantity,
  });

  final int quantity;

  @override
  Widget build(BuildContext context) {
    if (quantity == 0) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$quantity',
        style: const TextStyle(
          color: Colors.black,
          fontSize: 12,
        ),
      ),
    );
  }
}

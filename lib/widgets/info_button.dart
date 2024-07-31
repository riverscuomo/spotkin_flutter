import 'package:flutter/material.dart';
import 'package:spotkin_flutter/app_core.dart';

class InfoButton extends StatelessWidget {
  const InfoButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.info),
      onPressed: () {
        showInfoBottomSheet(context);
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'spotkin_info_content.dart';

class CustomBottomSheet extends StatelessWidget {
  final Widget title;
  final List<Widget> content;
  final double initialChildSize;
  final double minChildSize;
  final double maxChildSize;
  final bool showImage;

  const CustomBottomSheet({
    Key? key,
    required this.title,
    required this.content,
    this.initialChildSize = 0.9,
    this.minChildSize = 0.5,
    this.maxChildSize = 0.9,
    this.showImage = false,
  }) : super(key: key);

  static Future<void> show({
    required BuildContext context,
    required Widget title,
    required List<Widget> content,
    double initialChildSize = 0.9,
    double minChildSize = 0.5,
    double maxChildSize = 0.9,
    showImage = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return CustomBottomSheet(
          title: title,
          content: content,
          initialChildSize: initialChildSize,
          minChildSize: minChildSize,
          maxChildSize: maxChildSize,
          showImage: showImage,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      builder: (_, controller) {
        return Column(
          children: [
            Container(
              height: 5,
              width: 40,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: DefaultTextStyle(
                style: Theme.of(context).textTheme.titleLarge!,
                child: title,
              ),
            ),
            showImage
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Image.asset(
                      'assets/images/spotkin.jpg',
                      fit: BoxFit.cover,
                    ),
                  )
                : const SizedBox(),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: content.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: content[index],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

void showInfoBottomSheet(BuildContext context) {
  CustomBottomSheet.show(
    context: context,
    title: const Text('About Spotkin'),
    content: infoSheetContent,
    showImage: true,
  );
}

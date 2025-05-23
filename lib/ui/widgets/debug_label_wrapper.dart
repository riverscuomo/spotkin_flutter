import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Global flag to enable/disable debug labels
bool showDebugLabels = kDebugMode;

/// A simple debug overlay system that adds small text labels
/// to widgets without interfering with layout or hit testing.
class DebugLabelWrapper extends StatelessWidget {
  final Widget child;
  final String widgetName;
  
  const DebugLabelWrapper({
    Key? key,
    required this.child,
    required this.widgetName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Only show debug labels when enabled and in debug mode
    if (!kDebugMode || !showDebugLabels) {
      return child;
    }
    
    // Use a simpler approach with decoration
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red, width: 1),
      ),
      child: Stack(
        children: [
          child,
          Positioned(
            left: 0,
            top: 0,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                color: Colors.red.withOpacity(0.7),
                child: Text(
                  widgetName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Extension method to easily wrap widgets with debug labels
extension DebugLabelExtension on Widget {
  Widget withDebugLabel(String widgetName) {
    // Skip labeling if not in debug mode
    if (!kDebugMode || !showDebugLabels) {
      return this;
    }
    return DebugLabelWrapper(
      widgetName: widgetName,
      child: this,
    );
  }
}

/// Function to toggle debug labels on/off
void toggleDebugLabels() {
  showDebugLabels = !showDebugLabels;
}

import 'package:flutter/material.dart';

/// A widget that displays a placeholder for unsupported file types.
///
/// This widget is used when a file type is unknown or unsupported,
/// and it displays a message that the preview is not available.
/// It can be used in scenarios where the application needs to
/// handle unsupported file formats gracefully.
class UnsupportedFilePreview extends StatelessWidget {
  /// Creates an [UnsupportedFilePreview] widget.
  ///
  /// This constructor doesn't require any parameters.
  /// It simply returns a widget
  /// that displays a placeholder message indicating that the preview
  ///  is not available.
  const UnsupportedFilePreview({super.key});

  /// Builds the UI for the unsupported file preview.
  ///
  /// This method returns a [Center] widget containing a
  /// [Container] with a message displayed in the center.
  /// The message indicates that the file type is unsupported.
  ///
  /// The [Container] has a fixed width and height, a light grey background, and
  /// a border to visually distinguish it from other elements on the screen.
  ///
  /// Returns:
  /// A [Widget] containing the unsupported file preview.
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[200], // Light grey background
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey),
        ),
        child: const Center(
          child: Text(
            'Preview Not Available',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
        ),
      ),
    );
  }
}

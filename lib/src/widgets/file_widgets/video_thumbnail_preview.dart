import 'package:flutter/material.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:jsonschema_form/src/utils/string_extension.dart';
import 'package:jsonschema_form/src/widgets/file_widgets/app_image.dart';
import 'package:jsonschema_form/src/widgets/file_widgets/unsupported_file_preview.dart';

/// A widget to display a video player and its thumbnail for preview.
///
/// This widget takes an [XFile] and generates a thumbnail for the video.
/// Once the thumbnail is generated,
/// it is displayed using the [AppImage] widget.
class VideoThumbnailPreview extends StatelessWidget {
  /// Creates a new [VideoThumbnailPreview] for the provided [path].
  ///
  /// The [path] parameter is required and represents
  /// the video file to be previewed.
  const VideoThumbnailPreview({
    required this.path,
    super.key,
    this.width,
  });

  /// This file will be used to generate a thumbnail or to play the video
  /// if necessary.
  final String path;

  /// The width of the image to be displayed.
  /// If null, the width will be automatically
  /// adjusted based on the parent widget's constraints.
  final double? width;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: generateThumbnail(path), // Call to generate the thumbnail
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show loading spinner while thumbnail is being generated
          return const CircularProgressIndicator();
        } else if (snapshot.hasData) {
          // Display the generated thumbnail
          return AppImage(
            imageData: snapshot.data!,
            width: width,
          );
        } else {
          // If no thumbnail is generated
          return const UnsupportedFilePreview();
        }
      },
    );
  }

  /// Generates a thumbnail for the given video file.
  ///
  /// The method uses the [VideoThumbnail] package to generate a thumbnail
  /// from the video file and returns an [String] containing the thumbnail image.
  Future<String> generateThumbnail(String path) async {
    var thumbnailPath = path;
    if (path.isValidUrl) {
      // Generate the thumbnail and store it in a temporary in-memory URL
      final file = await path.urlMediaToFile();
      thumbnailPath = file?.path ?? '';
    }
    // Generate the thumbnail using the video file
    final fileName = await VideoThumbnail.thumbnailData(
      video: thumbnailPath,
      maxWidth: 128, // Specify the maximum width for the thumbnail
      quality: 25, // Specify the quality of the thumbnail
    );

    // Return the generated thumbnail as an XFile
    return XFile.fromData(fileName).path;
  }
}

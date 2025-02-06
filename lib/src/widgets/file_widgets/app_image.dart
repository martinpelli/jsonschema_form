import 'dart:convert';
import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jsonschema_form/src/utils/string_extension.dart';

/// A custom image widget that handles different types of images including
/// network images, base64 images, SVG images, and local assets.
///
/// You can provide a base64 string, an SVG asset, or a network URL.
/// It also supports placeholders for loading or failed images.
///
/// The widget offers flexibility with optional parameters:
/// - [width], [height]: Define the size of the image.
/// - [fit]: Define how the image should be fitted within the given size.
/// - [color]: Apply a color filter to the image.
/// - [placeholder]: Provide a local asset path for a placeholder image.
/// - [placeholderWidget]: Provide a custom widget to show as a placeholder.
class AppImage extends StatelessWidget {
  /// Constructor for [AppImage],
  /// which supports different types of image sources.
  ///
  /// - [imageData]: A string representing the image,
  /// which can be a network URL, base64 encoded string, or asset path.
  /// - Optional parameters: [width], [height], [fit], [color],
  ///  [package], [placeholder], [placeholderWidget].
  const AppImage({
    required this.imageData,
    super.key,
    this.width,
    this.height,
    this.fit,
    this.color,
    this.package,
    this.placeholder,
    this.placeholderWidget,
  });

  /// The data representing the image, which can be a network URL,
  /// base64 string, or asset path.
  final String imageData;

  /// Optional width of the image.
  final double? width;

  /// Optional height of the image.
  final double? height;

  /// How the image should be fitted within the container
  /// (e.g., [BoxFit.contain]).
  final BoxFit? fit;

  /// Color filter to apply to the image.
  final Color? color;

  /// Optional package name to load assets from a package.
  final String? package;

  /// Optional path to a placeholder image (e.g., 'assets/placeholder.png').
  final String? placeholder;

  /// Optional widget to display as a placeholder or in case of error.
  final Widget? placeholderWidget;

  @override
  Widget build(BuildContext context) {
    // Check if the image is an SVG by looking at the file extension
    final isSvgImage = imageData.split('.').last == 'svg';

    // If the imageData is empty, show the placeholder widget or
    // load the placeholder asset.
    if (imageData.isEmpty) {
      return _getPlaceholderWidget();
    }

    // Check if the image is base64 encoded
    final isBase64 = imageData.isBase64();

    // Handle local image paths (e.g., assets or file paths)
    if (!imageData.contains('http') && !isBase64) {
      return loadLocalAsset(imageData);
    }

    // Handle SVG images
    if (isSvgImage) {
      return SvgPicture.network(
        imageData,
        width: width,
        height: height,
        fit: fit ?? BoxFit.contain,
        colorFilter: color != null
            ? ColorFilter.mode(
                color!,
                BlendMode.srcIn,
              )
            : null,
        placeholderBuilder: (context) {
          return _getPlaceholderWidget();
        },
      );
    }
    // Handle base64 encoded images
    else if (isBase64) {
      return Base64ImageWidget(
        base64String: imageData,
        width: width,
        height: height,
        fit: fit,
        placeholderWidget: _getPlaceholderWidget(),
      );
    }
    // Handle network images
    else {
      return ExtendedImage.network(
        imageData,
        width: width,
        height: height,
        fit: fit,
        color: color,
        loadStateChanged: (state) {
          switch (state.extendedImageLoadState) {
            case LoadState.completed:
              return state.completedWidget;
            case LoadState.failed || LoadState.loading:
              return _getPlaceholderWidget();
          }
        },
      );
    }
  }

  Widget _getPlaceholderWidget() {
    if (placeholderWidget != null) {
      return placeholderWidget!;
    } else if (placeholder != null) {
      return loadLocalAsset(
        placeholder!,
      );
    } else {
      return const SizedBox();
    }
  }

  /// Load a local asset image or file.
  ///
  /// This method checks if the [imageData] is an SVG or a valid file path,
  /// and returns the appropriate widget.
  Widget loadLocalAsset(String imageData) {
    final isSvgImage = imageData.split('.').last == 'svg';

    // If it's an SVG image, load it using SvgPicture
    if (isSvgImage) {
      return SvgPicture.asset(
        imageData,
        width: width,
        height: height,
        fit: fit ?? BoxFit.contain,
        colorFilter: color != null
            ? ColorFilter.mode(
                color!,
                BlendMode.srcIn,
              )
            : null,
        package: package,
      );
    }

    // Handle Android-specific case where file might be loaded
    //from local storage
    if (TargetPlatform.android == defaultTargetPlatform) {
      final file = File(imageData);
      if (file.existsSync()) {
        return Image.file(
          File(imageData),
          width: width,
          height: height,
          fit: fit,
          color: color,
        );
      }
    }

    // If the image data is an asset, load the image using Image.asset
    if (imageData.startsWith('assets')) {
      return Image.asset(
        imageData,
        width: width,
        height: height,
        fit: fit,
        color: color,
        package: package,
      );
    }

    // Default to showing the placeholder widget if no conditions are met
    return placeholderWidget ??
        ((placeholder != null)
            ? loadLocalAsset(
                placeholder!,
              )
            : const SizedBox());
  }
}

/// A widget that displays an image from a base64-encoded string.
class Base64ImageWidget extends StatelessWidget {
  /// Constructor for [Base64ImageWidget] to accept a base64 string and
  /// optional parameters for image size and fit.
  ///
  /// The [base64String] is required, and the widget will try to display the
  /// image from this base64 string.
  /// You can also specify optional parameters:
  /// - [width] and [height] to define the size of the image.
  /// - [fit] to define how the image should be scaled to fit the given
  /// dimensions (defaults to [BoxFit.cover]).
  /// - [placeholderWidget] is optional and will be shown
  /// if the base64 string is invalid.
  const Base64ImageWidget({
    required this.base64String,
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholderWidget,
  });

  /// The base64-encoded string representing the image.
  final String base64String;

  /// The optional width of the image.
  final double? width;

  /// The optional height of the image.
  final double? height;

  /// The [BoxFit] to use for scaling the image to fit the space.
  /// Defaults to [BoxFit.cover].
  final BoxFit? fit;

  /// An optional widget to show in case the base64 string is invalid
  /// (e.g., placeholder).
  final Widget? placeholderWidget;

  @override
  Widget build(BuildContext context) {
    try {
      // Remove the data URI scheme if it exists (e.g., 'data:image/png;base64,')
      final cleanBase64String = base64String.replaceAll(
        RegExp('^data.*base64,'),
        '',
      );

      // Decode the base64 string into bytes
      final bytes = base64Decode(cleanBase64String);

      // Return an Image widget using the decoded bytes
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
      );
    } catch (e) {
      // If base64 string is invalid, show a placeholder or error message
      return placeholderWidget ?? const Center(child: Text('Invalid Image'));
    }
  }
}

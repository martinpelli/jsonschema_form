/// This enum defines possible values for the UI widget types in a JSON Schema.
///
/// Each option represents a UI feature that can be customized in the schema.
/// These options define behaviors for buttons, file input handling,
/// and file uploads.
enum UiOptions {
  /// If either `items` or `additionalItems` contains a schema object, an "add"
  /// button for adding new items is shown by default. You can turn this off
  /// with the `addable` option in the `uiSchema`.
  addable,

  /// A "remove" button is shown by default for an item if `items` contains
  /// a schema object, or the item is an `additionalItems` instance.
  /// You can turn this off with the `removable` option in the `uiSchema`.
  removable,

  /// Used for file inputs when the `format` is specified in the `jsonSchema`.
  /// This option  can be used to specify particular file extensions to accept.
  /// Multiple extensions can be provided, separated by commas.
  /// For example, `.pdf,.mp4`.
  accept,

  /// Used for file inputs when the `format` is specified in the `jsonSchema`.
  /// If `camera` is set to true, a camera button will appear to allow users
  /// to take a photo or video for file uploading.
  /// If this option is not provided, it will default to false.
  camera,

  /// Used for file inputs when the `format` is specified in the `jsonSchema`.
  /// If `explorer` is set to true, a "choose file" button will appear to allow
  /// users to pick a file from the file explorer.
  /// If this option is not provided, it will default to true.
  explorer,

  /// Used for file inputs when the `format` is specified in the `jsonSchema`.
  /// If `photo` is set to true, the [camera] option will allow users to
  /// take photos. If this option is not provided, it will default to true.
  photo,

  /// Used for file inputs when the `format` is specified in the `jsonSchema`.
  /// If `video` is set to true, the [camera] option will allow users to
  /// take videos. If this option is not provided, it will default  to false.
  video,

  /// Specifies the resolution option for media files (photos and videos).
  /// This option is used to define the resolution settings for capturing media
  /// via camera, e.g., low, high, or max.
  resolution,

  /// Used for building specific inputs, for now only tel is supported.
  inputType;
}

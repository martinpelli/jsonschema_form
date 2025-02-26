/// This enum defines possible values for the UI widget types in a JSON Schema.
///
/// Each option represents a UI feature that can be customized in the schema.
/// These options define behaviors for buttons, file input handling,
/// and file uploads.
enum UiOptions {
  /// If either `items` or `additionalItems` contains a schema object, an "add"
  /// button for adding new items is shown by default.
  /// You can turn this off with the `addable` option set to false in the
  /// `uiSchema`.
  addable,

  /// If either `items` or `additionalItems` contains a schema object, a
  /// "remove" button is shown by default.
  /// You can turn this off with the `removable` option set to false in the
  /// `uiSchema`.
  removable,

  /// If either `items` or `additionalItems` contains a schema object, you can
  /// wrap array items in an ExpansionTile so they don't take too much space
  /// You can turn this on with the `expandable` option set to true in the
  /// `uiSchema`.
  ///
  /// This property must be provided inside 'items' property in UiSchema in
  /// order to work
  expandable,

  /// If either `items` or `additionalItems` contains a schema object, this can
  /// be used to change the way an array item is created. Posible options are
  /// 'dialog', 'screen' and 'inner'. Default to inner.
  ///
  /// This property must be provided inside 'items' property in UiSchema in
  /// order to work
  createArrayItemAs,

  /// If either `items` or `additionalItems` contains a schema object, this can
  /// be used to change the way an array item is edited. Posible options are
  /// 'dialog', 'screen' and 'inner'. Default to dialog if expandable is true.
  ///
  /// This property only has effect if expandable is true.
  ///
  /// This property must be provided inside 'items' property in UiSchema in
  /// order to work
  editArrayItemAs,

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
  inputType,

  /// Used for indicating if widget should align children vertically or
  /// horizontally.
  /// This only applies when ui:widget is radio or checkbox
  inline;
}

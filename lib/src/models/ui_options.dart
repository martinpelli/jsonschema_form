/// This enum defines possible values for the ui widgets types in jsonSchema
enum UiOptions {
  /// If either items or additionalItems contains a schema object, an add button
  ///  for new items is shown by default. You can turn this off with the addable
  ///  option in uiSchema
  addable,

  /// A remove button is shown by default for an item if items contains a schema
  /// object, or the item is an additionalItems instance. You can turn this off
  /// with the removable option in uiSchema:
  removable,

  /// Used for files when format is specified in jsonSchema. It can be used for
  /// specifiying particular files extensions to accept
  /// To specify more than one extension use ,
  /// Fo rexzample '.pdf,.mp4'
  accept,

  /// Used for files when format is specified in jsonSchema. If it is true then
  /// a camera button will apear to take a photo/video for file uploading.
  /// If is not provided then it will be taken as false
  camera,

  /// Used for files when format is specified in jsonSchema. If it is true then
  /// a choose file button will apear to pick a file from explorer.
  /// If is not provided then it will be taken as true
  explorer,

  /// Used for files when format is specified in jsonSchema. If it is true then
  /// a [camera] option will allow photos
  /// If is not provided then it will be taken as true
  photo,

  /// Used for files when format is specified in jsonSchema. If it is true then
  /// a [camera] option will allow videos
  /// If is not provided then it will be taken as false
  video,

  /// Used for building specific inputs, for now only tel is supported.
  inputType;
}

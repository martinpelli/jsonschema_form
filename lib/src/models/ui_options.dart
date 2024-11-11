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
}

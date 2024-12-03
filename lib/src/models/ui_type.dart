/// This enum defines possible values for the ui widgets types in jsonSchema
enum UiType {
  /// Represents a TextFormField in Flutter
  text,

  /// Represents a TextFormField with multiple lines in Flutter
  textarea,

  /// Represents a numeric TextFormField in Flutter
  updown,

  /// Represents a DropdownMenu in Flutter
  select,

  /// Represents a RadioListTile in Flutter
  radio,

  /// Represents a CheckboxListTile in Flutter
  checkboxes,

  /// Represents a TextFormField with selectable datetime in Flutter
  dateTime,

  /// Represents a TextFormField with selectable date in Flutter
  date,

  /// Represents a Mix of Widget that lets the user select a file in Flutter
  file;
}

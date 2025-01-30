/// Possible values of inputTypes in ui:options field at uiSchema
enum InputType {
  /// Used to build an telephone input
  tel;
}

/// Map used for json parsing InputType objects
const $InputTypeFromJson = {
  'tel': InputType.tel,
};

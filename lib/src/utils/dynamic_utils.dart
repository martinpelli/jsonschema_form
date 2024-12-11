/// Utility class for working with dynamic types, particularly when handling
/// complex structures like `List<Map<String, dynamic>>`.
class DynamicUtils {
  /// Checks whether a given dynamic value is a list of objects
  /// (`List<Map<String, dynamic>>`) and casts it safely.
  ///
  /// This method is particularly useful when working with dynamically-typed
  /// data (e.g., data from JSON parsing or external sources) where you need
  /// to ensure the list elements are of type `Map<String, dynamic>`.
  ///
  /// ## Example
  /// ```dart
  /// dynamic data = [
  ///   {'key': 'value'},
  ///   {'anotherKey': 'anotherValue'}
  /// ];
  ///
  /// final list = DynamicUtils.tryParseListOfMaps(data);
  /// if (list != null) {
  ///   print(list); // Safe to use as a List<Map<String, dynamic>>
  /// } else {
  ///   print('Not a valid list of objects.');
  /// }
  /// ```
  ///
  /// ## Parameters
  /// - [value]: The dynamic value to check and potentially cast.
  ///
  /// ## Returns
  /// - A `List<Map<String, dynamic>>` if the value is a `List` where all
  ///  elements are `Map<String, dynamic>`.
  /// - `null` if the value does not meet the criteria.
  ///
  /// ## Notes
  /// - If the list is empty, it returns `null` because there's no way to
  ///   validate the type of its elements.
  /// - The method performs a safe cast and returns a new typed list.
  ///
  /// ## Limitations
  /// - This method does not deeply inspect nested structures within the
  ///   `Map<String, dynamic>` objects.
  static List<Map<String, dynamic>>? tryParseListOfMaps(dynamic value) {
    if (isListOfMaps(value)) {
      return (value as List).cast<Map<String, dynamic>>();
    }

    return null;
  }

  /// Checks if a dynamic value is a list of maps of type <String, dynamic>
  static bool isListOfMaps(dynamic value) {
    if (value is List) {
      for (final item in value) {
        if (item is! Map<String, dynamic>) {
          return false;
        }
      }
      return value.isNotEmpty;
    }
    return false;
  }
}

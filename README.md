# Jsonschema Form

`jsonschema_form` is a Flutter package designed for developers to dynamically build forms using jsonSchema, uiSchema and formData. These three objects are needed to build the form and they are tipically provided by backend. It simplifies decoding schemas pre-populating forms and building them dynamically.

## Features ✨
- **Dynamic Form Creation**: Automatically generate forms from a JSON schema.
- **Customizable UI**: Use a UI schema for tailored form styling.
- **Pre-Populated Data**: Initialize forms with pre-existing data and update as needed.
- **Dependencies**: Build fields that depends on values from others. For exampe show an input if a radio button is marked as true.
- **File support**: Allows the user to select a file from storage or take a photo/video
- **Array support**: Allows arrays with items that can be added or removed dynamically by user

## Current Package Status ⚠️

This package is currently under development in a very early development stage. The plan is to publish it on [pub.dev](https://pub.dev/).
- **JsonSchema** is a model class that tells the form how it should be built. The currently *json* supported properties for now are:
    - **title**: A human-readable name or label for a particular schema or field. It’s often displayed as the label or header when generating forms based on the schema.
    - **description**: Is shown above each field if is not null, providing neccessary information if needed.
    - **default**: Is the default value that this field takes. If there is data present on the corresponding formData property, this is ignored.
    - **type**: Defines the data type of a field or schema element. Possible types include "string", "number", "integer", "boolean", "array" and "object". It tells the UI what kind of input widget needs to be rendered.
    - **requiredFields**: A list of required fields, is composed by the key properties that corresponds to the jsonSchema. If a jsonKey is required then the form cannot be submitted if there is no value in the corresponding field.
    - **properties**: When type is "object", properties is used to define the schema for each of the fields within that object. Each key in properties is a jsonKey and the value is the schema for that field.
    - **enum**: Allows to specify a fixed set of acceptable values for a field, effectively creating a dropdown or selection list in form-based UIs. It’s used to restrict the possible values for a field.
    - **const**: Used to specify that a field must have a single specific value. It’s useful when a field needs a fixed value.
    - **dependencies**: Allows to define conditional logic within the schema, where certain fields are required or change their validation based on the presence or value of another field. Dependencies can work in two ways: *Schema dependencies*: Where certain fields are only required or validated if another field exists. *Property dependencies*: Where certain fields are only required if another field has a specific value.
    - **items**: Items is only present when type is equal to array. The form generated will have fields that allow users to enter multiple entries, essentially creating a dynamic list of inputs. If additionalItems is null then the type of items will be JsonSchema. If additionalItems is not null then the type of items will be Array.
    - **additionalItems**: When is not null, then items will be an array of items. Form will show those items by default and pressing add button will build a new schema provided by additionalItems.
    - **minItems**: If type is array and needs to be populated, minItems can specify the minimum number of items that the array must have.
    - **maxItems**: If type is array and needs to be populated, maxItems can specify the maximum number of items that the array can have.
    - **uniqueItems**: If type is array and uniqueItems is set to true, all items from the array follows the same schema.
    - **oneOf**: A way to define conditional schemas where only one of multiple schemas must be valid, depending on specific conditions. When dependencies is used with oneOf, it enables conditional logic based on the fields in the JSON data, allowing the schema to adapt according to certain field value.
    - **format**: Allows to define specific format for some scenarios. If format is data-url a file upload form is built. If format is email, the TextFormField is adapted to an email input.
    - **minLength**: When the type is string this will be used as the minimum length user can enter in a TextFormField.
    - **maxLength**: When the type is string this will be used as the maximum length user can enter in a TextFormField.
    - **readOnly**: If it is true then this field can't be modified. This is an alternative to readonly from uiSchema.

- **UiSchema** is a model class that tells the form how it should looks like. The currently *json* supported properties for now are:
    - **ui:widget**: Defines the type of widget to be used for the given key.
    - **ui:autofocus**: Automatically focus on a text input or textarea input when is true.
    - **ui:emptyValue**: Provides the default value to use when an input for a field is empty.
    - **ui:placeholder**: Add placeholder text to an input
    - **ui:title**: The title of a field. If this is null, jsonSchema.title will be used and if jsonSchema.title is null the jsonKey will be used as title. 
    - **ui:description**: Sometimes it's convenient to change the description of a field. This will be shown as a Text widget above the field.
    - **ui:help**: Provides a brief description under the field for helping de user.
    - **ui:readonly**: If the field is an input and readonly is true then the input can't be modified.
    - **ui:options**: Defines options to be used for the given key, for instance: if options is { removable: false } then this indicates user can't delete items from array. See [UiOptons] enum class to see all available options.
    - **ui:maxLines**: Indicates the maximum amount of lines that a TextFormField can have, this is only useful when [ui:widget] is text. If this value is null then 1 is used as default. If 0 is provided this value is infinite, which means that user can add as much lines as he wants
    - **ui:order**: Defines the order in which fields should be displayed
    - **ui:showArrayTitles**: If the jsonSchema type is array, this property is true by default. Pass false if you want to avoid a title with a divider on each array item.
 
### TODOs:
- Add AllOf and AnyOff support to Json Schema
- Widgets need to be reused in OneOf
- Support referencing for reusable form definitions
- Localize error messages
- upDown widget is not correctly implemented yet
- Live Demo to showcase the package

## Installation 💻

As is not yet published at [pub.dev](https://pub.dev/). Install modifying your *pubspec.yaml* file. Add these lines:

```sh
  jsonschema_form:
    git:
      url: https://github.com/martinpelli/jsonschema_form.git
      ref: stable
```

---

## Usage 🕹️

### Import the package 📦

```sh
import 'package:jsonschema_form/jsonschema_form.dart';
```

### Initializing a JsonSchemaForm class 🎬

#### From Decoded JSON

```sh
final form = JsonschemaForm(
 "jsonSchema": {...}, // your jsonSchema coming from API
  "uiSchema": {...},  // your uiSchema coming from API
  "formData": {...},  // your formData coming from API
);
```

### Build the form 🚀

```sh
JsonschemaFormBuilder(
      jsonSchemaForm: jsonschemaForm, //Previously initialized JsonschemaForm class
      },
    );
```

---


[very_good_ventures_link_light]: https://verygood.ventures#gh-light-mode-only
[very_good_ventures_link_dark]: https://verygood.ventures#gh-dark-mode-only
[very_good_workflows_link]: https://github.com/VeryGoodOpenSource/very_good_workflows

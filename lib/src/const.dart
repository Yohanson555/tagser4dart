part of tagser;

const TYPE_TAG = 'tag';
const TYPE_TEXT = 'text';

const CHAR_BACK_SLASH = 92; // \
const CHAR_SLASH = 47; // /
const CHAR_ENTER = 10; // '\n'
const CHAR_SPACE = 32; // ' '
const CHAR_OPEN_BRACKET = 60; // <
const CHAR_CLOSE_BRACKET = 62; // >
const CHAR_UNDERSCORE = 95; // _
const CHAR_QUOTE = 34; // "
const CHAR_SINGLE_QUOTE = 39; // '
const CHAR_EQUAL = 61; // =
const CHAR_EXCL_MARK = 33; // !
const CHAR_EOS = -1; // end of source

const NOTIFY_TAG_NAME_RESULT = 1;
const NOTIFY_ATTR_RESULT = 2;
const NOTIFY_CLOSE_BRACKET_FOUND = 3;
const NOTIFY_TAG_RESULT = 4;
const NOTIFY_SLASH_FOUND = 5;
const NOTIFY_CLOSE_TAG_FOUND = 6;
const NOTIFY_ATTR_NAME_RESULT = 7;
const NOTIFY_ATTR_VALUE_RESULT = 8;
const NOTIFY_CLOSE_TAG = 9;

const ERROR_WRONG_TAG_CHARACTER = 1;
const ERROR_EMPTY_TAG_NAME = 2;
const ERROR_TAG_MALFORMED = 3;
const ERROR_WRONG_CHARACTER_GIVEN = 4;
const ERROR_SOURCE_DOCUMENT_MALFORMED = 5;
const ERROR_WRONG_CLOSE_TAG = 6;
const ERROR_ATTR_NAME_EMPTY = 7;
const ERROR_ATTR_VALUE_EMPTY = 8;
const ERROR_ATTR_VALUE_MALFORMED = 9;
const ERROR_UNEXPECTED_EOS = 10;
const ERROR_END_OF_TAG = 11;

const messages = {
  ERROR_WRONG_TAG_CHARACTER: "Wrong tag name character: {{char}}",
  ERROR_EMPTY_TAG_NAME: "Empty tag name",
  ERROR_TAG_MALFORMED: "Tag malformed",
  ERROR_WRONG_CHARACTER_GIVEN: "Wrong character given: \"{{char}}\". \"{{await}}\" awaits",
  ERROR_SOURCE_DOCUMENT_MALFORMED: "Source document malformed",
  ERROR_WRONG_CLOSE_TAG: "Wrong close tag: {{tag}}",
  ERROR_ATTR_NAME_EMPTY: "Attribute malformed: empty name",
  ERROR_ATTR_VALUE_EMPTY: "Attribute malformed: empty value",
  ERROR_ATTR_VALUE_MALFORMED: "Attribute value malfromed: the attribute value should be a string",
  ERROR_UNEXPECTED_EOS: "Unexpected end of source",
  ERROR_END_OF_TAG: "Unexpected end of tag \"{{tag}}\" ({{line}}:{{symbol}})",
};


String getError(int code, Map values) {
  var message = messages[code];

  if (message.isNotEmpty) {
    if (values != null && values.isNotEmpty) {
      values.forEach((k,v) {
        message = message.replaceAll('{{$k}}', v.toString());
      });
    }
  }

  return message ?? '';
}

part of tagser;

const typeTag = 'tag';
const typeText = 'text';

const charBackSlash = 92; // \
const charSlash = 47; // /
const charEnter = 10; // '\n'
const charSpace = 32; // ' '
const charOpenBracket = 60; // <
const charCloseBracket = 62; // >
const charUnderscore = 95; // _
const charQuote = 34; // "
const charSingleQuote = 39; // '
const charEqual = 61; // =
const charExclMark = 33; // !
const charEos = -1; // end of source

const notifyTagNameResult = 1;
const notifyAttrResult = 2;
const notifyCloseBracketFound = 3;
const notifyTagResult = 4;
const notifySlashFound = 5;
const notifyCloseTagFound = 6;
const notifyAttrNameResult = 7;
const notifyAttrValueResult = 8;
const notifyCloseTag = 9;

const errorWrongTagCharacter = 1;
const errorEmptyTagName = 2;
const errorTagMalformed = 3;
const errorWrongCharacterGiven = 4;
const errorSourceDocumentMalformed = 5;
const errorWrongCloseTag = 6;
const errorAttrNameEmpty = 7;
const errorAttrValueEmpty = 8;
const errorAttrValueMalformed = 9;
const errorUnexpectedEos = 10;
const errorEndOfTag = 11;

const messages = {
  errorWrongTagCharacter: "Wrong tag name character: {{char}}",
  errorEmptyTagName: "Empty tag name",
  errorTagMalformed: "Tag malformed",
  errorWrongCharacterGiven:
      "Wrong character given: \"{{char}}\". \"{{await}}\" awaits",
  errorSourceDocumentMalformed: "Source document malformed",
  errorWrongCloseTag: "Wrong close tag: {{tag}}",
  errorAttrNameEmpty: "Attribute malformed: empty name",
  errorAttrValueEmpty: "Attribute malformed: empty value",
  errorAttrValueMalformed:
      "Attribute value malfromed: the attribute value should be a string",
  errorUnexpectedEos: "Unexpected end of source",
  errorEndOfTag: "Unexpected end of tag \"{{tag}}\" ({{line}}:{{symbol}})",
};

String getError(int code, Map? values) {
  var message = messages[code];

  if (message != null &&
      message.isNotEmpty &&
      values != null &&
      values.isNotEmpty) {
    values.forEach((k, v) {
      message = message!.replaceAll('{{$k}}', v.toString());
    });
  }

  return message ?? '';
}

part of tagser;

class TagserState {
  Map<String, Function> methods = {};

  bool canAcceptMessage(TagserMessage msg) {
    if (msg != null) {
      final messageName = msg.getName();

      if (methods[messageName] != null) {
        return true;
      }
    }

    return false;
  }

  TagserResult processMessage(TagserMessage msg, TagserContext context) {
    if (msg != null) {
      final messageName = msg.getName();

      if (methods[messageName] != null) {
        return methods[messageName](msg, context);
      }
    }

    return null;
  }

  @override
  String toString() {
    return runtimeType.toString();
  }
}

/// ROOT STATE

class RootState extends TagserState {
  List<Tag> tags = [];
  Tag _openedTag;
  String _text;
  bool _escape;
  bool _opened;

  RootState(Tag tag) {
    this._openedTag = tag;

    methods = {
      'process': (msg, context) => process(msg, context),
      'notify': (msg, context) => notify(msg, context),
    };
  }

  @override
  String toString() {
    if (_openedTag != null) {
      return runtimeType.toString() + '(${_openedTag.name})';
    }

    return runtimeType.toString();
  }

  TagserResult process(ProcessMessage msg, TagserContext context) {
    final charCode = msg.charCode;

    _text ??= '';

    if (charCode == CHAR_EOS) {
      if (_openedTag != null) {
        return TagserResult(
          err: TagserError(
            code: ERROR_END_OF_TAG,
            text: getError(ERROR_END_OF_TAG, {
              "tag": _openedTag.name,
              "line": _openedTag.line,
              "symbol": _openedTag.symbol,
            }),
          ),
        );
      }
      _text = _text.trim();

      if (_text.isNotEmpty) {
        tags.add(
          Tag(
              name: '',
              type: TYPE_TEXT,
              body: _text,
              symbol: context.symbol,
              line: context.line),
        );
        _text = '';
      }
    } else if (_opened == true) {
      _opened = false;

      if (TagserUtils.isAvailableCharacter(charCode)) {
        return TagserResult(
          state: TagState(),
          message: InitMessage(
            charCode: charCode,
          ),
        );
      } else if (charCode == CHAR_SLASH) {
        if (_openedTag != null && _openedTag != null) {
          return TagserResult(
            state: CloseTag(_openedTag.name),
            message: InitMessage(
              charCode: charCode,
            ),
          );
        }

        return TagserResult(
            err: TagserError(
                code: ERROR_SOURCE_DOCUMENT_MALFORMED,
                text: getError(ERROR_SOURCE_DOCUMENT_MALFORMED, null)));
      } else {
        return TagserResult(
            err: TagserError(
                code: ERROR_TAG_MALFORMED,
                text: getError(ERROR_TAG_MALFORMED, null)));
      }
    } else if (_escape == true) {
      _text += String.fromCharCode(charCode);
    } else if (charCode == CHAR_BACK_SLASH) {
      _escape = true;
    } else if (charCode == CHAR_OPEN_BRACKET) {
      _opened = true;

      _text = _text.trim();

      if (_text.isNotEmpty) {
        tags.add(
          Tag(
              name: '',
              type: TYPE_TEXT,
              body: _text,
              symbol: context.symbol,
              line: context.line),
        );
        _text = '';
      }
    } else {
      _text += String.fromCharCode(charCode);
    }

    return null;
  }

  TagserResult notify(NotifyMessage msg, TagserContext context) {
    switch (msg.type) {
      case NOTIFY_TAG_RESULT:
        tags.add(msg.value);

        break;
      case NOTIFY_CLOSE_TAG_FOUND:
        return TagserResult(
          pop: true,
          message: NotifyMessage(
            charCode: msg.charCode,
            value: tags,
            type: NOTIFY_CLOSE_TAG,
          ),
        );
      default:
        return null;
    }

    return null;
  }
}

/// TAG STATE

class TagState extends TagserState {
  Tag _tag;

  TagState() {
    methods = {
      'init': (msg, context) => init(msg, context),
      'process': (msg, context) => process(msg, context),
      'notify': (msg, context) => notify(msg, context),
    };
  }

  TagserResult init(InitMessage msg, TagserContext context) {
    return TagserResult(
      state: TagNameState(),
      message: ProcessMessage(charCode: msg.charCode),
    );
  }

  TagserResult process(ProcessMessage msg, TagserContext context) {
    final charCode = msg.charCode;

    if (charCode == CHAR_EOS) {
      return TagserResult(
        err: TagserError(
            code: ERROR_UNEXPECTED_EOS,
            text: getError(ERROR_UNEXPECTED_EOS, null)),
      );
    } else if (TagserUtils.isAvailableCharacter(charCode)) {
      return TagserResult(
        state: AttrState(),
        message: InitMessage(charCode: charCode),
      );
    } else if (charCode == CHAR_SLASH) {
      return TagserResult(
        state: GetCloseBracket(),
      );
    } else if (charCode == CHAR_CLOSE_BRACKET) {
      return TagserResult(
        state: RootState(_tag),
      );
    } else if (charCode == CHAR_SPACE) {
      return null;
    } else {
      return TagserResult(
        err: TagserError(
            code: ERROR_TAG_MALFORMED,
            text: getError(ERROR_TAG_MALFORMED, null)),
      );
    }
  }

  TagserResult notify(NotifyMessage msg, TagserContext context) {
    switch (msg.type) {
      case NOTIFY_TAG_NAME_RESULT:
        final String tagName = msg.value != null ? msg.value.toString() : null;

        _tag = Tag(
            name: tagName,
            type: TYPE_TAG,
            symbol: context.symbol,
            line: context.line);
        return TagserResult(
          message: ProcessMessage(
            charCode: msg.charCode,
          ),
        );

      /*
        return TagserResult(
          err: TagserError(
            code: ERROR_EMPTY_TAG_NAME,
            text: getError(ERROR_EMPTY_TAG_NAME, null),
          ),
        );
        */

      case NOTIFY_ATTR_RESULT:
        _tag.addAttr(msg.value);
        return TagserResult(
          message: ProcessMessage(
            charCode: msg.charCode,
          ),
        );

      case NOTIFY_CLOSE_BRACKET_FOUND:
        return TagserResult(
          pop: true,
          message: NotifyMessage(
            type: NOTIFY_TAG_RESULT,
            value: _tag,
          ),
        );

      case NOTIFY_CLOSE_TAG:
        if (msg.value != null && msg.value is List) {
          (msg.value as List).forEach((t) {
            _tag.addChild(t);
          });
        }

        return TagserResult(
          pop: true,
          message: NotifyMessage(
            type: NOTIFY_TAG_RESULT,
            value: _tag,
          ),
        );
      default:
        return null;
    }
  }
}

/// TAG NAME STATE

class TagNameState extends TagserState {
  String _name = '';

  TagNameState() {
    methods = {
      'process': (msg, context) => process(msg, context),
      //'notify': (msg, context) => notify(msg, context),
    };
  }

  TagserResult process(ProcessMessage msg, TagserContext context) {
    final charCode = msg.charCode;

    if (charCode == CHAR_EOS) {
      return TagserResult(
        err: TagserError(
            code: ERROR_UNEXPECTED_EOS,
            text: getError(ERROR_UNEXPECTED_EOS, null)),
      );
    } else if (TagserUtils.isAvailableCharacter(charCode)) {
      _name += String.fromCharCode(charCode);
    } else if (charCode == CHAR_CLOSE_BRACKET ||
        charCode == CHAR_SPACE ||
        charCode == CHAR_SLASH) {
      return TagserResult(
        pop: true,
        message: NotifyMessage(
          value: _name,
          charCode: charCode,
          type: NOTIFY_TAG_NAME_RESULT,
        ),
      );
    } else {
      return TagserResult(
        err: TagserError(
          code: ERROR_WRONG_TAG_CHARACTER,
          text: getError(
            ERROR_WRONG_TAG_CHARACTER,
            {'char': String.fromCharCode(charCode)},
          ),
        ),
      );
    }

    return null;
  }
}

/// CLOSE TAG STATE

class CloseTag extends TagserState {
  final String tagName;

  CloseTag(this.tagName) {
    methods = {
      'init': (msg, context) => init(msg, context),
      'process': (msg, context) => process(msg, context),
      'notify': (msg, context) => notify(msg, context),
    };
  }

  TagserResult init(InitMessage msg, TagserContext context) {
    return TagserResult(
      state: TagNameState(),
    );
  }

  TagserResult process(ProcessMessage msg, TagserContext context) {
    final charCode = msg.charCode;

    switch (charCode) {
      case CHAR_EOS:
        return TagserResult(
          err: TagserError(
              code: ERROR_UNEXPECTED_EOS,
              text: getError(ERROR_UNEXPECTED_EOS, null)),
        );

      case CHAR_SPACE:
        return null;

      case CHAR_CLOSE_BRACKET:
        return TagserResult(
          pop: true,
          message: NotifyMessage(
            type: NOTIFY_CLOSE_TAG_FOUND,
          ),
        );

      default:
        return null;
    }
  }

  TagserResult notify(NotifyMessage msg, TagserContext context) {
    switch (msg.type) {
      case NOTIFY_TAG_NAME_RESULT:
        String source = tagName;
        String result = msg.value;

        if (context.getOption('ignoreCase') == true) {
          source = source.toLowerCase();
          result = result.toLowerCase();
        }

        if (source != result) {
          return TagserResult(
            err: TagserError(
              code: ERROR_WRONG_CLOSE_TAG,
              text: getError(ERROR_WRONG_CLOSE_TAG, {'tag': msg.value}),
            ),
          );
        }

        return TagserResult(
          message: ProcessMessage(charCode: msg.charCode),
        );

      default:
        return null;
    }
  }
}

/// ATTR STATE

class AttrState extends TagserState {
  String _name;
  String _value;

  AttrState() {
    methods = {
      'init': (msg, context) => init(msg, context),
      'process': (msg, context) => process(msg, context),
      'notify': (msg, context) => notify(msg, context),
    };
  }

  TagserResult init(InitMessage msg, TagserContext context) {
    return TagserResult(
        state: AttrNameState(),
        message: ProcessMessage(charCode: msg.charCode));
  }

  TagserResult process(ProcessMessage msg, TagserContext context) {
    final charCode = msg.charCode;

    if (charCode == CHAR_EOS) {
      return TagserResult(
        err: TagserError(
            code: ERROR_UNEXPECTED_EOS,
            text: getError(ERROR_UNEXPECTED_EOS, null)),
      );
    } else if (charCode == CHAR_EQUAL) {
      return TagserResult(
        state: AttrValueState(),
      );
    }

    return TagserResult(
        pop: true,
        message: NotifyMessage(
            charCode: msg.charCode,
            type: NOTIFY_ATTR_RESULT,
            value: TagAttribute(
              name: _name,
              value: _value ?? 'true',
            )));
  }

  TagserResult notify(NotifyMessage msg, TagserContext context) {
    switch (msg.type) {
      case NOTIFY_ATTR_NAME_RESULT:
        final res = TagserResult();

        _name = msg.value;
        res.message = ProcessMessage(
          charCode: msg.charCode,
        );

        return res;
      case NOTIFY_ATTR_VALUE_RESULT:
        if (msg.value is String && msg.value.isNotEmpty) {
          _value = msg.value;
        } else {
          return TagserResult(
              err: TagserError(
            code: ERROR_ATTR_VALUE_EMPTY,
            text: getError(ERROR_ATTR_VALUE_EMPTY, {}),
          ));
        }

        return null;
      default:
        return null;
    }
  }
}

/// ATTR NAME STATE

class AttrNameState extends TagserState {
  String _name;

  AttrNameState() {
    _name = '';

    methods = {
      'process': (msg, context) => process(msg, context),
    };
  }

  TagserResult process(ProcessMessage msg, TagserContext context) {
    final charCode = msg.charCode;

    if (charCode == CHAR_EOS) {
      return TagserResult(
        err: TagserError(
            code: ERROR_UNEXPECTED_EOS,
            text: getError(ERROR_UNEXPECTED_EOS, null)),
      );
    } else if (TagserUtils.isAvailableCharacter(charCode)) {
      _name += String.fromCharCode(charCode);
    } else {
      return TagserResult(
        pop: true,
        message: NotifyMessage(
          type: NOTIFY_ATTR_NAME_RESULT,
          charCode: charCode,
          value: _name,
        ),
      );
    }

    return null;
  }
}

/// ATTR VALUE STATE

class AttrValueState extends TagserState {
  String _value = '';
  int _quote;
  bool isFirstChar = true;

  AttrValueState() {
    methods = {
      'process': (msg, context) => process(msg, context),
    };
  }

  TagserResult process(ProcessMessage msg, TagserContext context) {
    final charCode = msg.charCode;

    if (charCode == CHAR_EOS) {
      return TagserResult(
        err: TagserError(
            code: ERROR_UNEXPECTED_EOS,
            text: getError(ERROR_UNEXPECTED_EOS, null)),
      );
    } else if (isFirstChar) {
      isFirstChar = false;

      if (charCode == CHAR_QUOTE || charCode == CHAR_SINGLE_QUOTE) {
        _quote = charCode;
      } else {
        return TagserResult(
          err: TagserError(
            code: ERROR_ATTR_VALUE_MALFORMED,
            text: getError(ERROR_ATTR_VALUE_MALFORMED, {}),
          ),
        );
      }
    } else {
      if (charCode == _quote) {
        return TagserResult(
          pop: true,
          message: NotifyMessage(
              type: NOTIFY_ATTR_VALUE_RESULT,
              value: _value,
              charCode: charCode),
        );
      } else {
        _value += String.fromCharCode(charCode);
      }
    }

    return null;
  }
}

/// GET CLOSE BRACKET STATE

class GetCloseBracket extends TagserState {
  GetCloseBracket() {
    methods = {
      'process': (msg, context) => process(msg, context),
    };
  }

  TagserResult process(ProcessMessage msg, TagserContext context) {
    switch (msg.charCode) {
      case CHAR_EOS:
        return TagserResult(
          err: TagserError(
              code: ERROR_UNEXPECTED_EOS,
              text: getError(ERROR_UNEXPECTED_EOS, null)),
        );

      case CHAR_CLOSE_BRACKET:
        return TagserResult(
          pop: true,
          message: NotifyMessage(
            charCode: msg.charCode,
            type: NOTIFY_CLOSE_BRACKET_FOUND,
          ),
        );

      default:
        return TagserResult(
          err: TagserError(
              code: ERROR_WRONG_CHARACTER_GIVEN,
              text: getError(ERROR_WRONG_CHARACTER_GIVEN,
                  {'char': String.fromCharCode(msg.charCode), 'await': '>'})),
        );
    }
  }
}

/// GET SLASH STATE
/*
class GetSlash extends TagserState {
  GetCloseBracket() {
    methods = {
      'process': (msg) => process(msg),
    };
  }

  TagserResult process(ProcessMessage msg) {
    switch (msg.charCode) {
      case CHAR_SLASH:
        return TagserResult(
            pop: true,
            message: NotifyMessage(
              charCode: msg.charCode,
              type: NOTIFY_SLASH_FOUND,
            ));
      default:
        return TagserResult(
            err: TagserError(
                code: ERROR_WRONG_CHARACTER_GIVEN,
                text: getError(ERROR_WRONG_CHARACTER_GIVEN, {
                  'char': String.fromCharCode(msg.charCode),
                  'await': '/'
                })));
    }
  }
}
*/

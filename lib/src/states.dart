part of tagser;

class TagserState {
  Map<String, Function> methods = {};

  bool canAcceptMessage(TagserMessage msg) {
    final messageName = msg.getName();

    if (methods[messageName] != null) {
      return true;
    }

    return false;
  }

  TagserResult? processMessage(TagserMessage msg, TagserContext context) {
    final messageName = msg.getName();

    if (methods[messageName] != null) {
      return methods[messageName]!(msg, context);
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
  Tag? _openedTag;
  String _text = '';
  bool _escape = false;
  bool _opened = false;

  RootState(Tag? tag) {
    _openedTag = tag;

    methods = {
      'process': (msg, context) => process(msg, context),
      'notify': (msg, context) => notify(msg, context),
    };
  }

  @override
  String toString() {
    if (_openedTag != null) {
      return runtimeType.toString() + '(${_openedTag!.name})';
    }

    return runtimeType.toString();
  }

  TagserResult? process(ProcessMessage msg, TagserContext context) {
    final charCode = msg.charCode;

    if (charCode == charEos) {
      if (_openedTag != null) {
        return TagserResult(
          err: TagserError(
            code: errorEndOfTag,
            text: getError(errorEndOfTag, {
              "tag": _openedTag!.name,
              "line": _openedTag!.line,
              "symbol": _openedTag!.symbol,
            }),
          ),
        );
      }
      _text = _text.trim();

      if (_text.isNotEmpty) {
        tags.add(
          Tag(
              name: '',
              type: typeText,
              body: _text,
              symbol: context.symbol ?? 0,
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
      } else if (charCode == charSlash) {
        if (_openedTag != null) {
          return TagserResult(
            state: CloseTag(_openedTag!.name ?? ''),
            message: InitMessage(
              charCode: charCode,
            ),
          );
        }

        return TagserResult(
            err: TagserError(
                code: errorSourceDocumentMalformed,
                text: getError(errorSourceDocumentMalformed, null)));
      } else {
        return TagserResult(
            err: TagserError(
                code: errorTagMalformed,
                text: getError(errorTagMalformed, null)));
      }
    } else if (_escape == true) {
      _text += String.fromCharCode(charCode!);
    } else if (charCode == charBackSlash) {
      _escape = true;
    } else if (charCode == charOpenBracket) {
      _opened = true;

      _text = _text.trim();

      if (_text.isNotEmpty) {
        tags.add(
          Tag(
              name: '',
              type: typeText,
              body: _text,
              symbol: context.symbol ?? 0,
              line: context.line),
        );
        _text = '';
      }
    } else {
      _text += String.fromCharCode(charCode!);
    }

    return null;
  }

  TagserResult? notify(NotifyMessage msg, TagserContext context) {
    switch (msg.type) {
      case notifyTagResult:
        tags.add(msg.value);

        break;
      case notifyCloseTagFound:
        return TagserResult(
          pop: true,
          message: NotifyMessage(
            charCode: msg.charCode,
            value: tags,
            type: notifyCloseTag,
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
  Tag? _tag;

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

  TagserResult? process(ProcessMessage msg, TagserContext context) {
    final charCode = msg.charCode;

    if (charCode == charEos) {
      return TagserResult(
        err: TagserError(
            code: errorUnexpectedEos, text: getError(errorUnexpectedEos, null)),
      );
    } else if (TagserUtils.isAvailableCharacter(charCode)) {
      return TagserResult(
        state: AttrState(),
        message: InitMessage(charCode: charCode),
      );
    } else if (charCode == charSlash) {
      return TagserResult(
        state: GetCloseBracket(),
      );
    } else if (charCode == charCloseBracket) {
      return TagserResult(
        state: RootState(_tag),
      );
    } else if (charCode == charSpace) {
      return null;
    } else {
      return TagserResult(
        err: TagserError(
            code: errorTagMalformed, text: getError(errorTagMalformed, null)),
      );
    }
  }

  TagserResult? notify(NotifyMessage msg, TagserContext context) {
    switch (msg.type) {
      case notifyTagNameResult:
        final String? tagName = msg.value?.toString();

        _tag = Tag(
            name: tagName ?? '',
            type: typeTag,
            symbol: context.symbol ?? 0,
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

      case notifyAttrResult:
        _tag!.addAttr(msg.value);
        return TagserResult(
          message: ProcessMessage(
            charCode: msg.charCode,
          ),
        );

      case notifyCloseBracketFound:
        return TagserResult(
          pop: true,
          message: NotifyMessage(
            type: notifyTagResult,
            value: _tag,
          ),
        );

      case notifyCloseTag:
        if (msg.value != null && msg.value is List) {
          for (final t in (msg.value as List)) {
            _tag!.addChild(t);
          }
        }

        return TagserResult(
          pop: true,
          message: NotifyMessage(
            type: notifyTagResult,
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

  TagserResult? process(ProcessMessage msg, TagserContext context) {
    final charCode = msg.charCode;

    if (charCode == charEos) {
      return TagserResult(
        err: TagserError(
            code: errorUnexpectedEos, text: getError(errorUnexpectedEos, null)),
      );
    } else if (TagserUtils.isAvailableCharacter(charCode)) {
      _name += String.fromCharCode(charCode!);
    } else if (charCode == charCloseBracket ||
        charCode == charSpace ||
        charCode == charSlash) {
      return TagserResult(
        pop: true,
        message: NotifyMessage(
          value: _name,
          charCode: charCode,
          type: notifyTagNameResult,
        ),
      );
    } else {
      return TagserResult(
        err: TagserError(
          code: errorWrongTagCharacter,
          text: getError(
            errorWrongTagCharacter,
            {'char': String.fromCharCode(charCode!)},
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

  TagserResult? process(ProcessMessage msg, TagserContext context) {
    final charCode = msg.charCode;

    switch (charCode) {
      case charEos:
        return TagserResult(
          err: TagserError(
              code: errorUnexpectedEos,
              text: getError(errorUnexpectedEos, null)),
        );

      case charSpace:
        return null;

      case charCloseBracket:
        return TagserResult(
          pop: true,
          message: NotifyMessage(
            type: notifyCloseTagFound,
          ),
        );

      default:
        return null;
    }
  }

  TagserResult? notify(NotifyMessage msg, TagserContext context) {
    switch (msg.type) {
      case notifyTagNameResult:
        String source = tagName;
        String result = msg.value;

        if (context.getOption('ignoreCase') == true) {
          source = source.toLowerCase();
          result = result.toLowerCase();
        }

        if (source != result) {
          return TagserResult(
            err: TagserError(
              code: errorWrongCloseTag,
              text: getError(errorWrongCloseTag, {'tag': msg.value}),
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
  String _name = '';
  String? _value;

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

    if (charCode == charEqual) {
      return TagserResult(
        state: AttrValueState(),
      );
    }

    return TagserResult(
        pop: true,
        message: NotifyMessage(
            charCode: msg.charCode,
            type: notifyAttrResult,
            value: TagAttribute(
              name: _name,
              value: _value ?? 'true',
            )));
  }

  TagserResult? notify(NotifyMessage msg, TagserContext context) {
    switch (msg.type) {
      case notifyAttrNameResult:
        final res = TagserResult();

        _name = msg.value;
        res.message = ProcessMessage(
          charCode: msg.charCode,
        );

        return res;
      case notifyAttrValueResult:
        _value = msg.value ?? '';

        return null;
      default:
        return null;
    }
  }
}

/// ATTR NAME STATE

class AttrNameState extends TagserState {
  String _name = '';

  AttrNameState() {
    methods = {
      'process': (msg, context) => process(msg, context),
    };
  }

  TagserResult? process(ProcessMessage msg, TagserContext context) {
    final charCode = msg.charCode;

    if (charCode == charEos) {
      return TagserResult(
        err: TagserError(
            code: errorUnexpectedEos, text: getError(errorUnexpectedEos, null)),
      );
    } else if (TagserUtils.isAvailableCharacter(charCode)) {
      _name += String.fromCharCode(charCode!);
    } else {
      return TagserResult(
        pop: true,
        message: NotifyMessage(
          type: notifyAttrNameResult,
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
  int _quote = -1;
  bool isFirstChar = true;

  AttrValueState() {
    methods = {
      'process': (msg, context) => process(msg, context),
    };
  }

  TagserResult? process(ProcessMessage msg, TagserContext context) {
    final charCode = msg.charCode;

    if (charCode == charEos) {
      return TagserResult(
        err: TagserError(
            code: errorUnexpectedEos, text: getError(errorUnexpectedEos, null)),
      );
    } else if (isFirstChar) {
      isFirstChar = false;

      if (charCode == charQuote || charCode == charSingleQuote) {
        _quote = charCode!;
      } else {
        return TagserResult(
          err: TagserError(
            code: errorAttrValueMalformed,
            text: getError(errorAttrValueMalformed, {}),
          ),
        );
      }
    } else {
      if (charCode == _quote) {
        return TagserResult(
          pop: true,
          message: NotifyMessage(
              type: notifyAttrValueResult, value: _value, charCode: charCode),
        );
      } else {
        _value += String.fromCharCode(charCode!);
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
      case charEos:
        return TagserResult(
          err: TagserError(
              code: errorUnexpectedEos,
              text: getError(errorUnexpectedEos, null)),
        );

      case charCloseBracket:
        return TagserResult(
          pop: true,
          message: NotifyMessage(
            charCode: msg.charCode,
            type: notifyCloseBracketFound,
          ),
        );

      default:
        return TagserResult(
          err: TagserError(
              code: errorWrongCharacterGiven,
              text: getError(errorWrongCharacterGiven,
                  {'char': String.fromCharCode(msg.charCode!), 'await': '>'})),
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

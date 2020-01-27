import 'package:meta/meta.dart';
import 'package:stubble/states.dart';
import 'package:stubble/messages.dart';
import 'package:stubble/const.dart';

const TYPE_TAG = 'tag';
const TYPE_TEXT = 'text';

class Tagser {
  List<TagserState> _stack;
  int _line = 0; // template lining support
  int _symbol = 0;

  List<Tag> parse(String source) {
    _stack = [];
    _stack.add(RootState(null));

    if (source != null && source.isNotEmpty) {
      final lines = source.split('\n');

      for (var l = 0; l < lines.length; l++) {
        _line = l;
        final line = lines[l];

        for (var i = 0; i < line.length; i++) {
          //print('Current state is: ${_stack.last}');
          _symbol = i;
          final charCode = line.codeUnitAt(i);

          //print('Pocessing char "${String.fromCharCode(charCode)}"; State - ${_stack.last.toString()}');
          //print("char: ${line[i]}");

          process(ProcessMessage(charCode: charCode));
        }

        //if (l < lines.length - 1) {
          //process(ProcessMessage(charCode: CHARS.ENTER));
        //}
      }

      process(ProcessMessage(charCode: CHAR_EOS));

      final state = _stack.last;

      if (_stack.length != 1 || !(state is RootState) ) {
        throw Exception(
            'Source document malformed.');
      } else {
        return (state as RootState).tags ;
      }
    }

    return null;
  }

  void process(TagserMessage msg) {
    final state = _stack.last;

    if (state != null && state.canAcceptMessage(msg)) {
      final res = state.processMessage(msg);

      if (res != null) {
        processResult(res);
      }
    }
  }

  void processResult(TagserResult r) {
    if (r.pop == true) {
      pop();
    }

    if (r.state != null) {
      _stack.add(r.state);
    }

    if (r.message != null) {
      process(r.message);
    }

    if (r.err != null) {
      final e = 'Error (${r.err.code}) on $currentLine:$_symbol ${r.err.text}';

      print(e);

      throw Exception(e);
    }
  }

  void pop() {
    _stack.removeLast();
  }

  int get currentLine {
    return _line + 1;
  }
}

class Tag {
  String _name;
  String _type;
  Map<String, TagAttribute> _attributes;
  List<Tag> _childs;
  String _body;

  Tag(String name, String type, [String body]) {
    _name = name;
    _type = type;
    _body = body;
    _attributes = {};
    _childs = [];
  }

  addAttr(TagAttribute attr) {
    if (_attributes == null) _attributes = {};

    if (attr != null) {
      _attributes[attr.name] = attr;
    }
  }

  addChild(Tag child) {
    if (_childs == null) _childs = [];

    _childs.add(child);
  }

  attrValue(String name) {
    if (_attributes.containsKey(name)) {
      return _attributes[name].value;
    }

    return null;
  }

  String get name {
    return _name;
  }

  String get type {
    return _type;
  }

  String get body {
    return _body;
  }

  List<Tag> get childs {
    return _childs;
  }

  Map<String, TagAttribute> get attributes {
    return _attributes;
  }
}

class TagAttribute {
  final String name;
  final String value;

  TagAttribute({@required this.name, @required this.value});
}

class TagserResult {
  TagserState state;
  bool pop;
  TagserError err;
  String result;
  TagserMessage message;

  TagserResult({
    this.state,
    this.message,
    this.pop,
    this.err,
    this.result,
  });
}

class TagserError {
  final int code;
  final String text;

  TagserError({this.code, this.text});
}
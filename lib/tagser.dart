library tagser;

part 'src/attribute.dart';

part 'src/const.dart';

part 'src/context.dart';

part 'src/error.dart';

part 'src/messages.dart';

part 'src/result.dart';

part 'src/states.dart';

part 'src/tag.dart';

part 'src/utils.dart';

class Tagser {
  Map<String, dynamic> _options = {
    'ignoreCase': false,
  };

  List<TagserState> _stack;
  int _line = 0; // template lining support
  int _symbol = 0;

  Tagser({Map<String, dynamic> options}) {
    if (options != null) {
      _options.addAll(options);
    }
  }

  List<Tag> parse(String source) {
    _stack = [];
    _stack.add(RootState(null));

    final context = TagserContext(
      options: _options,
    );

    if (source != null && source.isNotEmpty) {
      final lines = source.split('\n');

      for (var l = 0; l < lines.length; l++) {
        _line = l + 1;
        final line = lines[l];

        for (var i = 0; i < line.length; i++) {
          //print('Current state is: ${_stack.last}');
          _symbol = i + 1;
          final charCode = line.codeUnitAt(i);

          //print('Pocessing char "${String.fromCharCode(charCode)}"; State - ${_stack.last.toString()}');
          //print("char: ${line[i]}");

          context.symbol = _symbol;
          context.line = _line;

          process(ProcessMessage(charCode: charCode), context);
        }

        //if (l < lines.length - 1) {
        //process(ProcessMessage(charCode: CHARS.ENTER));
        //}
      }

      process(ProcessMessage(charCode: CHAR_EOS), context);

      final state = _stack.last;

      if (_stack.length != 1 || !(state is RootState)) {
        throw Exception('Source document malformed.');
      } else {
        return (state as RootState).tags;
      }
    }

    return null;
  }

  void process(TagserMessage msg, TagserContext context) {
    final state = _stack.last;

    if (state != null && state.canAcceptMessage(msg)) {
      final res = state.processMessage(msg, context);

      if (res != null) {
        processResult(res, context);
      }
    }
  }

  void processResult(TagserResult r, TagserContext context) {
    if (r.pop == true) {
      pop();
    }

    if (r.state != null) {
      _stack.add(r.state);
    }

    if (r.message != null) {
      process(r.message, context);
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
    return _line;
  }

  setOption(String name, dynamic value) {
    if (name != null && name.isNotEmpty) {
      if (_options == null) _options = {};

      _options[name] = value;
    }
  }
}

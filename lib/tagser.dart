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
  final Map<String, dynamic> _options = {
    'ignoreCase': false,
  };

  List<TagserState> _stack = [];
  int _line = 0; // template lining support
  int _symbol = 0;

  Tagser({Map<String, dynamic>? options}) {
    _options.addAll(options ?? {});
  }

  List<Tag> parse(String? source) {
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
      }

      process(ProcessMessage(charCode: charEos), context);

      final state = _stack.last;

      if (state is RootState) {
        return state.tags;
      }
    }

    return [];
  }

  void process(TagserMessage msg, TagserContext context) {
    final state = _stack.last;

    if (state.canAcceptMessage(msg)) {
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
      _stack.add(r.state!);
    }

    if (r.message != null) {
      process(r.message!, context);
    }

    if (r.err != null) {
      throw Exception('Error (${r.err!.code}) on $currentLine:$_symbol ${r.err!.text}');
    }
  }

  void pop() {
    _stack.removeLast();
  }

  int get currentLine {
    return _line;
  }

  setOption(String name, dynamic value) {
    _options[name] = value;
  }

  String html(List<Tag>? tags) {
    String res = '';

    if (tags != null && tags.isNotEmpty) {
      for (final tag in tags) {
        if (tag.type == typeTag) {
          res += '<${tag.name}';

          // attrs

          final attrs = tag.attributes;

          if (attrs.isNotEmpty) {
            attrs.forEach((name, attr) {
              res += ' ${attr.name}="${attr.value}"';
            });
          }

          res += '>';

          // childs

          final childs = tag.childs;

          if (childs.isNotEmpty) {
            res += html(childs);
          }

          //end

          res += '</${tag.name}>';
        } else {
          res += tag.body != null ? tag.body! : '';
        }
      }
    }

    return res;
  }
}

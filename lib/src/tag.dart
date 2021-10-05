part of tagser;

class Tag {
  String _name = '';
  String? _type;
  String? _body;
  int? _line;
  int _symbol = 0;

  Map<String, TagAttribute> _attributes = {};
  List<Tag> _childs = [];

  Tag({
    required String name,
    required int symbol,
    String? type,
    String? body,
    int? line,
  }) {
    _name = name;
    _type = type;
    _body = body;
    _attributes = {};
    _childs = [];
    _line = line;
    _symbol = symbol;
  }

  addAttr(TagAttribute? attr) {
    if (attr != null) {
      _attributes[attr.name] = attr;
    }
  }

  addChild(Tag child) {
    _childs.add(child);
  }

  attrValue(String name) {
    if (_attributes.containsKey(name)) {
      return _attributes[name]!.value;
    }

    return null;
  }

  String? get name {
    return _name;
  }

  String? get type {
    return _type;
  }

  String? get body {
    return _body;
  }

  List<Tag> get childs {
    return _childs;
  }

  Map<String, TagAttribute> get attributes {
    return _attributes;
  }

  int? get line {
    return _line;
  }

  int? get symbol {
      return _symbol - _name.length - 1; // start of tag
  }
}

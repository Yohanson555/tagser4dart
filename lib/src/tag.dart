part of tagser;

class Tag {
  String _name;
  String _type;
  Map<String, TagAttribute> _attributes;
  List<Tag> _childs;
  String _body;
  int _line;
  int _symbol;

  Tag({
    String name,
    String type,
    String body,
    int line,
    int symbol
  }) {
    _name = name;
    _type = type;
    _body = body;
    _attributes = {};
    _childs = [];
    _line = line;
    _symbol = symbol;
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

  int get line {
    return _line;
  }

  int get symbol {
    return _symbol - _name.length - 1; // start of tag
  }
}
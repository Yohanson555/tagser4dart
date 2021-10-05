part of tagser;

class TagserContext {
  int? line;
  int? symbol;
  Map<String, dynamic>? options;

  TagserContext({
    this.line,
    this.symbol,
    this.options,
  });

  dynamic getOption(String? key) {
    if (key != null && options != null && options!.containsKey(key)) {
      return options![key];
    }

    return null;
  }
}

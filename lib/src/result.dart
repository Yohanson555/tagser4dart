part of tagser;

class TagserResult {
  TagserState? state;
  bool? pop;
  TagserError? err;
  String? result;
  TagserMessage? message;

  TagserResult({
    this.state,
    this.message,
    this.pop,
    this.err,
    this.result,
  });
}
part of tagser;

abstract class TagserMessage {
  String getName();
}

class InitMessage extends TagserMessage {
  final dynamic value;
  final int? charCode;

  InitMessage({this.value, this.charCode});

  @override
  String getName() => 'init';
}

class ProcessMessage extends TagserMessage {
  final int? charCode;

  @override
  String getName() => 'process';

  ProcessMessage({
    this.charCode,
  });
}

class NotifyMessage extends TagserMessage {
  final int? charCode;
  final int? type;
  final dynamic value;

  @override
  String getName() => 'notify';

  NotifyMessage({
    this.charCode,
    this.type,
    this.value,
  });
}

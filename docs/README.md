### Overview
                                                                                                          
`Tagser` - is a simple tag-based document parser. 

There is no restrictions about what tags a source document can contain. 

You can parse documents with your own tags like `<someTag>`

### Usage

A simple usage example:

```dart
import 'package:tagser/tagser.dart';

main() {
  var tagser = new Tagser();
  var html = '<hello> Hello bro </hello>';
  
  var list =  tagser.parse(html);
}
```

As a result of parse command you will receive a `List` of `Tag`s.

Each text value will be interpreted as a `Tag` with `text` type.

### Options

`caseSensitive` - is parser is case-sensitive in case of tag names. If this option is set to `true` next example will be malformed:

```
<Tag>
    some body
</tag>
```

, and exception will be thrown. If `caseSensitive` set to false previous example will be parsed correctly.
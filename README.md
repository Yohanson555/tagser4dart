A library for Dart developers.

Simple tag-based document parser. 

Available types of tags:
- Selfclosing tags: <tag [attributes]/>
- Block tags: <tag [attributes]> Body </tag>

Attributes types: 
- bool: <tag bordered /> - will be converted to `bordered='true'`
- with value: <tag bordered='false' width='7' /> - value should be placed in single or double quotes

## Usage

A simple usage example:

```dart
import 'package:tagser/tagser.dart';

main() {
  var tagser = new Tagser();
  var html = '<hello> Hello bro </hello>';
  
  var list =  tagser.parse(html);
}
```

## Features and bugs

...

## Overview
                                                                                                          
`Tagser` - is a simple tag-based document parser. 

There is no restrictions about what tags a source document can contain. 

You can parse documents with your own tags like `<someTag>`

Available types of tags:
- Self closing tags: <tag [attributes]/>
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

As a result of parse command you will receive a `List` of `Tag`s.

Each text value will be interpreted as a `Tag` with `text` type.

## Notes

- Tag names are case sensitive. Open and close tags in block tag declaration should have the same spelling
- Attribute names are case sensitive: attribute `A` and attribute `a` are not the same

## Restrictions
- All self closing tags should have slash before closing bracket. Using `<br>` tag without slash will cause an error.
- No spaces allowed between open bracket and tag name: `< tag />` - will cause an error
- No spaces allowed between slash and close bracket : `<tag / >` - will cause an error
- No spaces allowed in attribute declaration:
 - `<tag A = 'value'` /> - error
 - `<tag A= 'value'` /> - error
 - `<tag A ='value'` /> - error

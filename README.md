# Tagser for Dart ![Coverage](https://raw.githubusercontent.com/Yohanson555/stubble4dart/master/coverage_badge.svg?sanitize=true)

## Overview

A library for Dart developers.

Simple tag-based document parser. It is not about HTML parsing. You can use whatever tags you want.

Available types of tags:
- Self closing tags: <tag [attributes]/>
- Block tags: <tag [attributes]> Body </tag>

Attributes types: 
- bool: <tag bordered /> - will be converted to `bordered='true'`
- with value: <tag bordered='false' width='7' /> - value should be placed in single or double quotes

## Methods

`parse(String source)` - parsing source string of tags into a list of `Tag` objects.
`html(List<Tag> tags)` - converting a list of `Tag` objects into a correct HTML body.

## Usage

A simple usage example:

```dart
import 'package:tagser/tagser.dart';

main() {
  var tagser = new Tagser();
  var source = '<line show/><hello> Hello bro </hello><br />';
  
  var tags =  tagser.parse(source);
  var html = tagser.html(tags);
  
  print(html); //prints: <line show="true"></line><hello> Hello bro </hello><br></br>
}
```

## Notes

- Tag names are case sensitive. Open and close tags in block tag declaration should have the same spelling. It can be changed by passing `"ignoreCase": true` as option to `Tagser`
- Attribute names are case sensitive: attribute `A` and attribute `a` are not the same

## Restrictions
- All self closing tags should have slash before closing bracket. Using `<br>` tag without slash will cause an error.
- No spaces allowed between open bracket and tag name: `< tag />` - will cause an error
- No spaces allowed between slash and close bracket : `<tag / >` - will cause an error
- No spaces allowed in attribute declaration:
 - `<tag A = 'value'` /> - error
 - `<tag A= 'value'` /> - error
 - `<tag A ='value'` /> - error
 
## Options

You can pass options to the `Tagser` constructor or set them with `setOption()` method.

Available options:
- `ignoreCase` - enables or disables case ignoring of opening and closing tag; `false` by default

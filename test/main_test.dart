import 'package:stubble/states.dart';
import 'package:stubble/tagser.dart';
import 'package:test/test.dart';

void main() {
  group('Testing correct sources', () {
    final tagser = Tagser();

    test('Only text', () {
      final html = 'Simple text';
      final list = tagser.parse(html);

      expect(list.length, 1);
      expect(list.first.type, TYPE_TEXT);
      expect(list.first.body, 'Simple text');
      expect(list.first.childs.length, 0);
      expect(list.first.name, '');
    });

    test('Only text with spaces', () {
      final html = '  Simple text   ';
      final list = tagser.parse(html);

      expect(list.length, 1);
      expect(list.first.type, TYPE_TEXT);
      expect(list.first.body, 'Simple text');
    });

    test('Only text with escapeing', () {
      final html = '  Simple text \\<';
      final list = tagser.parse(html);

      expect(list.length, 1);
      expect(list.first.type, TYPE_TEXT);
      expect(list.first.body, 'Simple text \<');
    });

    test('Selfclosed tag with no attrs', () {
      final html = '<tag/>';
      final list = tagser.parse(html);

      expect(list.length, 1);
      expect(list.first.name, 'tag');
      expect(list.first.type, TYPE_TAG);
      expect(list.first.body, null);
      expect(list.first.childs.length, 0);
      expect(list.first.attributes.length, 0);
    });

    test('Selfclosed tag with space after name', () {
      final html = '<tag />';
      final list = tagser.parse(html);

      expect(list.length, 1);
      expect(list.first.name, 'tag');
      expect(list.first.type, TYPE_TAG);
      expect(list.first.body, null);
      expect(list.first.childs.length, 0);
      expect(list.first.attributes.length, 0);
    });

    test('Selfclosed tag with one bool attribute', () {
      final html = '<tag attr/>';
      final list = tagser.parse(html);

      expect(list.length, 1);
      expect(list.first.name, 'tag');
      expect(list.first.type, TYPE_TAG);
      expect(list.first.attributes.length, 1);
      expect(list.first.attributes['attr'].name, 'attr');
      expect(list.first.attributes['attr'].value, 'true');
    });

    test('Selfclosed tag with two params', () {
      final html = '<tag A B="value"/>';
      final list = tagser.parse(html);

      expect(list.length, 1);
      expect(list.first.name, 'tag');
      expect(list.first.type, TYPE_TAG);
      expect(list.first.attributes.length, 2);
      expect(list.first.attributes['A'].name, 'A');
      expect(list.first.attributes['A'].value, 'true');
      expect(list.first.attributes['B'].name, 'B');
      expect(list.first.attributes['B'].value, 'value');
      expect(list.first.attrValue('B'), 'value');
      expect(list.first.attrValue('C'), null);
    });

    test('Selfclosed tag with two params with same name', () {
      final html = '<tag A A="value"/>';
      final list = tagser.parse(html);

      expect(list.length, 1);
      expect(list.first.name, 'tag');
      expect(list.first.type, TYPE_TAG);
      expect(list.first.attributes.length, 1);
      expect(list.first.attributes['A'].name, 'A');
      expect(list.first.attributes['A'].value, 'value');
    });

    test('Simple block tag', () {
      final html = '<tag>tag body</tag>';
      final list = tagser.parse(html);

      expect(list.length, 1);
      expect(list.first.name, 'tag');
      expect(list.first.type, TYPE_TAG);
      expect(list.first.childs.length, 1);
      expect(list.first.childs.first.name, '');
      expect(list.first.childs.first.type, TYPE_TEXT);
      expect(list.first.childs.first.body, 'tag body');
    });

    test('Nested block tags', () {
      final html =
          '<u><row><cell>{{name}}</cell><cell width="3">{{quantity}}</cell><cell width="8" align="right">{{\$item_price}}</cell></row></u>';
      final list = tagser.parse(html);

      expect(list.length, 1);
      expect(list.first.name, 'u');
      expect(list.first.type, TYPE_TAG);
      expect(list.first.childs.length, 1);
      expect(list.first.childs.first.name, 'row');
      expect(list.first.childs.first.type, TYPE_TAG);
      expect(list.first.childs.first.childs.length, 3);
      expect(list.first.childs.first.childs[0].attributes.length, 0);
      expect(list.first.childs.first.childs[0].childs[0].body, '{{name}}');
      expect(list.first.childs.first.childs[1].attributes.length, 1);
      expect(list.first.childs.first.childs[1].childs[0].body, '{{quantity}}');
      expect(list.first.childs.first.childs[2].attributes.length, 2);
      expect(
          list.first.childs.first.childs[2].childs[0].body, '{{\$item_price}}');
    });

    test('Testing step toString() #1', () {
      final state = RootState(null);

      expect(state.toString(), 'RootState(null)');
    });

    test('Testing step toString() #2', () {
      final state = RootState('tag');

      expect(state.toString(), 'RootState(tag)');
    });

    test('Testing step toString() #2', () {
      final state = TagState();

      expect(state.toString(), 'TagState');
    });
  });

  group('Testing malformed sources', () {
    final tagser = Tagser();

    test('Malformed tag', () {
      final html = '< tag >';
      expect(
          () => tagser.parse(html),
          throwsA(predicate((e) =>
              e is Exception &&
              e.toString() == 'Exception: Error (3) on 1:1 Tag malformed')));
    });

    test('Empty tag name', () {
      final html = '< />';
      expect(
          () => tagser.parse(html),
          throwsA(predicate((e) =>
              e is Exception &&
              e.toString() == 'Exception: Error (3) on 1:1 Tag malformed')));
    });

    test('Closed tag withou opened', () {
      final html = '</tag>';
      expect(
          () => tagser.parse(html),
          throwsA(predicate((e) =>
              e is Exception &&
              e.toString() ==
                  'Exception: Error (5) on 1:1 Source document malformed')));
    });

    test('Malformed tag #2', () {
      final html = '<tag#%^adf >';
      expect(
          () => tagser.parse(html),
          throwsA(predicate((e) =>
              e is Exception &&
              e.toString() ==
                  'Exception: Error (1) on 1:4 Wrong tag name character: #')));
    });

    test('Malformed tag #3', () {
      final html = '<tag #%^>';
      expect(
          () => tagser.parse(html),
          throwsA(predicate((e) =>
              e is Exception &&
              e.toString() == 'Exception: Error (3) on 1:5 Tag malformed')));
    });

    test('Close bracket with space', () {
      final html = '<tag / >';
      expect(
          () => tagser.parse(html),
          throwsA(predicate((e) =>
              e is Exception &&
              e.toString() ==
                  'Exception: Error (4) on 1:6 Wrong character given: " ". ">" awaits')));
    });

    test('Wrong close tag1', () {
      final html = '<tag></tag1>';
      expect(
          () => tagser.parse(html),
          throwsA(predicate((e) =>
              e is Exception &&
              e.toString() ==
                  'Exception: Error (6) on 1:11 Wrong close tag: tag1')));
    });

    test('Wrong attr #1', () {
      final html = '<tag A%/>';

      expect(
          () => tagser.parse(html),
          throwsA(predicate((e) =>
              e is Exception &&
              e.toString() == 'Exception: Error (3) on 1:6 Tag malformed')));
    });

    test('Wrong attr #2', () {
      final html = '<tag B=/>';

      expect(
          () => tagser.parse(html),
          throwsA(predicate((e) =>
              e is Exception &&
              e.toString() ==
                  'Exception: Error (9) on 1:7 Attribute value malfromed: the attribute value should be a string')));
    });

    test('Wrong attr #3', () {
      final html = '<tag B=true/>';

      expect(
          () => tagser.parse(html),
          throwsA(predicate((e) =>
              e is Exception &&
              e.toString() ==
                  'Exception: Error (9) on 1:7 Attribute value malfromed: the attribute value should be a string')));
    });

    test('Wrong attr #4', () {
      final html = '<tag B=3456/>';

      expect(
          () => tagser.parse(html),
          throwsA(predicate((e) =>
              e is Exception &&
              e.toString() ==
                  'Exception: Error (9) on 1:7 Attribute value malfromed: the attribute value should be a string')));
    });

    test('Wrong attr #5', () {
      final html = '<tag B="" />';

      expect(
          () => tagser.parse(html),
          throwsA(predicate((e) =>
              e is Exception &&
              e.toString() ==
                  'Exception: Error (8) on 1:8 Attribute malformed: empty value')));
    });

    test('Malformed document', () {
      final html = '<tag> tag body';

      expect(
          () => tagser.parse(html),
          throwsA(predicate((e) =>
              e is Exception &&
              e.toString() ==
                  'Exception: Source document malformed.')));
    });
  });
}

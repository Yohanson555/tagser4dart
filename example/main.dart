import 'package:tagser/tagser.dart';

void main() {
  final t = Tagser();

  final source = '''
    <schema>
      <header>
        <cell>№</cell>
        <cell>Name</cell>
        <cell>Lastname</cell>
        <cell>Age</cell>
      </header>
      <row>
        <cell>1</cell>
        <cell>John</cell>
        <cell>Doe</cell>
        <cell>45</cell>
      </row>
      
      <row>
        <cell>2</cell>
        <cell>Alice</cell>
        <cell>Doe</cell>
        <cell>40</cell>
      </row>
      
      <row>
        <cell>3</cell>
        <cell>Mike</cell>
        <cell>Doe</cell>
        <cell>25</cell>
      </row>
    </schema>
  ''';

  final tags = t.parse(source);

  print(tags);
}
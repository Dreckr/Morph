part of morph_test;


class CollectionsModel
{
  Map<String, int> map;
  List<String> list;
}


void collectionsModelTest() {
  var morph = new Morph();
  var map = { 'map': { 'first': 42, 'second': 123 }, 
              'list': [ 'list', 'of', 'strings' ] };

  group('Collections model:', () {
    test('Assign collections from map', () {
      var model = morph.deserialize(CollectionsModel, map);

      expect(model.map, equals(map['map']));
      expect(model.list, equals(map['list']));
    });

    test('Extract collections to map', () {
      var model = new CollectionsModel()
       ..map  = { 'first': 42, 'second': 123 }
       ..list  = [ 'list', 'of', 'strings' ];

      expect(morph.serialize(model), equals(map));
    });
  });
}

part of morph_test;

class InnerModel {
  String string;
  int integer;
}

class OuterModel {
  InnerModel inner;
}

void recursiveModelTest() {
  var morph = new Morph();
  var map = { 'inner': { 'string': 'some text', 'integer': 42 } };

  group('Recursive model:', () {
    test('Assign model from map', () {
      var model = morph.deserialize(OuterModel, map);

      expect(model.inner, isNotNull);
      expect(model.inner.string, equals('some text'));
      expect(model.inner.integer, equals(42));
    });

    test('Extract model to map', () {
      var model = new OuterModel()
        ..inner      = new InnerModel()
        ..inner.string  = 'some text'
        ..inner.integer  = 42;

      expect(morph.serialize(model), equals(map));
    });
  });
}
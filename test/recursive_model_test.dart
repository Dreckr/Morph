part of model_map_test;


class InnerModel
{
  String string;
  int integer;
}

class OuterModel
{
  InnerModel inner;
}

void recursiveModelTest()
{
  var map = { 'inner': { 'string': 'some text', 'integer': 42 } };

  group('Recursive model:', () {
    test('Assign model from map', () {
      var modelMap = new ModelMap();
      var model = modelMap.deserialize(OuterModel, map);

      expect(model.inner, isNotNull);
      expect(model.inner.string, equals('some text'));
      expect(model.inner.integer, equals(42));
    });

    test('Extract model to map', () {
      var modelMap = new ModelMap();
      var model = new OuterModel()
        ..inner      = new InnerModel()
        ..inner.string  = 'some text'
        ..inner.integer  = 42;

      expect(modelMap.serialize(model), equals(map));
    });
  });
}
part of morph_test;

@serializable
class PropertyModel {

  String someString;

  @Property("otherName")
  String named;

}

// TODO(diego): Add tests for getters and setters
void propertyAnnotationTest() {
  var morph = new Morph();
  var model = new PropertyModel()
                ..someString = "someString"
                ..named = "named";

  var map = {"someString": "someString", "otherName": "named"};

  group("Property annotation:", () {
    test("Serialization", () {
      var serializedModel = morph.serialize(model);

      expect(serializedModel, equals(map));
    });

    test("Deserialization", () {
      var deserializedModel = morph.deserialize(PropertyModel, map);

      expect(deserializedModel, new isInstanceOf<PropertyModel>());
      expect(deserializedModel.someString, equals("someString"));
      expect(deserializedModel.named, equals("named"));
    });
  });

}
part of model_map_test;

class PropertyModel {
  
  String someString;
  
  @Property("otherName")
  String named;
  
}

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
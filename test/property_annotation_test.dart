part of model_map_test;

class PropertyModel {
  
  String someString;
  
  @Property("otherName")
  String named;
  
}

void propertyAnnotationTest() {
  var modelMap = new ModelMap();
  var model = new PropertyModel()
                ..someString = "someString"
                ..named = "named";
  
  var map = {"someString": "someString", "otherName": "named"};
  
  group("Property annotation:", () {
    test("Serialization", () {
      var serializedModel = modelMap.toMap(model);
      
      expect(serializedModel, equals(map));
    });
    
    test("Deserialization", () {
      var deserializedModel = modelMap.fromMap(PropertyModel, map);
      
      expect(deserializedModel, new isInstanceOf<PropertyModel>());
      expect(deserializedModel.someString, equals("someString"));
      expect(deserializedModel.named, equals("named"));
    });
  });
  
}
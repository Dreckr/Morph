part of morph_test;

class SuperModel {
  String parentField;
}

class SubModel extends SuperModel {}

void subclassTest() {
  var morph = new Morph();
  var model = new SubModel()
                    ..parentField = "someString";
  var map = {"parentField": "someString"};
  
  group("Subclass:", () {
    test("Serialization of inherited field", () {
      expect(morph.serialize(model), equals(map));
    });
    
    test("Deserialization of inherited field", () {
      var deserializedModel = morph.deserialize(SubModel, map);
      
      expect(deserializedModel.parentField, equals("someString"));
    });
  });
}
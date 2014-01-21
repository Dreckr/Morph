part of morph_test;

class IgnoreModel {
  
  String someString;
  
  @Ignore
  String ignoredString;
  
  String _hiddenString;
  @Ignore String get hiddenString => _hiddenString;
                 set hiddenString (String value) => _hiddenString = value;
  
  String _preservedString = "Initial value";
  String get preservedString => _preservedString;
         @Ignore 
         set preservedString (String value) => _preservedString = value;
                 
}

void ignoreAnnotationTest() {
  var morph = new Morph();
  var model = new IgnoreModel()
                ..someString = "someString"
                ..ignoredString = "ignoredString"
                ..hiddenString = "hiddenString"
                ..preservedString = "preservedString";
  
  var map = {"someString": "someString", 
             "ignoredString": "ignoredString",
             "hiddenString": "hiddenString",
             "preservedString": "preservedString"};
  
  group("Ignore annotation:", () {
    test("Serialization",() {
      var serializedModel = morph.serialize(model);
      
      expect(serializedModel, new isInstanceOf<Map>());
      expect(serializedModel["someString"], equals(model.someString));
      expect(serializedModel["ignoredString"], isNull);
      expect(serializedModel["hiddenString"], isNull);
      expect(serializedModel["preservedString"], equals("preservedString"));
    });
    
    test("Deserialization", () {
      var deserializedModel = morph.deserialize(IgnoreModel, map);
      
      expect(deserializedModel, new isInstanceOf<IgnoreModel>());
      expect(deserializedModel.someString, equals("someString"));
      expect(deserializedModel.ignoredString, isNull);
      expect(deserializedModel.hiddenString, equals("hiddenString"));
      expect(deserializedModel.preservedString, equals("Initial value"));
    });
    
  });
}
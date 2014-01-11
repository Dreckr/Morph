part of model_map_test;

class IgnoreModel {
  
  String someString;
  
  @Ignore
  String ignoredString;
  
  String _hiddenString;
  @Ignore String get hiddenString => _hiddenString;
                 set hiddenString (String value) => _hiddenString = value;
  
  String _unmodifiableString = "Initial value";
  String get unmodifiableString => _unmodifiableString;
         @Ignore 
         set unmodifiableString (String value) => _unmodifiableString = value;
                 
}

void ignoreAnnotationTest() {
  var modelMap = new ModelMap();
  var model = new IgnoreModel()
                ..someString = "someString"
                ..ignoredString = "ignoredString"
                ..hiddenString = "hiddenString"
                ..unmodifiableString = "unmodifiableString";
  
  var map = {"someString": "someString", 
             "ignoredString": "ignoredString",
             "hiddenString": "hiddenString",
             "unmodifiableString": "unmodifiableString"};
  
  group("Ignore annotation:", () {
    test("Serialization",() {
      var serializedModel = modelMap.toMap(model);
      
      expect(serializedModel, new isInstanceOf<Map>());
      expect(serializedModel["someString"], equals(model.someString));
      expect(serializedModel["ignoredString"], isNull);
      expect(serializedModel["hiddenString"], isNull);
      expect(serializedModel["unmodifiableString"], equals("unmodifiableString"));
    });
    
    test("Deserialization", () {
      var deserializedModel = modelMap.fromMap(IgnoreModel, map);
      
      expect(deserializedModel, new isInstanceOf<IgnoreModel>());
      expect(deserializedModel.someString, equals("someString"));
      expect(deserializedModel.ignoredString, isNull);
      expect(deserializedModel.hiddenString, equals("hiddenString"));
      expect(deserializedModel.unmodifiableString, equals("Initial value"));
    });
    
  });
}
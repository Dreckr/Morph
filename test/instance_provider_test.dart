part of model_map_test;

class Provided {
  final String finalString;

  Provided(this.finalString);

}

class ProvidedInstanceProvider implements InstanceProvider<Provided> {
  
  Provided createInstance(Type instanceType) {
    if (instanceType == Provided) {
      return new Provided("someString");
    } else {
      throw new ArgumentError("ProvidedInstanceProvider can't provide "
                               "instances of type $instanceType");
    }
  }

}

void instanceProviderTest() {
  var modelMap;
  
  group("Instance Provider:", () {
    setUp(() {
      modelMap = new ModelMap();
    });
    
    test(
        "Deserialization without custom instance provider throws ArgumentError",
        () {
      var deserialization = () {
        Provided model = modelMap.deserialize(Provided, {});
      };
      
      expect(deserialization, throwsArgumentError);
    });
    
    test("Deserialization using custom instance provider", () {
      modelMap.registerInstanceProvider(Provided, 
                                        new ProvidedInstanceProvider());
      Provided model = modelMap.deserialize(Provided, {});
      
      expect(model.finalString, equals("someString"));
    });
  });
}
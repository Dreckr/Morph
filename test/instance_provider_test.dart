part of morph_test;

@InstanceProvider(ProvidedModelInstanceProvider)
class ProvidedModel {
  final String finalString;

  ProvidedModel(this.finalString);

}

class ProvidedModelInstanceProvider 
  implements CustomInstanceProvider<ProvidedModel> {
  
  ProvidedModel createInstance(Type instanceType) {
    if (instanceType == ProvidedModel) {
      return new ProvidedModel("someString");
    } else {
      throw new ArgumentError("ProvidedModelInstanceProvider can't provide "
                               "instances of type $instanceType");
    }
  }

}

void instanceProviderTest() {
  var morph;
  
  group("Instance Provider:", () {
    setUp(() {
      morph = new Morph();
    });
    
    test("Deserialization with annotated custom instance provider ",() {
      ProvidedModel model = morph.deserialize(ProvidedModel, {});
      
      expect(model.finalString, equals("someString"));
    });
    
    test("Deserialization using custom instance provider", () {
      morph.registerInstanceProvider(ProvidedModel, 
                                     new ProvidedModelInstanceProvider());
      ProvidedModel model = morph.deserialize(ProvidedModel, {});
      
      expect(model.finalString, equals("someString"));
    });
  });
}
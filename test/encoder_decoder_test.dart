part of model_map_test;

void encoderDecoderTest() {
  ModelMap modelMap;
  var now    = new DateTime.now();
  var date  = now.toString().replaceFirst(' ', 'T');
  var map    = { 'string': 'some text', 'integer': 42, 
                 'flag': true, 'float': 1.23, 'date': date };
  var json  = JSON.encode(map);
  
  var model = new SimpleModel()
                      ..string = 'some text'
                      ..integer = 42
                      ..flag = true
                      ..float = 1.23
                      ..date = now;
  
  group("Encoder/decoder test", () {
    setUp(() {
      modelMap = new ModelMap();
    });
    
    test("Transform output with encoder", () {
      var result = modelMap.serialize(model, JSON.encoder);
      expect(result, equals(json));
    });
    
    test("Transform input with decoder", () {
      var result = modelMap.deserialize(SimpleModel, json, JSON.decoder);
      
      expect(result.string, equals('some text'));
      expect(result.integer, equals(42));
      expect(result.flag, equals(true));
      expect(result.float, equals(1.23));
      expect(result.date, equals(now));
    });
  });
}
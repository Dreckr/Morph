part of morph_test;

void encoderDecoderTest() {
  Morph morph;
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
      morph = new Morph();
    });
    
    test("Transform output with encoder", () {
      var result = morph.serialize(model, JSON.encoder);
      expect(result, equals(json));
    });
    
    test("Transform input with decoder", () {
      var result = morph.deserialize(SimpleModel, json, JSON.decoder);
      
      expect(result.string, equals('some text'));
      expect(result.integer, equals(42));
      expect(result.flag, equals(true));
      expect(result.float, equals(1.23));
      expect(result.date, equals(now));
    });
  });
}
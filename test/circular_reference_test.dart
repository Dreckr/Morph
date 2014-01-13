part of model_map_test;

class CircularOne {
  CircularTwo two;
}

class CircularTwo {
  CircularThree three;
}

class CircularThree {
  CircularOne one;
}

// TODO(diego): Test deeper circular reference check
void circularReferenceTest() {
  var morph = new Morph();
  var one = new CircularOne();
  var two = new CircularTwo();
  var three = new CircularThree();
  
  one.two = two;
  two.three = three;
  three.one = one;
  
  group("Circular reference:", () {
    test("Serialization throws ArgumentError", () {
      
      var serialization = () {
        morph.serialize(one);
      };
      
      expect(serialization, throwsArgumentError);
    });
  });
}
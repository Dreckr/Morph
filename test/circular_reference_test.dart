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

void circularReferenceTest() {
  var modelMap = new ModelMap();
  var one = new CircularOne();
  var two = new CircularTwo();
  var three = new CircularThree();
  
  one.two = two;
  two.three = three;
  three.one = one;
  
  group("Circular reference:", () {
    test("Serialization throws ArgumentError", () {
      
      var serialization = () {
        modelMap.toMap(one);
      };
      
      expect(serialization, throwsArgumentError);
    });
  });
}
part of morph_test;

@serializable
class CircularOne {
  CircularTwo two;
}

@serializable
class CircularTwo {
  CircularThree three;
}

@serializable
class CircularThree {
  CircularOne one;

  CircularTwo two;
}

// TODO(diego): Test deeper circular reference check
void circularReferenceTest() {
  var morph = new Morph();
  var one;
  var two;
  var three;

  group("Circular reference:", () {
    setUp(() {
      one = new CircularOne();
      two = new CircularTwo();
      three = new CircularThree();

      one.two = two;
      two.three = three;
    });

    test("Direct circular reference throws ArgumentError", () {
      three.one = one;

      var serialization = () {
        morph.serialize(one);
      };

      expect(serialization, throws);
    });

    test("Indirect circular reference throws Exception", () {
      three.two = two;

      var serialization = () {
        morph.serialize(one);
      };

      expect(serialization, throws);
    });
  });
}
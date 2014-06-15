part of morph_test;

@TypeAdapter(CustomModelSerializer)
@TypeAdapter(CustomModelDeserializer)
class CustomModel {
  final String partA, partB;

  CustomModel(this.partA, this.partB);

}

class CustomModelSerializer extends Serializer {

  dynamic serialize(CustomModel obj) {
    var map = {};

    map["string"] = "${obj.partA}-${obj.partB}";

    return map;
  }

  @override
  bool supportsSerializationOf(object) =>
      object is CustomModel;
}

class CustomModelDeserializer extends Deserializer {


  CustomModel deserialize(value, Type targetType) {
    if (value is Map) {
      var string = value["string"];

      if (string is String) {
        var parts = string.split("-");

        if (parts.length == 2) {
          return new CustomModel(parts[0], parts[1]);
        }
      }
    }

    throw new ArgumentError("$value cannot be deserialized into CustomModel");
  }

  @override
  bool supportsDeserializationOf(object, Type targetType) =>
      (object is Map) && (targetType == CustomModel);
}

void customSerializerDeserializerTest() {
  var map = {"string": "part1-part2"};
  var model = new CustomModel("part1", "part2");

  var morph = new Morph();
  morph.registerTypeAdapter(new CustomModelSerializer());
  morph.registerTypeAdapter(new CustomModelDeserializer());

  group("Custom serializer/deserializer:", () {
    test("Serialization", () {
      expect(morph.serialize(model), equals(map));
    });

    test("Deserialization", () {
      var deserializedModel = morph.deserialize(CustomModel, map);
      expect(deserializedModel.partA, equals(model.partA));
      expect(deserializedModel.partB, equals(model.partB));
    });
  });
}
Morph
=====
[![Build Status](https://drone.io/github.com/Dreckr/Morph/status.png)](https://drone.io/github.com/Dreckr/Morph/latest)


Morph is a mirror based serializer and deserializer of Dart objects.

Morph is format agnostic, as it uses Maps of simple objects as a serialization
format. That means that you can take objects, transform them into Maps and then
use an encoder, like the JsonEncoder on dart:convert, to produce your output.
Likewise, you can take an input, decode it and extract objects out of it. This
is interesting because it lets you choose the serialization format on runtime,
having only to switch between codecs.

Morph is a heavily modified fork of Dan Parnham's [ModelMap][model_map]. It has
a different focus but was a great starting point. Thanks Dan!

[model_map]: https://github.com/parnham/model_map.dart

Getting Started
---------------

Using Morph is really straightforward:

```dart
import 'package:morph/morph.dart';

void main() {
  var morph = new Morph();
  var someObject = new SomeClass();
  
  var serializedMap = morph.serialize(someObject);
  var deserializedObject = morph.deserialize(SomeClass, serializedMap);
}
```

Wow, that's all? What just happend?

Well, first we created a Morph instance. We have to do that because Morph is 
configurable and we want you to be able to have as many configurations as you 
need. After that, we took an arbitrary object
and serialized it using `morph.serialize(someObject)`. That method call returns
a serialized map with the state stored by `someObject`. Last, just to cover all
the basic API, we took that serialized map and deserialized it back to a new
instance of `SomeClass` by calling 
`morph.deserialize(SomeClass, serializedMap)`. Notice that the first argument is
the Type of the instance that we want deserialized. We have to pass it because
it is impossible for Morph to guess what type of object it needs to create just
by looking at the map. 

Nice! What else can I do?
-------------------------

To help you with your serialization/deserialization work, Morph provides a set
of features that might come in handy.

### Codec support
As we have said earlier, Morph uses a Map of simple objects as a serialization
format, but that won't be much helpful unless you encode into a format that you
can pass around and everybody (not only Dart) understands. For that purpose
Morph allows you to pass an encoder/decoder as an optional argument to its
`serialize` and `deserialize` methods. Here is an example using the JSON codec
from dart:convert :

```dart
var jsonString = morph.serialize(someObject, JSON.encoder);

var deserializedObject = morph.deserialize(SomeClass, jsonString, JSON.decoder);
```

### Custom serializer/deserializer
Sometimes you may need to apply a custom behavior to the serialization of
objects of an specific class. In such cases you can register type adapters.
A type adapter can be a Serializer, defining only the serialization behavior, a
Deserializer, defining only the deserialization behavior, or a TypeAdapter,
defining both.

```dart
void main() {
  var morph = new Morph();
  morph.registerTypeAdapter(CustomModel, new CustomModelSerializer());
  morph.registerTypeAdapter(CustomModel, new CustomModelDeserializer());
}

class CustomModel {
  final String partA, partB;
  
  CustomModel(this.partA, this.partB);

}

class CustomModelSerializer extends Serializer<CustomModel> {
  
  Map serialize(CustomModel obj) {
    var map = {};
    
    map["string"] = "${obj.partA}-${obj.partB}";
    
    return map;
  }
}

class CustomModelDeserializer extends Deserializer<CustomModel> {
  
  
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
}
```

You can also define a serializer or deserializer using the `@TypeAdapter` 
annotation.

```dart
@TypeAdapter(CustomModelSerializer)
@TypeAdapter(CustomModelDeserializer)
class CustomModel {
  final String partA, partB;
  
  CustomModel(this.partA, this.partB);

}
```

### Instance provider
Morph cannot deserialize instances of a classe that do not have a no-args 
constructor all by itself, you need to give it a hand. To do so, you need to
register an instance provider. All an instance provider has to do is build a
fresh and clean instance of such class.

```dart
void main() {
  var morph = new Morph();
  morph.registerInstanceProvider(ProvidedModel, 
                                 new ProvidedModelInstanceProvider());
}

class ProvidedModel {
  final String finalString;

  ProvidedModel(this.finalString);

}

class ProvidedModelInstanceProvider 
  implements CustomInstanceProvider<ProvidedModel> {
  
  Provided createInstance(Type instanceType) {
    if (instanceType == ProvidedModel) {
      return new Provided("someString");
    } else {
      throw new ArgumentError("CustomInstanceProvider can't provide "
                               "instances of type $instanceType");
    }
  }

}
```

Alternatively, you can define instance providers using the `@InstanceProvider`
annotation.

```dart
@InstanceProvider(ProvidedModelInstanceProvider)
class ProvidedModel {
  final String finalString;

  ProvidedModel(this.finalString);

}
```

### Ignore annotation
If you want to hide a field from serialization or preserve the default value of
field on deserialization, the `@Ignore` annotation should be used. It also works
with getters and setters!

```dart
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
```

### Property annotation
The name of a property may differ from the name of your field. To solve this
problem we have the `@Property` annotation, that takes the property name as 
argument.

```dart
class PropertyModel {
  
  String someString;
  
  @Property("otherName")
  String named;
  
}
```

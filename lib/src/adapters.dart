library model_map.adapters;

import 'dart:mirrors';
import 'core.dart';

// TODO(diego): Implement custom instance providers
// TODO(diego): Support custom property name
// TODO(diego): Support ignore
class GenericTypeAdapter extends TypeAdapter {
  
  Map<String, dynamic> serialize(object, ClassMirror objectType) {
    var result  = new Map<String, dynamic>();
    var im = reflect(object);
    
    var members = im.type.declarations.values;

    for (var m in members.where(
         (m) => (m is VariableMirror || (m is MethodMirror && m.isGetter)) &&
         !m.isPrivate && !m.isStatic)) {
      var name  = MirrorSystem.getName(m.simpleName);
      var value = modelMap.serialize(im.getField(m.simpleName).reflectee);

      if (value != null) result[name] = value;
    }

    return result;
  }
  
  dynamic deserialize(object, ClassMirror objectType) {
    if (object is! Map) {
      throw new ArgumentError("$object cannot be deserialized into a ClassMirror");
    }
    
    var instance = _createInstanceOf(objectType);
    
    var im = reflect(instance);
    var members = im.type.declarations.values;

    members
    .where(
        (member) => 
          member is VariableMirror && 
          !member.isPrivate && 
          !member.isStatic)
       .forEach(
        (member) {
          var name = MirrorSystem.getName(member.simpleName);
  
          if (member.type is ClassMirror && object.containsKey(name)) {
            im.setField(member.simpleName, 
                        modelMap.deserialize(member.type, object[name]));
          }
       });
    
    members
    .where(
        (member) => 
          member is MethodMirror && 
          member.isSetter &&
          !member.isPrivate && 
          !member.isStatic)
       .forEach(
        (member) {
          var name = MirrorSystem.getName(member.simpleName);
          name = name.substring(0, name.length - 1);
          var type = member.parameters[0].type;
  
          if (type is ClassMirror && object.containsKey(name)) {
            im.setField(MirrorSystem.getSymbol(name), 
                        modelMap.deserialize(type, object[name]));
          }
       });

    return instance;
  }
  
  dynamic _createInstanceOf(ClassMirror classMirror) {
    var constructors = classMirror.declarations.values.where(
      (declaration) =>
        (declaration is MethodMirror) && (declaration.isConstructor));
    
    var selectedConstructor = constructors.firstWhere(
        (constructor) => constructor.parameters.where(
            (parameter) => !parameter.isOptional).length == 0
            , orElse: () =>  null);
    
    if (selectedConstructor == null) {
      throw new ArgumentError("${classMirror.reflectedType} does not have a no-args constructor or "
                               "an instance provider.");
    }
    
    return classMirror
              .newInstance(selectedConstructor.constructorName, []).reflectee;
  }
}

class StringTypeAdapter extends TypeAdapter<String> {
  
  dynamic serialize(String object, ClassMirror objectType) {
    return object;
  }
  
  String deserialize(object, ClassMirror objectType) {
    return object.toString();
  }
  
}

class NumTypeAdapter extends TypeAdapter<num> {
  
  dynamic serialize(num object, ClassMirror objectType) {
    return object;
  }
  
  num deserialize(object, ClassMirror objectType) {
    if (object is String) {
      return num.parse(object, 
        (string) => 
          throw new ArgumentError("$object cannot be deserialized into a num"));
    } else if (object is num) {
      return object;
    } else {
      throw new ArgumentError("$object cannot be deserialized into a num");
    }
  }
  
}

class IntTypeAdapter extends TypeAdapter<int> {
  
  dynamic serialize(int object, ClassMirror objectType) {
    return object;
  }
  
  int deserialize(object, ClassMirror objectType) {
    if (object is String) {
      return int.parse(object, 
        onError: (string) => 
          throw new ArgumentError("$object cannot be deserialized into a int"));
    } else if (object is int) {
      return object;
    } else {
      throw new ArgumentError("$object cannot be deserialized into a int");
    }
  }
  
}

class DoubleTypeAdapter extends TypeAdapter<double> {
  
  dynamic serialize(double object, ClassMirror objectType) {
    return object;
  }
  
  double deserialize(object, ClassMirror objectType) {
    if (object is String) {
      return double.parse(object, 
        (string) => 
          throw new ArgumentError("$object cannot be deserialized into a double"));
    } else if (object is num) {
      return object.toDouble();
    } else {
      throw new ArgumentError("$object cannot be deserialized into a double");
    }
  }
  
}

class BoolTypeAdapter extends TypeAdapter<bool> {
  
  dynamic serialize(bool object, ClassMirror objectType) {
    return object;
  }
  
  bool deserialize(object, ClassMirror objectType) {
    if (object is String) {
      if (object == "true") {
        return true;
      } else if (object == "false") {
        return false;
      } else {
        throw new ArgumentError("$object cannot be deserialized into a bool");
      }
    } else if (object is bool) {
      return object;
    } else {
      throw new ArgumentError("$object cannot be deserialized into a bool");
    }
  }
  
}

class DateTimeTypeAdapter extends TypeAdapter<DateTime> {
  
  dynamic serialize(DateTime object, ClassMirror objectType) {
    return object.toString().replaceFirst(' ', 'T');
  }
  
  DateTime deserialize(object, ClassMirror objectType) {
    if (object is String) {
      return DateTime.parse(object);
    } else if (object is num) {
      return new DateTime.fromMillisecondsSinceEpoch(object, isUtc: true);
    } else if (object is DateTime) {
      return object;
    } else {
      throw new ArgumentError("$object cannot be deserialized into a DateTime");
    }
  }
  
}
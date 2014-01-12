library model_map.adapters;

import 'dart:mirrors';
import 'annotations.dart';
import 'core.dart';

class GenericTypeAdapter extends TypeAdapter {
  InstanceProvider _genericInstanceProvider = new _GenericInstanceProvider();
  
  Map<String, dynamic> serialize(object) {
    var result  = new Map<String, dynamic>();
    var im = reflect(object);
    
    var members = im.type.declarations.values;

    members
      .where(
         (member) => 
             (member is VariableMirror || 
                 (member is MethodMirror && member.isGetter)) &&
            !member.isPrivate && !member.isStatic && !_shouldIgnore(member))
      .forEach((member) {
        var name  = _getPropertyName(member);
        var value = 
                  modelMap.serialize(im.getField(member.simpleName).reflectee);
  
        if (value != null) result[name] = value;
    });

    return result;
  }
  
  dynamic deserialize(object, Type objectType) {
    if (object is! Map) {
      throw 
        new ArgumentError("$object cannot be deserialized into a ClassMirror");
    }
    
    var instance = _createInstanceOf(objectType);
    
    var im = reflect(instance);
    var members = im.type.declarations.values;

    members
    .where(
        (member) => 
          member is VariableMirror && 
          !member.isPrivate && 
          !member.isStatic &&
          !member.isFinal &&
          !_shouldIgnore(member))
       .forEach(
        (member) {
          var name = _getPropertyName(member);
  
          if (member.type is ClassMirror && object.containsKey(name)) {
            im.setField(member.simpleName, 
                        modelMap.deserialize(member.type.reflectedType,
                                             object[name]));
          }
       });
    
    members
    .where(
        (member) => 
          member is MethodMirror && 
          member.isSetter &&
          !member.isPrivate && 
          !member.isStatic &&
          !_shouldIgnore(member))
       .forEach(
        (member) {
          var propertyName = _getPropertyName(member);
          
          var name = MirrorSystem.getName(member.simpleName);
          name = name.substring(0, name.length - 1);
          
          if (member.parameters.length == 0)
            return;
          
          var type = member.parameters[0].type;
          
          if (type is ClassMirror && object.containsKey(propertyName)) {
            im.setField(MirrorSystem.getSymbol(name), 
                        modelMap.deserialize(type.reflectedType, 
                                             object[propertyName]));
          }
       });

    return instance;
  }
  
  dynamic _createInstanceOf(Type type) {
    if (modelMap.instanceProviders.containsKey(type)) {
      return modelMap.instanceProviders[type].createInstance(type);
    } else {
      return _genericInstanceProvider.createInstance(type);
    }
  }
  
  bool _shouldIgnore(DeclarationMirror member) =>
    member.metadata.any((metadata) => metadata.reflectee == Ignore);
  
  String _getPropertyName(DeclarationMirror member) {
    var propertyAnnotation = member.metadata.firstWhere(
        (metadata) => metadata.reflectee is Property,
        orElse: () => null);
    
    if (propertyAnnotation != null) {
      return propertyAnnotation.reflectee.name;
    } else {
      var name = MirrorSystem.getName(member.simpleName);
      
      if (member is MethodMirror && member.isSetter) {
        name = name.substring(0, name.length - 1);
      }
      
      return name;
    }
  }
}

class StringTypeAdapter extends TypeAdapter<String> {
  
  dynamic serialize(String object) {
    return object;
  }
  
  String deserialize(object, Type objectType) {
    return object.toString();
  }
  
}

class NumTypeAdapter extends TypeAdapter<num> {
  
  dynamic serialize(num object) {
    return object;
  }
  
  num deserialize(object, Type objectType) {
    if (object is String) {
      return num.parse(object, 
        (string) => 
          throw 
              new ArgumentError("$object cannot be deserialized into a num"));
    } else if (object is num) {
      return object;
    } else {
      throw new ArgumentError("$object cannot be deserialized into a num");
    }
  }
  
}

class IntTypeAdapter extends TypeAdapter<int> {
  
  dynamic serialize(int object) {
    return object;
  }
  
  int deserialize(object, Type objectType) {
    if (object is String) {
      return int.parse(object, 
        onError: (string) => 
          throw 
              new ArgumentError("$object cannot be deserialized into a int"));
    } else if (object is int) {
      return object;
    } else {
      throw new ArgumentError("$object cannot be deserialized into a int");
    }
  }
  
}

class DoubleTypeAdapter extends TypeAdapter<double> {
  
  dynamic serialize(double object) {
    return object;
  }
  
  double deserialize(object, Type objectType) {
    if (object is String) {
      return double.parse(object, 
        (string) => 
          throw 
            new ArgumentError("$object cannot be deserialized into a double"));
    } else if (object is num) {
      return object.toDouble();
    } else {
      throw new ArgumentError("$object cannot be deserialized into a double");
    }
  }
  
}

class BoolTypeAdapter extends TypeAdapter<bool> {
  
  dynamic serialize(bool object) {
    return object;
  }
  
  bool deserialize(object, Type objectType) {
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
  
  dynamic serialize(DateTime object) {
    return object.toString().replaceFirst(' ', 'T');
  }
  
  DateTime deserialize(object, Type objectType) {
    if (object is String) {
      return DateTime.parse(object);
    } else if (object is num) {
      return new DateTime.fromMillisecondsSinceEpoch(object, isUtc: true);
    } else if (object is DateTime) {
      return object;
    } else {
      throw 
        new ArgumentError("$object cannot be deserialized into a DateTime");
    }
  }
  
}

class _GenericInstanceProvider implements InstanceProvider {
  
  dynamic createInstance(Type instanceType) {
    var classMirror = reflectClass(instanceType);
    var constructors = classMirror.declarations.values.where(
      (declaration) =>
        (declaration is MethodMirror) && (declaration.isConstructor));
    
    var selectedConstructor = constructors.firstWhere(
        (constructor) => constructor.parameters.where(
            (parameter) => !parameter.isOptional).length == 0
            , orElse: () =>  null);
    
    if (selectedConstructor == null) {
      throw new ArgumentError("${classMirror.reflectedType} does not have a "
                               "no-args constructor or "
                               "an instance provider.");
    }
    
    return classMirror
              .newInstance(selectedConstructor.constructorName, []).reflectee;
  }
}

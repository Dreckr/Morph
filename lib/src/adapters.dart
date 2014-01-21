library morph.adapters;

import 'dart:mirrors';
import 'annotations.dart';
import 'core.dart';
import 'mirrors_util.dart' as MirrorsUtil;

class GenericTypeAdapter extends CustomTypeAdapter {
  CustomInstanceProvider _genericInstanceProvider = 
      new _GenericInstanceProvider();
  
  Map<String, dynamic> serialize(object) {
    var result  = new Map<String, dynamic>();
    var im = reflect(object);
    
    var members = im.type.declarations.values;

    members
      .where(
         (member) => 
             (member is VariableMirror || 
             (member is MethodMirror && member.isGetter)) &&
            !member.isPrivate && 
            !member.isStatic && 
            !_shouldIgnore(member))
      .forEach((member) {
        var name  = _getPropertyName(member);
        var value = im.getField(member.simpleName).reflectee;
        
        if (value != null) {
          result[name] = morph.serialize(value);
        }
  
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
                        morph.deserialize(member.type.reflectedType,
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
            im.setField(MirrorSystem.getSymbol(name, type.owner), 
                        morph.deserialize(type.reflectedType, 
                                             object[propertyName]));
          }
       });

    return instance;
  }
  
  dynamic _createInstanceOf(Type type) {
    if (morph.instanceProviders.containsKey(type)) {
      return morph.instanceProviders[type].createInstance(type);
    } else {
      var classMirror = reflectClass(type);
      var instanceMirrorMetadata = classMirror.metadata.firstWhere(
          (metadata) => metadata.reflectee is InstanceProvider, 
          orElse: () => null);
      
      if (instanceMirrorMetadata != null ) {
        CustomInstanceProvider customInstanceProvider = 
            MirrorsUtil.createInstanceOf(
                instanceMirrorMetadata.reflectee.instanceProvider);
        
        morph.registerInstanceProvider(type, customInstanceProvider);
        
        return customInstanceProvider.createInstance(type);
      } else {
        return _genericInstanceProvider.createInstance(type);
      }
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

class StringTypeAdapter extends CustomTypeAdapter<String> {
  
  dynamic serialize(String object) {
    return object;
  }
  
  String deserialize(object, Type objectType) {
    return object.toString();
  }
  
}

class NumTypeAdapter extends CustomTypeAdapter<num> {
  
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

class IntTypeAdapter extends CustomTypeAdapter<int> {
  
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

class DoubleTypeAdapter extends CustomTypeAdapter<double> {
  
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

class BoolTypeAdapter extends CustomTypeAdapter<bool> {
  
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

class DateTimeTypeAdapter extends CustomTypeAdapter<DateTime> {
  
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

class ListTypeAdapter extends CustomTypeAdapter<List> {
  
  @override
  bool get serializesSubtypes => true;
  
  @override
  bool get deserializesNonGenerics => true;
  
  dynamic serialize(List object) {
    return new List.from(object.map((value) => morph.serialize(value)));
  }
  
  List deserialize(object, Type objectType) {
    // reflectType is used so we can know the type arguments
    var classMirror = reflectType(objectType) as ClassMirror;
    
    if (classMirror.typeArguments.any(
        (typeArg) => typeArg == currentMirrorSystem().dynamicType)) {
      throw new UnsupportedError("Unbound generic Lists are not supported.");
    }
    
    var valueType = classMirror.typeArguments[0] as ClassMirror;

    return new List.from(object.map(
            (value) => morph.deserialize(valueType.reflectedType, value)));
    
  }
  
}

class MapTypeAdapter extends CustomTypeAdapter<Map> {
  
  @override
  bool get serializesSubtypes => true;
  
  @override
  bool get deserializesNonGenerics => true;
  
  dynamic serialize(Map object) {
    return new Map.fromIterables(object.keys.map((key) => key.toString()), 
                                  object.values.map(
                                      (value) => morph.serialize(value)));
  }
  
  Map deserialize(object, Type objectType) {
    if (object is! Map) {
      throw new ArgumentError("$object cannot be deserialized into a Map");
    }
    
    // reflectType is used so we can know the type arguments
    var classMirror = reflectType(objectType) as ClassMirror;
    
    if (classMirror.typeArguments.any(
        (typeArg) => typeArg == currentMirrorSystem().dynamicType)) {
      throw new UnsupportedError("Unbound generic Maps are not supported.");
    }
    
    var keyType = classMirror.typeArguments[0] as ClassMirror;
    var valueType = classMirror.typeArguments[1] as ClassMirror;

    return new Map.fromIterables(object.keys, object.values.map(
        (value) => morph.deserialize(valueType.reflectedType, value)));
    
  }
  
}

// TODO(diego): Support non-default constructors
class _GenericInstanceProvider implements CustomInstanceProvider {
  
  dynamic createInstance(Type instanceType) {
    return MirrorsUtil.createInstanceOf(instanceType);
  }
}

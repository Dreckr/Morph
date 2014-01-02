library model_map;

import 'dart:mirrors';

class ModelMap {
  
  // TODO(diego): Support custom property name
  // TODO(diego): Support ignore
  dynamic fromMap(Type type, Map<String, dynamic> map, [dynamic instance]) {
    if (instance == null) {
      instance = _createInstanceOf(type);
    }
    
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
  
          if (member.type is ClassMirror && map.containsKey(name)) {
            im.setField(member.simpleName, _parseValue(member.type, map[name]));
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
  
          if (type is ClassMirror && map.containsKey(name)) {
            im.setField(MirrorSystem.getSymbol(name), _parseValue(type, map[name]));
          }
       });

    return instance;
  }
  
  Map<String, dynamic> toMap(object) {
    var result  = new Map<String, dynamic>();
    var im    = reflect(object);
    var members = im.type.declarations.values;

    for (var m in members.where(
         (m) => (m is VariableMirror || (m is MethodMirror && m.isGetter)) &&
         !m.isPrivate && !m.isStatic)) {
      var name  = MirrorSystem.getName(m.simpleName);
      var value = _getValue(im.getField(m.simpleName).reflectee);

      if (value != null) result[name] = value;
    }

    return result;
  }
  
  // TODO(diego): Implement custom instance providers
  dynamic _createInstanceOf(Type type) {
    var classMirror = reflectClass(type);
    var constructors = classMirror.declarations.values.where(
      (declaration) =>
        (declaration is MethodMirror) && (declaration.isConstructor));
    
    var selectedConstructor = constructors.firstWhere(
        (constructor) => constructor.parameters.where(
            (parameter) => !parameter.isOptional).length == 0
            , orElse: () =>  null);
    
    if (selectedConstructor == null) {
      throw new ArgumentError("$type does not have a no-args constructor or "
                               "an instance provider.");
    }
    
    return classMirror
              .newInstance(selectedConstructor.constructorName, []).reflectee;
  }
  
  // TODO(diego): Implement custom serializers
  dynamic _getValue(dynamic value) {
    if (value is String || value is num || value is bool) {
      return value;
    } else if (value is DateTime) {
      return value.toString().replaceFirst(' ', 'T');
    } else if (value is List) {
      return new List.from(value.map((i) => _getValue(i)));
    } else if (value is Map) {
      return new Map.fromIterables(value.keys, 
                                    value.values.map((i) => _getValue(i)));
    } else if (value != null) {
      return toMap(value);
    }
    
    return null;
  }
  
  // TODO(diego): Implement custom deserializers
  dynamic _parseValue(ClassMirror type, dynamic value) {
    switch(type.reflectedType) {
      case String:  return value is String ? value : null;
      case int:   return value is num ? value.toInt() : 0;
      case double:  return value is num ? value.toDouble() : 0;
      case num:   return value is num ? value : 0;
      case bool:    return value is bool ? value : false;
      case DateTime:  return _parseDate(value);
      default:    return _parseComplex(type, value);
    }
  }


  DateTime _parseDate(dynamic value) {
    if (value is String)  return DateTime.parse(value);
    if (value is num)     return new DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
    return null;
  }


  dynamic _parseComplex(ClassMirror classMirror, dynamic value) {
    var result;
    var type = classMirror.reflectedType;
    
    if (classMirror.simpleName == const Symbol("List") && value is List) {
      result = new List();
      var valueType = classMirror.typeArguments[0];

      if (valueType is ClassMirror) {
        for (var i in value) result.add(_parseValue(valueType, i));
      }
    } else if (classMirror.simpleName == const Symbol("Map") && 
                value is Map) {
      result = new Map();
      var keyType   = classMirror.typeArguments[0];
      var valueType = classMirror.typeArguments[1];

      if (keyType is ClassMirror && valueType is ClassMirror) {
        if ((keyType as ClassMirror).reflectedType == String) {
          value.forEach((k, v) => result[k] = _parseValue(valueType, v));
        }
      }
    } else if (value is Map) {
      result = fromMap(classMirror.reflectedType, value);
    }

    return result;
  }
}
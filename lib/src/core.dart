library model_map.core;

import 'dart:mirrors';
import 'package:quiver/mirrors.dart';
import 'adapters.dart';

class ModelMap {
  Map<Type, Deserializer> _deserializers = {};
  Map<Type, Serializer> _serializers = {};
  Serializer _genericSerializer;
  Deserializer _genericDeserializer;
  
  ModelMap() {
    _genericDeserializer = _genericSerializer = new GenericTypeAdapter();
    _genericDeserializer.install(this);
    setTypeAdapter(String, new StringTypeAdapter());
    setTypeAdapter(int, new IntTypeAdapter());
    setTypeAdapter(double, new DoubleTypeAdapter());
    setTypeAdapter(num, new NumTypeAdapter());
    setTypeAdapter(bool, new BoolTypeAdapter());
    setTypeAdapter(DateTime, new DateTimeTypeAdapter());
  }
  
  void setTypeAdapter(Type type, adapter) {
    if (adapter is Serializer) {
      adapter.install(this);
      _serializers[type] = adapter;
    }
    
    if (adapter is Deserializer) {
      adapter.install(this);
      _deserializers[type] = adapter;
    }
  }
  
  dynamic fromMap(Type type, Map<String, dynamic> map) {
    // TODO(diego): Check if type is a class
    
    return deserialize(reflectClass(type), map);
  }

  Map<String, dynamic> toMap(object) {
    // TODO(diego): Check if object's type is a class
    
    return serialize(object);
  }
  
  // TODO(diego): Implement cyclical reference check
  dynamic serialize(dynamic value) {
    if (value is Iterable) {
      return new List.from(value.map((i) => serialize(i)));
    } else if (value is Map) {
      return new Map.fromIterables(value.keys, 
                                    value.values.map((i) => serialize(i)));
    } else if (_serializers.containsKey(value.runtimeType)) {
      return _serializers[value.runtimeType]
                .serialize(value, reflectClass(value.runtimeType));
    } else if (value != null) {
      return _genericSerializer
                .serialize(value, reflectClass(value.runtimeType));
    }
    
    return null;
  }
  
  dynamic deserialize(ClassMirror type, dynamic value) {
    if (classImplements(type, #dart.core.Iterable) || classImplements(type, #dart.core.Map)) {
      return _deserializeComplex(type, value);
    } else if (_deserializers.containsKey(type.reflectedType)) {
      return _deserializers[type.reflectedType].deserialize(value, type);
    } else if (value != null) {
      return _genericDeserializer.deserialize(value, type);
    }
    
    return null;
  }

  dynamic _deserializeComplex(ClassMirror classMirror, dynamic value) {
    var result;
    
    if (classImplements(classMirror, #dart.core.Iterable) && value is Iterable) {
      result = new List();
      var valueType = classMirror.typeArguments[0];

      if (valueType is ClassMirror) {
        for (var i in value) result.add(deserialize(valueType, i));
      }
    } else if (classImplements(classMirror, #dart.core.Map) && 
                value is Map) {
      result = new Map();
      var keyType   = classMirror.typeArguments[0];
      var valueType = classMirror.typeArguments[1];

      if (keyType is ClassMirror && valueType is ClassMirror) {
        if (keyType.reflectedType == String) {
          value.forEach((k, v) => result[k] = deserialize(valueType, v));
        }
      }
    }

    return result;
  }
}

abstract class Serializer<T> {
  ModelMap modelMap;
  
  void install(ModelMap modelMap) {
    this.modelMap = modelMap;
  }
  
  dynamic serialize(T object, ClassMirror objectType);
  
}

abstract class Deserializer<T> {
  ModelMap modelMap;
  
  void install(ModelMap modelMap) {
    this.modelMap = modelMap;
  }
  
  T deserialize(object, ClassMirror objectType);
  
}

abstract class TypeAdapter<T> implements Serializer<T>, Deserializer<T> {
  ModelMap modelMap;
  
  void install(ModelMap modelMap) {
    this.modelMap = modelMap;
  }
}
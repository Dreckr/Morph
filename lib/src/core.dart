library model_map.core;

import 'dart:mirrors';
import 'package:quiver/mirrors.dart';
import 'package:collection/collection.dart';
import 'adapters.dart';

// TODO(diego): Document
// TODO(diego): Improve error messages
class ModelMap {
  Map<Type, Deserializer> _deserializers = {};
  Map<Type, Serializer> _serializers = {};
  TypeAdapter _genericTypeAdapter = new GenericTypeAdapter();
  Map<Type, InstanceProvider> _instanceProviders = {};
  dynamic _workingObject;
  
  Map<Type, InstanceProvider> get instanceProviders => 
      new UnmodifiableMapView(_instanceProviders);
  
  ModelMap() {
    _genericTypeAdapter.install(this);
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
  
  void setInstanceProvider(Type type, InstanceProvider instanceProvider) {
    _instanceProviders[type] = instanceProvider;
  }
  
  // TODO(diego): Ensure that this objects serializer returns a map
  Map<String, dynamic> toMap(dynamic object) => serialize(object);
  
  dynamic fromMap(Type targetType, Map<String, dynamic> map) =>
      deserialize(targetType, map);
  
  dynamic serialize(dynamic value) {
    if (_workingObject == null) {
      _workingObject = value;
    } else if (_workingObject == value) {
      throw new ArgumentError("$value has a circular reference.");
    }

    var result;
    
    if (value is Iterable) {
      result = new List.from(value.map((i) => serialize(i)));
    } else if (value is Map) {
      result = new Map.fromIterables(value.keys, 
                                    value.values.map((i) => serialize(i)));
    } else if (_serializers.containsKey(value.runtimeType)) {
      result = _serializers[value.runtimeType]
                .serialize(value);
    } else if (value != null) {
      result = _genericTypeAdapter.serialize(value);
    }
    
    if (_workingObject == value) {
      _workingObject = null;
    };
    
    return result;
  }
  
  dynamic deserialize(Type targetType, dynamic value) {
    if (_workingObject == null) {
      _workingObject = value;
    } else if (_workingObject == value) {
      throw new ArgumentError("$value has a circular reference.");
    }
    
    var classMirror = reflectClass(targetType);
    
    if (classImplements(classMirror, getTypeName(Iterable)) || 
        classImplements(classMirror, getTypeName(Map))) {
      return _deserializeComplex(targetType, value);
    } else if (_deserializers.containsKey(targetType)) {
      return _deserializers[targetType].deserialize(value, targetType);
    } else if (value != null) {
      return _genericTypeAdapter.deserialize(value, targetType);
    }
    
    if (_workingObject == value) {
      _workingObject = null;
    }
    
    return null;
  }

  dynamic _deserializeComplex(Type type, dynamic value) {
    var result;
    var classMirror = reflectType(type) as ClassMirror;
    
    if (classImplements(classMirror, getTypeName(Iterable)) && value is Iterable) {
      result = new List();
      var valueType = classMirror.typeArguments[0];

      if (valueType is ClassMirror) {
        for (var i in value) result.add(
            deserialize(valueType.reflectedType, i));
      }
    } else if (classImplements(classMirror, getTypeName(Map)) && 
                value is Map) {
      result = new Map();
      var keyType   = classMirror.typeArguments[0];
      var valueType = classMirror.typeArguments[1];

      if (keyType is ClassMirror && valueType is ClassMirror) {
        if (keyType.reflectedType == String) {
          value.forEach((k, v) => result[k] = 
              deserialize(valueType.reflectedType, v));
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
  
  dynamic serialize(T object);
  
}

abstract class Deserializer<T> {
  ModelMap modelMap;
  
  void install(ModelMap modelMap) {
    this.modelMap = modelMap;
  }
  
  T deserialize(object, Type targetType);
  
}

abstract class TypeAdapter<T> implements Serializer<T>, Deserializer<T> {
  ModelMap modelMap;
  
  void install(ModelMap modelMap) {
    this.modelMap = modelMap;
  }
}

abstract class InstanceProvider<T> {
  
  T createInstance(Type instanceType);
  
}
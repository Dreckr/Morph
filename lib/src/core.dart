library model_map.core;

import 'dart:convert';
import 'dart:mirrors';
import 'package:quiver/mirrors.dart';
import 'package:collection/collection.dart';
import 'adapters.dart';

// TODO(diego): Document
// TODO(diego): Improve error messages
/**
 * An easy to use serializer/deserializer of Dart objects.
 * 
 * A [ModelMap] can take almost any object and serialize it into a map of simple
 * objects (String, int, double, num, bool, List or Map) so that it can be 
 * easily encoded to JSON, XML or any other format.
 */
class ModelMap {
  Map<Type, Deserializer> _deserializers = {};
  Map<Type, Serializer> _serializers = {};
  TypeAdapter _genericTypeAdapter = new GenericTypeAdapter();
  Map<Type, InstanceProvider> _instanceProviders = {};
  dynamic _workingObject;
  
  /// All deserializers registered
  Map<Type, Deserializer> get deserializers =>
      new UnmodifiableMapView<Type, Deserializer>(_deserializers);
  
  /// All serializers registered
  Map<Type, Serializer> get serializers =>
      new UnmodifiableMapView<Type, Serializer>(_serializers);
  
  /// All instance providers registered
  Map<Type, InstanceProvider> get instanceProviders => 
      new UnmodifiableMapView<Type, InstanceProvider>(_instanceProviders);
  
  ModelMap() {
    _genericTypeAdapter.install(this);
    registerTypeAdapter(String, new StringTypeAdapter());
    registerTypeAdapter(int, new IntTypeAdapter());
    registerTypeAdapter(double, new DoubleTypeAdapter());
    registerTypeAdapter(num, new NumTypeAdapter());
    registerTypeAdapter(bool, new BoolTypeAdapter());
    registerTypeAdapter(DateTime, new DateTimeTypeAdapter());
  }
  
  /// Registers a new [Serializer], [Deserializer] or [TypeAdapter] for [type]
  void registerTypeAdapter(Type type, adapter) {
    if (adapter is Serializer) {
      adapter.install(this);
      _serializers[type] = adapter;
    }
    
    if (adapter is Deserializer) {
      adapter.install(this);
      _deserializers[type] = adapter;
    }
  }
  
  /// Registers a new [InstanceProvider] for [type]
  void registerInstanceProvider(Type type, InstanceProvider instanceProvider) {
    _instanceProviders[type] = instanceProvider;
  }
  
  /**
   * Returns a serialization of [object] into a simple object.
   * 
   * If [object] is already simple, it is returned. If it is a iterable or map, 
   * all its elements are serialized. In case it is of any other type, either
   * a custom [Serializer] is used (if registered for such type) or a generic
   * serializer that uses reflection is used 
   * (which should be fine for most uses) and a map is returned.
   * 
   * Optionally, you can pass a encoder to transform the output. For example,
   * if you want to serialize an object into a JSON string, you can call
   * 'modelMap.serialize(object, JSON.encoder)'.
   * 
   * Note: The keys of a map are transformed to strings using toString().
   */
  dynamic serialize(dynamic object, [Converter<Object, Object> encoder]) {
    if (_workingObject == null) {
      _workingObject = object;
    } else if (_workingObject == object) {
      throw new ArgumentError("object has a circular reference.");
    }

    var result;
    
    if (object is Iterable) {
      result = new List.from(object.map((i) => serialize(i)));
    } else if (object is Map) {
      result = new Map.fromIterables(object.keys.map((i) => i.toString()), 
                                     object.values.map((i) => serialize(i)));
    } else if (_serializers.containsKey(object.runtimeType)) {
      result = _serializers[object.runtimeType]
                .serialize(object);
    } else if (object != null) {
      result = _genericTypeAdapter.serialize(object);
    }
    
    if (_workingObject == object) {
      _workingObject = null;
    };
    
    if (encoder != null) {
      result = encoder.convert(result);
    }
    
    return result;
  }
  
  /**
   * Returns a deserialization of simple object [value] into an object of 
   * [targetType].
   * 
   * If a custom [Deserializer] is registered for [targetType], it is used, 
   * otherwise a generic deserializer that uses reflection is used. To 
   * deserialize objects that do not have a custom deserializer, its class must
   * have a no-args constructor or an [InstanceProvider] for its type must be
   * registered.
   * 
   * Optionally, you can pass a decoder to transform the input. For example,
   * if your input [value] is a JSON string, you can call 
   * 'modelMap.deserialize(SomeType, input, JSON.decoder)'.
   */
  dynamic deserialize(Type targetType, dynamic value, 
                      [Converter<Object, Object> decoder]) {
    if (_workingObject == null) {
      _workingObject = value;
    } else if (_workingObject == value) {
      throw new ArgumentError("$value has a circular reference.");
    }
    
    if (decoder != null) {
      value = decoder.convert(value);
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
    
    if (classImplements(classMirror, getTypeName(Iterable)) && 
        value is Iterable) {
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

/**
 * An abstract class for custom serializers.
 * 
 * A custom serializer must be able to take objects of [T] and serialize its 
 * state into a simple object (String, num, bool, null, List or Map).
 */
abstract class Serializer<T> {
  ModelMap modelMap;
  
  /// Installs this serializer on ModelMap.
  void install(ModelMap modelMap) {
    this.modelMap = modelMap;
  }
  
  dynamic serialize(T object);
  
}

/**
 * An abstract class for custom deserializers.
 * 
 * A custom deserializer must be able to create objects of [T] from a simple 
 * object (String, num, bool, null, List or Map).
 */
abstract class Deserializer<T> {
  ModelMap modelMap;
  
  /// Installs this deserializer on ModelMap.
  void install(ModelMap modelMap) {
    this.modelMap = modelMap;
  }
  
  T deserialize(object, Type targetType);
  
}

/**
 * An abstract class for custom type adapter.
 * 
 * A [TypeAdapter] is a object that can serialize and deserialize objects of 
 * [T].
 */
abstract class TypeAdapter<T> implements Serializer<T>, Deserializer<T> {
  ModelMap modelMap;
  
  /// Installs this type adapter on ModelMap.
  void install(ModelMap modelMap) {
    this.modelMap = modelMap;
  }
}

/**
 * A instance provider for type [T].
 * 
 * Sometimes you have to deserialize an object of a class that doesn't have a 
 * no-args constructor. For those cases, you have to create a custom instance
 * provider that allows ModelMap to create instances of such type.
 */
abstract class InstanceProvider<T> {
  
  /** Returns an instance of [instanceType].
    * 
    * A type is passed as parameter to permit the same instance provider to be
    * registered for several types and still know which one it is providing.
    */
  T createInstance(Type instanceType);
  
}
library morph.core;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:mirrors';
import 'package:quiver/mirrors.dart';
import 'package:collection/collection.dart';
import 'adapters.dart';
import 'annotations.dart';
import 'exceptions.dart';
import 'mirrors_util.dart' as MirrorsUtil;

// TODO(diego): Document
/**
 * An easy to use serializer/deserializer of Dart objects.
 * 
 * A [Morph] can take almost any object and serialize it into a map of simple
 * objects (String, int, double, num, bool, List or Map) so that it can be 
 * easily encoded to JSON, XML or any other format.
 */
class Morph {
  Map<Type, Deserializer> _deserializers = {};
  Map<Type, Serializer> _serializers = {};
  CustomTypeAdapter _genericTypeAdapter = new GenericTypeAdapter();
  Map<Type, CustomInstanceProvider> _instanceProviders = {};
  Queue _workingObjects = new Queue();
  
  /// All deserializers registered
  Map<Type, Deserializer> get deserializers =>
      new UnmodifiableMapView<Type, Deserializer>(_deserializers);
  
  /// All serializers registered
  Map<Type, Serializer> get serializers =>
      new UnmodifiableMapView<Type, Serializer>(_serializers);
  
  /// All instance providers registered
  Map<Type, CustomInstanceProvider> get instanceProviders => 
      new UnmodifiableMapView<Type, CustomInstanceProvider>(_instanceProviders);
  
  Morph() {
    _genericTypeAdapter.install(this);
    registerTypeAdapter(String, new StringTypeAdapter());
    registerTypeAdapter(int, new IntTypeAdapter());
    registerTypeAdapter(double, new DoubleTypeAdapter());
    registerTypeAdapter(num, new NumTypeAdapter());
    registerTypeAdapter(bool, new BoolTypeAdapter());
    registerTypeAdapter(DateTime, new DateTimeTypeAdapter());
    registerTypeAdapter(List, new ListTypeAdapter());
    registerTypeAdapter(Iterable, new ListTypeAdapter());
    registerTypeAdapter(Map, new MapTypeAdapter());
  }
  
  /// Registers a new [Serializer], [Deserializer] or [CustomTypeAdapter] for 
  /// [type]
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
  
  /// Registers a new [CustomInstanceProvider] for [type]
  void registerInstanceProvider(Type type, 
                                CustomInstanceProvider CustomInstanceProvider) {
    _instanceProviders[type] = CustomInstanceProvider;
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
   * 'morph.serialize(object, JSON.encoder)'.
   * 
   * Note: The keys of a map are transformed to strings using toString().
   */
  dynamic serialize(dynamic object, [Converter<Object, Object> encoder]) {
    if (_workingObjects.contains(object)) {
      throw new ArgumentError("$object contains a circular reference");
    }
    
    _workingObjects.addLast(object);
      
    var result;
    
    try {
      if (_serializers.containsKey(object.runtimeType) ||
                  (_checkForTypeAdapters(object.runtimeType) &&
                    _serializers.containsKey(object.runtimeType))) {
        result = _serializers[object.runtimeType]
                  .serialize(object);
      } else if (_isSupported(object)) {
        var classMirror = reflectClass(object.runtimeType);
        var supertype = _serializers.keys
            .where((key) => _serializers[key].serializesSubtypes)
            .firstWhere((key) => classImplements(classMirror, getTypeName(key)),
            orElse: () => null);
        
        if (supertype != null) {
          result = _serializers[supertype].serialize(object);
        } else {
          result = _genericTypeAdapter.serialize(object);
        }
      } else {
        throw 
          new UnsupportedError("Serialization of $object is not supported");
      }
      
      if (encoder != null) {
        result = encoder.convert(result);
      }
    } on SerializationException catch(exception) {
      rethrow;
    } catch(error) {
      throw new SerializationException(error);
    } finally {
      _workingObjects.removeLast();
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
   * have a no-args constructor or an [CustomInstanceProvider] for its type must 
   * be registered.
   * 
   * Optionally, you can pass a decoder to transform the input. For example,
   * if your input [value] is a JSON string, you can call 
   * 'morph.deserialize(SomeType, input, JSON.decoder)'.
   */
  dynamic deserialize(Type targetType, dynamic value, 
                      [Converter<Object, Object> decoder]) {
    
    if (value == null) {
      return value;
    }
    
    if (_workingObjects.contains(value)) {
      throw new ArgumentError("$value contains a circular reference");
    }
    
    _workingObjects.addLast(value);
    
    if (decoder != null) {
      value = decoder.convert(value);
    }
    
    var result;
    try {
      if (_deserializers.containsKey(targetType) ||
                  (_checkForTypeAdapters(targetType) && 
                    _deserializers.containsKey(targetType))) {
        result = _deserializers[targetType].deserialize(value, targetType);
      } else if (_isSupported(targetType)) {
        var classMirror = reflectClass(targetType);
        var genericType = _deserializers.keys
            .where((key) => _deserializers[key].deserializesNonGenerics)
            .firstWhere((key) => getTypeName(key) == classMirror.qualifiedName,
              orElse: () => null);
        
        if (genericType != null) {
          result = _deserializers[genericType].deserialize(value, targetType);
        } else {
          result = _genericTypeAdapter.deserialize(value, targetType);
        }
      } else {
        throw 
          new UnsupportedError("Deserialization of $targetType is not supported");
      }
    } on DeserializationException catch(exception) {
      rethrow;
    } catch(error) {
      throw new DeserializationException(error);
    } finally {
      _workingObjects.removeLast();
    }
    
    return result;
  }
  
  bool _checkForTypeAdapters(Type type) {
    var foundTypeAdapter = false;
    var classMirror = reflectClass(type);
    classMirror.metadata.where(
        (metadata) => metadata.reflectee is TypeAdapter
    ).forEach((typeAdapterMetadata) {
      foundTypeAdapter = true;
      var adapter = 
          MirrorsUtil.createInstanceOf(
              typeAdapterMetadata.reflectee.typeAdapter);
      
      registerTypeAdapter(type, adapter);
    });
    
    return foundTypeAdapter;
  }
}

/**
 * An abstract class for custom serializers.
 * 
 * A custom serializer must be able to take objects of [T] and serialize its 
 * state into a simple object (String, num, bool, null, List or Map).
 */
abstract class Serializer<T> {
  Morph morph;
  
  bool get serializesSubtypes => false;
  
  /// Installs this serializer on Morph.
  void install(Morph morph) {
    this.morph = morph;
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
  Morph morph;
  
  bool get deserializesNonGenerics => false;
  
  /// Installs this deserializer on Morph.
  void install(Morph morph) {
    this.morph = morph;
  }
  
  T deserialize(object, Type targetType);
  
}

/**
 * An abstract class for custom type adapter.
 * 
 * A [CustomTypeAdapter] is a object that can serialize and deserialize objects 
 * of [T].
 */
abstract class CustomTypeAdapter<T> extends Object 
                                      with Serializer<T>, Deserializer<T> {
  Morph morph;
  
  /// Installs this type adapter on Morph.
  void install(Morph morph) {
    this.morph = morph;
  }
}

/**
 * A instance provider for type [T].
 * 
 * Sometimes you have to deserialize an object of a class that doesn't have a 
 * no-args constructor. For those cases, you have to create a custom instance
 * provider that allows Morph to create instances of such type.
 */
abstract class CustomInstanceProvider<T> {
  
  /** Returns an instance of [instanceType].
    * 
    * A type is passed as parameter to permit the same instance provider to be
    * registered for several types and still know which one it is providing.
    */
  T createInstance(Type instanceType);
  
}

bool _isSupported(object) {
  if (object is Type) {
    return object != Function && object != Stream &&
            object != Future && object is! Mirror;
  } else {
    return object is! Function && object is! Stream && 
            object is! Future && object is! Mirror && object != null;
  }
}
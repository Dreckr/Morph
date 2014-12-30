library morph.adapters;

import 'dart:mirrors';
import 'annotations.dart';
import 'core.dart';
import 'mirrors_util.dart' as MirrorsUtil;
import 'package:quiver/mirrors.dart';

class GenericTypeAdapter extends CustomTypeAdapter {
  CustomInstanceProvider _genericInstanceProvider =
      new _GenericInstanceProvider();

  Map<String, dynamic> serialize(object) {
    var result  = new Map<String, dynamic>();
    var im = reflect(object);

    var members = _getAllDeclarations(im.type).values;

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
    var members = _getAllDeclarations(im.type).values;

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

  Map<Symbol, DeclarationMirror> _getAllDeclarations(ClassMirror classMirror) {
    var declarations = {};

    while (classMirror.superclass != null) {
      declarations.addAll(classMirror.declarations);
      classMirror = classMirror.superclass;
    }

    return declarations;
  }

  @override
  bool supportsDeserializationOf(object, Type targetType) => true;

  @override
  bool supportsSerializationOf(object) => true;
}

class StringTypeAdapter extends CustomTypeAdapter {

  dynamic serialize(String object) {
    return object;
  }

  String deserialize(object, Type objectType) {
    return object.toString();
  }


  @override
  bool supportsDeserializationOf(object, Type targetType) =>
      targetType == String;

  @override
  bool supportsSerializationOf(object) =>
      object is String;
}

class NumTypeAdapter extends CustomTypeAdapter {

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

  @override
  bool supportsDeserializationOf(object, Type targetType) =>
      (object is String || object is num) && (targetType == num);

  @override
  bool supportsSerializationOf(object) =>
      object is num;
}

class IntTypeAdapter extends CustomTypeAdapter {

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

  @override
  bool supportsDeserializationOf(object, Type targetType) =>
      (object is String || object is int) && (targetType == int);

  @override
  bool supportsSerializationOf(object) =>
      object is int;

}

class DoubleTypeAdapter extends CustomTypeAdapter {

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

  @override
  bool supportsDeserializationOf(object, Type targetType) =>
      (object is String || object is double) && (targetType == double);

  @override
  bool supportsSerializationOf(object) =>
      object is double;

}

class BoolTypeAdapter extends CustomTypeAdapter {

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

  @override
  bool supportsDeserializationOf(object, Type targetType) =>
      (object is String || object is bool) && (targetType == bool);

  @override
  bool supportsSerializationOf(object) =>
      object is bool;

}

class DateTimeTypeAdapter extends CustomTypeAdapter {

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

  @override
  bool supportsDeserializationOf(object, Type targetType) =>
      (object is String || object is bool || object is num) &&
      (targetType == DateTime);

  @override
  bool supportsSerializationOf(object) =>
      object is DateTime;

}

// TODO(diego): Properly propagate errors on ListTypeAdapter and MapTypeAdapter
class IterableTypeAdapter extends CustomTypeAdapter {

  static final ClassMirror listClassMirror = reflectClass(List);
  static final ClassMirror setClassMirror = reflectClass(Set);

  dynamic serialize(Iterable object) {
    return new List.from(object.map((value) => morph.serialize(value)));
  }

  Iterable deserialize(object, Type targetType) {
    // reflectType is used so we can know the type arguments
    var classMirror = reflectType(targetType) as ClassMirror;

    var valueType = classMirror.typeArguments[0] as ClassMirror;

    if (classImplements(classMirror, listClassMirror))
      return new List.from(object.map(
            (value) => morph.deserialize(valueType.reflectedType, value)));
    else if (classImplements(classMirror, setClassMirror))
      return new Set.from(object.map(
            (value) => morph.deserialize(valueType.reflectedType, value)));
    else
      throw new UnsupportedError("Unsupported Iterable type $targetType");

  }

  @override
  bool supportsDeserializationOf(object, Type targetType) =>
      (object is Iterable);

  @override
  bool supportsSerializationOf(object) =>
      object is Iterable;

}

class MapTypeAdapter extends CustomTypeAdapter {

  static final ClassMirror mapClassMirror = reflectClass(Map);

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

  @override
  bool supportsDeserializationOf(object, Type targetType) =>
      (object is Map) &&
      (classImplements(reflectClass(targetType), mapClassMirror));

  @override
  bool supportsSerializationOf(object) =>
      object is Map;

}

// TODO(diego): Support non-default constructors
class _GenericInstanceProvider implements CustomInstanceProvider {

  dynamic createInstance(Type instanceType) {
    return MirrorsUtil.createInstanceOf(instanceType);
  }
}

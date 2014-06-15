library morph.mirrors;

import 'dart:mirrors';
import 'annotations.dart';

dynamic createInstanceOf(Type type) {
  var classMirror = reflectClass(type);
  var constructors = classMirror.declarations.values.where(
      (declaration) =>
        (declaration is MethodMirror) && (declaration.isConstructor));

    var selectedConstructor = constructors.firstWhere(
        (constructor) => constructor.parameters.where(
            (parameter) => !parameter.isOptional).length == 0
            , orElse: () =>  null);

    if (selectedConstructor == null) {
      throw new ArgumentError("${classMirror.reflectedType} does not have a "
                               "no-args constructor.");
    }

    return classMirror
              .newInstance(selectedConstructor.constructorName, []).reflectee;
}

class TypeReference<T> {

  const TypeReference();

  Type getType() =>
      reflect(this).type.typeArguments[0].reflectedType;
}
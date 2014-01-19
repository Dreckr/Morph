library morph.annotations;

const Ignore = const IgnoreAnnotation._();
class IgnoreAnnotation {
  
  const IgnoreAnnotation._();
}

class Property {
  final String name;
  
  const Property(this.name);
}

class TypeAdapter {
  final Type typeAdapter;
  
  const TypeAdapter(this.typeAdapter);
}

class InstanceProvider {
  final Type instanceProvider;
  
  const InstanceProvider(this.instanceProvider);
}
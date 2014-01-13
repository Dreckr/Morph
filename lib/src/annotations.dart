library morph.annotations;

const Ignore = const IgnoreAnnotation._();
class IgnoreAnnotation {
  
  const IgnoreAnnotation._();
}

class Property {
  final String name;
  
  const Property(this.name);
}
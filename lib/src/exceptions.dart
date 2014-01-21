library morph.exceptions;

class SerializationException implements Exception {
  List<Reference> referenceChain;
  var originalError;
  
  SerializationException(Reference finalReference, this.originalError): 
    referenceChain = [finalReference];
  
  SerializationException.fromPrevious(SerializationException previousException, 
                                  Reference currentReference): 
                                    originalError = 
                                      previousException.originalError,
                                    referenceChain = 
                                      previousException.referenceChain
                                                      ..add(currentReference);
  
  String toString() {
    return "SerializationException:\n" +
        originalError.toString() + "\n" +
        "On reference chain: " +
        referenceChain.reversed.join(" -> ");
  }
}

class DeserializationException implements Exception {
  List<Reference> referenceChain;
  var originalError;
  
  DeserializationException(Reference finalReference, this.originalError): 
    referenceChain = [finalReference];
  
  DeserializationException.fromPrevious(DeserializationException previousException, 
                                  Reference currentReference): 
                                    originalError = 
                                      previousException.originalError,
                                    referenceChain = 
                                      previousException.referenceChain
                                                      ..add(currentReference);
  
  String toString() {
    return "DeserializationException:\n" +
        originalError.toString() + "\n" +
        "On reference chain: " +
        referenceChain.reversed.join(" -> ");
  }
}

class Reference {
  var field;
  
  Reference(this.field);
  
  String toString() {
    return field.toString();
  }
}
library morph.exceptions;

class SerializationException implements Exception {
  List<Reference> referenceChain = [];
  var originalError;
  
  SerializationException(this.originalError, [Reference finalReference]) { 
    if (finalReference != null) {
      referenceChain = [finalReference];
    }
  }
  
  SerializationException.fromPrevious(SerializationException previousException, 
                                  Reference currentReference): 
                                    originalError = 
                                      previousException.originalError,
                                      referenceChain = 
                                      previousException.referenceChain {
    if (currentReference != null) {
      referenceChain.add(currentReference);
    }
  }
  
  String toString() {
    return "SerializationException:\n" +
        originalError.toString() + "\n" +
        (referenceChain.isNotEmpty ?
          "On reference chain: " +
          referenceChain.reversed.join(" -> ") : "");
  }
}

class DeserializationException implements Exception {
  List<Reference> referenceChain = [];
  var originalError;
  
  DeserializationException(this.originalError, [Reference finalReference]) { 
    if (finalReference != null) {
      referenceChain = [finalReference];
    }
  }
  
  DeserializationException.fromPrevious(DeserializationException previousException, 
                                  [Reference currentReference]): 
                                    originalError = 
                                      previousException.originalError,
                                    referenceChain = 
                                      previousException.referenceChain {
    if (currentReference != null) {
      referenceChain.add(currentReference);
    }
  }
  
  String toString() {
    return "DeserializationException:\n" +
        originalError.toString() + "\n" +
        (referenceChain.isNotEmpty ?
            "On reference chain: " +
            referenceChain.reversed.join(" -> ") : "");
  }
}

class Reference {
  var field;
  
  Reference(this.field);
  
  String toString() {
    return field.toString();
  }
}
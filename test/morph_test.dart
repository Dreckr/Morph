library morph_test;

import 'dart:convert';
import 'package:unittest/unittest.dart';
import 'package:unittest/vm_config.dart';
import 'package:morph/morph.dart';

part 'simple_model_test.dart';
part 'collections_model_test.dart';
part 'recursive_model_test.dart';
part 'complex_model_test.dart';
part 'custom_serializer_deserializer_test.dart';
part 'ignore_annotation_test.dart';
part 'property_annotation_test.dart';
part 'circular_reference_test.dart';
part 'instance_provider_test.dart';
part 'encoder_decoder_test.dart';

void main() {
  useVMConfiguration();
  
  simpleModelTest();
  
  collectionsModelTest();
  
  recursiveModelTest();
  
  complexModelTest();
  
  customSerializerDeserializerTest();
  
  ignoreAnnotationTest();
  
  propertyAnnotationTest();
  
  circularReferenceTest();
  
  instanceProviderTest();
  
  encoderDecoderTest();
  
}
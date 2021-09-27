import 'dart:io';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
//import 'package:flutter_objc_pd/OneDScreen.dart';
import 'package:flutter_objc_pd/SensorProcessing.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart' as path_rovider;
void intiaLizeHive () async {
  var path = Directory.current.path;
  await Hive.init(path + 'sensor_processing_test.dart');
  await Hive.openBox("app_settings");
  await Hive.openBox("app_presets");
}

void main() async {
  await intiaLizeHive ();

  test('Testing calculateXRadian (vertical phone)', () {
    // phone perfectly upright
    expect(calculateXRadian(0,10,0), 0);
    // phone tilted, but not in X direction
    expect(calculateXRadian(0,5,5), 0);
    // phone tilted 90° to the left
    expect(calculateXRadian(10,0,0), -pi/2);
    // phone tilted 90° to the right
    expect(calculateXRadian(-10,0,0), pi/2);
  });

  test('Testing calculateYRadian (landscape phone)', () {
    // phone perfectly upright
    expect(calculateYRadian(10,0,0), 0);
    // phone tilted, but not in Y direction
    expect(calculateYRadian(5,0,5), 0);
    // phone tilted 90° to the left
    expect(calculateYRadian(0,10,0), pi/2);
    // phone tilted 90° to the right
    expect(calculateYRadian(0,-10,0), -pi/2);
  });

  test('Testing deriveSoundValue', () {
    // 0 degree off should be sound value 0
    expect(deriveSoundValue(0), 0);
    // an angle that is off over the outer_margin stays 1
    expect(deriveSoundValue(50), 1); //actually depends on margins!!! currently set to 45°
    // an angle that is off over the outer margin in the other direction stays -1
    expect(deriveSoundValue(-50), -1);
    // an angle between the margins depends too much on those and possible changes to the function that I don't bother writing tests yet :)
  });
}
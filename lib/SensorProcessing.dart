import 'dart:async';
import 'dart:math';
import 'package:sensors/sensors.dart';

//Mocked Angles
//These mock the tilt angle of the phone, not the displayed angle per se.
//Set to angle in degree or null for no mocking.
const double x_angle_mock = null; //short axis
const double y_angle_mock = null; //long axis

//Values determining the margins (in degree) after which
//sound stops changing
const double inner_margin = 1;
const double outer_margin = 45;


class SensorProcessor {
  StreamSubscription accListener;
  List<double> filteredAcc;

  SensorProcessor() {
    this.filteredAcc = [0, 0, 0];

    accListener = accelerometerEvents.listen((AccelerometerEvent event) {
      filteredAcc = accLowPass(event.x, event.y, event.z);
      });
  }

  void pauseListeners() {
    accListener.pause();
    print("listener paused");
  }

  void resumeListeners() {
    if (accListener.isPaused) {
      accListener.resume();
      print("listener resumed");
    }
  }

  //Simple low pass filter for the accelerometer values
  List<double> accLowPass(double x, double y, double z) {
    const double a = 0.8;
    //List<double> filteredValues = [];
    double filteredX = x * a + filteredAcc[0] * (1 - a);
    double filteredY = y * a + filteredAcc[1] * (1 - a);
    double filteredZ = z * a + filteredAcc[2] * (1 - a);
    return [filteredX, filteredY, filteredZ];
  }

  //Calculates an angle
  //axis=1 -> X
  //axis=2 -> Y
  double calculateAngle(int axis) {
    double rad;
    switch(axis) {
      case 1:
        {
          if (x_angle_mock != null) return x_angle_mock;
          rad =
              calculateXRadian(filteredAcc[0], filteredAcc[1], filteredAcc[2]);
        }
        break;
      case 2:
        {
          if (y_angle_mock != null) return y_angle_mock;
          rad =
              calculateYRadian(filteredAcc[0], filteredAcc[1], filteredAcc[2]);
        }
        break;
    }
    if (rad != null && !rad.isNaN) {
      return rad * (180 / pi);
    } else {
      return 0;
    }
  }
}

//TODO: make this function work as expected
//calculates the angle to be displayed in 2D-mode
//inputs are the angles for the separate axes
double totalDegree2D(double x, double y) {
  double radX = x*pi/180;
  double radY = y*pi/180;
  //up vector
  List vec = [0,0,1];
  //rotated around X
  vec = [0, -sin(radX), cos(radX)];
  //rotated around Y
  vec = [sin(radY)*cos(radX), -sin(radX), cos(radY)*cos(radX)];
  //angle between rotated and up vector
  double abs = acos(vec[2] / sqrt(vec[0].pow(2) + vec[1].pow(2) + vec[2].pow(2)))*180/pi;
  return abs;
}

//Calculate x-radian
double calculateXRadian(double x, double y, double z) {
  return -asin(x / sqrt((x * x) + (y * y) + (z * z)));
}

//Calculate y-radian
double calculateYRadian(double x, double y, double z) {
  return asin(y / sqrt((x * x) + (y * y) + (z * z)));
}

//Outputs fitting pd-input-values according to angles and margins
double deriveSoundValue(double angle) {
  double abs = angle.abs();
  double value = 0;
  if (abs < inner_margin) {
    value = 0;
  } else if (abs > outer_margin) {
    value = 1;
  } else {
    value = (abs - inner_margin) / (outer_margin - inner_margin);
  }
  if (angle < 0) {
    value *= -1;
  }
  return value;
}

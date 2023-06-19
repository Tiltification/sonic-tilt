import 'package:flutter/material.dart';

class FocusPathPainter extends CustomPainter {
  // double animations which manipulate the position and shape of the focus paths
  Animation<double> _pathOneAnimation,
      _pathTwoAnimation,
      _pathThreeMoveToWidthAnimation,
      _pathThreeMoveToHeightAnimation,
      _pathThreeLineToWidthAnimation,
      _pathThreeLineToHeightAnimation;

  // color tween animations which change its color according to
  // the validness of the tilt and recent mode
  Animation _pathAcceptanceColorAnimation, _middlePathModeSwitchColorAnimation;

  // controller for each animation
  AnimationController _controllerPathManipulation;
  AnimationController _controllerColorPath;
  AnimationController _controllerMiddleColorPath;
  Paint _paint;

  // FocusPathPainter constructor receiving the controller and animations
  FocusPathPainter(
      this._controllerPathManipulation,
      this._controllerColorPath,
      this._controllerMiddleColorPath,
      this._pathOneAnimation,
      this._pathTwoAnimation,
      this._pathThreeMoveToWidthAnimation,
      this._pathThreeMoveToHeightAnimation,
      this._pathThreeLineToWidthAnimation,
      this._pathThreeLineToHeightAnimation,
      this._pathAcceptanceColorAnimation,
      this._middlePathModeSwitchColorAnimation) {}

  static bool oldMeasuringIn2DMode = false;
  static bool newMeasuringIn2DMode = false;

  static bool oldValidness = false;
  static bool newValidness = false;

  //Setter for the recent Mode
  static void setNewMode(bool measuringIn2Dmode) {
    newMeasuringIn2DMode = measuringIn2Dmode;
  }

  //Setter for validCenter
  static void setValidness(bool valid) {
    newValidness = valid;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // *  manipulate the outer paths ...
    // *  manipulate the middle path color ...
    // ... according to the mode
    if (newMeasuringIn2DMode) {
      _controllerPathManipulation.reverse();
      _controllerMiddleColorPath.forward();
    } else {
      _controllerPathManipulation.forward();
      _controllerMiddleColorPath.reverse();
    }
    // manipulate the color of the paths according to the validness
    // if it is centered perfectly, turn the color green
    if (newValidness) {
      _controllerColorPath.forward();
    } else {
      _controllerColorPath.reverse();
    }


    // general path paint
    _paint = Paint()
      ..color = _pathAcceptanceColorAnimation.value
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    // path manipulation according to the focusPathAnimator value
    double yStart = size.height * 0.25;
    double yEnd = size.height * 0.75;

    Path path_0 = Path();
    path_0.moveTo(size.width * _pathOneAnimation.value, yStart);
    path_0.lineTo(size.width * _pathOneAnimation.value, yEnd);

    canvas.drawPath(path_0, _paint);

    Path path_1 = Path();
    path_1.moveTo(size.width * _pathTwoAnimation.value, yStart);
    path_1.lineTo(size.width * _pathTwoAnimation.value, yEnd);

    canvas.drawPath(path_1, _paint);

    // painting the middle path
    // it has a different color when in 1D mode and when it is valid
    Paint paint_2 = new Paint()
      ..color = newValidness
          ? _pathAcceptanceColorAnimation.value
          : _middlePathModeSwitchColorAnimation.value
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    // path manipulation according to the focusPathAnimator value
    Path path_2 = Path();
    path_2.moveTo(size.width * _pathThreeMoveToWidthAnimation.value,
        size.height * _pathThreeMoveToHeightAnimation.value);
    path_2.lineTo(size.width * _pathThreeLineToWidthAnimation.value,
        size.height * _pathThreeLineToHeightAnimation.value);

    canvas.drawPath(path_2, paint_2);
  }

  @override
  bool shouldRepaint(FocusPathPainter oldDelegate) {
    // only repaint when the mode is changed, or the tilt is perfectly centered
    // repainting too often costs too many resources
    if (newMeasuringIn2DMode != oldMeasuringIn2DMode ||
        newValidness != oldValidness) {
      oldMeasuringIn2DMode = newMeasuringIn2DMode;
      oldValidness = newValidness;
      return true;
    } else {
      return false;
    }
  }
}

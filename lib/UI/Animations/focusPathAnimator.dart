import 'package:flutter/material.dart';

import '../focusPathPainter.dart';

class FocusPathAnimator extends StatefulWidget {
  FocusPathAnimator({Key key}) : super(key: key);

  _FocusPathAnimatorState createState() => _FocusPathAnimatorState();
}

class _FocusPathAnimatorState extends State<FocusPathAnimator>
    with TickerProviderStateMixin {
  // double animations which manipulate the position and shape of the focus paths
  Animation<double> pathOneAnimation,
      pathTwoAnimation,
      pathThreeMoveToWidthAnimation,
      pathThreeMoveToHeightAnimation,
      pathThreeLineToWidthAnimation,
      pathThreeLineToHeightAnimation;

  // color tween animations which change its color according to
  // the validness of the tilt and recent mode
  Animation pathAcceptanceColorAnimation, middlePathModeSwitchColorAnimation;

  // controller for each animation
  AnimationController controllerPathManipulation;
  AnimationController controllerColorPath;
  AnimationController controllerMiddleColorPath;

  @override
  void initState() {
    super.initState();

    // controller initializations with each a 500 ms duration
    controllerPathManipulation = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);

    controllerColorPath = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);

    controllerMiddleColorPath = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);

    // path animations according to the mode
    pathOneAnimation = Tween<double>(begin: 0.50, end: 0.05).animate(
        CurvedAnimation(
            parent: controllerPathManipulation,
            curve: Curves.ease,
            reverseCurve: Curves.easeOut));

    pathTwoAnimation = Tween<double>(begin: 0.50, end: 0.95).animate(
        CurvedAnimation(
            parent: controllerPathManipulation,
            curve: Curves.ease,
            reverseCurve: Curves.easeOut));

    pathThreeMoveToWidthAnimation = Tween<double>(begin: 0.25, end: 0.50)
        .animate(CurvedAnimation(
            parent: controllerPathManipulation,
            curve: Curves.ease,
            reverseCurve: Curves.easeOut));

    pathThreeMoveToHeightAnimation = Tween<double>(begin: 0.50, end: 0.35)
        .animate(CurvedAnimation(
            parent: controllerPathManipulation,
            curve: Curves.ease,
            reverseCurve: Curves.easeOut));

    pathThreeLineToWidthAnimation = Tween<double>(begin: 0.75, end: 0.50)
        .animate(CurvedAnimation(
            parent: controllerPathManipulation,
            curve: Curves.ease,
            reverseCurve: Curves.easeOut));

    pathThreeLineToHeightAnimation = Tween<double>(begin: 0.50, end: 0.65)
        .animate(CurvedAnimation(
            parent: controllerPathManipulation,
            curve: Curves.ease,
            reverseCurve: Curves.easeOut));

    // color animations according to the validness of the tilt
    // and the recent mode
    //umwebejo        ColorTween(begin: Color(0xffF2F2F2), end: Color(0xff5bdc97))
    //umwebejo        ColorTween(begin: Color(0xff292b2e), end: Color(0xffF2F2F2))
    pathAcceptanceColorAnimation =
        ColorTween(begin: Color(0xffF2F200), end: Color(0xff5bdc00))
            .animate(controllerColorPath);
    middlePathModeSwitchColorAnimation =
        ColorTween(begin: Color(0xff292b00), end: Color(0xffF2F200))
            .animate(controllerMiddleColorPath);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: controllerPathManipulation,
        builder: (BuildContext context, _) {
          return Center(
              child: Container(
                  alignment: Alignment.center,
                  height: 70,
                  width: 70,
              child: CustomPaint(
                    size: Size(1100, 600),
                    // returning the focus path painter and
                    // giving it the animations as well as the controller for them
                    // the controller arent starting in this class,
                    // as we want to manipulate them directly with the repaint function
                    painter: FocusPathPainter(
                        controllerPathManipulation,
                        controllerColorPath,
                        controllerMiddleColorPath,
                        pathOneAnimation,
                        pathTwoAnimation,
                        pathThreeMoveToWidthAnimation,
                        pathThreeMoveToHeightAnimation,
                        pathThreeLineToWidthAnimation,
                        pathThreeLineToHeightAnimation,
                        pathAcceptanceColorAnimation,
                        middlePathModeSwitchColorAnimation
                    ),
              )));
        });
  }

  // disposing controller when they arent used anymore
  @override
  void dispose() {
    controllerPathManipulation.dispose();
    controllerColorPath.dispose();
    controllerMiddleColorPath.dispose();
    super.dispose();
  }
}

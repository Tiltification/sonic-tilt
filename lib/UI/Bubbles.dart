import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive/rive.dart';

import '../LevelTheme.dart';
import 'focusPathPainter.dart';

class Bubbles extends StatefulWidget {
  Bubbles(
      this.measuringIn2DMode,
      this.isLockingModeSelected,
      this.xDotPosition,
      this.yDotPosition,
      this.zDotPosition,
      this.xInclination,
      this.yInclination,
      this.zInclination,
      this.landscapeMode,
      this.landscapeModeLeft);

  bool measuringIn2DMode, landscapeMode, landscapeModeLeft;
  var isLockingModeSelected;
  double xDotPosition,
      yDotPosition,
      zDotPosition,
      xInclination,
      yInclination,
      zInclination;

  _BubblesState createState() => _BubblesState();

  //TODO manual trigger, if needed ~ doesnt look so for the time being
  // void triggerAnimationUpdate() {
    // print("triggered" + xDotPosition.toString());
    // _bubbleState.manipulateBubbleContainersRotationTween();
    // _bubbleState.handle2DBubblePosition();
  // }
}

class _BubblesState extends State<Bubbles> with TickerProviderStateMixin {
  // double animations which manipulate the position and shape of the focus paths

  /// Tracks if the animation is playing by whether controller is running.
  bool get isPlaying => _controller?.isActive ?? false;

  RiveAnimationController _controller;

  final riveFileBubbleOne = 'assets/rive/animation.riv';
  final riveFile2DBubbleOneAnimationNames = [
    "default",
    "load",
    "load-inverse",
    "centered",
    "centered-inverse"
  ];
  Artboard _artboardMainBubble;

  Animation _bubbleContainersRotationAnimation, _oneDWhiteBackgroundAnimation;
  Tween<double> _bubbleContainersRotationTween, _oneDWhiteBackgroundTween;
  AnimationController _bubbleContainersRotationAnimationController,
      _oneDWhiteBackgroundAnimationController;

  int currentBubbleState = 0;
  int currentlyWantedBubbleAnimation = 0;
  Timer centeredAnimationTimer;
  bool isCenterAnimationLockedByTimer = false;
  double rotationToBubble = 0;

  @override
  void initState() {
    super.initState();

    //imports animationfile for rive animations on the bigger bubble
    _loadRiveFile2DMode();

    _initializeTweenAnimations();

    _triggerUpdateAllAnimations();
  }

  // loads a Rive file for following animation of the big bubble
  void _loadRiveFile2DMode() async {
    final bytes = await rootBundle.load(riveFileBubbleOne);
    final file = RiveFile();

    if (_artboardMainBubble == null) {
      if (file.import(bytes)) {
        // Select an animation by its name
        setState(() => _artboardMainBubble = file.mainArtboard
          ..addController(
            SimpleAnimation('default', mix: 1),
          ));
      }
    }
  }

  // triggers animation update every 200 ms
  void _triggerUpdateAllAnimations() {
    const duration = const Duration(milliseconds: 200);
    new Timer.periodic(
        duration,
        (Timer t) => {
              _handle2DBubblePosition(),
              _manipulateBubbleContainersRotationTween(),
              _manipulateOneDModeWhiteBGTween(),
            });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Center(
          child: AnimatedBuilder(
              animation: _bubbleContainersRotationAnimationController,
              builder: (context, child) => Transform.rotate(
                  //rotate white background according to the recent x inclination of the phone
                  angle: _bubbleContainersRotationAnimation.value,
                  alignment: Alignment.center,
                  child: AnimatedAlign(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.linear,
                      // changing alignment according to mode
                      // 1D mode locks the y axis at 0
                      alignment: _returnRecentBubblesAlignment(true),
                      child: ClipOval(
                        child: Container(
                          width: 70,
                          height: 70,
                          color: LevelTheme.darkModeGreen,
                        ),
                      ))))),
      Center(
          child: AnimatedBuilder(
              animation: _bubbleContainersRotationAnimationController,
              builder: (context, child) => Transform.rotate(
                  //rotate white background according to the recent x inclination of the phone
                  angle: _bubbleContainersRotationAnimation.value,
                  alignment: Alignment.center,
                  child: AnimatedAlign(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.linear,
                      // changing alignment according to mode
                      // 1D mode locks the y axis at 0
                      alignment: _returnRecentBubblesAlignment(false),
                      child: RotationTransition(
                          // rotate the animation bubble content according to the position of the second smaller bubble
                          turns: new AlwaysStoppedAnimation(
                              rotationToBubble / 360),
                          child: Container(
                              width: 300,
                              height: 300,
                              child: Rive(artboard: _artboardMainBubble))))))),
      AnimatedContainer(
          // animated controller to animate the changing position of the layer according to the mode
          duration: Duration(milliseconds: 500),
          //according to the mode the white background is positioned outside or inside the screen
          transform:
              ((widget.measuringIn2DMode && widget.isLockingModeSelected[0]) ||
                      widget.isLockingModeSelected[1])
                  ? Matrix4.translationValues(
                      0.0, -MediaQuery.of(context).size.height * 3, 0)
                  : Matrix4.translationValues(
                      0.0, -MediaQuery.of(context).size.height / 2, 0),
          curve: Curves.easeInOut,
          child: AnimatedBuilder(
              animation: _oneDWhiteBackgroundAnimationController,
              builder: (context, child) => Transform.rotate(
                  //rotate white background according to the recent x inclination of the phone
                  angle: _oneDWhiteBackgroundAnimation.value,
                  alignment: Alignment.bottomCenter,
                  child: Transform.scale(
                      scale: 3,
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: double.infinity,
                        height: ((widget.measuringIn2DMode &&
                                    widget.isLockingModeSelected[0]) ||
                                widget.isLockingModeSelected[1])
                            ? 0.0
                            : double.infinity,
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                          color: ((widget.measuringIn2DMode &&
                                      widget.isLockingModeSelected[0]) ||
                                  widget.isLockingModeSelected[1])
                              ? Colors.transparent
                              : LevelTheme.mainLightMode,
                        ),
                      ))))),
    ]);
  }

  // returns bubble alignment for specific bubble
  Alignment _returnRecentBubblesAlignment(greenBubble) {
    double x = widget.xDotPosition;
    double y = widget.yDotPosition;
    // bool oneDMode =
    //     ((!widget.measuringIn2DMode && widget.isLockingModeSelected[0]) ||
    //         widget.isLockingModeSelected[2]);
    bool twoDMode =
        (widget.measuringIn2DMode && widget.isLockingModeSelected[0]) ||
            widget.isLockingModeSelected[1];
    bool landScapeMode = widget.landscapeMode;
    // when we are in landscape mode right, the direction of the axis is flipped
    // we want the same behaviour as on landscapemode left, so we flip the axis manually
    bool landscapeModeLeft = widget.landscapeModeLeft;
    if (greenBubble) {
      return (twoDMode
          ? landScapeMode
              ? landscapeModeLeft
                  ? Alignment(y / 10, x / 10)
                  : Alignment(-y / 10, -x / 10)
              : Alignment(x / 10, y / 10)
          : landScapeMode
              ? Alignment(0, -y / 5)
              : Alignment(x / 10, 0));
    } else {
      return (twoDMode
          ? landScapeMode
              ? landscapeModeLeft
                  ? Alignment(-y / 10, -x / 10)
                  : Alignment(y / 10, x / 10)
              : Alignment(-x / 10, -y / 10)
          : landScapeMode
              ? Alignment(0, y / 2)
              : Alignment(-x / 2, 0));
    }
  }

  // setting up Tween Animations
  void _initializeTweenAnimations() {
    //Buuble containers rotation animation
    _bubbleContainersRotationAnimationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _bubbleContainersRotationTween = Tween(begin: 0.0, end: 0.0 * pi / 180);
    _bubbleContainersRotationAnimation = _bubbleContainersRotationTween.animate(
        CurvedAnimation(
            parent: _bubbleContainersRotationAnimationController,
            curve: Curves.ease,
            reverseCurve: Curves.easeOut));

    //One D White Background rotation animation
    _oneDWhiteBackgroundAnimationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _oneDWhiteBackgroundTween =
        Tween(begin: 0.0, end: widget.xInclination * pi / 180);
    _oneDWhiteBackgroundAnimation = _oneDWhiteBackgroundTween.animate(
        CurvedAnimation(
            parent: _oneDWhiteBackgroundAnimationController,
            curve: Curves.ease,
            reverseCurve: Curves.easeOut));
  }

  void _manipulateBubbleContainersRotationTween() {
    //rotate bubble containers according to current rotation
    _bubbleContainersRotationTween.begin = _bubbleContainersRotationTween.end;
    _bubbleContainersRotationAnimationController.reset();
    // when we are in landscape mode right, the direction of the axis is flipped
    // we want the same behaviour as on landscapemode left, so we flip the axis manually
    bool twoDMode =
        (widget.measuringIn2DMode && widget.isLockingModeSelected[0]) ||
            widget.isLockingModeSelected[1];
    bool landScapeMode = widget.landscapeMode;
    _bubbleContainersRotationTween.end = (twoDMode
            ? 0
            : landScapeMode
                ? (180 - widget.yInclination)
                : landScapeMode
                    ? (180 - widget.yInclination) -
                        90 //why 0.25? => 0.25 === 90°
                    : widget.xInclination) *
        pi /
        180;
    _bubbleContainersRotationAnimationController.forward();
  }

  void _manipulateOneDModeWhiteBGTween() {
    //rotate white 1d layer according to current rotation
    _oneDWhiteBackgroundTween.begin = _oneDWhiteBackgroundTween.end;
    _oneDWhiteBackgroundAnimationController.reset();
    _oneDWhiteBackgroundTween.end = (widget.landscapeMode
            ? ((180.0 - widget.yInclination) - 90.0)
            : widget.xInclination) *
        pi /
        180;
    _oneDWhiteBackgroundAnimationController.forward();
  }

  // Decide on if and when -> which animation should be played.
  void _handle2DBubblePosition() {
    //TODO consider tilt speed and manipulate animationspeed according to it
    // Construct on triggering each animations according to
    // the x, y, z coordinates of the phone/position of the bubbles
    // each position triggers specific animations in the @selectionGraphic function
    // in regards of the previous state of animation
    // print("x: " +
    //     widget.xDotPosition.toString() +
    //     " y: " +
    //     widget.yDotPosition.toString() +
    //     " z: " +
    //     widget.zDotPosition.toString());

    bool oneDMode =
        ((!widget.measuringIn2DMode && widget.isLockingModeSelected[0]) ||
            widget.isLockingModeSelected[2]);
    bool twoDMode =
        ((widget.measuringIn2DMode && widget.isLockingModeSelected[0]) ||
            widget.isLockingModeSelected[1]);

    if (_canTheOuterRiveAnimationBePlayed(oneDMode, twoDMode)) {
      //triggering final centering animation
      if (_canTheInnerRiveAnimationBePlayed(oneDMode, twoDMode)) {
        currentlyWantedBubbleAnimation = 2;
        FocusPathPainter.setValidness(
            true); //animate colorchange on center path, before starting the rive animation

        //we dont want to trigger the center animation everytime the sensors jump into this value and out
        // we want to wait for the user to center is correctly, wait if they changed it, if not = play animation
        if (!isCenterAnimationLockedByTimer) {
          isCenterAnimationLockedByTimer = true;
          centeredAnimationTimer = new Timer.periodic(
              new Duration(seconds: 1),
              (timer) async => {
                    if (currentlyWantedBubbleAnimation == 2)
                      {
                        if (currentBubbleState != 3) {selectGraphic(3)}
                      }
                    else
                      {
                        FocusPathPainter.setValidness(false),
                        //device isnt centered anymore, change color of path, cause maybe no graphic was changed
                      },
                    timer.cancel(),
                    isCenterAnimationLockedByTimer = false
                  });
        }
      } else {
        currentlyWantedBubbleAnimation = 1;
        if (currentBubbleState == 3) {
          selectGraphic(4);
        }
        if (currentBubbleState != 4 && currentBubbleState != 1) {
          selectGraphic(1);
        }
      }
    } else {
      currentlyWantedBubbleAnimation = 0;
      if (currentBubbleState == 1 || currentBubbleState == 4) {
        selectGraphic(2);
      } else if (currentBubbleState == 3) {
        selectGraphic(4);
        selectGraphic(2);
      } else {
        selectGraphic(0);
      }
    }

    bool landScapeMode = widget.landscapeMode;
    // when we are in landscape mode right, the direction of the axis is flipped
    // we want the same behaviour as on landscapemode left, so we flip the axis manually
    bool landscapeModeLeft = widget.landscapeModeLeft;

    // determining the rotation of the animated bubble in the direction of the
    // smaller bubble
    // Difference in 1D and 2D mode is, that the 1D mode doesn't manipulate
    // the y position of the smaller bubble nor the bigger bubble

    rotationToBubble = (twoDMode
        ? landScapeMode
            ? landscapeModeLeft
                ? ((((atan2((-widget.yDotPosition), widget.xDotPosition)) *
                            180.0) /
                        pi)
                    .roundToDouble())
                : ((((atan2((widget.yDotPosition), -widget.xDotPosition)) *
                            180.0) /
                        pi)
                    .roundToDouble())
            : ((((atan2((widget.yDotPosition), (widget.xDotPosition))) *
                            180.0) /
                        pi)
                    .roundToDouble() -
                90.0)
        : landScapeMode
            ? ((((atan2((0), -(widget.yDotPosition))) * 180.0) / pi)
                .roundToDouble())
            : ((((atan2((0), (widget.xDotPosition))) * 180.0) / pi)
                    .roundToDouble() -
                90.0));
  }

  bool _canTheOuterRiveAnimationBePlayed(oneDMode, twoDMode) {
    if (widget.landscapeMode) {
      if ((oneDMode && widget.yDotPosition <= 2 && widget.yDotPosition >= -2) ||
          (twoDMode &&
              (widget.yDotPosition <= 2.1 && widget.yDotPosition >= -2.1) &&
              (widget.xDotPosition <= 5.3 && widget.xDotPosition >= -5.3))) {
        return true;
      } else {
        return false;
      }
    } else {
      if ((oneDMode &&
              (widget.xDotPosition <= 2.7 && widget.xDotPosition >= -2.7)) ||
          (twoDMode &&
              (widget.xDotPosition <= 5.3 &&
                  widget.xDotPosition >= -5.3 &&
                  widget.yDotPosition <= 2.1 &&
                  widget.yDotPosition >= -2.1))) {
        return true;
      } else {
        return false;
      }
    }
  }

  bool _canTheInnerRiveAnimationBePlayed(oneDMode, twoDMode) {
    if (widget.landscapeMode) {
      if ((oneDMode &&
              widget.yDotPosition <= 0.1 &&
              widget.yDotPosition >= -0.1) ||
          (twoDMode &&
              (widget.yDotPosition <= 0.1 && widget.yDotPosition >= -0.1) &&
              (widget.xDotPosition <= 0.1 && widget.xDotPosition >= -0.1))) {
        return true;
      } else {
        return false;
      }
    } else {
      if ((oneDMode &&
              (widget.xDotPosition <= 0.1 && widget.xDotPosition >= -0.1)) ||
          (twoDMode &&
              (widget.xDotPosition <= 0.1 &&
                  widget.xDotPosition >= -0.1 &&
                  widget.yDotPosition <= 0.1 &&
                  widget.yDotPosition >= -0.1))) {
        return true;
      } else {
        return false;
      }
    }
  }

  // Trigger animation which suits the recent position of the small bubble / tilt of the phone
  void selectGraphic(state) {
    if (_artboardMainBubble != null) {
      if (currentBubbleState != state) {
        currentBubbleState = state;
        FocusPathPainter.setValidness(state == 3);
        _artboardMainBubble.artboard
          ..addController(SimpleAnimation(
              riveFile2DBubbleOneAnimationNames[state],
              mix: 1));
      }
    }
  }

  // disposing controller when they arent used anymore
  @override
  void dispose() {
    _bubbleContainersRotationAnimationController.dispose();
    _oneDWhiteBackgroundAnimationController.dispose();
    centeredAnimationTimer?.cancel();

    super.dispose();
  }
}

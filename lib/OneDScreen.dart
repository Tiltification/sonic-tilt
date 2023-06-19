import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart' show TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animated_dialog/flutter_animated_dialog.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';
import 'package:native_device_orientation/native_device_orientation.dart';
import 'package:rive/rive.dart';
import 'package:sensors/sensors.dart';
import 'package:wakelock/wakelock.dart';

import 'Dialogs/PresetDialog.dart';
import 'Dialogs/HelpDialog.dart';
import 'LevelTheme.dart';
import 'UI/Animations/focusPathAnimator.dart';
import 'UI/Bubbles.dart';
import 'UI/focusPathPainter.dart';
import 'SensorProcessing.dart';

//Overarching widget class for the MainScreen
class OneDScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('en', ''),
        // English, no country code
      ],
      title: 'Sonic Tilt',
      home: OneDLevel(title: 'Sonic Tilt Screen'),
      theme: LevelTheme.levelThemeData,
      debugShowCheckedModeBanner: false,
    );
  }
}

//Overarching stateful widget class for the One-Dimensional Level screen
class OneDLevel extends StatefulWidget {
  OneDLevel({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _OneDLevelState createState() => _OneDLevelState();
}

//Current state of Main Screen
class _OneDLevelState extends State<OneDLevel> with WidgetsBindingObserver, TickerProviderStateMixin {
  // The timer to update GUI and sound
  Timer updateTimer;

  // variables to check if calculations are needed
  bool backgroundSound = false;
  bool isInBackground = false;

  // The object handling all sensor value related things
  SensorProcessor sp;

  // Calculated angles in degree
  static double angleX = 0;
  static double angleY = 0;

  var presets = <
      int>[]; //Stores presets as array of int arrays. First element of every element is angle, second is direction
  static int currentPresetAngle = 0; //stores current preset angle
  static int currentPresetDirection =
      -1; //-1 when no angle, 0 for arrowUp, 1 for arrowRight, 2 for arrowDown, 3 for arrowLeft

  // Text to be shown on screen
  String showText = "";
  final appBox = Hive.box(
      'app_settings'); //variable for Hive Box //Box is opened on main.dart
  final presetBox = Hive.box(
      'app_presets'); //variable for preset Hive Box // Box is opened in main.dart

  final isLockingModeSelected = <bool>[true, false, false];
  final isLockingOrientationSelected = <bool>[true, false, false];
  final isHelpSelected = <bool>[false, false, false];
  List<bool> isMainMenuSelected = <bool>[false, false, false, false];
  List<bool> isOffsetMenuSelected = <bool>[false, false, false];
  static bool eyeOpen = false;
  static bool _isDetailedDegreesVisible =
      false; //this variable is used to delay other animations, which are followed by hiding the detailed degrees
  List<bool> presetToggles = <bool>[];
  List<Widget> presetButtons = [];

  static bool landscapeMode = false;
  static bool landscapeModeLeft = true;

  //Is Index of offset in presetList when offset active and -1 when not
  int currentOffsetPicked = -1;

  // begin of sound stuff +++++++++++++++++++++++++++++++++
  static const platform =
      const MethodChannel("sonic_tilt");

  void _applyUserPrefsAfterUIRendered(bool startAudioOnBoot) async {
    try {
      await platform.invokeListMethod("applyUserPrefsAfterUIRendered",
          {"startAudioOnBoot": startAudioOnBoot.toString()});
    } catch (e) {
      print(e);
    }
  }

  void _applyUserPrefsForSoundInBackground(bool play) async {
    //print("background sound: " + play.toString());
    backgroundSound = play;
    try {
      await platform
          .invokeListMethod("playInBackground", {"play": play.toString()});
    } catch (e) {
      print(e);
    }
  }

  void _toggleAudio(bool switchOff) async {
    try {
      await platform
          .invokeListMethod("toggleAudio", {"switchOff": switchOff.toString()});
    } catch (e) {
      print(e);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch(state) {
      case AppLifecycleState.paused:
        isInBackground = true;
        if (!backgroundSound) {
          sp.pauseListeners();
        }
        //print("paused");
        break;
      case AppLifecycleState.resumed:
        isInBackground = false;
        sp.resumeListeners();
        //print("resumed");
        break;
      case AppLifecycleState.inactive:
        //print("inactive");
        break;
      case AppLifecycleState.detached:
        //print("detached");
        break;
    }
  }

  void _sendValueXToLibPd(double value) async {
    try {
      await platform.invokeListMethod("sendAngleXToLibPd", {"targetX": value});
    } catch (e) {
      print(e);
    }
  }

  void _sendValueYToLibPd(double value) async {
    try {
      await platform.invokeListMethod("sendAngleYToLibPd", {"targetY": value});
    } catch (e) {
      print(e);
    }
  }

  void togglePinkNoise(bool pinkMute) async {
    try {
      await platform.invokeListMethod(
          "togglePinkNoise", {"pinkMute": pinkMute.toString()});
    } catch (e) {
      print(e);
    }
  }

  // end of sound stuff ++++++++++++++++++++++++++++++++++
//
  //Changes state of showText to adjust display of angle
  void changeText(String newText) {
    setState(() => showText = newText);
  }

  //Getter for angleX
  static double getAngleX() {
    return angleX;
  }

  static double getAngleY() {
    return angleY;
  }

  //Updates sound and GUI output
  void soundGuiUpdate() {
    angleX = sp.calculateAngle(1);
    angleY = sp.calculateAngle(2);
    if ((measuringIn2DMode && isLockingModeSelected[0]) ||
        isLockingModeSelected[1]) {
      //2D-mode laying on screen needs mirrored X angle
      if (sp.filteredAcc[2] > 0) {
        angleX = -angleX;
      }

      if (!landscapeMode) {
        //preset stuff 2D Mode (just vertical):
        if (currentPresetDirection == 0) {
          angleY += currentPresetAngle;
        } else if (currentPresetDirection == 1) {
          angleX += currentPresetAngle;
        } else if (currentPresetDirection == 2) {
          angleY -= currentPresetAngle;
        } else if (currentPresetDirection == 3) {
          angleX -= currentPresetAngle;
        }
      } else if (landscapeMode && landscapeModeLeft) {
        //preset stuff 2D Mode (left landscape)
        if (currentPresetDirection == 0) {
          angleX += currentPresetAngle;
        } else if (currentPresetDirection == 1) {
          angleY -= currentPresetAngle;
        } else if (currentPresetDirection == 2) {
          angleX -= currentPresetAngle;
        } else if (currentPresetDirection == 3) {
          angleY += currentPresetAngle;
        }
      } else if (landscapeMode && !landscapeModeLeft) {
        //preset stuff 2D Mode (right landscape)
        if (currentPresetDirection == 0) {
          angleX -= currentPresetAngle;
        } else if (currentPresetDirection == 1) {
          angleY += currentPresetAngle;
        } else if (currentPresetDirection == 2) {
          angleX += currentPresetAngle;
        } else if (currentPresetDirection == 3) {
          angleY -= currentPresetAngle;
        }
      }

      //TODO: Calculate the mathematically correct 2D-angle
      changeText(
          sqrt(pow(angleX, 2) + pow(angleY, 2)).round().toString() + "°");
      //similarity to landscape mode is preferred, so the axes passed are switched
      _sendValueXToLibPd(-deriveSoundValue(angleY));
      _sendValueYToLibPd(deriveSoundValue(angleX));
    } else if (((!measuringIn2DMode && isLockingModeSelected[0]) ||
            isLockingModeSelected[2]) &&
        landscapeMode) {
      //the two different landscape modes need opposite angles
      if (sp.filteredAcc[0] < 0) {
        angleY = -angleY;
      }

      //preset stuff landscape:
      if (currentPresetDirection == 1) {
        angleY -= currentPresetAngle;
      } else if (currentPresetDirection == 3) {
        angleY += currentPresetAngle;
      }

      changeText(angleY.round().toString() + "°");
      //we act as if Y-axis was X here to get the same sound
      _sendValueXToLibPd(-deriveSoundValue(angleY));
      _sendValueYToLibPd(0);
    } else if ((!measuringIn2DMode && isLockingModeSelected[0]) ||
        isLockingModeSelected[2]) {
      //the upside down 1D-mode needs mirrored X angle
      if (sp.filteredAcc[1] < 0) {
        angleX = -angleX;
      }

      //preset stuff vertical:
      if (currentPresetDirection == 1) {
        angleX -= currentPresetAngle;
      } else if (currentPresetDirection == 3) {
        angleX += currentPresetAngle;
      }

      changeText(angleX.round().toString() + "°");
      _sendValueXToLibPd(-deriveSoundValue(angleX));
      _sendValueYToLibPd(0);
    }

    /**************Animation related start************************/
    double norm_Of_g = sqrt(sp.filteredAcc[0] * sp.filteredAcc[0] +
        sp.filteredAcc[1] * sp.filteredAcc[1] +
        sp.filteredAcc[2] * sp.filteredAcc[2]);

    //unify x and y
    double x = -angleX / 90;
    double y = angleY / 90;
    double z = sp.filteredAcc[2] / norm_Of_g;

    //unify xDot and yDot
    xDotPosition = angleX / 9;
    yDotPosition = angleY / 9;
    zDotPosition = sp.filteredAcc[2];

    //set coordinate values to 0.0 if it is nearly at this point && round values to have 3 digits after comma
    xDotPosition = _returnCenteredDotPosition(
        ((xDotPosition * 1000).roundToDouble()) /
            1000); //_returnCenteredDotPosition(xDotPosition).roundToDouble();
    yDotPosition = _returnCenteredDotPosition(
        ((yDotPosition * 1000).roundToDouble()) /
            1000); //_returnCenteredDotPosition(yDotPosition).roundToDouble();
    zDotPosition = ((yDotPosition * 1000).roundToDouble()) / 1000;

    // important values for handling rotations and trigger animation
    xInclination = -(asin(x) * (180 / pi)).roundToDouble();
    yInclination = (acos(y) * (180 / pi)).roundToDouble();
    zInclination = (atan(z) * (180 / pi)).roundToDouble();

    /**************Animation related end************************/
  }

  bool _readBackgroundSoundMode() {
    if (appBox.get('backgroundSoundMode') == null) {
      appBox.put('backgroundSoundMode', false);
    }
    return appBox.get('backgroundSoundMode');
  }

  bool _setBackgroundSoundMode(bool playInBackground) {
    appBox.put('backgroundSoundMode', playInBackground);
    _applyUserPrefsForSoundInBackground(playInBackground);
  }

  bool _readSoundMode() {
    if (appBox.get('soundMode') == null) {
      appBox.put('soundMode', false);
    }
    return appBox.get('soundMode');
  }

  bool _setSoundMode(bool newSoundMode) {
    appBox.put('soundMode', newSoundMode);
    _toggleAudio(newSoundMode);
  }

  double _returnCenteredDotPosition(val) {
    if (val <= 0.09 && val >= -0.09) {
      return 0.0;
    } else {
      return val;
    }
  }

  /**************Animation related start************************/
  double xInclination = 0;
  double yInclination = 0;
  double zInclination = 0;
  double xDotPosition = 0;
  double yDotPosition = 0;
  double zDotPosition = 0;

  Bubbles bubblesClass;

  bool measuringIn2DMode = true;

  Animation _presetButtonDirectionAnimation,
      _presetBottomMenuButtonAnimation,
      _detailedDegreeViewAnimation;
  Tween<double> _presetButtonDirectionTween;
  Tween<Offset> _presetBottomMenuButtonTween, _detailedDegreeViewTween;
  AnimationController _presetButtonDirectionAnimationController,
      _presetBottomMenuButtonAnimationController,
      _detailedDegreeViewAnimationController;
  static const _presetBottomMenuButtonAnimationDuration = 500;

  /**************Animation related end************************/

  //Initial settings for the class
  //Adds listener to accelerometer and sets Orientation to portrait
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    //imports animationfile for rive animations on button icons
    //run in separate functions, as awaiting file grabbing in a row takes to much time in one
    _loadLockIconRiveAnimationFiles();
    _loadEyeIconRiveAnimationFiles();
    _loadSoundIconRiveAnimationFiles();

    _initializeTweenAnimations();

    //keep display awake while using the app
    Wakelock.enable();

    //using the encapsulated sensor processing
    sp = new SensorProcessor();

    updateTimer = Timer.periodic(new Duration(milliseconds: 20), (timer) {
      if (!isInBackground || backgroundSound) {
        //print("calculating");
        soundGuiUpdate();
      } else {
        //print("not calculating");
      }
    });
    //Resets fixed orientation from splashscreen
    intializePresetFromHive();
    initializeModeLocksFromHive();
    _applyUserPrefsAfterUIRendered(_readSoundMode());
    _applyUserPrefsForSoundInBackground(_readBackgroundSoundMode());
  }

  // setting up Tween Animations
  void _initializeTweenAnimations() {
    // Preset direction button icon direction animation
    _presetButtonDirectionAnimationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _presetButtonDirectionTween =
        Tween(begin: 0.0, end: currentPresetDirection * 90 * pi / 180);
    _presetButtonDirectionAnimation = _presetButtonDirectionTween.animate(
        CurvedAnimation(
            parent: _presetButtonDirectionAnimationController,
            curve: Curves.ease,
            reverseCurve: Curves.easeOut));

    // Preset bottom menu button chnage from icon to text etc animation
    _presetBottomMenuButtonAnimationController = AnimationController(
        vsync: this,
        duration:
            Duration(milliseconds: _presetBottomMenuButtonAnimationDuration));
    _presetBottomMenuButtonTween =
        Tween<Offset>(begin: Offset.zero, end: const Offset(0.0, -1.5));
    _presetBottomMenuButtonAnimation = _presetBottomMenuButtonTween.animate(
        CurvedAnimation(
            parent: _presetBottomMenuButtonAnimationController,
            curve: Curves.easeIn,
            reverseCurve: Curves.easeOut));

    // slide animation of advanced degree content
    _detailedDegreeViewAnimationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 400));
    _detailedDegreeViewTween =
        Tween<Offset>(begin: Offset.zero, end: const Offset(0.5, 0.0));
    _detailedDegreeViewAnimation = _detailedDegreeViewTween.animate(
        CurvedAnimation(
            parent: _detailedDegreeViewAnimationController,
            curve: Curves.ease,
            reverseCurve: Curves.easeOut));
  }

  final riveFileLockIcon = "assets/rive/lock_icon_animation.riv";
  final riveFileEyeIcon = "assets/rive/eye_icon_animation.riv";
  final riveFileSoundIcon = "assets/rive/sound_icon_animation.riv";

  final riveFileLockIconAnimationNames = [
    "unlock",
    "lock",
    "idle-unlock",
    "idle-lock"
  ];
  final riveFileEyeIconAnimationNames = [
    "open",
    "close",
    "idle-open",
    "idle-close"
  ];
  final riveFileSoundIconAnimationNames = [
    "off",
    "on",
    "bg",
    "idle-off",
    "idle-on",
    "idle-bg"
  ];
  bool _artboardLockIconLocked = false;
  bool _artboardEyeIconLocked = false;
  int _artboardSoundIconLockedPosition = 0;
  Artboard _artboardLockIcon;
  Artboard _artboardEyeIcon;
  Artboard _artboardSoundIcon;

  // loads a Rive file for following animation of icon button
  // run in separate functions, as awaiting file grabbing in a row takes to much time in one
  void _loadLockIconRiveAnimationFiles() async {
    final lockBytes = await rootBundle.load(riveFileLockIcon);
    final lockFile = RiveFile();

    if (_artboardLockIcon == null) {
      if (lockFile.import(lockBytes)) {
        _artboardLockIconLocked = (isLockingModeSelected[1] ||
            isLockingModeSelected[2] ||
            isLockingOrientationSelected[1] ||
            isLockingOrientationSelected[2]);
        // Select an animation by its name
        setState(() => _artboardLockIcon = lockFile.mainArtboard
          ..addController(
            SimpleAnimation(
                riveFileLockIconAnimationNames[
                    (_artboardLockIconLocked ? 3 : 2)],
                mix: 1),
          ));
      }
    }
  }

  // loads a Rive file for following animation of icon button
  void _loadEyeIconRiveAnimationFiles() async {
    final eyeBytes = await rootBundle.load(riveFileEyeIcon);
    final eyeFile = RiveFile();

    if (_artboardEyeIcon == null) {
      if (eyeFile.import(eyeBytes)) {
        _artboardEyeIconLocked = eyeOpen;
        // Select an animation by its name
        setState(() => _artboardEyeIcon = eyeFile.mainArtboard
          ..addController(
            SimpleAnimation(
                riveFileEyeIconAnimationNames[(_artboardEyeIconLocked ? 2 : 3)],
                mix: 1),
          ));
      }
    }
  }

  // loads a Rive file for following animation of icon button
  void _loadSoundIconRiveAnimationFiles() async {
    final soundBytes = await rootBundle.load(riveFileSoundIcon);
    final soundFile = RiveFile();

    if (_artboardSoundIcon == null) {
      if (soundFile.import(soundBytes)) {
        _artboardSoundIconLockedPosition =
            (_readSoundMode() && _readBackgroundSoundMode())
                ? 2
                : (_readSoundMode() && !_readBackgroundSoundMode())
                    ? 1
                    : 0;
        // Select an animation by its name
        setState(() => _artboardSoundIcon = soundFile.mainArtboard
          ..addController(
            SimpleAnimation(
                riveFileSoundIconAnimationNames[
                    (_artboardSoundIconLockedPosition + 3)],
                mix: 1), //+3 for using idle animation (still anim)
          ));
      }
    }
  }

  /**
   * modifies graphic of btn icon artboard according to wanted state
   */
  void _selectGraphicForIcon(btn, state) {
    switch (btn) {
      case "lock":
        if (_artboardLockIcon != null) {
          //dont rerun animation, if same lock was selected
          if ((_artboardLockIconLocked && (state == 0 || state == 2)) ||
              (!_artboardLockIconLocked && (state == 1 || state == 3))) {
            _artboardLockIconLocked = (state == 1) || (state == 3);
            _artboardLockIcon.artboard
              ..addController(SimpleAnimation(
                  riveFileLockIconAnimationNames[state],
                  mix: 1));
          }
        }
        break;
      case "eye":
        if (_artboardEyeIcon != null) {
          //dont rerun animation, if same eye anim was selected
          if ((!_artboardEyeIconLocked && (state == 0 || state == 2)) ||
              (_artboardEyeIconLocked && (state == 1 || state == 3))) {
            _artboardEyeIconLocked = (state == 0) || (state == 2);
            _artboardEyeIcon.artboard
              ..addController(SimpleAnimation(
                  riveFileEyeIconAnimationNames[state],
                  mix: 1));
          }
        }
        break;
      case "sound":
        if (_artboardSoundIcon != null) {
          //dont rerun animation, if same eye anim was selected
          if (_artboardSoundIconLockedPosition != state &&
              _artboardSoundIconLockedPosition != (state + 3)) {
            _artboardSoundIconLockedPosition = state;
            _artboardSoundIcon.artboard
              ..addController(SimpleAnimation(
                  riveFileSoundIconAnimationNames[state],
                  mix: 1));
          }
        }
        break;
    }
  }

  // Set Color of Bottom Menu Rive Artboards
  void _setColorOfBottomMenuRiveArtboards() {
    //set color of lock icon
    if (_artboardLockIcon != null) {
      _artboardLockIcon.forEachComponent((child) {
        if (child is Shape &&
            (child.name == 'lockhead' || child.name == 'lockbody')) {
          final Shape shape = child;
          shape.fills.first.paint.color =
              (isMainMenuSelected[2] || isMainMenuSelected[3])
                  ? LevelTheme.darkModeBlack
                  : LevelTheme.darkModeYellow;
        }
      });
    }
    //set color of sound icon
    if (_artboardSoundIcon != null) {
      _artboardSoundIcon.forEachComponent((child) {
        if (child is Shape &&
            (child.name == 'speaker' ||
                child.name == 'tone_small' ||
                child.name == 'tone_medium' ||
                child.name == 'negate')) {
          final Shape shape = child;
          shape.fills.first.paint.color = ((isMainMenuSelected[1] ||
                  isMainMenuSelected[2] ||
                  isMainMenuSelected[3])
              ? LevelTheme.darkModeBlack
              : LevelTheme.darkModeYellow);
        }
      });
    }
  }

  // Set color of eye icon Rive Artboard
  void _setColorOfEyeRiveArtboard() {
    if (_artboardEyeIcon != null) {
      _artboardEyeIcon.forEachComponent((child) {
        if (child is Shape &&
            (child.name == 'eyehead' || child.name == 'negate')) {
          final Shape shape = child;
          shape.fills.first.paint.color =
              (((!measuringIn2DMode && isLockingModeSelected[0]) ||
                      isLockingModeSelected[2])
                  ? LevelTheme.darkModeBlack
                  : LevelTheme.darkModeYellow);
        }
      });
    }
  }

  //Returns transparent color for button on touch
  //For some reason does not work when I put the Color in directly only when this function returns it
  Color getEyeButtonColor(Set<MaterialState> states) {
    return Colors.transparent;
  }

  //Returns a button for the preset bar with the desired angle as Text and the desired Index on click
  Widget producePresetButton(String presetButtonText) {
    return Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.0),
        child: Text(presetButtonText + "°",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 30,
              color: LevelTheme.darkModeYellow
            )));
  }

  //Adds a preset, preset button and necessary complimentary boolean to the right lists
  void addPreset(int presetIndex, int presetAngle) {
    presetToggles.insert(presetIndex, false);
    presetButtons.insert(
        presetIndex, producePresetButton(presetAngle.toString()));
    presets.insert(presetIndex, presetAngle);
    //All values have to be reset because the indices in the presetlist have changed
    currentOffsetPicked = -1;
    currentPresetAngle = 0;
    currentPresetDirection = -1;
  }

  //Finds the correct index in the list for a new preset
  int findPresetIndex(int presetValue) {
    int currentIndex = 0;
    while (
        currentIndex < presets.length && presetValue > presets[currentIndex]) {
      currentIndex++;
    }
    return currentIndex;
  }

  //Adds preset from the stored data of Hive
  void intializePresetFromHive() {
    if (presetBox.isNotEmpty) {
      //Following two lines make sure presets are still ordered
      //If this does not happen, the presets will be ordered by time added
      //Because Hive does not allow adding presets in specific indices
      var hivePresets = presetBox.values.toList();
      hivePresets.sort();
      //intialize preset
      for (int i = 0; i < hivePresets.length; i++) {
        addPreset(i, hivePresets[i]);
      }
      //initialize currentOffsetPicked
      if (appBox.get('currentOffsetPicked') == null) {
        appBox.put('currentOffsetPicked', -1);
      } else {
        currentOffsetPicked = appBox.get('currentOffsetPicked');
        if (currentOffsetPicked > -1) {
          presetToggles[currentOffsetPicked] = true;
          currentPresetAngle = presets[currentOffsetPicked];
        }
      }
      //initialize currentPresetDirection
      if (appBox.get('currentPresetDirection') == null) {
        appBox.put('currentPresetDirection', 0);
      } else {
        currentPresetDirection = appBox.get('currentPresetDirection');
        _manipulatePresetDirectionButtonTween();
      }
    }
  }

  void soundSwitchController() {
    if (_readSoundMode() && _readBackgroundSoundMode()) {
      _setSoundMode(false);
      _setBackgroundSoundMode(false);
      _selectGraphicForIcon("sound", 0);
    } else if (_readSoundMode() && !_readBackgroundSoundMode()) {
      _setBackgroundSoundMode(true);
      _selectGraphicForIcon("sound", 2);
    } else if (!_readSoundMode() && !_readBackgroundSoundMode()) {
      _setSoundMode(true);
      _setBackgroundSoundMode(false);
      _selectGraphicForIcon("sound", 1);
    }
  }

  void initializeModeLocksFromHive() {
    if (appBox.get('currentAxisLock') == null) {
      appBox.put('currentAxisLock', 0);
    } else {
      for (int i = 0; i < isLockingModeSelected.length; i++) {
        isLockingModeSelected[i] = i == appBox.get('currentAxisLock');
      }
    }
    if (appBox.get('currentOrientationLock') == null) {
      appBox.put('currentOrientationLock', 0);
    } else {
      for (int i = 0; i < isLockingOrientationSelected.length; i++) {
        isLockingOrientationSelected[i] =
            i == appBox.get('currentOrientationLock');
      }
    }

    //select icon animation for lock btn
    bool isAnyLockSelected = (isLockingModeSelected[1] ||
        isLockingModeSelected[2] ||
        isLockingOrientationSelected[1] ||
        isLockingOrientationSelected[2]);
    _selectGraphicForIcon("lock", (isAnyLockSelected ? 3 : 2));
  }

  //save value to the Hive
  void savePresetInHive(value) {
    presetBox.add(value);
  }

  //remove preset value from Hive
  void removePresetFromHive(int index) {
    presetBox.deleteAt(index);
    setCurrentOffsetInHive(-1); //set currentOffsetPicked to -1 in Hive
    setcurrentDirectionInHive(-1); //set currentPresetDirection to 0 in Hive
  }

  //save current offset,direction in Hive
  void setCurrentOffsetInHive(int currentOffset) {
    appBox.put('currentOffsetPicked', currentOffset);
  }

  void setcurrentDirectionInHive(int currentDirection) {
    appBox.put('currentPresetDirection', currentDirection);
  }

  void setAxisInHive(int currentAxisMode) {
    appBox.put('currentAxisLock', currentAxisMode);
  }

  void setOrientationInHive(int currentOrientationMode) {
    appBox.put('currentOrientationLock', currentOrientationMode);
  }

  //Closes whatever menu is currently open
  void closeMenus() {
    if (isMainMenuSelected[2]) {
      isMainMenuSelected[2] = false;
    } else if (isMainMenuSelected[1]) {
      isMainMenuSelected[1] = false;
    } else if (isMainMenuSelected[3]) {
      isMainMenuSelected[3] = false;
    }
    _setColorOfBottomMenuRiveArtboards(); //updates colors of rive anim icons
  }

  void resetPresets() {
    presetToggles[currentOffsetPicked] = false;
    currentOffsetPicked = -1;
    currentPresetAngle = 0;
    currentPresetDirection = -1;
    setCurrentOffsetInHive(
        currentOffsetPicked); //save currentOffsetPicked in Hive
    setcurrentDirectionInHive(currentPresetDirection);
  }

  void _manipulatePresetDirectionButtonTween() {
    //rotate icon according to current preset direction
    _presetButtonDirectionTween.begin = _presetButtonDirectionTween.end;
    _presetButtonDirectionAnimationController.reset();
    _presetButtonDirectionTween.end = currentPresetDirection * 90 * pi / 180;
    _presetButtonDirectionAnimationController.forward();
  }

  //triggers preset bottom animation to slide up and the reverse the sliding
  //meanwhile when the icon/text is hidden, the content changes
  void _triggerBottomMenuPresetButtonAnimation() {
    TickerFuture tickerFuture =
        _presetBottomMenuButtonAnimationController.repeat(reverse: true);
    tickerFuture.timeout(
        Duration(milliseconds: _presetBottomMenuButtonAnimationDuration * 2),
        onTimeout: () {
      _presetBottomMenuButtonAnimationController.forward(from: 0);
      _presetBottomMenuButtonAnimationController.stop(canceled: true);
    });
  }

  //triggers sliding in or out - of detailed degree texts
  void _triggerScaleDetailedDegreeViewAnimation(show) {
    _detailedDegreeViewAnimationController.reset();
    _detailedDegreeViewTween.begin = show ? Offset(-0.5, 0.0) : Offset.zero;
    _detailedDegreeViewTween.end = show ? Offset.zero : Offset(-0.5, 0.0);
    _detailedDegreeViewAnimationController.forward();
  }

  @override
  void dispose() {
    updateTimer.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _presetButtonDirectionAnimationController.dispose();
    _presetBottomMenuButtonAnimationController.dispose();
    _detailedDegreeViewAnimationController.dispose();
    super.dispose();
  }

  //Returns toggleButtons inside the presetBar containing the presets that activate the preset when clicked
  ToggleButtons presetToggleButtons() {
    return ToggleButtons(
      color: LevelTheme.darkModeBlack,
      selectedColor: LevelTheme.darkModeYellow,
      fillColor: Colors.transparent,
      splashColor: Colors.transparent,
      hoverColor: Colors.transparent,
      isSelected: presetToggles,
      renderBorder: false,
      onPressed: (index) async {
        _triggerBottomMenuPresetButtonAnimation(); //triggers carousel animation for presetbutton
        await new Future.delayed(const Duration(
            milliseconds:
                _presetBottomMenuButtonAnimationDuration)); //waits for icon/text to slide out, before changing it
        // Respond to button selection
        setState(() {
          for (int i = 0; i < presetToggles.length; i++) {
            presetToggles[i] = (i == index && currentOffsetPicked != index);
          }
          if (index == currentOffsetPicked) {
            resetPresets();
          } else {
            //New preset is picked so preset values are set
            currentOffsetPicked = index;
            currentPresetAngle = presets[currentOffsetPicked];
            setCurrentOffsetInHive(
                currentOffsetPicked); //save currentOffsetPicked in Hive
            if (isLockingModeSelected[2]) {
              currentPresetDirection = 1;
            } else {
              currentPresetDirection = 0;
            }
            _manipulatePresetDirectionButtonTween();
          }
          setcurrentDirectionInHive(currentPresetDirection);
        });
      },
      children: presetButtons,
    );
  }

  //Returns horizontal ListView that contains the presets as toggle buttons
  ListView presetBar() {
    return ListView(
      scrollDirection: Axis.horizontal,
      shrinkWrap: true,
      //children: presetList
      children: [presetToggleButtons()],
    );
  }

  //Returns gestureDetector on black opacity screen behind menus that will close menus when clicked
  GestureDetector opacityClickDetector() {
    return //Gesture Detector wrapped around opacity screen to ensure that menus
        //can be closed by clicking the screen outside of the menu
        GestureDetector(
      onTap: () {
        closeMenus();
      },
      //Container that spans the whole screen and will put a black opaque
      //background over things when the any of the menus is opened
      child: opacityScreen(),
    );
  }

  //Returns black opacity screen behind menus in front of UI
  AnimatedOpacity opacityScreen() {
    return AnimatedOpacity(
        opacity: isMainMenuSelected[2] ||
                isMainMenuSelected[1] ||
                isMainMenuSelected[3]
            ? 1.0
            : 0.0,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Container(
          height: (isMainMenuSelected[2] ||
                  isMainMenuSelected[1] ||
                  isMainMenuSelected[3])
              ? double.infinity
              : 0.0,
          width: double.infinity,
          decoration: BoxDecoration(
              color: isMainMenuSelected[2] ||
                      isMainMenuSelected[1] ||
                      isMainMenuSelected[3]
                  ? Colors.black.withOpacity(0.5)
                  : Colors.transparent),
        ));
  }

  //Returns Padding that contains the add preset button
  Padding presetAddButton() {
    return Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.0),
        child: Tooltip(
          message: AppLocalizations.of(context).presetButtonText,
          decoration: BoxDecoration(
            color: LevelTheme.darkModeBlack.withOpacity(0.9),
            borderRadius: const BorderRadius.all(Radius.circular(20)),
          ),
          textStyle: TextStyle(color: Colors.white, fontSize: 22),
          showDuration: Duration(seconds: 5),
          preferBelow: true,
          verticalOffset: 30,
          child: FaIcon(FontAwesomeIcons.plus,
              color: LevelTheme.darkModeYellow, size: 24),
          // isMainMenuSelected[2]? 24.0: 0),
        ));
  }

  //Returns Padding that contains the presetdirection button
  Padding presetDirectionButton() {
    return Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.0),
        child: Tooltip(
            message: AppLocalizations.of(context).angleDirection,
            decoration: BoxDecoration(
              color: LevelTheme.darkModeBlack.withOpacity(0.9),
              borderRadius: const BorderRadius.all(Radius.circular(20)),
            ),
            textStyle: TextStyle(color: Colors.white, fontSize: 22),
            showDuration: Duration(seconds: 5),
            preferBelow: true,
            verticalOffset: 30,
            child: (currentOffsetPicked == -1)
                ? Icon(Icons.pivot_table_chart,
                    color: LevelTheme.darkModeBlack, size: 34)
                : AnimatedBuilder(
                    animation: _presetButtonDirectionAnimationController,
                    builder: (context, child) => Transform.rotate(
                        angle: _presetButtonDirectionAnimation.value,
                        child: Icon(Icons.arrow_upward_rounded,
                            color: LevelTheme.darkModeYellow, size: 34)))));
  }

  //Returns Padding that contains the delete preset button
  Padding presetDeleteButton() {
    return Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.0),
        child: Tooltip(
          message: AppLocalizations.of(context).removePreset,
          decoration: BoxDecoration(
            color: LevelTheme.darkModeBlack.withOpacity(0.9),
            borderRadius: const BorderRadius.all(Radius.circular(20)),
          ),
          textStyle: TextStyle(color: Colors.white, fontSize: 22),
          showDuration: Duration(seconds: 5),
          preferBelow: true,
          verticalOffset: 30,
          child: Icon(Icons.delete_rounded,
              color: ((currentOffsetPicked == -1)
                  ? LevelTheme.darkModeBlack
                  : LevelTheme.darkModeYellow),
              size: 34),
          // (isMainMenuSelected[2]) ? 34 : 0),
        ));
  }

  //Returns ToggleButtons that make up the bottom bar in the presets submenu
  //that contains the direction, add preset and delete preset button
  ToggleButtons presetOptionButtons() {
    return ToggleButtons(
      color: LevelTheme.darkModeBlack,
      selectedColor: LevelTheme.darkModeYellow,
      fillColor: Colors.transparent,
      splashColor: Colors.transparent,
      hoverColor: Colors.transparent,
      isSelected: isOffsetMenuSelected,
      renderBorder: false,
      onPressed: (index) {
        // Respond to button selection
        if (index == 0) {
          //-1 means no preset is picked, so if preset is picked this button cycles to the next direction
          if (currentOffsetPicked != -1) {
            setState(() {
              if (!isLockingModeSelected[2]) {
                currentPresetDirection = (currentPresetDirection + 1) % 4;
              } else {
                currentPresetDirection = (currentPresetDirection + 2) % 4;
              }
              _manipulatePresetDirectionButtonTween();
              setcurrentDirectionInHive(
                  currentPresetDirection); //save currentPresetDirection in Hive
            });
          }
        } else if (index == 1) {
          Future result = showAnimatedDialog(
            context: context,
            barrierDismissible: true,
            builder: (BuildContext context2) {
              return CustomDialogue(
                title: AppLocalizations.of(context).presetLabel,
                buttonText: AppLocalizations.of(context).presetButtonText,
                presetDialogue: true,
              );
            },
            animationType: DialogTransitionType.slideFromBottomFade,
            curve: Curves.fastOutSlowIn,
            duration: Duration(milliseconds: 800),
          );
          result.then((value) {
            if (value != null) {
              addPreset(findPresetIndex(value), value);
              savePresetInHive(value);
            }
          }, onError: (error) {
            print(error);
          });
        } else if (index == 2) {
          if (presetButtons.length != 0 && currentOffsetPicked != -1) {
            setState(() {
              presetButtons.removeAt(currentOffsetPicked);
              presetToggles.removeAt(currentOffsetPicked);
              presets.removeAt(currentOffsetPicked);
              removePresetFromHive(currentOffsetPicked);
              currentOffsetPicked = -1;
              currentPresetAngle = 0;
              currentPresetDirection = -1;
            });
          }
        }
      },
      children: [
        presetDirectionButton(),
        presetAddButton(),
        presetDeleteButton(),
      ],
    );
  }

  //Returns animatedOpacity containing the whole preset Submenu
  AnimatedOpacity presetSubmenu() {
    return //Preset Bar
        AnimatedOpacity(
            opacity: isMainMenuSelected[2] ? 1.0 : 0.0,
            duration: Duration(milliseconds: 700),
            curve: Curves.easeInOut,
            child: AnimatedSize(
                curve: Curves.easeInOut,
                vsync: this,
                duration: Duration(milliseconds: 700),
                child: AnimatedContainer(
                  decoration: BoxDecoration(
                      color: LevelTheme.bgColor,
                      borderRadius: BorderRadius.circular(20.0)),
                  // //Height changes from 0 to normal height when offsetUi menu is opened
                  height: 150.0,
                  width: MediaQuery.of(context).size.width * 0.65,
                  padding: EdgeInsets.all(8),
                  transform: isMainMenuSelected[2]
                      ? Matrix4.translationValues(0, 0, 0)
                      : Matrix4.translationValues(0, 300, 0),
                  duration: Duration(milliseconds: 700),
                  curve: Curves.easeInOut,
                  child: Column(children: [
                    Expanded(
                      flex: 5,
                      child: Text(AppLocalizations.of(context).presetLabel,
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: LevelTheme.darkModeYellow)),
                    ),
                    Expanded(flex: 5, child: presetBar()),
                    Expanded(
                        flex: 1,
                        child: Divider(
                          color: LevelTheme.darkModeBlack,
                          height: 20,
                          thickness: 1,
                          indent: 20,
                          endIndent: 20,
                        )),
                    Expanded(flex: 5, child: presetOptionButtons())
                  ]),
                )));
  }

  //Returns button to lock axis in 1D mode
  Padding axis1dButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.0),
      child: Tooltip(
          message: AppLocalizations.of(context).twoAxis,
          decoration: BoxDecoration(
            color: LevelTheme.darkModeBlack.withOpacity(0.9),
            borderRadius: const BorderRadius.all(Radius.circular(20)),
          ),
          textStyle: TextStyle(color: Colors.white, fontSize: 22),
          showDuration: Duration(seconds: 5),
          preferBelow: false,
          verticalOffset: 30,
          child: Icon(Icons.hdr_strong, size: 34)),
    );
  }

  //Returns button to lock axis in 2d mode
  Padding axis2dButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.0),
      child: Tooltip(
          message: AppLocalizations.of(context).oneAxis,
          decoration: BoxDecoration(
            color: LevelTheme.darkModeBlack.withOpacity(0.9),
            borderRadius: const BorderRadius.all(Radius.circular(20)),
          ),
          textStyle: TextStyle(color: Colors.white, fontSize: 22),
          showDuration: Duration(seconds: 5),
          preferBelow: false,
          verticalOffset: 30,
          child: Icon(Icons.tonality_rounded, size: 34)),
    );
  }

  //Returns button to lock axis in automatic mode
  Padding axisAutomaticButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.0),
      child: Tooltip(
          message: AppLocalizations.of(context).automaticMode,
          decoration: BoxDecoration(
            color: LevelTheme.darkModeBlack.withOpacity(0.9),
            borderRadius: const BorderRadius.all(Radius.circular(20)),
          ),
          textStyle: TextStyle(color: Colors.white, fontSize: 22),
          showDuration: Duration(seconds: 5),
          preferBelow: false,
          verticalOffset: 30,
          child: Icon(Icons.cached, size: 34)),
    );
  }

  //Returns ToggleButtons containing the axis lock submenu
  ToggleButtons axisSubmenu() {
    return ToggleButtons(
      color: LevelTheme.darkModeBlack,
      selectedColor: LevelTheme.darkModeYellow,
      fillColor: Colors.transparent,
      splashColor: Colors.transparent,
      hoverColor: Colors.transparent,
      isSelected: isLockingModeSelected,
      renderBorder: false,
      onPressed: (index) {
        // Respond to button selection
        setState(() {
          setAxisInHive(index);
          for (int i = 0; i < isLockingModeSelected.length; i++) {
            isLockingModeSelected[i] = i == index;
          }
          // bubblesClass.triggerAnimationUpdate(); //trigger bubbleanimation on changed mode
          if (index == 2 && currentOffsetPicked != -1) {
            resetPresets();
          }

          //handle icon animation
          _selectGraphicForIcon("lock", (index == 0) ? 0 : 1);

          //update color of eye rive anim
          _setColorOfEyeRiveArtboard();
        });
      },
      children: [
        axisAutomaticButton(),
        axis1dButton(),
        axis2dButton(),
      ],
    );
  }

  //Button for automatic mode in screen orientation submenu
  Padding orientationAutoButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.0),
      child: Tooltip(
          message: AppLocalizations.of(context).automaticOrientation,
          decoration: BoxDecoration(
            color: LevelTheme.darkModeBlack.withOpacity(0.9),
            borderRadius: const BorderRadius.all(Radius.circular(20)),
          ),
          textStyle: TextStyle(color: Colors.white, fontSize: 22),
          showDuration: Duration(seconds: 5),
          preferBelow: true,
          verticalOffset: 30,
          child: Icon(Icons.cached, size: 34)),
    );
  }

  //Returns button to lock orientation in portrait mode
  Padding orientationPortraitButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.0),
      child: Tooltip(
          message: AppLocalizations.of(context).portraitMode,
          decoration: BoxDecoration(
            color: LevelTheme.darkModeBlack.withOpacity(0.9),
            borderRadius: const BorderRadius.all(Radius.circular(20)),
          ),
          textStyle: TextStyle(color: Colors.white, fontSize: 22),
          showDuration: Duration(seconds: 5),
          preferBelow: true,
          verticalOffset: 30,
          child: Icon(Icons.screen_lock_portrait_rounded, size: 34)),
    );
  }

  //Returns button to lock orientation in landscape mode
  Padding orientationLandscapeButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.0),
      child: Tooltip(
          message: AppLocalizations.of(context).landscapeMode,
          decoration: BoxDecoration(
            color: LevelTheme.darkModeBlack.withOpacity(0.9),
            borderRadius: const BorderRadius.all(Radius.circular(20)),
          ),
          textStyle: TextStyle(color: Colors.white, fontSize: 22),
          showDuration: Duration(seconds: 5),
          preferBelow: true,
          verticalOffset: 30,
          child: Icon(Icons.screen_lock_landscape_rounded, size: 34)),
    );
  }

  //Returns the orientation lock submenu
  ToggleButtons orientationSubmenu() {
    return ToggleButtons(
      color: LevelTheme.darkModeBlack,
      selectedColor: LevelTheme.darkModeYellow,
      fillColor: Colors.transparent,
      splashColor: Colors.transparent,
      hoverColor: Colors.transparent,
      isSelected: isLockingOrientationSelected,
      renderBorder: false,
      onPressed: (index) {
        // Respond to button selection
        setState(() {
          setOrientationInHive(index);
          for (int i = 0; i < isLockingOrientationSelected.length; i++) {
            isLockingOrientationSelected[i] = i == index;
            if (isLockingOrientationSelected[1]) {
              landscapeMode = false;
              SystemChrome.setPreferredOrientations(
                  [DeviceOrientation.portraitUp]);
            } else if (isLockingOrientationSelected[2]) {
              landscapeMode = true;
              SystemChrome.setPreferredOrientations(
                  [DeviceOrientation.landscapeLeft]);
            }
          }
          //handle icon animation
          _selectGraphicForIcon("lock", (index == 0) ? 0 : 1);
          // bubblesClass.triggerAnimationUpdate(); //trigger bubbleanimation on changed mode
        });
      },
      children: [
        orientationAutoButton(),
        orientationPortraitButton(),
        orientationLandscapeButton(),
      ],
    );
  }

  //Animated Opacity containing the whole locking submenu
  Positioned lockSubmenu() {
    return Positioned(
        bottom: 0,
        child: AnimatedOpacity(
            opacity: isMainMenuSelected[1] ? 1.0 : 0.0,
            duration: Duration(milliseconds: 700),
            curve: Curves.easeInOut,
            child: AnimatedSize(
                curve: Curves.easeInOut,
                vsync: this,
                duration: Duration(milliseconds: 700),
                child: AnimatedContainer(
                    decoration: BoxDecoration(
                        color: LevelTheme.bgColor,
                        borderRadius: BorderRadius.circular(20.0)),
                    width: landscapeMode
                        ? MediaQuery.of(context).size.width * 0.35
                        : MediaQuery.of(context).size.width * 0.65,
                    padding: EdgeInsets.all(8),
                    transform: isMainMenuSelected[1]
                        ? Matrix4.translationValues(0, 0, 0)
                        //-MediaQuery.of(context).size.height * 3, 0)
                        : Matrix4.translationValues(0, 300, 0),
                    //-MediaQuery.of(context).size.height / 2, 0),
                    duration: Duration(milliseconds: 700),
                    curve: Curves.easeInOut,
                    child: Align(
                        alignment: Alignment.center,
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              axisSubmenu(),
                              Divider(
                                color: LevelTheme.darkModeBlack,
                                height: 20,
                                thickness: 1,
                                indent: 20,
                                endIndent: 20,
                              ),
                              orientationSubmenu(),
                            ]))))));
  }

  HelpDialog impressumDialog() {
    return HelpDialog(
      title: AppLocalizations.of(context).imprint,
      htmlBody: AppLocalizations.of(context).imprintText,
      buttonText: AppLocalizations.of(context).imprintClose,
      socialBar: false,
    );
  }

  HelpDialog faqDialog() {
    return HelpDialog(
      title: AppLocalizations.of(context).faqLabel,
      htmlBody: AppLocalizations.of(context).faqText,
      buttonText: AppLocalizations.of(context).imprintClose,
      socialBar: false,
    );
  }

  HelpDialog contactDialog() {
    return HelpDialog(
      title: AppLocalizations.of(context).contact,
      htmlBody: AppLocalizations.of(context).contactText,
      buttonText: AppLocalizations.of(context).imprintClose,
      socialBar: true,
    );
  }

  //Imprint Button in help menu
  Column helpImprintButton() {
    return Column(children: [
      Padding(
          padding: EdgeInsets.symmetric(vertical: 3.0),
          child: Icon(Icons.policy_rounded, size: 28)),
      Text(AppLocalizations.of(context).imprint,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: LevelTheme.darkModeYellow)),
    ]);
  }

  //Faq button in help menu
  Column helpFaqButton() {
    return Column(children: [
      Padding(
          padding: EdgeInsets.symmetric(vertical: 3.0),
          child: Icon(Icons.question_answer_rounded, size: 28)),
      Text('FAQ',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: LevelTheme.darkModeYellow)),
    ]);
  }

  //Contact button in help menu
  Column helpContactButton() {
    return Column(children: [
      Padding(
          padding: EdgeInsets.symmetric(vertical: 3.0),
          child: Icon(Icons.contact_mail_rounded, size: 28)),
      Text(AppLocalizations.of(context).contact,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: LevelTheme.darkModeYellow)),
    ]);
  }

  //Returns buttons in the help submenu
  ToggleButtons helpButtons() {
    return ToggleButtons(
        color: LevelTheme.darkModeYellow,
        selectedColor: LevelTheme.darkModeYellow,
        fillColor: Colors.transparent,
        splashColor: Colors.transparent,
        hoverColor: Colors.transparent,
        constraints: BoxConstraints.expand(
            width: (MediaQuery.of(context).size.width * 0.65) / 3),
        isSelected: isHelpSelected,
        renderBorder: false,
        onPressed: (index) {
          // Respond to button selection
          setState(() {
            if (index == 0) {
              showAnimatedDialog(
                context: context,
                barrierDismissible: true,
                builder: (BuildContext context2) {
                  return impressumDialog();
                },
                animationType: DialogTransitionType.slideFromBottomFade,
                curve: Curves.fastOutSlowIn,
                duration: Duration(milliseconds: 800),
              );
            } else if (index == 1) {
              showAnimatedDialog(
                context: context,
                barrierDismissible: true,
                builder: (BuildContext context2) {
                  return faqDialog();
                },
                animationType: DialogTransitionType.slideFromBottomFade,
                curve: Curves.fastOutSlowIn,
                duration: Duration(milliseconds: 800),
              );
            } else if (index == 2) {
              showAnimatedDialog(
                context: context,
                barrierDismissible: true,
                builder: (BuildContext context2) {
                  return contactDialog();
                },
                animationType: DialogTransitionType.slideFromBottomFade,
                curve: Curves.fastOutSlowIn,
                duration: Duration(milliseconds: 800),
              );
            }
          });
        },
        children: [
          helpImprintButton(),
          helpFaqButton(),
          helpContactButton(),
        ]);
  }

  //Returns positioned containing the help submenu
  Positioned helpSubmenu() {
    return Positioned(
        bottom: 0,
        child: AnimatedOpacity(
            opacity: isMainMenuSelected[3] ? 1.0 : 0.0,
            duration: Duration(milliseconds: 700),
            child: AnimatedSize(
              curve: Curves.easeInOut,
              vsync: this,
              duration: Duration(milliseconds: 700),
              child: AnimatedContainer(
                  decoration: BoxDecoration(
                      color: LevelTheme.bgColor,
                      borderRadius: BorderRadius.circular(20.0)),
                  padding: EdgeInsets.all(10),
                  transform: isMainMenuSelected[3]
                      ? Matrix4.translationValues(0, 0, 0)
                      : Matrix4.translationValues(0, 300, 0),
                  duration: Duration(milliseconds: 700),
                  curve: Curves.easeInOut,
                  child: Align(
                    alignment: Alignment.center,
                    child: helpButtons(),
                  )),
            )));
  }

  //MainMenu Sound on/off button
  Tooltip mainSoundButton() {
    return Tooltip(
        message: _readSoundMode() && _readBackgroundSoundMode()
            ? AppLocalizations.of(context).soundOn
            : _readSoundMode() && !_readBackgroundSoundMode()
                ? AppLocalizations.of(context).inAppSound
                : AppLocalizations.of(context).soundOff,
        decoration: BoxDecoration(
          color: (isMainMenuSelected[1] ||
                  isMainMenuSelected[2] ||
                  isMainMenuSelected[3])
              ? LevelTheme.bgColor.withOpacity(0.9)
              : LevelTheme.darkModeBlack.withOpacity(0.9),
          borderRadius: const BorderRadius.all(Radius.circular(20)),
        ),
        textStyle: TextStyle(color: Colors.white, fontSize: 22),
        showDuration: Duration(seconds: 5),
        preferBelow: true,
        verticalOffset: 30,
        child: Container(
            width: 35, height: 35, child: Rive(artboard: _artboardSoundIcon)));
  }

  //Main menu lock button
  Tooltip mainLockButton() {
    return Tooltip(
        message: (isLockingModeSelected[1] ||
                isLockingModeSelected[2] ||
                isLockingOrientationSelected[1] ||
                isLockingOrientationSelected[2])
            ? AppLocalizations.of(context).locked
            : AppLocalizations.of(context).unlocked,
        decoration: BoxDecoration(
          color: (isMainMenuSelected[1] ||
                  isMainMenuSelected[2] ||
                  isMainMenuSelected[3])
              ? LevelTheme.bgColor.withOpacity(0.9)
              : LevelTheme.darkModeBlack.withOpacity(0.9),
          borderRadius: const BorderRadius.all(Radius.circular(20)),
        ),
        textStyle: TextStyle(color: Colors.white, fontSize: 22),
        showDuration: Duration(seconds: 5),
        preferBelow: true,
        verticalOffset: 30,
        child: Container(
            width: 35, height: 35, child: Rive(artboard: _artboardLockIcon)));
  }

  //Main menu preset button
  Tooltip mainPresetButton() {
    return Tooltip(
        message: AppLocalizations.of(context).preset,
        decoration: BoxDecoration(
          color: (isMainMenuSelected[1] ||
                  isMainMenuSelected[2] ||
                  isMainMenuSelected[3])
              ? LevelTheme.bgColor.withOpacity(0.9)
              : LevelTheme.darkModeBlack.withOpacity(0.9),
          borderRadius: const BorderRadius.all(Radius.circular(20)),
        ),
        textStyle: TextStyle(color: Colors.white, fontSize: 22),
        showDuration: Duration(seconds: 5),
        preferBelow: true,
        verticalOffset: 30,
        child: SlideTransition(
            position: _presetBottomMenuButtonAnimation,
            child: currentOffsetPicked != -1
                ? Text(presets[currentOffsetPicked].toString() + '°',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: (isMainMenuSelected[1] || isMainMenuSelected[3])
                            ? LevelTheme.darkModeBlack
                            : LevelTheme.darkModeYellow))
                : Icon(Icons.perm_data_setting_rounded,
                    size: 32,
                    color: (isMainMenuSelected[1] || isMainMenuSelected[3])
                        ? LevelTheme.darkModeBlack
                        : LevelTheme.darkModeYellow)));
  }

  //Main Menu help button
  Tooltip mainHelpButton() {
    return Tooltip(
      message: AppLocalizations.of(context).help,
      decoration: BoxDecoration(
        color: (isMainMenuSelected[1] ||
                isMainMenuSelected[2] ||
                isMainMenuSelected[3])
            ? LevelTheme.bgColor.withOpacity(0.9)
            : LevelTheme.darkModeBlack.withOpacity(0.9),
        borderRadius: const BorderRadius.all(Radius.circular(20)),
      ),
      textStyle: TextStyle(color: Colors.white, fontSize: 22),
      showDuration: Duration(seconds: 5),
      preferBelow: true,
      verticalOffset: 30,
      child: FaIcon(FontAwesomeIcons.question,
          size: 28,
          color: (isMainMenuSelected[2] || isMainMenuSelected[1])
              ? LevelTheme.darkModeBlack
              : LevelTheme.darkModeYellow),
    );
  }

  //Returns ToggleButtons containing the main menu buttons
  ToggleButtons mainMenuButtons() {
    return ToggleButtons(
      color: LevelTheme.darkModeBlack,
      selectedColor: LevelTheme.darkModeYellow,
      fillColor: Colors.transparent,
      splashColor: Colors.transparent,
      hoverColor: Colors.transparent,
      isSelected: isMainMenuSelected,
      constraints: BoxConstraints.expand(
          width: landscapeMode
              ? ((MediaQuery.of(context).size.width * 0.35) / 4)
              : ((MediaQuery.of(context).size.width * 0.60) / 4),
          height: 50),
      renderBorder: false,
      onPressed: (index) {
        // Respond to button selection
        setState(() {
          for (int i = 0; i < isMainMenuSelected.length; i++) {
            isMainMenuSelected[i] =
                (i == index && isMainMenuSelected[i] == false);
          }
          if (index == 0) {
            soundSwitchController();
          }

          _setColorOfBottomMenuRiveArtboards();
        });
      },
      children: [
        mainSoundButton(),
        mainLockButton(),
        mainPresetButton(),
        mainHelpButton(),
      ],
    );
  }

  //Returns Align that contains bottom menu that's always visible
  Align mainMenu() {
    return Align(
        alignment: Alignment.center,
        //Container with bottom row of buttons that are always visible
        child: Container(
            margin: EdgeInsets.only(
                top: 30.0,
                right: 50.0,
                left: 50.0,
                bottom: landscapeMode ? 30.0 : 50.0),
            width: landscapeMode
                ? MediaQuery.of(context).size.width * 0.40
                : MediaQuery.of(context).size.width * 0.65,
            decoration: BoxDecoration(
                color: LevelTheme.bgColor,
                borderRadius: BorderRadius.circular(100.0)),
            //Align that keeps the buttons centered inside the menu
            //Both Aligns are needed!
            child:
                Align(alignment: Alignment.center, child: mainMenuButtons())));
  }

  //Build instructions for the one direction level screen
  @override
  Widget build(BuildContext context) {
    //WillPopScope allows to put in a veto when user tries to close app with back button
    return new WillPopScope(
        onWillPop: () async {
          //If any menu is open menu gets closed and the exit gets vetoed
          if (isMainMenuSelected[1] ||
              isMainMenuSelected[2] ||
              isMainMenuSelected[3]) {
            closeMenus();
            return false;
          } else {
            //If no menu is open the back button lets you exit the app
            return true;
          }
        },
        child: Scaffold(
            resizeToAvoidBottomPadding: false,
            //needed to avoid pixeloverflows with opening a keyboard
            body: Container(
                decoration: BoxDecoration(
                  color: LevelTheme.bgColor,
                ),
                child: Stack(children: [
                  //return bubbles and the white background for 1D mode
                  Center(
                    child: bubblesClass = Bubbles(
                        measuringIn2DMode,
                        isLockingModeSelected,
                        xDotPosition,
                        yDotPosition,
                        zDotPosition,
                        xInclination,
                        yInclination,
                        zInclination,
                        landscapeMode,
                        landscapeModeLeft),
                  ),
                  // Change from 1D to 2D mode regarding the tilt of the phone and it's orientation
                  NativeDeviceOrientationReader(
                    builder: (context) {
                      var platform = Theme.of(context).platform;
                      final orientation =
                          NativeDeviceOrientationReader.orientation(context);
                      if (orientation == NativeDeviceOrientation.portraitUp ||
                          orientation == NativeDeviceOrientation.portraitDown) {
                        // 1D mode is triggered when the zInclination is at 20 or - 20 degrees
                        // so when the phone is straight up -> 1D mode is triggered
                        if (measuringIn2DMode) {
                          measuringIn2DMode =
                              !((angleX > 55.0 && landscapeMode) ||
                                  (angleX < -55.0 && landscapeMode) ||
                                  angleY > 55.0 ||
                                  angleY < -55.0);
                        } else {
                          measuringIn2DMode =
                          !((angleX > 30.0 && landscapeMode) ||
                              (angleX < -30.0 && landscapeMode) ||
                              angleY > 30.0 ||
                              angleY < -30.0);
                        }
                        //only change to landscape mode, if autoswitching orientation is enabled
                        if ((isLockingOrientationSelected[0] &&
                                !isLockingModeSelected[1]) ||
                            //handling 2d in autoorientation, to make laying phone down in landscape mode, possible
                            (isLockingOrientationSelected[0] &&
                                isLockingModeSelected[1] &&
                                (zInclination.roundToDouble() < 12.0 &&
                                    zInclination.roundToDouble() > -12.0))) {
                          landscapeMode = false;

                          final landScapeOrientation = (orientation ==
                                  NativeDeviceOrientation.portraitUp)
                              ? [DeviceOrientation.portraitUp]
                              : [DeviceOrientation.portraitDown];
                          SystemChrome.setPreferredOrientations(
                              landScapeOrientation);
                        }
                      } else if (orientation ==
                              NativeDeviceOrientation.landscapeLeft ||
                          orientation ==
                              NativeDeviceOrientation.landscapeRight) {
                        //landscapeMode = true;
                        // measuringIn2DMode =
                        //     !(zInclination.roundToDouble() < 20.0 &&
                        //         zInclination.roundToDouble() > -20.0);
                        if (measuringIn2DMode) {
                          measuringIn2DMode =
                          !((angleX > 55.0 && landscapeMode) ||
                              (angleX < -55.0 && landscapeMode) ||
                              angleY > 55.0 ||
                              angleY < -55.0);
                        } else {
                          measuringIn2DMode =
                          !((angleX > 30.0 && landscapeMode) ||
                              (angleX < -30.0 && landscapeMode) ||
                              angleY > 30.0 ||
                              angleY < -30.0);
                        }
                        if ((zInclination.roundToDouble() < 20.0 &&
                                zInclination.roundToDouble() > -20.0) &&
                            //ignore trigger, if phone is straight, which means the user is trying to level portrait in 1D mode
                            !(zInclination.roundToDouble() < 3.0 &&
                                zInclination.roundToDouble() > -3)) {
                          measuringIn2DMode = false;

                          //only change to landscape mode, if autoswitching orientation is enabled
                          if (isLockingOrientationSelected[0]) {
                            landscapeMode = true;

                            if (platform == TargetPlatform.android) {
                              final landScapeOrientation = (orientation ==
                                      NativeDeviceOrientation.landscapeRight)
                                  ? [DeviceOrientation.landscapeRight]
                                  : [DeviceOrientation.landscapeLeft];
                              landscapeModeLeft = (orientation ==
                                  NativeDeviceOrientation
                                      .landscapeLeft); //needed for preset orientation
                              SystemChrome.setPreferredOrientations(
                                  landScapeOrientation);
                            } else {
                              final landScapeOrientation = (orientation ==
                                      NativeDeviceOrientation.landscapeRight)
                                  ? [DeviceOrientation.landscapeLeft]
                                  : [DeviceOrientation.landscapeRight];
                              landscapeModeLeft = (orientation ==
                                  NativeDeviceOrientation
                                      .landscapeLeft); //needed for preset orientation
                              SystemChrome.setPreferredOrientations(
                                  landScapeOrientation);
                            }
                          }
                        }
                      } else {
                        measuringIn2DMode = true;
                      }

                      //send recent mode to linepainter
                      FocusPathPainter.setNewMode(
                          ((measuringIn2DMode && isLockingModeSelected[0]) ||
                              isLockingModeSelected[1]));

                      //update color of eye rive anim
                      _setColorOfEyeRiveArtboard();

                      //starts focusPathAnimations and it's costum painter
                      return FocusPathAnimator();
                    },
                    // use sensors to determine orientation, instead of just reading it's locked orientation (if phone orientation mode switch is locked)
                    useSensor: true,
                  ),
                  //All menu button on the top of the screen
                  Container(
                    margin: EdgeInsets.only(
                        top: landscapeMode
                            ? 0.0
                            : (MediaQuery.of(context).size.width * 0.1),
                        bottom: landscapeMode ? 0.0 : 30.0),
                    child: Column(children: [
                      AnimatedContainer(
                          duration: Duration(milliseconds: 500),
                          margin: EdgeInsets.only(
                              top: landscapeMode ? 20.0 : 30.0,
                              bottom: landscapeMode ? 0.0 : 10.0),
                          width: 50,
                          height: 50,
                          child: IconButton(
                            icon: Tooltip(
                                message: eyeOpen
                                    ? AppLocalizations.of(context).hideAngles
                                    : AppLocalizations.of(context).showAngles,
                                decoration: BoxDecoration(
                                  color:
                                      LevelTheme.darkModeBlack.withOpacity(0.9),
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(20)),
                                ),
                                textStyle: TextStyle(
                                    color: Colors.white, fontSize: 22),
                                showDuration: Duration(seconds: 5),
                                preferBelow: false,
                                verticalOffset: 20,
                                child: Container(
                                    child: Rive(artboard: _artboardEyeIcon))),
                            onPressed: () {
                              eyeOpen = !eyeOpen;
                              _triggerScaleDetailedDegreeViewAnimation(eyeOpen);
                              _selectGraphicForIcon("eye", (eyeOpen ? 0 : 1));
                              if (eyeOpen) {
                                _isDetailedDegreesVisible = true;
                              }
                            },
                          )),
                      //Row containing the two text displays
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('$showText',
                                style: ((measuringIn2DMode &&
                                            isLockingModeSelected[0]) ||
                                        isLockingModeSelected[1])
                                    ? Theme.of(context).textTheme.bodyText2
                                    : Theme.of(context)
                                        .textTheme
                                        .bodyText2
                                        .apply(color: LevelTheme.bgColor)),
                            AnimatedOpacity(
                                opacity: eyeOpen ? 1.0 : 0.0,
                                duration: Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                                onEnd: () {
                                  setState(() {
                                    if (!eyeOpen) {
                                      //this variable is used to delay other animations,
                                      //which are followed by hiding the detailed degrees
                                      _isDetailedDegreesVisible = false;
                                    }
                                  });
                                },
                                child: SlideTransition(
                                    position: _detailedDegreeViewAnimation,
                                    //that can be toggled with the eye icon
                                    child: AnimatedSize(
                                      curve: Curves.easeInOut,
                                      vsync: this,
                                      duration: Duration(milliseconds: 400),
                                      child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            //Column containing the two more detailed X and Y angles
                                            Text(
                                                _isDetailedDegreesVisible
                                                    ? 'X: ${angleX.round()} °'
                                                    : "",
                                                style: ((measuringIn2DMode &&
                                                            isLockingModeSelected[
                                                                0]) ||
                                                        isLockingModeSelected[
                                                            1])
                                                    ? Theme.of(context)
                                                        .textTheme
                                                        .bodyText1
                                                    : Theme.of(context)
                                                        .textTheme
                                                        .bodyText1
                                                        .apply(
                                                            color: LevelTheme
                                                                .bgColor)),
                                            Text(
                                                _isDetailedDegreesVisible
                                                    ? 'Y: ${angleY.round()} °'
                                                    : "",
                                                style: ((measuringIn2DMode &&
                                                            isLockingModeSelected[
                                                                0]) ||
                                                        isLockingModeSelected[
                                                            1])
                                                    ? Theme.of(context)
                                                        .textTheme
                                                        .bodyText1
                                                    : Theme.of(context)
                                                        .textTheme
                                                        .bodyText1
                                                        .apply(
                                                            color: LevelTheme
                                                                .bgColor))
                                          ]),
                                    )))
                          ]),
                    ]),
                  ),
                  //Black opacity layer between menus
                  opacityClickDetector(),
                  //Column containing all the menu buttons and aligned to the bottom
                  // to prevent menu moving downwards when offset buttons appear
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              lockSubmenu(),
                              presetSubmenu(),
                              helpSubmenu(),
                            ]),
                        //Align that keeps the bottom row of buttons centered on the screen
                        mainMenu(),
                      ]),
                ]))));
  }
}

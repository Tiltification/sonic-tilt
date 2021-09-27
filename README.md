![MIT Licence](https://badges.frapsoft.com/os/mit/mit.svg?v=103)

# Sonic Tilt

Sonic Tilt is the open-source branch of Tiltification, the sound leveling app on both iOS and Android. For more information, check out our [website](https://tiltification.uni-bremen.de/).

In this document we will describe how to set up the development environment and explain a few implementation details that might be useful.

The App is written in [flutter](https://flutter.dev/) and ships to both Android and iOS.

## Table of Contents

1. [Setting up the Development Environment](#setting-up-the-development-environment)
1. [Implementation](#implementation)
1. [License](#license)
1. [CI/CD for your own Project](#cicd-for-your-own-project)
1. [Errors, Troubleshooting and Misc](#errors-troubleshooting-and-misc)

## Setting up the Development Environment

### Installing flutter

Please refer to the [flutter installation guide](https://flutter.dev/docs/get-started/install) and follow the instructions described in the guide for your platform.

### IDE

Generally any current IDE or text editor can be used. Additionally it is necessary to use the platform specific IDEs for Android (Android-Studio) and Mac (xCode), though that should be covered in the `flutter` installation guide.

### Android NDK Setup in Android Studio

It is necessary to install the Android NDK because we use native Android-Code in our `flutter`-application. We use NDK version `r21d`. There are two ways to install the NDK:

- Via Android-Studio: Refer to the [official guide](https://developer.android.com/studio/projects/install-ndk). If there is an issue, where Android-Studio cannot find the NDK, even though it was just installed, check where Android-Studio installed the NDK files to. If it was installed into a folder which is named after the version, then move the files inside that folder to the encompassing `ndk`-folder.

- Manually via Download: Download the NDK from <https://developer.android.com/ndk/downloads>. Extract it, rename the folder to `ndk-bundle`, and save it somewhere on your PC. A good location would, for example, be `<path-to-android-suite>/Android/sdk/ndk-bundle`. Then in Android-Studio specify the path to the NDK, via `Project-Structure/sdk`. You can also refer to this [stackoverflow article](https://stackoverflow.com/questions/40474050/android-studio-where-to-install-ndk-file-downloaded-it-in-zip).

### Creating Local Builds Android

If Android Studio is set up properly and the other steps from the `flutter`-guide have been followed as well, then local builds can be created via the build command. If there are issues when trying to create `release`-builds, check the build configuration in the `build.gradle`-file under `android/app`.

### Setting up the project in XCode

First, run `flutter pub get` in the project's root directory. Then execute the command `pod install` in the `ios` directory right after. These commands should install all needed dependencies.

### Creating Local Builds iOS

In xCode, select `Runner`, then navigate to `General/Signing&Capabilities/Signing`. Select your Apple developer account and change the bundle-identifier to one that is not already registered.

### Using Simulators for Screenshots and Capturing Sounds

Since the simulators do not provide sensor values (at least in iOS) the UI will not be properly rendered and thus does not allow to take useful screenshots for, e.g., the App Store product page. We implemented a work-around for that, in which values can be set and used instead of the sensors. Thus the UI will get rendered and you can take screenshots. Set the values here in `lib/SensorProcessing.dart`:

``` dart
//Mocked Angles
//These mock the tilt angle of the phone, not the displayed angle per se.
//Set to angle in degree or null for no mocking.
const double x_angle_mock = null; //short axis
const double y_angle_mock = null; //long axis
```

### Running Tests locally for different Platforms

- `flutter`

    change into the root directory of the project and run `flutter test`

- `android`

    change into the `android` folder and run `./gradlew testDebug --stackTrace`; make sure that the local.properties file has correct paths to the `flutter sdk`, as well as the `android sdk` and `ndk`

- `iOS`

    open xCode and select the test-navigator; from there select the file or single tests to run (ref. <https://developer.apple.com/library/archive/documentation/DeveloperTools/Conceptual/testing_with_xcode/chapters/05-running_tests.html>)

## Implementation

This section will explain implementation details for several components of the project, such as UI, Sensors etc. It might be useful to know certain terms like _container_, _widget_, and so on in the context of `flutter` and `dart`, to better understand this section.

### UI

#### Sound Updates

Updates for the sound (and also the GUI) are triggered in fixed 20ms intervals by a timer (resulting in 50Hz rate) inside the `void initState()` function in OneDScreen.dart

``` Dart
updateTimer = Timer.periodic(new Duration(milliseconds: 20), (timer) {
  soundGuiUpdate();
});
```

#### Orientation / Mode Switches

The _NativeDeviceOrientationReader_ package forms a container inside the _OneDScreen_ class. To manipulate the screen orientation the package reads the sensor values to determine the orientation.

To have a more dynamic change to the orientation, the inclinations of each axis can be used to reduce the switching in specific ranges. Example:

``` Dart
if ((zInclination.roundToDouble() < 20.0 &&
        zInclination.roundToDouble() > -20.0) &&
    //ignore trigger, if phone is straight, which means the user is trying to level portrait in 1D mode
    !(zInclination.roundToDouble() < 3.0 &&
        zInclination.roundToDouble() > -3))
```

Keep in mind, when switching modes to check the manually set modes.

Setting the variable _measuringIn2DMode_ to true will result in the auto switching of the mode. Furthermore, every update triggers the _FocusPathPainter_ to handle the new mode (if not also set manually)

``` Dart
FocusPathPainter.setNewMode(((measuringIn2DMode && isLockingModeSelected[0]) ||
                              isLockingModeSelected[1]));
```

Remember, this implementation works great for when the phone's orientation is locked in portrait mode. Problems might occur more frequently when having screen orientation set to automatic.

#### Bubbles

The bubbles and the white 1D background are located in a different class called _Bubbles_.

The two bubbles are separate containers inside the _Stack_ of the _Widget_, which use the sensor values on any update and manipulate their alignment on the screen accordingly, with an _AnimatedAlign_ container. As this class is a _StatefulWidget_, the values provided on initialization are constantly updated from the _OneDScreen_, where the object is instantiated.

UI Updates are triggered separately every 200ms:

``` Dart
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
```

The gray bubble's animations are _Rive_-animations (see [following chapter](#rive-animation-manipulation-or-creation) for further explanations). Every trigger for each _Rive_-animation is handled by calling `_handle2DBubblePosition()`. Regarding the mode and orientation, the sensor values are compared to previously manually specified sensor values inside `_canTheOuterRiveAnimationBePlayed()` and `_canTheInnerRiveAnimationBePlayed()`

To finally trigger a new _Rive_ animation, previously defined inside a _Rive_ asset file, the function `selectGraphic(state)` is triggered. This will check the _Artboard_ existence, precautiously check if it is a new state, before finally starting the center path animation (description following). The _SimpleAnimation_ is changed with a new String defined in the _riveFile2DBubbleOneAnimationNames_. By using _mix_ the animations look more mixed together.

``` Dart
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
```

The center animation is not played right away. Instead, the center path animation is triggered first, whereas the finish _Rive_-animation is delayed for 1 second. This reduces flickering, as the center animation would otherwise be played too fast/often.

Every animation can transition into various other animations. For Example: If the current state would be the inner animation, but then the center is misaligned, the reverse finish animation would be played.

``` Dart
if (currentBubbleState == 3) {
          selectGraphic(4);
        }
```

This is configured for every possibility.

#### Rotations

Rotations for the center bubble animations are also calculated (`rotationToBubble`).Those are needed to rotate the grey bubble into the direction of the small green bubble. To rotate the 1D Mode white background, the inclination of the recent orientation and mode must be used. The function `_manipulateOneDModeWhiteBGTween()` is called every 200ms.

**Explanation of Tween animation rotations (example)**: At the beginning, _Tween_ animations need to initilized before usage, with an _AnimationController_, _Animation_ and _Tween_. This is, for example, used for the rotation of the white background. The rotation needs to transition seemlessly from the previous state.Therefore, the beginning of the _Tween_ needs to be the end of the previously ended _Tween_ Animation. Then the controller is reset, so the animation can be restarted with new _Tween_ interpolations. The new end-value is calculated with the orientation and its inclination. Finally, by calling `forward()` the animation will be played.

``` Dart
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
```

#### Rive (Animation manipulation or creation)

Previously mentioned animations use _Rive_. _Rive_ is an external platform which allows to create elements and animations by manipulation. To manipulate an existing animation, you need to create an account at <https://rive.app/>. The collaboration model is not free, therefore only one person at a time can work on it. The _Rive_-files are located inside the assets _Rive_ folder. Inside the _Rive_-App, start a new project, then pull the local file inside the _Rive_-editor. Now. you got the _Artboard_ where you can manipulate the elements and the animations themselves.Pay attention to center elements, especially for the center bubble, as misaligned elements in the _Artboard_ will result in jumping objects inside _Flutter_.

**Troubleshooting**: Certain problems can occur when using _Rive_ on some browsers and systems. If anything does not work, make sure to use Chrome (not just Chromium), install it as a webapp, and if nothing else works, to run it on windows.

#### FocusPathPainter (Center Path Animations)

All center path animations are initialized by the _focusPathAnimator_, where all related _Tween_ animations are initialized. The general _CustomPaint_ "action" happens inside _focusPathPainter_.

Previously set _Tween_ values are used in the creation of all paths. For example:

``` Dart
    Path path_1 = Path();
    path_1.moveTo(size.width * _pathTwoAnimation.value, yStart);
    path_1.lineTo(size.width * _pathTwoAnimation.value, yEnd);
    canvas.drawPath(path_1, _paint);
```

Mode update triggers are called from outside the class in order to update animations:

``` Dart
//Setter for the recent Mode
static void setNewMode(bool measuringIn2Dmode) {
newMeasuringIn2DMode = measuringIn2Dmode;
}
```

Center-animation color triggers are also called from outside the class:

``` Dart
//Setter for validCenter
static void setValidness(bool valid) {
newValidness = valid;
}
```

The canvas is repainted if the mode changed or the phone has the centered state while executing the _shouldRepaint()_ function. By manipulating _newMeasuringIn2DMode_ and _newValidness_ in this method. The program knows which _animationControllers_ need to be played and if they need to be reversed.

#### Interactive Icons

Please refer to the [chapter on _Rive_-animations](#rive-animation-manipulation-or-creation), as the interactive icons are handled just like the bubbles from said chapter, only using other triggers.

### Sensors

Everything correlated to the sensor access and their processing can be found in the separate ```SensorProcessing.dart``` file. It holds the class ```SensorProcessor``` in which the sensor event listener, their filter and the corresponding angle calculations are stored.

``` Dart
import 'package:sensors/sensors.dart';
[...]

class SensorProcessor {
  List<double> filteredAcc;

  SensorProcessor() {
    this.filteredAcc = [0, 0, 0];

    accelerometerEvents.listen((AccelerometerEvent event) {
      filteredAcc = accLowPass(event.x, event.y, event.z);
      });
  }
  [...]
  
  double calculateAngle(int axis) {
  [...]
  }
}
```

As of now, the filtering consists of a basic low-pass-filter for the accelerometer values:

``` Dart
List<double> accLowPass(double x, double y, double z) {
    const double a = 0.8;
    double filteredX = x * a + filteredAcc[0] * (1 - a);
    double filteredY = y * a + filteredAcc[1] * (1 - a);
    double filteredZ = z * a + filteredAcc[2] * (1 - a);
    return [filteredX, filteredY, filteredZ];
}
```

When not in motion these accelerometer values can be interpreted as an up-vector due to the influence of gravity on them, so the phones angle can be derived using vector arithmetic.
The function ```double calculateAngle(int axis)``` handles these and returns the angle in degree for the given axis (1 for x and 2 for y, seeing x as along the short- and y as along the long phone edge).

Two constants at the beginning of the file can also be used by developers to mock phone angles when using an emulator for example:
``` dart
//Mocked Angles
//These mock the tilt angle of the phone, not the displayed angle per se.
//Set to angle in degree or null for no mocking.
const double x_angle_mock = null; //short axis
const double y_angle_mock = null; //long axis
```

All these angles do not include changes by the presets yet, but represent the actual phone angles!

Another important processing function in this file is ```double deriveSoundValue(double angle)```. This function turns angles in degree to the according normalized sound value for PureData. This takes into account margins defined at the beginning of the file to limit the space in which the sound changes has to change. ```inner_margin``` determining the angle at which the sound should imply the phone is leveled enough and ``` outer_margin``` setting the bound to where more detailed sonification wont provide additional value.

``` dart
//Values determining the margins (in degree) after which
//sound stops changing
const double inner_margin = 1;
const double outer_margin = 45;
```

### PureData

PureData is installed as a library for each platform and is called within `lib/OneDScreen.dart` whenever the method `platform.invokeListMethod()` is used. An example would be `_sendValueXToLibPd` and `_sendValueYToLibPd`:

``` dart
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
```

These methods in specific invoke methods in the native code, that pass the x and y values to the main PureData-patch `receiverLibPD.pd`. These are stored in different locations for each platform:

- Android: `android/app/src/main/res/streamingassets.zip` (inside the `.zip`, as it gets unpacked during the build process)
- iOS: `ios/Runner/receiverLibPD.pd`

You can replace the PureData-patch(es) at the specified locations, but it might be necessary to adjust code in several places as well. A good place to start would be:

- Android: `android/app/src/main/java`, especially `PureDataController.java`, `PureDataConstants.java`, and `MethodChannelHandler.java`
- iOS: `ios/Runner`, especially `PureDataController.m` and `MethodChannelHandler.m`

You might also want to adjust the flutter code, to not invoke list methods that do not exist. These methods should all be contained withing the previously mentioned `lib/OneDScreen.dart`.

### Hive

Preferences are saved with the [Hive](https://docs.hivedb.dev/#/) package. The app contains two different Hive boxes, namely, the `appBox` which stores various general app settings, and the `presetBox` which stores the presets. In the `initState`-function, various variables stored in Hive get checked and saved values get loaded. If no values are saved, a default value is stored in there. This happens in the `initializePresetFromHive`,`initializeModeLocksFromHive` and `initializeFirstStartFromHive` functions. Changes to the hive box are made every time a setting is changed via button click. For that, the various setter and getter functions like `savePresetInHive` should be used.

#### Reason for ordering the presets after loading them from Hive

If the preset-list does not get sorted immediately after pulling it from Hive, the preset-buttons in the UI will be in the wrong order. This is necessary because Hive does not allow the user to insert a preset in a specific place in the saved list. Because of that, a newly added preset can only be added at the end of the `presetBox` without deleting the other element in the desired place. Clearing the `presetBox` after adding a new preset and re-adding every element in the correct order is not only ineffective but also will break the duplicate check in the dialogue to add a new preset.

### Localizations

To localize this app, the flutter_localizations package was used. The open-source version only supports English, but you can add other languages to your liking.

To use localized translations in code, first import the following:

``` Dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
```

Supported languages are defined in the build function of the different App screens.

```dart
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
        // add your other supported languages here
      ],[...]
    );}}
```

To add a new language, look up the language and, if necessary, the country code and add it to the `supportedLocales`-array. The first language there is treated as the standard language, which in this case is English. The actual translations are stored in the `lib\l10n` folder as `.arb`-files with filenames in `app_CountryCode_LanguageCode(if necessary)_ScriptCode(if necessary)` format (for example `app_en.arb`).

Inside the file for the standard language, (here `app_en.arb`) the translations are stored in the following format:

``` Dart
"exampleVariableName": "Example text in English",
    "@exampleVariableName":{
    "description": "Description of context for translation"
    }
```

The standard language file always needs to contain the description. For the other languages this is omitted and the translations are stored in the following format:

``` Dart
"exampleVariableName": "Beispiel Text auf Deutsch"
```

When the app is built, `.dart`-files will be automatically generated from the mentioned `.arb`-files. Because of this, a newly added translation used in the way shown below might give errors or warnings claiming that the variables do not exist. They will go away after building the app, because the files will then be generated.

These localized translations can be referred in code by using `AppLocalizations.of(context).exampleVariableName`.

For more information, please refer to the first part of [this guide on internationalizing flutter apps](https://flutter.dev/docs/development/accessibility-and-localization/internationalization).

## License

The source code for Sonic Tilt is licensed under the MIT License, a copy of which can be found in the root of this repository. This means, third parties can copy, change and alter, redistribute the source code without much restriction.

Exception to this are several source files not authored by us, which include their own proprietary licenses, for example, some are licensed with the Apache license.

We retain copyright for the Tiltification brand name (not for Sonic Tilt) and of the graphical assets of the **original Tiltification app**, which is currently on the appstores. Such assets include for example the app icon or intro-animations. We made sure to remove our copyrighted materials from this open-source version and replace them with placeholders, so you can play around with this version and distribute it without worry.

## CI/CD for your own Project

If you are new to CI&CD we recommend this article to get a grasp on the topic: [Continuous Integration](https://www.atlassian.com/continuous-delivery/principles/continuous-integration-vs-delivery-vs-deployment).

If you then want to set up a CI/CD pipeline for your project, please refer to this [extensive guide](https://medium.com/@fezu54/our-story-with-flutter-and-gitlab-ci-26bd40c26155). It is written for the gitlab-pipeline, but can be adjusted to other ci/cd providers.

## Errors, Troubleshooting and Misc

- **target URI error for localization**: This error should only occur for the first local build, since the files get autogenerated. Simply build the project again, then the error should be gone.
- **xCode missing files or not being able to reference them**: Sometimes xCode is unable to find files, e.g., because references in the `project.pbxproj` are not relative and instead reference a direct path of a certain system. Usually those files will be displayed in red in the project finder (look under `Runner/Runner`). Delete the file reference (make sure not to delete the file; you will be prompted for that), then open the directory which contains the file and drag it into the corresponding folder in xCode. You will be prompted to create references for that group. Accept and try to build again.
- **possible issues with pd-for-ios in xCode**: In order to be able to import Pd-files into the project in Xcode and make them available during runtime, they need to be placed in the home directory of the project, i.e., in the same directory as the `AppDelegate.h/m` files. Otherwise, the Pd-files cannot be read properly, as they reference each other via relative paths. Said paths assume that all Pd-patches are located in the same directory (home directory), which was also the reason for not putting them in a separate directory. After downloading/installing the Pd-library, some configurations have to be done in XCode. Under `build settings -> User Header Search Paths` add the relative path to the library, pd-for-ios. Then, in the tab `build phases`, the library should be added to the list of libraries for the linker:  `build phases -> Link binary with libraries`. Now the icon for LibPd `libpd.xcodeproj` should not be red anymore which means that Pd has been configured successfully.

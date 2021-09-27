//import 'dart:html';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../LevelTheme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CustomDialogue extends StatefulWidget {
  CustomDialogue(
      {Key key,
      @required this.title,
      @required this.buttonText,
      this.description,
      @required this.presetDialogue})
      : super(key: key);

  final String title, buttonText, description;
  final bool presetDialogue;

  @override
  CustomDialogueState createState() => CustomDialogueState();
}

class CustomDialogueState extends State<CustomDialogue> {
  static final _formKey = GlobalKey<FormState>();
  int angle;
  final presetBox = Hive.box('app_presets');

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Consts.padding),
      ),
      elevation: 0.0,
      backgroundColor: Colors.transparent,
      child: dialogContent(context),
    );
  }

  dialogContent(BuildContext context) {
    return Stack(
      children: <Widget>[
        //bottom card part,
        Container(
            padding: EdgeInsets.only(
              top: Consts.padding,
              bottom: Consts.padding,
              left: Consts.padding,
              right: Consts.padding,
            ),
            decoration: new BoxDecoration(
              color: widget.presetDialogue
                  ? LevelTheme.bgColor
                  : LevelTheme.mainLightMode,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(Consts.padding),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10.0,
                  offset: const Offset(0.0, 10.0),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min, // To make the card compact
                children: <Widget>[
                  widget.presetDialogue
                      ? Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              TextFormField(
                                keyboardType: TextInputType.number,
                                style: LevelTheme.dialogueText,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                    border: const UnderlineInputBorder(
                                      borderSide: const BorderSide(
                                          color: LevelTheme.darkModeGreen),
                                    ),
                                    errorStyle: LevelTheme.errorText,
                                    errorBorder: const UnderlineInputBorder(
                                      borderSide: const BorderSide(
                                          color: LevelTheme.darkModeYellow),
                                    ),
                                    focusedErrorBorder:
                                        const UnderlineInputBorder(
                                      borderSide: const BorderSide(
                                          color: LevelTheme.darkModeYellow),
                                    ),
                                    focusedBorder: const UnderlineInputBorder(
                                      borderSide: const BorderSide(
                                          color: LevelTheme.darkModeGreen),
                                    ),
                                    hintText: AppLocalizations.of(context).enterOffset,
                                    hintStyle: LevelTheme.defaultText),
                                validator: (value) {
                                  //TODO: Further validation?
                                  if (value.isEmpty ||
                                      int.tryParse(value) == null) {
                                    return AppLocalizations.of(context).errorValidAngle;
                                  } else if (int.parse(value) > 45 ||
                                      int.parse(value) < 1) {
                                    return AppLocalizations.of(context).errorAngle;
                                  }
                                  //TODO: FIX THIS VALIDATION
                                  else if(presetBox.values.toList().contains(int.parse(value))){
                                    return AppLocalizations.of(context).errorDuplicate;
                                  }
                                  angle = int.parse(value);
                                  return null;
                                },
                              )
                            ],
                          ),
                        )
                      : Column(children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 24.0,
                              fontWeight: FontWeight.w700,
                              color: LevelTheme.mainDarkMode,
                            ),
                          ),
                          SizedBox(height: 16.0),
                          Text(
                            widget.description,
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize: 16.0,
                              color: LevelTheme.textColor,
                            ),
                          ),
                        ]),
                  SizedBox(height: 24.0),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: FlatButton(
                      onPressed: () {
                        if (widget.presetDialogue) {
                          //Calls validator for all fields in form
                          if (_formKey.currentState.validate()) {
                            //Sends data back to main screen
                            Navigator.of(context).pop(angle);
                          }
                        } else {
                          //Doesnt have to send any data
                          Navigator.of(context).pop();
                        } // To close the dialog
                      },
                      child: Text(widget.buttonText,
                          style: TextStyle(
                            color: widget.presetDialogue
                                ? LevelTheme.darkModeGreen
                                : LevelTheme.mainDarkMode,
                            fontSize: 24,
                          )),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

class Consts {
  Consts._();

  static const double padding = 16.0;
}

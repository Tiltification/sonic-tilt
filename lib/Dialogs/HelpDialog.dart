//import 'dart:html';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:simple_html_css/simple_html_css.dart';
import 'package:social_buttons/social_buttons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../LevelTheme.dart';

class HelpDialog extends StatelessWidget {
  final String title, htmlBody, buttonText;
  final bool socialBar;

  HelpDialog(
      {Key key,
      @required this.title,
      @required this.htmlBody,
      @required this.buttonText,
      @required this.socialBar})
      : super(key: key);

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
              top: Consts.avatarRadius + Consts.padding,
              bottom: Consts.padding,
              left: Consts.padding,
              right: Consts.padding,
            ),
            margin: EdgeInsets.only(top: Consts.avatarRadius),
            decoration: new BoxDecoration(
              color: LevelTheme.mainLightMode,
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
            child: Column(
                mainAxisSize: MainAxisSize.min, // To make the card compact
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Stack(children: <Widget>[
                    Text(title,
                        style: TextStyle(
                          fontSize: 30,
                          letterSpacing: 1.0,
                          fontWeight: FontWeight.bold,
                          foreground: Paint()
                            ..style = PaintingStyle.stroke
                            ..strokeWidth = 3
                            ..color = LevelTheme.bgColor,
                        )),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 30,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.bold,
                        color: LevelTheme.darkModeYellow,
                      ),
                    )
                  ]),
                  Flexible(
                    fit: FlexFit.loose,
                    child: SingleChildScrollView(
                      child: Container(
                        padding: EdgeInsets.only(
                          top: Consts.padding,
                          left: Consts.padding,
                          right: Consts.padding,
                        ),
                        /*EdgeInsets.all(10.0),*/
                        child: Column(
                          children: <Widget>[
                            RichText(
                              text: HTML.toTextSpan(context, htmlBody,
                                  defaultTextStyle: LevelTheme.htmlText,
                                  overrideStyle: {"a": LevelTheme.linkText},
                                  linksCallback: (link) async {
                                await canLaunch(link)
                                    ? await launch(link)
                                    : throw 'Could not launch $link';
                              }),
                            ),
                            socialBar
                                ? SocialButtons(
                                  // TODO: Link your social-media and website here to 
                                  // have them linked in the FAQ's contact section
                                  // 
                                  // For that, fill the url-attribute of the respective
                                  // SocialButtonItem
                                    items: [
                                      // Instagram Button
                                      SocialButtonItem(
                                          socialItem: socialItems.instagram,
                                          itemColor: Colors.pink[800],
                                          itemSize: 30.0,
                                          url:
                                              ""),
                                      // Facebook Button
                                      SocialButtonItem(
                                          socialItem: socialItems.facebook,
                                          itemColor: Colors.blue[900],
                                          itemSize: 30.0,
                                          url:
                                              ""),
                                      // Website Button
                                      SocialButtonItem(
                                          socialItem: socialItems.website,
                                          itemColor: LevelTheme.darkModeGreen,
                                          itemSize: 30.0,
                                          url:
                                              "")
                                    ],
                                  )
                                : Text(""),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: FlatButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Icon(Icons.cancel,
                            size: 30, color: LevelTheme.darkModeBlack),
                        /*Text(buttonText,
                  style: TextStyle(
                    color: LevelTheme.mainDarkMode,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  )),*/
                      ),
                    ),
                  ),
                ])),
        Positioned(
            left: Consts.padding,
            right: Consts.padding,
            child: CircleAvatar(
              backgroundColor: Colors.transparent,
              radius: Consts.avatarRadius,
              child: ClipRRect(
                  borderRadius:
                      BorderRadius.all(Radius.circular(Consts.avatarRadius)),
                  child: Image.asset("assets/logo.png")),
            ))
      ],
    );
  }
}

class Consts {
  Consts._();

  static const double padding = 18.0;
  static const double avatarRadius = 45;
}

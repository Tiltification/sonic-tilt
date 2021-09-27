//
//  MethodChannelHandler.m
//  Runner
//
//  Created by Fida on 12.01.21.
//

#import "MethodChannelHandler.h"
 
@implementation MethodChannelHandler

- (void) configureMethodChannel: (FlutterViewController* )flutterController {
   
  
    FlutterMethodChannel *channel = [FlutterMethodChannel   methodChannelWithName:@"sonic_tilt" binaryMessenger:flutterController];
    [channel setMethodCallHandler:^(FlutterMethodCall * _Nonnull call, FlutterResult  _Nonnull result) {
       
        if ([@"toggleAudio" isEqualToString:call.method]) {
            NSString *_switchedOff = call.arguments[@"switchOff"];
            [self toggleAudio:_switchedOff];
         }
        if ([@"sendAngleXToLibPd" isEqualToString:call.method]) {
    
            float targetX = [call.arguments[@"targetX"] floatValue];
            [self sendAngleXToLibPd:targetX];
            
          }
        
        if ([@"sendAngleYToLibPd" isEqualToString:call.method]) {
            float targetY = [call.arguments[@"targetY"] floatValue];
            [self sendAngleYToLibPd:targetY];
            
         }
        if ([@"applyUserPrefsAfterUIRendered" isEqualToString:call.method]) {
            NSString *startAudioOnBoot = call.arguments[@"startAudioOnBoot"];
            [self applyUserPrefsAfterUIRendered:startAudioOnBoot];
         }
        if ([@"togglePinkNoise" isEqualToString:call.method]) {
            NSString *pinkMute = call.arguments[@"pinkMute"];
            [self setPinkMute:pinkMute];
         }
        if ([@"playInBackground" isEqualToString:call.method]) {
            NSString *play = call.arguments[@"play"];
            [self playInBackground:play];
         }
        if ([@"setPinkNoiseSensitivityRange" isEqualToString:call.method]) {
            NSString *range = call.arguments[@"range"];
            [self setPinkNoiseSensitivityRange:range];
         }

    }];
    
}

- (void) toggleAudio: (NSString *) switchOff {
    bool isOn =  [SimpleUtils stringToBool:switchOff];;
    
    if (isOn) {
        NSLog(@"start audio");
        [PureDataController startAudio];
    }else{
        [PureDataController stopAudio];
        NSLog(@"stop audio");
    }
}
- (void) setPinkMute:(NSString *) mute{
    bool pinkMute = [SimpleUtils stringToBool:mute];
    [PureDataController setPinkMute:pinkMute];
}
- (void) sendAngleXToLibPd: (float) targetX {
    [PureDataController sendAngleXToLibPd:targetX];
}
- (void) sendAngleYToLibPd: (float) targetY {
    [PureDataController sendAngleYToLibPd:targetY];
}
- (void) applyUserPrefsAfterUIRendered:(NSString *) startAudioOnBoot{
    bool start = [SimpleUtils stringToBool:startAudioOnBoot];
    if (start) {
        NSLog(@"applyUserPrefsAfterUIRendered start audio is on");
    }
    [PureDataController applyUserPrefsAfterUIRendered:start];
}
- (void) playInBackground:(NSString *) play{
    bool playBool = [SimpleUtils stringToBool:play];
    [UserPreference setPlayInBackground:playBool];
}
- (void) setPinkNoiseSensitivityRange:(NSString *) range{
   float rangeF = [range floatValue];
    [UserPreference setPinkNoiseSensitivityRange: rangeF];
}

@end

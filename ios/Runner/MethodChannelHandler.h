//
//  MethodChannelHandler.h
//  Runner
//
//  Created by Fida on 12.01.21.
//

#import <Flutter/Flutter.h>
#import <Foundation/Foundation.h>
#import "PureDataController.h"
#import "SimpleUtils.h"
#import "UserPreference.h"

NS_ASSUME_NONNULL_BEGIN

@interface MethodChannelHandler : NSObject

- (void) configureMethodChannel: (FlutterViewController *)flutterController;
- (void) toggleAudio: (NSString *) switchOff;
- (void) sendAngleXToLibPd: (float) targetX;
- (void) sendAngleYToLibPd: (float) targetY;
- (void) applyUserPrefsAfterUIRendered:(NSString *) startAudioOnBoot;
- (void) setPinkMute:(NSString *) mute;
- (void) playInBackground:(NSString *) play;
- (void) setPinkNoiseSensitivityRange:(NSString *) range;
@end

NS_ASSUME_NONNULL_END

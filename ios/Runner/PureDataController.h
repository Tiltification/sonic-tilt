//
//  PureDataController.h
//  Runner
//
//  Created by Fida on 12.01.21.
//

#import <Foundation/Foundation.h>
#import "PdAudioController.h"
#import "PdDispatcher.h"
#import "UserPreference.h"

NS_ASSUME_NONNULL_BEGIN

@interface PureDataController : NSObject

@property (strong, nonatomic) PdAudioController *pdAudioController;
@property PdDispatcher *dispatcher;
- (instancetype) initPdAudio;
- (instancetype) initWithFile:(NSString *) pdFile;
- (void) nullify;
+ (void) setVolume:(float) volume;
+ (void) setMute:(BOOL) mute;
+ (void) setPinkMute:(BOOL) mute;
+ (void) sendAngleXToLibPd:(float) anlgeToAxisX;
+ (void) sendAngleYToLibPd:(float) anlgeToAxisY;
+ (void) startAudio;
+ (void) stopAudio;
+ (void) applyUserPrefsAfterUIRendered:(BOOL) startAudioOnBoot;
+ (void) applyUserPrefsWhenEnteringBackground;
+ (void) applyUserPrefsWhenEnteringForeground;
+ (void) setWasPlayingInBG:(BOOL) wasPlayInBG;
+ (BOOL) getWasPlayingInBG;
+ (void) setIsPlaying:(BOOL) isPlayed;
+ (BOOL) getIsPlaying;
+ (void) togglePinkNoiseDependingOnRange;
@end

NS_ASSUME_NONNULL_END

//
//  PureDataController.m
//  Runner
//
//  Created by Fida on 12.01.21.
//

#import "PureDataController.h"
#import "PdBase.h"

@implementation PureDataController
static BOOL wasPlaying = false;  // to save the state before entering the background
                            //for applying presets when reentering the foreground
static BOOL isPlaying = false;
static float actualRangeX = 0.0f;
static float actualRangeY = 0.0f;
- (instancetype) initPdAudio{
    
    if (!self.pdAudioController.active) {

    self.pdAudioController = [[PdAudioController alloc] init];
    
    PdAudioStatus pdInit = [self.pdAudioController configureAmbientWithSampleRate:44100 numberChannels:2 mixingEnabled:YES];
    self.dispatcher = [[PdDispatcher alloc] init];
    [PdBase setDelegate:self.dispatcher];
    [self.pdAudioController print];
    [self.pdAudioController setActive:true];
    
    if (pdInit != PdAudioError){
           NSLog(@"Pd initialized successfully");
           self = [self initWithFile:@"receiverLibPD.pd"];
       }else{
           NSLog(@"Pd failed to initialize");
       }
    }
    return self;
 }

- (instancetype) initWithFile:(NSString *) pdFile{
    self = [super init];
    if (self){
        void * patch = [PdBase openFile:pdFile path:[NSBundle mainBundle].resourcePath];
        if (!patch){
            NSLog(@"Failed to load patch %@ ", pdFile);
        }else{
            NSLog(@"File \"%@\" loaded successfully", pdFile);
        }
    }
    
    return self;
}

- (void) nullify{
    [PdBase setDelegate:nil];
}

+ (void) setVolume:(float) volume{
    [PdBase sendFloat:volume toReceiver:@"volume"];
}
+ (void) setMute:(BOOL) mute{
    float muteF = mute == true ? 1 : 0;
    [PdBase sendFloat:muteF toReceiver:@"soundMute"];
}
+ (void) setPinkMute:(BOOL) mute{
    float muteF = mute == true ? 1 : 0;
    [PdBase sendFloat:muteF toReceiver:@"pinkMute"];
}
+ (void) sendAngleXToLibPd:(float) valueX{
    actualRangeX = fabsf(valueX);
    [self togglePinkNoiseDependingOnRange];
    [PdBase sendFloat:valueX toReceiver:@"targetX"];
}
+ (void) sendAngleYToLibPd:(float) valueY{
    actualRangeY = fabsf(valueY);
    [self togglePinkNoiseDependingOnRange];
    [PdBase sendFloat:valueY toReceiver:@"targetY"];
}
+ (void) startAudio{
    [self setPinkMute:false];
    [self setVolume:1];
    [self setMute:false];
    [self setIsPlaying: true];
}
+ (void) stopAudio{
    [self setPinkMute:true];
    [self setVolume:0];
    [self setMute:true];
    [self setIsPlaying: false];
}
+ (void) applyUserPrefsAfterUIRendered:(BOOL) startAudioOnBoot{
    //dirty solution
    // we need to toggle the pink noise otherwise it will not be played
    [self setPinkMute:false];
    [self setPinkMute:true];
    if(startAudioOnBoot){
        [self startAudio];
    }else{
        [self stopAudio];
    }
}
+ (void) applyUserPrefsWhenEnteringBackground{
    bool playInBG = [UserPreference getPlayInBackground];
    [self setWasPlayingInBG:isPlaying];
    if (!playInBG) {
        [self stopAudio];
    }
}

+ (void) applyUserPrefsWhenEnteringForeground{
    bool toBePlayed = [self getWasPlayingInBG];
    if (toBePlayed) {
        [self startAudio];
     }
 }

+ (void) setWasPlayingInBG:(BOOL) wasPlayInBG{
     wasPlaying = wasPlayInBG;
}
+ (BOOL) getWasPlayingInBG{
    return  wasPlaying;
}
+ (void) setIsPlaying:(BOOL) isPlayed{
    isPlaying = isPlayed;
}
+ (BOOL) getIsPlaying{
    return isPlaying;
}
+ (void) togglePinkNoiseDependingOnRange{
    if (actualRangeX >= [UserPreference getPinkNoiseSensitivityRange]
        || actualRangeY >= [UserPreference getPinkNoiseSensitivityRange]) {
        [self setPinkMute:true];
    }else{
        [self setPinkMute:false];
    }
}
@end

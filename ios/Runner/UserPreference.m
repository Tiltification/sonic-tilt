//
//  UserPreference.m
//  Runner
//
//  Created by Fida on 13.01.21.
//

#import "UserPreference.h"

@implementation UserPreference

static BOOL playInBackground = false;// comes from flutter/hive and is set in channelHandler
static float defaultPinkNoiseRange = 0.045f;// 2°
- (id) initDefaults{

   self = [super init];
   self.playOnBoot = false;
   self.oneDimensionalMode = true;
   self.twoDimensionalMode = false;
   self.defaultVolume = 1;
   return self;
}
+ (void) setPlayInBackground: (BOOL) playInBG{
    playInBackground = playInBG;
}
 
+ (BOOL) getPlayInBackground{
    return playInBackground;
}
+ (void) setPinkNoiseSensitivityRange: (float) range{
      defaultPinkNoiseRange = range;
}
+ (float) getPinkNoiseSensitivityRange{
    return defaultPinkNoiseRange;
}
@end

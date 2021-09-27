//
//  UserPreference.h
//  Runner
//
//  Created by Fida on 13.01.21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UserPreference : NSObject
@property BOOL playOnBoot;
@property float defaultVolume;
@property BOOL oneDimensionalMode;
@property BOOL twoDimensionalMode;

+ (void) setPlayInBackground: (BOOL) playInBG;
+ (BOOL) getPlayInBackground;
+ (void) setPinkNoiseSensitivityRange: (float) range;
+ (float) getPinkNoiseSensitivityRange;
@end

NS_ASSUME_NONNULL_END

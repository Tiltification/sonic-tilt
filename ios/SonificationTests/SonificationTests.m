//
//  SonificationTests.m
//  SonificationTests
//
//  Created by Fida on 23.03.21.
//

//Naming convention:
// test + name of the method being tested + constellation + the expected outcome

#import <XCTest/XCTest.h>
#import "SimpleUtils.h"
#import "UserPreference.h"
@import XCTest;
@interface SonificationTests : XCTestCase
//@property UserPreference preset;
@end

@implementation SonificationTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testStringToBool_stringValueIsTrue_true {
   
   BOOL isTrue = [SimpleUtils stringToBool:@"true"];
   XCTAssertTrue(isTrue,@"expected false but found true");
}

- (void)testStringToBool_stringValueIsFalse_false {
   
   BOOL isFalse = [SimpleUtils stringToBool:@"false"];
   XCTAssertFalse(isFalse,@"expected false but found true");
}
- (void)testStringToBool_InvalidString_false {
   
   BOOL isFalse = [SimpleUtils stringToBool:@"falseeeee"];
   XCTAssertFalse(isFalse,@"expected false but found true");
}

//TODO: external dependencies like libpd causes trouble. This needs to be
// addressed before writing unit tests for PureDataController
- (void)testPureDataController_startAudio_isPlaying_ok {
   
   //[PureDataController startAudio];
   //BOOL isFalse =[PureDataController getIsPlaying];
   //XCTAssertFalse(isFalse,@"expected true but found false");
}

//UserPreferences:
- (void)testPinkNoiseDefaultRange_rangeNotSet_equalTrue {
    float defaultPinkNoiseRange = 0.045f;
    float range = [UserPreference getPinkNoiseSensitivityRange];
    XCTAssertEqual(range, defaultPinkNoiseRange, @"expected true but found false");
}
- (void)testSetPinkNoiseRange_rangeSet_EqualTrue {
    float nonDefaultPinkNoiseRange = 1.0f;
    [UserPreference setPinkNoiseSensitivityRange:1.0f];
    float range = [UserPreference getPinkNoiseSensitivityRange];
    XCTAssertEqual(range, nonDefaultPinkNoiseRange, @"expected true but found false");
}
- (void)testPinkNoiseRange_rangeNotSet_Equalfalse {
    float nonDefaultPinkNoiseRange = 1.0f;
    float range = [UserPreference getPinkNoiseSensitivityRange];
    XCTAssertNotEqual(range, nonDefaultPinkNoiseRange, @"expected false but found true");
}

- (void)testPlayingInBackground_defaultIsFalse_false {
    BOOL isPlayingInBG = [UserPreference getPlayInBackground];
    XCTAssertFalse(isPlayingInBG, @"expected false but found true");
}
- (void)testPlayingInBackground_setToTrue_true {
    [UserPreference setPlayInBackground:true];
    BOOL isPlayingInBG = [UserPreference getPlayInBackground];
    XCTAssertTrue(isPlayingInBG, @"expected true but found false");
}
@end

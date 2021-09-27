//
//  SimpleUtils.m
//  Runner
//
//  Created by Fida on 08.02.21.
//
#import "SimpleUtils.h"
 
@implementation SimpleUtils

+ (BOOL) stringToBool: (NSString *) myString {
    bool myBool = [myString isEqual: @"true"] ? true : false;
    return myBool;
}
@end

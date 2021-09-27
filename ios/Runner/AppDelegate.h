#import <Flutter/Flutter.h>
#import <UIKit/UIKit.h>
#import "PdAudioController.h"
#import "PdDispatcher.h"
#import "PdBase.h"
#import "PureDataController.h"
#import "MethodChannelHandler.h"

@interface AppDelegate : FlutterAppDelegate
@property (strong, nonatomic) PureDataController *pureDataController;
@property (strong, nonatomic) MethodChannelHandler *methodChannelHandler;
@property PdDispatcher *dispatcher;
@end

//
//  SapphireExternalMenu.h
//  Sapphire
//
//  
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SapphireExternalMenu: UIViewController <UIGestureRecognizerDelegate, UITextFieldDelegate>
+ (BOOL)passthroughMode;
- (void)resetLoopTimer;
- (void)stopLoopTimer;
- (void)setTargetProcessName:(NSString *)processName;
@end

NS_ASSUME_NONNULL_END

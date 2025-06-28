//
//  SapphireApp.h
//  Sapphire
//
//  
//

#import <UIKit/UIKit.h>
// #import "TSSettingsControllerDelegate.h"

NS_ASSUME_NONNULL_BEGIN

// Notification constants
extern NSString * const kToggleHUDAfterLaunchNotificationName;
extern NSString * const kToggleHUDAfterLaunchNotificationActionKey;
extern NSString * const kToggleHUDAfterLaunchNotificationActionToggleOn;
extern NSString * const kToggleHUDAfterLaunchNotificationActionToggleOff;

@interface SapphireApp : UIViewController
@property (nonatomic, strong) UIView *backgroundView;
+ (void)setShouldToggleHUDAfterLaunch:(BOOL)flag;
- (void)reloadMainButtonState;
@end

NS_ASSUME_NONNULL_END

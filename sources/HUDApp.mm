//
//  HUDApp.mm
//  Sapphire
//
//  
//

#import <notify.h>
#import <mach-o/dyld.h>
#import <sys/utsname.h>
#import <objc/runtime.h>

#import "IOKit+SPI.h"
#import "HUDHelper.h"
#import "TSEventFetcher.h"
#import "BackboardServices.h"
#import "AXEventRepresentation.h"
#import "UIApplication+Private.h"

#define PID_PATH "/var/mobile/Library/Caches/a0.sapphire.external.pid"

static __used
NSString *mDeviceModel(void) {
    struct utsname systemInfo;
    uname(&systemInfo);
    return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}

static __used
void _HUDEventCallback(void *target, void *refcon, IOHIDServiceRef service, IOHIDEventRef event)
{
    static UIApplication *app = [UIApplication sharedApplication];
    log_debug(OS_LOG_DEFAULT, "_HUDEventCallback => %{public}@", event);

    if (@available(iOS 13.0, *)) {}
    else {
        [app _enqueueHIDEvent:event];
    }

    BOOL shouldUseAXEvent = YES;

    BOOL isExactly15 = NO;
    static NSOperatingSystemVersion version = [[NSProcessInfo processInfo] operatingSystemVersion];
    if (version.majorVersion == 15 && version.minorVersion == 0 && version.patchVersion == 0) {
        NSString *deviceModel = mDeviceModel();
        if (![deviceModel hasPrefix:@"iPhone13,"] && ![deviceModel hasPrefix:@"iPhone14,"]) {
            isExactly15 = YES;
        }
    }

    if (@available(iOS 13.0, *)) {
        shouldUseAXEvent = !isExactly15;
    } else {
        shouldUseAXEvent = NO;
    }

    if (shouldUseAXEvent)
    {
        static Class AXEventRepresentationCls = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [[NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/AccessibilityUtilities.framework"] load];
            AXEventRepresentationCls = objc_getClass("AXEventRepresentation");
        });

        AXEventRepresentation *rep = [AXEventRepresentationCls representationWithHIDEvent:event hidStreamIdentifier:@"UIApplicationEvents"];
        log_debug(OS_LOG_DEFAULT, "_HUDEventCallback => %{public}@", rep.handInfo);

        {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                static UIWindow *keyWindow = nil;
                static dispatch_once_t onceToken;
                dispatch_once(&onceToken, ^{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                    keyWindow = [[app windows] firstObject];
#pragma clang diagnostic pop
                });

                UIView *keyView = [keyWindow hitTest:[rep location] withEvent:nil];

                UITouchPhase phase = UITouchPhaseEnded;
                if ([rep isTouchDown])
                    phase = UITouchPhaseBegan;
                else if ([rep isMove])
                    phase = UITouchPhaseMoved;
                else if ([rep isCancel])
                    phase = UITouchPhaseCancelled;
                else if ([rep isLift] || [rep isInRange] || [rep isInRangeLift])
                    phase = UITouchPhaseEnded;

                NSInteger pointerId = [[[[rep handInfo] paths] firstObject] pathIdentity];
                if (pointerId > 0)
                    [TSEventFetcher receiveAXEventID:MIN(MAX(pointerId, 1), 98) atGlobalCoordinate:[rep location] withTouchPhase:phase inWindow:keyWindow onView:keyView];
            });
        }
    }
}

int main(int argc, char *argv[])
{
    @autoreleasepool
    {
        log_debug(OS_LOG_DEFAULT, "launched argc %{public}d, argv[1] %{public}s", argc, argc > 1 ? argv[1] : "NULL");

        if (argc <= 1) {
            return UIApplicationMain(argc, argv, @"MainApplication", @"MainApplicationDelegate");
        }

        NSString *pidPath;
#if !TARGET_OS_SIMULATOR
        pidPath = JBROOT_PATH_NSSTRING(@"" PID_PATH);
#else
        pidPath = [[[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask].firstObject path] stringByAppendingPathComponent:@"a0.sapphire.external.pid"];
#endif

        if (strcmp(argv[1], "-hud") == 0)
        {
            pid_t pid = getpid();
            pid_t pgid = getgid();
            (void)pgid;
            log_debug(OS_LOG_DEFAULT, "HUD pid %d, pgid %d", pid, pgid);

            NSString *pidString = [NSString stringWithFormat:@"%d", pid];
            [pidString writeToFile:pidPath
                        atomically:YES
                          encoding:NSUTF8StringEncoding
                             error:nil];

            [UIScreen initialize];
            CFRunLoopGetCurrent();

            GSInitialize();
            BKSDisplayServicesStart();
            UIApplicationInitialize();

            UIApplicationInstantiateSingleton(objc_getClass("HUDMainApplication"));
            static id<UIApplicationDelegate> appDelegate = [[objc_getClass("HUDMainApplicationDelegate") alloc] init];
            [UIApplication.sharedApplication setDelegate:appDelegate];
            [UIApplication.sharedApplication _accessibilityInit];

            [NSRunLoop currentRunLoop];
            BKSHIDEventRegisterEventCallback(_HUDEventCallback);

            [UIApplication.sharedApplication __completeAndRunAsPlugin];

            static int _springboardBootToken;
            notify_register_dispatch("SBSpringBoardDidLaunchNotification", &_springboardBootToken, dispatch_get_main_queue(), ^(int token) {
                notify_cancel(token);

                notify_post(NOTIFY_DISMISSAL_HUD);

                // re-enable HUD after SpringBoard launches
                SetHUDEnabled(YES);

                // exit current HUD instance
                kill(pid, SIGKILL);
            });

            if (@available(iOS 13.0, *)) {
                GSEventInitialize(0);
                GSEventPushRunLoopMode(kCFRunLoopDefaultMode);
            }

            CFRunLoopRun();
            return EXIT_SUCCESS;
        }
        else if (strcmp(argv[1], "-exit") == 0)
        {
            NSString *pidString = [NSString stringWithContentsOfFile:pidPath
                                                            encoding:NSUTF8StringEncoding
                                                               error:nil];

            if (pidString)
            {
                pid_t pid = (pid_t)[pidString intValue];
                kill(pid, SIGKILL);
                unlink([pidPath UTF8String]);
            }

            return EXIT_SUCCESS;
        }
        else if (strcmp(argv[1], "-check") == 0)
        {
            NSString *pidString = [NSString stringWithContentsOfFile:pidPath
                                                            encoding:NSUTF8StringEncoding
                                                               error:nil];

            if (pidString)
            {
                pid_t pid = (pid_t)[pidString intValue];
                int killed = kill(pid, 0);
                return (killed == 0 ? EXIT_FAILURE : EXIT_SUCCESS);
            }
            else return EXIT_SUCCESS;  // no PID file, so HUD isnt running
        }
    }
}


//
//  HUDMainWindow.mm
//  Sapphire
//
//  
//

#import "HUDMainWindow.h"
#import "SapphireExternalMenu.h"

@implementation HUDMainWindow

+ (BOOL)_isSystemWindow { return YES; }
- (BOOL)_isWindowServerHostingManaged { return NO; }
- (BOOL)_ignoresHitTest { 
    // allow touches thru for dragging
    return NO; 
}
- (BOOL)_isSecure { return YES; }
- (BOOL)_shouldCreateContextAsSecure { return YES; }

@end

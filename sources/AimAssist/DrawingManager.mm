//
//  DrawingManager.mm
//  Sapphire
//
//  
//

#import "DrawingManager.h"
#import "SVGView.h"
#import "CircleView.h"

@interface DrawingManager ()
@property (nonatomic, weak) UIView *parentView;
@end

@implementation DrawingManager

- (instancetype)initWithParentView:(UIView *)parentView {
    self = [super init];
    if (self) {
        _parentView = parentView;
        _svgVisible = NO;
        _circleVisible = NO;
        _circleSize = 28.0; // Default circle size
    }
    return self;
}

- (void)createSVGView {
    // Remove existing SVG view if it exists
    UIView *existingSVG = [self.parentView viewWithTag:998];
    if (existingSVG) {
        [existingSVG removeFromSuperview];
    }
    
    // Create SVG view in center of screen
    CGFloat screenWidth = self.parentView.bounds.size.width;
    CGFloat screenHeight = self.parentView.bounds.size.height;
    CGFloat svgSize = 1492.0;
    CGFloat svgX = (screenWidth - svgSize) / 2.0;
    CGFloat svgY = (screenHeight - svgSize) / 2.0;
    
    SVGView *svgView = [[SVGView alloc] initWithFrame:CGRectMake(svgX, svgY, svgSize, svgSize)];
    svgView.tag = 998;
    svgView.hidden = !_svgVisible;
    svgView.userInteractionEnabled = NO;
    
    [self.parentView addSubview:svgView];
    _svgView = svgView;
    
    // Ensure all elements have consistent thickness when SVG is created
    if (_svgVisible) {
        [self updateSVGLineThickness:2.48];
        [self updateConnectionLineThickness:258.0];
        [self setInnerConnectionLineThickness:45.0];
        [self updateCircleThickness:10.0];
        
        // Update connection lines immediately with default values
        if ([_svgView respondsToSelector:@selector(updateConnectionLines)]) {
            [_svgView updateConnectionLines];
            NSLog(@"[DEBUG] Connection lines updated with default values when creating SVG view");
        }
    }
    
    NSLog(@"[DEBUG] SVG view created with visibility: %@, size: %.1f", _svgVisible ? @"visible" : @"hidden", svgSize);
}

- (void)createCircleView {
    if (_circleView) {
        [_circleView removeFromSuperview];
    }
    
    CGFloat screenWidth = self.parentView.bounds.size.width;
    CGFloat screenHeight = self.parentView.bounds.size.height;
    
    // Use saved position or center if no saved position
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    CGFloat circleX, circleY;
    
    if ([defaults objectForKey:@"circleCenterX"] && [defaults objectForKey:@"circleCenterY"]) {
        CGFloat centerX = [defaults doubleForKey:@"circleCenterX"];
        CGFloat centerY = [defaults doubleForKey:@"circleCenterY"];
        circleX = centerX - _circleSize / 2.0;
        circleY = centerY - _circleSize / 2.0;
    } else {
        // Center on screen if no saved position
        circleX = (screenWidth - _circleSize) / 2.0;
        circleY = (screenHeight - _circleSize) / 2.0;
    }
    
    CircleView *redCircleBorder = [[CircleView alloc] initWithFrame:CGRectMake(circleX, circleY, _circleSize, _circleSize)];
    redCircleBorder.userInteractionEnabled = YES;
    redCircleBorder.tag = 999;
    redCircleBorder.hidden = !_circleVisible;
    redCircleBorder.delegate = self; // Set delegate for drag notifications
    [self.parentView addSubview:redCircleBorder];
    
    _circleView = redCircleBorder;
    
    NSLog(@"[DEBUG] Red circle created with visibility: %@, size: %.1f", _circleVisible ? @"visible" : @"hidden", _circleSize);
}

- (void)toggleSVG:(BOOL)visible {
    if (_svgView) {
        _svgView.hidden = !visible;
        _svgVisible = visible;
        NSLog(@"[DEBUG] SVG visibility set to: %@", visible ? @"visible" : @"hidden");
        
        // When enabling SVG, ensure circle is also visible and update connection lines
        if (visible) {
            // Make sure circle is visible
            if (!_circleVisible || !_circleView) {
                [self toggleCircle:YES];
            }
            
            // Set default line thickness to 2.48 for SVG and 258 for connection lines
            [self updateSVGLineThickness:2.48];
            [self updateConnectionLineThickness:258.0];
            [self setInnerConnectionLineThickness:45.0];
            [self updateCircleThickness:10.0];
            
            // Update connection lines immediately with default values
            if (_svgView && [_svgView respondsToSelector:@selector(updateConnectionLines)]) {
                [_svgView updateConnectionLines];
                NSLog(@"[DEBUG] Connection lines updated with default values when enabling SVG");
            }
        }
    } else {
        NSLog(@"[DEBUG] SVG view not found, creating it now");
        // Create the SVG view if it doesn't exist
        [self createSVGView];
        // Try to set visibility again
        if (_svgView) {
            _svgView.hidden = !visible;
            _svgVisible = visible;
            
            // When enabling SVG, ensure circle is also visible and update connection lines
            if (visible) {
                // Make sure circle is visible
                if (!_circleVisible || !_circleView) {
                    [self toggleCircle:YES];
                }
                
                // Set default line thickness to 2.48 for SVG and 258 for connection lines
                [self updateSVGLineThickness:2.48];
                [self updateConnectionLineThickness:258.0];
                [self setInnerConnectionLineThickness:45.0];
                [self updateCircleThickness:10.0];
                
                // Update connection lines immediately with default values
                if (_svgView && [_svgView respondsToSelector:@selector(updateConnectionLines)]) {
                    [_svgView updateConnectionLines];
                    NSLog(@"[DEBUG] Connection lines updated with default values when creating and enabling SVG");
                }
            }
        }
    }
}

- (void)toggleCircle:(BOOL)visible {
    if (_circleView) {
        _circleView.hidden = !visible;
        _circleVisible = visible;
        NSLog(@"[DEBUG] Red circle visibility set to: %@", visible ? @"visible" : @"hidden");
    } else {
        NSLog(@"[DEBUG] Red circle not found, creating it now");
        // Create the red circle if it doesn't exist
        [self createCircleView];
        // Try to set visibility again
        if (_circleView) {
            _circleView.hidden = !visible;
            _circleVisible = visible;
        }
    }
}

- (void)updateSVGPosition {
    if (_svgView) {
        CGFloat screenWidth = self.parentView.bounds.size.width;
        CGFloat screenHeight = self.parentView.bounds.size.height;
        CGFloat svgSize = _svgView.frame.size.width;
        CGFloat svgX = (screenWidth - svgSize) / 2.0;
        CGFloat svgY = (screenHeight - svgSize) / 2.0;
        
        _svgView.frame = CGRectMake(svgX, svgY, svgSize, svgSize);
        
        // Update connection lines after position change
        if ([_svgView respondsToSelector:@selector(updateConnectionLines)]) {
            [_svgView performSelector:@selector(updateConnectionLines)];
        }
    }
}

- (void)updateCirclePosition {
    if (_circleView) {
        // Keep current center position, just update frame size
        CGPoint currentCenter = _circleView.center;
        _circleView.frame = CGRectMake(currentCenter.x - _circleSize/2, currentCenter.y - _circleSize/2, _circleSize, _circleSize);
        
        // Update SVG connection lines with new circle position
        if (_svgView && [_svgView respondsToSelector:@selector(updateConnectionLinesWithCircleCenter:circleRadius:)]) {
            CGPoint circleCenterInSVG = [_svgView convertPoint:_circleView.center fromView:_circleView.superview];
            CGFloat circleRadius = _circleSize / 2.0;
            [_svgView updateConnectionLinesWithCircleCenter:circleCenterInSVG circleRadius:circleRadius];
        }
    }
}

- (void)updateSVGSize:(CGFloat)size {
    if (_svgView) {
        [_svgView updateSVGSize:size];
        NSLog(@"[DEBUG] SVG size updated to: %.1f", size);
    }
}

- (void)updateCircleSize:(CGFloat)size {
    NSLog(@"[DEBUG] DrawingManager updateCircleSize called with size: %.1f", size);
    
    // Check if both circle and SVG are visible
    if (!_circleVisible || !_svgVisible) {
        NSLog(@"[DEBUG] Circle or SVG not visible - Circle: %@, SVG: %@", _circleVisible ? @"YES" : @"NO", _svgVisible ? @"YES" : @"NO");
        NSLog(@"[DEBUG] Making both visible...");
        _circleVisible = YES;
        _svgVisible = YES;
        if (_circleView) _circleView.hidden = NO;
        if (_svgView) _svgView.hidden = NO;
    }
    
    _circleSize = size; // Store the new size
    
    if (_circleView) {
        NSLog(@"[DEBUG] Circle view exists, calling updateSize");
        NSLog(@"[DEBUG] Circle visible: %@, hidden: %@", _circleVisible ? @"YES" : @"NO", _circleView.hidden ? @"YES" : @"NO");
        [_circleView updateSize:size];
        
        // Update SVG connection lines with new circle position and size
        if (_svgView && [_svgView respondsToSelector:@selector(updateConnectionLinesWithCircleCenter:circleRadius:)]) {
            if (!_svgView.hidden) {
                CGPoint circleCenterInSVG = [_svgView convertPoint:_circleView.center fromView:_circleView.superview];
                CGFloat circleRadius = size / 2.0;
                NSLog(@"[DEBUG] Calling updateConnectionLinesWithCircleCenter - center: (%.1f, %.1f), radius: %.1f", circleCenterInSVG.x, circleCenterInSVG.y, circleRadius);
                [_svgView updateConnectionLinesWithCircleCenter:circleCenterInSVG circleRadius:circleRadius];
                NSLog(@"[DEBUG] Connection lines updated for size: %.1f", size);
            } else {
                NSLog(@"[DEBUG] SVG is hidden, skipping connection line update");
            }
        } else {
            NSLog(@"[DEBUG] SVG view or method not available - SVG: %@, respondsToSelector: %@", _svgView ? @"YES" : @"NO", [_svgView respondsToSelector:@selector(updateConnectionLinesWithCircleCenter:circleRadius:)] ? @"YES" : @"NO");
            
            // Try to create SVG if it doesn't exist
            if (!_svgView) {
                NSLog(@"[DEBUG] Creating SVG view...");
                [self createSVGView];
                // Try updating again
                if (_svgView && [_svgView respondsToSelector:@selector(updateConnectionLinesWithCircleCenter:circleRadius:)]) {
                    CGPoint circleCenterInSVG = [_svgView convertPoint:_circleView.center fromView:_circleView.superview];
                    CGFloat circleRadius = size / 2.0;
                    [_svgView updateConnectionLinesWithCircleCenter:circleCenterInSVG circleRadius:circleRadius];
                    NSLog(@"[DEBUG] Connection lines updated after creating SVG");
                }
            }
        }
        
        NSLog(@"[DEBUG] Circle size updated to: %.1f", size);
    } else {
        NSLog(@"[DEBUG] Circle view is nil! Creating it now...");
        [self createCircleView];
        // Try updating again
        if (_circleView) {
            [_circleView updateSize:size];
        }
    }
}

- (void)updateSVGLineThickness:(CGFloat)thickness {
    if (_svgView) {
        [_svgView updateSVGLineThickness:thickness];
        NSLog(@"[DEBUG] SVG line thickness updated to: %.1f", thickness);
    }
}

- (void)updateConnectionLineThickness:(CGFloat)thickness {
    if (_svgView) {
        [_svgView updateConnectionLineThickness:thickness];
        NSLog(@"[DEBUG] Connection line thickness updated to: %.1f", thickness);
    }
}

- (void)updateConnectionLineAlpha:(CGFloat)alpha {
    if (_svgView) {
        [_svgView updateConnectionLineAlpha:alpha];
        NSLog(@"[DEBUG] Connection line alpha updated to: %.2f", alpha);
    }
}

- (void)setInnerConnectionLineThickness:(CGFloat)thickness {
    if (_svgView) {
        [_svgView setInnerConnectionLineThickness:thickness];
        NSLog(@"[DEBUG] Inner connection line thickness set to: %.1f", thickness);
    }
}

- (void)updateSVGColor:(UIColor *)color {
    if (_svgView) {
        [_svgView updateSVGColor:color];
    }
    
    // Also update circle color to match SVG lines
    [self updateCircleColor:color];
}

- (void)updateCircleColor:(UIColor *)color {
    if (_circleView) {
        [_circleView updateColor:color];
        NSLog(@"[DEBUG] Circle color updated");
    }
}

- (void)updateCircleThickness:(CGFloat)thickness {
    if (_circleView) {
        // Handle negative values - use absolute value for border width
        CGFloat baseLineWidth = fabs(thickness);
        
        // Use same scaling as connection lines - divide by 10 to match connection line thickness
        CGFloat scaledBorderWidth = baseLineWidth / 10.0;
        
        [_circleView updateThickness:scaledBorderWidth];
        NSLog(@"[DEBUG] Circle thickness updated to: %.3f (base: %.3f, scaled: %.3f, raw value: %.1f)", scaledBorderWidth, baseLineWidth, scaledBorderWidth, thickness);
    }
}

- (void)setConnectionLinesEnabled:(BOOL)enabled {
    if (_svgView) {
        [_svgView setConnectionLinesEnabled:enabled];
        NSLog(@"[DEBUG] Connection lines %@", enabled ? @"enabled" : @"disabled");
    }
}

- (void)updateSVGPositionX:(CGFloat)x {
    if (_svgView) {
        CGFloat screenWidth = self.parentView.bounds.size.width;
        CGFloat screenHeight = self.parentView.bounds.size.height;
        CGFloat svgSize = _svgView.frame.size.width;
        
        // Calculate Y position (keep current Y or center if not set)
        CGFloat currentY = _svgView.frame.origin.y;
        CGFloat svgY = (currentY < 0 || currentY > screenHeight) ? (screenHeight - svgSize) / 2.0 : currentY;
        
        // Calculate X position based on slider value (0-1000 range to screen width)
        CGFloat svgX = (x / 1000.0) * (screenWidth - svgSize);
        svgX = MAX(0, MIN(screenWidth - svgSize, svgX)); // Clamp to screen bounds
        
        _svgView.frame = CGRectMake(svgX, svgY, svgSize, svgSize);
        
        // Update connection lines after position change
        if ([_svgView respondsToSelector:@selector(updateConnectionLines)]) {
            [_svgView performSelector:@selector(updateConnectionLines)];
        }
        
        NSLog(@"[DEBUG] SVG position X updated to: %.1f (screen X: %.1f)", x, svgX);
    }
}

- (void)updateSVGPositionY:(CGFloat)y {
    if (_svgView) {
        CGFloat screenWidth = self.parentView.bounds.size.width;
        CGFloat screenHeight = self.parentView.bounds.size.height;
        CGFloat svgSize = _svgView.frame.size.width;
        
        // Calculate X position (keep current X or center if not set)
        CGFloat currentX = _svgView.frame.origin.x;
        CGFloat svgX = (currentX < 0 || currentX > screenWidth) ? (screenWidth - svgSize) / 2.0 : currentX;
        
        // Calculate Y position based on slider value (0-1000 range to screen height)
        CGFloat svgY = (y / 1000.0) * (screenHeight - svgSize);
        svgY = MAX(0, MIN(screenHeight - svgSize, svgY)); // Clamp to screen bounds
        
        _svgView.frame = CGRectMake(svgX, svgY, svgSize, svgSize);
        
        // Update connection lines after position change
        if ([_svgView respondsToSelector:@selector(updateConnectionLines)]) {
            [_svgView performSelector:@selector(updateConnectionLines)];
        }
        
        NSLog(@"[DEBUG] SVG position Y updated to: %.1f (screen Y: %.1f)", y, svgY);
    }
}

// MARK: - CircleViewDelegate

- (void)circleViewDidMove:(UIView *)circleView {
    // Update SVG connection lines when circle is moved
    if (_svgView && [_svgView respondsToSelector:@selector(updateConnectionLinesWithCircleCenter:circleRadius:)]) {
        CGPoint circleCenterInSVG = [_svgView convertPoint:_circleView.center fromView:_circleView.superview];
        CGFloat circleRadius = _circleSize / 2.0;
        [_svgView updateConnectionLinesWithCircleCenter:circleCenterInSVG circleRadius:circleRadius];
    }
}

@end 
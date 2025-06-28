//
//  CircleView.mm
//  Sapphire
//
//  Created by AlexZero on 24.06.2025.
//

#import "CircleView.h"

@interface CircleView ()
@property (nonatomic, assign) CGFloat baseBorderWidth;
@property (nonatomic, assign) BOOL isDragging;
@property (nonatomic, assign) CGPoint dragStartPoint;
@property (nonatomic, assign) CGPoint originalCenter;
@end

@implementation CircleView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        NSLog(@"[DEBUG] CircleView created with frame: %@", NSStringFromCGRect(frame));
        // Use a very transparent background to make the entire area touchable
        self.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.01]; // Almost transparent but touchable
        self.userInteractionEnabled = YES; // Enable user interaction for dragging
        
        // Create circular border with same color as SVG lines
        self.layer.cornerRadius = frame.size.width / 2.0;
        self.layer.borderWidth = 1.0; // Same as connection lines default width (10/10)
        self.baseBorderWidth = 1.0; // Store base border width
        
        // Use same color as separators (same as SVG lines)
        UIColor *separatorColor = [UIColor colorWithRed:15.0/255.0 green:82.0/255.0 blue:186.0/255.0 alpha:1.0];
        self.layer.borderColor = separatorColor.CGColor;
        
        // No glow effects - remove any shadow properties
        self.layer.shadowColor = [UIColor clearColor].CGColor;
        self.layer.shadowOffset = CGSizeZero;
        self.layer.shadowRadius = 0.0;
        self.layer.shadowOpacity = 0.0;
        
        // Create grab handle icon below the circle
        [self createGrabHandle];
        
        // Add pan gesture to the main view to handle touches outside the circle
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
        panGesture.delegate = self;
        panGesture.maximumNumberOfTouches = 1;
        panGesture.minimumNumberOfTouches = 1;
        panGesture.delaysTouchesBegan = NO;
        panGesture.delaysTouchesEnded = NO;
        panGesture.cancelsTouchesInView = NO;
        [self addGestureRecognizer:panGesture];
        
        // Load saved position
        [self loadPosition];
    }
    return self;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    // Create a large touch area that includes the circle and the grab handle
    CGFloat radius = self.frame.size.width / 2.0;
    CGPoint center = CGPointMake(radius, radius);
    CGFloat distance = sqrt(pow(point.x - center.x, 2) + pow(point.y - center.y, 2));
    
    // Allow touch if point is within the circle or in the grab handle area
    if (distance <= radius) {
        return YES; // Touch is inside the circle
    }
    
    // Check if touch is in the grab handle area (below the circle)
    UIImageView *grabHandle = [self viewWithTag:1001];
    if (grabHandle && CGRectContainsPoint(grabHandle.frame, point)) {
        return YES; // Touch is in the grab handle area
    }
    
    return NO;
}

- (void)createGrabHandle {
    // Create a grab handle icon using SF Symbols
    UIImage *grabIcon = [UIImage systemImageNamed:@"hand.draw.fill"];
    UIImageView *grabHandle = [[UIImageView alloc] initWithImage:grabIcon];
    
    // Position the grab handle much lower below the circle
    CGFloat handleSize = 40.0; // Larger size for easier touching
    CGFloat circleRadius = self.frame.size.width / 2.0;
    grabHandle.frame = CGRectMake(circleRadius - handleSize/2, circleRadius + 30, handleSize, handleSize);
    
    // Style the grab handle with black color
    grabHandle.tintColor = [UIColor blackColor];
    grabHandle.userInteractionEnabled = NO; // Disable interaction on the icon itself
    grabHandle.tag = 1001; // Tag to identify the grab handle
    
    [self addSubview:grabHandle];
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        // Start dragging
        _isDragging = YES;
        _dragStartPoint = [gesture locationInView:self.superview];
        _originalCenter = self.center;
        NSLog(@"[DEBUG] Started dragging circle");
    } else if (gesture.state == UIGestureRecognizerStateChanged && _isDragging) {
        // Continue dragging - optimized for performance
        CGPoint translation = [gesture translationInView:self.superview];
        CGPoint newCenter = CGPointMake(_originalCenter.x + translation.x, _originalCenter.y + translation.y);
        
        // Keep the circle within screen bounds
        CGFloat halfWidth = self.frame.size.width / 2.0;
        CGFloat halfHeight = self.frame.size.height / 2.0;
        CGSize screenSize = self.superview.bounds.size;
        
        newCenter.x = MAX(halfWidth, MIN(screenSize.width - halfWidth, newCenter.x));
        newCenter.y = MAX(halfHeight, MIN(screenSize.height - halfHeight, newCenter.y));
        
        self.center = newCenter;
        
        // Notify delegate about the move
        if ([self.delegate respondsToSelector:@selector(circleViewDidMove:)]) {
            [self.delegate circleViewDidMove:self];
        }
    } else if (gesture.state == UIGestureRecognizerStateEnded && _isDragging) {
        // End dragging
        _isDragging = NO;
        [self savePosition];
        NSLog(@"[DEBUG] Finished dragging circle");
    } else if (gesture.state == UIGestureRecognizerStateCancelled && _isDragging) {
        // Cancel dragging
        _isDragging = NO;
        NSLog(@"[DEBUG] Cancelled dragging circle");
    }
}

- (void)savePosition {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setDouble:self.center.x forKey:@"circleCenterX"];
    [defaults setDouble:self.center.y forKey:@"circleCenterY"];
    [defaults synchronize];
}

- (void)loadPosition {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"circleCenterX"] && [defaults objectForKey:@"circleCenterY"]) {
        CGFloat x = [defaults doubleForKey:@"circleCenterX"];
        CGFloat y = [defaults doubleForKey:@"circleCenterY"];
        self.center = CGPointMake(x, y);
    }
}

- (void)updateColor:(UIColor *)color {
    self.layer.borderColor = color.CGColor;
}

- (void)updateThickness:(CGFloat)thickness {
    // Update base border width and recalculate scaled border width
    self.baseBorderWidth = fabs(thickness);
    CGFloat scaleFactor = self.frame.size.width / 28.0; // Scale factor based on new default 28px size
    self.layer.borderWidth = self.baseBorderWidth * scaleFactor;
}

- (void)updateSize:(CGFloat)size {
    // Update the circle size while maintaining its center position
    CGPoint center = self.center;
    CGRect newFrame = CGRectMake(center.x - size/2, center.y - size/2, size, size);
    self.frame = newFrame;
    self.layer.cornerRadius = size / 2.0;
    
    // Update the border width to scale with the circle size
    CGFloat scaleFactor = size / 28.0; // Scale factor based on new default 28px size
    self.layer.borderWidth = self.baseBorderWidth * scaleFactor;
    
    // Update grab handle position
    UIImageView *grabHandle = [self viewWithTag:1001];
    if (grabHandle) {
        CGFloat handleSize = 40.0;
        CGFloat circleRadius = size / 2.0;
        grabHandle.frame = CGRectMake(circleRadius - handleSize/2, circleRadius + 30, handleSize, handleSize);
    }
}

@end 
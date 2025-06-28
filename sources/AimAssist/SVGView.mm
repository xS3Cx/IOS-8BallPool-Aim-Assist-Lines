//
//  SVGView.mm
//  Sapphire
//
//  
//

#import "SVGView.h"
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

@interface SVGView ()
@property (nonatomic, strong, readonly) CAShapeLayer *shapeLayer;
@property (nonatomic, strong, readonly) CAShapeLayer *glowLayer;
@property (nonatomic, strong, readonly) CAShapeLayer *connectionLayer;
@property (nonatomic, strong, readonly) CAShapeLayer *innerConnectionLayer;
@property (nonatomic, assign) CGFloat currentSVGLineThickness;
@property (nonatomic, assign) CGFloat currentConnectionLineThickness;
@property (nonatomic, strong) UIColor *currentColor;
@property (nonatomic, assign) CGPoint lastCircleCenter;
@property (nonatomic, assign) CGFloat lastCircleRadius;
@end

@implementation SVGView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;
    
    self.backgroundColor = UIColor.clearColor;
    self.userInteractionEnabled = NO;
    
    // Initialize tracking properties
    _lastCircleCenter = CGPointMake(-1, -1);
    _lastCircleRadius = -1;
    
    // Create and configure layers
    [self setupLayers];
    [self createSVGPath];
    [self updateConnectionLines];
    
    return self;
}

- (void)dealloc {
    // No need to invalidate any timer as it's removed from the code
}

#pragma mark - Private Methods

- (void)setupLayers {
    // Initialize default values
    self.currentSVGLineThickness = 2.48;
    self.currentConnectionLineThickness = 10.0;
    self.currentColor = self.separatorColor;
    
    // Create main shape layer
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.fillColor = UIColor.clearColor.CGColor;
    shapeLayer.strokeColor = self.currentColor.CGColor;
    shapeLayer.lineWidth = self.currentSVGLineThickness / 100.0;
    shapeLayer.lineCap = kCALineCapRound;
    shapeLayer.lineJoin = kCALineJoinRound;
    
    // Create glow layer
    CAShapeLayer *glowLayer = [CAShapeLayer layer];
    glowLayer.fillColor = UIColor.clearColor.CGColor;
    glowLayer.strokeColor = self.currentColor.CGColor;
    glowLayer.lineWidth = self.currentSVGLineThickness / 100.0;
    glowLayer.lineCap = kCALineCapRound;
    glowLayer.lineJoin = kCALineJoinRound;
    glowLayer.shadowColor = self.currentColor.CGColor;
    glowLayer.shadowOffset = CGSizeZero;
    glowLayer.shadowRadius = 4.0;
    glowLayer.shadowOpacity = 0.8;
    
    // Create connection layer
    CAShapeLayer *connectionLayer = [CAShapeLayer layer];
    connectionLayer.fillColor = UIColor.clearColor.CGColor;
    connectionLayer.strokeColor = self.connectionColor.CGColor;
    connectionLayer.lineWidth = self.currentConnectionLineThickness / 10.0;
    connectionLayer.lineCap = kCALineCapRound;
    connectionLayer.lineJoin = kCALineJoinRound;
    connectionLayer.shadowColor = self.connectionColor.CGColor;
    connectionLayer.shadowOffset = CGSizeZero;
    connectionLayer.shadowRadius = 4.0;
    connectionLayer.shadowOpacity = 0.4;
    
    // Create inner connection layer
    CAShapeLayer *innerConnectionLayer = [CAShapeLayer layer];
    innerConnectionLayer.fillColor = UIColor.clearColor.CGColor;
    innerConnectionLayer.strokeColor = self.connectionColor.CGColor;
    innerConnectionLayer.lineWidth = 45.0 / 10.0; // Set to 45 thickness by default
    innerConnectionLayer.lineCap = kCALineCapRound;
    innerConnectionLayer.lineJoin = kCALineJoinRound;
    innerConnectionLayer.shadowColor = self.connectionColor.CGColor;
    innerConnectionLayer.shadowOffset = CGSizeZero;
    innerConnectionLayer.shadowRadius = 4.0;
    innerConnectionLayer.shadowOpacity = 0.4;
    
    // Add layers in order: glow (back), shape (middle), connections (front)
    [self.layer addSublayer:glowLayer];
    [self.layer addSublayer:shapeLayer];
    [self.layer addSublayer:connectionLayer];
    [self.layer addSublayer:innerConnectionLayer];
    
    // Store layers using associated objects for cleaner access
    objc_setAssociatedObject(self, @selector(shapeLayer), shapeLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(glowLayer), glowLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(connectionLayer), connectionLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(innerConnectionLayer), innerConnectionLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)createSVGPath {
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    // Define SVG path segments as array of point pairs
    NSArray<NSArray<NSValue *> *> *pathSegments = @[
        @[@(CGPointMake(2.959, 7.801)), @(CGPointMake(2.683, 7.541))],
        @[@(CGPointMake(2.947, 13.758)), @(CGPointMake(2.959, 7.801))],
        @[@(CGPointMake(2.694, 14.023)), @(CGPointMake(2.947, 13.758))],
        @[@(CGPointMake(3.238, 14.579)), @(CGPointMake(3.503, 14.314))],
        @[@(CGPointMake(10.361, 14.587)), @(CGPointMake(10.444, 14.313))],
        @[@(CGPointMake(16.512, 14.31)), @(CGPointMake(10.444, 14.31))],
        @[@(CGPointMake(16.776, 14.563)), @(CGPointMake(16.512, 14.31))],
        @[@(CGPointMake(17.305, 14.046)), @(CGPointMake(17.045, 13.755))],
        @[@(CGPointMake(17.038, 7.79)), @(CGPointMake(17.045, 13.755))],
        @[@(CGPointMake(17.307, 7.514)), @(CGPointMake(17.038, 7.79))],
        @[@(CGPointMake(16.779, 6.997)), @(CGPointMake(16.501, 7.262))],
        @[@(CGPointMake(10.425, 7.258)), @(CGPointMake(16.501, 7.262))],
        @[@(CGPointMake(10.339, 6.988)), @(CGPointMake(10.424, 7.258))],
        @[@(CGPointMake(9.66, 6.988)), @(CGPointMake(9.578, 7.258))],
        @[@(CGPointMake(3.505, 7.263)), @(CGPointMake(9.578, 7.258))],
        @[@(CGPointMake(3.235, 6.992)), @(CGPointMake(3.505, 7.263))],
        @[@(CGPointMake(9.573, 14.316)), @(CGPointMake(3.503, 14.314))],
        @[@(CGPointMake(9.669, 14.6)), @(CGPointMake(9.573, 14.316))]
    ];
    
    // Build path from segments
    for (NSArray<NSValue *> *segment in pathSegments) {
        CGPoint start = segment[0].CGPointValue;
        CGPoint end = segment[1].CGPointValue;
        [path moveToPoint:start];
        [path addLineToPoint:end];
    }
    
    [path closePath];
    
    // Apply path to layers
    self.shapeLayer.path = path.CGPath;
    self.glowLayer.path = path.CGPath;
    
    // Apply transform
    CATransform3D transform = [self transformForPath];
    self.shapeLayer.transform = transform;
    self.glowLayer.transform = transform;
}

- (CATransform3D)transformForPath {
    CGFloat scaleX = self.bounds.size.width / 20.0;
    CGFloat scaleY = self.bounds.size.height / 20.0;
    CGFloat scale = MIN(scaleX, scaleY) * 0.8;
    
    CATransform3D transform = CATransform3DIdentity;
    transform = CATransform3DTranslate(transform, self.bounds.size.width / 2, self.bounds.size.height / 2, 0);
    transform = CATransform3DScale(transform, scale, scale, 1.0);
    transform = CATransform3DTranslate(transform, -10, -10, 0);
    
    return transform;
}

- (void)updateConnectionLines {
    [self updateConnectionLinesWithCircleCenter:CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2) 
                                  circleRadius:100.0];
}

- (void)updateConnectionLinesWithCircleCenter:(CGPoint)circleCenter circleRadius:(CGFloat)circleRadius {
    // Update immediately without any throttling for maximum responsiveness
    _lastCircleCenter = circleCenter;
    _lastCircleRadius = circleRadius;
    
    // Update immediately
    [self performConnectionLinesUpdateDirect];
}

- (void)performConnectionLinesUpdateDirect {
    if (!self.connectionLayer || !self.innerConnectionLayer) return;
    
    // Define corner points with their labels - pre-calculated for better performance
    NSArray<NSValue *> *cornerPoints = @[
        @(CGPointMake(3.0895, 14.159)), // Left top
        @(CGPointMake((17.045 + 16.776) / 2.0, (13.755 + 14.563) / 2.0)), // Right top
        @(CGPointMake(16.903, 7.3965)), // Right bottom
        @(CGPointMake((3.235 + 2.959) / 2.0, (6.992 + 7.801) / 2.0)), // Left bottom
        @(CGPointMake((9.578 + 10.424) / 2.0, 7.258)), // H4 to H2
        @(CGPointMake((9.573 + 10.444) / 2.0, (14.316 + 14.313) / 2.0)) // J1 to C2
    ];
    
    // Use CGMutablePath for better performance than UIBezierPath
    CGMutablePathRef connectionPath = CGPathCreateMutable();
    CGMutablePathRef innerConnectionPath = CGPathCreateMutable();
    CGFloat scale = MIN(self.bounds.size.width / 20.0, self.bounds.size.height / 20.0) * 0.8;
    
    // Pre-calculate center and radius for better performance
    CGPoint center = _lastCircleCenter;
    CGFloat radius = _lastCircleRadius;
    
    // Optimize the loop by pre-calculating common values
    CGFloat centerX = center.x;
    CGFloat centerY = center.y;
    
    for (NSValue *pointValue in cornerPoints) {
        CGPoint originalPoint = pointValue.CGPointValue;
        CGPoint screenPoint = [self transformPoint:originalPoint scale:scale];
        CGPoint circlePoint = [self pointOnCircleOptimized:centerX centerY:centerY radius:radius targetX:screenPoint.x targetY:screenPoint.y];
        
        // Outer connection line (thicker)
        CGPathMoveToPoint(connectionPath, NULL, circlePoint.x, circlePoint.y);
        CGPathAddLineToPoint(connectionPath, NULL, screenPoint.x, screenPoint.y);
        
        // Inner connection line (thinner, 45 thickness)
        CGPathMoveToPoint(innerConnectionPath, NULL, circlePoint.x, circlePoint.y);
        CGPathAddLineToPoint(innerConnectionPath, NULL, screenPoint.x, screenPoint.y);
    }
    
    self.connectionLayer.path = connectionPath;
    self.innerConnectionLayer.path = innerConnectionPath;
    CGPathRelease(connectionPath);
    CGPathRelease(innerConnectionPath);
}

- (CGPoint)transformPoint:(CGPoint)point scale:(CGFloat)scale {
    return CGPointMake(
        (point.x - 10) * scale + self.bounds.size.width / 2,
        (point.y - 10) * scale + self.bounds.size.height / 2
    );
}

- (CGPoint)pointOnCircleOptimized:(CGFloat)centerX centerY:(CGFloat)centerY radius:(CGFloat)radius targetX:(CGFloat)targetX targetY:(CGFloat)targetY {
    CGFloat directionX = targetX - centerX;
    CGFloat directionY = targetY - centerY;
    CGFloat distance = sqrt(directionX * directionX + directionY * directionY);
    
    if (distance > 0) {
        directionX /= distance;
        directionY /= distance;
    }
    
    return CGPointMake(
        centerX + directionX * radius,
        centerY + directionY * radius
    );
}

- (void)clearAllLabels {
    NSArray<CALayer *> *textLayers = [self.layer.sublayers filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(CALayer *layer, NSDictionary *bindings) {
        return [layer isKindOfClass:CATextLayer.class];
    }]];
    
    [textLayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
}

#pragma mark - Lazy Properties

- (UIColor *)separatorColor {
    return [UIColor colorWithRed:15.0/255.0 green:82.0/255.0 blue:186.0/255.0 alpha:1.0];
}

- (UIColor *)connectionColor {
    return [UIColor colorWithRed:15.0/255.0 green:82.0/255.0 blue:186.0/255.0 alpha:0.6];
}

- (CAShapeLayer *)shapeLayer {
    return objc_getAssociatedObject(self, @selector(shapeLayer));
}

- (CAShapeLayer *)glowLayer {
    return objc_getAssociatedObject(self, @selector(glowLayer));
}

- (CAShapeLayer *)connectionLayer {
    return objc_getAssociatedObject(self, @selector(connectionLayer));
}

- (CAShapeLayer *)innerConnectionLayer {
    return objc_getAssociatedObject(self, @selector(innerConnectionLayer));
}

#pragma mark - Public Methods for DrawingManager

- (void)updateSVGLineThickness:(CGFloat)thickness {
    self.currentSVGLineThickness = thickness;
    
    // Handle negative values - use absolute value for line width
    CGFloat baseLineWidth = fabs(thickness);
    
    // Use much smaller scaling for line thickness - divide by 100 to get reasonable values
    CGFloat scaledLineWidth = baseLineWidth / 100.0;
    
    self.shapeLayer.lineWidth = scaledLineWidth;
    self.glowLayer.lineWidth = scaledLineWidth;
}

- (void)updateConnectionLineThickness:(CGFloat)thickness {
    self.currentConnectionLineThickness = thickness;
    
    // Handle negative values - use absolute value for line width
    CGFloat baseLineWidth = fabs(thickness);
    
    // Use different scaling for connection lines - divide by 10 instead of 100 to make them thicker
    CGFloat scaledLineWidth = baseLineWidth / 10.0;
    
    // Only update the outer connection layer thickness
    self.connectionLayer.lineWidth = scaledLineWidth;
    
    // Always ensure inner connection layer maintains its original thickness (45.0 / 10.0 = 4.5)
    self.innerConnectionLayer.lineWidth = 4.5;
}

- (void)updateConnectionLineAlpha:(CGFloat)alpha {
    // Clamp alpha value between 0.1 and 1.0
    CGFloat clampedAlpha = MAX(0.1, MIN(1.0, alpha));
    
    // Update the connection layer's opacity
    self.connectionLayer.opacity = clampedAlpha;
    self.innerConnectionLayer.opacity = clampedAlpha;
    
    // Also update the shadow opacity proportionally
    self.connectionLayer.shadowOpacity = clampedAlpha * 0.4; // Keep shadow at 40% of main opacity
    self.innerConnectionLayer.shadowOpacity = clampedAlpha * 0.4; // Keep shadow at 40% of main opacity
}

- (void)updateSVGColor:(UIColor *)color {
    self.currentColor = color;
    
    self.shapeLayer.strokeColor = color.CGColor;
    self.glowLayer.strokeColor = color.CGColor;
    self.glowLayer.shadowColor = color.CGColor;
    
    // Update connection color with alpha transparency
    UIColor *connectionColor = [color colorWithAlphaComponent:0.6];
    self.connectionLayer.strokeColor = connectionColor.CGColor;
    self.connectionLayer.shadowColor = connectionColor.CGColor;
    self.innerConnectionLayer.strokeColor = connectionColor.CGColor;
    self.innerConnectionLayer.shadowColor = connectionColor.CGColor;
}

- (void)setConnectionLinesEnabled:(BOOL)enabled {
    self.connectionLayer.hidden = !enabled;
    self.innerConnectionLayer.hidden = !enabled;
}

- (void)updateSVGSize:(CGFloat)size {
    // Update the view frame to match the new size
    CGFloat screenWidth = self.superview.bounds.size.width;
    CGFloat screenHeight = self.superview.bounds.size.height;
    CGFloat svgX = (screenWidth - size) / 2.0;
    CGFloat svgY = (screenHeight - size) / 2.0;
    self.frame = CGRectMake(svgX, svgY, size, size);
    
    // Update the layer transforms to match the new size
    CATransform3D transform = [self transformForPath];
    self.shapeLayer.transform = transform;
    self.glowLayer.transform = transform;
    
    // Update connection lines
    [self updateConnectionLines];
}

- (void)setInnerConnectionLineThickness:(CGFloat)thickness {
    // Handle negative values - use absolute value for line width
    CGFloat baseLineWidth = fabs(thickness);
    
    // Use different scaling for inner connection lines - divide by 10 to match outer lines
    CGFloat scaledLineWidth = baseLineWidth / 10.0;
    
    self.innerConnectionLayer.lineWidth = scaledLineWidth;
}

@end

NS_ASSUME_NONNULL_END 
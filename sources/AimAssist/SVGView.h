//
//  SVGView.h
//  Sapphire
//
//  
//

#import <UIKit/UIKit.h>

@interface SVGView : UIView

- (instancetype)initWithFrame:(CGRect)frame;
- (void)updateConnectionLines;
- (void)updateConnectionLinesWithCircleCenter:(CGPoint)circleCenter circleRadius:(CGFloat)circleRadius;
- (void)clearAllLabels;

// Public methods for DrawingManager to update properties
- (void)updateSVGLineThickness:(CGFloat)thickness;
- (void)updateConnectionLineThickness:(CGFloat)thickness;
- (void)updateConnectionLineAlpha:(CGFloat)alpha;
- (void)setInnerConnectionLineThickness:(CGFloat)thickness;
- (void)updateSVGColor:(UIColor *)color;
- (void)setConnectionLinesEnabled:(BOOL)enabled;
- (void)updateSVGSize:(CGFloat)size;

@end 
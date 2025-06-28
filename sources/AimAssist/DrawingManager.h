//
//  DrawingManager.h
//  Sapphire
//
//  
//

#import <UIKit/UIKit.h>
#import "CircleView.h"

@class SVGView;
@class CircleView;

@interface DrawingManager : NSObject <CircleViewDelegate>

@property (nonatomic, strong) SVGView *svgView;
@property (nonatomic, strong) CircleView *circleView;
@property (nonatomic, assign) BOOL svgVisible;
@property (nonatomic, assign) BOOL circleVisible;
@property (nonatomic, assign) CGFloat circleSize;

- (instancetype)initWithParentView:(UIView *)parentView;
- (void)createSVGView;
- (void)createCircleView;
- (void)toggleSVG:(BOOL)visible;
- (void)toggleCircle:(BOOL)visible;
- (void)updateSVGPosition;
- (void)updateCirclePosition;
- (void)updateSVGSize:(CGFloat)size;
- (void)updateCircleSize:(CGFloat)size;
- (void)updateSVGLineThickness:(CGFloat)thickness;
- (void)updateConnectionLineThickness:(CGFloat)thickness;
- (void)updateConnectionLineAlpha:(CGFloat)alpha;
- (void)updateSVGColor:(UIColor *)color;
- (void)updateCircleColor:(UIColor *)color;
- (void)updateCircleThickness:(CGFloat)thickness;
- (void)setConnectionLinesEnabled:(BOOL)enabled;
- (void)updateSVGPositionX:(CGFloat)x;
- (void)updateSVGPositionY:(CGFloat)y;
- (void)setInnerConnectionLineThickness:(CGFloat)thickness;

@end 
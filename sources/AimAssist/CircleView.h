//
//  CircleView.h
//  Sapphire
//
//  
//

#import <UIKit/UIKit.h>

@protocol CircleViewDelegate <NSObject>
- (void)circleViewDidMove:(UIView *)circleView;
@end

@interface CircleView : UIView <UIGestureRecognizerDelegate>

@property (nonatomic, weak) id<CircleViewDelegate> delegate;

- (instancetype)initWithFrame:(CGRect)frame;
- (void)updateColor:(UIColor *)color;
- (void)updateThickness:(CGFloat)thickness;
- (void)updateSize:(CGFloat)size;

@end 
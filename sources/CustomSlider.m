//
//  CustomSlider.m
//  Sapphire
//
//  Created by Alex on 2025/6/26.
//

#import "CustomSlider.h"

@implementation CustomSlider

- (CGRect)trackRectForBounds:(CGRect)bounds {
    CGRect originalRect = [super trackRectForBounds:bounds];
    return CGRectMake(originalRect.origin.x,
                     originalRect.origin.y + (originalRect.size.height - 8.0) / 2,
                     originalRect.size.width,
                     8.0); // Wysokość paska 8.0
}

@end 
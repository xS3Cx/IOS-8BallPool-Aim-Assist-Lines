#import <notify.h>
#import <WebKit/WebKit.h>
#import <AVFoundation/AVFoundation.h>

#import "HUDHelper.h"
#import "MainButton.h"
#import "SapphireApp.h"
#import "UIApplication+Private.h"
#import "Memory.h"

#define HUD_TRANSITION_DURATION 0.25

// Define the notification constants
NSString * const kToggleHUDAfterLaunchNotificationName = @"a0.sapphire.external.notification.toggle-hud";
NSString * const kToggleHUDAfterLaunchNotificationActionKey = @"action";
NSString * const kToggleHUDAfterLaunchNotificationActionToggleOn = @"toggle-on";
NSString * const kToggleHUDAfterLaunchNotificationActionToggleOff = @"toggle-off";

// Static variable to track if we should toggle HUD after launch
static BOOL _shouldToggleHUDAfterLaunch = NO;

// Particle view for background particles
@interface ParticleView : UIView
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, strong) NSMutableArray *particles;
- (void)startParticles;
- (void)stopParticles;
@end

@implementation ParticleView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupParticles];
    }
    return self;
}

- (void)setupParticles {
    self.backgroundColor = [UIColor clearColor];
    self.userInteractionEnabled = NO;
    
    // Initialize particles array
    self.particles = [NSMutableArray array];
    
    // Create initial particles
    for (int i = 0; i < 50; i++) {
        [self createParticle];
    }
}

- (void)createParticle {
    // Random position
    CGFloat x = (CGFloat)arc4random_uniform((uint32_t)self.bounds.size.width);
    CGFloat y = (CGFloat)arc4random_uniform((uint32_t)self.bounds.size.height);
    
    // Random size (1-5 pixels)
    CGFloat size = 1.0 + (CGFloat)arc4random_uniform(5);
    
    // Much more varied movement patterns with higher speeds
    CGFloat speedX, speedY;
    int movementType = arc4random_uniform(8);
    
    switch (movementType) {
        case 0: // Fast left and up
            speedX = -2.0 - (CGFloat)arc4random_uniform(4);
            speedY = -1.5 - (CGFloat)arc4random_uniform(3);
            break;
        case 1: // Fast right and down
            speedX = 1.5 + (CGFloat)arc4random_uniform(4);
            speedY = 1.0 + (CGFloat)arc4random_uniform(3);
            break;
        case 2: // Fast diagonal up-right
            speedX = 1.0 + (CGFloat)arc4random_uniform(3);
            speedY = -1.2 - (CGFloat)arc4random_uniform(3);
            break;
        case 3: // Fast diagonal down-left
            speedX = -1.8 - (CGFloat)arc4random_uniform(3);
            speedY = 1.2 + (CGFloat)arc4random_uniform(3);
            break;
        case 4: // Very fast horizontal left
            speedX = -3.0 - (CGFloat)arc4random_uniform(3);
            speedY = -0.5 + (CGFloat)arc4random_uniform(2) - 1.0;
            break;
        case 5: // Very fast vertical up
            speedX = -0.8 + (CGFloat)arc4random_uniform(4) - 2.0;
            speedY = -2.5 - (CGFloat)arc4random_uniform(3);
            break;
        case 6: // Circular motion
            speedX = 1.5 + (CGFloat)arc4random_uniform(2);
            speedY = 1.5 + (CGFloat)arc4random_uniform(2);
            break;
        case 7: // Zigzag motion
            speedX = -1.0 - (CGFloat)arc4random_uniform(2);
            speedY = 1.0 + (CGFloat)arc4random_uniform(2);
            break;
        default:
            speedX = -1.5 - (CGFloat)arc4random_uniform(3);
            speedY = -0.8 - (CGFloat)arc4random_uniform(2);
            break;
    }
    
    // Random opacity with more variation
    CGFloat opacity = 0.2 + (CGFloat)arc4random_uniform(80) / 100.0;
    
    // Add some particles with pulsing effect
    BOOL shouldPulse = arc4random_uniform(10) < 4; // 40% chance to pulse
    
    // Add acceleration for some particles
    BOOL shouldAccelerate = arc4random_uniform(10) < 3; // 30% chance to accelerate
    
    NSDictionary *particle = @{
        @"x": @(x),
        @"y": @(y),
        @"size": @(size),
        @"speedX": @(speedX),
        @"speedY": @(speedY),
        @"opacity": @(opacity),
        @"shouldPulse": @(shouldPulse),
        @"shouldAccelerate": @(shouldAccelerate),
        @"pulsePhase": @((CGFloat)arc4random_uniform(100) / 100.0 * 2 * M_PI),
        @"originalSize": @(size),
        @"originalOpacity": @(opacity),
        @"originalSpeedX": @(speedX),
        @"originalSpeedY": @(speedY),
        @"lifeTime": @(0.0)
    };
    
    [self.particles addObject:particle];
}

- (void)startParticles {
    if (!self.displayLink) {
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateParticles)];
        [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
}

- (void)stopParticles {
    [self.displayLink invalidate];
    self.displayLink = nil;
}

- (void)updateParticles {
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Clear background
    CGContextClearRect(context, rect);
    
    // Update and draw particles
    NSMutableArray *particlesToRemove = [NSMutableArray array];
    static CGFloat time = 0;
    time += 0.016; // Approximate frame time
    
    for (NSDictionary *particle in self.particles) {
        CGFloat x = [particle[@"x"] floatValue];
        CGFloat y = [particle[@"y"] floatValue];
        CGFloat size = [particle[@"size"] floatValue];
        CGFloat opacity = [particle[@"opacity"] floatValue];
        BOOL shouldPulse = [particle[@"shouldPulse"] boolValue];
        BOOL shouldAccelerate = [particle[@"shouldAccelerate"] boolValue];
        CGFloat pulsePhase = [particle[@"pulsePhase"] floatValue];
        CGFloat originalSize = [particle[@"originalSize"] floatValue];
        CGFloat originalOpacity = [particle[@"originalOpacity"] floatValue];
        CGFloat originalSpeedX = [particle[@"originalSpeedX"] floatValue];
        CGFloat originalSpeedY = [particle[@"originalSpeedY"] floatValue];
        CGFloat lifeTime = [particle[@"lifeTime"] floatValue];
        
        // Update lifetime
        lifeTime += 0.016;
        
        // Apply pulsing effect if enabled
        if (shouldPulse) {
            CGFloat pulseValue = sin(time * 3 + pulsePhase) * 0.4 + 0.6; // Pulse between 0.2 and 1.0
            size = originalSize * pulseValue;
            opacity = originalOpacity * pulseValue;
        }
        
        // Apply acceleration if enabled
        CGFloat currentSpeedX = originalSpeedX;
        CGFloat currentSpeedY = originalSpeedY;
        if (shouldAccelerate) {
            CGFloat acceleration = 1.0 + (lifeTime * 0.5); // Accelerate over time
            currentSpeedX = originalSpeedX * acceleration;
            currentSpeedY = originalSpeedY * acceleration;
        }
        
        // Add some random movement variation
        CGFloat randomX = (sin(time * 2 + lifeTime) * 0.3);
        CGFloat randomY = (cos(time * 1.5 + lifeTime) * 0.3);
        
        // Update position with all effects
        CGFloat newX = x + currentSpeedX + randomX;
        CGFloat newY = y + currentSpeedY + randomY;
        
        // Check if particle is off screen (all edges)
        if (newX < -size || newY < -size || newX > self.bounds.size.width + size || newY > self.bounds.size.height + size) {
            [particlesToRemove addObject:particle];
            continue;
        }
        
        // Update particle data
        NSMutableDictionary *updatedParticle = [particle mutableCopy];
        updatedParticle[@"x"] = @(newX);
        updatedParticle[@"y"] = @(newY);
        updatedParticle[@"lifeTime"] = @(lifeTime);
        
        // Draw particle with anti-aliasing and glow effect
        CGContextSetFillColorWithColor(context, [[UIColor whiteColor] colorWithAlphaComponent:opacity].CGColor);
        CGContextSetAllowsAntialiasing(context, true);
        CGContextSetShouldAntialias(context, true);
        
        // Draw glow effect for some particles
        if (shouldPulse) {
            CGContextSetShadowWithColor(context, CGSizeMake(0, 0), 2.0, [[UIColor whiteColor] colorWithAlphaComponent:opacity * 0.5].CGColor);
        }
        
        CGContextFillEllipseInRect(context, CGRectMake(newX, newY, size, size));
        
        // Reset shadow
        CGContextSetShadowWithColor(context, CGSizeMake(0, 0), 0, NULL);
    }
    
    // Remove off-screen particles and create new ones
    [self.particles removeObjectsInArray:particlesToRemove];
    
    // Create new particles to maintain count
    while (self.particles.count < 60) { // Increased particle count
        [self createParticle];
    }
}

@end

// Debug overlay view for showing debug information
@interface DebugOverlayView : UIView
@property (nonatomic, strong) UILabel *debugLabel;
- (void)showDebugInfo:(NSString *)info;
- (void)hideDebugInfo;
@end

@implementation DebugOverlayView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupDebugOverlay];
    }
    return self;
}

- (void)setupDebugOverlay {
    self.backgroundColor = [UIColor clearColor];
    self.layer.cornerRadius = 25.0;
    self.hidden = YES;
    
    // Debug label
    self.debugLabel = [[UILabel alloc] init];
    self.debugLabel.textColor = [UIColor whiteColor];
    self.debugLabel.font = [UIFont systemFontOfSize:12.0];
    self.debugLabel.numberOfLines = 0;
    self.debugLabel.textAlignment = NSTextAlignmentLeft;
    [self addSubview:self.debugLabel];
    
    // Setup constraints
    self.debugLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:@[
        [self.debugLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:8],
        [self.debugLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:8],
        [self.debugLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-8],
        [self.debugLabel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-8]
    ]];
}

- (NSAttributedString *)createAttributedStringWithIcons:(NSDictionary *)iconTextPairs {
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] init];
    
    if (@available(iOS 13.0, *)) {
        UIImageSymbolConfiguration *symbolConfig = [UIImageSymbolConfiguration configurationWithPointSize:12 weight:UIImageSymbolWeightRegular];
        UIImageSymbolConfiguration *titleConfig = [UIImageSymbolConfiguration configurationWithPointSize:14 weight:UIImageSymbolWeightBold];
        
        for (NSString *iconName in iconTextPairs) {
            NSString *text = iconTextPairs[iconName];
            
            // Check if this is a title (starts with "---")
            if ([text hasPrefix:@"---"]) {
                // Add extra spacing before title
                NSAttributedString *spacingString = [[NSAttributedString alloc] initWithString:@"\n"];
                [attributedString appendAttributedString:spacingString];
                
                // Create title with bold icon and background
                UIImage *titleIcon = [[UIImage systemImageNamed:iconName withConfiguration:titleConfig] imageWithTintColor:[UIColor whiteColor]];
                
                // Create background for title text
                UIFont *titleFont = [UIFont systemFontOfSize:14.0 weight:UIFontWeightBold];
                NSString *titleText = [text substringFromIndex:3];
                CGSize titleTextSize = [titleText sizeWithAttributes:@{NSFontAttributeName: titleFont}];
                
                // Create combined background for icon + text
                CGFloat combinedWidth = 18 + 8 + titleTextSize.width + 16; // icon + space + text + padding
                UIView *combinedTitleBg = [[UIView alloc] initWithFrame:CGRectMake(0, 0, combinedWidth, 18)];
                combinedTitleBg.backgroundColor = [UIColor colorWithRed:20.0/255.0 green:20.0/255.0 blue:20.0/255.0 alpha:0.8];
                combinedTitleBg.layer.cornerRadius = 9;
                combinedTitleBg.clipsToBounds = YES;
                
                // Create image from background view
                UIGraphicsBeginImageContextWithOptions(combinedTitleBg.bounds.size, NO, 0);
                [combinedTitleBg.layer renderInContext:UIGraphicsGetCurrentContext()];
                UIImage *combinedBgImage = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
                
                // Create blue background for icon
                UIView *iconBg = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 18, 18)];
                iconBg.backgroundColor = [UIColor colorWithRed:15.0/255.0 green:82.0/255.0 blue:186.0/255.0 alpha:1.0];
                iconBg.layer.cornerRadius = 9;
                iconBg.clipsToBounds = YES;
                
                UIGraphicsBeginImageContextWithOptions(iconBg.bounds.size, NO, 0);
                [iconBg.layer renderInContext:UIGraphicsGetCurrentContext()];
                UIImage *iconBgImage = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
                
                // Draw combined background, blue icon background, icon, and text
                UIGraphicsBeginImageContextWithOptions(CGSizeMake(combinedWidth, 18), NO, 0);
                [combinedBgImage drawInRect:CGRectMake(0, 0, combinedWidth, 18)];
                [iconBgImage drawInRect:CGRectMake(0, 0, 18, 18)];
                [titleIcon drawInRect:CGRectMake(3, 2, 12, 14)];
                [titleText drawInRect:CGRectMake(29, (18-titleTextSize.height)/2, titleTextSize.width, titleTextSize.height) withAttributes:@{NSFontAttributeName: titleFont, NSForegroundColorAttributeName: [UIColor whiteColor]}];
                UIImage *combinedTitleImage = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
                
                NSTextAttachment *titleAttachment = [[NSTextAttachment alloc] init];
                titleAttachment.image = combinedTitleImage;
                titleAttachment.bounds = CGRectMake(0, -2, combinedWidth, 18);
                
                NSAttributedString *titleString = [NSAttributedString attributedStringWithAttachment:titleAttachment];
                [attributedString appendAttributedString:titleString];
                
                // Add spacing after title
                NSAttributedString *afterSpacingString = [[NSAttributedString alloc] initWithString:@"\n"];
                [attributedString appendAttributedString:afterSpacingString];
            } else {
                // Create regular icon with background
                UIImage *iconImage = [[UIImage systemImageNamed:iconName withConfiguration:symbolConfig] imageWithTintColor:[UIColor whiteColor]];
                
                // Create background for regular text
                UIFont *textFont = [UIFont systemFontOfSize:12.0];
                CGSize textSize = [text sizeWithAttributes:@{NSFontAttributeName: textFont}];
                
                // Create combined background for icon + text
                CGFloat combinedWidth = 16 + 8 + textSize.width + 16; // icon + space + text + padding
                UIView *combinedBg = [[UIView alloc] initWithFrame:CGRectMake(0, 0, combinedWidth, 16)];
                combinedBg.backgroundColor = [UIColor colorWithRed:20.0/255.0 green:20.0/255.0 blue:20.0/255.0 alpha:0.8];
                combinedBg.layer.cornerRadius = 8;
                combinedBg.clipsToBounds = YES;
                
                // Create image from background view
                UIGraphicsBeginImageContextWithOptions(combinedBg.bounds.size, NO, 0);
                [combinedBg.layer renderInContext:UIGraphicsGetCurrentContext()];
                UIImage *combinedBgImage = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
                
                // Create blue background for icon
                UIView *iconBg = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 16, 16)];
                iconBg.backgroundColor = [UIColor colorWithRed:15.0/255.0 green:82.0/255.0 blue:186.0/255.0 alpha:1.0];
                iconBg.layer.cornerRadius = 8;
                iconBg.clipsToBounds = YES;
                
                UIGraphicsBeginImageContextWithOptions(iconBg.bounds.size, NO, 0);
                [iconBg.layer renderInContext:UIGraphicsGetCurrentContext()];
                UIImage *iconBgImage = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
                
                // Draw combined background, blue icon background, icon, and text
                UIGraphicsBeginImageContextWithOptions(CGSizeMake(combinedWidth, 16), NO, 0);
                [combinedBgImage drawInRect:CGRectMake(0, 0, combinedWidth, 16)];
                [iconBgImage drawInRect:CGRectMake(0, 0, 16, 16)];
                [iconImage drawInRect:CGRectMake(2, 2, 12, 12)];
                [text drawInRect:CGRectMake(26, (16-textSize.height)/2, textSize.width, textSize.height) withAttributes:@{NSFontAttributeName: textFont, NSForegroundColorAttributeName: [UIColor whiteColor]}];
                UIImage *combinedImage = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
                
                NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
                attachment.image = combinedImage;
                attachment.bounds = CGRectMake(0, -2, combinedWidth, 16);
                
                // Add combined icon + text
                NSAttributedString *combinedString = [NSAttributedString attributedStringWithAttachment:attachment];
                [attributedString appendAttributedString:combinedString];
                
                // Add newline
                NSAttributedString *newlineString = [[NSAttributedString alloc] initWithString:@"\n"];
                [attributedString appendAttributedString:newlineString];
            }
        }
    }
    
    return attributedString;
}

- (void)showDebugInfo:(NSString *)info {
    self.debugLabel.text = info;
    self.hidden = NO;
    self.alpha = 0.0;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 1.0;
    }];
}

- (void)showDebugInfoWithIcons:(NSDictionary *)iconTextPairs {
    NSAttributedString *attributedString = [self createAttributedStringWithIcons:iconTextPairs];
    self.debugLabel.attributedText = attributedString;
    self.hidden = NO;
    self.alpha = 0.0;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 1.0;
    }];
}

- (void)hideDebugInfo {
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 0.0;
    } completion:^(BOOL finished) {
        self.hidden = YES;
    }];
}

@end

// Social media icons view for Telegram and GitHub
@interface SocialIconsView : UIView
@property (nonatomic, strong) UIButton *telegramButton;
@property (nonatomic, strong) UIButton *githubButton;
- (void)setupSocialIcons;
@end

@implementation SocialIconsView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupSocialIcons];
    }
    return self;
}

- (void)setupSocialIcons {
    self.backgroundColor = [UIColor clearColor];
    
    // Create Telegram button
    self.telegramButton = [UIButton buttonWithType:UIButtonTypeCustom];
    // Use system icon for Telegram (paperplane.fill is closest to Telegram icon)
    if (@available(iOS 13.0, *)) {
        UIImageSymbolConfiguration *symbolConfig = [UIImageSymbolConfiguration configurationWithPointSize:20 weight:UIImageSymbolWeightMedium];
        UIImage *telegramIcon = [[UIImage systemImageNamed:@"paperplane.fill" withConfiguration:symbolConfig] imageWithTintColor:[UIColor whiteColor]];
        [self.telegramButton setImage:telegramIcon forState:UIControlStateNormal];
    } else {
        // Fallback for older iOS versions
        [self.telegramButton setTitle:@"TG" forState:UIControlStateNormal];
        [self.telegramButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.telegramButton.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    }
    self.telegramButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.telegramButton.backgroundColor = [UIColor colorWithRed:15.0/255.0 green:82.0/255.0 blue:186.0/255.0 alpha:0.8];
    self.telegramButton.layer.cornerRadius = 20.0;
    self.telegramButton.layer.shadowColor = [UIColor colorWithRed:15.0/255.0 green:82.0/255.0 blue:186.0/255.0 alpha:1.0].CGColor;
    self.telegramButton.layer.shadowOffset = CGSizeMake(0, 2);
    self.telegramButton.layer.shadowOpacity = 0.6;
    self.telegramButton.layer.shadowRadius = 8;
    [self.telegramButton addTarget:self action:@selector(telegramTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.telegramButton];
    
    // Create GitHub button
    self.githubButton = [UIButton buttonWithType:UIButtonTypeCustom];
    // Use github-mark-white.png image with white color on blue background
    UIImage *githubImage = [UIImage imageNamed:@"github-mark-white"];
    if (@available(iOS 13.0, *)) {
        githubImage = [githubImage imageWithTintColor:[UIColor whiteColor]];
    }
    [self.githubButton setImage:githubImage forState:UIControlStateNormal];
    self.githubButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.githubButton.backgroundColor = [UIColor colorWithRed:15.0/255.0 green:82.0/255.0 blue:186.0/255.0 alpha:0.8];
    self.githubButton.layer.cornerRadius = 20.0;
    self.githubButton.layer.shadowColor = [UIColor colorWithRed:15.0/255.0 green:82.0/255.0 blue:186.0/255.0 alpha:1.0].CGColor;
    self.githubButton.layer.shadowOffset = CGSizeMake(0, 2);
    self.githubButton.layer.shadowOpacity = 0.6;
    self.githubButton.layer.shadowRadius = 8;
    [self.githubButton addTarget:self action:@selector(githubTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.githubButton];
    
    // Setup constraints
    self.telegramButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.githubButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:@[
        [self.telegramButton.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.telegramButton.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [self.telegramButton.widthAnchor constraintEqualToConstant:40],
        [self.telegramButton.heightAnchor constraintEqualToConstant:40],
        
        [self.githubButton.leadingAnchor constraintEqualToAnchor:self.telegramButton.trailingAnchor constant:12],
        [self.githubButton.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [self.githubButton.widthAnchor constraintEqualToConstant:40],
        [self.githubButton.heightAnchor constraintEqualToConstant:40],
        [self.githubButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor]
    ]];
}

- (void)telegramTapped:(UIButton *)sender {
    // Add haptic feedback
    UIImpactFeedbackGenerator *impactFeedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
    [impactFeedback impactOccurred];
    
    // Open Telegram URL
    NSURL *telegramURL = [NSURL URLWithString:@"https://t.me/cruexgg"];
    if ([[UIApplication sharedApplication] canOpenURL:telegramURL]) {
        [[UIApplication sharedApplication] openURL:telegramURL options:@{} completionHandler:nil];
    }
}

- (void)githubTapped:(UIButton *)sender {
    // Add haptic feedback
    UIImpactFeedbackGenerator *impactFeedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
    [impactFeedback impactOccurred];
    
    // Open GitHub URL
    NSURL *githubURL = [NSURL URLWithString:@"https://github.com/Lessica/TrollSpeed"];
    if ([[UIApplication sharedApplication] canOpenURL:githubURL]) {
        [[UIApplication sharedApplication] openURL:githubURL options:@{} completionHandler:nil];
    }
}

@end

@implementation SapphireApp {
    MainButton *_mainButton;
    UIImageView *_sapphireImageView;
    UIImageView *_cheatsImageView;
    UIImageView *_buttonOverlayImageView;
    BOOL _isRemoteHUDActive;
    UIImpactFeedbackGenerator *_impactFeedbackGenerator;
    DebugOverlayView *_debugOverlay;
    UILabel *_awaitingLabel;
    UILabel *_descriptionLabel;
    UILabel *_technicalLogsLabel;
    WKWebView *_loadingView;
    NSTimer *_processCheckTimer;
    BOOL _gameProcessDetected;
    ParticleView *_particleView;
    NSMutableArray<NSAttributedString *> *_logLinesArray;
    AVAudioPlayer *_backgroundMusicPlayer;
    SocialIconsView *_socialIconsView;
}

- (BOOL)isHUDEnabled
{
    return IsHUDEnabled();
}

- (void)setHUDEnabled:(BOOL)enabled
{
    SetHUDEnabled(enabled);
}

- (void)loadView
{
    CGRect bounds = UIScreen.mainScreen.bounds;

    self.view = [[UIView alloc] initWithFrame:bounds];
    self.view.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.58f];

    self.backgroundView = [[UIView alloc] initWithFrame:bounds];
    self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.backgroundView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.backgroundView];

    // Create particle view for background particles
    _particleView = [[ParticleView alloc] initWithFrame:bounds];
    _particleView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.backgroundView addSubview:_particleView];

    // Create social icons view
    _socialIconsView = [[SocialIconsView alloc] initWithFrame:CGRectZero];
    _socialIconsView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.backgroundView addSubview:_socialIconsView];

    // Create UIImageView for SAPPHIRE image
    _sapphireImageView = [[UIImageView alloc] init];
    _sapphireImageView.contentMode = UIViewContentModeScaleAspectFit;
    _sapphireImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.backgroundView addSubview:_sapphireImageView];

    // Create UIImageView for CHEATS image
    _cheatsImageView = [[UIImageView alloc] init];
    _cheatsImageView.contentMode = UIViewContentModeScaleAspectFit;
    _cheatsImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.backgroundView addSubview:_cheatsImageView];

    // Create awaiting label
    _awaitingLabel = [[UILabel alloc] init];
    _awaitingLabel.text = @"Awaiting Process";
    _awaitingLabel.textColor = [UIColor whiteColor];
    _awaitingLabel.font = [UIFont boldSystemFontOfSize:24.0];
    _awaitingLabel.textAlignment = NSTextAlignmentCenter;
    [self.backgroundView addSubview:_awaitingLabel];
    
    // Create description label
    _descriptionLabel = [[UILabel alloc] init];
    _descriptionLabel.text = @"Made By AlexZero";
    _descriptionLabel.textColor = [UIColor colorWithRed:0.7 green:0.7 blue:0.7 alpha:0.8];
    _descriptionLabel.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:11.0];
    _descriptionLabel.textAlignment = NSTextAlignmentCenter;
    [self.backgroundView addSubview:_descriptionLabel];
    // Create technical logs label
    _technicalLogsLabel = [[UILabel alloc] init];
    _technicalLogsLabel.text = @""; // Start with empty logs
    _technicalLogsLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.7]; // Changed to white
    _technicalLogsLabel.font = [UIFont systemFontOfSize:11.0]; // Smaller font
    _technicalLogsLabel.textAlignment = NSTextAlignmentLeft; // Changed to left alignment like description
    _technicalLogsLabel.numberOfLines = 0;
    
    // Add background with same color as debug info
    _technicalLogsLabel.backgroundColor = [UIColor colorWithRed:20.0/255.0 green:20.0/255.0 blue:20.0/255.0 alpha:0.8];
    _technicalLogsLabel.layer.cornerRadius = 8.0;
    _technicalLogsLabel.clipsToBounds = YES;
    
    // Add padding
    _technicalLogsLabel.layer.borderWidth = 0;
    _technicalLogsLabel.layer.borderColor = [UIColor clearColor].CGColor;
    
    [self.backgroundView addSubview:_technicalLogsLabel];
    
    // Create loading WebView with HTML/CSS animation
    WKWebViewConfiguration *loadingWebConfig = [[WKWebViewConfiguration alloc] init];
    loadingWebConfig.allowsInlineMediaPlayback = YES;
    loadingWebConfig.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;
    
    _loadingView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:loadingWebConfig];
    _loadingView.backgroundColor = [UIColor clearColor];
    _loadingView.opaque = NO;
    _loadingView.scrollView.scrollEnabled = NO;
    _loadingView.scrollView.bounces = NO;
    _loadingView.userInteractionEnabled = NO;
    [self.backgroundView addSubview:_loadingView];
    
    // Load the HTML with CSS loader
    [self loadLoadingHTML];

    _mainButton = [MainButton buttonWithType:UIButtonTypeCustom];
    [_mainButton setImage:[UIImage imageNamed:@"SAPBUTTON.png"] forState:UIControlStateNormal];
    _mainButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    _mainButton.backgroundColor = [UIColor clearColor];
    _mainButton.layer.cornerRadius = 25.0;
    _mainButton.layer.shadowColor = [UIColor colorWithRed:15.0/255.0 green:82.0/255.0 blue:186.0/255.0 alpha:1.0].CGColor;
    _mainButton.layer.shadowOffset = CGSizeMake(0, 0);
    _mainButton.layer.shadowOpacity = 0.6;
    _mainButton.layer.shadowRadius = 12;
    
    // Configure button for perfect centering
    _mainButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    _mainButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    
    [_mainButton addTarget:self action:@selector(tapMainButton:) forControlEvents:UIControlEventTouchUpInside];
    [_mainButton addTarget:self action:@selector(buttonTouchDown:) forControlEvents:UIControlEventTouchDown];
    [_mainButton addTarget:self action:@selector(buttonTouchUp:) forControlEvents:UIControlEventTouchUpOutside];
    _mainButton.hidden = YES; // Initially hidden
    _mainButton.alpha = 0.0; // Initially transparent
    
    // Add overlay image view for INJECT/UNLOAD text
    _buttonOverlayImageView = [[UIImageView alloc] init];
    _buttonOverlayImageView.contentMode = UIViewContentModeScaleAspectFit;
    _buttonOverlayImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [_mainButton addSubview:_buttonOverlayImageView];
    
    [self.backgroundView addSubview:_mainButton];

    // Create debug overlay
    _debugOverlay = [[DebugOverlayView alloc] initWithFrame:CGRectZero];
    [self.backgroundView addSubview:_debugOverlay];

    UILayoutGuide *safeArea = self.backgroundView.safeAreaLayoutGuide;
    [_mainButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_sapphireImageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_cheatsImageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_debugOverlay setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_awaitingLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_loadingView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_descriptionLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_technicalLogsLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [NSLayoutConstraint activateConstraints:@[
        // Social icons view - top right corner
        [_socialIconsView.topAnchor constraintEqualToAnchor:safeArea.topAnchor constant:20],
        [_socialIconsView.trailingAnchor constraintEqualToAnchor:safeArea.trailingAnchor constant:-20],
        [_socialIconsView.widthAnchor constraintEqualToConstant:92], // 40 + 12 + 40
        [_socialIconsView.heightAnchor constraintEqualToConstant:40],
        
        [_sapphireImageView.centerXAnchor constraintEqualToAnchor:safeArea.centerXAnchor],
        [_sapphireImageView.topAnchor constraintEqualToAnchor:safeArea.topAnchor constant:30],
        [_sapphireImageView.widthAnchor constraintEqualToConstant:450],
        [_sapphireImageView.heightAnchor constraintEqualToConstant:280],
        
        [_cheatsImageView.trailingAnchor constraintEqualToAnchor:_sapphireImageView.trailingAnchor],
        [_cheatsImageView.topAnchor constraintEqualToAnchor:_sapphireImageView.bottomAnchor constant:5],
        [_cheatsImageView.widthAnchor constraintEqualToConstant:150],
        [_cheatsImageView.heightAnchor constraintEqualToConstant:80],
        
        [_descriptionLabel.centerXAnchor constraintEqualToAnchor:safeArea.centerXAnchor constant:-120],
        [_descriptionLabel.topAnchor constraintEqualToAnchor:safeArea.topAnchor constant:200],
        
        // Move technical logs lower to make space for social icons
        [_technicalLogsLabel.centerXAnchor constraintEqualToAnchor:safeArea.centerXAnchor],
        [_technicalLogsLabel.topAnchor constraintEqualToAnchor:_descriptionLabel.bottomAnchor constant:30],
        [_technicalLogsLabel.widthAnchor constraintEqualToConstant:300],
        [_technicalLogsLabel.heightAnchor constraintGreaterThanOrEqualToConstant:20],
        
        [_awaitingLabel.centerXAnchor constraintEqualToAnchor:safeArea.centerXAnchor],
        [_awaitingLabel.centerYAnchor constraintEqualToAnchor:safeArea.centerYAnchor],
        
        [_loadingView.centerXAnchor constraintEqualToAnchor:safeArea.centerXAnchor],
        [_loadingView.topAnchor constraintEqualToAnchor:_awaitingLabel.bottomAnchor constant:20],
        [_loadingView.widthAnchor constraintEqualToConstant:60],
        [_loadingView.heightAnchor constraintEqualToConstant:60],
        
        [_mainButton.centerXAnchor constraintEqualToAnchor:safeArea.centerXAnchor],
        [_mainButton.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor constant:-20],
        [_mainButton.widthAnchor constraintEqualToConstant:600],
        [_mainButton.heightAnchor constraintEqualToConstant:160],
        
        // Button overlay image constraints
        [_buttonOverlayImageView.centerXAnchor constraintEqualToAnchor:_mainButton.centerXAnchor],
        [_buttonOverlayImageView.centerYAnchor constraintEqualToAnchor:_mainButton.centerYAnchor],
        [_buttonOverlayImageView.widthAnchor constraintEqualToConstant:180],
        [_buttonOverlayImageView.heightAnchor constraintEqualToConstant:45],
        
        // Debug overlay constraints - moved lower to avoid overlap with social icons
        [_debugOverlay.topAnchor constraintEqualToAnchor:_socialIconsView.bottomAnchor constant:10],
        [_debugOverlay.trailingAnchor constraintEqualToAnchor:safeArea.trailingAnchor constant:-20],
        [_debugOverlay.widthAnchor constraintEqualToAnchor:_debugOverlay.debugLabel.widthAnchor constant:16],
        [_debugOverlay.heightAnchor constraintLessThanOrEqualToConstant:200],
    ]];
    _mainButton.titleLabel.textAlignment = NSTextAlignmentCenter;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _logLinesArray = [NSMutableArray array];

    _impactFeedbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
    
    // Start particle animation
    [_particleView startParticles];
    
    // Setup and start background music
    [self setupBackgroundMusic];
    
    // Ensure initial states
    _gameProcessDetected = NO;
    _mainButton.hidden = YES;
    _mainButton.alpha = 0.0;
    _awaitingLabel.hidden = NO;
    _awaitingLabel.alpha = 1.0;
    _loadingView.hidden = NO;
    _loadingView.alpha = 1.0;
    
    // Apply default position to CHEATS label
    _cheatsImageView.transform = CGAffineTransformMakeTranslation(-16, -145);
    
    [self reloadMainButtonState];
    [self loadSapphireImages];
    
    // Start checking for game process after a short delay
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self startProcessChecking];
    });
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)reloadMainButtonState
{
    BOOL wasEnabled = _isRemoteHUDActive;
    _isRemoteHUDActive = [self isHUDEnabled];
    
    // Hide debug overlay when unloading (going from enabled to disabled)
    if (wasEnabled && !_isRemoteHUDActive) {
        [_debugOverlay hideDebugInfo];
    }
    
    // Update button overlay image based on state
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || !strongSelf->_buttonOverlayImageView) {
            return;
        }
        
        NSString *imageName = strongSelf->_isRemoteHUDActive ? @"unload.png" : @"inject.png";
        
        // Fade out current image
        [UIView animateWithDuration:0.2 animations:^{
            strongSelf->_buttonOverlayImageView.alpha = 0.0;
        } completion:^(BOOL finished) {
            // Change image and fade in
            strongSelf->_buttonOverlayImageView.image = [UIImage imageNamed:imageName];
            [UIView animateWithDuration:0.2 animations:^{
                strongSelf->_buttonOverlayImageView.alpha = 1.0;
            }];
        }];
    });
}

- (void)animateTypingLog:(NSString *)logText completion:(void(^)(void))completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSAttributedString *formattedLine = [self formatLogLine:logText];
        [self->_logLinesArray addObject:formattedLine];

        if (self->_logLinesArray.count > 6) {
            [self->_logLinesArray removeObjectAtIndex:0];
        }

        NSMutableAttributedString *finalLogs = [[NSMutableAttributedString alloc] init];
        for (int i = 0; i < self->_logLinesArray.count; i++) {
            [finalLogs appendAttributedString:self->_logLinesArray[i]];
            if (i < self->_logLinesArray.count - 1) {
                [finalLogs appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
            }
        }

        self->_technicalLogsLabel.alpha = 0.0;
        self->_technicalLogsLabel.attributedText = finalLogs;
        
        [UIView animateWithDuration:0.3 animations:^{
            self->_technicalLogsLabel.alpha = 1.0;
        } completion:^(BOOL finished) {
            if (completion) {
                completion();
            }
        }];
    });
}

- (void)updateTechnicalLogs:(NSString *)logText {
    // This function is not used by tapMainButton, but we'll keep it consistent
    dispatch_async(dispatch_get_main_queue(), ^{
        NSAttributedString *formattedLine = [self formatLogLine:logText];
        [self->_logLinesArray addObject:formattedLine];

        if (self->_logLinesArray.count > 6) {
            [self->_logLinesArray removeObjectAtIndex:0];
        }
        
        NSMutableAttributedString *finalLogs = [[NSMutableAttributedString alloc] init];
        for (int i = 0; i < self->_logLinesArray.count; i++) {
            [finalLogs appendAttributedString:self->_logLinesArray[i]];
            if (i < self->_logLinesArray.count - 1) {
                [finalLogs appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
            }
        }
        self->_technicalLogsLabel.attributedText = finalLogs;
    });
}

- (NSAttributedString *)formatLogLine:(NSString *)logLine {
    NSString *tag = nil;
    NSString *tagText = nil;
    NSString *symbolName = nil;
    UIColor *backgroundColor = nil;
    
    if ([logLine hasPrefix:@"[SUCCESS]"]) {
        tag = @"[SUCCESS]";
        tagText = @"SUCCESS";
        symbolName = @"checkmark.circle.fill";
        backgroundColor = [UIColor colorWithRed:4.0/255.0 green:97.0/255.0 blue:211.0/255.0 alpha:1.0];
    } else if ([logLine hasPrefix:@"[INFO]"]) {
        tag = @"[INFO]";
        tagText = @"INFO";
        symbolName = @"info.circle.fill";
        backgroundColor = [UIColor colorWithRed:4.0/255.0 green:80.0/255.0 blue:174.0/255.0 alpha:1.0];
    } else if ([logLine hasPrefix:@"[ERROR]"]) {
        tag = @"[ERROR]";
        tagText = @"ERROR";
        symbolName = @"exclamationmark.triangle.fill";
        backgroundColor = [UIColor colorWithRed:255.0/255.0 green:59.0/255.0 blue:48.0/255.0 alpha:1.0];
    }
    
    NSMutableAttributedString *finalString = [[NSMutableAttributedString alloc] init];
    
    if (tag) {
        // --- Create the combined tag image (symbol + text + background) ---
        UIFont *tagFont = [UIFont systemFontOfSize:11.0 weight:UIFontWeightBold];
        UIImageSymbolConfiguration *symbolConfig = [UIImageSymbolConfiguration configurationWithPointSize:11.0 weight:UIImageSymbolWeightBold];
        
        UIImage *icon = [[UIImage systemImageNamed:symbolName withConfiguration:symbolConfig] imageWithTintColor:[UIColor whiteColor]];
        NSDictionary *attributes = @{NSFontAttributeName: tagFont, NSForegroundColorAttributeName: [UIColor whiteColor]};
        CGSize tagTextSize = [tagText sizeWithAttributes:attributes];

        CGFloat hPadding = 8.0;
        CGFloat vPadding = 2.0;
        CGFloat iconWidth = 12.0;
        CGFloat iconPadding = 4.0;
        CGSize bgSize = CGSizeMake(hPadding + iconWidth + iconPadding + tagTextSize.width + hPadding, tagTextSize.height + vPadding * 2);
        
        UIGraphicsBeginImageContextWithOptions(bgSize, NO, 0.0);
        
        [backgroundColor set];
        [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, bgSize.width, bgSize.height) cornerRadius:5.0] fill];
        
        [icon drawInRect:CGRectMake(hPadding, (bgSize.height - iconWidth)/2, iconWidth, iconWidth)];
        [tagText drawInRect:CGRectMake(hPadding + iconWidth + iconPadding, (bgSize.height - tagTextSize.height)/2, tagTextSize.width, tagTextSize.height) withAttributes:attributes];
        
        UIImage *tagImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
        attachment.image = tagImage;
        attachment.bounds = CGRectMake(0, -2.5, bgSize.width, bgSize.height);
        [finalString appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
        
        NSString *messagePart = [logLine substringFromIndex:tag.length];
        NSAttributedString *messageString = [[NSAttributedString alloc] initWithString:messagePart attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:11.0], NSForegroundColorAttributeName: [UIColor whiteColor]}];
        [finalString appendAttributedString:messageString];
        
    } else {
        NSAttributedString *plainString = [[NSAttributedString alloc] initWithString:logLine attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:11.0], NSForegroundColorAttributeName: [UIColor whiteColor]}];
        [finalString appendAttributedString:plainString];
    }
    
    return finalString;
}

- (void)tapMainButton:(UIButton *)sender
{
    os_log_debug(OS_LOG_DEFAULT, "- [SapphireApp tapMainButton:%{public}@", sender);

    BOOL isCurrentlyEnabled = [self isHUDEnabled];
    NSString *gameProcessName = @"pool";
    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    NSString *bundleName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    
    [_logLinesArray removeAllObjects];
    _technicalLogsLabel.attributedText = [[NSAttributedString alloc] initWithString:@""];
    
    // Update technical logs with animation based on operation type
    if (isCurrentlyEnabled) {
        // Unload operation
        [self animateTypingLog:@"[INFO] Attempting to unload cheat package..." completion:^{
            [self animateTypingLog:[NSString stringWithFormat:@"[INFO] Target process: %@", gameProcessName] completion:^{
               
                 [self animateTypingLog:@"[SUCCESS] Cheat package unloaded successfully!" completion:^{
                        [self animateTypingLog:@"[SUCCESS] Overlay disabled successfully!" completion:nil];
                    }];
                }];
           
        }];
        
        // Toggle HUD immediately for unload
        [self setHUDEnabled:NO];
        
        // Remove target process file when unloading
        NSString *processNamePath = @"/tmp/SapphireTargetProcess.txt";
        NSError *removeError = nil;
        if ([[NSFileManager defaultManager] fileExistsAtPath:processNamePath]) {
            BOOL removeSuccess = [[NSFileManager defaultManager] removeItemAtPath:processNamePath error:&removeError];
            if (!removeSuccess) {
                //NSLog(@"[ERROR] Failed to remove process name file: %@", removeError);
            } else {
                //NSLog(@"[DEBUG] Successfully removed process name file");
            }
        }
        
        if (self->_impactFeedbackGenerator) {
            [self->_impactFeedbackGenerator impactOccurred];
        }
        
        self.view.userInteractionEnabled = NO;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.view.userInteractionEnabled = YES;
            [self reloadMainButtonState];
            // Restore button glow effect
            [self buttonTouchUp:sender];
        });
        
    } else {
        // Inject operation
        [self animateTypingLog:@"[INFO] Attempting to inject cheat package..." completion:^{
            [self animateTypingLog:[NSString stringWithFormat:@"[INFO] Target process: %@", gameProcessName] completion:^{
                
                MemoryUtils *utils = [[MemoryUtils alloc] initWithProcessName:gameProcessName];
                if (!utils.valid) { 
                    [self animateTypingLog:[NSString stringWithFormat:@"[ERROR] Process not found: %@", gameProcessName] completion:^{
                        [self animateTypingLog:@"[ERROR] Injection failed - target process unavailable" completion:nil];
                    }];
                    
                    NSDictionary *errorIcons = @{
                        @"exclamationmark.triangle": [NSString stringWithFormat:@"Failed to find or access process: %@", gameProcessName],
                        @"info.circle": @"Make sure the game is running."
                    };
                    [self->_debugOverlay showDebugInfoWithIcons:errorIcons];
                    return;
                }

                if (utils && utils.valid) { 
                    // Update technical logs with process info
                    [self animateTypingLog:@"[SUCCESS] Target process located!" completion:^{
                        [self animateTypingLog:[NSString stringWithFormat:@"[INFO] Process Name: %@", utils.processName] completion:^{
                            [self animateTypingLog:[NSString stringWithFormat:@"[INFO] Injecting bundle: %@", bundleName ?: bundleId] completion:^{
                                
                                // Reading an Int32 as Mach-O signature. Common signatures are 0xfeedface, 0xfeedfacf, 0xcafebabe etc.
                                NSError *__autoreleasing readError = nil;
                                uint32_t machoSig = [utils readUInt32AtAddress:utils.baseAddress error:&readError]; 
                                
                                if (readError) {
                                    NSString *errorDescription = readError.localizedDescription;
                                    [self animateTypingLog:@"[ERROR] Failed to read process signature" completion:^{
                                        [self animateTypingLog:[NSString stringWithFormat:@"[ERROR] Memory read error: %@", errorDescription] completion:nil];
                                    }];
                                    
                                    NSDictionary *errorIcons = @{
                                        @"exclamationmark.triangle": @"Failed to read Mach-O signature:",
                                        @"text.alignleft": errorDescription
                                    };
                                    [self->_debugOverlay showDebugInfoWithIcons:errorIcons];
                                    return;
                                }
                                
                                // Update logs with success
                                [self animateTypingLog:@"[SUCCESS] Cheat package injected successfully!" completion:^{
                                    [self animateTypingLog:@"[SUCCESS] Overlay enabled successfully!" completion:nil];
                                }];
                                
                                // Write target process name to file for HUD
                                NSString *processNamePath = @"/tmp/SapphireTargetProcess.txt";
                                NSError *writeError = nil;
                                BOOL writeSuccess = [gameProcessName writeToFile:processNamePath 
                                                                      atomically:YES 
                                                                        encoding:NSUTF8StringEncoding 
                                                                           error:&writeError];
                                if (!writeSuccess) {
                                    //NSLog(@"[ERROR] Failed to write process name to file: %@", writeError);
                                } else {
                                    //NSLog(@"[DEBUG] Successfully wrote process name '%@' to file", gameProcessName);
                                }
                                
                                NSDictionary *successIcons = @{
                                    @"checkmark.circle": @"Game Process Found!",
                                    @"gamecontroller": [NSString stringWithFormat:@"Game: %@", utils.processName],
                                    @"number.circle": [NSString stringWithFormat:@"PID: %d", utils.processID],
                                    @"location": [NSString stringWithFormat:@"Base Address: 0x%llx", utils.baseAddress],
                                    @"magnifyingglass": [NSString stringWithFormat:@"Mach-O Signature: 0x%08x", machoSig],
                                    @"lightbulb": @"Ready To Inject"
                                };
                                
                                [self->_debugOverlay showDebugInfoWithIcons:successIcons];
                                
                                // Toggle HUD after showing info
                                [self setHUDEnabled:YES];
                                
                                if (self->_impactFeedbackGenerator) {
                                    [self->_impactFeedbackGenerator impactOccurred];
                                }
                                
                                self.view.userInteractionEnabled = NO;
                                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                    self.view.userInteractionEnabled = YES;
                                    [self reloadMainButtonState];
                                });
                            }];
                        }];
                    }];
                    
                } else {
                    // This case should ideally be caught by the '!utils.valid' check above.
                    [self animateTypingLog:@"[ERROR] Failed to open process or retrieve base address" completion:^{
                        [self animateTypingLog:@"[ERROR] Injection failed - process access denied" completion:nil];
                    }];
                    
                    NSDictionary *errorIcons = @{
                        @"exclamationmark.triangle": @"Failed to open process or retrieve base address."
                    };
                    [self->_debugOverlay showDebugInfoWithIcons:errorIcons];
                }
            }];
        }];
    }
}

- (void)loadSapphireImages {
    // Load SAPPHIRE image
    if (_sapphireImageView) {
        _sapphireImageView.image = [UIImage imageNamed:@"SAPPHIRE-22-06-2025.png"];
        _sapphireImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    
    // Load CHEATS image
    if (_cheatsImageView) {
        _cheatsImageView.image = [UIImage imageNamed:@"CHEATS-22-06-2025.png"];
        _cheatsImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
}

- (void)loadLoadingHTML {
    NSString *htmlContent = @"<!DOCTYPE html>\
<html lang=\"en\">\
<head>\
    <meta charset=utf-8>\
    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\
    <title>loader</title>\
    <style>\
        body {\
            margin: 0;\
            padding: 0;\
            background: transparent;\
            display: flex;\
            align-items: center;\
            justify-content: center;\
            height: 100vh;\
        }\
        .loader {\
            width: 48px;\
            height: 48px;\
            border-radius: 50%;\
            display: inline-block;\
            border-top: 4px solid rgb(15, 82, 186);\
            border-right: 4px solid transparent;\
            box-sizing: border-box;\
            position: relative;\
            animation: rotation 1s linear infinite;\
        }\
        .loader::after {\
            content: '';\
            box-sizing: border-box;\
            position: absolute;\
            left: 0;\
            top: 0;\
            width: 48px;\
            height: 48px;\
            border-radius: 50%;\
            border-left: 4px solid #0E4AA4;\
            border-bottom: 4px solid transparent;\
            animation: rotation 0.5s linear infinite reverse;\
        }\
        @keyframes rotation {\
            0% {\
                transform: rotate(0deg);\
            }\
            100% {\
                transform: rotate(360deg);\
            }\
        }\
    </style>\
</head>\
<body>\
    <span class=\"loader\"></span>\
</body>\
</html>";
    
    [_loadingView loadHTMLString:htmlContent baseURL:nil];
}

- (void)startProcessChecking {
    // Check immediately
    [self checkForGameProcess];
    
    // Set up timer to check every 2 seconds
    _processCheckTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 
                                                          target:self 
                                                        selector:@selector(checkForGameProcess) 
                                                        userInfo:nil 
                                                         repeats:YES];
}

- (void)checkForGameProcess {
    NSString *gameProcessName = @"pool";
    MemoryUtils *utils = [[MemoryUtils alloc] initWithProcessName:gameProcessName];
    
    BOOL processFound = utils && utils.valid;
    
    if (processFound && !_gameProcessDetected) {
        // Process just found - show button
        _gameProcessDetected = YES;
        [self showMainButton];
    } else if (!processFound && _gameProcessDetected) {
        // Process lost - hide button
        _gameProcessDetected = NO;
        [self hideMainButton];
    }
}

- (void)showMainButton {
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.5 animations:^{
            self->_awaitingLabel.alpha = 0.0;
            self->_loadingView.alpha = 0.0;
        } completion:^(BOOL finished) {
            self->_awaitingLabel.hidden = YES;
            self->_loadingView.hidden = YES;
            
            [UIView animateWithDuration:0.5 animations:^{
                self->_mainButton.alpha = 1.0;
            }];
            self->_mainButton.hidden = NO;
        }];
    });
}

- (void)hideMainButton {
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.5 animations:^{
            self->_mainButton.alpha = 0.0;
        } completion:^(BOOL finished) {
            self->_mainButton.hidden = YES;
            
            [UIView animateWithDuration:0.5 animations:^{
                self->_awaitingLabel.alpha = 1.0;
                self->_loadingView.alpha = 1.0;
            }];
            self->_awaitingLabel.hidden = NO;
            self->_loadingView.hidden = NO;
        }];
    });
}

- (void)buttonTouchDown:(UIButton *)sender {
    // Increase glow effect when button is pressed
    [UIView animateWithDuration:0.2 animations:^{
        sender.layer.shadowRadius = 24;
        sender.layer.shadowOpacity = 0.8;
        sender.transform = CGAffineTransformMakeScale(0.95, 0.95);
    }];
}

- (void)buttonTouchUp:(UIButton *)sender {
    // Restore normal glow effect when button is released
    [UIView animateWithDuration:0.2 animations:^{
        sender.layer.shadowRadius = 12;
        sender.layer.shadowOpacity = 0.6;
        sender.transform = CGAffineTransformIdentity;
    }];
}

- (void)setupBackgroundMusic {
    // Get the path to menu.mp3 in the app bundle
    NSString *musicPath = [[NSBundle mainBundle] pathForResource:@"menu" ofType:@"mp3"];
    
    if (musicPath) {
        NSURL *musicURL = [NSURL fileURLWithPath:musicPath];
        NSError *error = nil;
        
        // Create audio player
        _backgroundMusicPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:musicURL error:&error];
        
        if (_backgroundMusicPlayer && !error) {
            // Configure audio player
            _backgroundMusicPlayer.numberOfLoops = -1; // Loop indefinitely
            _backgroundMusicPlayer.volume = 0.0; // Start with 0 volume for fade in
            
            // Prepare to play
            [_backgroundMusicPlayer prepareToPlay];
            
            // Start playing with delay and fade in
            [self startMusicWithDelay];
            
        } else {
            //NSLog(@"[ERROR] Failed to initialize audio player: %@", error.localizedDescription);
        }
    } else {
        //NSLog(@"[ERROR] menu.mp3 not found in app bundle");
    }
}

- (void)startMusicWithDelay {
    // Start playing immediately but with 0 volume
    BOOL playSuccess = [_backgroundMusicPlayer play];
    if (playSuccess) {
        //NSLog(@"[INFO] Background music started (silent)");
        
        // Wait 2 seconds for app to fully load, then fade in
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self fadeInMusic];
        });
    } else {
        //NSLog(@"[ERROR] Failed to start background music");
    }
}

- (void)fadeInMusic {
    // Fade in music over 3 seconds
    [UIView animateWithDuration:3.0 animations:^{
        // We need to animate volume manually since UIView animation doesn't work with AVAudioPlayer
    } completion:^(BOOL finished) {
        // Use a timer to gradually increase volume
        [self fadeInVolumeFrom:0.0 to:0.7 duration:3.0];
    }];
}

- (void)fadeInVolumeFrom:(float)fromVolume to:(float)toVolume duration:(NSTimeInterval)duration {
    const int steps = 30; // 30 steps for smooth fade
    const float volumeStep = (toVolume - fromVolume) / steps;
    const NSTimeInterval stepDuration = duration / steps;
    
    __block int currentStep = 0;
    
    [NSTimer scheduledTimerWithTimeInterval:stepDuration repeats:YES block:^(NSTimer * _Nonnull timer) {
        currentStep++;
        float currentVolume = fromVolume + (volumeStep * currentStep);
        
        if (self->_backgroundMusicPlayer) {
            self->_backgroundMusicPlayer.volume = currentVolume;
        }
        
        if (currentStep >= steps) {
            [timer invalidate];
            //NSLog(@"[INFO] Background music fade-in completed");
        }
    }];
}

+ (void)setShouldToggleHUDAfterLaunch:(BOOL)shouldToggle {
    _shouldToggleHUDAfterLaunch = shouldToggle;
}

- (void)dealloc {
    if (_processCheckTimer) {
        [_processCheckTimer invalidate];
        _processCheckTimer = nil;
    }
    
    // Stop particle animation
    [_particleView stopParticles];
    
    // Stop background music
    if (_backgroundMusicPlayer) {
        [_backgroundMusicPlayer stop];
        _backgroundMusicPlayer = nil;
    }
}

@end

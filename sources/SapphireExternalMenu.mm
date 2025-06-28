//
//  SapphireExternalMenu.mm
//  Sapphire
//
//  
//

#import <notify.h>
#import <objc/runtime.h>

#import "SapphireExternalMenu.h"
#import "TSEventFetcher.h"
#import "FBSOrientationObserver.h"
#import "FBSOrientationUpdate.h"
#import "Memory.h"
#import "CustomSlider.h"
#import "DrawingManager.h"

@interface SapphireExternalMenu () <UIGestureRecognizerDelegate, UITextFieldDelegate, UIScrollViewDelegate>
@end

@implementation SapphireExternalMenu {
    UIView *_modMenuView;
    UIView *_menuButton;
    UIPanGestureRecognizer *_panGestureRecognizer;
    UITapGestureRecognizer *_tapGestureRecognizer;
    FBSOrientationObserver *_orientationObserver;
    UIInterfaceOrientation _orientation;
    NSString *_targetProcessName;
    MemoryUtils *_memoryUtils;
    NSTimer *_processCheckTimer;
    BOOL _menuVisible;
    UIScrollView *_mainScrollView;
    UIView *_customAlertView;
    NSMutableArray *_activeAlerts;
    DrawingManager *_drawingManager;
    NSInteger _currentSegmentIndex; 
    UIColor *_currentRGBColor; 
    BOOL _rgbThemeEnabled; 
    BOOL _glowEnabled; 
    NSTimer *_rgbCycleTimer;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _orientation = UIInterfaceOrientationPortrait;
        _targetProcessName = nil;
        _memoryUtils = nil;
        _processCheckTimer = nil;
        _menuVisible = NO;
        _rgbCycleTimer = nil;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
   
    _drawingManager = [[DrawingManager alloc] initWithParentView:self.view];
    

    [_drawingManager createCircleView];
    

    [_drawingManager createSVGView];
    
    
    NSString *processNamePath = @"/tmp/SapphireTargetProcess.txt";
    NSError *error = nil;
    NSString *processName = [NSString stringWithContentsOfFile:processNamePath encoding:NSUTF8StringEncoding error:&error];
    
    if (error) {
  
    } else {
       
    }
    
    if (processName && processName.length > 0) {
      
        processName = [processName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
       
        [self setTargetProcessName:processName];
    } else {
       
  
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self retryReadingProcessName];
        });
    }
    
   
    [self setupFBSOrientationObserver];
}

- (void)retryReadingProcessName {
    NSString *processNamePath = @"/tmp/SapphireTargetProcess.txt";
    NSError *error = nil;
    NSString *processName = [NSString stringWithContentsOfFile:processNamePath encoding:NSUTF8StringEncoding error:&error];
    
    if (error) {
       
        return;
    }
    
    if (processName && processName.length > 0) {
        processName = [processName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [self setTargetProcessName:processName];
    } else {
       
    }
}

- (void)setTargetProcessName:(NSString *)processName {
    
    if (!processName || processName.length == 0) {
       
        _targetProcessName = nil;
        _memoryUtils = nil;
        [self stopProcessMonitoring];
        [self removeModMenu];
        return;
    }
    
    _targetProcessName = processName;
    
   
    _memoryUtils = [[MemoryUtils alloc] initWithProcessName:processName];
    
  
    
  
    if (_memoryUtils && _memoryUtils.isValid && self.isViewLoaded) {
       
        [self createModMenu];
        [self startProcessMonitoring];
    } else {
       
       
       
    }
}

- (void)startProcessMonitoring {
    if (_processCheckTimer) {
        [_processCheckTimer invalidate];
    }
    

    _processCheckTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 
                                                          target:self 
                                                        selector:@selector(checkProcessStatus) 
                                                        userInfo:nil 
                                                         repeats:YES];
}

- (void)stopProcessMonitoring {
    if (_processCheckTimer) {
        [_processCheckTimer invalidate];
        _processCheckTimer = nil;
    }
}

- (void)checkProcessStatus {
    if (!_targetProcessName || !_memoryUtils) {
       
        [self processNotFound];
        return;
    }
    
  
    

    MemoryUtils *newMemoryUtils = [[MemoryUtils alloc] initWithProcessName:_targetProcessName];
    if (!newMemoryUtils || !newMemoryUtils.isValid) {
       
        [self processNotFound];
    } else {
       
        _memoryUtils = newMemoryUtils;
      
        if (!_menuButton) {
           
            [self createModMenu];
        }
    }
}

- (void)processNotFound {
    [self removeModMenu];
    [self stopProcessMonitoring];
    
 
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showCustomAlert:@"Process Stopped" description:[NSString stringWithFormat:@"Process '%@' is no longer running.", self->_targetProcessName]];
    });
}

- (void)removeModMenu {
    if (_modMenuView) {
        [_modMenuView removeFromSuperview];
        _modMenuView = nil;
    }
    if (_menuButton) {
        [_menuButton removeFromSuperview];
        _menuButton = nil;
    }
    _menuVisible = NO;
}

- (void)createModMenu {

    if (_menuButton) {
       
        return;
    }
    
  
    
   
    CGFloat buttonSize = 50.0;
    _menuButton = [[UIView alloc] initWithFrame:CGRectMake(50, 100, buttonSize, buttonSize)];
    _menuButton.backgroundColor = [UIColor clearColor];
    _menuButton.layer.cornerRadius = 8.0; 
    _menuButton.userInteractionEnabled = YES;
    

    UIImageView *iconImageView = [[UIImageView alloc] initWithFrame:_menuButton.bounds];
    iconImageView.image = [UIImage imageNamed:@"icon.png"];
    iconImageView.contentMode = UIViewContentModeScaleAspectFit;
    iconImageView.layer.cornerRadius = 8.0; 
    iconImageView.clipsToBounds = YES;
    iconImageView.tag = 100; 
    [_menuButton addSubview:iconImageView];
    
    _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(menuButtonPanned:)];
    _panGestureRecognizer.delegate = self;
    _panGestureRecognizer.maximumNumberOfTouches = 1;
    _panGestureRecognizer.minimumNumberOfTouches = 1;
    [_menuButton addGestureRecognizer:_panGestureRecognizer];
    
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(menuButtonTapped:)];
    _tapGestureRecognizer.delegate = self;
    _tapGestureRecognizer.numberOfTapsRequired = 1;
    _tapGestureRecognizer.numberOfTouchesRequired = 1;
    [_menuButton addGestureRecognizer:_tapGestureRecognizer];
    
    [self loadMenuPosition];
    

    _modMenuView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 700, 410)];
    _modMenuView.backgroundColor = [UIColor clearColor]; 
    _modMenuView.layer.cornerRadius = 10.0;
    _modMenuView.hidden = YES;
    _modMenuView.userInteractionEnabled = YES; 
    _modMenuView.tag = 1000; 
    
   
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterial];
    UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    blurView.frame = _modMenuView.bounds;
    blurView.layer.cornerRadius = 10.0;
    blurView.clipsToBounds = YES;
    [_modMenuView addSubview:blurView];
   
    UIView *blackOverlay = [[UIView alloc] initWithFrame:_modMenuView.bounds];
    blackOverlay.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.3]; 
    blackOverlay.layer.cornerRadius = 10.0;
    blackOverlay.clipsToBounds = YES;
    [_modMenuView addSubview:blackOverlay];
    
   
    [self createMenuHeader];
    
   
    _mainScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 40, 700, 330)]; 
    _mainScrollView.backgroundColor = [UIColor clearColor];
    _mainScrollView.layer.cornerRadius = 5.0;
    _mainScrollView.showsVerticalScrollIndicator = YES;
    _mainScrollView.showsHorizontalScrollIndicator = NO;
    _mainScrollView.userInteractionEnabled = YES;
    _mainScrollView.delaysContentTouches = NO; 
    _mainScrollView.canCancelContentTouches = YES; 
    _mainScrollView.delegate = self; 
    [_modMenuView addSubview:_mainScrollView];
    

    UIBlurEffect *scrollBlurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterial];
    UIVisualEffectView *scrollBlurView = [[UIVisualEffectView alloc] initWithEffect:scrollBlurEffect];
    scrollBlurView.frame = _mainScrollView.bounds;
    scrollBlurView.layer.cornerRadius = 5.0;
    scrollBlurView.clipsToBounds = YES;
    [_mainScrollView insertSubview:scrollBlurView atIndex:0]; 
    
   
    UIView *scrollBlackOverlay = [[UIView alloc] initWithFrame:_mainScrollView.bounds];
    scrollBlackOverlay.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.3]; 
    scrollBlackOverlay.layer.cornerRadius = 5.0;
    scrollBlackOverlay.clipsToBounds = YES;
    [_mainScrollView insertSubview:scrollBlackOverlay atIndex:1]; 
 
    [self createMenuOptions];
    

    UIView *headerSeparatorLine = [[UIView alloc] initWithFrame:CGRectMake(15, 43, 670, 3)]; 
    UIColor *headerLineColor = [UIColor colorWithRed:15.0/255.0 green:82.0/255.0 blue:186.0/255.0 alpha:1.0];
    headerSeparatorLine.backgroundColor = headerLineColor;
    headerSeparatorLine.layer.cornerRadius = 1.5;
    headerSeparatorLine.tag = 521;
    
  
    headerSeparatorLine.layer.shadowColor = headerLineColor.CGColor;
    headerSeparatorLine.layer.shadowOffset = CGSizeZero;
    headerSeparatorLine.layer.shadowRadius = 4.0;
    headerSeparatorLine.layer.shadowOpacity = 0.8;
    
    [_modMenuView addSubview:headerSeparatorLine];
    
   
    [self createMenuFooter];
    
 
    UIView *footerSeparatorLine = [[UIView alloc] initWithFrame:CGRectMake(15, 375, 670, 3)]; 
    UIColor *footerLineColor = [UIColor colorWithRed:15.0/255.0 green:82.0/255.0 blue:186.0/255.0 alpha:1.0];
    footerSeparatorLine.backgroundColor = footerLineColor;
    footerSeparatorLine.layer.cornerRadius = 1.5;
    footerSeparatorLine.tag = 520; 
    
  
    footerSeparatorLine.layer.shadowColor = footerLineColor.CGColor;
    footerSeparatorLine.layer.shadowOffset = CGSizeZero;
    footerSeparatorLine.layer.shadowRadius = 4.0;
    footerSeparatorLine.layer.shadowOpacity = 0.8;
    
    [_modMenuView addSubview:footerSeparatorLine];
    
 
    [self.view addSubview:_menuButton];
    [self.view addSubview:_modMenuView];
    
   
}

- (void)createMenuHeader {
  
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 700, 40)];
    headerView.backgroundColor = [UIColor clearColor]; 
    headerView.layer.cornerRadius = 10.0;
    headerView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    headerView.userInteractionEnabled = YES; 
    headerView.tag = 300; 
    
    
    UIBlurEffect *headerBlurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterial];
    UIVisualEffectView *headerBlurView = [[UIVisualEffectView alloc] initWithEffect:headerBlurEffect];
    headerBlurView.frame = headerView.bounds;
    headerBlurView.layer.cornerRadius = 10.0;
    headerBlurView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    headerBlurView.clipsToBounds = YES;
    [headerView insertSubview:headerBlurView atIndex:0]; 
    
 
    UIView *headerBlackOverlay = [[UIView alloc] initWithFrame:headerView.bounds];
    headerBlackOverlay.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.3]; 
    headerBlackOverlay.layer.cornerRadius = 10.0;
    headerBlackOverlay.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    headerBlackOverlay.clipsToBounds = YES;
    [headerView insertSubview:headerBlackOverlay atIndex:1]; 
    

    UILabel *headerTitle = [[UILabel alloc] initWithFrame:CGRectMake(15, 2, 200, 18)];
    headerTitle.text = @"SAPPHIRE CHEATS";
    headerTitle.textColor = [UIColor colorWithRed:0.7 green:0.7 blue:0.7 alpha:1.0];
    headerTitle.font = [UIFont fontWithName:@"Semakin" size:16];
    headerTitle.textAlignment = NSTextAlignmentLeft;
    headerTitle.tag = 302; 
    [headerView addSubview:headerTitle];
    
    // Add "Made By AlexZero" text below the main title
    UILabel *madeByLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 20, 200, 15)];
    madeByLabel.text = @"Made By AlexZero";
    madeByLabel.textColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    madeByLabel.font = [UIFont fontWithName:@"Semakin" size:10];
    madeByLabel.textAlignment = NSTextAlignmentLeft;
    madeByLabel.tag = 303; 
    [headerView addSubview:madeByLabel];
    
   
    UIView *customSegmentedControl = [[UIView alloc] initWithFrame:CGRectMake(220, 10, 400, 20)]; 
    customSegmentedControl.backgroundColor = [UIColor clearColor]; 
    customSegmentedControl.layer.cornerRadius = 5.0;
    customSegmentedControl.userInteractionEnabled = YES;
    customSegmentedControl.tag = 400; 
    

    NSArray *segmentTitles = @[@"PREPARE", @"DRAWNING", @"MENU"];
    NSArray *symbolNames = @[@"eye.fill", @"scope", @"bolt.fill"];
    CGFloat segmentWidth = 400.0 / 3.0; 
    
    for (int i = 0; i < 3; i++) { 
        UIButton *segmentButton = [UIButton buttonWithType:UIButtonTypeCustom];
        segmentButton.frame = CGRectMake(i * segmentWidth, 0, segmentWidth, 20); 
        segmentButton.tag = i;
        segmentButton.backgroundColor = [UIColor clearColor];
        segmentButton.layer.cornerRadius = 5.0;
        segmentButton.userInteractionEnabled = YES;
        segmentButton.exclusiveTouch = YES; 
        
     
        UIImageConfiguration *symbolConfig = [UIImageSymbolConfiguration configurationWithPointSize:12 weight:UIImageSymbolWeightMedium];
        UIImage *symbolImage = [[UIImage systemImageNamed:symbolNames[i] withConfiguration:symbolConfig] imageWithTintColor:[UIColor colorWithRed:0.7 green:0.7 blue:0.7 alpha:1.0]];
        

        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] init];
        
        
        NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
        attachment.image = symbolImage;
        attachment.bounds = CGRectMake(0, 1, 14, 14); 
        
        NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
        [attributedString appendAttributedString:attachmentString];
        
      
        NSAttributedString *spaceString = [[NSAttributedString alloc] initWithString:@" "];
        [attributedString appendAttributedString:spaceString];
        
      
        NSAttributedString *textString = [[NSAttributedString alloc] initWithString:segmentTitles[i] attributes:@{
            NSFontAttributeName: [UIFont fontWithName:@"Semakin" size:12],
            NSForegroundColorAttributeName: [UIColor colorWithRed:0.7 green:0.7 blue:0.7 alpha:1.0],
            NSBaselineOffsetAttributeName: @(4) 
        }];
        [attributedString appendAttributedString:textString];
        
      
        [segmentButton setAttributedTitle:attributedString forState:UIControlStateNormal];
        

        NSMutableAttributedString *selectedAttributedString = [[NSMutableAttributedString alloc] init];
        
     
        NSTextAttachment *selectedAttachment = [[NSTextAttachment alloc] init];
        selectedAttachment.image = [[UIImage systemImageNamed:symbolNames[i] withConfiguration:symbolConfig] imageWithTintColor:[UIColor colorWithRed:15.0/255.0 green:82.0/255.0 blue:186.0/255.0 alpha:1.0]];
        selectedAttachment.bounds = CGRectMake(0, 1, 14, 14); 
        
        NSAttributedString *selectedAttachmentString = [NSAttributedString attributedStringWithAttachment:selectedAttachment];
        [selectedAttributedString appendAttributedString:selectedAttachmentString];
        
       
        [selectedAttributedString appendAttributedString:spaceString];
        
   
        NSShadow *textShadow = [[NSShadow alloc] init];
        textShadow.shadowColor = [UIColor colorWithRed:15.0/255.0 green:82.0/255.0 blue:186.0/255.0 alpha:1.0];
        textShadow.shadowOffset = CGSizeZero;
        textShadow.shadowBlurRadius = 4.0; 
        
        NSAttributedString *selectedTextString = [[NSAttributedString alloc] initWithString:segmentTitles[i] attributes:@{
            NSFontAttributeName: [UIFont fontWithName:@"Semakin" size:12],
            NSForegroundColorAttributeName: [UIColor colorWithRed:15.0/255.0 green:82.0/255.0 blue:186.0/255.0 alpha:1.0],
            NSShadowAttributeName: textShadow,
            NSBaselineOffsetAttributeName: @(4) 
        }];
        [selectedAttributedString appendAttributedString:selectedTextString];
        
       
        [segmentButton setAttributedTitle:selectedAttributedString forState:UIControlStateSelected];
        

        UITapGestureRecognizer *buttonTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(customSegmentButtonTapped:)];
        buttonTapGesture.delegate = self;
        buttonTapGesture.numberOfTapsRequired = 1;
        buttonTapGesture.numberOfTouchesRequired = 1;
        [segmentButton addGestureRecognizer:buttonTapGesture];
        
      
        if (i == 0) {
            segmentButton.selected = YES;
        }
        
        [customSegmentedControl addSubview:segmentButton];
    }
    
    
    UITapGestureRecognizer *segmentTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(segmentTapped:)];
    segmentTapGesture.delegate = self;
    segmentTapGesture.numberOfTapsRequired = 1;
    segmentTapGesture.numberOfTouchesRequired = 1;
    [customSegmentedControl addGestureRecognizer:segmentTapGesture];
    
  
    UIPanGestureRecognizer *headerPanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(menuHeaderPanned:)];
    headerPanGesture.delegate = self; 
    headerPanGesture.maximumNumberOfTouches = 1;
    headerPanGesture.minimumNumberOfTouches = 1;
    [headerView addGestureRecognizer:headerPanGesture];
    
   
    [headerView addSubview:customSegmentedControl];
    
 
    UIColor *separatorColor = [UIColor colorWithRed:15.0/255.0 green:82.0/255.0 blue:186.0/255.0 alpha:1.0];
    
   
    CGFloat centerY = 10 + (20 - 12) / 2; 
    
   
    UIView *separator1 = [[UIView alloc] initWithFrame:CGRectMake(220 + segmentWidth, centerY, 3, 12)];
    separator1.backgroundColor = separatorColor;
    separator1.layer.cornerRadius = 1.5;
    separator1.tag = 500; 
    

    separator1.layer.shadowColor = separatorColor.CGColor;
    separator1.layer.shadowOffset = CGSizeZero;
    separator1.layer.shadowRadius = 4.0;
    separator1.layer.shadowOpacity = 0.8;
    
    [headerView addSubview:separator1];
    
  
    UIView *separator2 = [[UIView alloc] initWithFrame:CGRectMake(220 + segmentWidth * 2, centerY, 3, 12)];
    separator2.backgroundColor = separatorColor;
    separator2.layer.cornerRadius = 1.5;
    separator2.tag = 501; 
    
   
    separator2.layer.shadowColor = separatorColor.CGColor;
    separator2.layer.shadowOffset = CGSizeZero;
    separator2.layer.shadowRadius = 4.0;
    separator2.layer.shadowOpacity = 0.8;
    
    [headerView addSubview:separator2];
    
    
    UIView *closeButtonView = [[UIView alloc] initWithFrame:CGRectMake(660, (40 - 25) / 2, 25, 25)]; 
    closeButtonView.backgroundColor = [UIColor clearColor];
    closeButtonView.layer.cornerRadius = 12.5;
    closeButtonView.layer.masksToBounds = YES;
    closeButtonView.userInteractionEnabled = YES;
    closeButtonView.tag = 200; 
    
 
    UIImageConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:18 weight:UIImageSymbolWeightBold];
    UIImage *closeImage = [UIImage systemImageNamed:@"xmark.circle.fill" withConfiguration:configuration];
    
    UIImageView *closeImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 25, 25)];
    closeImageView.image = closeImage;
    closeImageView.contentMode = UIViewContentModeCenter;
    closeImageView.tintColor = [UIColor colorWithRed:0.7 green:0.7 blue:0.7 alpha:1.0]; 
    
    
    UIColor *glowColor = [UIColor colorWithRed:0.7 green:0.7 blue:0.7 alpha:1.0];
    closeImageView.layer.shadowColor = glowColor.CGColor;
    closeImageView.layer.shadowOffset = CGSizeZero;
    closeImageView.layer.shadowRadius = 4.0;
    closeImageView.layer.shadowOpacity = 0.8;
    
    [closeButtonView addSubview:closeImageView];
    
  
    UITapGestureRecognizer *closeTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeMenuButtonTapped:)];
    closeTapGesture.delegate = self;
    closeTapGesture.numberOfTapsRequired = 1;
    closeTapGesture.numberOfTouchesRequired = 1;
    [closeButtonView addGestureRecognizer:closeTapGesture];
    
    [headerView addSubview:closeButtonView];
    
    [_modMenuView addSubview:headerView];
    
    
}

- (void)createMenuFooter {
   
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 380, 700, 30)];
    footerView.backgroundColor = [UIColor clearColor]; 
    footerView.layer.cornerRadius = 10.0;
    footerView.layer.maskedCorners = kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner;
    footerView.tag = 370; 
    
    
    UIBlurEffect *footerBlurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterial];
    UIVisualEffectView *footerBlurView = [[UIVisualEffectView alloc] initWithEffect:footerBlurEffect];
    footerBlurView.frame = footerView.bounds;
    footerBlurView.layer.cornerRadius = 10.0;
    footerBlurView.layer.maskedCorners = kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner;
    footerBlurView.clipsToBounds = YES;
    [footerView insertSubview:footerBlurView atIndex:0]; 
    

    UIView *footerBlackOverlay = [[UIView alloc] initWithFrame:footerView.bounds];
    footerBlackOverlay.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.3]; 
    footerBlackOverlay.layer.cornerRadius = 10.0;
    footerBlackOverlay.layer.maskedCorners = kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner;
    footerBlackOverlay.clipsToBounds = YES;
    [footerView insertSubview:footerBlackOverlay atIndex:1]; 
    

    UILabel *leftFooterText = [[UILabel alloc] initWithFrame:CGRectMake(15, 5, 100, 20)];
    leftFooterText.text = @"EXTERNAL";
    leftFooterText.textColor = [UIColor colorWithRed:0.7 green:0.7 blue:0.7 alpha:1.0];
    leftFooterText.font = [UIFont fontWithName:@"Semakin" size:12];
    leftFooterText.textAlignment = NSTextAlignmentLeft;
    [footerView addSubview:leftFooterText];
    
   
    UIView *leftSeparator = [[UIView alloc] initWithFrame:CGRectMake(125, 8, 3, 14)];
    UIColor *separatorColor = [UIColor colorWithRed:15.0/255.0 green:82.0/255.0 blue:186.0/255.0 alpha:1.0];
    leftSeparator.backgroundColor = separatorColor;
    leftSeparator.layer.cornerRadius = 1.5; 
    leftSeparator.tag = 510;
    

    leftSeparator.layer.shadowColor = separatorColor.CGColor;
    leftSeparator.layer.shadowOffset = CGSizeZero;
    leftSeparator.layer.shadowRadius = 4.0;
    leftSeparator.layer.shadowOpacity = 0.8;
    
    [footerView addSubview:leftSeparator];
    

    UILabel *centerFooterText = [[UILabel alloc] initWithFrame:CGRectMake(140, 5, 420, 20)]; 
    centerFooterText.text = @"T.ME/CRUEXGG";
    centerFooterText.textColor = [UIColor colorWithRed:0.7 green:0.7 blue:0.7 alpha:1.0];
    centerFooterText.font = [UIFont fontWithName:@"Semakin" size:12];
    centerFooterText.textAlignment = NSTextAlignmentCenter;
    [footerView addSubview:centerFooterText];
    
 
    UIView *rightSeparator = [[UIView alloc] initWithFrame:CGRectMake(570, 8, 3, 14)]; 
    rightSeparator.backgroundColor = separatorColor;
    rightSeparator.layer.cornerRadius = 1.5; 
    rightSeparator.tag = 511; 
    

    rightSeparator.layer.shadowColor = separatorColor.CGColor;
    rightSeparator.layer.shadowOffset = CGSizeZero;
    rightSeparator.layer.shadowRadius = 4.0;
    rightSeparator.layer.shadowOpacity = 0.8;
    
    [footerView addSubview:rightSeparator];
    
   
    UILabel *rightFooterText = [[UILabel alloc] initWithFrame:CGRectMake(585, 5, 100, 20)]; 
    rightFooterText.text = @"v1.02";
    rightFooterText.textColor = [UIColor colorWithRed:0.7 green:0.7 blue:0.7 alpha:1.0];
    rightFooterText.font = [UIFont fontWithName:@"Semakin" size:12];
    rightFooterText.textAlignment = NSTextAlignmentRight;
    [footerView addSubview:rightFooterText];
    
    [_modMenuView addSubview:footerView];
}

- (void)createMenuOptions {

    _currentSegmentIndex = 0;
    
   
    _currentRGBColor = [UIColor colorWithRed:15.0/255.0 green:82.0/255.0 blue:186.0/255.0 alpha:1.0];
    
 
    _rgbThemeEnabled = NO;
    _glowEnabled = YES; 
    
    
    [self updateMenuViewForSegment:_currentSegmentIndex];
}

- (void)updateMenuViewForSegment:(NSInteger)segmentIndex {

    for (UIView *subview in _mainScrollView.subviews) {
        [subview removeFromSuperview];
    }
    
   
    NSArray *functions = [self getFunctionsForSegment:segmentIndex];
    

    UIColor *currentColor = _currentRGBColor ?: [UIColor colorWithRed:15.0/255.0 green:82.0/255.0 blue:186.0/255.0 alpha:1.0];
    
    CGFloat buttonHeight = 30.0;
    CGFloat spacing = 5.0;
    CGFloat startY = 10.0; 
    CGFloat itemWidth = 330.0;
    int itemsPerRow = 2; 
    
 
    for (int i = 0; i < functions.count; i++) {
        NSDictionary *item = functions[i];
        NSString *type = item[@"type"];
        
     
        int row = i / itemsPerRow;
        int col = i % itemsPerRow;
        CGFloat xPos = 10 + col * (itemWidth + 10); 
        CGFloat yPos = startY + row * (buttonHeight + spacing);
        
      
        UIView *menuItemView = [[UIView alloc] initWithFrame:CGRectMake(xPos, yPos, itemWidth, buttonHeight)];
        menuItemView.backgroundColor = [UIColor clearColor]; 
        menuItemView.layer.cornerRadius = 5.0;
        
        
        UIBlurEffect *itemBlurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterial];
        UIVisualEffectView *itemBlurView = [[UIVisualEffectView alloc] initWithEffect:itemBlurEffect];
        itemBlurView.frame = menuItemView.bounds;
        itemBlurView.layer.cornerRadius = 5.0;
        itemBlurView.clipsToBounds = YES;
        [menuItemView insertSubview:itemBlurView atIndex:0]; 
        
     
        UIView *itemBlackOverlay = [[UIView alloc] initWithFrame:menuItemView.bounds];
        itemBlackOverlay.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.3]; 
        itemBlackOverlay.layer.cornerRadius = 5.0;
        itemBlackOverlay.clipsToBounds = YES;
        [menuItemView insertSubview:itemBlackOverlay atIndex:1]; 
        

        menuItemView.layer.shadowColor = [UIColor blackColor].CGColor;
        menuItemView.layer.shadowOffset = CGSizeMake(0, 2);
        menuItemView.layer.shadowRadius = 4.0;
        menuItemView.layer.shadowOpacity = 0.3;
        menuItemView.layer.masksToBounds = NO; 
        
      
        menuItemView.layer.borderWidth = 0.0; 
        
        menuItemView.userInteractionEnabled = YES;
        menuItemView.tag = i;
        

        UILabel *itemLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, 150, buttonHeight)];
        itemLabel.text = item[@"title"];
        itemLabel.textColor = [UIColor colorWithRed:0.7 green:0.7 blue:0.7 alpha:1.0];
        itemLabel.textAlignment = NSTextAlignmentLeft;
        itemLabel.font = [UIFont fontWithName:@"Semakin" size:12]; 
        [menuItemView addSubview:itemLabel];
        
        
        if ([type isEqualToString:@"slider"]) {
            CGFloat defaultValue = [item[@"default"] floatValue];
            NSString *valueText;
            if ([item[@"title"] isEqualToString:@"SVG Line Thickness"]) {
                valueText = [NSString stringWithFormat:@"%.2f", defaultValue];
            } else {
                valueText = [NSString stringWithFormat:@"%.0f", defaultValue];
            }
            
     
            UIFont *valueFont = [UIFont fontWithName:@"Semakin" size:10];
            CGSize textSize = [valueText sizeWithAttributes:@{NSFontAttributeName: valueFont}];
            CGFloat valueLabelWidth = textSize.width + 10; 
            
         
            CGFloat valueLabelX = 200 - valueLabelWidth - 5; 
            UILabel *valueLabel = [[UILabel alloc] initWithFrame:CGRectMake(valueLabelX, 0, valueLabelWidth, buttonHeight)];
            valueLabel.text = valueText;
            valueLabel.textColor = currentColor; 
            valueLabel.textAlignment = NSTextAlignmentRight;
            valueLabel.font = valueFont;
            valueLabel.tag = 100; 
            [menuItemView addSubview:valueLabel];
        }
        
        if ([type isEqualToString:@"toggle"]) {
          
            UISwitch *toggleSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(itemWidth - 50, (buttonHeight - 31) / 2, 51, 31)];  
            toggleSwitch.tag = i;
            toggleSwitch.onTintColor = [currentColor colorWithAlphaComponent:0.8];
            toggleSwitch.tintColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.8];
            toggleSwitch.userInteractionEnabled = YES;
            
           
            toggleSwitch.transform = CGAffineTransformMakeScale(0.8, 0.8);
            
            [toggleSwitch addTarget:self action:@selector(toggleSwitchChanged:) forControlEvents:UIControlEventValueChanged];
            [menuItemView addSubview:toggleSwitch];
            
        } else if ([type isEqualToString:@"button"]) {
         
            UIView *buttonContainer = [[UIView alloc] initWithFrame:CGRectMake(240, (buttonHeight - 25) / 2, 80, 25)];
            buttonContainer.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.8];
            buttonContainer.layer.cornerRadius = 5.0;
            buttonContainer.userInteractionEnabled = YES;
            buttonContainer.tag = i;
            
          
            buttonContainer.layer.borderWidth = 1.0;
            buttonContainer.layer.borderColor = currentColor.CGColor;
            buttonContainer.layer.shadowColor = currentColor.CGColor; 
            buttonContainer.layer.shadowOffset = CGSizeZero;
            buttonContainer.layer.shadowRadius = 4.0;
            buttonContainer.layer.shadowOpacity = 0.8;
            
          
            UILabel *buttonLabel = [[UILabel alloc] initWithFrame:buttonContainer.bounds];
            
           
            if ([item[@"title"] isEqualToString:@"Red Circle"]) {
                buttonLabel.text = _drawingManager.circleVisible ? @"DISABLE" : @"ENABLE";
            } else if ([item[@"title"] isEqualToString:@"SVG Drawing"]) {
                buttonLabel.text = _drawingManager.svgVisible ? @"DISABLE" : @"ENABLE";
            } else if ([item[@"title"] isEqualToString:@"RGB Theme"]) {
                buttonLabel.text = _rgbThemeEnabled ? @"DISABLE" : @"ENABLE";
            } else {
                buttonLabel.text = @"ENABLE";
            }
            
            buttonLabel.textColor = [UIColor whiteColor];
            buttonLabel.font = [UIFont fontWithName:@"Semakin" size:10];
            buttonLabel.textAlignment = NSTextAlignmentCenter;
            buttonLabel.tag = 2000 + i; 
            [buttonContainer addSubview:buttonLabel];
            
           
            UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(buttonTapped:)];
            tapGesture.delegate = self;
            tapGesture.numberOfTapsRequired = 1;
            tapGesture.numberOfTouchesRequired = 1;
            [buttonContainer addGestureRecognizer:tapGesture];
            
            [menuItemView addSubview:buttonContainer];
            
        } else if ([type isEqualToString:@"slider"]) {
           
            UIView *sliderContainer = [[UIView alloc] initWithFrame:CGRectMake(200, (buttonHeight - 25) / 2, 100, 25)];
            sliderContainer.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.8];
            sliderContainer.layer.cornerRadius = 5.0;
            sliderContainer.userInteractionEnabled = YES;
            sliderContainer.tag = i;
            
         
            UIView *trackView = [[UIView alloc] initWithFrame:CGRectMake(5, 8, 90, 6)]; 
            trackView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.1];
            trackView.layer.cornerRadius = 3.0;
            [sliderContainer addSubview:trackView];
            
          
            CGFloat defaultValue = [item[@"default"] floatValue];
            CGFloat minValue = [item[@"min"] floatValue];
            CGFloat maxValue = [item[@"max"] floatValue];
            CGFloat percentage = ((defaultValue - minValue) / (maxValue - minValue)) * 100.0;
            CGFloat progressWidth = (percentage / 100.0) * 90.0; 
            CGFloat thumbX = 5 + progressWidth;
            
           
            UIView *progressView = [[UIView alloc] initWithFrame:CGRectMake(5, 8, progressWidth, 6)];
            progressView.backgroundColor = [currentColor colorWithAlphaComponent:0.2]; 
            progressView.layer.cornerRadius = 3.0;
            progressView.tag = 1000;
            [sliderContainer addSubview:progressView];
            
          
            CGFloat thumbSize = 20.0; 
            UIView *thumbView = [[UIView alloc] initWithFrame:CGRectMake(thumbX - thumbSize/2, (25 - thumbSize) / 2, thumbSize, thumbSize)];
            thumbView.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
            thumbView.layer.cornerRadius = thumbSize / 2;
            
         
            thumbView.layer.shadowColor = currentColor.CGColor; 
            thumbView.layer.shadowOffset = CGSizeZero;
            thumbView.layer.shadowRadius = 4.0;
            thumbView.layer.shadowOpacity = 0.8;
            
          
            thumbView.layer.borderWidth = 1.0;
            thumbView.layer.borderColor = currentColor.CGColor; 
            
            thumbView.tag = 1001;
            [sliderContainer addSubview:thumbView];
            
          
            UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(customSliderPanned:)];
            panGesture.delegate = self;
            panGesture.maximumNumberOfTouches = 1;
            panGesture.minimumNumberOfTouches = 1;
            [sliderContainer addGestureRecognizer:panGesture];
            
            [menuItemView addSubview:sliderContainer];
            
         
            UIView *resetButton = [[UIView alloc] initWithFrame:CGRectMake(305, (buttonHeight - 20) / 2, 20, 20)];
            resetButton.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.8]; 
            resetButton.layer.cornerRadius = 10.0;
            resetButton.userInteractionEnabled = YES;
            resetButton.tag = 3000 + i; 
            
           
            UIImageConfiguration *resetConfig = [UIImageSymbolConfiguration configurationWithPointSize:12 weight:UIImageSymbolWeightMedium];
            UIImage *resetImage = [UIImage systemImageNamed:@"arrow.clockwise" withConfiguration:resetConfig];
            
            UIImageView *resetImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
            resetImageView.image = resetImage;
            resetImageView.contentMode = UIViewContentModeCenter;
            resetImageView.tintColor = currentColor; 
            
          
            resetImageView.layer.shadowColor = currentColor.CGColor; 
            resetImageView.layer.shadowOffset = CGSizeZero;
            resetImageView.layer.shadowRadius = 4.0;
            resetImageView.layer.shadowOpacity = 0.8;
            
            [resetButton addSubview:resetImageView];
            
           
            UITapGestureRecognizer *resetTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resetSliderTapped:)];
            resetTapGesture.delegate = self;
            resetTapGesture.numberOfTapsRequired = 1;
            resetTapGesture.numberOfTouchesRequired = 1;
            [resetButton addGestureRecognizer:resetTapGesture];
            
            [menuItemView addSubview:resetButton];
            
        } else if ([type isEqualToString:@"textfield"]) {
            
            UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(200, (buttonHeight - 25) / 2, 100, 25)];
            textField.tag = i;
            textField.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.8];
            textField.textColor = [UIColor whiteColor];
            textField.font = [UIFont fontWithName:@"Semakin" size:10]; 
            textField.placeholder = @"Enter text...";
            textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Enter text..." 
                                                                              attributes:@{NSForegroundColorAttributeName: [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:0.8]}];
            textField.layer.cornerRadius = 5.0;
            textField.layer.borderWidth = 1.0;
            
      
            textField.layer.borderColor = currentColor.CGColor; 
            textField.layer.shadowColor = currentColor.CGColor; 
            textField.layer.shadowOffset = CGSizeZero;
            textField.layer.shadowRadius = 4.0;
            textField.layer.shadowOpacity = 0.8;
            
       
            UIView *leftPaddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 8, 25)];
            textField.leftView = leftPaddingView;
            textField.leftViewMode = UITextFieldViewModeAlways;
            
            textField.userInteractionEnabled = YES;
            textField.delegate = self;
            textField.returnKeyType = UIReturnKeyDone;
            [textField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
            
          
            UITapGestureRecognizer *textFieldTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(textFieldTapped:)];
            textFieldTapGesture.delegate = self;
            textFieldTapGesture.numberOfTapsRequired = 1;
            textFieldTapGesture.numberOfTouchesRequired = 1;
            [textField addGestureRecognizer:textFieldTapGesture];
            
            [menuItemView addSubview:textField];
            
         
            UIView *resetButton = [[UIView alloc] initWithFrame:CGRectMake(305, (buttonHeight - 20) / 2, 20, 20)]; 
            resetButton.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.8]; 
            resetButton.layer.cornerRadius = 10.0;
            resetButton.userInteractionEnabled = YES;
            resetButton.tag = 4000 + i; 
            
          
            UIImageConfiguration *resetConfig = [UIImageSymbolConfiguration configurationWithPointSize:12 weight:UIImageSymbolWeightMedium];
            UIImage *resetImage = [UIImage systemImageNamed:@"arrow.clockwise" withConfiguration:resetConfig];
            
            UIImageView *resetImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
            resetImageView.image = resetImage;
            resetImageView.contentMode = UIViewContentModeCenter;
            resetImageView.tintColor = currentColor; 
            
        
            resetImageView.layer.shadowColor = currentColor.CGColor; 
            resetImageView.layer.shadowOffset = CGSizeZero;
            resetImageView.layer.shadowRadius = 4.0;
            resetImageView.layer.shadowOpacity = 0.8;
            
            [resetButton addSubview:resetImageView];
            
        
            UITapGestureRecognizer *resetTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resetTextFieldTapped:)];
            resetTapGesture.delegate = self;
            resetTapGesture.numberOfTapsRequired = 1;
            resetTapGesture.numberOfTouchesRequired = 1;
            [resetButton addGestureRecognizer:resetTapGesture];
            
            [menuItemView addSubview:resetButton];
        }
        
        [_mainScrollView addSubview:menuItemView];
    }
    
    
    CGFloat totalHeight = ((functions.count + itemsPerRow - 1) / itemsPerRow) * (buttonHeight + spacing) + startY + 10;
    _mainScrollView.contentSize = CGSizeMake(_mainScrollView.frame.size.width, totalHeight);
}

- (NSArray *)getFunctionsForSegment:(NSInteger)segmentIndex {
    switch (segmentIndex) {
        case 0: 
            return @[
                @{@"title": @"Table Size", @"type": @"slider", @"min": @"1200", @"max": @"2000", @"default": @"1492"},
                @{@"title": @"Table Position Y", @"type": @"slider", @"min": @"0", @"max": @"1000", @"default": @"500"},
                @{@"title": @"Table Position X", @"type": @"slider", @"min": @"0", @"max": @"1000", @"default": @"500"},
                @{@"title": @"Target Ball Size", @"type": @"slider", @"min": @"20", @"max": @"500", @"default": @"28"}
            ];
            
        case 1: // DRAWNING
            return @[
                @{@"title": @"Draw Mode", @"type": @"button"},
                @{@"title": @"Table Thickness", @"type": @"slider", @"min": @"1", @"max": @"50", @"default": @"2.48"},
                @{@"title": @"Ball Thickness", @"type": @"slider", @"min": @"1", @"max": @"200", @"default": @"10"},
                @{@"title": @"Pocket Lines Size", @"type": @"slider", @"min": @"10", @"max": @"300", @"default": @"258"},
                @{@"title": @"Pocket Lines Alpha", @"type": @"slider", @"min": @"0.1", @"max": @"1.0", @"default": @"0.6"}
            ];
            
        case 2: // MENU
            return @[
                @{@"title": @"RGB Slider", @"type": @"slider", @"min": @"0", @"max": @"360", @"default": @"240"},
                @{@"title": @"RGB Theme", @"type": @"button"},
                @{@"title": @"Scale Menu", @"type": @"slider", @"min": @"0.5", @"max": @"2.0", @"default": @"1.0"}
            ];
            
        default:
            return @[];
    }
}

- (void)toggleSwitchChanged:(UISwitch *)sender {
   
    NSArray *functions = [self getFunctionsForSegment:_currentSegmentIndex];
    if (sender.tag >= 0 && sender.tag < functions.count) {
        NSDictionary *item = functions[sender.tag];
        NSString *title = item[@"title"];
        
       
        if ([title isEqualToString:@"RGB Theme"]) {
            _rgbThemeEnabled = sender.isOn;
            NSString *status = sender.isOn ? @"enabled" : @"disabled";
            [self startRGBCycle:sender.isOn];
            [self showCustomAlert:@"RGB Theme" description:[NSString stringWithFormat:@"RGB cycle theme has been %@!", status]];
        } else if ([title isEqualToString:@"Drawing Mode"]) {
            NSString *status = sender.isOn ? @"enabled" : @"disabled";
            [self showCustomAlert:@"Drawing Mode" description:[NSString stringWithFormat:@"Drawing mode has been %@!", status]];
        } else if ([title isEqualToString:@"Auto Hide"]) {
            NSString *status = sender.isOn ? @"enabled" : @"disabled";
            [self showCustomAlert:@"Auto Hide" description:[NSString stringWithFormat:@"Auto hide has been %@!", status]];
        } else if ([title isEqualToString:@"Debug Mode"]) {
            NSString *status = sender.isOn ? @"enabled" : @"disabled";
            [self showCustomAlert:@"Debug Mode" description:[NSString stringWithFormat:@"Debug mode has been %@!", status]];
        } else {
          
            NSString *status = sender.isOn ? @"activated" : @"deactivated";
            [self showCustomAlert:@"Toggle Status" description:[NSString stringWithFormat:@"%@ has been %@!", title, status]];
        }
    }
}


- (void)buttonTapped:(UITapGestureRecognizer *)sender {
    UIView *buttonContainer = sender.view;
    NSInteger buttonIndex = buttonContainer.tag;
    
  
    NSArray *functions = [self getFunctionsForSegment:_currentSegmentIndex];
    if (buttonIndex >= 0 && buttonIndex < functions.count) {
        NSDictionary *item = functions[buttonIndex];
        NSString *title = item[@"title"];
        
        if ([title isEqualToString:@"SVG Drawing"]) {
          
            _drawingManager.svgVisible = !_drawingManager.svgVisible;
            [_drawingManager toggleSVG:_drawingManager.svgVisible];
            
         
            _drawingManager.circleVisible = _drawingManager.svgVisible;
            [_drawingManager toggleCircle:_drawingManager.circleVisible];
            
          
            UILabel *buttonLabel = [buttonContainer viewWithTag:2000 + buttonIndex];
            if (buttonLabel) {
                buttonLabel.text = _drawingManager.svgVisible ? @"DISABLE" : @"ENABLE";
            }
            
         
            NSString *status = _drawingManager.svgVisible ? @"enabled" : @"disabled";
            [self showCustomAlert:@"SVG Drawing" description:[NSString stringWithFormat:@"SVG drawing and red circle have been %@!", status]];
            
           
        } else if ([title isEqualToString:@"Red Circle"]) {
        
            _drawingManager.circleVisible = !_drawingManager.circleVisible;
            [_drawingManager toggleCircle:_drawingManager.circleVisible];
            
        
            UILabel *buttonLabel = [buttonContainer viewWithTag:2000 + buttonIndex];
            if (buttonLabel) {
                buttonLabel.text = _drawingManager.circleVisible ? @"DISABLE" : @"ENABLE";
            }
            
         
            NSString *status = _drawingManager.circleVisible ? @"enabled" : @"disabled";
            [self showCustomAlert:@"Red Circle" description:[NSString stringWithFormat:@"Red circle has been %@!", status]];
            
            
        } else if ([title isEqualToString:@"RGB Theme"]) {
         
            _rgbThemeEnabled = !_rgbThemeEnabled;
            [self startRGBCycle:_rgbThemeEnabled];
            
          
            UILabel *buttonLabel = [buttonContainer viewWithTag:2000 + buttonIndex];
            if (buttonLabel) {
                buttonLabel.text = _rgbThemeEnabled ? @"DISABLE" : @"ENABLE";
            }
            
       
            NSString *status = _rgbThemeEnabled ? @"enabled" : @"disabled";
            [self showCustomAlert:@"RGB Theme" description:[NSString stringWithFormat:@"RGB cycle theme has been %@!", status]];
            
        } else if ([title isEqualToString:@"Disable Glow"]) {
         
            _glowEnabled = !_glowEnabled;
            [self setGlowEnabled:_glowEnabled];
            
       
            UILabel *buttonLabel = [buttonContainer viewWithTag:2000 + buttonIndex];
            if (buttonLabel) {
                buttonLabel.text = _glowEnabled ? @"DISABLE" : @"ENABLE";
            }
            
           
            NSString *status = _glowEnabled ? @"enabled" : @"disabled";
            [self showCustomAlert:@"Glow Effect" description:[NSString stringWithFormat:@"Glow effects have been %@!", status]];
            
        } else if ([title isEqualToString:@"Test Function 2"]) {
            
            [self showCustomAlert:@"Test Function 2" description:@"Test Function 2 has been activated!"];
            
        } else if ([title isEqualToString:@"Draw Mode"]) {
            
            _drawingManager.svgVisible = !_drawingManager.svgVisible;
            [_drawingManager toggleSVG:_drawingManager.svgVisible];
            
        
            _drawingManager.circleVisible = _drawingManager.svgVisible;
            [_drawingManager toggleCircle:_drawingManager.circleVisible];
            

            UILabel *buttonLabel = [buttonContainer viewWithTag:2000 + buttonIndex];
            if (buttonLabel) {
                buttonLabel.text = _drawingManager.svgVisible ? @"DISABLE" : @"ENABLE";
            }
            
           
            NSString *status = _drawingManager.svgVisible ? @"enabled" : @"disabled";
            [self showCustomAlert:@"Draw Mode" description:[NSString stringWithFormat:@"Draw mode and red circle have been %@!", status]];
            
          
        } else {
           
            [self showCustomAlert:title description:[NSString stringWithFormat:@"%@ has been activated!", title]];
        }
    }
    

    [UIView animateWithDuration:0.1 animations:^{
        buttonContainer.alpha = 0.5;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.1 animations:^{
            buttonContainer.alpha = 1.0;
        }];
    }];
}

- (void)customSliderPanned:(UIPanGestureRecognizer *)sender {
    UIView *sliderContainer = sender.view;
    UIView *thumbView = [sliderContainer viewWithTag:1001];
    UIView *progressView = [sliderContainer viewWithTag:1000];
    
    CGPoint translation = [sender translationInView:sliderContainer];
    
    if (sender.state == UIGestureRecognizerStateBegan) {
      
    } else if (sender.state == UIGestureRecognizerStateChanged) {
      
        NSArray *functions = [self getFunctionsForSegment:_currentSegmentIndex];
        NSDictionary *item = functions[sliderContainer.tag];
        NSString *title = item[@"title"];
        
      
        CGFloat sensitivityFactor = 1.0;
        if ([title isEqualToString:@"Table Size"]) {
            sensitivityFactor = 0.1; 
        } else if ([title isEqualToString:@"RGB Color"]) {
            sensitivityFactor = 0.2; 
        }
        
       
        CGPoint adjustedTranslation = CGPointMake(translation.x * sensitivityFactor, translation.y * sensitivityFactor);
        
       
        CGFloat trackWidth = 90.0; 
        CGFloat thumbRadius = 12.0; 
        
       
        CGFloat currentThumbX = thumbView.center.x;
        CGFloat newThumbX = currentThumbX + adjustedTranslation.x;
        
      
        CGFloat minX = 5 + thumbRadius; 
        CGFloat maxX = 5 + trackWidth - thumbRadius; 
        newThumbX = MAX(minX, MIN(maxX, newThumbX));
        
        
        thumbView.center = CGPointMake(newThumbX, thumbView.center.y);
        
       
        CGFloat progressWidth = newThumbX - 5; 
        progressView.frame = CGRectMake(5, 8, progressWidth, 6); 
        
        
        CGFloat percentage = ((newThumbX - minX) / (maxX - minX)) * 100.0;
        
        CGFloat minValue = [item[@"min"] floatValue];
        CGFloat maxValue = [item[@"max"] floatValue];
        CGFloat actualValue = minValue + (percentage / 100.0) * (maxValue - minValue);
        
 
        
      
        UIView *menuItemView = sliderContainer.superview;
        UILabel *valueLabel = [menuItemView viewWithTag:100];
        if (valueLabel) {
            NSString *newValueText;
            if ([title isEqualToString:@"Table Thickness"]) {
                newValueText = [NSString stringWithFormat:@"%.2f", actualValue];
            } else if ([title isEqualToString:@"Pocket Lines Alpha"]) {
                newValueText = [NSString stringWithFormat:@"%.2f", actualValue];
            } else {
                newValueText = [NSString stringWithFormat:@"%.0f", actualValue];
            }
            valueLabel.text = newValueText;
            
           
            UIFont *valueFont = [UIFont fontWithName:@"Semakin" size:10];
            CGSize textSize = [newValueText sizeWithAttributes:@{NSFontAttributeName: valueFont}];
            CGFloat valueLabelWidth = textSize.width + 10; 
            CGFloat valueLabelX = 200 - valueLabelWidth - 5; 
            
            valueLabel.frame = CGRectMake(valueLabelX, valueLabel.frame.origin.y, valueLabelWidth, valueLabel.frame.size.height);
        }
        
     
    
        if ([title isEqualToString:@"RGB Slider"]) {
            [self updateRGBColor:actualValue];
         
            [sender setTranslation:CGPointZero inView:sliderContainer];
            return;
        }
        
   
        if ([title isEqualToString:@"Table Size"]) {
            [_drawingManager updateSVGSize:actualValue];
     
            [sender setTranslation:CGPointZero inView:sliderContainer];
            return;
        }
        
    
        if ([title isEqualToString:@"Table Position Y"]) {
            [_drawingManager updateSVGPositionY:actualValue];
           
            [sender setTranslation:CGPointZero inView:sliderContainer];
            return;
        }
        
 
        if ([title isEqualToString:@"Table Position X"]) {
            [_drawingManager updateSVGPositionX:actualValue];
            
            [sender setTranslation:CGPointZero inView:sliderContainer];
            return;
        }
        
 
        if ([title isEqualToString:@"Target Ball Size"]) {
        
           
            [_drawingManager updateCircleSize:actualValue];
          
        
            [sender setTranslation:CGPointZero inView:sliderContainer];
            return;
        }
        
        
        if ([title isEqualToString:@"Scale Menu"]) {
          
            _modMenuView.transform = CGAffineTransformMakeScale(actualValue, actualValue);
           
            [sender setTranslation:CGPointZero inView:sliderContainer];
            return;
        }
        
      
        if ([title isEqualToString:@"Connection Lines Thickness"]) {
            [_drawingManager updateConnectionLineThickness:actualValue];
            
            [sender setTranslation:CGPointZero inView:sliderContainer];
            return;
        }
        
    
        if ([title isEqualToString:@"Table Thickness"]) {
            [_drawingManager updateSVGLineThickness:actualValue];
           
            [sender setTranslation:CGPointZero inView:sliderContainer];
            return;
        }
        
      
        if ([title isEqualToString:@"Ball Thickness"]) {
            [_drawingManager updateCircleThickness:actualValue];
          
            [sender setTranslation:CGPointZero inView:sliderContainer];
            return;
        }
        

        if ([title isEqualToString:@"Pocket Lines Size"]) {
            [_drawingManager updateConnectionLineThickness:actualValue];
          
            [sender setTranslation:CGPointZero inView:sliderContainer];
            return;
        }
        
        if ([title isEqualToString:@"Pocket Lines Alpha"]) {
            [_drawingManager updateConnectionLineAlpha:actualValue];
          
            [sender setTranslation:CGPointZero inView:sliderContainer];
            return;
        }
        
       
        [self showCustomAlert:@"Custom Slider Value" description:[NSString stringWithFormat:@"%@ value: %.1f", title, actualValue]];
        
        [sender setTranslation:CGPointZero inView:sliderContainer];
    } else if (sender.state == UIGestureRecognizerStateEnded) {
   
    }
}

- (void)textFieldDidChange:(UITextField *)sender {
    // Text field change handling can be implemented here if needed
}

- (void)menuButtonTapped:(UITapGestureRecognizer *)sender {
    _menuVisible = !_menuVisible;
    
   
    UIImageView *iconImageView = [_menuButton viewWithTag:100];
    
    if (_menuVisible) {
      
        _modMenuView.hidden = NO;
        _modMenuView.frame = CGRectMake(_menuButton.frame.origin.x + _menuButton.frame.size.width + 10,
                                       _menuButton.frame.origin.y,
                                       _modMenuView.frame.size.width,
                                       _modMenuView.frame.size.height);
        
       
        _modMenuView.alpha = 0.0;
        [UIView animateWithDuration:0.3 animations:^{
            self->_modMenuView.alpha = 1.0;
            iconImageView.alpha = 0.0;
        }];
    } else {
  
        [UIView animateWithDuration:0.3 animations:^{
            self->_modMenuView.alpha = 0.0;
            iconImageView.alpha = 1.0;
        } completion:^(BOOL finished) {
            self->_modMenuView.hidden = YES;
        }];
    }
}

- (void)menuButtonPanned:(UIPanGestureRecognizer *)sender {
    CGPoint translation = [sender translationInView:self.view];
    
    if (sender.state == UIGestureRecognizerStateBegan) {
        // Store initial position if needed
    } else if (sender.state == UIGestureRecognizerStateChanged) {
        CGPoint newCenter = CGPointMake(_menuButton.center.x + translation.x,
                                       _menuButton.center.y + translation.y);
        
        // Constrain to screen bounds
        CGFloat halfWidth = _menuButton.frame.size.width / 2.0;
        CGFloat halfHeight = _menuButton.frame.size.height / 2.0;
        CGSize screenSize = self.view.bounds.size;
        
        newCenter.x = MAX(halfWidth, MIN(screenSize.width - halfWidth, newCenter.x));
        newCenter.y = MAX(halfHeight, MIN(screenSize.height - halfHeight, newCenter.y));
        
        _menuButton.center = newCenter;
        [sender setTranslation:CGPointZero inView:self.view];
    } else if (sender.state == UIGestureRecognizerStateEnded || sender.state == UIGestureRecognizerStateCancelled) {
        [self saveMenuPosition];
    }
}

- (void)menuItemTapped:(UITapGestureRecognizer *)sender {

}

- (void)menuOptionSelected:(UIButton *)sender {
   
    NSString *title = [sender titleForState:UIControlStateNormal];
 
   
    if (sender.backgroundColor == [UIColor redColor]) {
        sender.backgroundColor = [UIColor blueColor];
        [sender setTitle:[NSString stringWithFormat:@"%@ ✓", title] forState:UIControlStateNormal];
        
      
        [self showCustomAlert:@"Mod Activated" description:[NSString stringWithFormat:@"%@ has been activated!", title]];
    } else {
        sender.backgroundColor = [UIColor redColor];
        [sender setTitle:title forState:UIControlStateNormal];
    }
    
   
    [UIView animateWithDuration:0.1 animations:^{
        sender.alpha = 0.5;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.1 animations:^{
            sender.alpha = 1.0;
        }];
    }];
}

- (void)saveMenuPosition {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setDouble:_menuButton.center.x forKey:@"menuButtonX"];
    [defaults setDouble:_menuButton.center.y forKey:@"menuButtonY"];
    

    if (_modMenuView) {
        [defaults setDouble:_modMenuView.center.x forKey:@"modMenuX"];
        [defaults setDouble:_modMenuView.center.y forKey:@"modMenuY"];
    }
    
    [defaults synchronize];
}

- (void)loadMenuPosition {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"menuButtonX"] && [defaults objectForKey:@"menuButtonY"]) {
        CGFloat x = [defaults doubleForKey:@"menuButtonX"];
        CGFloat y = [defaults doubleForKey:@"menuButtonY"];
        _menuButton.center = CGPointMake(x, y);
    }
    
  
    if (_modMenuView && [defaults objectForKey:@"modMenuX"] && [defaults objectForKey:@"modMenuY"]) {
        CGFloat menuX = [defaults doubleForKey:@"modMenuX"];
        CGFloat menuY = [defaults doubleForKey:@"modMenuY"];
        _modMenuView.center = CGPointMake(menuX, menuY);
    }
}

+ (BOOL)passthroughMode {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"passthroughMode"];
}

- (void)resetLoopTimer {
}

- (void)stopLoopTimer {
}



static inline CGFloat orientationAngle(UIInterfaceOrientation orientation) {
    switch (orientation) {
        case UIInterfaceOrientationPortraitUpsideDown:
            return M_PI;
        case UIInterfaceOrientationLandscapeLeft:
            return -M_PI_2;
        case UIInterfaceOrientationLandscapeRight:
            return M_PI_2;
        default:
            return 0;
    }
}

static inline CGRect orientationBounds(UIInterfaceOrientation orientation, CGRect bounds) {
    switch (orientation) {
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
            return CGRectMake(0, 0, bounds.size.height, bounds.size.width);
        default:
            return bounds;
    }
}

- (void)setupFBSOrientationObserver {
    _orientationObserver = [[objc_getClass("FBSOrientationObserver") alloc] init];
    __weak SapphireExternalMenu *weakSelf = self;
    [_orientationObserver setHandler:^(FBSOrientationUpdate *orientationUpdate) {
        SapphireExternalMenu *strongSelf = weakSelf;
        dispatch_async(dispatch_get_main_queue(), ^{
            [strongSelf updateOrientation:(UIInterfaceOrientation)orientationUpdate.orientation 
                       animateWithDuration:orientationUpdate.duration];
        });
    }];
}

- (void)updateOrientation:(UIInterfaceOrientation)orientation animateWithDuration:(NSTimeInterval)duration {
    if (orientation == _orientation) {
        return;
    }
    
    _orientation = orientation;
    

    CGRect bounds = orientationBounds(orientation, [UIScreen mainScreen].bounds);
    [self.view setNeedsUpdateConstraints];
    [self.view setHidden:YES];  
    [self.view setBounds:bounds];
    
    [self resetGestureRecognizers];
    
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:duration animations:^{
        [weakSelf.view setTransform:CGAffineTransformMakeRotation(orientationAngle(orientation))];
    } completion:^(BOOL finished) {
        [weakSelf.view setHidden:NO];
        [weakSelf adjustRedSquareAfterOrientation];
    }];
}

- (void)resetGestureRecognizers {

    for (UIGestureRecognizer *recognizer in self.view.gestureRecognizers) {
        [recognizer setEnabled:NO];
        [recognizer setEnabled:YES];
    }
    if (_menuButton) {
        for (UIGestureRecognizer *recognizer in _menuButton.gestureRecognizers) {
            [recognizer setEnabled:NO];
            [recognizer setEnabled:YES];
        }
    }
    if (_modMenuView) {
        for (UIGestureRecognizer *recognizer in _modMenuView.gestureRecognizers) {
            [recognizer setEnabled:NO];
            [recognizer setEnabled:YES];
        }
    }
}

- (void)adjustRedSquareAfterOrientation {
    if (_menuButton) {
        CGFloat halfWidth = _menuButton.frame.size.width / 2.0;
        CGFloat halfHeight = _menuButton.frame.size.height / 2.0;
        CGSize screenSize = self.view.bounds.size;
        
        CGPoint currentCenter = _menuButton.center;
        CGPoint adjustedCenter = CGPointMake(
            MAX(halfWidth, MIN(screenSize.width - halfWidth, currentCenter.x)),
            MAX(halfHeight, MIN(screenSize.height - halfHeight, currentCenter.y))
        );
        
        _menuButton.center = adjustedCenter;
        [self saveMenuPosition];
    }
}

- (void)dealloc {
    [self stopProcessMonitoring];
    [_orientationObserver invalidate];
    
    // Stop RGB cycle timer
    if (_rgbCycleTimer) {
        [_rgbCycleTimer invalidate];
        _rgbCycleTimer = nil;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    

    if (_memoryUtils && _memoryUtils.isValid && _targetProcessName && !_menuButton) {
    
        [self createModMenu];
        [self startProcessMonitoring];
    }
}

- (void)closeMenuButtonTapped:(UITapGestureRecognizer *)sender {
 
    
    _menuVisible = NO;
    

    UIImageView *iconImageView = [_menuButton viewWithTag:100];
    
 
    [UIView animateWithDuration:0.3 animations:^{
        self->_modMenuView.alpha = 0.0;
        iconImageView.alpha = 1.0;
    } completion:^(BOOL finished) {
        self->_modMenuView.hidden = YES;
    }];
}

- (void)menuHeaderPanned:(UIPanGestureRecognizer *)sender {
    CGPoint translation = [sender translationInView:self.view];
    
    if (sender.state == UIGestureRecognizerStateBegan) {
        // Store initial position if needed
    } else if (sender.state == UIGestureRecognizerStateChanged) {
        CGPoint newCenter = CGPointMake(_modMenuView.center.x + translation.x,
                                       _modMenuView.center.y + translation.y);
        
        // Constrain to screen bounds
        CGFloat halfWidth = _modMenuView.frame.size.width / 2.0;
        CGFloat halfHeight = _modMenuView.frame.size.height / 2.0;
        CGSize screenSize = self.view.bounds.size;
        
        newCenter.x = MAX(halfWidth, MIN(screenSize.width - halfWidth, newCenter.x));
        newCenter.y = MAX(halfHeight, MIN(screenSize.height - halfHeight, newCenter.y));
        
        _modMenuView.center = newCenter;
        [sender setTranslation:CGPointZero inView:self.view];
    } else if (sender.state == UIGestureRecognizerStateEnded || sender.state == UIGestureRecognizerStateCancelled) {
        [self saveMenuPosition];
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        UIPanGestureRecognizer *panGesture = (UIPanGestureRecognizer *)gestureRecognizer;
        CGPoint velocity = [panGesture velocityInView:gestureRecognizer.view];
        
        // Check if it's a horizontal pan (for scroll view)
        if (fabs(velocity.x) > fabs(velocity.y)) {
            if (gestureRecognizer.view == _mainScrollView) {
                return YES;
            }
        }
        
        // Check if it's a vertical pan (for dragging)
        if (fabs(velocity.y) > fabs(velocity.x)) {
            UIView *headerView = [_modMenuView viewWithTag:300];
            if (headerView && gestureRecognizer.view == headerView) {
                CGPoint touchPoint = [gestureRecognizer locationInView:headerView];
                if (CGRectContainsPoint(headerView.bounds, touchPoint)) {
                    UIView *customSegmentedControl = [headerView viewWithTag:400];
                    if (customSegmentedControl && CGRectContainsPoint(customSegmentedControl.frame, touchPoint)) {
                        return NO; // Don't allow pan on segmented control
                    }
                    return YES;
                }
            }
        }
        
        // Allow pan for menu button
        if (gestureRecognizer.view == _menuButton) {
            return YES;
        }
    }
    
    // Allow tap gestures
    if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
        return YES;
    }
    
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    // Allow simultaneous recognition for scroll view and pan gestures
    if (gestureRecognizer.view == _mainScrollView && [otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        UIPanGestureRecognizer *panGesture = (UIPanGestureRecognizer *)otherGestureRecognizer;
        CGPoint velocity = [panGesture velocityInView:panGesture.view];
        
        // Allow simultaneous recognition for horizontal scrolling
        if (fabs(velocity.x) > fabs(velocity.y)) {
            return YES;
        }
    }
    
    // Allow simultaneous recognition for menu button pan and tap
    if (gestureRecognizer.view == _menuButton && otherGestureRecognizer.view == _menuButton) {
        return YES;
    }
    
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    // Make tap gesture wait for pan gesture to fail
    if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]] && 
        [otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] &&
        gestureRecognizer.view == _menuButton && otherGestureRecognizer.view == _menuButton) {
        return YES;
    }
    
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    // Make pan gesture require tap gesture to fail for better responsiveness
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] && 
        [otherGestureRecognizer isKindOfClass:[UITapGestureRecognizer class]] &&
        gestureRecognizer.view == _menuButton && otherGestureRecognizer.view == _menuButton) {
        return YES;
    }
    
    return NO;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
   
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  
   
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
   
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
   
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
   
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
   
    NSArray *functions = [self getFunctionsForSegment:_currentSegmentIndex];
    if (textField.tag >= 0 && textField.tag < functions.count) {
        NSDictionary *item = functions[textField.tag];
        NSString *title = item[@"title"];
        

    
        if ([title isEqualToString:@"Menu Text"]) {
          
            UIView *headerView = [_modMenuView viewWithTag:300];
            if (headerView) {
                UILabel *headerTitle = [headerView viewWithTag:302];
                if (headerTitle) {
                    headerTitle.text = textField.text.length > 0 ? textField.text : @"SAPPHIRE CHEATS";
                }
            }
            [self showCustomAlert:@"Menu Text Updated" description:[NSString stringWithFormat:@"Menu header text has been updated to: %@", textField.text.length > 0 ? textField.text : @"SAPPHIRE CHEATS"]];
        } else {
          
            NSString *message = textField.text.length > 0 ? textField.text : @"No text entered";
            [self showCustomAlert:@"Text Field Result" description:[NSString stringWithFormat:@"%@ final text: %@", title, message]];
        }
    }
}

- (void)textFieldTapped:(UITapGestureRecognizer *)sender {
    
    NSArray *functions = [self getFunctionsForSegment:_currentSegmentIndex];
    NSDictionary *item = functions[sender.view.tag];
    NSString *title = item[@"title"];
    
  
    
    UITextField *textField = (UITextField *)sender.view;
    [textField becomeFirstResponder];

    [self showCustomAlert:@"Text Field Active" description:[NSString stringWithFormat:@"%@ is now active. Tap to enter text.", title]];
}

- (void)categorySegmentChanged:(UISegmentedControl *)sender {
    NSArray *categories = @[@"PREPARE", @"DRAWNING", @"MENU", @"MISC"];
    NSString *selectedCategory = categories[sender.selectedSegmentIndex];
    

    [self showCustomAlert:@"Category Changed" description:[NSString stringWithFormat:@"Switched to %@ category", selectedCategory]];
}

- (void)segmentTapped:(UITapGestureRecognizer *)sender {

    UISegmentedControl *segmentedControl = (UISegmentedControl *)sender.view;
    NSArray *categories = @[@"PREPARE", @"DRAWNING", @"MENU", @"MISC"];
  
    CGPoint tapPoint = [sender locationInView:segmentedControl];
    CGFloat segmentWidth = segmentedControl.bounds.size.width / 4.0; 
    NSInteger tappedIndex = (NSInteger)(tapPoint.x / segmentWidth);
    
    if (tappedIndex >= 0 && tappedIndex < 4) { 
        segmentedControl.selectedSegmentIndex = tappedIndex;
        NSString *selectedCategory = categories[tappedIndex];
       
        
       
        _currentSegmentIndex = tappedIndex;
        [self updateMenuViewForSegment:_currentSegmentIndex];
        
       
        [UIView animateWithDuration:0.3 animations:^{
           
            [segmentedControl setNeedsDisplay];
        }];
        
  
        [self showCustomAlert:@"Category Changed" description:[NSString stringWithFormat:@"Switched to %@ category", selectedCategory]];
    }
}

- (void)customSegmentButtonTapped:(UITapGestureRecognizer *)sender {
    UIButton *segmentButton = (UIButton *)sender.view;
    NSArray *categories = @[@"PREPARE", @"DRAWNING", @"MENU", @"MISC"];
    NSString *selectedCategory = categories[segmentButton.tag];
    
  
    
 
    UIView *customSegmentedControl = [_modMenuView viewWithTag:400];
    for (UIView *subview in customSegmentedControl.subviews) {
        if ([subview isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)subview;
            button.selected = (button == segmentButton);
        }
    }
    

    _currentSegmentIndex = segmentButton.tag;
    [self updateMenuViewForSegment:_currentSegmentIndex];
    
 
    [self showCustomAlert:@"Category Changed" description:[NSString stringWithFormat:@"Switched to %@ category", selectedCategory]];
}

- (void)updateSegmentYPosition:(CGFloat)newYPosition {
   
    
   
    UIView *customSegmentedControl = [_modMenuView viewWithTag:400];
    if (!customSegmentedControl) {
       
        return;
    }
    
    
    NSArray *segmentTitles = @[@"PREPARE", @"DRAWNING", @"MENU"];
    NSArray *symbolNames = @[@"eye.fill", @"scope", @"bolt.fill"];
    
    for (UIView *subview in customSegmentedControl.subviews) {
        if ([subview isKindOfClass:[UIButton class]]) {
            UIButton *segmentButton = (UIButton *)subview;
            int buttonIndex = (int)segmentButton.tag;
            
          
            UIImageConfiguration *symbolConfig = [UIImageSymbolConfiguration configurationWithPointSize:12 weight:UIImageSymbolWeightMedium];
            UIImage *symbolImage = [[UIImage systemImageNamed:symbolNames[buttonIndex] withConfiguration:symbolConfig] imageWithTintColor:[UIColor colorWithRed:0.7 green:0.7 blue:0.7 alpha:1.0]];
            
    
            NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] init];
            
       
            NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
            attachment.image = symbolImage;
            attachment.bounds = CGRectMake(0, newYPosition, 14, 14); 
            
            NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
            [attributedString appendAttributedString:attachmentString];
            
         
            NSAttributedString *spaceString = [[NSAttributedString alloc] initWithString:@" "];
            [attributedString appendAttributedString:spaceString];
            
       
            NSAttributedString *textString = [[NSAttributedString alloc] initWithString:segmentTitles[buttonIndex] attributes:@{
                NSFontAttributeName: [UIFont fontWithName:@"Semakin" size:12],
                NSForegroundColorAttributeName: [UIColor colorWithRed:0.7 green:0.7 blue:0.7 alpha:1.0],
                NSBaselineOffsetAttributeName: @(newYPosition) 
            }];
            [attributedString appendAttributedString:textString];
            
           
            [segmentButton setAttributedTitle:attributedString forState:UIControlStateNormal];
            
           
            NSMutableAttributedString *selectedAttributedString = [[NSMutableAttributedString alloc] init];
            
            
            NSTextAttachment *selectedAttachment = [[NSTextAttachment alloc] init];
            selectedAttachment.image = [[UIImage systemImageNamed:symbolNames[buttonIndex] withConfiguration:symbolConfig] imageWithTintColor:[UIColor colorWithRed:15.0/255.0 green:82.0/255.0 blue:186.0/255.0 alpha:1.0]];
            selectedAttachment.bounds = CGRectMake(0, newYPosition, 14, 14); 
            
            NSAttributedString *selectedAttachmentString = [NSAttributedString attributedStringWithAttachment:selectedAttachment];
            [selectedAttributedString appendAttributedString:selectedAttachmentString];
            

            [selectedAttributedString appendAttributedString:spaceString];
            
         
            NSShadow *textShadow = [[NSShadow alloc] init];
            textShadow.shadowColor = [UIColor colorWithRed:15.0/255.0 green:82.0/255.0 blue:186.0/255.0 alpha:1.0];
            textShadow.shadowOffset = CGSizeZero;
            textShadow.shadowBlurRadius = 4.0; 
            
            NSAttributedString *selectedTextString = [[NSAttributedString alloc] initWithString:segmentTitles[buttonIndex] attributes:@{
                NSFontAttributeName: [UIFont fontWithName:@"Semakin" size:12],
                NSForegroundColorAttributeName: [UIColor colorWithRed:15.0/255.0 green:82.0/255.0 blue:186.0/255.0 alpha:1.0],
                NSShadowAttributeName: textShadow,
                NSBaselineOffsetAttributeName: @(newYPosition) 
            }];
            [selectedAttributedString appendAttributedString:selectedTextString];
            
           
            [segmentButton setAttributedTitle:selectedAttributedString forState:UIControlStateSelected];
        }
    }
}

- (void)updateRGBColor:(CGFloat)value {
    
    CGFloat hue = value / 360.0;
    UIColor *newColor = [UIColor colorWithHue:hue saturation:1.0 brightness:1.0 alpha:1.0];
    
    
    _currentRGBColor = newColor;
    
   
    
    
    UIView *headerView = [_modMenuView viewWithTag:300];
    if (headerView) {
        for (UIView *subview in headerView.subviews) {
            if (subview.tag >= 500 && subview.tag <= 503) {
                subview.backgroundColor = newColor;
                subview.layer.shadowColor = newColor.CGColor;
            }
            // Update "Made By AlexZero" text color
            if (subview.tag == 303) {
                UILabel *madeByLabel = (UILabel *)subview;
                madeByLabel.textColor = newColor;
            }
        }
    }
    
    
    UIView *customSegmentedControl = [_modMenuView viewWithTag:400];
    if (customSegmentedControl) {
        NSArray *symbolNames = @[@"eye.fill", @"scope", @"bolt.fill"];
        
        for (UIView *subview in customSegmentedControl.subviews) {
            if ([subview isKindOfClass:[UIButton class]]) {
                UIButton *segmentButton = (UIButton *)subview;
                int buttonIndex = (int)segmentButton.tag;
                
              
                UIImageConfiguration *symbolConfig = [UIImageSymbolConfiguration configurationWithPointSize:12 weight:UIImageSymbolWeightMedium];
                
                NSMutableAttributedString *selectedAttributedString = [[NSMutableAttributedString alloc] init];
                NSTextAttachment *selectedAttachment = [[NSTextAttachment alloc] init];
                selectedAttachment.image = [[UIImage systemImageNamed:symbolNames[buttonIndex] withConfiguration:symbolConfig] imageWithTintColor:newColor];
                selectedAttachment.bounds = CGRectMake(0, 1, 14, 14);
                
                NSAttributedString *selectedAttachmentString = [NSAttributedString attributedStringWithAttachment:selectedAttachment];
                [selectedAttributedString appendAttributedString:selectedAttachmentString];
                
                NSAttributedString *spaceString = [[NSAttributedString alloc] initWithString:@" "];
                [selectedAttributedString appendAttributedString:spaceString];
                
                NSShadow *textShadow = [[NSShadow alloc] init];
                textShadow.shadowColor = newColor;
                textShadow.shadowOffset = CGSizeZero;
                textShadow.shadowBlurRadius = 4.0;
                
                NSAttributedString *selectedTextString = [[NSAttributedString alloc] initWithString:@[@"PREPARE", @"DRAWNING", @"MENU"][buttonIndex] attributes:@{
                    NSFontAttributeName: [UIFont fontWithName:@"Semakin" size:12],
                    NSForegroundColorAttributeName: newColor,
                    NSShadowAttributeName: textShadow,
                    NSBaselineOffsetAttributeName: @(4)
                }];
                [selectedAttributedString appendAttributedString:selectedTextString];
                [segmentButton setAttributedTitle:selectedAttributedString forState:UIControlStateSelected];
            }
        }
    }
    
    
    for (UIView *menuItemView in _mainScrollView.subviews) {
        if ([menuItemView isKindOfClass:[UIView class]] && menuItemView.tag >= 0) {
            for (UIView *subview in menuItemView.subviews) {
                if ([subview isKindOfClass:[UITextField class]]) {
                    UITextField *textField = (UITextField *)subview;
                    textField.layer.borderColor = newColor.CGColor;
                    textField.layer.shadowColor = newColor.CGColor;
                }
            }
        }
    }
    
    
    for (UIView *menuItemView in _mainScrollView.subviews) {
        if ([menuItemView isKindOfClass:[UIView class]] && menuItemView.tag >= 0) {
         
            UILabel *valueLabel = [menuItemView viewWithTag:100];
            if (valueLabel) {
                valueLabel.textColor = newColor;
            }
            
    
            for (UIView *subview in menuItemView.subviews) {
                if ([subview isKindOfClass:[UIView class]] && subview.tag >= 0) {
                  
                    UIView *thumbView = [subview viewWithTag:1001];
                    if (thumbView) {
                        thumbView.layer.borderColor = newColor.CGColor;
                        thumbView.layer.shadowColor = newColor.CGColor;
                    }
                    
             
                    UIView *progressView = [subview viewWithTag:1000];
                    if (progressView) {
                        progressView.backgroundColor = [newColor colorWithAlphaComponent:0.2];
                    }
                }
            }
        }
    }
    
  
    for (UIView *menuItemView in _mainScrollView.subviews) {
        if ([menuItemView isKindOfClass:[UIView class]] && menuItemView.tag >= 0) {
            for (UIView *subview in menuItemView.subviews) {
                if ([subview isKindOfClass:[UIView class]] && subview.tag >= 0) {
               
                    UIView *buttonContainer = subview;
                    if (buttonContainer.tag == 0 || buttonContainer.tag == 1) { 
                        buttonContainer.layer.borderColor = newColor.CGColor;
                        buttonContainer.layer.shadowColor = newColor.CGColor;
                    }
                }
            }
        }
    }
    
   
    UIView *footerView = [_modMenuView viewWithTag:370];
    if (footerView) {
        for (UIView *subview in footerView.subviews) {
            if (subview.tag == 510 || subview.tag == 511) {
                subview.backgroundColor = newColor;
                subview.layer.shadowColor = newColor.CGColor;
            }
        }
    }
    

    for (UIView *subview in _modMenuView.subviews) {
        if (subview.tag == 520 || subview.tag == 521) {
            subview.backgroundColor = newColor;
            subview.layer.shadowColor = newColor.CGColor;
        }
    }
    
  
    for (UIView *alertView in _activeAlerts) {
        if (alertView) {
            for (UIView *subview in alertView.subviews) {
                if ([subview isKindOfClass:[UILabel class]] && subview.tag == 600) {
                    UILabel *titleLabel = (UILabel *)subview;
                    titleLabel.textColor = newColor;
                    titleLabel.layer.shadowColor = newColor.CGColor;
                }
            }
        }
    }
    
    
    [_drawingManager updateSVGColor:newColor];
    

    for (UIView *menuItemView in _mainScrollView.subviews) {
        if ([menuItemView isKindOfClass:[UIView class]] && menuItemView.tag >= 0) {
            for (UIView *subview in menuItemView.subviews) {
               
                if ([subview isKindOfClass:[UIView class]] && (subview.tag >= 3000 && subview.tag < 5000)) {
                    
                    for (UIView *resetSubview in subview.subviews) {
                        if ([resetSubview isKindOfClass:[UIImageView class]]) {
                            UIImageView *resetImageView = (UIImageView *)resetSubview;
                            
                         
                            resetImageView.tintColor = newColor;
                         
                            resetImageView.layer.shadowColor = newColor.CGColor;
                        }
                    }
                }
            }
        }
    }
}

- (void)showCustomAlert:(NSString *)title description:(NSString *)description {
   
    if (!_activeAlerts) {
        _activeAlerts = [NSMutableArray array];
    }
    

    UIFont *descriptionFont = [UIFont fontWithName:@"Semakin" size:11];
    CGSize textSize = [description sizeWithAttributes:@{NSFontAttributeName: descriptionFont}];
    
   
    CGFloat minWidth = 200.0f; 
    CGFloat maxWidth = 600.0f; 
    CGFloat textWidth = textSize.width + 20.0f; 
    CGFloat totalTextWidth = 105.0f + textWidth; 
    CGFloat alertWidth = MAX(minWidth, MIN(maxWidth, totalTextWidth));
    CGFloat alertHeight = 30.0f;
    
    UIView *alertView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, alertWidth, alertHeight)];
    alertView.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.9];
    alertView.layer.cornerRadius = 6.0f;
    alertView.layer.borderWidth = 1.0f;
    alertView.layer.borderColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.8].CGColor;
    
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, 80, 20)];
    titleLabel.text = @"SAPPHIRE";
    titleLabel.textColor = [UIColor colorWithRed:15.0/255.0 green:82.0/255.0 blue:186.0/255.0 alpha:1.0]; 
    titleLabel.font = [UIFont fontWithName:@"Semakin" size:12];
    titleLabel.textAlignment = NSTextAlignmentLeft;
    titleLabel.tag = 600; 
    
  
    titleLabel.layer.shadowColor = [UIColor colorWithRed:15.0/255.0 green:82.0/255.0 blue:186.0/255.0 alpha:1.0].CGColor;
    titleLabel.layer.shadowOffset = CGSizeZero;
    titleLabel.layer.shadowRadius = 4.0;
    titleLabel.layer.shadowOpacity = 0.8;
    
    [alertView addSubview:titleLabel];
    

    UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(95, 8, 1, 14)];
    separator.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.8];
    [alertView addSubview:separator];
    
   
    UILabel *descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(105, 5, alertWidth - 115, 20)];
    descriptionLabel.text = description;
    descriptionLabel.textColor = [UIColor whiteColor];
    descriptionLabel.font = descriptionFont;
    descriptionLabel.textAlignment = NSTextAlignmentLeft;
    descriptionLabel.numberOfLines = 1;
    [alertView addSubview:descriptionLabel];
 
    CGFloat y;
    if (_modMenuView && !_modMenuView.hidden) {
        y = _modMenuView.frame.origin.y - alertHeight - 10.0f;
    } else {
    
        if (@available(iOS 13.0, *)) {
            UIWindow *window = [UIApplication sharedApplication].windows.firstObject;
            UIWindowScene *windowScene = window.windowScene;
            if (windowScene && windowScene.statusBarManager) {
                y = windowScene.statusBarManager.statusBarFrame.size.height + 20.0f;
            } else {
                y = 44.0f;
            }
        } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            y = UIApplication.sharedApplication.statusBarFrame.size.height + 20.0f;
#pragma clang diagnostic pop
        }
    }
  
    CGFloat spacingBetweenAlerts = 5.0f;
    y = y - ([_activeAlerts count] * (alertHeight + spacingBetweenAlerts));
 
    CGFloat screenWidth = self.view.bounds.size.width;
    alertView.frame = CGRectMake(screenWidth, y, alertWidth, alertHeight);
    
  
    [self.view addSubview:alertView];
    [_activeAlerts addObject:alertView];
    
  
    [UIView animateWithDuration:0.4 delay:0.0 usingSpringWithDamping:0.8 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        alertView.frame = CGRectMake(screenWidth - alertWidth - 16.0f, y, alertWidth, alertHeight);
    } completion:nil];
 
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self dismissAlert:alertView];
    });
}

- (void)dismissAlert:(UIView *)alertView {
    
    CGFloat screenWidth = self.view.bounds.size.width;
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        alertView.frame = CGRectMake(screenWidth, alertView.frame.origin.y, alertView.frame.size.width, alertView.frame.size.height);
    } completion:^(BOOL finished) {
        [alertView removeFromSuperview];
        [_activeAlerts removeObject:alertView];
       
        [self repositionAlerts];
    }];
}

- (void)repositionAlerts {
    CGFloat alertHeight = 30.0f;
    CGFloat spacingBetweenAlerts = 5.0f;
    
    CGFloat baseY;
    if (_modMenuView && !_modMenuView.hidden) {
        baseY = _modMenuView.frame.origin.y - alertHeight - 10.0f;
    } else {
      
        if (@available(iOS 13.0, *)) {
            UIWindow *window = [UIApplication sharedApplication].windows.firstObject;
            UIWindowScene *windowScene = window.windowScene;
            if (windowScene && windowScene.statusBarManager) {
                baseY = windowScene.statusBarManager.statusBarFrame.size.height + 20.0f;
            } else {
                baseY = 44.0f;
            }
        } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            baseY = UIApplication.sharedApplication.statusBarFrame.size.height + 20.0f;
#pragma clang diagnostic pop
        }
    }
    
    for (NSInteger i = 0; i < [_activeAlerts count]; i++) {
        UIView *alert = _activeAlerts[i];
        CGFloat newY = baseY - (i * (alertHeight + spacingBetweenAlerts));
        
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            alert.frame = CGRectMake(alert.frame.origin.x, newY, alert.frame.size.width, alert.frame.size.height);
        } completion:nil];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
   
    [_drawingManager updateCirclePosition];
    

    [_drawingManager updateSVGPosition];
}

- (void)resetSliderTapped:(UITapGestureRecognizer *)sender {
    UIView *resetButton = sender.view;
    NSInteger sliderIndex = resetButton.tag - 3000;
    
   
    
   
    NSArray *functions = [self getFunctionsForSegment:_currentSegmentIndex];
    
    if (sliderIndex >= 0 && sliderIndex < functions.count) {
        NSDictionary *item = functions[sliderIndex];
        NSString *title = item[@"title"];
        CGFloat defaultValue = [item[@"default"] floatValue];
        
    
        UIView *menuItemView = resetButton.superview;
        UIView *sliderContainer = [menuItemView viewWithTag:sliderIndex];
        
     
        if (sliderContainer) {
            [self resetSliderToDefault:sliderContainer withValue:defaultValue];
            [self showCustomAlert:@"Slider Reset" description:[NSString stringWithFormat:@"%@ reset to default value: %.2f", title, defaultValue]];
        } else {
           
        }
    } else {
       
    }
    
 
    [UIView animateWithDuration:0.1 animations:^{
        resetButton.alpha = 0.5;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.1 animations:^{
            resetButton.alpha = 1.0;
        }];
    }];
}

- (void)resetTextFieldTapped:(UITapGestureRecognizer *)sender {
    UIView *resetButton = sender.view;
    NSInteger textFieldIndex = resetButton.tag - 4000;
    

    NSArray *functions = [self getFunctionsForSegment:_currentSegmentIndex];
    
    NSDictionary *item = functions[textFieldIndex];
    NSString *title = item[@"title"];
    
 
    UIView *menuItemView = resetButton.superview;
    UITextField *textField = [menuItemView viewWithTag:textFieldIndex];
    
    if (textField) {
        textField.text = @"";
        [textField resignFirstResponder];
        [self showCustomAlert:@"Text Field Reset" description:[NSString stringWithFormat:@"%@ text field has been cleared", title]];
    }
    
 
    [UIView animateWithDuration:0.1 animations:^{
        resetButton.alpha = 0.5;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.1 animations:^{
            resetButton.alpha = 1.0;
        }];
    }];
}

- (void)resetSliderToDefault:(UIView *)sliderContainer withValue:(CGFloat)defaultValue {

    UIView *thumbView = [sliderContainer viewWithTag:1001];
    UIView *progressView = [sliderContainer viewWithTag:1000];
    
    
    NSArray *functions = [self getFunctionsForSegment:_currentSegmentIndex];
    NSDictionary *item = functions[sliderContainer.tag];
    CGFloat minValue = [item[@"min"] floatValue];
    CGFloat maxValue = [item[@"max"] floatValue];
    
 
    CGFloat percentage = ((defaultValue - minValue) / (maxValue - minValue)) * 100.0;
    CGFloat trackWidth = 90.0;
    CGFloat thumbRadius = 12.0;
    CGFloat minX = 5 + thumbRadius;
    CGFloat maxX = 5 + trackWidth - thumbRadius;
    CGFloat newThumbX = minX + (percentage / 100.0) * (maxX - minX);
    
   
    thumbView.center = CGPointMake(newThumbX, thumbView.center.y);
    

    CGFloat progressWidth = newThumbX - 5;
    progressView.frame = CGRectMake(5, 8, progressWidth, 6);
    
  
    UIView *menuItemView = sliderContainer.superview;
    UILabel *valueLabel = [menuItemView viewWithTag:100];
    if (valueLabel) {
        NSString *newValueText;
        if ([item[@"title"] isEqualToString:@"Table Thickness"]) {
            newValueText = [NSString stringWithFormat:@"%.2f", defaultValue];
        } else if ([item[@"title"] isEqualToString:@"Pocket Lines Alpha"]) {
            newValueText = [NSString stringWithFormat:@"%.2f", defaultValue];
        } else {
            newValueText = [NSString stringWithFormat:@"%.0f", defaultValue];
        }
        valueLabel.text = newValueText;
        
      
        UIFont *valueFont = [UIFont fontWithName:@"Semakin" size:10];
        CGSize textSize = [newValueText sizeWithAttributes:@{NSFontAttributeName: valueFont}];
        CGFloat valueLabelWidth = textSize.width + 10; 
        CGFloat valueLabelX = 200 - valueLabelWidth - 5; 
        
        valueLabel.frame = CGRectMake(valueLabelX, valueLabel.frame.origin.y, valueLabelWidth, valueLabel.frame.size.height);
    }
    
  
    NSString *title = item[@"title"];
   
    
    if ([title isEqualToString:@"Table Thickness"]) {
        [_drawingManager updateSVGLineThickness:defaultValue];
    } else if ([title isEqualToString:@"Ball Thickness"]) {
        [_drawingManager updateCircleThickness:defaultValue];
    } else if ([title isEqualToString:@"Table Size"]) {
        [_drawingManager updateSVGSize:defaultValue];
    } else if ([title isEqualToString:@"Table Position Y"]) {
        [_drawingManager updateSVGPositionY:defaultValue];
    } else if ([title isEqualToString:@"Table Position X"]) {
        [_drawingManager updateSVGPositionX:defaultValue];
    } else if ([title isEqualToString:@"Target Ball Size"]) {
        [_drawingManager updateCircleSize:defaultValue];
    } else if ([title isEqualToString:@"RGB Slider"]) {
        [self updateRGBColor:defaultValue];
    } else if ([title isEqualToString:@"Scale Menu"]) {
        _modMenuView.transform = CGAffineTransformMakeScale(defaultValue, defaultValue);
    } else if ([title isEqualToString:@"Pocket Lines Size"]) {
        [_drawingManager updateConnectionLineThickness:defaultValue];
    } else if ([title isEqualToString:@"Pocket Lines Alpha"]) {
        [_drawingManager updateConnectionLineAlpha:defaultValue];
    } else {
       
    }
}

- (void)startRGBCycle:(BOOL)enabled {
    if (enabled) {
        // Stop existing timer if running
        if (_rgbCycleTimer) {
            [_rgbCycleTimer invalidate];
            _rgbCycleTimer = nil;
        }
        
        // Start new RGB cycle timer
        _rgbCycleTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateRGBCycle) userInfo:nil repeats:YES];
    } else {
        // Stop the RGB cycle timer
        if (_rgbCycleTimer) {
            [_rgbCycleTimer invalidate];
            _rgbCycleTimer = nil;
        }
        
        // Reset to default blue color
        [self updateRGBColor:240.0]; 
    }
}

- (void)updateRGBCycle {
    static CGFloat hue = 0.0;
    hue += 2.0; 
    if (hue >= 360.0) hue = 0.0;
    
    [self updateRGBColor:hue];
}

- (void)setGlowEnabled:(BOOL)enabled {

   
    
   
    if (enabled) {
       
        
    } else {
      
       
    }
}

@end
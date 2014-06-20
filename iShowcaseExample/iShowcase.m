//
//  iShowcase.m
//  iShowcase
//
//  Created by Rahul Iyer
//  This software is released under the MIT License.
//
//  Copyright (c) 2014 Rahul Iyer
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
//  Except as contained in this notice, the name(s) of the above copyright holders shall not be used in advertising or otherwise to promote the sale, use or other dealings in this Software without prior written authorization.

#import "iShowcase.h"

@interface iShowcase()

- (void) setupBackground;
- (void) setupTextWithTitle: (NSString*) title detailsText : (NSString*) details;
- (void) calculateRegion;
- (NSArray*) getBestPositionOfTitleWithSize: (CGSize) titleSize detailsSize: (CGSize) detailsSize;
- (void) showcaseTapped;
- (void) onAnimationComplete;
- (UITapGestureRecognizer*) getGesture;

@property (nonatomic) UIImageView *showcaseImageView;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UILabel *detailsLabel;

@property (nonatomic) UIColor *titleColor;
@property (nonatomic) UIColor *detailsColor;
@property (nonatomic) UIColor *backgroundColor;
@property (nonatomic) UIFont *titleFont;
@property (nonatomic) UIFont *detailsFont;
@property (nonatomic) NSTextAlignment titleAlignment;
@property (nonatomic) NSTextAlignment detailsAlignment;
@property (nonatomic, retain) id containerView;

@property (nonatomic) int region;
@property (nonatomic) CGRect showcaseRect;

@end

@implementation iShowcase

@synthesize delegate;
@synthesize showcaseImageView;
@synthesize titleLabel;
@synthesize detailsLabel;
@synthesize showcaseRect;
@synthesize containerView;

-(id) init
{
    return [self initWithTitleFont:[UIFont boldSystemFontOfSize:24.0f] detailsFont:[UIFont systemFontOfSize:16.0f] titleColor:[UIColor whiteColor] detailsColor:[UIColor whiteColor]];
}

-(id) initWithTitleFont:(UIFont *)titleFont detailsFont:(UIFont *)detailsFont
{
    return [self initWithTitleFont:titleFont detailsFont:detailsFont titleColor:[UIColor whiteColor] detailsColor:[UIColor whiteColor]];
}

-(id) initWithTitleColor:(UIColor *)titleColor detailsColor:(UIColor *)detailsColor
{
    return [self initWithTitleFont:[UIFont boldSystemFontOfSize:24.0f] detailsFont:[UIFont systemFontOfSize:16.0f] titleColor:titleColor detailsColor:detailsColor];
}

-(id) initWithTitleFont:(UIFont *)titleFont detailsFont:(UIFont *)detailsFont titleColor:(UIColor *)titleColor detailsColor:(UIColor *)detailsColor
{
    self.backgroundColor = [UIColor blackColor];
    self.titleFont = titleFont;
    self.titleColor = titleColor;
    self.detailsFont = detailsFont;
    self.detailsColor = detailsColor;
    self.titleAlignment = NSTextAlignmentCenter;
    self.detailsAlignment = NSTextAlignmentCenter;
    return [self initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
}

-(void) setupShowcaseForTarget:(id)target title:(NSString *)title details:(NSString *)details
{
    [self setupShowcaseForLocation:CGRectMake([target frame].origin.x, [target frame].origin.y, [target bounds].size.width, [target bounds].size.height) title:title details:details];
}

- (void) setupShowcaseForLocation:(CGRect)location title:(NSString *)title details:(NSString *)details
{
    self.showcaseRect = location;
    [self setupBackground];
    [self calculateRegion];
    [self setupTextWithTitle:title detailsText:details];
    
    [self addSubview:showcaseImageView];
    [self addSubview:titleLabel];
    [self addSubview:detailsLabel];
    [self addGestureRecognizer:[self getGesture]];
}

-(void) show
{
    [self showInContainer:containerView];
}

-(void) showInContainer:(id)container
{
    containerView = container;
    self.alpha = 1.0f;
    for (UIView* view in [container subviews])
    {
        [view setUserInteractionEnabled:NO];
    }
    
    [UIView transitionWithView:container
                    duration:0.5
                    options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        [container addSubview:self];
                    }
                    completion:^(BOOL finished) {
                        [delegate iShowcaseShown];
                    }];
}

- (void) setupBackground
{
    UIImage *showcaseImage = nil;
    
    // Black Background
    UIGraphicsBeginImageContext([containerView size]);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [self.backgroundColor CGColor]);
    CGContextFillRect(context, [containerView bounds]);
    showcaseImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // Clear Region
    UIGraphicsBeginImageContext(showcaseImage.size);
    [showcaseImage drawAtPoint:CGPointZero];
    context = UIGraphicsGetCurrentContext();
    CGContextAddPath(context, [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, showcaseImage.size.width, showcaseImage.size.height)].CGPath);
    CGContextClip(context);
    CGContextClearRect(context, showcaseRect);
    showcaseImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    context = NULL;
    
    showcaseImageView = [[UIImageView alloc] initWithImage:showcaseImage];
    showcaseImage = nil;
    [showcaseImageView setAlpha:0.75f];
}

- (void) setupTextWithTitle:(NSString *)title detailsText:(NSString *)details
{
    CGSize titleSize = [title sizeWithAttributes:@{NSFontAttributeName: self.titleFont}];
    CGSize detailsSize = [details sizeWithAttributes:@{NSFontAttributeName: self.detailsFont}];
    NSArray *textPosition = [self getBestPositionOfTitleWithSize:titleSize detailsSize:detailsSize];
    
    if (self.region != 2)
    {
        titleLabel = [[UILabel alloc] initWithFrame:[(NSValue*) [textPosition objectAtIndex:0] CGRectValue]];
        detailsLabel = [[UILabel alloc] initWithFrame:[(NSValue*) [textPosition objectAtIndex:1] CGRectValue]];
    }
    else // Bottom Region
    {
        detailsLabel = [[UILabel alloc] initWithFrame:[(NSValue*) [textPosition objectAtIndex:0] CGRectValue]];
        titleLabel = [[UILabel alloc] initWithFrame:[(NSValue*) [textPosition objectAtIndex:1] CGRectValue]];
    }
    
    titleLabel.text = title;
    titleLabel.textAlignment = self.titleAlignment;
    titleLabel.textColor = self.titleColor;
    titleLabel.font = self.titleFont;
    
    detailsLabel.text = details;
    detailsLabel.textAlignment = self.detailsAlignment;
    detailsLabel.textColor = self.detailsColor;
    detailsLabel.font = self.detailsFont;
}

- (void) calculateRegion
{
    float left = showcaseRect.origin.x,
    right = showcaseRect.origin.x + showcaseRect.size.width,
    top = showcaseRect.origin.y,
    bottom = showcaseRect.origin.y + showcaseRect.size.height;
    
    NSArray* areas = [[NSArray alloc] initWithObjects:
                      [NSNumber numberWithFloat:top  * [[UIScreen mainScreen] bounds].size.width], // Top Region
                      [NSNumber numberWithFloat:left *  [[UIScreen mainScreen] bounds].size.height ], // Left Region
                      [NSNumber numberWithFloat:([[UIScreen mainScreen] bounds].size.height - bottom) * [[UIScreen mainScreen] bounds].size.width], // Bottom Region
                      [NSNumber numberWithFloat:([[UIScreen mainScreen] bounds].size.width - right) * [[UIScreen mainScreen] bounds].size.height], nil]; // Right Region
    
    int largest = 0;
    
    
    for (int i=0; i < [areas count]; i++)
    {
        if ([[areas objectAtIndex:i] floatValue] > [[areas objectAtIndex:largest] floatValue])
            largest = i;
    }
    
    self.region = largest;
}

- (NSArray*) getBestPositionOfTitleWithSize:(CGSize)titleSize detailsSize:(CGSize)detailsSize
{
    CGRect rect0, rect1;
    switch (self.region)
    {
        case 0: // Top Region
            rect0 = CGRectMake([containerView bounds].size.width / 2.0f - titleSize.width / 2.0f, titleSize.height + 64, titleSize.width, titleSize.height);
            rect1 = CGRectMake([containerView bounds].size.width / 2.0f - detailsSize.width / 2.0f, rect0.origin.y + rect0.size.height + detailsSize.height / 2.0f, detailsSize.width, detailsSize.height);
            break;
        case 1: // Left Region
            rect0 = CGRectMake(0, [containerView bounds].size.height / 2.0f, titleSize.width, titleSize.height);
            rect1 = CGRectMake([containerView bounds].size.width / 2.0f - detailsSize.width / 2.0f, rect0.origin.y + rect0.size.height + detailsSize.height / 2.0f, detailsSize.width, detailsSize.height);
            break;
        case 2: // Bottom Region
            rect0 = CGRectMake([containerView bounds].size.width / 2.0f - detailsSize.width / 2.0f , [containerView bounds].size.height - detailsSize.height * 2.0f, detailsSize.width, detailsSize.height);
            rect1 = CGRectMake([containerView bounds].size.width / 2.0f - titleSize.width / 2.0f, rect0.origin.y - rect0.size.height - titleSize.height / 2.0f, titleSize.width, titleSize.height);
            break;
        case 3: // Right Region
            rect0 = CGRectMake([containerView bounds].size.width - titleSize.width, [containerView bounds].size.height / 2.0f, titleSize.width, titleSize.height);
            rect1 = CGRectMake([containerView bounds].size.width / 2.0f - detailsSize.width / 2.0f, rect0.origin.y + rect0.size.height + detailsSize.height / 2.0f, detailsSize.width, detailsSize.height);
            break;
    }

    return [NSArray arrayWithObjects:[NSValue valueWithCGRect:rect0], [NSValue valueWithCGRect:rect1], nil];
}

- (UITapGestureRecognizer*) getGesture
{
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showcaseTapped)];
    singleTap.numberOfTapsRequired = 1;
    singleTap.numberOfTouchesRequired = 1;
    return singleTap;
}

- (void) showcaseTapped
{
    [UIView animateWithDuration:0.5 animations:^{ self.alpha = 0.0f; } completion:^(BOOL finished) { [self onAnimationComplete]; } ];
}

-(void) onAnimationComplete
{
    for (UIView *view in [self.containerView subviews])
    {
        [view setUserInteractionEnabled:YES];
    }
    [showcaseImageView removeFromSuperview];
    showcaseImageView = NULL;
    [titleLabel removeFromSuperview];
    titleLabel = NULL;
    [detailsLabel removeFromSuperview];
    detailsLabel = NULL;
    [self removeFromSuperview];
    [delegate iShowcaseDismissed];
}

+ (UIColor*) colorFromHexString:(NSString *)hexCode
{
    NSString *cleanString = [hexCode stringByReplacingOccurrencesOfString:@"#" withString:@""];
    if([cleanString length] == 3) {
        cleanString = [NSString stringWithFormat:@"%@%@%@%@%@%@",
                       [cleanString substringWithRange:NSMakeRange(0, 1)],[cleanString substringWithRange:NSMakeRange(0, 1)],
                       [cleanString substringWithRange:NSMakeRange(1, 1)],[cleanString substringWithRange:NSMakeRange(1, 1)],
                       [cleanString substringWithRange:NSMakeRange(2, 1)],[cleanString substringWithRange:NSMakeRange(2, 1)]];
    }
    if([cleanString length] == 6) {
        cleanString = [cleanString stringByAppendingString:@"ff"];
    }
    
    unsigned int baseValue;
    [[NSScanner scannerWithString:cleanString] scanHexInt:&baseValue];
    
    float red = ((baseValue >> 24) & 0xFF)/255.0f;
    float green = ((baseValue >> 16) & 0xFF)/255.0f;
    float blue = ((baseValue >> 8) & 0xFF)/255.0f;
    float alpha = ((baseValue >> 0) & 0xFF)/255.0f;
    
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
    
}

@end
//
//  AppDelegate.h
//  Bad Sign
//
//  Created by admin on 12/8/13.
//  Copyright (c) 2013 Void Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ViewController.h"

static NSString * const kAppStoreID      = @"912176242";
#define kAppStoreURL     ([@"https://itunes.apple.com/us/app/bad-sign/id" stringByAppendingString:kAppStoreID])
#define kAppStoreRateURL ([@"itms-apps://itunes.apple.com/app/id" stringByAppendingString:kAppStoreID])





@interface AppDelegate : UIResponder <UIApplicationDelegate> {
    ViewController * viewController;
    
    UILabel* dateLabel;
    // UILabel* timeLabel;
    
    UIDatePicker * datePicker;
    // UIDatePicker * timePicker;
    
    UIView* statsView;
    UILabel * labStat1;
    UILabel * labStat2;
    UILabel * labStat3;
    UILabel * labStat3_ago;
    UILabel * labStat4;
    UILabel * labStat4_ago;
    UILabel * labStat5;
    UILabel * labStat5_ago;
    UILabel * labStat6;
    UILabel * labStat6_ago;
    UILabel * labStat_moon;
    UIImageView * moonView;
    
    UINavigationController * navController;
    
    // share
    UIActivityIndicatorView *activityIndicator;
    UIImageView * shareView;
    
    int uses_count;
    
    double screenWidth;
    
    NSTimer * datePickerTimer;
}

@property (strong, nonatomic) UIWindow *window;


-(void) dateChanged:(id) sender;
// -(void) timeChanged:(id) sender;

-(void) hidePickers;

// Returns the directory where arch.7z is pre-extracted at first launch.
+ (NSString *)archiveCacheDir;

@end

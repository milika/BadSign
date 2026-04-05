//
//  AppDelegate.m
//  Bad Sign
//
//  Created by admin on 12/8/13.
//  Copyright (c) 2013 Void Software. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "Signs.h"
#import "LZMAExtractor.h"




@implementation AppDelegate

UITapGestureRecognizer * backTap;

+ (NSString *)archiveCacheDir {
    NSString *appSupport = [NSSearchPathForDirectoriesInDomains(
        NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject];
    return [appSupport stringByAppendingPathComponent:@"arch"];
}

+ (void)ensureArchiveExtracted {
    NSString *cacheDir = [AppDelegate archiveCacheDir];
    NSString *sentinelPath = [cacheDir stringByAppendingPathComponent:@".done"];
    NSFileManager *fm = [NSFileManager defaultManager];

    if ([fm fileExistsAtPath:sentinelPath]) return; // already extracted

    NSString *archivePath = [[NSBundle mainBundle] pathForResource:@"arch" ofType:@"7z"];
    if (!archivePath) { NSLog(@"[ARCH] arch.7z not found in bundle"); return; }

    [fm createDirectoryAtPath:cacheDir withIntermediateDirectories:YES attributes:nil error:nil];
    [LZMAExtractor extract7zArchive:archivePath dirName:cacheDir preserveDir:NO];

    NSError *err = nil;
    [@"1" writeToFile:sentinelPath atomically:YES encoding:NSUTF8StringEncoding error:&err];
    NSLog(@"[ARCH] Archive extracted to %@", cacheDir);
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Pre-extract arch.7z to Application Support once so subsequent sign
    // calculations read from disk (no LZMA decompression cost).
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [AppDelegate ensureArchiveExtracted];
    });

    // iOS7 = [[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0;
    //  size4Inch =[[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.height == 568.0;
    
    screenWidth = [[UIScreen mainScreen] bounds].size.width;
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor colorWithRed:38.0/255 green:39.0/255 blue:43.0/255 alpha:1.0]; // [UIColor whiteColor];
    viewController = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil];
    navController = [[UINavigationController alloc] initWithRootViewController:viewController];
    navController.navigationBar.prefersLargeTitles = false;
    navController.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    
    // cutom title view
    UIView* customTitleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, 44)];
    customTitleView.userInteractionEnabled = YES;
    
    navController.navigationBar.translucent = NO;
    customTitleView.backgroundColor = [UIColor colorWithRed:38.0/255 green:39.0/255 blue:43.0/255 alpha:0.0];
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:38.0/255 green:39.0/255 blue:43.0/255 alpha:1.0]];
    [[UINavigationBar appearance] setBackgroundColor:[UIColor colorWithRed:38.0/255 green:39.0/255 blue:43.0/255 alpha:1.0]];
    navController.navigationBar.backgroundColor = [UIColor colorWithRed:38.0/255 green:39.0/255 blue:43.0/255 alpha:1.0];
    
    
    
    // stats
    int  add_ofset = 12.0;
    
    int  ofset = 4;
    
    float x = navController.navigationBar.frame.origin.y+navController.navigationBar.frame.size.height+screenWidth*216.0/320.0;
    statsView = [[UIView alloc] initWithFrame:CGRectMake(0, x, screenWidth, self.window.frame.size.height-x)];
    statsView.backgroundColor = [UIColor colorWithRed:240.0/255 green:241.0/255 blue:236.0/255 alpha:1.0];
    statsView.hidden = YES;
    statsView.userInteractionEnabled = YES;
    [navController.view addSubview:statsView];
    
    
    backTap =[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backTap:)];
    backTap.numberOfTapsRequired = 1;
    backTap.enabled = NO;
    //statsView.userInteractionEnabled = YES;
    //[customTitleView bringSubviewToFront:statsView];
    [statsView addGestureRecognizer:backTap];
    
    
    labStat1 = [[UILabel alloc] initWithFrame:CGRectMake(22, 20, screenWidth-22, 24)];
    labStat1.text = @"...";
    [labStat1 setFont:[UIFont fontWithName:@"Helvetica Neue LT Com" size:16.0]];
    [labStat1 setTextColor:[UIColor colorWithRed:51.0/255 green:51.0/255 blue:53.0/255 alpha:1.0]];
    [labStat1 setTextAlignment:NSTextAlignmentLeft];
    [labStat1 setBackgroundColor:[UIColor clearColor]];
    [statsView addSubview:labStat1];
    
    labStat2 = [[UILabel alloc] initWithFrame:CGRectMake(22, 48+add_ofset, screenWidth-22, 24)];
    labStat2.text = @"...";
    [labStat2 setFont:[UIFont fontWithName:@"Helvetica Neue LT Com" size:10.0]];
    [labStat2 setTextColor:[UIColor colorWithRed:150.0/255 green:148.0/255 blue:149.0/255 alpha:1.0]];
    [labStat2 setTextAlignment:NSTextAlignmentLeft];
    [labStat2 setBackgroundColor:[UIColor clearColor]];
    [statsView addSubview:labStat2];
    
    labStat3 = [[UILabel alloc] initWithFrame:CGRectMake(22, 78+2*add_ofset, screenWidth-22, 24)];
    labStat3.text = @"...";
    [labStat3 setFont:[UIFont fontWithName:@"Helvetica Neue LT Com" size:16.0]];
    [labStat3 setTextColor:[UIColor colorWithRed:51.0/255 green:51.0/255 blue:53.0/255 alpha:1.0]];
    [labStat3 setTextAlignment:NSTextAlignmentLeft];
    [labStat3 setBackgroundColor:[UIColor clearColor]];
    [statsView addSubview:labStat3];
    
    labStat3_ago = [[UILabel alloc] initWithFrame:CGRectMake(22, 78+2*add_ofset-ofset, screenWidth-22, 24)];
    labStat3_ago.text = @"ago";
    [labStat3_ago setFont:[UIFont fontWithName:@"Helvetica Neue LT Com" size:16.0]];
    [labStat3_ago setTextColor:[UIColor colorWithRed:150.0/255 green:148.0/255 blue:149.0/255 alpha:1.0]];
    [labStat3_ago setTextAlignment:NSTextAlignmentLeft];
    [labStat3_ago setBackgroundColor:[UIColor clearColor]];
    [statsView addSubview:labStat3_ago];
    
    labStat4 = [[UILabel alloc] initWithFrame:CGRectMake(22, 115+3*add_ofset, screenWidth-22, 24)];
    labStat4.text = @"...";
    [labStat4 setFont:[UIFont fontWithName:@"Helvetica Neue LT Com" size:16.0]];
    [labStat4 setTextColor:[UIColor colorWithRed:51.0/255 green:51.0/255 blue:53.0/255 alpha:1.0]];
    [labStat4 setTextAlignment:NSTextAlignmentLeft];
    [labStat4 setBackgroundColor:[UIColor clearColor]];
    [statsView addSubview:labStat4];
    
    labStat4_ago = [[UILabel alloc] initWithFrame:CGRectMake(22, 115+3*add_ofset-ofset, screenWidth-22, 24)];
    labStat4_ago.text = @"ago";
    [labStat4_ago setFont:[UIFont fontWithName:@"Helvetica Neue LT Com" size:16.0]];
    [labStat4_ago setTextColor:[UIColor colorWithRed:150.0/255 green:148.0/255 blue:149.0/255 alpha:1.0]];
    [labStat4_ago setTextAlignment:NSTextAlignmentLeft];
    [labStat4_ago setBackgroundColor:[UIColor clearColor]];
    [statsView addSubview:labStat4_ago];
    
    labStat5 = [[UILabel alloc] initWithFrame:CGRectMake(22, 149+4*add_ofset, screenWidth-22, 24)];
    labStat5.text = @"...";
    [labStat5 setFont:[UIFont fontWithName:@"Helvetica Neue LT Com" size:16.0]];
    [labStat5 setTextColor:[UIColor colorWithRed:51.0/255 green:51.0/255 blue:53.0/255 alpha:1.0]];
    [labStat5 setTextAlignment:NSTextAlignmentLeft];
    [labStat5 setBackgroundColor:[UIColor clearColor]];
    [statsView addSubview:labStat5];
    
    labStat5_ago = [[UILabel alloc] initWithFrame:CGRectMake(22, 149+4*add_ofset-ofset, screenWidth-22, 24)];
    labStat5_ago.text = @"ago";
    [labStat5_ago setFont:[UIFont fontWithName:@"Helvetica Neue LT Com" size:16.0]];
    [labStat5_ago setTextColor:[UIColor colorWithRed:150.0/255 green:148.0/255 blue:149.0/255 alpha:1.0]];
    [labStat5_ago setTextAlignment:NSTextAlignmentLeft];
    [labStat5_ago setBackgroundColor:[UIColor clearColor]];
    [statsView addSubview:labStat5_ago];
    
    labStat6 = [[UILabel alloc] initWithFrame:CGRectMake(22, 184+5*add_ofset, screenWidth-22, 24)];
    labStat6.text = @"...";
    [labStat6 setFont:[UIFont fontWithName:@"Helvetica Neue LT Com" size:16.0]];
    [labStat6 setTextColor:[UIColor colorWithRed:51.0/255 green:51.0/255 blue:53.0/255 alpha:1.0]];
    [labStat6 setTextAlignment:NSTextAlignmentLeft];
    [labStat6 setBackgroundColor:[UIColor clearColor]];
    [statsView addSubview:labStat6];
    
    labStat6_ago = [[UILabel alloc] initWithFrame:CGRectMake(22, 184+5*add_ofset-ofset, screenWidth-22, 24)];
    labStat6_ago.text = @"ago";
    [labStat6_ago setFont:[UIFont fontWithName:@"Helvetica Neue LT Com" size:16.0]];
    [labStat6_ago setTextColor:[UIColor colorWithRed:150.0/255 green:148.0/255 blue:149.0/255 alpha:1.0]];
    [labStat6_ago setTextAlignment:NSTextAlignmentLeft];
    [labStat6_ago setBackgroundColor:[UIColor clearColor]];
    [statsView addSubview:labStat6_ago];
    
    labStat_moon = [[UILabel alloc] initWithFrame:CGRectMake(screenWidth-(320.0-206.0), 184+5*add_ofset-ofset, 302-206, 24)];
    labStat_moon.text = @"New Moon";
    [labStat_moon setFont:[UIFont fontWithName:@"Helvetica Neue LT Com" size:10.0]];
    [labStat_moon setTextColor:[UIColor colorWithRed:150.0/255 green:148.0/255 blue:149.0/255 alpha:1.0]];
    [labStat_moon setTextAlignment:NSTextAlignmentCenter];
    [labStat_moon setBackgroundColor:[UIColor clearColor]];
    [statsView addSubview:labStat_moon];
    
    moonView = [[UIImageView alloc] initWithFrame:CGRectMake(screenWidth-(320.0-220.0), 106+4*add_ofset, 68, 68)];
    [statsView addSubview:moonView];
    
    // UIImageView * imgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"top-back.jpg"]];
    // [customTitleView addSubview:imgView];
    
    // customTitleView.layer.borderWidth = 1.0;
    // customTitleView.layer.borderColor = [[UIColor grayColor] CGColor];
    
    dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(14, 4, 200, 44)];
    dateLabel.text = @"date...";
    [dateLabel setFont:[UIFont fontWithName:@"Helvetica Neue LT Com" size:16.0]];
    [dateLabel setTextColor:[UIColor colorWithRed:240.0/255 green:240.0/255 blue:237.0/255 alpha:1.0]];
    [dateLabel setTextAlignment:NSTextAlignmentLeft];
    [dateLabel setBackgroundColor:[UIColor clearColor]];
    //[dateLabel sizeToFit];
    //[dateLabel setCenter:[customTitleView center]];
    [customTitleView addSubview:dateLabel];
    
    /*
     timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(215, 4, 92, 44)];
     timeLabel.text = @"time...";
     [timeLabel setFont:[UIFont fontWithName:@"Helvetica Neue LT Com" size:16.0]];
     [timeLabel setTextColor:[UIColor colorWithRed:240.0/255 green:240.0/255 blue:237.0/255 alpha:1.0]];
     [timeLabel setTextAlignment:NSTextAlignmentRight];
     [timeLabel setBackgroundColor:[UIColor clearColor]];
     //[timeLabel sizeToFit];
     //[timeLabel setCenter:[customTitleView center]];
     [customTitleView addSubview:timeLabel];
     */
    shareView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"share-white.png"]];
    [shareView setFrame:CGRectMake(screenWidth-(320.0-280.0), 8.0, 19.0, 27.0)];
    [customTitleView addSubview:shareView];
    
    activityIndicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    activityIndicator.frame = CGRectMake(screenWidth-(320.0-280.0), 8.0, 19.0, 27.0);
    activityIndicator.hidden = YES;
    [customTitleView addSubview: activityIndicator];
    
    UITapGestureRecognizer * dateTimeTap =[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dateTimeTap:)];
    dateTimeTap.numberOfTapsRequired = 1;
    [customTitleView addGestureRecognizer:dateTimeTap];
    
    //    [viewController.navigationItem setTitleView:customTitleView];
    [[navController navigationBar] addSubview:customTitleView];
    
    // datepicker init
    float reservedTop=self.window.safeAreaInsets.top;
    datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, reservedTop+navController.navigationBar.frame.origin.y+navController.navigationBar.frame.size.height, screenWidth, screenWidth*216.0/320.0)];
    //    datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, 0, screenWidth, screenWidth*216.0/320.0)];
    
    if (@available(iOS 13.4, *)) {
        datePicker.preferredDatePickerStyle = UIDatePickerStyleWheels;
    }
    datePicker.datePickerMode = UIDatePickerModeDate;
    datePicker.hidden = YES;
    datePicker.backgroundColor = statsView.backgroundColor;
    datePicker.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    [datePicker addTarget:self action:@selector(dateChanged:) forControlEvents:UIControlEventValueChanged];
    
    // load date
    NSDate * loadDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"birtday"];
    if (loadDate != nil) datePicker.date = loadDate;
    else {
        datePicker.date = [NSDate date];
        
        // open date selection
        datePicker.hidden = NO;
        backTap.enabled = YES;
        statsView.hidden = NO;
        viewController.view.userInteractionEnabled = NO;
        viewController.view.hidden = YES;
    }
    
    [self dateChanged:self];
    [navController.view addSubview:datePicker];
    datePicker.frame =  CGRectMake(0, reservedTop+navController.navigationBar.frame.origin.y+navController.navigationBar.frame.size.height, screenWidth, screenWidth*216.0/320.0);
    
    /*
     // timepicker init
     timePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, navController.navigationBar.frame.origin.y+navController.navigationBar.frame.size.height, 320, 216.0)];
     timePicker.datePickerMode = UIDatePickerModeTime;
     timePicker.hidden = YES;
     [timePicker addTarget:self action:@selector(timeChanged:) forControlEvents:UIControlEventValueChanged];
     timePicker.date = datePicker.date;
     [self timeChanged:self];
     [navController.view addSubview:timePicker];
     */
    
    // finish initialization
    self.window.rootViewController = navController;
    [navController setNavigationBarHidden:YES];
    [navController setNavigationBarHidden:NO];
    [self.window makeKeyAndVisible];
    
    // rate count
    uses_count = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"uses_count"];
    NSLog(@"uses_count %i",uses_count);
    
    return YES;
}

- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    //UIGraphicsBeginImageContext(newSize);
    // In next line, pass 0.0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
    // Pass 1.0 to force exact pixel size.
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

// tap the share icon
-(void) shareTap
{
    
    UIImage* backImg = [UIImage imageNamed:@"sharebig.png"];
    
    UIImage* bandImg = nil; // [viewController getBandImage:0];
    //    NSLog(@"band height %f", bandImg.size.height);
    
    // combine
    CGSize size = CGSizeMake(backImg.size.width, backImg.size.height);
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)])
    {
        UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
    } else {
        UIGraphicsBeginImageContext(size);
    }
    
    CGPoint point = CGPointMake(0, 0);
    [backImg drawAtPoint:point];
    
    for (int i=0; i<12; i++) {
        bandImg = [viewController getBandImage:i];
        point = CGPointMake(18.0/2, 90.0/2+bandImg.size.height*i);
        [bandImg drawAtPoint:point];
    }
    
    UIImage* shareImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    float maxHeight = 1080.0/2;
    CGSize s = CGSizeMake(shareImage.size.width/(shareImage.size.height/maxHeight), maxHeight);
    shareImage = [self imageWithImage:shareImage scaledToSize:s];
    
    // share it
    
    // save image
    NSData *compressedImage = UIImageJPEGRepresentation(shareImage, 0.90 );
    NSString *docsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *imagePath = [docsPath stringByAppendingPathComponent:@"badsign.jpg"];
    NSURL *imageUrl     = [NSURL fileURLWithPath:imagePath];
    [compressedImage writeToURL:imageUrl atomically:YES]; // save the file
    
    NSString *shareString = @"Check out all Your signs using Bad Sing app...";
    
    NSURL *shareUrl = [NSURL URLWithString:kAppStoreURL];
    
    NSArray *activityItems = [NSArray arrayWithObjects:shareString, imageUrl, shareUrl, nil];
    
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    activityViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [activityViewController setValue:@"Bad Sign" forKey:@"subject"]; // email subject
    
    /*
     [activityViewController setCompletionHandler:^(NSString *act, BOOL done)
     {
     if ( done )
     {

     }
     else
     {
     // didn't succeed.
     }
     }];
     */
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self->shareView.hidden = NO;
        self->activityIndicator.hidden = YES;
        [self->activityIndicator stopAnimating];
        
        [self->viewController refresh];
        
        [self->navController presentViewController:activityViewController animated:YES completion:nil];
        
    });
    
}

-(void) dateTimeTap:(UITapGestureRecognizer*) recognizer {
    // NSLog(@"dateTimeTap");
    
    if (!activityIndicator.hidden) {
        return;
    }
    
    if (recognizer.state == UIGestureRecognizerStateRecognized) {
        CGPoint p = [recognizer locationInView:recognizer.view];
        // NSLog(@"dateTimeTap %fx%f", p.x, p.y);
        if (p.x > (dateLabel.frame.size.width+20.0)) {
            // share
            shareView.hidden = YES;
            activityIndicator.hidden = NO;
            [activityIndicator startAnimating];
            
            [viewController closeCells];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                [self shareTap];
            });
            
            
        } else {
            datePicker.hidden = !datePicker.hidden;
            //timePicker.hidden = YES;
            
            if (datePicker.hidden) {
                viewController.view.hidden = NO;
                viewController.view.userInteractionEnabled = YES;
                
                backTap.enabled = NO;
                statsView.hidden = YES;
                
            } else {
                backTap.enabled = YES;
                statsView.hidden = NO;
                
                viewController.view.userInteractionEnabled = NO;
                viewController.view.hidden = YES;
            }
            
        }
        [self dateChanged:self];
        // [self timeChanged:self];
    }
    
}

- (NSDate *)combineDate:(NSDate *)date withTime:(NSDate *)time {
    
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    
    unsigned unitFlagsDate = NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay;
    NSDateComponents *dateComponents = [gregorian components:unitFlagsDate fromDate:date];
    unsigned unitFlagsTime = NSCalendarUnitHour | NSCalendarUnitMinute |  NSCalendarUnitSecond;
    NSDateComponents *timeComponents = [gregorian components:unitFlagsTime fromDate:time];
    
    [dateComponents setSecond:[timeComponents second]];
    [dateComponents setHour:[timeComponents hour]];
    [dateComponents setMinute:[timeComponents minute]];
    
    NSDate *combDate = [gregorian dateFromComponents:dateComponents];
    
    // [gregorian release];
    
    return combDate;
}





-(void) updateStats
{
    // NSLog(@"updateStats");
    
    if (datePicker.date == nil) return;
    //if (timePicker.date == nil) return;
    
    
    
    // update stats display
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateStyle = NSDateFormatterFullStyle;
    
    NSDate* now = [NSDate date];
    //    NSDate* birtday = [self combineDate:datePicker.date withTime:timePicker.date];
    NSDate* birtday = datePicker.date;
    
    // save date
    [[NSUserDefaults standardUserDefaults] setObject:birtday forKey:@"birtday"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    labStat1.text = [NSString stringWithFormat:@"%@", [df stringFromDate:birtday]];
    
    labStat2.text = [NSString stringWithFormat:@"Time difference from today (%@):", [df stringFromDate: now]];
    
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:birtday toDate:now options:0];
    
    int day = (int)[components day];
    NSString * day_desc = @"day";
    if (day != 1) day_desc = @"days";
    
    int month = (int)[components month];
    NSString * month_desc = @"month";
    if (month != 1) month_desc = @"months";
    
    int year = (int)[components year];
    NSString * year_desc = @"year";
    if (year != 1) year_desc = @"years";
    
    labStat3.text = [NSString stringWithFormat:@"%i %@ %i %@ %i %@", year,year_desc,month,month_desc,day,day_desc];
    [labStat3 sizeToFit];
    CGRect frame = labStat3_ago.frame;
    frame.origin.x = labStat3.frame.origin.x+labStat3.frame.size.width+5.0;
    labStat3_ago.frame = frame;
    
    
    components = [[NSCalendar currentCalendar] components:NSCalendarUnitWeekOfYear | NSCalendarUnitDay fromDate:birtday toDate:now options:0];
    
    day = (int)[components day];
    day_desc = @"day";
    if (day != 1) day_desc = @"days";
    
    int week = (int)[components weekOfYear];
    NSString * week_desc = @"week";
    if (week != 1) week_desc = @"weeks";
    
    labStat4.text = [NSString stringWithFormat:@"%i %@ %i %@", week,week_desc,day,day_desc];
    [labStat4 sizeToFit];
    frame = labStat4_ago.frame;
    frame.origin.x = labStat4.frame.origin.x+labStat4.frame.size.width+5.0;
    labStat4_ago.frame = frame;
    
    // lab 5
    components = [[NSCalendar currentCalendar] components: NSCalendarUnitDay  fromDate:birtday toDate:now options:0];
    day = (int)[components day];
    day_desc = @"day";
    if (day != 1) day_desc = @"days";
    
    labStat5.text = [NSString stringWithFormat:@"%i %@",day,day_desc];
    [labStat5 sizeToFit];
    frame = labStat5_ago.frame;
    frame.origin.x = labStat5.frame.origin.x+labStat5.frame.size.width+5.0;
    labStat5_ago.frame = frame;
    
    // lab 6
    components = [[NSCalendar currentCalendar] components: NSCalendarUnitDay | NSCalendarUnitYear fromDate:birtday toDate:now options:0];
    
    day = (int)[components day];
    year = (int)[components year];
    year_desc = @"year";
    if (year != 1) year_desc = @"years";
    
    labStat6.text = [NSString stringWithFormat:@"%g %@",year+(1.0*day/365),year_desc];
    [labStat6 sizeToFit];
    frame = labStat6_ago.frame;
    frame.origin.x = labStat6.frame.origin.x+labStat6.frame.size.width+5.0;
    labStat6_ago.frame = frame;
    
    // moon
    Signs * mp = [[Signs alloc] initWithDate:birtday];
    
    float moonPhase = roundf([mp phase] * 100);
    // NSLog(@"moon phase: %f",moonPhase);
    if ((moonPhase >= 98.0) || (moonPhase <= 2.0)) {
        [moonView setImage:[UIImage imageNamed:@"moon0"]];
        labStat_moon.text = @"New Moon";
    }
    if ((moonPhase >= 3.0) && (moonPhase <= 23.0)) {
        [moonView setImage:[UIImage imageNamed:@"moon1"]];
        labStat_moon.text = @"Young Crescent";
    }
    if ((moonPhase >= 24.0) && (moonPhase <= 26.0)) {
        [moonView setImage:[UIImage imageNamed:@"moon2"]];
        labStat_moon.text = @"First Quarter";
    }
    if ((moonPhase >= 27.0) && (moonPhase <= 47.0)) {
        [moonView setImage:[UIImage imageNamed:@"moon3"]];
        labStat_moon.text = @"Waxing Gibbous";
    }
    if ((moonPhase >= 48.0) && (moonPhase <= 52.0)) {
        [moonView setImage:[UIImage imageNamed:@"moon4"]];
        labStat_moon.text = @"Full Moon";
    }
    if ((moonPhase >= 53.0) && (moonPhase <= 73.0)) {
        [moonView setImage:[UIImage imageNamed:@"moon5"]];
        labStat_moon.text = @"Waning Gibbous";
    }
    if ((moonPhase >= 74.0) && (moonPhase <= 76.0)) {
        [moonView setImage:[UIImage imageNamed:@"moon6"]];
        labStat_moon.text = @"Last Quarter";
    }
    if ((moonPhase >= 77.0) && (moonPhase <= 97.0)) {
        [moonView setImage:[UIImage imageNamed:@"moon7"]];
        labStat_moon.text = @"Old Crescent";
    }
    // 98-2% - new moon
    // 3-23% - Waxing (young)'crescent moon'
    // 24-26% - First quarter
    // 17-47% - Waxing 'gibbous moon'
    // 48-52% - full moon
    // 53-73% - Waning 'gibbous moon'
    // 74-76% - Last (third) quarter moon
    // 77-97% - Waning (old) crescent moon
    
    // NSDate *methodStart = [NSDate date];
    
    [viewController calculateSigns:birtday];
    
    // NSDate *methodFinish = [NSDate date];
    // NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
    // timeLabel.text = [NSString stringWithFormat:@"%lims", lround(executionTime*1000)];
}

-(void) dateChanged:(id) sender {
    NSString * sufix  = @"";
    if (!datePicker.hidden) {
        sufix = @"\u2713";
    }
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateStyle = NSDateFormatterLongStyle;
    dateLabel.text = [NSString stringWithFormat:@"%@ %@",
                      [df stringFromDate:datePicker.date],sufix];
    // Debounce: cancel any pending update and reschedule.
    // This prevents calculateSigns from being called on every wheel tick.
    [datePickerTimer invalidate];
    datePickerTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                      target:self
                                                    selector:@selector(updateStats)
                                                    userInfo:nil
                                                     repeats:NO];
}

/*
 -(void) timeChanged:(id) sender {
 
 NSString * prefix  = @"";
 if (!timePicker.hidden) {
 prefix = @"\u2713";
 }
 
 NSDateFormatter *df = [[NSDateFormatter alloc] init];
 // df.dateStyle = NSDateFormatterMediumStyle;
 df.timeStyle = NSDateFormatterShortStyle;
 [df setTimeZone:[NSTimeZone localTimeZone]];
 timeLabel.text = [NSString stringWithFormat:@"%@ %@", prefix,[df stringFromDate:timePicker.date]];
 [self updateStats];
 }
 */
-(void) hidePickers {
    if ((!datePicker.hidden) /*|| (!timePicker.hidden)*/) {
        NSLog(@"hidePickers");
        
        viewController.view.hidden = NO;
        viewController.view.alpha = 0.0;
        
        
        [UIView animateWithDuration:0.15
                              delay:0.0
                            options: 0
                         animations:^{
            self->datePicker.alpha = 0.0;
            // timePicker.alpha = 0.0;
            self->statsView.alpha = 0.0;
            
            self->viewController.view.alpha = 1.0;
            
            [self dateChanged:nil];
            //[self timeChanged:nil];
        }
                         completion:^(BOOL finished){
            self->datePicker.hidden = YES;
            // timePicker.hidden = YES;
            self->statsView.hidden = YES;
            
            self->datePicker.alpha = 1.0;
            // timePicker.alpha = 1.0;
            self->statsView.alpha = 1.0;
            
            self->viewController.view.hidden = NO;
            
            [self dateChanged:nil];
            //[self timeChanged:nil];
            
            NSLog(@"Done!");
        }];
        
        
        viewController.view.userInteractionEnabled = YES;
        backTap.enabled = NO;
        
        // count used times
        uses_count++;
        
        if (uses_count > 4)
        {
            uses_count = -99;
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Rate Bad Sign"
                                                                           message:@"Please rate our app, ratings are the only way we can interact with users and we depend on them greatly..."
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Noooo" style:UIAlertActionStyleCancel handler:nil]];
            [alert addAction:[UIAlertAction actionWithTitle:@"Rate App" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                NSURL *theUrl = [NSURL URLWithString:kAppStoreRateURL];
                [[UIApplication sharedApplication] openURL:theUrl options:@{} completionHandler:nil];
            }]];
            [navController presentViewController:alert animated:YES completion:nil];
        }
        
    }
}

-(void) backTap:(UITapGestureRecognizer*) recognizer {
    NSLog(@"backTap");
    [self hidePickers];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    
    
    [[NSUserDefaults standardUserDefaults] setInteger:uses_count forKey:@"uses_count"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end

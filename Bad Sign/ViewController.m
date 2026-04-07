//
//  ViewController.m
//  Bad Sign
//
//  Created by admin on 12/8/13.
//  Copyright (c) 2013 Void Software. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
#import "Signs.h"



#import <QuartzCore/QuartzCore.h>


@interface WKWebView(SynchronousEvaluateJavaScript)
- (NSString *)stringByEvaluatingJavaScriptFromString:(NSString *)script;
@end

@implementation WKWebView(SynchronousEvaluateJavaScript)

- (NSString *)stringByEvaluatingJavaScriptFromString:(NSString *)script
{
    __block NSString *resultString = nil;
    __block BOOL finished = NO;

    [self evaluateJavaScript:script completionHandler:^(id result, NSError *error) {
        if (error == nil) {
            if (result != nil) {
                resultString = [NSString stringWithFormat:@"%@", result];
            }
        } else {
            NSLog(@"evaluateJavaScript error : %@", error.localizedDescription);
        }
        finished = YES;
    }];

    while (!finished)
    {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }

    return resultString;
}
@end


@interface ViewController ()

@end

@implementation ViewController

const double CELL_HEIGHT = 85.0f;

int rowSelected, secSelected;
AppDelegate* delegate;

UIColor * backColor;

int old_rowSelected;



- (UIImage *)imageOfView:(UIView *)view
{
    
  
    // This if-else clause used to check whether the device support retina display or not so that
    // we can render image for both retina and non retina devices.
    
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)])
    {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, [UIScreen mainScreen].scale);
    } else {
        UIGraphicsBeginImageContext(view.bounds.size);
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (context == NULL) return nil;
    
    [view.layer renderInContext:context];
    
    UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return img;
}

- (NSString*) getHtml7z:(NSString*) fileName
{
    NSString *name = [fileName stringByDeletingPathExtension];
    NSLog(@"[HTML] looking for resource name='%@' type='html' inDirectory='SignAssets'", name);

    NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"html"
                                               inDirectory:@"SignAssets"];
    NSLog(@"[HTML] pathForResource result: %@", path ? path : @"(nil)");

    if (!path) {
        // Fallback: try direct path inside bundle
        NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
        NSString *directPath = [[[bundlePath stringByAppendingPathComponent:@"SignAssets"]
                                  stringByAppendingPathComponent:name]
                                 stringByAppendingPathExtension:@"html"];
        NSLog(@"[HTML] trying direct path: %@", directPath);
        BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:directPath];
        NSLog(@"[HTML] direct path exists: %@", exists ? @"YES" : @"NO");

        // Also log what's actually in SignAssets if we can find it
        NSString *signAssetsDir = [[NSBundle mainBundle] bundlePath];
        signAssetsDir = [signAssetsDir stringByAppendingPathComponent:@"SignAssets"];
        BOOL dirExists = [[NSFileManager defaultManager] fileExistsAtPath:signAssetsDir];
        NSLog(@"[HTML] SignAssets dir exists in bundle: %@", dirExists ? @"YES" : @"NO");
        if (dirExists) {
            NSArray *contents = [[NSFileManager defaultManager]
                                 contentsOfDirectoryAtPath:signAssetsDir error:nil];
            NSLog(@"[HTML] SignAssets contents (%lu files): %@", (unsigned long)[contents count],
                  [[contents subarrayWithRange:NSMakeRange(0, MIN(5, [contents count]))] componentsJoinedByString:@", "]);
        } else {
            NSLog(@"[HTML] SignAssets NOT found — folder may not be added to Xcode target");
        }

        if (exists) {
            path = directPath;
        } else {
            return nil;
        }
    }

    NSData *data = [NSData dataWithContentsOfFile:path];
    NSLog(@"[HTML] read %lu bytes", (unsigned long)[data length]);
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (void) getPng7z:(NSString*) fileName out:(NSString*) fileNameOut
{
    NSString *srcName  = [NSString stringWithFormat:@"%@@2x", fileName];
    NSLog(@"[PNG] looking for resource name='%@' type='png' inDirectory='SignAssets'", srcName);

    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:srcName ofType:@"png"
                                                     inDirectory:@"SignAssets"];
    NSLog(@"[PNG] pathForResource result: %@", bundlePath ? bundlePath : @"(nil)");

    if (!bundlePath) {
        // Fallback: try direct path
        NSString *directPath = [[[[NSBundle mainBundle] bundlePath]
                                   stringByAppendingPathComponent:@"SignAssets"]
                                  stringByAppendingPathComponent:[NSString stringWithFormat:@"%@@2x.png", fileName]];
        NSLog(@"[PNG] trying direct path: %@", directPath);
        if ([[NSFileManager defaultManager] fileExistsAtPath:directPath]) {
            bundlePath = directPath;
        } else {
            NSLog(@"[PNG] not found anywhere, skipping");
            return;
        }
    }

    NSString *destPath = [NSTemporaryDirectory() stringByAppendingPathComponent:
                          [NSString stringWithFormat:@"%@@2x.png", fileNameOut]];
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:destPath]) [fm removeItemAtPath:destPath error:nil];
    NSError *copyErr = nil;
    [fm copyItemAtPath:bundlePath toPath:destPath error:&copyErr];
    if (copyErr) NSLog(@"[PNG] copy error: %@", copyErr);
    else NSLog(@"[PNG] copied to %@", destPath);
}


// Called once all preload webviews have finished — updates horData, reloads titles,
// and re-enables user interaction.
- (void)revealSignTitles
{
    if (pendingSignIndices == nil) return;
    NSMutableArray *secNumArr = [horData objectAtIndex:0];
    for (int i = 0; i < 12; i++) {
        [secNumArr replaceObjectAtIndex:i withObject:pendingSignIndices[i]];
    }
    pendingSignIndices = nil;
    NSLog(@"[DIAG] revealSignTitles — reloadData + enabling interaction");
    [tableView reloadData];
    tableView.userInteractionEnabled = YES;
}

// Preload all 12 sign HTML pages into off-screen WKWebViews so the first tap is instant.
- (void)preloadAllWebViews
{
    // Create (or reuse) an off-screen container that is never visible to the user.
    if (!preloadContainer) {
        preloadContainer = [[UIView alloc] initWithFrame:CGRectMake(-screenWidth * 3, 0, screenWidth, 1)];
        preloadContainer.userInteractionEnabled = NO;
        preloadContainer.clipsToBounds = YES;
        [self.view addSubview:preloadContainer];
    }
    // Remove any webviews from a previous date selection.
    for (UIView *v in [preloadContainer.subviews copy]) [v removeFromSuperview];
    [preloadedWebViews removeAllObjects];

    NSURL *baseURL  = [[NSBundle mainBundle] bundleURL];
    NSMutableArray *secHtmlArr = [htmlData objectAtIndex:0];

    preloadPendingCount = 0;
    for (int i = 0; i < 12; i++) {
        NSString *html = [secHtmlArr objectAtIndex:i];
        if (!html || [html length] == 0) {
            [preloadedWebViews addObject:[NSNull null]];
            continue;
        }
        preloadPendingCount++;
        WKWebView *wv = [self defWV];
        // Lay them out vertically inside the off-screen container so each
        // has a real frame and WKWebView actually renders.
        wv.frame = CGRectMake(0, i * 2000, screenWidth, 50);
        wv.tag = 2000 + i;   // distinct from 1001 used by the expanded cell
        [preloadContainer addSubview:wv];
        [wv loadHTMLString:html baseURL:baseURL];
        [preloadedWebViews addObject:wv];
    }
    // Make the container just tall enough to hold all webviews.
    CGRect f = preloadContainer.frame;
    f.size.height = 12 * 2000 + 50;
    preloadContainer.frame = f;

    // Edge case: all HTML was empty — reveal titles immediately.
    if (preloadPendingCount == 0) {
        [self revealSignTitles];
    }
}

// create default WebView
- (WKWebView*) defWV
{
    WKWebView * webView1 = [[WKWebView alloc] initWithFrame:CGRectMake(0,0, screenWidth, 50.0)];
    webView1.autoresizingMask = 0; // UIViewAutoresizingFlexible ; // |UIViewAutoresizingFlexibleWidth;
    webView1.tag = 1001;
    webView1.userInteractionEnabled = NO;
    webView1.opaque = NO;
    webView1.backgroundColor = [UIColor clearColor];
    webView1.scrollView.backgroundColor = [UIColor clearColor];
    webView1.hidden = NO;
    // webView1.scalesPageToFit = NO;
//    [webView1 setDelegate:self];
    [webView1 setNavigationDelegate:self];
    
    //    [webView1 loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"help" ofType:@"html"] isDirectory:NO]]];
    //  [cellWeb addSubview:webView1];
    return webView1;
}

-(void) socialBandTap:(UITapGestureRecognizer*) recognizer {
    NSLog(@"socialBandTap");
    if (recognizer.state == UIGestureRecognizerStateRecognized) {
        
        CGPoint touchPoint = [recognizer locationInView: recognizer.view];
        
        if (touchPoint.x > 200.0) {
            // goto void homepage
            // NSURL *url = [NSURL URLWithString:@"http://voidsoft.tumblr.com"];
			// NSURL *url = [NSURL URLWithString:@"https://m.facebook.com/VoidSoftware"];
            NSURL *url = [NSURL URLWithString:@"fb://profile/129832637067081"];
            
            /*
            if (![[UIApplication sharedApplication] openURL:url]) {
               // NSLog(@"%@%@",@"Failed to open url:",[url description]);
            }
            */
            if ([[UIApplication sharedApplication] canOpenURL:url]) {
                [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
            } else {
                //fanPageURL failed to open.  Open the website in Safari instead
                NSURL *webURL = [NSURL URLWithString:@"https://m.facebook.com/VoidSoftware"];
                [[UIApplication sharedApplication] openURL:webURL options:@{} completionHandler:nil];
            }
        } else {
        
        // create share image
        
        // title
        NSIndexPath * indexPath =[NSIndexPath indexPathForRow:rowSelected inSection:secSelected];
        [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
        UITableViewCell *cell =  [tableView cellForRowAtIndexPath:indexPath];
        UIImage * titleImg = [self imageOfView:cell];
        
        // web body
        indexPath =[NSIndexPath indexPathForRow:rowSelected+1 inSection:secSelected];
        // [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
        cell =  [tableView cellForRowAtIndexPath:indexPath];
        UIImage * webvImg = [self imageOfView:cell];
        
        // combine
        CGSize size = CGSizeMake(titleImg.size.width, titleImg.size.height+webvImg.size.height);
        if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)])
        {
            UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
        } else {
            UIGraphicsBeginImageContext(size);
        }
        CGPoint point = CGPointMake(0, 0);
        [titleImg drawAtPoint:point];
        point = CGPointMake(0, titleImg.size.height);
        [webvImg drawAtPoint:point];
        UIImage* shareImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        // save image
        NSData *compressedImage = UIImageJPEGRepresentation(shareImage, 0.90 );
        NSString *docsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *imagePath = [docsPath stringByAppendingPathComponent:@"badsign.jpg"];
        NSURL *imageUrl     = [NSURL fileURLWithPath:imagePath];
        [compressedImage writeToURL:imageUrl atomically:YES]; // save the file
        
        NSNumber * index = (NSNumber*) [[horData objectAtIndex:secSelected] objectAtIndex:rowSelected];
        NSString * name = (NSString*) [[[tableSubData objectAtIndex:secSelected] objectAtIndex:rowSelected] objectAtIndex:[index intValue]];
        NSString * name_astr = [[tableData objectAtIndex:secSelected] objectAtIndex:rowSelected];
        NSString *shareString = [NSString stringWithFormat:@"I am reading about the ""%@"" in ""%@"" using Bad Sing app...",name,name_astr];
        
      //  NSString *shareString = @"I am reading about the %@ in "%@" using Bad Sing app...just found out that I was born in is using Bad Sing...";
        // UIImage *shareImage = titleImg; // [UIImage imageNamed:@"aquarius.png"];
        NSURL *shareUrl = [NSURL URLWithString:kAppStoreURL];
        
        NSArray *activityItems = [NSArray arrayWithObjects:shareString, imageUrl, shareUrl, nil];
        
        UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
        activityViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [activityViewController setValue:@"Bad Sign" forKey:@"subject"]; // email subject
        
        activityViewController.completionWithItemsHandler = ^(UIActivityType act, BOOL done, NSArray *returnedItems, NSError *activityError)
         {
             
             /*
             NSLog(@"act type %@",act);
             NSString *ServiceMsg = nil;
             if ( [act isEqualToString:UIActivityTypeMail] )           ServiceMsg = @"Mail sent";
             if ( [act isEqualToString:UIActivityTypePostToTwitter] )  ServiceMsg = @"Post on twitter, ok!";
             if ( [act isEqualToString:UIActivityTypePostToFacebook] ) ServiceMsg = @"Post on facebook, ok!";
             */
             
             if ( done )
             {
             }
             else
             {
                 // didn't succeed.
             }
         };
        
        [self presentViewController:activityViewController animated:YES completion:nil];
        
        }
        
    }
}

-(UIImage*) getBandImage:(int) bandIndex
{
    __block UIImage *titleImg = nil;
    dispatch_block_t block = ^{
        NSIndexPath * indexPath = [NSIndexPath indexPathForRow:bandIndex inSection:0];
        [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        titleImg = [self imageOfView:cell];
    };
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
    return titleImg;
}

-(void) refresh
{
    [tableView reloadData];
    
    NSIndexPath * indexPath =[NSIndexPath indexPathForRow:0 inSection:0];
    [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
}


// create default social band
- (UIView*) defSV:(CGRect) frame
{
    UIView* socialBandView = [[UIView alloc] initWithFrame:frame];
    socialBandView.backgroundColor = [UIColor colorWithRed:240.0/255 green:240.0/255 blue:237.0/255 alpha:1.0];
    socialBandView.tag = 1007;
    
    UIImageView * fbView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"share.png"]];
    [fbView setCenter:CGPointMake(32.5, 26.5)];
    [socialBandView addSubview:fbView];
    
    
    UIImageView * voidView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"void.png"]];
    [voidView setCenter:CGPointMake(screenWidth-40.0, 26.5)];
    [socialBandView addSubview:voidView];

    socialBandView.userInteractionEnabled = YES;
    UITapGestureRecognizer *socialTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(socialBandTap:)];
    socialTap.numberOfTapsRequired = 1;
    [socialBandView addGestureRecognizer:socialTap];

    return socialBandView;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        screenWidth = [[UIScreen mainScreen] bounds].size.width;
        

        
        backColor = [UIColor whiteColor];
        //[UIColor colorWithRed:24.0/255 green:36.0/255 blue:50.0/255 alpha:1.0];
        
        // Custom initialization
        tableSections  = [NSArray arrayWithObjects:@"Classic"/*, @"Historic",@"Fantasy"*/, nil];
        
        tableData = [NSArray arrayWithObjects:
                     [NSArray arrayWithObjects:@"Western Astrology", @"Chinese Astrology",@"Aztec Astrology",@"Mayan Astrology", @"Egyptian Astrology", @"Zoroastrian Astrology", @"Celtic Astrology", @"Norse Astrology", @"Slavic Astrology", @"Numerology", @"Geek Astrology", @"Bad Sign", nil],
                     nil];
        
        tableSubData = [NSArray arrayWithObjects:
                        [NSArray arrayWithObjects:
                         // Western Astrology
                         [NSArray arrayWithObjects:@"Aries", @"Taurus", @"Gemini",@"Cancer", @"Leo", @"Virgo", @"Libra", @"Scorpio", @"Sagittarius", @"Capricorn", @"Aquarius", @"Pisces", nil],
                         
                         // Chinesse
                         [NSArray arrayWithObjects:@"Rat", @"Oxen", @"Tiger",@"Rabbit", @"Dragon", @"Snake", @"Horse", @"Sheep", @"Monkey", @"Rooster", @"Dog", @"Pig", nil],
                         
                         // Aztec Astrology
                         [NSArray arrayWithObjects:@"Crocodile", @"Wind", @"House",@"Lizard", @"Snake", @"Death", @"Deer", @"Rabbit", @"Water", @"Dog", @"Monkey", @"Grass", @"Reed", @"Ocelot", @"Eagle", @"Vulture", @"Motion", @"Flint Knife", @"Rain", @"Flower", nil],
                         
                         // Maya Astrology
                         [NSArray arrayWithObjects:@"Crocodile", @"Wind", @"House",@"Lizard", @"Serpent", @"Death", @"Deer", @"Rabbit", @"Water", @"Dog", @"Monkey", @"Grass", @"Reed", @"Jaguar", @"Eagle", @"Vulture", @"Earth", @"Knife", @"Storm", @"Sun", nil],
                         
                         // Egyptian Astrology
                         [NSArray arrayWithObjects:@"Thoth", @"Horus", @"Wadjet",@"Sekhmet", @"Sphinx", @"Shu", @"Isis", @"Osiris", @"Amun", @"Hathor", @"Phoenix", @"Anubis", nil],
                         
                         // Zoroasto Astrology
                         [NSArray arrayWithObjects:@"Deer", @"Ram", @"Mongoose", @"Wolf", @"Stork", @"Spider", @"Snake", @"Beaver", @"Turtle", @"Magpie", @"Squirrel ", @"Raven", @"Rooster", @"Bull", @"Badger", @"Camel", @"Hedgehog", @"Fallow Deer", @"Elephant", @"Horse", @"Cheetah", @"Peacock", @"Swan", @"Lynx", @"Donkey", @"Polar Bear", @"Eagle", @"Fox", @"Dolphin", @"Wild Boar", @"Owl", @"Falcon", nil],
                         
                         // Celtic Astrology
                         [NSArray arrayWithObjects:@"Birch", @"Rowan", @"Ash",@"Alder", @"Willow", @"Hawthorn", @"Oak", @"Holly", @"Hazel", @"Vine", @"Ivy", @"Reed", @"Elder", nil],
                         
                         // Norse Astrology
                         [NSArray arrayWithObjects:@"Ullr", @"Thor", @"Vali",@"Saga", @"Odin", @"Skadi", @"Baldr", @"Heimdall", @"Freya", @"Forseti", @"Njord", @"Vidar", nil],

                         // Slavic Astrology - svarog
                        [NSArray arrayWithObjects:@"Yarilo", @"Lada", @"Kostroma", @"Dodola", @"Veles", @"Kupalo", @"Dazhdbog", @"Mokosh", @"Svarozich", @"Morena", @"Semargl", @"Perun", @"Stribog", @"Svarog", @"Vesna", nil],
                         
                         // Numerology
                         [NSArray arrayWithObjects:@"Number", @"Number", @"Number", @"Number", @"Number", @"Number", @"Number", @"Number", @"Number", @"Number", @"Number",  nil],

                          // Geek
                         [NSArray arrayWithObjects:@"Robot", @"Wizard", @"Alien", @"Superhero", @"Slayer", @"Pirate", @"Daikaiju", @"Time Traveler", @"Spy", @"Astronaut", @"Samurai", @"Explorer", nil],

                          // Nash
                         [NSArray arrayWithObjects:@"Zmay", @"Alla", @"Bauk", @"Usud", @"Veshticca", @"Lesnik", @"Psoglav", @"Zduhach", @"Babaroga", @"Villa", @"Malich", @"Talason", nil],						 
						 
                         nil],
                        
                        nil];
        
        /*
         tableData = [NSArray arrayWithObjects:
         [NSArray arrayWithObjects:@"Western Astrology", @"Indian Astrology", @"Chinese Astrology",@"Mayan Astrology", @"Aztec Astrology", @"...", nil],
         [NSArray arrayWithObjects:@"Roman Astrology", @"Egyptian Astrology", @"Celtic Astrology", @"Slavic Astrology", @"Greek Astrology", nil],
         [NSArray arrayWithObjects:@"Geek Astrology", @"D&D Astrology", nil],
         nil];
         */
        
        tableColors = [NSArray arrayWithObjects:
                       [UIColor colorWithRed:231.0/255 green:21.0/255 blue:29.0/255 alpha:1.0],
                       [UIColor colorWithRed:236.0/255 green:67.0/255 blue:27.0/255 alpha:1.0],
                       [UIColor colorWithRed:240.0/255 green:116.0/255 blue:29.0/255 alpha:1.0],
                       [UIColor colorWithRed:248.0/255 green:173.0/255 blue:21.0/255 alpha:1.0],
                       [UIColor colorWithRed:244.0/255 green:225.0/255 blue:29.0/255 alpha:1.0],
                       [UIColor colorWithRed:136.0/255 green:186.0/255 blue:45.0/255 alpha:1.0],
                       
                       [UIColor colorWithRed:23.0/255 green:155.0/255 blue:57.0/255 alpha:1.0],
                       [UIColor colorWithRed:11.0/255 green:162.0/255 blue:200.0/255 alpha:1.0],
                       [UIColor colorWithRed:0.0/255 green:102.0/255 blue:178.0/255 alpha:1.0],
                       [UIColor colorWithRed:29.0/255 green:37.0/255 blue:124.0/255 alpha:1.0],
                       [UIColor colorWithRed:103.0/255 green:37.0/255 blue:126.0/255 alpha:1.0],
                       [UIColor colorWithRed:208.0/255 green:13.0/255 blue:103.0/255 alpha:1.0],
                       
                       nil];
        
        tableColorsUp = [NSArray arrayWithObjects:
                         [UIColor colorWithRed:235.0/255 green:63.0/255 blue:57.0/255 alpha:1.0],
                         [UIColor colorWithRed:240.0/255 green:101.0/255 blue:31.0/255 alpha:1.0],
                         [UIColor colorWithRed:247.0/255 green:150.0/255 blue:41.0/255 alpha:1.0],
                         [UIColor colorWithRed:251.0/255 green:205.0/255 blue:63.0/255 alpha:1.0],
                         [UIColor colorWithRed:245.0/255 green:233.0/255 blue:116.0/255 alpha:1.0],
                         [UIColor colorWithRed:196.0/255 green:214.0/255 blue:65.0/255 alpha:1.0],
                         
                         [UIColor colorWithRed:139.0/255 green:193.0/255 blue:93.0/255 alpha:1.0],
                         [UIColor colorWithRed:173.0/255 green:216.0/255 blue:221.0/255 alpha:1.0],
                         [UIColor colorWithRed:116.0/255 green:190.0/255 blue:232.0/255 alpha:1.0],
						 [UIColor colorWithRed:65.0/255 green:98.0/255 blue:166.0/255 alpha:1.0],
                         [UIColor colorWithRed:150.0/255 green:84.0/255 blue:152.0/255 alpha:1.0],
                         [UIColor colorWithRed:216.0/255 green:53.0/255 blue:128.0/255 alpha:1.0],
                         
                         nil];
        
        rowSelected = -99;
        tableView = nil;
        delegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
        
        // init cells
        cells = [[NSMutableArray alloc] init];
        webViews = [[NSMutableArray alloc] init];
        
        // insert sections
        int ofset;
        for (int i=0; i<[tableSections count]; i++) {
            NSMutableArray * secCellArr = [[NSMutableArray alloc] init];
            NSMutableArray * secWebArr = [[NSMutableArray alloc] init];
            
            NSMutableArray * secArr = [tableData objectAtIndex:i];
            for (int a=0; a<[secArr count]; a++) {
                NSString *CellIdentifier = [NSString stringWithFormat:@"cell_%d_%d",i,a];
                // cell
                UITableViewCell * cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.hidden = NO;
                cell.autoresizesSubviews = NO;
                cell.autoresizingMask = UIViewAutoresizingNone;
                
                UIView* upBandView = [[UIView alloc] initWithFrame:CGRectMake(0,0, screenWidth, 27.0)];
                upBandView.backgroundColor = [UIColor colorWithRed:223.0/255 green:82.0/255 blue:72.0/255 alpha:1.0];
                upBandView.tag = 1002;
                [cell.contentView addSubview:upBandView];
                
                UIView * mainBandView = [[UIView alloc] initWithFrame:CGRectMake(0,27.0, screenWidth, 57.5)];
                mainBandView.backgroundColor = [UIColor colorWithRed:219.0/255 green:41.0/255 blue:37.0/255 alpha:1.0];
                mainBandView.tag = 1003;
                [cell.contentView addSubview:mainBandView];
                
                 ofset = 2.0;
                
                UILabel * labUp = [[UILabel alloc] initWithFrame:CGRectMake(15.0, ofset, screenWidth-15.0, 27.0)];
                labUp.backgroundColor = [UIColor clearColor];
                [labUp setFont:[UIFont fontWithName:@"Helvetica Neue LT Com" size:18.0]];
                labUp.textColor = [UIColor whiteColor];
                labUp.tag = 1004;
                //[lab setCenter:mainBandView.center];
                [upBandView addSubview:labUp];
                
                ofset = 4.0;
                
                UILabel * labMain = [[UILabel alloc] initWithFrame:CGRectMake(15.0, ofset, screenWidth-15.0, 57.5)];
                labMain.backgroundColor = [UIColor clearColor];
                [labMain setFont:[UIFont fontWithName:@"Helvetica Neue LT Com" size:36.0]];
                labMain.textColor = [UIColor whiteColor];
                labMain.tag = 1005;
                //[lab setCenter:mainBandView.center];
                [mainBandView addSubview:labMain];
                
                UIImageView * imgRight = [[UIImageView alloc] initWithFrame:CGRectMake(screenWidth-(320.0-258.0), 4.5, 48.0, 48.0)];
                imgRight.tag = 1006;
                [mainBandView addSubview:imgRight];
                
                [secCellArr addObject:cell];
                
                // webView
                NSString *CellIdentifier2 = [NSString stringWithFormat:@"web_%d_%d",i,a];
                UITableViewCell * cellWeb = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier2];
                cellWeb.selectionStyle = UITableViewCellSelectionStyleNone;
                cellWeb.hidden = NO;
                cellWeb.autoresizesSubviews = NO;
                cellWeb.autoresizingMask = UIViewAutoresizingNone;
                
                /*
                 UIWebView * webView1 = [[UIWebView alloc] initWithFrame:CGRectMake(0,0, 320.0, 50.0)];
                 webView1.autoresizingMask = 0; // UIViewAutoresizingFlexible ; // |UIViewAutoresizingFlexibleWidth;
                 webView1.tag = 1001;
                 webView1.userInteractionEnabled = NO;
                 webView1.opaque = NO;
                 webView1.backgroundColor = [UIColor clearColor];
                 webView1.hidden = NO;
                 webView1.scalesPageToFit = NO;
                 [webView1 setDelegate:self];
                 [webView1 loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"help" ofType:@"html"] isDirectory:NO]]];
                 [cellWeb addSubview:webView1];
                 */
                
                /*
                UIWebView * webView1 = [self defWV];
                [webView1 loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"help" ofType:@"html"] isDirectory:NO]]];
                [cellWeb addSubview:webView1];
                */
                
                cellWeb.backgroundColor = [UIColor whiteColor];
                cellWeb.contentView.backgroundColor = [UIColor whiteColor];

                UIView* socialBandView = [self defSV:CGRectMake(0,0, screenWidth, 55.0)];
                
                [cellWeb addSubview:socialBandView];
                
                [secWebArr addObject:cellWeb];
                
                
                
            }
            [cells addObject:secCellArr];
            [webViews addObject:secWebArr];
            
        }
        
        // calculated horospe indexes
        horData = [[NSMutableArray alloc] init];
        htmlData = [[NSMutableArray alloc] init];
        webHeights = [[NSMutableArray alloc] init];
        for (int i=0; i<[tableSections count]; i++) {
            NSMutableArray * secNumArr = [[NSMutableArray alloc] init];
            NSMutableArray * secHtmlArr = [[NSMutableArray alloc] init];
            NSMutableArray * secHeightsArr = [[NSMutableArray alloc] init];
            
            NSMutableArray * secArr = [tableData objectAtIndex:i];
            for (int a=0; a<[secArr count]; a++) {
                [secNumArr addObject:[NSNull null]]; // unknown until calculateSigns:
                [secHtmlArr addObject:@""];
                [secHeightsArr addObject:@(0.0)];
            }
            
            [horData addObject:secNumArr];
            [htmlData addObject:secHtmlArr];
            [webHeights addObject:secHeightsArr];
        }
        
        // iad
        /*
        ADBannerView *adView = [[ADBannerView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height -44, 320, 50)];
        adView.delegate = self;
        [self.view addSubview:adView];
        */
        
        last_birthday = nil;
        
        preloadedWebViews = [[NSMutableArray alloc] init];
        preloadContainer  = nil;
        
        tw = nil;
    }
    return self;
}

-(void) releaseExpandedWebView
{
    // Remove the WKWebView from the previously-expanded web cell to free its process.
    if (old_rowSelected >= 0) {
        UITableViewCell *webCell = [[webViews objectAtIndex:secSelected] objectAtIndex:old_rowSelected];
        WKWebView *wv = (WKWebView*)[webCell viewWithTag:1001];
        [wv removeFromSuperview];
    }
}

-(void) closeCells
{
    // close if opened
    if (rowSelected >= 0) {
        old_rowSelected = rowSelected;
        
        [tableView beginUpdates];
        
        // delete webview row from table
        NSArray * delArr = [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:old_rowSelected+1 inSection:secSelected], nil];
        [tableView deleteRowsAtIndexPaths:delArr withRowAnimation:UITableViewRowAnimationNone];
        
        rowSelected = -99;
        
        [tableView endUpdates];
        
        // Free the WKWebView process — it's no longer visible
        [self releaseExpandedWebView];
    }
}

-(void) calculateSigns:(NSDate*) birthday
{
    if (birthday == nil) return;
    if (last_birthday != nil)
        if (ABS([last_birthday timeIntervalSinceDate:birthday]) <= 30.0) // 30 sec diff
            return;
    
    NSLog(@"** calculateSigns");
    NSDate *_diagStart = [NSDate date];
#define DIAG_LOG(label, val) NSLog(@"[DIAG] %@ %i (%.3fs)", label, val, -[_diagStart timeIntervalSinceNow])
    
    [self closeCells];
    NSLog(@"[DIAG] closeCells done (%.3fs)", -[_diagStart timeIntervalSinceNow]);

    // Reset horData to NSNull so old titles are cleared immediately,
    // whether this is first launch or a date change.
    NSMutableArray *secNumArr = [horData objectAtIndex:0];
    for (int i = 0; i < (int)[secNumArr count]; i++) {
        [secNumArr replaceObjectAtIndex:i withObject:[NSNull null]];
    }
    [tableView reloadData];

    // Disable interaction — re-enabled in revealSignTitles once preloads complete
    tableView.userInteractionEnabled = NO;

    last_birthday = birthday;

    Signs * signs = [[Signs alloc] initWithDate:birthday];
    NSLog(@"[DIAG] Signs alloc done (%.3fs)", -[_diagStart timeIntervalSinceNow]);

    // Phase 1: calculate all sign indices (fast math, no I/O - stays on main thread)
    int bs_calc = 0;
    int s0  = [signs westernSign];    DIAG_LOG(@"westernSign",   s0);  bs_calc += s0;
    int s1  = [signs chineseSign];    DIAG_LOG(@"chineseSign",   s1);  bs_calc += s1;
    int s2  = [signs aztecSign];      DIAG_LOG(@"aztecSign",     s2);  bs_calc += s2;
    int s3  = [signs mayanSign];      DIAG_LOG(@"mayanSign",     s3);  bs_calc += s3;
    int s4  = [signs egyptianSign];   DIAG_LOG(@"egyptianSign",  s4);  bs_calc += s4;
    int s5  = [signs zoroastoSign];   DIAG_LOG(@"zoroastoSign",  s5);  bs_calc += s5;
    int s6  = [signs celticSign];     DIAG_LOG(@"celticSign",    s6);  bs_calc += s6;
    int s7  = [signs norseSign];      DIAG_LOG(@"norseSign",     s7);  bs_calc += s7;
    int s8  = [signs slavicSign];     DIAG_LOG(@"slavicSign",    s8);  bs_calc += s8;
    int s9  = [signs numerologySign]; DIAG_LOG(@"numerologySign",s9);  bs_calc += s9;
    int s10 = [signs geekSign];       DIAG_LOG(@"geekSign",      s10); bs_calc += s10;
    int s11 = bs_calc % 12;           DIAG_LOG(@"badSign",       s11);
#undef DIAG_LOG

    NSArray<NSNumber*> *signIndices = @[@(s0),@(s1),@(s2),@(s3),@(s4),@(s5),
                                        @(s6),@(s7),@(s8),@(s9),@(s10),@(s11)];

    // Phase 2: heavy LZMA extraction on a background thread so the main thread stays free
    NSLog(@"[DIAG] dispatching background LZMA work");
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDate *_bg = [NSDate date];
        NSLog(@"[DIAG] background thread started");

        NSMutableArray<NSString*> *htmlStrings = [NSMutableArray arrayWithCapacity:12];

        for (int i = 0; i < 12; i++) {
            int idx = [signIndices[i] intValue];
            [self getPng7z:[NSString stringWithFormat:@"%i-%i", i, idx]
                       out:[NSString stringWithFormat:@"%i", i]];
            NSString *html = [self getHtml7z:[NSString stringWithFormat:@"%i-%i.html", i, idx]];
            if (html != nil) {
                NSString *viewportMeta = @"<meta name='viewport' content='width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no' />";
                if ([html containsString:@"width=device-width"]) {
                    NSLog(@"[VIEWPORT] sign %i: already has device-width viewport, no change needed", i);
                } else if ([html containsString:@"<head>"]) {
                    NSLog(@"[VIEWPORT] sign %i: injecting viewport into <head>", i);
                    html = [html stringByReplacingOccurrencesOfString:@"<head>"
                                                          withString:[NSString stringWithFormat:@"<head>%@", viewportMeta]];
                } else if ([html containsString:@"<HEAD>"]) {
                    NSLog(@"[VIEWPORT] sign %i: injecting viewport into <HEAD>", i);
                    html = [html stringByReplacingOccurrencesOfString:@"<HEAD>"
                                                          withString:[NSString stringWithFormat:@"<HEAD>%@", viewportMeta]];
                } else {
                    NSLog(@"[VIEWPORT] sign %i: no <head> tag found, prepending viewport", i);
                    html = [viewportMeta stringByAppendingString:html];
                }
            } else {
                NSLog(@"[VIEWPORT] sign %i: html is nil", i);
            }
            [htmlStrings addObject:(html != nil ? html : @"")];
            NSLog(@"[DIAG] LZMA %i done (%.3fs)", i, -[_bg timeIntervalSinceNow]);
        }

        NSLog(@"[DIAG] all LZMA done (%.3fs), dispatching to main", -[_bg timeIntervalSinceNow]);
        // Phase 3: all UIKit work back on the main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"[DIAG] Phase 3 main thread start");
            NSMutableArray *secHtmlArr = [htmlData objectAtIndex:0];
            NSMutableArray *secHeightsArr = [webHeights objectAtIndex:0];
            for (int i = 0; i < 12; i++) {
                // Store HTML for lazy loading — do NOT create WKWebViews here
                [secHtmlArr replaceObjectAtIndex:i withObject:htmlStrings[i]];
                // Reset cached height — content is new
                [secHeightsArr replaceObjectAtIndex:i withObject:@(0.0)];
                // Remove any previously loaded WebView to free its process
                UITableViewCell *cell = [[webViews objectAtIndex:0] objectAtIndex:i];
                WKWebView *webView = (WKWebView*)[cell viewWithTag:1001];
                [webView removeFromSuperview];
            }
            // Hold sign indices — horData stays as NSNull (blank titles) until
            // all preload webviews have finished loading.
            pendingSignIndices = signIndices;
            NSLog(@"[DIAG] Phase 3 starting preload (titles revealed after)");
            // Pre-warm web views; titles + interaction restored in didFinishNavigation
            // once the last preload completes.
            [self preloadAllWebViews];
        });
    });
}

-(UIColor*) getColor:(NSIndexPath*) indexPath up:(BOOL) lUp
{
    
    int cnt = 0;
    for (int i=0; i<indexPath.section; i++) {
        cnt += [[tableData objectAtIndex:i] count];
    }
    
    cnt += indexPath.row;
    
    while (cnt >= [tableColors count]) {
        cnt -= [tableColors count];
    }
    
    if (lUp) {
        return [tableColorsUp objectAtIndex:cnt];
    } else {
        return [tableColors objectAtIndex:cnt];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
	return [tableSections count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray * sec = [tableData objectAtIndex:section];
    int cnt = (int)[sec count];
    if (secSelected == section) {
        if (rowSelected >= 0) {
            // clasic view
            cnt++;
        }
    }
    
    tw = tableView;
    
    // NSLog(@"rowCnt sec:%i cnt:%i",section,cnt);
	return cnt;
}

// main cell setup
- (void) setUpCell: (UITableViewCell *) cell forIndexPath:(NSIndexPath *)indexPath
{
    // NSLog(@"setupcell %i, %i", indexPath.row, indexPath.section);
    
    //UIWebView* webView2 = nil;
    UIView * upBandView = nil;
    UIView * mainBandView = nil;
    UILabel * labUp = nil;
    UILabel * labMain = nil;
    UIImageView * imgRight = nil;
    
    /*
     webView2 = (UIWebView*)[cell viewWithTag:1001];
     if (webView2 != nil) {
     //[[cell subviews] delete:webView2];
     [webView2 removeFromSuperview];
     webView2 = nil;
     }
     */
    upBandView = [cell viewWithTag:1002];
    mainBandView = [cell viewWithTag:1003];
    labUp = (UILabel*)[cell viewWithTag:1004];
    labMain = (UILabel*)[cell viewWithTag:1005];
    imgRight = (UIImageView*)[cell viewWithTag:1006];
    
    upBandView.hidden = NO;
    mainBandView.hidden = NO;
    cell.userInteractionEnabled = YES;
    mainBandView.backgroundColor = [self getColor:indexPath up:NO]; // [tableColors objectAtIndex:indexPath.row];
    upBandView.backgroundColor = [self getColor:indexPath up:YES]; // [tableColorsUp objectAtIndex:indexPath.row];
    //tableView.backgroundColor = backColor;
    
    labUp.text = [[tableData objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    
    UIImage * img;
    CGSize imgSize;
    if (indexPath.row <= 11) {
        id indexVal = [[horData objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        // NSLog(@"setupCell [%i] %i",indexPath.row,[index intValue]);
        if ([indexVal isKindOfClass:[NSNumber class]]) {
            NSNumber *index = (NSNumber *)indexVal;
            NSString * name = (NSString*) [[[tableSubData objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectAtIndex:[index intValue]];
            labMain.text = name;
            // NSLog(@"setupcell [%@]", [NSString stringWithFormat:@"%i-%i",indexPath.row,[index intValue]]);
            // img = [self getPng7z:[NSString stringWithFormat:@"%i-%i",indexPath.row,[index intValue]]]; // direct from archive
            // img = [UIImage imageNamed:[NSString stringWithFormat:@"%i-%i",indexPath.row,[index intValue]]]; // base system
            img = [UIImage imageWithContentsOfFile:[NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%i@2x.png",(int)indexPath.row]]]; // cached
            imgSize = img.size;
            [imgRight setImage:img];
            [imgRight setFrame:CGRectMake(screenWidth-(320.0-258.0)+48.0-imgSize.width, 4.5, imgSize.width, imgSize.height)];
        } else {
            // Sign not yet calculated — show placeholder until calculateSigns: completes
            labMain.text = @"...";
            [imgRight setImage:nil];
        }
    } else {
        labMain.text = @"AQUARIUS";
        img = [UIImage imageNamed:@"0-7"];
        imgSize = img.size;
        [imgRight setImage:img];
        [imgRight setFrame:CGRectMake(screenWidth-(320.0-258.0)+48.0-imgSize.width, 4.5, imgSize.width, imgSize.height)];
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableViewPar cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == nil) {
        tableView = tableViewPar;
        tableView.backgroundView = nil;
        tableView.backgroundColor = backColor;
        [tableView setSeparatorColor:[UIColor whiteColor]];
        tableView.clipsToBounds = YES;
            [tableView setSeparatorInset:UIEdgeInsetsZero];
    }
    
    UITableViewCell *cell = nil;
    
    if ((rowSelected >= 0) && (secSelected == indexPath.section)) {
        if (indexPath.row == (rowSelected+1)) {
            // webView — create lazily, only for the currently expanded row
            cell = [[webViews objectAtIndex:secSelected] objectAtIndex:rowSelected];
            WKWebView * webView = (WKWebView*)[cell viewWithTag:1001];

            // Create the WebView on demand if not yet present
            if (webView == nil) {
                // Try to use a pre-warmed webview for instant display.
                WKWebView *prewarmed = nil;
                if (rowSelected < (int)[preloadedWebViews count]) {
                    id obj = [preloadedWebViews objectAtIndex:rowSelected];
                    if (obj != [NSNull null]) prewarmed = (WKWebView *)obj;
                }

                if (prewarmed) {
                    // Move out of the off-screen container into the cell.
                    [prewarmed removeFromSuperview];
                    prewarmed.tag = 1001;
                    CGFloat knownHeight = prewarmed.frame.size.height;
                    prewarmed.frame = CGRectMake(0, 0, screenWidth, MAX(knownHeight, 50.0));
                    prewarmed.alpha = 0;
                    [cell addSubview:prewarmed];
                    webView = prewarmed;
                    [preloadedWebViews replaceObjectAtIndex:rowSelected withObject:[NSNull null]];
                    // Fade in after the insert animation completes to avoid black flash.
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)),
                                   dispatch_get_main_queue(), ^{
                        [UIView animateWithDuration:0.2 animations:^{ prewarmed.alpha = 1.0; }];
                    });
                } else {
                    // Fallback: load on demand — fade in from didFinishNavigation.
                    NSURL *url = [[NSBundle mainBundle] bundleURL];
                    NSString *html = [[htmlData objectAtIndex:secSelected] objectAtIndex:rowSelected];
                    webView = [self defWV];
                    webView.alpha = 0;
                    [webView loadHTMLString:html baseURL:url];
                    [cell addSubview:webView];
                }
            }

            UIView * socialView = [cell viewWithTag:1007];
            // recreate socialView
            if (socialView != nil)
                [socialView removeFromSuperview];
            
            CGRect sR = CGRectMake(0,0, screenWidth, 55.0);
            sR.origin.y = webView.frame.size.height;
            
            socialView = [self defSV:sR];
            [cell addSubview:socialView];
            
        } else {
            // rows after selection
            int rowMod = (int)indexPath.row;
            if (rowMod > rowSelected) rowMod--;
            cell = [[cells objectAtIndex:secSelected] objectAtIndex:rowMod];
            [self setUpCell:cell forIndexPath:[NSIndexPath indexPathForRow:rowMod inSection:secSelected]];
        }
    } else {
        // no rows selected
        cell = [[cells objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        [self setUpCell:cell forIndexPath:indexPath];
    }
    
    cell.hidden = NO;
    
    // NSLog(@"cellForRowAtIndexPath %i, %i, %@", indexPath.row, indexPath.section, [cell description]);
    
    return cell;
}
- (void)webView:(WKWebView *)webViewArg didFinishNavigation:(null_unspecified WKNavigation *)navigation
{
    NSString *currentURL = webViewArg.URL.absoluteString;
    if ([currentURL isEqualToString:@"about:blank"]) return;

    // Pre-warmed webview (tag 2000–2011) — just measure and cache the height.
    if (webViewArg.tag >= 2000 && webViewArg.tag < 2012) {
        int preloadIdx = (int)webViewArg.tag - 2000;
        [webViewArg evaluateJavaScript:@"document.body.scrollHeight"
                     completionHandler:^(id result, NSError *error) {
            if (!error && result) {
                CGFloat height = [result floatValue];
                if (height > 0) {
                    // Store height so heightForRowAtIndexPath returns it immediately on tap.
                    [[webHeights objectAtIndex:0] replaceObjectAtIndex:preloadIdx withObject:@(height)];
                    // Resize the off-screen webview to its natural height.
                    CGRect f   = webViewArg.frame;
                    f.size.height = height;
                    webViewArg.frame = f;
                }
            }
            // Count down — reveal titles once all preloads are done.
            preloadPendingCount--;
            NSLog(@"[PRELOAD] sign %i done, pending=%i", preloadIdx, preloadPendingCount);
            if (preloadPendingCount <= 0) {
                [self revealSignTitles];
            }
        }];
        return;
    }

    if (rowSelected < 0) return;

    // Capture row/section at callback time to guard against state change
    int capturedRow = rowSelected;
    int capturedSec = secSelected;

    // Async height — never spins the run loop, preventing UITableView reentrancy
    [webViewArg evaluateJavaScript:@"document.body.scrollHeight"
                 completionHandler:^(id result, NSError *error) {
        if (error || !result) return;
        CGFloat height = [result floatValue];
        if (height <= 0) return;
        // Guard: still showing same row
        if (rowSelected != capturedRow || secSelected != capturedSec) return;

        // Cache the height
        [[webHeights objectAtIndex:capturedSec] replaceObjectAtIndex:capturedRow withObject:@(height)];

        // Resize the webView
        CGRect frame = webViewArg.frame;
        frame.size.height = height;
        [webViewArg setFrame:frame];

        // Move the social band to sit below the content
        UITableViewCell *webCell = [[webViews objectAtIndex:capturedSec] objectAtIndex:capturedRow];
        UIView *socialView = [webCell viewWithTag:1007];
        if (socialView) {
            CGRect sR = socialView.frame;
            sR.origin.y = height;
            socialView.frame = sR;
        }

        // Fade in the webview now that content is measured (on-demand load case).
        if (webViewArg.alpha < 1.0) {
            [UIView animateWithDuration:0.2 animations:^{ webViewArg.alpha = 1.0; }];
        }

        // Animate the row height change
        if (tableView) {
            [tableView beginUpdates];
            [tableView endUpdates];
        }
    }];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    if (rowSelected >= 0) {
        if ((indexPath.row == (rowSelected+1)) && (indexPath.section == secSelected)) {
            UITableViewCell* webCell = [[webViews objectAtIndex:secSelected] objectAtIndex:rowSelected];
            //NSLog(@"web size: %f", webCell.frame.size.height);
            //return webCell.frame.size.height;
            
            WKWebView * webView2 = (WKWebView*)[webCell viewWithTag:1001];
            if (webView2 == nil) {
                return 50.0 + 55.0;
            } else {
                // Use the cached height set by didFinishNavigation (async, no runloop spin)
                NSNumber *cached = [[webHeights objectAtIndex:secSelected] objectAtIndex:rowSelected];
                CGFloat height = [cached floatValue];
                if (height <= 0) return 50.0 + 55.0;
                return height + 55.0;
            }
            
        } else {
            return CELL_HEIGHT;
        }
    } else {
        return CELL_HEIGHT;
    }
    
}

- (NSString *) tableView:(UITableView *)tableViewPar titleForHeaderInSection:(NSInteger)section
{
    /*
     if (rowSelected < 0) {
     return [tableSections objectAtIndex:section];
     }
	 return [tableSections objectAtIndex:secSelected];
     */
    return @"";
}





- (void) tableView:(UITableView *)tableViewPar didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [delegate hidePickers];
    
    // [UIView setAnimationsEnabled:NO];
    
    //[CATransaction begin];
    
    
    [tableViewPar beginUpdates];
    
    // NSLog(@"selected in: %i", indexPath.row);
    old_rowSelected = rowSelected;
    if ((indexPath.section == secSelected) && ((indexPath.row == rowSelected) || (indexPath.row == (rowSelected+1)))) {
        // NSLog(@"close select");
        // close
        
        // delete webview row
        NSArray * delArr = [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:old_rowSelected+1 inSection:secSelected], nil];
        [tableViewPar deleteRowsAtIndexPaths:delArr withRowAnimation:UITableViewRowAnimationTop];
        
        rowSelected = -99;
        
        // Free the WKWebView process — row is no longer visible
        [self releaseExpandedWebView];
        
    } else if (rowSelected < 0) {
        // NSLog(@"new select");
        
        // new select
        rowSelected = (int)indexPath.row;
        secSelected = (int)indexPath.section;
        
        
        // insert webview
        NSArray * insArr = [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:rowSelected+1 inSection:secSelected], nil];
        [tableViewPar insertRowsAtIndexPaths:insArr withRowAnimation:UITableViewRowAnimationTop];
        
        // [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:[NSIndexPath indexPathForRow:rowSelected inSection:indexPath.section], nil] withRowAnimation:UITableViewRowAnimationFade];
        
        
        // [webView removeFromSuperview];
        // webView.backgroundColor = [self getColor:indexPath up:YES]; // [tableColorsUp objectAtIndex:rowSelected];
        
        
        
    } else {
        // switch select
        
        // delete webview row
        NSArray * delArr = [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:old_rowSelected+1 inSection:secSelected], nil];
        [tableViewPar deleteRowsAtIndexPaths:delArr withRowAnimation:UITableViewRowAnimationTop];
        
        // Free the previous WKWebView process before opening a new one
        [self releaseExpandedWebView];
        
        // new select
        rowSelected = (int)indexPath.row;
        if ((secSelected == indexPath.section) && (rowSelected > old_rowSelected)) {
            // adjust for extra cell - webview
            rowSelected--;
        }
        secSelected = (int)indexPath.section;
        
        
        // insert webview
        NSArray * insArr = [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:rowSelected+1 inSection:secSelected], nil];
        [tableViewPar insertRowsAtIndexPaths:insArr withRowAnimation:UITableViewRowAnimationTop];
        
        
    }
    // NSLog(@"selected out: %i", rowSelected);
    // [tableViewPar reloadData];
    
    [tableViewPar endUpdates];
    
    /*
     // after scroll
     if (rowSelected < 0) {
     [CATransaction setCompletionBlock:^{
     NSLog(@"transfinish2");
     [tableViewPar reloadData];
     [tableViewPar scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:old_rowSelected inSection:secSelected] atScrollPosition:UITableViewScrollPositionNone animated:YES];
     }];
     } else {
     [CATransaction setCompletionBlock:^{
     NSLog(@"transfinish");
     [tableViewPar reloadData];
     [tableViewPar scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:rowSelected inSection:secSelected] atScrollPosition:UITableViewScrollPositionTop animated:YES];
     }];
     }
     
     
     [CATransaction commit];
     */
    
    //[UIView setAnimationsEnabled:YES];
    
    // after scroll
    if (rowSelected < 0) {
        [tableViewPar scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:old_rowSelected inSection:secSelected] atScrollPosition:UITableViewScrollPositionNone animated:YES];
    } else {
        [tableViewPar reloadData];
        [tableViewPar scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:rowSelected inSection:secSelected] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
    
}


@end




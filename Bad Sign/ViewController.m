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



#import "LZMAExtractor.h"
// #import "Flurry.h"

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
   // NSLog(@"getHtml7z %@", fileName);
    
    BOOL worked;
    
    NSString *archiveFilename = @"arch.7z";
    NSString *archiveResPath = [[NSBundle mainBundle] pathForResource:archiveFilename ofType:nil];
    NSAssert(archiveResPath, @"can't find arch.7z");
    
    // Extract single entry "make.out" and save it as "tmp/make.out.txt" in the tmp dir.
    
    NSString *entryFilename = fileName;
	NSString *makeTmpFilename = @"7z.html";
	NSString *makeTmpPath = [NSTemporaryDirectory() stringByAppendingPathComponent:makeTmpFilename];
    
    worked = [LZMAExtractor extractArchiveEntry:archiveResPath
                                   archiveEntry:entryFilename
                                        outPath:makeTmpPath];
    NSString *outStr = nil;
    if (worked) {
        //NSLog(@"%@", makeTmpPath);
        
        NSData *outputData = [NSData dataWithContentsOfFile:makeTmpPath];
        outStr = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
    }
    
   // NSLog(@"DONE getHtml7z");
    
    return outStr;
}

- (void) getPng7z:(NSString*) fileName out:(NSString*) fileNameOut
{
    // NSLog(@"getPng7z %@", fileName);
    
    BOOL /*worked,*/ worked2;
    
    NSString *archiveFilename = @"arch.7z";
    NSString *archiveResPath = [[NSBundle mainBundle] pathForResource:archiveFilename ofType:nil];
    NSAssert(archiveResPath, @"can't find arch.7z");
    
    /*
     // Extract single entry "make.out" and save it as "tmp/make.out.txt" in the tmp dir.
     NSString *entryFilename = [NSString stringWithFormat:@"%@.png",fileName];
     NSLog(@"%@", entryFilename);
     NSString *makeTmpFilename = [NSString stringWithFormat:@"%@.png",fileNameOut];
     NSString *makeTmpPath = [NSTemporaryDirectory() stringByAppendingPathComponent:makeTmpFilename];
     
     worked = [LZMAExtractor extractArchiveEntry:archiveResPath
     archiveEntry:entryFilename
     outPath:makeTmpPath];
     */
    
    NSString * entryFilename = [NSString stringWithFormat:@"%@@2x.png",fileName];
    // NSLog(@"%@", entryFilename);
	NSString * makeTmpFilename = [NSString stringWithFormat:@"%@@2x.png",fileNameOut];
	NSString *makeTmpPath2 = [NSTemporaryDirectory() stringByAppendingPathComponent:makeTmpFilename];
    
    worked2 = [LZMAExtractor extractArchiveEntry:archiveResPath
                                    archiveEntry:entryFilename
                                         outPath:makeTmpPath2];
    
    //UIImage* ret = nil;
    //    if (worked2) {
    // NSLog(@"%@", makeTmpPath2);
    //NSData *outputData = [NSData dataWithContentsOfFile:makeTmpPath2];
    //ret = [UIImage imageWithData:outputData scale:2.0];
    //  }
    
    // NSLog(@"DONE getPng7z");
    
    // return ret;
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
        NSURL *shareUrl = [NSURL URLWithString:@"https://itunes.apple.com/us/app/bad-sign/id912176242?ls=1&mt=8"];
        
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
                 // [Flurry logEvent:[NSString stringWithFormat:@"Shared - %@",act]];
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
    NSIndexPath * indexPath =[NSIndexPath indexPathForRow:bandIndex inSection:0];
    [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
    UITableViewCell *cell =  [tableView cellForRowAtIndexPath:indexPath];
    UIImage * titleImg = [self imageOfView:cell];
    
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
        for (int i=0; i<[tableSections count]; i++) {
            NSMutableArray * secNumArr = [[NSMutableArray alloc] init];
            NSMutableArray * secHtmlArr = [[NSMutableArray alloc] init];
            
            NSMutableArray * secArr = [tableData objectAtIndex:i];
            for (int a=0; a<[secArr count]; a++) {
                NSNumber * num = [NSNumber numberWithInt:0];
                [secNumArr addObject:num];
                [secHtmlArr addObject:@""];
            }
            
            [horData addObject:secNumArr];
            [htmlData addObject:secHtmlArr];
        }
        
        // iad
        /*
        ADBannerView *adView = [[ADBannerView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height -44, 320, 50)];
        adView.delegate = self;
        [self.view addSubview:adView];
        */
        
        last_birthday = nil;
        
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

    NSURL *url = [[NSBundle mainBundle] bundleURL];
    NSMutableArray *secNumArr = [horData objectAtIndex:0];

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
            if (i == 0 && html != nil) {
                // fix viewport meta for western sign
                html = [html stringByReplacingOccurrencesOfString:@"<meta content=”width=320; initial-scale=1.0; maximum-scale=1.0; user-scalable=0;”/>"
                                                       withString:@"<meta name='viewport' content='width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no' />"];
            }
            [htmlStrings addObject:(html != nil ? html : @"")];
            NSLog(@"[DIAG] LZMA %i done (%.3fs)", i, -[_bg timeIntervalSinceNow]);
        }

        NSLog(@"[DIAG] all LZMA done (%.3fs), dispatching to main", -[_bg timeIntervalSinceNow]);
        // Phase 3: all UIKit work back on the main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"[DIAG] Phase 3 main thread start");
            NSMutableArray *secHtmlArr = [htmlData objectAtIndex:0];
            for (int i = 0; i < 12; i++) {
                int idx = [signIndices[i] intValue];
                [secNumArr replaceObjectAtIndex:i withObject:@(idx)];
                // Store HTML for lazy loading — do NOT create WKWebViews here
                [secHtmlArr replaceObjectAtIndex:i withObject:htmlStrings[i]];
                // Remove any previously loaded WebView to free its process
                UITableViewCell *cell = [[webViews objectAtIndex:0] objectAtIndex:i];
                WKWebView *webView = (WKWebView*)[cell viewWithTag:1001];
                [webView removeFromSuperview];
            }
            NSLog(@"[DIAG] Phase 3 reloadData");
            [tableView reloadData];
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
        NSNumber * index = (NSNumber*) [[horData objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        // NSLog(@"setupCell [%i] %i",indexPath.row,[index intValue]);
        if (index != nil) {
            NSString * name = (NSString*) [[[tableSubData objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectAtIndex:[index intValue]];
            labMain.text = name;
            // NSLog(@"setupcell [%@]", [NSString stringWithFormat:@"%i-%i",indexPath.row,[index intValue]]);
            // img = [self getPng7z:[NSString stringWithFormat:@"%i-%i",indexPath.row,[index intValue]]]; // direct from archive
            // img = [UIImage imageNamed:[NSString stringWithFormat:@"%i-%i",indexPath.row,[index intValue]]]; // base system
            img = [UIImage imageWithContentsOfFile:[NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%i@2x.png",(int)indexPath.row]]]; // cached
            imgSize = img.size;
            [imgRight setImage:img];
            [imgRight setFrame:CGRectMake(screenWidth-(320.0-258.0)+48.0-imgSize.width, 4.5, imgSize.width, imgSize.height)];
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
                NSURL *url = [[NSBundle mainBundle] bundleURL];
                NSString *html = [[htmlData objectAtIndex:secSelected] objectAtIndex:rowSelected];
                webView = [self defWV];
                [webView loadHTMLString:html baseURL:url];
                [cell addSubview:webView];
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
    
    if ([currentURL isEqualToString:@"about:blank"]) {
        return;
    }
    
    
    CGRect oldBounds = [webViewArg bounds];
    //in the document you can use your string ... ans set the height
    CGFloat height = [[webViewArg stringByEvaluatingJavaScriptFromString:@"document.height"] floatValue];
    CGRect bounds = CGRectMake(oldBounds.origin.x, oldBounds.origin.y, oldBounds.size.width, height);
    [webViewArg setBounds:bounds];
    [webViewArg setFrame:bounds];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    if (rowSelected >= 0) {
        if ((indexPath.row == (rowSelected+1)) && (indexPath.section == secSelected)) {
            UITableViewCell* webCell = [[webViews objectAtIndex:secSelected] objectAtIndex:rowSelected];
            //NSLog(@"web size: %f", webCell.frame.size.height);
            //return webCell.frame.size.height;
            
            WKWebView * webView2 = (WKWebView*)[webCell viewWithTag:1001];
            //NSString *currentURL = webView2.request.URL.absoluteString;
            if (webView2 == nil) {
                return 50.0;
            } else {
                NSString *result = [webView2 stringByEvaluatingJavaScriptFromString:@"document.body.offsetHeight;"];
                
                int height = (int)[result integerValue];
                
                CGRect f = webView2.frame;
                f.size.height = height;
                webView2.frame = f;
                
               // NSLog(@"web size: %i", height);
                return height+55.0;

//                NSLog(@"web size: %f", webView2.bounds.size.height);
  //              return webView2.frame.size.height+55.0;
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




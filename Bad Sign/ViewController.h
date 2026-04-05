//
//  ViewController.h
//  Bad Sign
//
//  Created by admin on 12/8/13.
//  Copyright (c) 2013 Void Software. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <WebKit/WebKit.h>

@interface ViewController : UIViewController <WKNavigationDelegate, UITableViewDelegate, UITableViewDataSource>
{
    
    NSMutableArray * cells;
    NSMutableArray * webViews;
    
    NSArray * tableSections;
    NSArray * tableData;
    NSArray * tableSubData;
    
    NSArray * tableColors;
    NSArray * tableColorsUp;
    
    UITableView * tableView;
    
    // Horoscopes index
    NSMutableArray * horData;
    
    // HTML content for each sign (lazily loaded into WebViews on demand)
    NSMutableArray * htmlData;
    
    // Cached content heights for each sign's web cell
    NSMutableArray * webHeights;
    
    // HTML content preloaded into off-screen WKWebViews so tapping is instant
    NSMutableArray * preloadedWebViews; // 12 WKWebView*, NSNull if not ready
    UIView         * preloadContainer;  // off-screen host for pre-warmed webviews

    NSDate * last_birthday;
    
    UITableView* tw;
    
    double screenWidth;
}

-(void) calculateSigns:(NSDate*) birthday;
-(UIImage*) getBandImage:(int) bandIndex;

-(void) closeCells;
-(void) refresh;

@end

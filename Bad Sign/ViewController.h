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
    
    NSDate * last_birthday;
    
    UITableView* tw;
    
    double screenWidth;
}

-(void) calculateSigns:(NSDate*) birthday;
-(UIImage*) getBandImage:(int) bandIndex;

-(void) closeCells;
-(void) refresh;

@end

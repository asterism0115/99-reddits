//
//  AlbumViewControllerPad.h
//  99reddits
//
//  Created by Frank Jacob on 11/8/12.
//  Copyright (c) 2012 99 reddits. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SubRedditItem.h"
#import "PhotoItem.h"
#import "ASIHTTPRequestDelegate.h"
#import "NIProcessorHTTPRequest.h"

@class RedditsAppDelegate;
@class MainViewControllerPad;

@interface AlbumViewControllerPad : UIViewController <UITableViewDelegate, UITableViewDataSource, UITabBarDelegate, UIAlertViewDelegate, ASIHTTPRequestDelegate> {
	RedditsAppDelegate *appDelegate;
	MainViewControllerPad *mainViewController;
	
	IBOutlet UITableView *contentTableView;
	IBOutlet UIView *footerView;
	IBOutlet UIButton *moarButton;
	IBOutlet UIActivityIndicatorView *moarWaitingView;
	IBOutlet UITabBar *tabBar;
	IBOutlet UITabBarItem *hotItem;
	IBOutlet UITabBarItem *newItem;
	IBOutlet UITabBarItem *controversialItem;
	IBOutlet UITabBarItem *topItem;
	UITabBarItem *currentItem;
	IBOutlet UISegmentedControl *showTypeSegmentedControl;
	
	SubRedditItem *currentSubReddit;
	SubRedditItem *subReddit;
	
	NSOperationQueue *refreshQueue;
	NSOperationQueue *queue;
	
	NSMutableSet* activeRequests;
	NIImageMemoryCache* thumbnailImageCache;
	
	BOOL bFromSubview;
	
	BOOL bFavorites;
	
	BOOL bMOARLoading;
	
	float scale;
	
	NSMutableArray *currentPhotosArray;
}

@property (nonatomic, retain) MainViewControllerPad *mainViewController;
@property (nonatomic, retain) SubRedditItem *subReddit;
@property (nonatomic) BOOL bFavorites;

- (IBAction)onMOARButton:(id)sender;
- (IBAction)onShowType:(id)sender;
- (void)onSelectPhoto:(PhotoItem *)photo;

@end
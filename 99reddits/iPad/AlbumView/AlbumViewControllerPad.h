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
#import "CustomCollectionView.h"
#import <MessageUI/MessageUI.h>

@class MainViewControllerPad;

@interface AlbumViewControllerPad : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITabBarDelegate, UIAlertViewDelegate, ASIHTTPRequestDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate> {
	MainViewControllerPad __weak *mainViewController;
	
	IBOutlet CustomCollectionView *contentCollectionView;
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
	UIActionSheet *actionSheet;
	UITapGestureRecognizer *actionSheetTapGesture;

	SubRedditItem *currentSubReddit;
	SubRedditItem *subReddit;
	
	NSOperationQueue *refreshQueue;
	NSOperationQueue *queue;
	
	NSMutableSet *activeRequests;
	NIImageMemoryCache *thumbnailImageCache;
	
	BOOL shouldReleaseCaches;
	
	BOOL bFavorites;
	
	BOOL bMOARLoading;
	
	NSMutableArray *currentPhotosArray;

	BOOL initialized;
}

@property (nonatomic, weak) MainViewControllerPad *mainViewController;
@property (nonatomic, strong) SubRedditItem *subReddit;
@property (nonatomic) BOOL bFavorites;

- (IBAction)onMOARButton:(id)sender;
- (IBAction)onShowType:(id)sender;
- (void)onSelectPhoto:(PhotoItem *)photo;

@end

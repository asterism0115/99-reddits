//
//  RedditsViewController.h
//  99reddits
//
//  Created by Frank Jacob on 1/4/12.
//  Copyright (c) 2012 99 reddits. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MainViewController;
@class SubRedditItem;

@interface RedditsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
	MainViewController __weak *mainViewController;

	IBOutlet UIBarButtonItem *addButton;
	IBOutlet UIBarButtonItem *doneButton;
	IBOutlet UITableView *contentTableView;
	
	NSMutableArray *categoryArray;
	NSMutableArray *sectionArray;
	NSMutableSet *nameStringsSet;

	NSString *manualAddedNameString;
}

@property (nonatomic, weak) MainViewController *mainViewController;

- (void)onManualAdded:(NSString *)nameString;

@end

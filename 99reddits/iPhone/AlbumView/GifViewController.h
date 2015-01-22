//
//  GifViewController.h
//  99reddits
//
//  Created by Frank Jacob on 11/3/11.
//  Copyright (c) 2011 99 reddits. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PhotoView;

@interface GifViewController : UIViewController {
	IBOutlet UIWebView *webView;
	IBOutlet UIView *overlayView;
	
	NSData *_gifData;
	NSInteger width;
	NSInteger height;
	
	UITapGestureRecognizer* _tapGesture;
	
	BOOL hidden;
	
	PhotoView *__weak photoView;
}

@property (nonatomic, strong) NSData *gifData;
@property (nonatomic) NSInteger width;
@property (nonatomic) NSInteger height;
@property (nonatomic, weak) PhotoView *photoView;

@end

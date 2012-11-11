//
//  GifViewControllerPad.h
//  99reddits
//
//  Created by Frank Jacob on 11/11/12.
//  Copyright (c) 2012 99 reddits. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GifViewControllerPad : UIViewController {
	IBOutlet UIWebView *webView;
	IBOutlet UIView *overlayView;
	
	NSData *_gifData;
	int width;
	int height;
	
	UITapGestureRecognizer* _tapGesture;
	
	BOOL hidden;
}

@property (nonatomic, retain) NSData *gifData;
@property (nonatomic) int width;
@property (nonatomic) int height;

@end

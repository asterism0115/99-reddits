//
//  AlbumViewCellPad.m
//  99reddits
//
//  Created by Frank Jacob on 11/11/12.
//  Copyright (c) 2012 99 reddits. All rights reserved.
//

#import "AlbumViewCellPad.h"
#import "AlbumViewControllerPad.h"
#import <QuartzCore/QuartzCore.h>

@implementation AlbumViewCellPad

@synthesize albumViewController;
@synthesize photo;
@synthesize bFavorites;

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		self.backgroundColor = [UIColor clearColor];
		self.contentView.backgroundColor = [UIColor clearColor];

		appDelegate = (RedditsAppDelegate *)[[UIApplication sharedApplication] delegate];

		imageOutlineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 120, 120)];
		imageOutlineView.backgroundColor = [UIColor whiteColor];
		[self.contentView addSubview:imageOutlineView];

		imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 120, 120)];
		[imageOutlineView addSubview:imageView];

		favoriteOverlayView = [[UIImageView alloc] initWithFrame:CGRectMake(89, 89, 25, 25)];
		[self.contentView addSubview:favoriteOverlayView];

		tapButton = [UIButton buttonWithType:UIButtonTypeCustom];
		tapButton.frame = imageOutlineView.frame;
		[tapButton setImage:[UIImage imageNamed:@"ButtonOverlay.png"] forState:UIControlStateHighlighted];
		[tapButton addTarget:self action:@selector(onTap:) forControlEvents:UIControlEventTouchUpInside];
		[self.contentView addSubview:tapButton];
	}
	return self;
}

- (void)onTap:(id)sender {
	[albumViewController onSelectPhoto:photo];
}

- (void)setPhoto:(PhotoItem *)_photo {
	photo = nil;

	photo = _photo;

	if (bFavorites) {
		favoriteOverlayView.hidden = YES;
		favoriteOverlayView.image = nil;
	}
	else {
		if ([appDelegate isFavorite:photo]) {
			favoriteOverlayView.hidden = NO;
			favoriteOverlayView.image = [UIImage imageNamed:@"FavoritesRedIcon.png"];
		}
		else {
			favoriteOverlayView.hidden = YES;
			favoriteOverlayView.image = nil;
		}
	}
}

- (void)setThumbImage:(UIImage *)thumbImage animated:(BOOL)animated {
	[animateImageView.layer removeAllAnimations];
	[animateImageView removeFromSuperview];
	animateImageView = nil;

	if (thumbImage == nil) {
		imageOutlineView.frame = CGRectMake(0, 0, 120, 120);
		imageView.frame = CGRectMake(0, 0, 120, 120);
		imageView.image = [UIImage imageNamed:@"DefaultPhoto.png"];
		imageEmpty = YES;
	}
	else {
		NSInteger width = thumbImage.size.width;
		NSInteger height = thumbImage.size.height;
		if (width > height) {
			width = 108;
			height = height * width / thumbImage.size.width;
		}
		else {
			height = 108;
			width = width * height / thumbImage.size.height;
		}
		CGRect rect = CGRectMake((NSInteger)(108 - width) / 2 + 6, (NSInteger)(108 - height) / 2 + 6, width, height);

		rect.origin.x -= 6;
		rect.origin.y -= 6;
		rect.size.width += 12;
		rect.size.height += 12;
		imageOutlineView.frame = rect;

		rect = imageOutlineView.frame;
		rect.origin.x += (rect.size.width - 12);
		rect.origin.y += (rect.size.height - 12);
		rect.size.width = 25;
		rect.size.height = 25;
		favoriteOverlayView.frame = rect;

		imageView.frame = CGRectMake(0, 0, width + 12, height + 12);

		if (animated || imageEmpty) {
			imageView.image = [UIImage imageNamed:@"DefaultPhoto.png"];
			animateImageView = [[UIImageView alloc] initWithFrame:imageView.frame];
			animateImageView.image = thumbImage;
			[imageOutlineView addSubview:animateImageView];

			animateImageView.alpha = 0.0;
			[UIView animateWithDuration:0.2
							 animations:^(void) {
								 animateImageView.alpha = 1.0;
							 }
							 completion:^(BOOL finished) {
								 [animateImageView removeFromSuperview];
								 animateImageView = nil;
								 if (finished) {
									 imageView.image = thumbImage;
								 }
							 }];
		}
		else {
			imageView.image = thumbImage;
		}
		imageEmpty = NO;
	}
}

@end

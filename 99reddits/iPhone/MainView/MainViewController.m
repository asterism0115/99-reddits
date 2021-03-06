//
//  MainViewController.m
//  99reddits
//
//  Created by Frank Jacob on 10/12/11.
//  Copyright 2011 99 reddits. All rights reserved.
//

#import "MainViewController.h"
#import "MainViewCell.h"
#import "NIHTTPRequest.h"
#import "ASIDownloadCache.h"
#import "AlbumViewController.h"
#import "RedditsViewController.h"
#import "SettingsViewController.h"
#import "UserDef.h"

#define THUMB_WIDTH			55
#define THUMB_HEIGHT		55

@interface MainViewController ()

- (NSString *)cacheKeyForPhotoIndex:(NSInteger)photoIndex;
- (void)requestImageFromSource:(NSString *)source photoIndex:(NSInteger)photoIndex;

@end

@implementation MainViewController

@synthesize lastAddedIndex;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc {
	for (ASIHTTPRequest *request in refreshQueue.operations) {
		[request clearDelegatesAndCancel];
	}

	for (ASIHTTPRequest *request in queue.operations) {
		[request clearDelegatesAndCancel];
	}

	activeRequests = nil;
	thumbnailImageCache = nil;
	refreshQueue = nil;
	queue = nil;
}

- (void)didReceiveMemoryWarning {
	for (ASIHTTPRequest *request in refreshQueue.operations) {
		[request clearDelegatesAndCancel];
	}
	
	for (ASIHTTPRequest *request in queue.operations) {
		[request clearDelegatesAndCancel];
	}
	
	[activeRequests removeAllObjects];
	[thumbnailImageCache reduceMemoryUsage];
	
	refreshCount = 0;
	refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh"];
	[refreshControl endRefreshing];
	
	[self.tableView reloadData];

    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

	appDelegate = (RedditsAppDelegate *)[[UIApplication sharedApplication] delegate];
	subRedditsArray = appDelegate.subRedditsArray;
	
	refreshControl = [[UIRefreshControl alloc] init];
	refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh"];
	[refreshControl addTarget:self action:@selector(reloadData) forControlEvents:UIControlEventValueChanged];
	self.refreshControl = refreshControl;

	dispatch_async(dispatch_get_main_queue(), ^{
		[self.refreshControl beginRefreshing];
		[self.refreshControl endRefreshing];
	});

	self.title = @"99 reddits";
	
	self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:settingsItem, nil];
	self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:editItem, nil];
	
	[[ASIDownloadCache sharedCache] setShouldRespectCacheControlHeaders:NO];

	
	refreshQueue = [[NSOperationQueue alloc] init];
	[queue setMaxConcurrentOperationCount:5];
	
	queue = [[NSOperationQueue alloc] init];
	[queue setMaxConcurrentOperationCount:5];
	
	activeRequests = [[NSMutableSet alloc] init];
	
	thumbnailImageCache = [[NIImageMemoryCache alloc] init];
	
	refreshCount = 0;
	
	if (appDelegate.firstRun) {
		[self reloadData];
	}
	else {
//		NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
//		if (currentTime - appDelegate.updatedTime > 300)
//			[self reloadData];
	}

	CGRect frame = footerView.frame;
	frame.size.width = screenWidth;
	footerView.frame = frame;
	self.tableView.tableFooterView = footerView;

	self.view.backgroundColor = [UIColor whiteColor];
	self.edgesForExtendedLayout = UIRectEdgeAll;
	self.tableView.separatorInset = UIEdgeInsetsZero;

	[addButton setBackgroundImage:[[UIImage imageNamed:@"ButtonNormal.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 10)] forState:UIControlStateNormal];
	[addButton setBackgroundImage:[[UIImage imageNamed:@"ButtonHighlighted.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 10)] forState:UIControlStateHighlighted];
	[addButton setBackgroundImage:[[UIImage imageNamed:@"ButtonNormal.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 10)] forState:UIControlStateDisabled];

	lastAddedIndex = -1;
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotate {
	return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
	return UIInterfaceOrientationMaskPortrait;
}

- (void)viewWillAppear:(BOOL)animated {
	for (SubRedditItem *subReddit in subRedditsArray) {
		[subReddit calUnshowedCount];
	}
	[self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
	if (lastAddedIndex >= 0) {
		[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:lastAddedIndex + 1 inSection:0] atScrollPosition:UITableViewScrollPositionNone animated:YES];
		lastAddedIndex = -1;
	}
}

- (IBAction)onEditButton:(id)sender {
	[self setEditing:!self.editing animated:YES];
	if (self.editing) {
		self.refreshControl = nil;
		
		settingsItem.enabled = NO;

		self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:doneItem, nil];
	}
	else {
		self.refreshControl = refreshControl;
		
		settingsItem.enabled = YES;

		self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:editItem, nil];
	}
}

- (IBAction)onAddButton:(id)sender {
	RedditsViewController *redditsViewController = [[RedditsViewController alloc] initWithNibName:@"RedditsViewController" bundle:nil];
	redditsViewController.mainViewController = self;
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:redditsViewController];
	[self presentViewController:navigationController animated:YES completion:nil];
}

// UITableViewDatasource, UITableViewDelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return subRedditsArray.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *identifer = @"MAINVIEWCELL";
	MainViewCell *cell = (MainViewCell *)[tableView dequeueReusableCellWithIdentifier:identifer];
	if (cell == nil) {
		cell = [[MainViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifer];
	}
	
	if (indexPath.row == 0) {
//		cell.textLabel.text = appDelegate.favoritesItem.nameString;
		cell.contentTextLabel.text = appDelegate.favoritesItem.nameString;

		if (appDelegate.favoritesItem.photosArray.count == 0) {
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			[cell setThumbImage:[UIImage imageNamed:@"FavoritesIcon.png"] animated:NO];
		}
		else {
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.selectionStyle = UITableViewCellSelectionStyleBlue;
			
			NSString *urlString = [self cacheKeyForPhotoIndex:indexPath.row - 1];
			UIImage *image = [thumbnailImageCache objectWithName:urlString];
			if (image == nil) {
				[self requestImageFromSource:urlString photoIndex:indexPath.row - 1];
				[cell setThumbImage:[UIImage imageNamed:@"FavoritesIcon.png"] animated:NO];
			}
			else {
				[cell setThumbImage:image animated:NO];
			}
		}
		
		[cell setTotalCount:appDelegate.favoritesItem.photosArray.count];
	}
	else {
		SubRedditItem *subReddit = [subRedditsArray objectAtIndex:indexPath.row - 1];
//		cell.textLabel.text = subReddit.nameString;
		cell.contentTextLabel.text = subReddit.nameString;

		if (subReddit.photosArray.count == 0 || subReddit.loading) {
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			[cell setThumbImage:nil animated:NO];
		}
		else {
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.selectionStyle = UITableViewCellSelectionStyleBlue;
			
			NSString *urlString = [self cacheKeyForPhotoIndex:indexPath.row - 1];
			UIImage *image = [thumbnailImageCache objectWithName:urlString];
			if (image == nil) {
				[self requestImageFromSource:urlString photoIndex:indexPath.row - 1];
				[cell setThumbImage:nil animated:NO];
			}
			else {
				[cell setThumbImage:image animated:NO];
			}
		}
		
		[cell setUnshowedCount:subReddit.unshowedCount totalCount:subReddit.photosArray.count loading:subReddit.loading];
	}
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	if (self.editing)
		return;
	
	if (indexPath.row == 0) {
		if (appDelegate.favoritesItem.photosArray.count > 0) {
			AlbumViewController *albumViewController = [[AlbumViewController alloc] initWithNibName:@"AlbumViewController" bundle:nil];
			albumViewController.mainViewController = self;
			albumViewController.subReddit = appDelegate.favoritesItem;
			albumViewController.bFavorites = YES;
			[self.navigationController pushViewController:albumViewController animated:YES];
		}
	}
	else {
		SubRedditItem *subReddit = [subRedditsArray objectAtIndex:indexPath.row - 1];
		
		if (subReddit.photosArray.count > 0 && !subReddit.loading) {
			AlbumViewController *albumViewController = [[AlbumViewController alloc] initWithNibName:@"AlbumViewController" bundle:nil];
			albumViewController.mainViewController = self;
			albumViewController.subReddit = subReddit;
			albumViewController.bFavorites = NO;
			[self.navigationController pushViewController:albumViewController animated:YES];
		}
	}
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
//	if (!self.editing)
//		return NO;

	if (indexPath.row == 0)
		return NO;
	
	if (refreshCount != 0)
		return NO;
	
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		SubRedditItem *subReddit = [subRedditsArray objectAtIndex:indexPath.row - 1];
		if (subReddit.photosArray.count > 0) {
			NSString *thumbnailString = [[subReddit.photosArray objectAtIndex:0] thumbnailString];
			for (ASIHTTPRequest *request in queue.operations) {
				if ([[request.originalURL absoluteString] isEqualToString:thumbnailString]) {
					[request clearDelegatesAndCancel];
					[activeRequests removeObject:thumbnailString];
					break;
				}
			}
		}
		
		subReddit.subscribe = NO;
		[appDelegate.nameStringsSet removeObject:[subReddit.nameString lowercaseString]];
		[subRedditsArray removeObject:subReddit];
		[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
		
		[appDelegate saveToDefaults];
	}
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	if (!self.editing)
		return NO;
	
	if (indexPath.row == 0)
		return NO;
	
	if (refreshCount != 0)
		return NO;
	
	return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
	SubRedditItem *subReddit = [subRedditsArray objectAtIndex:fromIndexPath.row - 1];
	[subRedditsArray removeObjectAtIndex:fromIndexPath.row - 1];
	[subRedditsArray insertObject:subReddit atIndex:toIndexPath.row - 1];
	
	[appDelegate saveToDefaults];
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
	if (proposedDestinationIndexPath.row == 0)
		return sourceIndexPath;
	
	return proposedDestinationIndexPath;
}

- (void)reloadData {
	if (subRedditsArray.count == 0)
		return;
	
	if (![appDelegate checkNetworkReachable:YES])
		return;
	
	if (refreshCount != 0)
		return;
	
	self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Refreshing..."];
	[self.refreshControl beginRefreshing];
	
	editItem.enabled = NO;
	
	for (ASIHTTPRequest *request in refreshQueue.operations) {
		[request clearDelegatesAndCancel];
	}
	
	for (ASIHTTPRequest *request in queue.operations) {
		[request clearDelegatesAndCancel];
	}
	[activeRequests removeAllObjects];
	
	refreshCount = 0;
	
	for (NSInteger i = 0; i < subRedditsArray.count; i ++) {
		SubRedditItem *subReddit = [subRedditsArray objectAtIndex:i];
		subReddit.loading = YES;
		
		refreshCount ++;
		
		NSURL *url = [NSURL URLWithString:subReddit.urlString];
		NIProcessorHTTPRequest* albumRequest = [NIJSONKitProcessorHTTPRequest requestWithURL:url usingCache:nil];
		albumRequest.shouldAttemptPersistentConnection = NO;
		albumRequest.timeOutSeconds = 30;
		albumRequest.delegate = self;
        albumRequest.userAgentString = @"Mozilla/5.0 (iPhone; CPU iPhone OS 10_1 like Mac OS X) AppleWebKit/602.2.14 (KHTML, like Gecko) Mobile/14B72";
		albumRequest.processorDelegate = (id)[self class];
		[refreshQueue addOperation:albumRequest];
	}
	
	[self.tableView reloadData];
}

// ASIHTTPRequestDelegate
- (void)requestFinished:(NIProcessorHTTPRequest *)request {
	NSString *urlString = [[request originalURL] absoluteString];

	SubRedditItem *subReddit = nil;
	NSInteger index = 0;
	for (NSInteger i = 0; i < subRedditsArray.count; i ++) {
		SubRedditItem *tempSubReddit = [subRedditsArray objectAtIndex:i];
		if ([tempSubReddit.urlString isEqualToString:urlString]) {
			subReddit = tempSubReddit;
			index = i;
			break;
		}
	}

	if (subReddit == nil) {
		refreshCount --;
		if (refreshCount == 0) {
			self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh"];
			[self.refreshControl endRefreshing];

			editItem.enabled = YES;
		}
		return;
	}
	
	subReddit.loading = NO;
	subReddit.unshowedCount = 0;
	
	NSMutableArray *tempPhotosArray = [[NSMutableArray alloc] init];
	[tempPhotosArray addObjectsFromArray:subReddit.photosArray];

	NSDictionary *dictionary = (NSDictionary *)request.processedObject;
	[subReddit.photosArray removeAllObjects];
	[subReddit.photosArray addObjectsFromArray:[dictionary objectForKey:@"photos"]];

	subReddit.afterString = [dictionary objectForKey:@"after"];

	[subReddit calUnshowedCount];
	
//	[self.tableView reloadData];
	[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index + 1 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];

	[tempPhotosArray removeAllObjects];
	
	refreshCount --;
	if (refreshCount == 0) {
		self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh"];
		[self.refreshControl endRefreshing];
		
		editItem.enabled = YES;
		[appDelegate saveToDefaults];
	}
}

- (void)requestFailed:(ASIHTTPRequest *)request {
	NSString *urlString = [[request originalURL] absoluteString];
	
	SubRedditItem *subReddit = nil;
	NSInteger index = 0;
	for (NSInteger i = 0; i < subRedditsArray.count; i ++) {
		SubRedditItem *tempSubReddit = [subRedditsArray objectAtIndex:i];
		if ([tempSubReddit.urlString isEqualToString:urlString]) {
			subReddit = tempSubReddit;
			index = i;
			break;
		}
	}
	
	if (subReddit == nil) {
		refreshCount --;
		if (refreshCount == 0) {
			self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh"];
			[self.refreshControl endRefreshing];

			editItem.enabled = YES;
		}
		return;
	}
	
	subReddit.loading = NO;
	subReddit.unshowedCount = 0;
	[subReddit.photosArray removeAllObjects];

//	[self.tableView reloadData];
	[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index + 1 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];

	refreshCount --;
	if (refreshCount == 0) {
		self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh"];
		[self.refreshControl endRefreshing];
		
		editItem.enabled = YES;
	}
}

// NIProcessorDelegate
+ (id)processor:(id)processor processObject:(id)object error:(NSError **)processingError {
	if (![object isKindOfClass:[NSDictionary class]]) {
		return nil;
	}
	
	NSDictionary *data = [object objectForKey:@"data"];
	if (data == nil)
		return nil;
	
	NSDictionary *array = [data objectForKey:@"children"];
	if (array == nil)
		return nil;
	
	NSMutableArray *photosArray = [NSMutableArray arrayWithCapacity:array.count];
	for (NSDictionary *item in array) {
		NSDictionary *itemData = [item objectForKey:@"data"];
		
		PhotoItem *photo = [[PhotoItem alloc] init];
		photo.idString = [itemData objectForKey:@"id"];
		photo.nameString = [itemData objectForKey:@"name"];
		
		NSString *permalinkString = [itemData objectForKey:@"permalink"];
		if (!permalinkString)
			photo.permalinkString = @"";
		else if ([permalinkString hasPrefix:@"http"])
			photo.permalinkString = permalinkString;
		else
			photo.permalinkString = [NSString stringWithFormat:@"https://www.reddit.com%@.compact", permalinkString];
		
		photo.titleString = [RedditsAppDelegate stringByRemoveHTML:[itemData objectForKey:@"title"]];
		photo.urlString = [RedditsAppDelegate getImageURL:[itemData objectForKey:@"url"]];

		NSString *thumbnailString = [itemData objectForKey:@"thumbnail"];

		// If the thumbnail string is empty or a default value, AND the URL is an imgur link,
        // then we go to imgur to get the thumbnail
        // Small square [90x90px]:    http://i.imgur.com/46dFas.jpg
        if ([photo.urlString hasPrefix:@"http://i.imgur.com/"] || [photo.urlString hasPrefix:@"http://imgur.com/"]) {
			NSString *lastComp = [photo.urlString lastPathComponent];
			photo.thumbnailString = [NSString stringWithFormat:@"http://i.imgur.com/%@s.png", [lastComp stringByDeletingPathExtension]];
		}
		else {
			photo.thumbnailString = [RedditsAppDelegate getImageURL:thumbnailString];
		}
        
		NSString *extension = [[photo.urlString pathExtension] lowercaseString];
		if (extension.length != 0 && ([extension isEqualToString:@"jpg"] || 
									  [extension isEqualToString:@"jpeg"] || 
									  [extension isEqualToString:@"gif"] || 
									  [extension isEqualToString:@"png"] || 
									  [extension isEqualToString:@"tiff"] || 
									  [extension isEqualToString:@"tif"] || 
									  [extension isEqualToString:@"bmp"]
									  )) {
            
			// However if the thumbnail is empty or a default value and NOT an imgur link,
            // we instead use the FULL image URL as the thumbnail...
            // Do we need this?  Does this result in us downloading photos twice if we don't have
            // an otherwise usable thumbnail?  (Aman 20-Dec-2011)
            if ((photo.thumbnailString.length == 0) ||
                [photo.thumbnailString isEqualToString:@"nsfw"] ||
                [photo.thumbnailString isEqualToString:@"default"])
				photo.thumbnailString = photo.urlString;
			
            [photosArray addObject:photo];
		}
		
	}
	
	NSString *afterString = [data objectForKey:@"after"];
	
	NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:photosArray, @"photos", afterString, @"after", nil];

	return dictionary;
}

- (void)addSubReddit:(SubRedditItem *)subReddit {
	if (![appDelegate checkNetworkReachable:YES])
		return;

	self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Refreshing..."];
	[self.refreshControl beginRefreshing];
	
	editItem.enabled = NO;
	
	subReddit.loading = YES;
	
	refreshCount ++;
	
	NSURL *url = [NSURL URLWithString:subReddit.urlString];
	NIProcessorHTTPRequest* albumRequest = [NIJSONKitProcessorHTTPRequest requestWithURL:url usingCache:nil];
	albumRequest.shouldAttemptPersistentConnection = NO;
	albumRequest.timeOutSeconds = 30;
    albumRequest.userAgentString = @"Mozilla/5.0 (iPhone; CPU iPhone OS 10_1 like Mac OS X) AppleWebKit/602.2.14 (KHTML, like Gecko) Mobile/14B72";
	albumRequest.delegate = self;
	albumRequest.processorDelegate = (id)[self class];
	[refreshQueue addOperation:albumRequest];
}

- (NSString *)cacheKeyForPhotoIndex:(NSInteger)photoIndex {
	if (photoIndex == -1) {
		if (appDelegate.favoritesItem.photosArray.count == 0)
			return @"";
		
		return [[appDelegate.favoritesItem.photosArray objectAtIndex:0] thumbnailString];
	}
	else {
		SubRedditItem *subReddit = [subRedditsArray objectAtIndex:photoIndex];
		if (subReddit.photosArray.count == 0)
			return @"";
		
		return [[subReddit.photosArray objectAtIndex:0] thumbnailString];
	}
}

- (void)requestImageFromSource:(NSString *)source photoIndex:(NSInteger)photoIndex {
//	if (![appDelegate checkNetworkReachable:NO])
//		return;

	if (source.length == 0)
		return;
	
	if ([activeRequests containsObject:source]) {
		return;
	}
	
	NSURL *url = [NSURL URLWithString:source];
	
	__block NIHTTPRequest __weak *readOp = [NIHTTPRequest requestWithURL:url usingCache:[ASIDownloadCache sharedCache]];
	readOp.cacheStoragePolicy = ASICachePermanentlyCacheStoragePolicy;
	readOp.shouldAttemptPersistentConnection = NO;
	readOp.timeOutSeconds = 30;
	
	NSString *photoIndexKey = [self cacheKeyForPhotoIndex:photoIndex];
	
	[readOp setCompletionBlock:^{
		UIImage *image = [UIImage imageWithData:[readOp responseData]];
		
		NSInteger index = -2;
		if (photoIndex == -1) {
			index = -1;
		}
		else {
			for (NSInteger i = 0; i < subRedditsArray.count; i ++) {
				NSString *keyString = [self cacheKeyForPhotoIndex:i];
				if ([keyString isEqualToString:photoIndexKey]) {
					index = i;
					break;
				}
			}
		}
		
		if (index != -2) {
			if (image && (subRedditsArray.count + 1 > photoIndex || photoIndex == -1)) {
				NSInteger x, y, w, h;
				if (image.size.width > THUMB_WIDTH * 2 && image.size.height > THUMB_HEIGHT * 2) {
					float imgRatio = image.size.width / image.size.height;
					if (imgRatio < 1) {
						w = THUMB_WIDTH;
						h = w / imgRatio;
						x = 0;
						y = (THUMB_HEIGHT - h) / 2;
					}
					else if (imgRatio > 1) {
						h = THUMB_HEIGHT;
						w = h * imgRatio;
						x = (THUMB_WIDTH - w) / 2;
						y = 0;
					}
					else {
						w = THUMB_WIDTH;
						h = THUMB_HEIGHT;
						x = 0.0;
						y = 0.0;
					}
				}
				else {
					w = image.size.width;
					h = image.size.height;
					x = (THUMB_WIDTH - w) / 2;
					y = (THUMB_HEIGHT - h) / 2;
				}
				
				UIGraphicsBeginImageContextWithOptions(CGSizeMake(THUMB_WIDTH, THUMB_HEIGHT), NO, screenScale);
				CGContextSetFillColorWithColor(UIGraphicsGetCurrentContext(), [UIColor whiteColor].CGColor);
				CGContextFillRect(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, THUMB_WIDTH, THUMB_HEIGHT));
				CGRect rect = CGRectMake(x, y, w, h);
				[image drawInRect:rect];
				UIImage *thumbImage = UIGraphicsGetImageFromCurrentImageContext();
				UIGraphicsEndImageContext();
				
				[thumbnailImageCache storeObject:thumbImage withName:photoIndexKey];
				MainViewCell *cell = (MainViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index + 1 inSection:0]];
				[cell setThumbImage:thumbImage animated:YES];
			}
		}
		
		[activeRequests removeObject:source];
	}];
	
	[readOp setFailedBlock:^{
		[activeRequests removeObject:source];
	}];
	
	[readOp setQueuePriority:NSOperationQueuePriorityNormal];
	
	[activeRequests addObject:source];
	[queue addOperation:readOp];
}

- (IBAction)onSettingsButton:(id)sender {
	SettingsViewController *settingsViewController = [[SettingsViewController alloc] initWithNibName:@"SettingsViewController" bundle:nil];
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:settingsViewController];
	[self presentViewController:navigationController animated:YES completion:nil];
}

- (void)removeSubRedditOperations:(SubRedditItem *)subReddit {
	if (subReddit.photosArray.count > 0) {
		NSString *thumbnailString = [[subReddit.photosArray objectAtIndex:0] thumbnailString];
		for (ASIHTTPRequest *request in queue.operations) {
			if ([[request.originalURL absoluteString] isEqualToString:thumbnailString]) {
				[request clearDelegatesAndCancel];
				[activeRequests removeObject:thumbnailString];
				break;
			}
		}
	}
}

@end

//
//  AppDelegate.m
//  KeyValueCache
//
//  Created by Guillaume on 31/08/2015.
//
//

#import "AppDelegate.h"
#import <Parse/Parse.h>

#define CURRENT_FILE_NAME             ({ char *s = strrchr(__FILE__, '/'); (s != NULL) ? (s + 1) : NULL; })
#define LogFuncCall()                 NSLog(@"%s (%s line %d)", __PRETTY_FUNCTION__, CURRENT_FILE_NAME, __LINE__)
#define LogInfo(format, ...)          NSLog((@"Info : " format), ##__VA_ARGS__)
#define LogError(error, format, ...)  NSLog((@"Error : " format @" (%s, line %d) error : %@"), ##__VA_ARGS__, CURRENT_FILE_NAME, __LINE__, error)

NSString *NSStringFromPFCachePolicy(PFCachePolicy cachePolicy);


@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	[Parse setApplicationId:@"" clientKey:@""];
	[Parse setLogLevel:PFLogLevelDebug];

	[self runTest];

	return YES;
}

- (void)runTest
{
	// This will fill and ultimately block the serial cache dispatch queue
	[self runQueriesWithCachePolicy:kPFCachePolicyNetworkOnly afterDelay:0 count:100];
	[self runQueriesWithCachePolicy:kPFCachePolicyNetworkOnly afterDelay:5 count:100];
	[self runQueriesWithCachePolicy:kPFCachePolicyNetworkOnly afterDelay:10 count:100];
	[self runQueriesWithCachePolicy:kPFCachePolicyNetworkOnly afterDelay:15 count:100];

	// After a few seconds cache queries take forever.
	[self runQueriesWithCachePolicy:kPFCachePolicyCacheOnly afterDelay:0 count:5];
	[self runQueriesWithCachePolicy:kPFCachePolicyCacheOnly afterDelay:1 count:5];
	[self runQueriesWithCachePolicy:kPFCachePolicyCacheOnly afterDelay:5 count:5];
	[self runQueriesWithCachePolicy:kPFCachePolicyCacheOnly afterDelay:10 count:5];
	[self runQueriesWithCachePolicy:kPFCachePolicyCacheOnly afterDelay:20 count:5];
	[self runQueriesWithCachePolicy:kPFCachePolicyCacheOnly afterDelay:30 count:5];
	[self runQueriesWithCachePolicy:kPFCachePolicyCacheOnly afterDelay:40 count:5];
}

- (void)runQueriesWithCachePolicy:(PFCachePolicy)cachePolicy afterDelay:(int)delay count:(int)count
{
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		for (int i = 0 ; i < count ; i++) {
			[self runTestQueryWithId:[NSString stringWithFormat:@"(%2d, %2d)", delay, i] cachePolicy:cachePolicy];
		}
	});
}

- (void)runTestQueryWithId:(id)queryId cachePolicy:(PFCachePolicy)cachePolicy
{
	PFQuery *testQuery = [PFQuery queryWithClassName:@"TestClass"];
	[testQuery whereKey:@"key" equalTo:@(arc4random_uniform(2000))];
	testQuery.cachePolicy = cachePolicy;

	NSDate *start = [NSDate date];
	[testQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
		NSDate *end = [NSDate date];
		NSTimeInterval queryTime = [end timeIntervalSinceDate:start];
		if (objects && !error) {
			LogInfo(@"Query with id: %@, cachePolicy: %@ succeded in %.2f s.", queryId, NSStringFromPFCachePolicy(cachePolicy), queryTime);
		} else if (error && error.code == kPFErrorCacheMiss) {
			LogInfo(@"Query with id: %@ ended with cache miss after %.2f s.", queryId, queryTime);
		} else {
			LogError(error, @"Query with with id: %@, cachePolicy: %@ failed after %.2f s.", queryId, NSStringFromPFCachePolicy(cachePolicy), queryTime);
		}
	}];
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
	LogFuncCall();
}

@end


NSString *NSStringFromPFCachePolicy(PFCachePolicy cachePolicy)
{
	switch (cachePolicy) {
		case kPFCachePolicyIgnoreCache:
			return @"ignoreCache";
		case kPFCachePolicyCacheOnly:
			return @"cacheOnly";
		case kPFCachePolicyNetworkOnly:
			return @"networkOnly";
		case kPFCachePolicyCacheElseNetwork:
			return @"cacheElseNetwork";
		case kPFCachePolicyNetworkElseCache:
			return @"networkElseCache";
		case kPFCachePolicyCacheThenNetwork:
			return @"cacheThenNetwork";
	}
	return nil;
}

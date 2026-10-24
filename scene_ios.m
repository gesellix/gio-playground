//go:build ios

#import <UIKit/UIKit.h>
#include "_cgo_export.h"

static void report(NSString *s) {
	playgroundSceneEvent((char *)[s UTF8String]);
}

// observeScenes logs the scene notifications, to see when UIKit connects
// and disconnects a scene and whether the process survives it.
void observeScenes(void) {
	if (@available(iOS 13.0, *)) {
		NSNotificationCenter *c = NSNotificationCenter.defaultCenter;
		NSOperationQueue *q = NSOperationQueue.mainQueue;
		[c addObserverForName:UISceneWillConnectNotification object:nil queue:q usingBlock:^(NSNotification *n) {
			report([NSString stringWithFormat:@"will connect %@", ((UIScene *)n.object).session.persistentIdentifier]);
		}];
		[c addObserverForName:UISceneDidDisconnectNotification object:nil queue:q usingBlock:^(NSNotification *n) {
			report([NSString stringWithFormat:@"did disconnect %@", ((UIScene *)n.object).session.persistentIdentifier]);
		}];
		[c addObserverForName:UISceneDidActivateNotification object:nil queue:q usingBlock:^(NSNotification *n) {
			report(@"did activate");
		}];
		[c addObserverForName:UISceneDidEnterBackgroundNotification object:nil queue:q usingBlock:^(NSNotification *n) {
			report(@"did enter background");
		}];
	}
}

void disconnectScenes(void) {
	dispatch_async(dispatch_get_main_queue(), ^{
		if (@available(iOS 13.0, *)) {
			UIApplication *app = UIApplication.sharedApplication;
			if (app.connectedScenes.count == 0) {
				report(@"no connected scene (app delegate life cycle?)");
			}
			for (UIScene *scene in app.connectedScenes) {
				report([NSString stringWithFormat:@"requesting the destruction of %@", scene.session.persistentIdentifier]);
				[app requestSceneSessionDestruction:scene.session options:nil errorHandler:^(NSError *err) {
					report([NSString stringWithFormat:@"destruction failed: %@", err.localizedDescription]);
				}];
			}
		}
	});
}

int hasInfoKey(const char *key) {
	return [NSBundle.mainBundle objectForInfoDictionaryKey:@(key)] != nil;
}

int hasResource(const char *name, const char *ext) {
	return [NSBundle.mainBundle pathForResource:@(name) ofType:@(ext)] != nil;
}

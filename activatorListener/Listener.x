#include <dispatch/dispatch.h>
#import <libactivator/libactivator.h>
#import "../Shared.h"
#import "../NSTask.h"

@interface Listener : NSObject <LAListener>
@end

@implementation Listener

static Listener *myDataSource;

- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event forListenerName:(NSString *)listenerName {
	NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];

	int _i = 0;
	for(int i = 0; i < [[prefs objectForKey:@"Groups"] count]; i++){
		if([[[[prefs objectForKey:@"Groups"][i] objectForKey:@"id"] stringValue] isEqualToString:[listenerName componentsSeparatedByString:@"."][3]]){
			_i = i;
		}
	}

	NSTask *task = [[NSTask alloc] init];
	task.launchPath = @"/usr/bin/tweakdisabler";


	if(![[[prefs objectForKey:@"Groups"][_i] objectForKey:@"state"] boolValue]){
		task.arguments = @[@"disable", listenerName];
		[[prefs objectForKey:@"Groups"][_i] setObject:[NSNumber numberWithBool:1] forKey:@"state"];
	} else {
		task.arguments = @[@"enable", listenerName];
		[[prefs objectForKey:@"Groups"][_i] setObject:[NSNumber numberWithBool:0] forKey:@"state"];
	}

	NSLog(@"[DEBUG] BOOL: %hhd", [[[prefs objectForKey:@"Groups"][_i] objectForKey:@"state"] boolValue]);

	[prefs writeToFile:plistPath atomically:YES];
	HBLogDebug(@"Notification Content: %@", listenerName);
	if([self tweakListIsEmpty:listenerName]){
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Respring?"
                               message:@"Do you still want to respring even though you didn't specify any tweaks that should be disabled?"
                               preferredStyle:UIAlertControllerStyleAlert];
 
            UIAlertAction* respring = [UIAlertAction actionWithTitle:@"Respring" style:UIAlertActionStyleDestructive
                handler:^(UIAlertAction * action) {
                    [task launch];
                    [task waitUntilExit];
                }];

            UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                handler:^(UIAlertAction * action) {}];
            
            [alert addAction:cancel];
            [alert addAction:respring];
            [[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:alert animated:YES completion:nil];
        } else {
            [task launch];
            [task waitUntilExit];
        }
}

- (UIImage *)activator:(LAActivator *)activator requiresIconForListenerName:(NSString *)listenerName scale:(CGFloat)scale {
	return [UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/TweakDisabler.bundle/icon.png"];
}
- (UIImage *)activator:(LAActivator *)activator requiresSmallIconForListenerName:(NSString *)listenerName scale:(CGFloat)scale {
	return [UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/TweakDisabler.bundle/icon.png"];
}

+ (void)load
{
        @autoreleasepool {
                myDataSource = [[Listener alloc] init];
        }
}

- (id)init {
        if ((self = [super init])) {
			[self registerListeners];
        }
        return self;
}

-(void)registerListeners {
	HBLogDebug(@"registerEvents");
	NSError *err;
	NSArray * dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Library/Activator/Listeners/" error:&err];

	if(!err){
		for(id name in dirContents){
			if([name containsString:@"com.h4ckua11.tweakdisabler"]){
				HBLogDebug(@"%@", name);
				[LASharedActivator registerListener:self forName:name];
			}
		}
	} else {
		HBLogDebug(@"Something went wrong...");
	}
}

- (BOOL)tweakListIsEmpty:(NSString*)group {
    NSDictionary *tweakList = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"/var/mobile/Library/Preferences/com.h4ckua11.tweakdisabler/tweakGroup.%@.disabled", [group componentsSeparatedByString:@"."][3]]];
    NSMutableArray *tweaks = [[NSMutableArray alloc] init];
    if(!tweakList){
        return YES;
    } else {
        for(id tweak in tweakList) {
            if([[tweakList objectForKey:tweak] boolValue]){
                [tweaks addObject:tweak];
            }
        }
		if(![tweaks count]){
			return YES;
		} else {
			return NO;
		}
    }
}

@end
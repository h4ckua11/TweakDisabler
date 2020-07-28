#import "../Shared.h"
#import "../NSTask.h"
#import <ControlCenterUIKit/CCUIToggleModule.h>

@interface ControlCenterModule : CCUIToggleModule {
    BOOL _selected;
}

- (UIImage *)iconGlyph;
- (UIImage *)selectedIconGlyph;
- (UIColor *)selectedColor;
- (BOOL)isSelected;
- (void)setSelected:(BOOL)selected;
@end

@implementation ControlCenterModule

- (UIImage *)iconGlyph {
    return [UIImage imageNamed:@"icon" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
}

- (UIImage *)selectedIconGlyph {
    return [UIImage imageNamed:@"icon" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
}

- (UIColor *)selectedColor {
    return [UIColor orangeColor];
}

- (BOOL)isSelected {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:plistPath]; //load prefs

    if(![[prefs objectForKey:@"Groups"] count]){
        return NO;
    }

    NSString *listenerName = [prefs objectForKey:@"ccGroup"];
    int _i = 0;
    if([listenerName containsString:@"com.h4ckua11.tweakdisabler."]){
        for(int i = 0; i < [[prefs objectForKey:@"Groups"] count]; i++){
            if([[[[prefs objectForKey:@"Groups"][i] objectForKey:@"id"] stringValue] isEqualToString:[listenerName componentsSeparatedByString:@"."][3]]){
                _i = i;
            }
        }
    } else {
        return NO;
    }

    if([[[prefs objectForKey:@"Groups"][_i] objectForKey:@"state"] boolValue]){
        return YES;
    }
    return NO;
}

- (void)setSelected:(BOOL)selected {
    NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
    NSString *listenerName = [prefs objectForKey:@"ccGroup"];

    if (!prefs) {
        prefs = [[NSMutableDictionary alloc] init];
    }

    if(!listenerName){
        listenerName = @"NO_GROUP_SPECIFIED";
        selected = NO;

        NSLog(@"[DEBUG] NO listenername specified");
        dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Assign Group"
                               message:@"Please go and assign a TweakGroup that should be disabled.\nYou can find that option under Settings->TweakDisabler->YourGroup and at the bottom there is a button that says \"Assign To CC Module\"."
                               preferredStyle:UIAlertControllerStyleAlert];
 
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
            handler:^(UIAlertAction * action) {}];
 
        [alert addAction:defaultAction];

        [[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:alert animated:YES completion:nil];
        });
    } else if(![listenerName containsString:@"com.h4ckua11.tweakdisabler."]){
        listenerName = @"WRONG_GROUP_FORMAT";
        selected = NO;

        dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error"
                               message:@"An Error occured while trying to read the tweakgroup name.\nTry to go to settings and reassign your group to the CC Module again."
                               preferredStyle:UIAlertControllerStyleAlert];
 
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
            handler:^(UIAlertAction * action) {}];
 
        [alert addAction:defaultAction];

        [[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:alert animated:YES completion:nil];
        });
    } else if(![[prefs objectForKey:@"Groups"] count]){
        listenerName = @"WRONG_GROUP_FOR_CCTOGGLE";
        selected = NO;

        dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error"
                               message:@"oof...\nThe Group that you assigned isn't there anymore. Please assign it again."
                               preferredStyle:UIAlertControllerStyleAlert];
 
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
            handler:^(UIAlertAction * action) {}];
 
        [alert addAction:defaultAction];

        [[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:alert animated:YES completion:nil];
        });
    } else {

        NSTask *task = [[NSTask alloc] init];
        task.launchPath = @"/usr/bin/tweakdisabler";

        if(selected){
            // NSLog(@"[DEBUG] Disable: Posting Notification with ListenerName: %@", listenerName);
            task.arguments = @[@"disable", listenerName];
        } else {
            // NSLog(@"[DEBUG] Enable: Posting Notification with ListenerName: %@", listenerName);
            task.arguments = @[@"enable", listenerName];
        }

        // NSLog(@"[DEBUG] Launching Task...");

        int _i = 0;
        for(int i = 0; i < [[prefs objectForKey:@"Groups"] count]; i++){
            if([[[[prefs objectForKey:@"Groups"][i] objectForKey:@"id"] stringValue] isEqualToString:[listenerName componentsSeparatedByString:@"."][3]]){
                _i = i;
            }
        }

        if([self tweakListIsEmpty:listenerName]){
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Respring?"
                               message:@"Do you still want to respring even though you didn't specify any tweaks that should be disabled?"
                               preferredStyle:UIAlertControllerStyleAlert];
 
            UIAlertAction* respring = [UIAlertAction actionWithTitle:@"Respring" style:UIAlertActionStyleDestructive
                handler:^(UIAlertAction * action) {
                    // NSLog(@"[DEBUG] Setting selected State into plist");
                    NSLog(@"[DEBUG] SELECTED: %hhd", selected);
                    [[prefs objectForKey:@"Groups"][_i] setObject:[NSNumber numberWithBool:selected] forKey:@"state"];
                    [prefs writeToFile:plistPath atomically:YES];

                    _selected = selected;
                    [super refreshState];
                    [task launch];
                    [task waitUntilExit];
                }];

            UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                handler:^(UIAlertAction * action) {
                    _selected = NO;
                    [super refreshState];
                }];
            
            [alert addAction:cancel];
            [alert addAction:respring];
            [[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:alert animated:YES completion:nil];
        } else {
            [[prefs objectForKey:@"Groups"][_i] setObject:[NSNumber numberWithBool:selected] forKey:@"state"];
            [prefs writeToFile:plistPath atomically:YES];

            [task launch];
            [task waitUntilExit];
        }
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
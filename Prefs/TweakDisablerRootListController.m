#import "TweakDisablerRootListController.h"

@implementation TweakDisablerRootListController

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadSpecifiers];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Apply" style:UIBarButtonItemStyleDone target:self action:@selector(respring)];
}

-(void)respring {
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/sbreload";
    [task launch];
    [task waitUntilExit];
}

-(void)addGroup{
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    NSNumber *ID;
    NSMutableArray *ids = [[NSMutableArray alloc] init];

    if(!prefs) {
        prefs = [[NSDictionary alloc] init];
    }

    for(int i=0; i < [[prefs objectForKey:@"Groups"] count]; i++){
        [ids addObject:[[prefs objectForKey:@"Groups"][i] objectForKey:@"id"]];
    }

    NSNumber *max=[ids valueForKeyPath:@"@max.self"];

    int big = [max intValue];
    int small = 1;

    if([[prefs objectForKey:@"Groups"] count] > 0){
        while (small<=big) {
            if ([ids containsObject:[NSNumber numberWithInt:small]]) {
                if(small==big){
                    ID = [NSNumber numberWithInt:big+1];
                }
            } else {
                ID = [NSNumber numberWithInt:small];
                break;
            }
            small++;
        }
    } else {
        ID = [NSNumber numberWithInt:1];
    }

    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir;
    if(![fm fileExistsAtPath:[NSString stringWithFormat:@"/Library/Activator/Listeners/com.h4ckua11.tweakdisabler.%@/", ID] isDirectory:&isDir]){
        [fm createDirectoryAtPath:[NSString stringWithFormat:@"/Library/Activator/Listeners/com.h4ckua11.tweakdisabler.%@/", ID] withIntermediateDirectories:YES attributes:nil error:NULL];
    }

    NSString *path = [NSString stringWithFormat:@"/Library/Activator/Listeners/com.h4ckua11.tweakdisabler.%@/Info.plist", ID];
    NSMutableDictionary *listener = [[NSMutableDictionary alloc] init];
    [listener setObject:@"Description" forKey:@"description"];
    [listener setObject:@"TweakDisabler" forKey:@"group"];
    [listener setObject:[NSString stringWithFormat:@"Default - %@", ID] forKey:@"title"];
    [listener setObject:@[@"springboard",@"lockscreen",@"application"] forKey:@"compatibale-modes"];
    NSLog(@"[DEBUG] FileContents: %@", listener);
    [listener writeToFile:path atomically:YES];
    NSLog(@"[DEBUG] Created Activator Listener");

    [self createLinkCell:[NSString stringWithFormat:@"Default - %@", ID] ID:ID];
    // NSLog(@"[DEBUG] Refresh");
    [self reloadSpecifiers];
}

-(void)createLinkCell:(NSString*)label ID:(NSNumber*)ID {
    NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
    if(!prefs){
        prefs = [[NSMutableDictionary alloc] init];
    }
    NSMutableArray *items = [prefs objectForKey:@"Groups"];
    if(!items){
        items = [[NSMutableArray alloc] init];
    }
    NSDictionary *linkCell = @{@"label":label,@"id":ID};
    [items addObject:linkCell];

    [prefs removeObjectForKey:@"Groups"];
    [prefs setObject:items forKey:@"Groups"];
    [prefs writeToFile:plistPath atomically:YES];
    NSLog(@"[DEBUG] Should have written to file");
}

-(void)dealloc {
    _specifiers = [[NSMutableArray alloc] init];
}

-(void)showInstructions {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Instructions"
                               message:@"Oh I see that you don't know what to do with this tweak...\n Don't worry it's quite easy.\n\nSo basically you can add a group where you can select Tweaks, that are installed on your iDevice, that should be disabled/enabled when pressing the CC Toggle or triggering the Activator listener.\nSo for each group there's gonna be an Activator listener after hitting \"Apply\".\nBtw if you scroll to the bottom of a specific group you can change the name and description of the Activator listener and the Groupname itself.\nFYI if you want to trigger a group from the CC Module you have to hit \"Assign To CC Module\".\n You can find that option under Settings->TweakDisabler->YourGroup and at the bottom there is a button that says \"Assign To CC Module\"."
                               preferredStyle:UIAlertControllerStyleAlert];
 
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"I think I got it 👌" style:UIAlertActionStyleDefault
        handler:^(UIAlertAction * action) {}];
 
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)resetToDefaults {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Reset"
                               message:@"Do you really want to reset all settings?"
                               preferredStyle:UIAlertControllerStyleAlert];
 
    UIAlertAction* reset = [UIAlertAction actionWithTitle:@"Reset" style:UIAlertActionStyleDestructive
        handler:^(UIAlertAction * action) {
            NSError *error;
            NSFileManager *fm = [NSFileManager defaultManager];

            NSMutableArray *pathsToDelete = [[NSMutableArray alloc] init];
    
            NSString *prefsPath = @"/var/mobile/Library/Preferences/com.h4ckua11.tweakdisabler.plist";
            NSString *tweakSettingsPath = @"/var/mobile/Library/Preferences/com.h4ckua11.tweakdisabler/";
            NSString *activatorListenersPath = @"/Library/Activator/Listeners/";

            NSArray *listeners = [fm contentsOfDirectoryAtPath:activatorListenersPath error:&error];
            for(NSString *listener in listeners){
                if([listener containsString:@"com.h4ckua11.tweakdisabler"]){
                    [pathsToDelete addObject:[NSString stringWithFormat:@"%@%@/", activatorListenersPath, listener]];
                }
            }

            [pathsToDelete addObject:prefsPath];
            [pathsToDelete addObject:tweakSettingsPath];
            
            // Deleting Files
            for(NSString *path in pathsToDelete){
                [fm removeItemAtPath:path error:&error];
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                [self dismissViewControllerAnimated:YES completion:^{
                    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Restored Settings"
                               message:@"Successfully restored settings.\nYou have to respring to apply the changes."
                               preferredStyle:UIAlertControllerStyleAlert];
 
                    UIAlertAction* respring = [UIAlertAction actionWithTitle:@"Respring" style:UIAlertActionStyleCancel
                    handler:^(UIAlertAction * action) {
                        NSTask *task = [[NSTask alloc] init];
                        task.launchPath = @"/usr/bin/killall";
                        task.arguments = @[@"-9",@"SpringBoard"];
                        [task launch];
                        [task waitUntilExit];
                    }];
                    
                    [alert addAction:respring];
                    [self presentViewController:alert animated:YES completion:nil];
                }];
            });
    }];
    
    UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
        handler:^(UIAlertAction * action) {}];
 
    [alert addAction:cancel];
    [alert addAction:reset];
    [self presentViewController:alert animated:YES completion:nil];
}

// Background Stuff...

- (NSArray *)specifiers {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:plistPath];
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
        if(prefs){
            for(int i = 0; i < [[prefs objectForKey:@"Groups"] count]; i++){
                PSSpecifier* specifier = [PSSpecifier preferenceSpecifierNamed:[[prefs objectForKey:@"Groups"][i] objectForKey:@"label"]
                                                        target:self
                                                           set:NULL
                                                           get:NULL
                                                        detail:NSClassFromString(@"GroupsViewController")
                                                          cell:PSLinkCell
                                                          edit:Nil];
                [specifier setProperty:@YES forKey:@"enabled"];
                [_specifiers insertObject:specifier atIndex:(i+2)];
            }
        }
	}

	return _specifiers;
}

- (PSSpecifier *)specifierForKey:(NSString *)key {
    for (PSSpecifier *spec in _specifiers) {
        NSString *keyInLoop = [spec propertyForKey:@"key"];
        if ([keyInLoop isEqualToString:key]) {
            return spec;
        }
    }
    return nil;
}

- (id)readPreferenceValue:(PSSpecifier *)specifier {
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    id object = [dict objectForKey:[specifier propertyForKey:@"key"]];
    if (!object) {
        object = [specifier propertyForKey:@"default"];
    }
    return object;
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
    if (!dict) {
        dict = [[NSMutableDictionary alloc] init];
    }
    [dict setObject:value forKey:[specifier propertyForKey:@"key"]];
    [dict writeToFile:plistPath atomically:YES];
}

- (void)reloadSpecifierForValue:(NSString *)specifier {
	dispatch_async(dispatch_get_main_queue(), ^{
		[self reloadSpecifier:[self specifierForKey:specifier] animated:YES];
	});
}

@end

#import "GroupsViewController.h"

static NSString *tweakGroupPath;
static NSString *ID;
int _i;

@implementation GroupsViewController

-(void)viewDidLoad {
    [super viewDidLoad];

    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir;
    if(![fm fileExistsAtPath:@"/var/mobile/Library/Preferences/com.h4ckua11.tweakdisabler/" isDirectory:&isDir]){
        [fm createDirectoryAtPath:@"/var/mobile/Library/Preferences/com.h4ckua11.tweakdisabler/" withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    for(int i=0; i < [[prefs objectForKey:@"Groups"] count]; i++){
        if([[[prefs objectForKey:@"Groups"][i] objectForKey:@"label"] isEqualToString:self.title]){
            tweakGroupPath = [NSString stringWithFormat:@"/var/mobile/Library/Preferences/com.h4ckua11.tweakdisabler/tweakGroup.%@.disabled", [[prefs objectForKey:@"Groups"][i] objectForKey:@"id"]];
            ID = [[prefs objectForKey:@"Groups"][i] objectForKey:@"id"];
            _i = i;
        }
    }

    UIBarButtonItem *trash = [[UIBarButtonItem alloc] initWithTitle:@"Delete" style:UIBarButtonItemStyleDone target:self action:@selector(deleteSelf)];
    trash.tintColor = [UIColor systemRedColor];
    self.navigationItem.rightBarButtonItem = trash;
}

-(void)editTitle {
    NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
    NSString *listenerPath = [NSString stringWithFormat:@"/Library/Activator/Listeners/com.h4ckua11.tweakdisabler.%@/Info.plist", ID];
    NSMutableDictionary *activatorListener = [NSMutableDictionary dictionaryWithContentsOfFile:listenerPath];

    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Edit Title"
                               message:@"Set your new title."
                               preferredStyle:UIAlertControllerStyleAlert];
 
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault
        handler:^(UIAlertAction * action) {
                if([[[prefs objectForKey:@"Groups"][_i] objectForKey:@"label"] isEqualToString:self.title]){
                    // NSLog(@"[DEBUG] Got Title: %@", [[prefs objectForKey:@"Groups"][ID] objectForKey:@"label"]);
                    // NSLog(@"[DEBUG] Text: %@", [[alert textFields][0] text]);
                    [activatorListener setObject:[alert textFields][0].text forKey:@"title"];
                    [[prefs objectForKey:@"Groups"][_i] setObject:[alert textFields][0].text forKey:@"label"];
                    self.title = [alert textFields][0].text;
                    [prefs writeToFile:plistPath atomically:YES];
                    [activatorListener writeToFile:listenerPath atomically:YES];
                    [self showShortAlert:@"Changed Title!"];
        }
    }];
        
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:defaultAction];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {}]; 
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)editDescription {
    NSString *listenerPath = [NSString stringWithFormat:@"/Library/Activator/Listeners/com.h4ckua11.tweakdisabler.%@/Info.plist", ID];
    NSMutableDictionary *activatorListener = [NSMutableDictionary dictionaryWithContentsOfFile:listenerPath];

    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Edit Description"
                               message:[NSString stringWithFormat:@"Set your new description.\nOld: %@",[activatorListener objectForKey:@"description"]]
                               preferredStyle:UIAlertControllerStyleAlert];
 
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault
        handler:^(UIAlertAction * action) {
                // NSLog(@"[DEBUG] Got Description: %@", [[prefs objectForKey:@"Groups"][ID] objectForKey:@"label"]);
                // NSLog(@"[DEBUG] Text: %@", [[alert textFields][0] text]);
                [activatorListener setObject:[alert textFields][0].text forKey:@"description"];
                [activatorListener writeToFile:listenerPath atomically:YES];
                [self showShortAlert:@"Changed Description!"];
    }];
        
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:defaultAction];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {}]; 
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)assignToCCModule {
    NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
    [prefs setObject:[NSString stringWithFormat:@"com.h4ckua11.tweakdisabler.%@", ID] forKey:@"ccGroup"];
    [prefs writeToFile:plistPath atomically:YES];
    [self showShortAlert:[NSString stringWithFormat:@"Assigned \"%@\" to the CC Module!", self.title]];
}

-(void)deleteSelf {
    NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
    NSString *listenerPath = [NSString stringWithFormat:@"/Library/Activator/Listeners/com.h4ckua11.tweakdisabler.%@/", ID];
    NSLog(@"[DEBUG] Deleting %@", listenerPath);
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Delete Group"
                                message:@"Do you really want to delete this group?"
                                preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
        for(int i=0; i < [[prefs objectForKey:@"Groups"] count]; i++){
            if([[[prefs objectForKey:@"Groups"][i] objectForKey:@"label"] isEqualToString:self.title]){
                [[prefs objectForKey:@"Groups"] removeObjectAtIndex:i];
                [prefs writeToFile:plistPath atomically:YES];
            }
        }

        NSError *error;
        NSFileManager *fm = [[NSFileManager alloc] init];
        [fm removeItemAtPath:tweakGroupPath error:&error];
        [fm removeItemAtPath:listenerPath error:&error];
        if(error){[self.navigationController popToRootViewControllerAnimated:YES];}
        [self.navigationController popToRootViewControllerAnimated:YES];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

-(NSMutableArray *)specifiers {
    if(!_specifiers) {
        NSLog(@"[DEBUG] Settings Specifiers");
        _specifiers = [[NSMutableArray alloc] init];

        [_specifiers addObject:[PSSpecifier groupSpecifierWithName:@"Select tweaks to disable"]];

         NSArray *dontShowThoseTweaks = @[@"TweakDisabler", @"MobileSafety", @"PreferenceLoader", @"000_Choicy", @"ChoicySB", @" TweakConfigurator", @"TweakRestrictor", @"zzzzzzUnSub", @"NoSubstitute", @"NoSubstitute12", @"PalBreakSB"];
         for (NSString *dylib in [self getDylibList]) {
            if (![dontShowThoseTweaks containsObject:dylib]) {
                PSSpecifier *specifier = [PSSpecifier preferenceSpecifierNamed:dylib target:self set:@selector(setPreferenceValue:specifier:) get:@selector(readPreferenceValue:) detail:nil cell:PSSwitchCell edit:nil];
                [specifier setProperty:@YES forKey:@"enabled"];
                [specifier setProperty:dylib forKey:@"key"];
                [_specifiers addObject:specifier];
            }
        }

        PSSpecifier *footer = [PSSpecifier groupSpecifierWithName:@"Edit Title and Description"];
        [footer setProperty:@"You can change the title and description of this group here. The changes also affect the Activator listeners and the CC module." forKey:@"footerText"];
        [_specifiers addObject:footer];

        PSSpecifier *editTitle = [PSSpecifier preferenceSpecifierNamed:@"Edit Title" target:self set:nil get:nil detail:nil cell:PSButtonCell edit:nil];
        editTitle->action = @selector(editTitle);
        [_specifiers addObject:editTitle];

        PSSpecifier *editDescription = [PSSpecifier preferenceSpecifierNamed:@"Edit Description" target:self set:nil get:nil detail:nil cell:PSButtonCell edit:nil];
        editDescription->action = @selector(editDescription);
        [_specifiers addObject:editDescription];

        PSSpecifier *footerAssignCC = [PSSpecifier groupSpecifierWithName:@"Assign to CC Module"];
        [footerAssignCC setProperty:@"Press this button to assign this group to the Control Center Module." forKey:@"footerText"];
        [_specifiers addObject:footerAssignCC];

        PSSpecifier *assignToCCModule = [PSSpecifier preferenceSpecifierNamed:@"Assign To CC Module" target:self set:nil get:nil detail:nil cell:PSButtonCell edit:nil];
        assignToCCModule->action = @selector(assignToCCModule);
        [_specifiers addObject:assignToCCModule];

        NSLog(@"[DEBUG] Set Specifiers");
    }
    return _specifiers;
}

-(NSArray *)getDylibList {
    NSURL *pathToDylibs = [NSURL fileURLWithPath:@"/Library/MobileSubstrate/DynamicLibraries"].URLByResolvingSymlinksInPath;
    NSArray *folderContents = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:pathToDylibs includingPropertiesForKeys:nil options:0 error:nil];

    NSMutableArray *dylibs = [[NSMutableArray alloc] init];
    for (NSURL *item in folderContents) {
        if ([item.pathExtension isEqualToString:@"dylib"] && [item checkResourceIsReachableAndReturnError:nil]) {
            [dylibs addObject:item.path.lastPathComponent.stringByDeletingPathExtension];
        }
    }
    
    NSLog(@"[DEBUG] Got %lu Dylibs.", [dylibs count]);
    return [[dylibs copy] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}

- (id)readPreferenceValue:(PSSpecifier *)specifier {
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:tweakGroupPath];
    id object = [dict objectForKey:[specifier propertyForKey:@"key"]];
    if (!object) {
        object = [specifier propertyForKey:@"default"];
    }
    return object;
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:tweakGroupPath];
    if (!dict) {
        dict = [[NSMutableDictionary alloc] init];
    }
    [dict setObject:value forKey:[specifier propertyForKey:@"key"]];
    [dict writeToFile:tweakGroupPath atomically:YES];
}

-(void)showShortAlert:(NSString*)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil
                               message:message
                               preferredStyle:UIAlertControllerStyleAlert];
 
        [self presentViewController:alert animated:YES completion:^{
            [NSThread sleepForTimeInterval:0.7f];
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
    });
}

@end
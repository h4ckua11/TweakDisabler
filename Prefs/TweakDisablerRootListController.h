#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <Cephei/HBPreferences.h>
#import <CepheiPrefs/HBRootListController.h>
#import "../Shared.h"
#import "../NSTask.h"
#import "GroupsViewController.h"

@interface TweakDisablerRootListController : HBRootListController

-(void)addGroup;

// Background Stuff...
- (NSArray *)specifiers;
- (PSSpecifier *)specifierForKey:(NSString *)key;
- (id)readPreferenceValue:(PSSpecifier *)specifier;
- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier;
- (void)reloadSpecifierForValue:(NSString *)specifier;

@end

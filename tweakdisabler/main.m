#import <stdio.h>
#import <string.h>
#import <dlfcn.h>
#import "../NSTask.h"
#define FLAG_PLATFORMIZE (1 << 1)

void fixSetuidForChimera() {
    void *handle = dlopen("/usr/lib/libjailbreak.dylib", RTLD_LAZY);
    if (!handle) {
        return;
    }
    
    dlerror();
    typedef void (*fix_entitle_prt_t)(pid_t pid, uint32_t what);
    fix_entitle_prt_t enetitle_ptr = (fix_entitle_prt_t)dlsym(handle, "jb_oneshot_entitle_now");
    const char *dlsym_error = dlerror();
    if (dlsym_error) {
        return;
    }
    enetitle_ptr(getpid(), FLAG_PLATFORMIZE);
    
    dlerror();
    typedef void (*fix_setuid_prt_t)(pid_t pid);
    fix_setuid_prt_t setuid_ptr = (fix_setuid_prt_t)dlsym(handle,"jb_oneshot_fix_setuid_now");
    dlsym_error = dlerror();
    if (dlsym_error) {
        return;
    }
    
    setuid_ptr(getpid());
    setuid(0);
    setgid(0);
    setuid(0);
    setgid(0);
}

NSArray *getTweakList(NSString *group){
    NSDictionary *tweakList = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"/var/mobile/Library/Preferences/com.h4ckua11.tweakdisabler/tweakGroup.%@.disabled", [group componentsSeparatedByString:@"."][3]]];
    NSMutableArray *tweaks = [[NSMutableArray alloc] init];
    if(!tweakList){
        return nil;
    } else {
        for(id tweak in tweakList) {
            if([[tweakList objectForKey:tweak] boolValue]){
                [tweaks addObject:tweak];
            }
        }
        return tweaks;
    }
}

void renameFiles(NSArray *files, NSString *oldExtension, NSString *newExtension) {
    NSError *err;
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *dylibPath = @"/Library/MobileSubstrate/DynamicLibraries";

    for(NSString *tweak in files){
        NSLog(@"[DEBUG] Renaming %@.%@ to %@.%@", tweak, oldExtension, tweak, newExtension);
        if([fm fileExistsAtPath:[NSString stringWithFormat:@"%@/%@.%@", dylibPath, tweak, oldExtension]]){
            [fm moveItemAtPath:[NSString stringWithFormat:@"%@/%@.%@", dylibPath, tweak, oldExtension] toPath:[NSString stringWithFormat:@"%@/%@.%@", dylibPath, tweak, newExtension] error:&err];
        } else {
            NSLog(@"[DEBUG] Didn't found file at Path: %@/%@.%@", dylibPath, tweak, oldExtension);
        }
    }
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/killall";
    task.arguments = @[@"-9", @"SpringBoard"];

    NSLog(@"[DEBUG] Tweak Count: %d", ![files count]);

    [task launch];
    [task waitUntilExit];
}

void disable(NSString *group){
    NSLog(@"[DEBUG] DISABLING GROUP %@", group);
    // NSLog(@"[DEBUG] List Of Tweaks: %@", [getTweakList(group) componentsJoinedByString:@","]);
    renameFiles(getTweakList(group), @"dylib",@"disabled");
}

void enable(NSString *group){
    NSLog(@"[DEBUG] ENABLING GROUP %@", group);
    // NSLog(@"[DEBUG] List Of Tweaks: %@", [getTweakList(group) componentsJoinedByString:@","]);
    renameFiles(getTweakList(group), @"disabled", @"dylib");
}

int main(int argc, char *argv[], char *envp[]) {
    if (argc < 3){
        printf("[DEBUG] You Must specify Enable or Disable and a Group BundleID\n");
        return 1;
    }

    setuid(0);
    if (getuid() != 0) {
        fixSetuidForChimera();
    }

    if(!strcmp(argv[1], "enable")){
        if([@(argv[2]) containsString:@"com.h4ckua11.tweakdisabler."]){
            enable(@(argv[2]));
        } else {
            printf("[DEBUG] Wrong Group Format\n");
            return 1;
        }
    } else if(!strcmp(argv[1], "disable")){
        if([@(argv[2]) containsString:@"com.h4ckua11.tweakdisabler."]){
            disable(@(argv[2]));
        } else {
            printf("[DEBUG] Wrong Group Format\n");
            return 1;
        }
    } else {
        printf("[DEBUG] Specify \"enable\" or \"disable\"\n");
    }

    return 0;
}

/*
#import "../Shared.h"
#import "../NSTask.h"

%hook SpringBoard

-(void)applicationDidFinishLaunching:(id)arg1 {
    %orig;
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(tweakdisabler:) name:@"com.h4ckua11.tweakdisabler" object:nil];
    NSLog(@"[DEBUG] Added NSNotificationObserver");
}

%new
-(void)tweakdisabler:(NSNotification *)noti {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    NSString *listenerName = [noti.userInfo objectForKey:@"listener"];
    NSString *shouldDo = [noti.userInfo objectForKey:@"shouldDo"];
    NSString *tweakGroupPath = [[NSString alloc] init];

    if(!prefs){
        prefs = [[NSDictionary alloc] init];
    }

    if([listenerName isEqualToString:@"NO_GROUP_SPECIFIED"]){
        NSLog(@"[DEBUG] NO_GROUP_SPECIFIED!");
        tweakGroupPath = @"NO_GROUP_SPECIFIED";
    } else if([listenerName isEqualToString:@"WRONG_GROUP_FORMAT"]){
        NSLog(@"[DEBUG] WRONG_GROUP_FORMAT!");
        tweakGroupPath = @"WRONG_GROUP_FORMAT";
    } else {
        tweakGroupPath = [NSString stringWithFormat:@"/var/mobile/Library/Preferences/com.h4ckua11.tweakdisabler/tweakGroup.%@.disabled", [listenerName componentsSeparatedByString:@"."][3]];
    
        NSLog(@"[DEBUG] Got Notification: %@", listenerName);
        NSLog(@"[DEBUG] TweakPath: %@", tweakGroupPath);
        NSLog(@"[DEBUG] ShouldDo: %@", shouldDo);

        NSTask *task = [[NSTask alloc] init];
        task.launchPath = @"/usr/bin/tweakdisabler";

        if([shouldDo isEqualToString:@"disable"]) {
            task.arguments = @[shouldDo];
            [task launch];
            [task waitUntilExit];
            NSLog(@"[DEBUG] Disable Tweaks");
        } else if([shouldDo isEqualToString:@"enable"]) {
            task.arguments = @[shouldDo];
            [task launch];
            [task waitUntilExit];
            NSLog(@"[DEBUG] Enable Tweaks");
        } else {
            NSLog(@"[DEBUG] Something Went wrong");
        }
    }
}

%end
*/
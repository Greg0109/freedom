#include "FDPRootListController.h"

@implementation FDPRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}

	return _specifiers;
}

-(void)viewDidLoad {
	[super viewDidLoad];
	UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:@"Apply" style:UIBarButtonItemStylePlain target:self action:@selector(killall)];
	self.navigationItem.rightBarButtonItem = button;
	((UITableView *)[self.view.subviews objectAtIndex:0]).keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
	[self checkdate];
}
- (id)readPreferenceValue:(PSSpecifier*)specifier {
	NSString *path = [NSString stringWithFormat:@"/User/Library/Preferences/%@.plist", specifier.properties[@"defaults"]];
	NSMutableDictionary *settings = [NSMutableDictionary dictionary];
	[settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:path]];
	return (settings[specifier.properties[@"key"]]) ?: specifier.properties[@"default"];
}
- (void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
	NSString *path = [NSString stringWithFormat:@"/User/Library/Preferences/%@.plist", specifier.properties[@"defaults"]];
	NSMutableDictionary *settings = [NSMutableDictionary dictionary];
	[settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:path]];
	[settings setObject:value forKey:specifier.properties[@"key"]];
	[settings writeToFile:path atomically:YES];
	CFStringRef notificationName = (__bridge CFStringRef)specifier.properties[@"PostNotification"];
	if (notificationName) {
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), notificationName, NULL, NULL, YES);
	}
}

- (void)killall {
    NSTask *killallSpringBoard = [[NSTask alloc] init];
    [killallSpringBoard setLaunchPath:@"/usr/bin/killall"];
    [killallSpringBoard setArguments:@[@"-9", @"SpringBoard"]];
    [killallSpringBoard launch];
}

-(void)displayalert {
	NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:@"/User/Library/Preferences/com.greg0109.freedomprefs.plist"];
	BOOL *bypasspassword = prefs[@"bypasspassword"] ? [prefs[@"bypasspassword"] boolValue] : NO;
	NSString *passwordstring = prefs[@"passwordstring"] ? [prefs[@"passwordstring"] stringValue] : @"password";
	if (bypasspassword) {
		UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Freedom!" message:nil preferredStyle:UIAlertControllerStyleAlert];
		[alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
			NSString *savedValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"SilentMaps"];
			if ([savedValue isEqual:@"(null)"]) {
				textField.placeholder = @"x;x;x;";
			} else {
				textField.text = savedValue;
			}
		}];
		UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
			if (![[[alertController textFields][0] text] isEqualToString:passwordstring]) {
				[self displayalert];
			}
		}];
		[alertController addAction:cancelAction];
		[[[UIApplication sharedApplication] keyWindow].rootViewController presentViewController:alertController animated:YES completion:^{}]; // For when theres no uiview
	} else {
		UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Freedom!" message:nil preferredStyle:UIAlertControllerStyleAlert];
		UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
			[self displayalert];
		}];
		[alertController addAction:cancelAction];
		[[[UIApplication sharedApplication] keyWindow].rootViewController presentViewController:alertController animated:YES completion:^{}]; // For when theres no uiview
	}
}

-(void)checkdate {
	NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:@"/User/Library/Preferences/com.greg0109.freedomprefs.plist"];
	NSString *starthour = prefs[@"starthour"] ? [prefs[@"starthour"] stringValue] : @"14:00";
	NSString *endhour = prefs[@"endhour"] ? [prefs[@"endhour"] stringValue] : @"16:00";
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"HH:mm"];
	NSDate *currentHour = [dateFormatter dateFromString:[dateFormatter stringFromDate:[NSDate date]]];
	NSDate *starthourdate = [dateFormatter dateFromString:starthour];
	NSDate *endhourdate = [dateFormatter dateFromString:endhour];
	if ([currentHour compare:starthourdate] == NSOrderedDescending && [currentHour compare:endhourdate] == NSOrderedAscending) {
		[self displayalert];
	}
}

@end

#import <UIKit/UIKit.h>

@interface SBApplication
@property (nonatomic,readonly) NSString * bundleIdentifier;                                                                                     //@synthesize bundleIdentifier=_bundleIdentifier - In the implementation block
@property (nonatomic,readonly) NSString * iconIdentifier;
@property (nonatomic,readonly) NSString * displayName;
@end

@interface SpringBoard : UIApplication
-(void)_simulateHomeButtonPress;
@end

@interface SBLockStateAggregator : NSObject
+(id)sharedInstance;
-(id)init;
-(void)dealloc;
-(id)description;
-(unsigned long long)lockState;
-(void)_updateLockState;
-(BOOL)hasAnyLockState;
-(id)_descriptionForLockState:(unsigned long long)arg1 ;
@end

BOOL enabled;
BOOL bypasspassword;
NSString *starthour;
NSString *endhour;
NSString *passwordstring;

BOOL isItLocked() {
	BOOL locked;
	int check =  [[%c(SBLockStateAggregator) sharedInstance] lockState];
	if (check == 3 || check == 1) {
		locked = TRUE;
	} else {
		locked = FALSE;
	}
	return locked;
}

static BOOL checkDate() {
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"HH:mm"];
	NSDate *currentHour = [dateFormatter dateFromString:[dateFormatter stringFromDate:[NSDate date]]];
	NSDate *starthourdate = [dateFormatter dateFromString:starthour];
	NSDate *endhourdate = [dateFormatter dateFromString:endhour];
	if ([currentHour compare:starthourdate] == NSOrderedDescending && [currentHour compare:endhourdate] == NSOrderedAscending) {
		NSLog(@"Freedom: Check date yes");
		return YES;
	}
	return NO;
}

static BOOL appMutedStatus(NSString *bundleID) {
	NSMutableDictionary *applist = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.greg0109.freedomapplist"];
	if ([[applist valueForKey:bundleID] boolValue] && checkDate()) {
		return YES;
	} else {
		return NO;
	}
}

static void displayAlert() {
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
				displayAlert();
			}
		}];
		[alertController addAction:cancelAction];
		[[[UIApplication sharedApplication] keyWindow].rootViewController presentViewController:alertController animated:YES completion:^{}]; // For when theres no uiview
	} else {
		UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Freedom!" message:nil preferredStyle:UIAlertControllerStyleAlert];
		UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
			[(SpringBoard *)[UIApplication sharedApplication] _simulateHomeButtonPress];
		}];
		[alertController addAction:cancelAction];
		[[[UIApplication sharedApplication] keyWindow].rootViewController presentViewController:alertController animated:YES completion:^{}]; // For when theres no uiview
	}
}

%hook SpringBoard
-(void)frontDisplayDidChange:(SBApplication *)arg1 {
	NSLog(@"Freedom: %@", arg1.bundleIdentifier);
	if (!isItLocked() && appMutedStatus(arg1.bundleIdentifier)) {
		displayAlert();
	}
	%orig;
}
%end

%ctor {
	NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:@"/User/Library/Preferences/com.greg0109.freedomprefs.plist"];
	enabled = prefs[@"enabled"] ? [prefs[@"enabled"] boolValue] : NO;
	starthour = prefs[@"starthour"] ? [prefs[@"starthour"] stringValue] : @"14:00";
	endhour = prefs[@"endhour"] ? [prefs[@"endhour"] stringValue] : @"16:00";
	bypasspassword = prefs[@"bypasspassword"] ? [prefs[@"bypasspassword"] boolValue] : NO;
	passwordstring = prefs[@"passwordstring"] ? [prefs[@"passwordstring"] stringValue] : @"password";
	NSLog(@"Freedom: %@ - %@", starthour, endhour);
	if (enabled) {
		%init();
	}
}
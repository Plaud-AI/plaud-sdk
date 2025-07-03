#import "PLLanguageManager.h"
#import <UIKit/UIKit.h>
#import "LocalizationHelper.h"
#import "NSBundle+Language.h"

static NSString *const kLanguageKey = @"PLSelectedLanguage";
static NSString *const kAppleLanguagesKey = @"AppleLanguages";
static NSString *const kLanguageDidChangeNotification = @"PLLanguageDidChangeNotification";

@interface PLLanguageManager()
@property (nonatomic, strong) NSBundle *currentBundle;
@end

@implementation PLLanguageManager

+ (instancetype)shared {
    static PLLanguageManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PLLanguageManager alloc] init];
    });
    return instance;
}

+ (void)setupDefaultLanguageEarly {
    static NSString *const kLanguageKey = @"PLSelectedLanguage";
    static NSString *const kAppleLanguagesKey = @"AppleLanguages";
    
    // Check if language has been set before
    NSNumber *savedLanguage = [[NSUserDefaults standardUserDefaults] objectForKey:kLanguageKey];
    if (!savedLanguage) {
        // Force set to English on fresh install
        [[NSUserDefaults standardUserDefaults] setObject:@(PLLanguageTypeEnglish) forKey:kLanguageKey];
        [[NSUserDefaults standardUserDefaults] setObject:@[@"en"] forKey:kAppleLanguagesKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        // Apply English setting immediately
        NSString *path = [[NSBundle mainBundle] pathForResource:@"en" ofType:@"lproj"];
        NSBundle *languageBundle = [NSBundle bundleWithPath:path];
        if (languageBundle) {
            [NSBundle setLanguageBundle:languageBundle];
        }
    }
}

- (void)setupDefaultLanguage {
    NSNumber *savedLanguage = [[NSUserDefaults standardUserDefaults] objectForKey:kLanguageKey];
    if (!savedLanguage) {
        // Use English interface by default on fresh install
        self.currentLanguage = PLLanguageTypeEnglish;
        [self saveLanguageSelection];
    } else {
        self.currentLanguage = (PLLanguageType)[savedLanguage integerValue];
    }
    
    // Apply the language
    [self applyCurrentLanguage];
}

- (void)switch:(PLLanguageType)language to:(void (^)(void))completion {
    if (self.currentLanguage == language) {
        if (completion) {
            completion();
        }
        return;
    }
    
    // Get language before switching, used for displaying prompt text
    PLLanguageType previousLanguage = self.currentLanguage;
    
    // Save new language setting
    self.currentLanguage = language;
    [self saveLanguageSelection];
    [self applyCurrentLanguage];  // Ensure language setting is applied immediately
    
    // Show restart required prompt
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = UIApplication.sharedApplication.windows.firstObject;
        UIViewController *topVC = window.rootViewController;
        while (topVC.presentedViewController) {
            topVC = topVC.presentedViewController;
        }
        
        // Use language before switching to display prompt text
        NSString *title = NSLocalizedString(@"language.switch.title", nil);
        NSString *subtitle = NSLocalizedString(@"language.switch.subtitle", nil);
        NSString *message = NSLocalizedString(@"language.switch.message", nil);
        NSString *okButton = NSLocalizedString(@"language.switch.restart_now", nil);
        NSString *cancelButton = NSLocalizedString(@"language.switch.restart_later", nil);
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                     message:[NSString stringWithFormat:@"%@\n\n%@", subtitle, message]
                                                              preferredStyle:UIAlertControllerStyleAlert];
        
        // Set title and message text styles
        NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:title];
        [attributedTitle addAttribute:NSFontAttributeName 
                              value:[UIFont systemFontOfSize:20 weight:UIFontWeightBold] 
                              range:NSMakeRange(0, title.length)];
        [alert setValue:attributedTitle forKey:@"attributedTitle"];
        
        // Create styled message text
        NSMutableAttributedString *attributedMessage = [[NSMutableAttributedString alloc] 
            initWithString:[NSString stringWithFormat:@"%@\n\n%@", subtitle, message]];
        [attributedMessage addAttribute:NSFontAttributeName 
                                value:[UIFont systemFontOfSize:16 weight:UIFontWeightMedium] 
                                range:NSMakeRange(0, subtitle.length)];
        [attributedMessage addAttribute:NSFontAttributeName 
                                value:[UIFont systemFontOfSize:14] 
                                range:NSMakeRange(subtitle.length + 2, message.length)];
        [alert setValue:attributedMessage forKey:@"attributedMessage"];
        
        // Set button style and action
        UIAlertAction *restartAction = [UIAlertAction actionWithTitle:okButton
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction * _Nonnull action) {
            if (completion) {
                completion();
            }
            
            // Use delay to ensure language setting has been saved and takes effect
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                exit(0);
            });
        }];
        
        UIAlertAction *laterAction = [UIAlertAction actionWithTitle:cancelButton
                                                            style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * _Nonnull action) {
            if (completion) {
                completion();
            }
        }];
        
        // Set button color
        [restartAction setValue:[UIColor systemBlueColor] forKey:@"titleTextColor"];
        [laterAction setValue:[UIColor grayColor] forKey:@"titleTextColor"];
        
        [alert addAction:laterAction];
        [alert addAction:restartAction];
        
        // Set popup appearance
        if (@available(iOS 13.0, *)) {
            alert.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
        }
        
        [topVC presentViewController:alert animated:YES completion:nil];
    });
}

- (void)reloadAllViewControllers:(UIViewController *)viewController {
    // This method is no longer needed
}

- (NSString *)localizedStringForKey:(NSString *)key {
    if (self.currentBundle) {
        NSString *value = [self.currentBundle localizedStringForKey:key value:nil table:nil];
        if (value) {
            return value;
        }
    }
    return NSLocalizedString(key, nil);
}

- (void)applyCurrentLanguage {
    NSString *languageCode = [self currentLanguageCode];
    
    // Load new language bundle
    NSString *path = [[NSBundle mainBundle] pathForResource:languageCode ofType:@"lproj"];
    NSBundle *languageBundle = [NSBundle bundleWithPath:path];
    
    // Apply language switch immediately
    [NSBundle setLanguageBundle:languageBundle];
    
    // Set language for next launch
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@[languageCode] forKey:kAppleLanguagesKey];
    [defaults synchronize];
    
    self.currentBundle = languageBundle ?: [NSBundle mainBundle];
}

- (NSString *)currentLanguageCode {
    switch (self.currentLanguage) {
        case PLLanguageTypeEnglish:
            return @"en";
        case PLLanguageTypeSimplifiedChinese:
            return @"zh-Hans";
        default:
            return @"en";
    }
}

- (NSString *)currentLanguageName {
    switch (self.currentLanguage) {
        case PLLanguageTypeEnglish:
            return @"English";
        case PLLanguageTypeSimplifiedChinese:
            return @"Simplified Chinese";
        default:
            return @"English";
    }
}

- (void)saveLanguageSelection {
    [[NSUserDefaults standardUserDefaults] setObject:@(self.currentLanguage) forKey:kLanguageKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end 

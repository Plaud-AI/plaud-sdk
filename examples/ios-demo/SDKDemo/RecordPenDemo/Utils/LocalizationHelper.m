#import "LocalizationHelper.h"

@implementation LocalizationHelper

+ (NSString *)localizedString:(NSString *)key {
    NSString *result = NSLocalizedString(key, nil);
    
#ifdef DEBUG
    // If the returned string is the same as the key, it means no localized string was found
    if ([result isEqualToString:key]) {
        NSLog(@"⚠️ Localization missing for key: %@", key);
        NSLog(@"Current language: %@", [self currentLanguage]);
        NSLog(@"Bundle: %@", [NSBundle mainBundle]);
        NSLog(@"Localizations: %@", [NSBundle mainBundle].localizations);
        
        // Check if Localizable.strings file exists
        NSString *path = [[NSBundle mainBundle] pathForResource:@"Localizable" ofType:@"strings" inDirectory:nil forLocalization:[self currentLanguage]];
        NSLog(@"Localizable.strings path: %@", path);
    }
#endif
    
    return result;
}

+ (NSString *)localizedStringWithFormat:(NSString *)key, ... {
    va_list args;
    va_start(args, key);
    NSString *format = NSLocalizedString(key, nil);
    
#ifdef DEBUG
    // If the returned string is the same as the key, it means no localized string was found
    if ([format isEqualToString:key]) {
        NSLog(@"⚠️ Localization missing for key: %@", key);
    }
#endif
    
    NSString *result = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    return result;
}

+ (NSString *)currentLanguage {
    NSString *language = [NSBundle mainBundle].preferredLocalizations.firstObject;
#ifdef DEBUG
    NSLog(@"Current language: %@", language);
#endif
    return language ?: @"en";
}

+ (NSString *)displayNameForLanguage:(NSString *)code {
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:code];
    NSString *displayName = [locale displayNameForKey:NSLocaleIdentifier value:code];
    return displayName ?: code;
}

@end 

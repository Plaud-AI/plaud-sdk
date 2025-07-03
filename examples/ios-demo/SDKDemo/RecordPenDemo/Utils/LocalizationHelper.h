#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LocalizationHelper : NSObject

+ (NSString *)localizedString:(NSString *)key;
+ (NSString *)localizedStringWithFormat:(NSString *)key, ...;

// Get current language
+ (NSString *)currentLanguage;


// Get language display name
+ (NSString *)displayNameForLanguage:(NSString *)code;

@end

NS_ASSUME_NONNULL_END 

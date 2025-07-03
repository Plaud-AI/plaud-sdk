#import "NSBundle+Language.h"
#import <objc/runtime.h>

static NSBundle *_languageBundle = nil;
static BOOL _methodsExchanged = NO;

@implementation NSBundle (Language)

+ (void)setLanguageBundle:(NSBundle *)bundle {
    _languageBundle = bundle;
    
    // Only swap methods on first call
    if (!_methodsExchanged) {
        _methodsExchanged = YES;
        // Swap mainBundle's localizedStringForKey method
        Method originalMethod = class_getInstanceMethod([NSBundle class], @selector(localizedStringForKey:value:table:));
        Method swizzledMethod = class_getInstanceMethod([NSBundle class], @selector(languageLocalizedStringForKey:value:table:));
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

+ (NSBundle *)languageBundle {
    return _languageBundle;
}

- (NSString *)languageLocalizedStringForKey:(NSString *)key value:(NSString *)value table:(NSString *)tableName {
    if (_languageBundle && self == [NSBundle mainBundle]) {
        return [_languageBundle localizedStringForKey:key value:value table:tableName];
    }
    // Call original implementation (since methods have been swapped, this actually calls the original localizedStringForKey:value:table:)
    return [self languageLocalizedStringForKey:key value:value table:tableName];
}

@end 
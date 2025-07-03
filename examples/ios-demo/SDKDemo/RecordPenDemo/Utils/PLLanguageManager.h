#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, PLLanguageType) {
    PLLanguageTypeSimplifiedChinese = 0,
    PLLanguageTypeEnglish = 1
};

@interface PLLanguageManager : NSObject

@property (nonatomic, assign) PLLanguageType currentLanguage;

+ (instancetype)shared;
+ (void)setupDefaultLanguageEarly;

- (void)setupDefaultLanguage;
- (void)switch:(PLLanguageType)language to:(void (^)(void))completion;

- (NSString *)currentLanguageCode;
- (NSString *)currentLanguageName;

@end

NS_ASSUME_NONNULL_END 

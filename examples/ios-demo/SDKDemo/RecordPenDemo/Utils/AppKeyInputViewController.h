#import <UIKit/UIKit.h>

@class LocalizationHelper;

NS_ASSUME_NONNULL_BEGIN

@protocol AppKeyInputViewControllerDelegate <NSObject>
- (void)appKeyInputDidFinishWithAppKey:(NSString *)appKey appSecret:(NSString *)appSecret;
- (void)appKeyInputDidCancel;
@end

@interface AppKeyInputViewController : UIViewController

@property (nonatomic, weak) id<AppKeyInputViewControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END 
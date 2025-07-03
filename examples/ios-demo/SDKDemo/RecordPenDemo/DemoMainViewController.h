#import <UIKit/UIKit.h>
@import PlaudDeviceBasicSDK;

NS_ASSUME_NONNULL_BEGIN

@protocol PLLanguageSelectionDelegate;

@interface DemoMainViewController : UIViewController <PLLanguageSelectionDelegate>

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *descriptionLabel;
@property (nonatomic, strong) UIButton *startScanButton;

- (void)startScanButtonTapped:(UIButton *)sender;

@end

NS_ASSUME_NONNULL_END 

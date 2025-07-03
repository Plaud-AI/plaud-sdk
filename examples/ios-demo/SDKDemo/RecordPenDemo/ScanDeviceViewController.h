#import <UIKit/UIKit.h>
@import PenBleSDK;
@import PlaudDeviceBasicSDK;

NS_ASSUME_NONNULL_BEGIN


@interface ScanDeviceViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, PlaudDeviceAgentProtocol>
- (void)connectToDevice:(BleDevice *)device;
@end

NS_ASSUME_NONNULL_END 

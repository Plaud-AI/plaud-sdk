#import <CoreBluetooth/CoreBluetooth.h>
#import "DemoMainViewController.h"
#import "ScanDeviceViewController.h"
#import "AppKeyInputViewController.h"
#import "LocalizationHelper.h"
#import "LocalizationMacros.h"
@import PlaudDeviceBasicSDK;
//@import FirebaseAnalytics;
#import "PLLanguageManager.h"

#if __has_include("SDKDemo-Swift.h")
#import "SDKDemo-Swift.h"
#endif

#if __has_include("SDKDemoInternal-Swift.h")
#import "SDKDemoInternal-Swift.h"
#endif


@interface BluetoothChecker : NSObject <CBCentralManagerDelegate>
@property (strong, nonatomic) CBCentralManager *centralManager;
@property (nonatomic, copy) void (^statusHandler)(BOOL isEnabled, NSString *authStatus);
@end

@implementation BluetoothChecker

- (instancetype)initWithStatusHandler:(void (^)(BOOL, NSString *))handler {
    self = [super init];
    if (self) {
        _statusHandler = handler;
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
    }
    return self;
}

#pragma mark - Bluetooth Status Detection
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    BOOL isBluetoothEnabled = NO;
    NSString *authStatus = @"";
    
    switch (central.state) {
        case CBManagerStatePoweredOn:
            isBluetoothEnabled = YES;
            authStatus = LocalizedString(@"ble.status.authorized");
            break;
        case CBManagerStatePoweredOff:
            isBluetoothEnabled = NO;
            authStatus = LocalizedString(@"ble.status.powered_off");
            break;
        case CBManagerStateUnauthorized:
            authStatus = LocalizedString(@"ble.status.unauthorized");
            break;
        case CBManagerStateUnsupported:
            authStatus = LocalizedString(@"ble.status.unsupported");
            break;
        case CBManagerStateResetting:
            authStatus = LocalizedString(@"ble.status.resetting");
            break;
        default:
            authStatus = LocalizedString(@"ble.status.unknown");
            break;
    }
    
    if (self.statusHandler) {
        self.statusHandler(isBluetoothEnabled, authStatus);
    }
}

+ (BOOL)bluetoothAuthorizationStatus {
    BOOL isAuthorization = NO;
    CBPeripheralManager *peripheralManager = [[CBPeripheralManager alloc] init];
    CBManagerState state = peripheralManager.state;
    NSLog(@"bluetoothAuthorizationStatus: %ld", (long)state);
    
    switch (state) {
        case CBManagerStatePoweredOn:
        case CBManagerStatePoweredOff:
            isAuthorization = YES;
            break;
            
        case CBManagerStateUnknown: {
            CBManagerAuthorization authorization;
            
            if (@available(iOS 13.1, *)) {
                authorization = [CBPeripheralManager authorization];
            } else {
                authorization = peripheralManager.authorization;
            }
            
            NSLog(@"bluetoothAuthorizationStatus: %ld", (long)authorization);
            isAuthorization = (authorization == CBManagerAuthorizationAllowedAlways);
            break;
        }
            
        default:
            isAuthorization = NO;
            break;
    }
    
    return isAuthorization;
}

@end


@interface DemoMainViewController () <AppKeyInputViewControllerDelegate, PLLanguageSelectionDelegate>
@property (nonatomic, strong) PlaudDeviceAgent* deviceAgent;

@end

@implementation DemoMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.deviceAgent = [PlaudDeviceAgent shared];
    
    [self showAppKeyPopupIfNeed];
        
    [self setupUI];
    [self setupConstraints];
    
    // Enable shake gesture
    [self becomeFirstResponder];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self resignFirstResponder];
}

- (BOOL)showAppKeyPopupIfNeed {
    // Please remember bindToken, it can only be changed after unbinding. If you have no special preference, you can use the device SN number for easy memory
    // Test appKey: @"plaud-zoem8KYd-1748487531106"
    // Test appSecret: @"aksk_hAyGDINVTsG3vsob2Shqku3iBqgI7clL"
    
    // Check if AppKey and AppSecret are saved
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *savedAppKey = [defaults stringForKey:@"PlaudAppKey"];
    NSString *savedAppSecret = [defaults stringForKey:@"PlaudAppSecret"];
    
    if (savedAppKey && savedAppSecret) {
        [self.deviceAgent initSDKWithHostName:@"DemoApp" appKey:savedAppKey
                                    appSecret:savedAppSecret bindToken:@"123456789" extra:@{}];
        return NO;
    } else {
        // Show input dialog
        [self showAppKeyInputDialog];
        return YES;
    }
    return NO;
}

- (void)showAppKeyInputDialog {
    AppKeyInputViewController *inputVC = [[AppKeyInputViewController alloc] init];
    //inputVC.modalPresentationStyle = UIModalPresentationOverFullScreen;
    inputVC.delegate = self;
    [self presentViewController:inputVC animated:YES completion:nil];
}

#pragma mark - AppKeyInputViewControllerDelegate

- (void)appKeyInputDidFinishWithAppKey:(NSString *)appKey appSecret:(NSString *)appSecret {
    // Save AppKey and AppSecret
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:appKey forKey:@"PlaudAppKey"];
    [defaults setObject:appSecret forKey:@"PlaudAppSecret"];
    [defaults synchronize];
    
    // Initialize SDK
    [self.deviceAgent initSDKWithHostName:@"DemoApp" appKey:appKey
                                appSecret:appSecret bindToken:@"123456789" extra:@{}];
}

- (void)appKeyInputDidCancel {
    // User cancelled input, you can add corresponding handling logic here
}

- (void)setupUI {
    // Setup title label
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.numberOfLines = 1;  // Limit to single line
    self.titleLabel.adjustsFontSizeToFitWidth = YES;  // Automatically adjust font size to fit width
    self.titleLabel.minimumScaleFactor = 0.8;  // Minimum scale factor
    NSMutableAttributedString *titleText = [[NSMutableAttributedString alloc] initWithString:LocalizedString(@"main.title")];
    [titleText addAttribute:NSFontAttributeName
                    value:[UIFont systemFontOfSize:32 weight:UIFontWeightBold]
                    range:NSMakeRange(0, titleText.length)];
    [titleText addAttribute:NSForegroundColorAttributeName
                    value:[UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0]
                    range:NSMakeRange(0, titleText.length)];
    self.titleLabel.attributedText = titleText;
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.titleLabel];
    
    // Setup description label
    self.descriptionLabel = [[UILabel alloc] init];
    self.descriptionLabel.numberOfLines = 0;
    NSMutableAttributedString *descriptionText = [[NSMutableAttributedString alloc] initWithString:LocalizedString(@"main.description")];
    [descriptionText addAttribute:NSFontAttributeName
                          value:[UIFont systemFontOfSize:16]
                          range:NSMakeRange(0, descriptionText.length)];
    [descriptionText addAttribute:NSForegroundColorAttributeName
                          value:[UIColor colorWithRed:0.45 green:0.45 blue:0.45 alpha:1.0]
                          range:NSMakeRange(0, descriptionText.length)];
    self.descriptionLabel.attributedText = descriptionText;
    self.descriptionLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.descriptionLabel];
    
    // Setup button (scan device) - main style
    self.startScanButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.startScanButton setTitle:LocalizedString(@"main.button.scan_device") forState:UIControlStateNormal];
    [self.startScanButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.startScanButton.backgroundColor = [UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:1.0];
    self.startScanButton.layer.cornerRadius = 14;
    self.startScanButton.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    self.startScanButton.layer.shadowColor = [UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:0.3].CGColor;
    self.startScanButton.layer.shadowOffset = CGSizeMake(0, 4);
    self.startScanButton.layer.shadowOpacity = 1;
    self.startScanButton.layer.shadowRadius = 8;
    [self.startScanButton addTarget:self action:@selector(startScanButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.startScanButton];
}

- (void)setupConstraints {
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.descriptionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.startScanButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    // Title label constraints
    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabel.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:60],
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:24],
        [self.titleLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24],
        [self.titleLabel.heightAnchor constraintEqualToConstant:44]
    ]];
    
    // Description label constraints
    [NSLayoutConstraint activateConstraints:@[
        [self.descriptionLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:24],
        [self.descriptionLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:24],
        [self.descriptionLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24],
        [self.descriptionLabel.heightAnchor constraintGreaterThanOrEqualToConstant:44]
    ]];
    
    // Button constraints - further from bottom
    [NSLayoutConstraint activateConstraints:@[
        [self.startScanButton.heightAnchor constraintEqualToConstant:56],
        [self.startScanButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:24],
        [self.startScanButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24],
        [self.startScanButton.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-90] 
    ]];
}

#pragma mark - Button Actions

- (void)startScanButtonTapped:(UIButton *)sender {
    NSLog(@"Start scan button tapped");
    
    BOOL showPopup = [self showAppKeyPopupIfNeed];
    if (showPopup) {
        return;
    }
    
    BOOL bluetoothAuthorizationStatus = [BluetoothChecker bluetoothAuthorizationStatus];
    if (!bluetoothAuthorizationStatus) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"bluetooth.permission.title", @"Bluetooth Permission")
                                                                 message:NSLocalizedString(@"bluetooth.permission.message", @"Please confirm Bluetooth is enabled and authorized")
                                                          preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"common.confirm", @"Confirm")
                                                              style:UIAlertActionStyleDestructive
                                                            handler:^(UIAlertAction * _Nonnull action) {
        }];
        
        [alert addAction:confirmAction];
        
        [self presentViewController:alert animated:YES completion:nil];
        
        return;
    }
    
    ScanDeviceViewController *vc2 = [[ScanDeviceViewController alloc] init];
    [[self navigationController] pushViewController:vc2 animated:YES];
}

#pragma mark - Shake Detection

- (BOOL)becomeFirstResponder {
    return YES;
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (motion == UIEventSubtypeMotionShake) {
        [self showLanguageSelection];
    }
}

- (void)showLanguageSelection {
    PLLanguageSelectionViewController *languageVC = [[PLLanguageSelectionViewController alloc] init];
    languageVC.delegate = self;
    languageVC.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [self presentViewController:languageVC animated:YES completion:nil];
}

#pragma mark - PLLanguageSelectionDelegate

- (void)languageDidChange {
    // No need for real-time refresh as we will restart the app
}

@end



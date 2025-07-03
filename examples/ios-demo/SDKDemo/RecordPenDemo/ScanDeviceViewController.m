#import "ScanDeviceViewController.h"
#import "LocalizationHelper.h"
#import "LocalizationMacros.h"

#if __has_include("SDKDemo-Swift.h")
#import "SDKDemo-Swift.h"
#endif

#if __has_include("SDKDemoInternal-Swift.h")
#import "SDKDemoInternal-Swift.h"
#endif


@interface DeviceCell : UITableViewCell

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *infoLabel;
@property (nonatomic, strong) UILabel *snLabel;
@property (nonatomic, strong) UILabel *bindStatusLabel;
@property (nonatomic, strong) UIButton *connectButton;
@property (nonatomic, strong) UIView *bindStatusIconView;
@property (nonatomic, strong) BleDevice *bleDevice;
@property (nonatomic, weak) ScanDeviceViewController* controller;
@property (nonatomic, copy) void (^connectButtonTapped)(BleDevice * device);

@end

@implementation DeviceCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.backgroundColor = [UIColor clearColor];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    // Container View
    self.containerView = [[UIView alloc] init];
    self.containerView.backgroundColor = [UIColor whiteColor];
    self.containerView.layer.cornerRadius = 12;
    self.containerView.layer.shadowColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.1].CGColor;
    self.containerView.layer.shadowOffset = CGSizeMake(0, 2);
    self.containerView.layer.shadowOpacity = 1;
    self.containerView.layer.shadowRadius = 4;
    self.containerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.containerView];
    
    // Name Label
    self.nameLabel = [[UILabel alloc] init];
    self.nameLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    self.nameLabel.textColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0];
    self.nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.containerView addSubview:self.nameLabel];
    
    // Info Label
    self.infoLabel = [[UILabel alloc] init];
    self.infoLabel.font = [UIFont systemFontOfSize:14];
    self.infoLabel.textColor = [UIColor colorWithRed:0.45 green:0.45 blue:0.45 alpha:1.0];
    self.infoLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.containerView addSubview:self.infoLabel];
    
    // SN Label
    self.snLabel = [[UILabel alloc] init];
    self.snLabel.font = [UIFont systemFontOfSize:13];
    self.snLabel.textColor = [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0];
    self.snLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.snLabel.numberOfLines = 1;
    self.snLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    [self.containerView addSubview:self.snLabel];
    
    // Bind Status Label
    self.bindStatusLabel = [[UILabel alloc] init];
    self.bindStatusLabel.font = [UIFont systemFontOfSize:13];
    self.bindStatusLabel.textColor = [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0];
    self.bindStatusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.containerView addSubview:self.bindStatusLabel];
    
    // Bind Status Icon View
    self.bindStatusIconView = [[UIView alloc] init];
    self.bindStatusIconView.translatesAutoresizingMaskIntoConstraints = NO;
    self.bindStatusIconView.layer.cornerRadius = 5;
    [self.containerView addSubview:self.bindStatusIconView];
    
    // Connect Button
    self.connectButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.connectButton setTitle:LocalizedString(@"common.connect") forState:UIControlStateNormal];
    [self.connectButton setTitleColor:[UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:1.0] forState:UIControlStateNormal];
    self.connectButton.backgroundColor = [UIColor whiteColor];
    self.connectButton.layer.cornerRadius = 8;
    self.connectButton.layer.borderWidth = 1.5;
    self.connectButton.layer.borderColor = [UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:1.0].CGColor;
    self.connectButton.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    self.connectButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.connectButton addTarget:self action:@selector(connectButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView addSubview:self.connectButton];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.containerView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:8],
        [self.containerView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
        [self.containerView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
        [self.containerView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-8],
        
        [self.nameLabel.topAnchor constraintEqualToAnchor:self.containerView.topAnchor constant:16],
        [self.nameLabel.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor constant:16],
        [self.nameLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.connectButton.leadingAnchor constant:-16],
        
        [self.infoLabel.topAnchor constraintEqualToAnchor:self.nameLabel.bottomAnchor constant:8],
        [self.infoLabel.leadingAnchor constraintEqualToAnchor:self.nameLabel.leadingAnchor],
        [self.infoLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.connectButton.leadingAnchor constant:-16],
        
        [self.snLabel.topAnchor constraintEqualToAnchor:self.infoLabel.bottomAnchor constant:6],
        [self.snLabel.leadingAnchor constraintEqualToAnchor:self.nameLabel.leadingAnchor],
        [self.snLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.connectButton.leadingAnchor constant:-16],
        
        [self.bindStatusLabel.topAnchor constraintEqualToAnchor:self.snLabel.bottomAnchor constant:6],
        [self.bindStatusLabel.leadingAnchor constraintEqualToAnchor:self.nameLabel.leadingAnchor],
        [self.bindStatusLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.connectButton.leadingAnchor constant:-16],
        [self.bindStatusLabel.bottomAnchor constraintLessThanOrEqualToAnchor:self.containerView.bottomAnchor constant:-16],
        
        [self.bindStatusIconView.centerYAnchor constraintEqualToAnchor:self.bindStatusLabel.centerYAnchor],
        [self.bindStatusIconView.leadingAnchor constraintEqualToAnchor:self.bindStatusLabel.trailingAnchor constant:12],
        [self.bindStatusIconView.widthAnchor constraintEqualToConstant:10],
        [self.bindStatusIconView.heightAnchor constraintEqualToConstant:10],
        
        [self.connectButton.centerYAnchor constraintEqualToAnchor:self.containerView.centerYAnchor],
        [self.connectButton.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor constant:-16],
        [self.connectButton.widthAnchor constraintEqualToConstant:80],
        [self.connectButton.heightAnchor constraintEqualToConstant:36]
    ]];
}

- (void)configureWithDevice:(BleDevice *)device controller:(ScanDeviceViewController*)controller{
    self.bleDevice = device;
    
    self.nameLabel.text = self.bleDevice.name;
    self.infoLabel.text = [NSString stringWithFormat:LocalizedString(@"ble.device.signal_strength"), (long)self.bleDevice.rssi];
    self.snLabel.text = [NSString stringWithFormat:LocalizedString(@"ble.device.serial_number"), self.bleDevice.serialNumber];
    BOOL isUnbound = self.bleDevice.bindCode == 0;
    self.bindStatusLabel.text = isUnbound ? 
        LocalizedString(@"ble.device.bind_status.unbound") : 
        LocalizedString(@"ble.device.bind_status.bound");
    self.bindStatusIconView.backgroundColor = isUnbound ? 
        [UIColor colorWithRed:39/255.0 green:174/255.0 blue:96/255.0 alpha:1.0] : 
        [UIColor clearColor];
    self.bindStatusIconView.hidden = !isUnbound;
    
    // Add breathing animation if device is unbound
    if (isUnbound) {
        [self startBreathingAnimation];
    } else {
        [self stopBreathingAnimation];
    }
    
    [self.snLabel sizeToFit];
    self.controller = controller;
}

- (void)connectButtonAction {
    if (self.controller && self.bleDevice) {
        [self.controller connectToDevice:self.bleDevice];
    }
    
    //    //[FIRAnalytics logEventWithName:@"connect_device_tapped"
    //                        parameters:@{
    //                                     }];
    //    
    //    [PlaudSDKLogger logEvent:@"connect_device_tapped"  parameters:@{
    //    }];
    
}

- (void)startBreathingAnimation {
    // Remove any existing animations
    [self.bindStatusIconView.layer removeAllAnimations];
    
    // Create breathing animation
    CABasicAnimation *breathingAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    breathingAnimation.fromValue = @(1.0);
    breathingAnimation.toValue = @(0.2);
    breathingAnimation.duration = 0.6;
    breathingAnimation.autoreverses = YES;
    breathingAnimation.repeatCount = HUGE_VALF;
    breathingAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    // Add animation to layer
    [self.bindStatusIconView.layer addAnimation:breathingAnimation forKey:@"breathing"];
}

- (void)stopBreathingAnimation {
    [self.bindStatusIconView.layer removeAllAnimations];
}

@end


@interface ScanDeviceViewController() <PlaudDeviceAgentProtocol>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<BleDevice *> *devices;
@property (nonatomic, strong) PlaudDeviceAgent *deviceAgent;
@property (nonatomic, strong) UIView *toastView;
@property (nonatomic, strong) UILabel *toastLabel;
@property (nonatomic, strong) BleDevice* currentDevice;
@end


@implementation ScanDeviceViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.devices = [NSMutableArray array];
    self.deviceAgent = [PlaudDeviceAgent shared];
    self.deviceAgent.delegate = self;
    [self setupUI];
    [self setupTableView];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Reset title style every time the page appears
    UIView *titleContainer = [[UIView alloc] init];
    titleContainer.translatesAutoresizingMaskIntoConstraints = NO;
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = LocalizedString(@"ble.scan.title");
    titleLabel.font = [UIFont systemFontOfSize:24 weight:UIFontWeightBold];
    titleLabel.textColor = [UIColor blackColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [titleContainer addSubview:titleLabel];
    
    // Use auto layout constraints to ensure title is centered
    [NSLayoutConstraint activateConstraints:@[
        [titleLabel.centerXAnchor constraintEqualToAnchor:titleContainer.centerXAnchor],
        [titleLabel.centerYAnchor constraintEqualToAnchor:titleContainer.centerYAnchor],
        [titleLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:titleContainer.leadingAnchor],
        [titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:titleContainer.trailingAnchor],
        [titleContainer.widthAnchor constraintEqualToConstant:200],
        [titleContainer.heightAnchor constraintEqualToConstant:44]
    ]];
    
    self.navigationItem.titleView = titleContainer;
    
    // Parent return, reset delegate
    self.deviceAgent = [PlaudDeviceAgent shared];
    self.deviceAgent.delegate = self;
    
    [self startScanning];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self stopScanning];
}

- (void)setupUI {
    self.view.backgroundColor = [UIColor colorWithRed:0.98 green:0.98 blue:0.98 alpha:1.0];
    
    // Set navigation bar title style
    UIView *titleContainer = [[UIView alloc] init];
    titleContainer.translatesAutoresizingMaskIntoConstraints = NO;
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = LocalizedString(@"ble.scan.title");
    titleLabel.font = [UIFont systemFontOfSize:24 weight:UIFontWeightBold];
    titleLabel.textColor = [UIColor blackColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [titleContainer addSubview:titleLabel];
    
    // Use auto layout constraints to ensure title is centered
    [NSLayoutConstraint activateConstraints:@[
        [titleLabel.centerXAnchor constraintEqualToAnchor:titleContainer.centerXAnchor],
        [titleLabel.centerYAnchor constraintEqualToAnchor:titleContainer.centerYAnchor],
        [titleLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:titleContainer.leadingAnchor],
        [titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:titleContainer.trailingAnchor],
        [titleContainer.widthAnchor constraintEqualToConstant:200], // Set appropriate fixed width
        [titleContainer.heightAnchor constraintEqualToConstant:44]
    ]];
    
    self.navigationItem.titleView = titleContainer;
    
    // Add refresh button
    UIButton *refreshButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [refreshButton setImage:[UIImage systemImageNamed:@"arrow.clockwise"] forState:UIControlStateNormal];
    [refreshButton setTitle:[NSString stringWithFormat:@"%@ ", LocalizedString(@"common.refresh")] forState:UIControlStateNormal];
    [refreshButton setTitleColor:[UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:1.0] forState:UIControlStateNormal];
    refreshButton.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    [refreshButton addTarget:self action:@selector(refreshButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    
    // Set button size
    [refreshButton sizeToFit];
    CGFloat buttonWidth = refreshButton.frame.size.width + 24;
    CGFloat buttonHeight = 44;
    refreshButton.frame = CGRectMake(0, 0, buttonWidth, buttonHeight);
    
    // Set spacing between button image and text
    refreshButton.imageEdgeInsets = UIEdgeInsetsMake(0, -4, 0, 4);
    refreshButton.titleEdgeInsets = UIEdgeInsetsMake(0, 4, 0, -4);
    refreshButton.contentEdgeInsets = UIEdgeInsetsMake(0, 8, 0, 8);
    
    UIBarButtonItem *refreshBarButton = [[UIBarButtonItem alloc] initWithCustomView:refreshButton];
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    spacer.width = -8;
    self.navigationItem.rightBarButtonItems = @[spacer, refreshBarButton];
    
    // Initialize Toast view
    [self setupToastView];
}

- (void)setupToastView {
    if (self.toastView) {
        [self.toastView removeFromSuperview];
        self.toastView = nil;
    }
    
    self.toastView = [[UIView alloc] init];
    self.toastView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
    self.toastView.layer.cornerRadius = 10;
    self.toastView.clipsToBounds = YES;
    self.toastView.translatesAutoresizingMaskIntoConstraints = NO;
    self.toastView.alpha = 0;
    
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    [window addSubview:self.toastView];
    
    self.toastLabel = [[UILabel alloc] init];
    self.toastLabel.textColor = [UIColor whiteColor];
    self.toastLabel.font = [UIFont systemFontOfSize:15];
    self.toastLabel.textAlignment = NSTextAlignmentCenter;
    self.toastLabel.numberOfLines = 0;
    self.toastLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.toastView addSubview:self.toastLabel];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.toastView.centerXAnchor constraintEqualToAnchor:window.centerXAnchor],
        [self.toastView.centerYAnchor constraintEqualToAnchor:window.centerYAnchor],
        [self.toastView.widthAnchor constraintLessThanOrEqualToConstant:280],
        [self.toastView.leadingAnchor constraintGreaterThanOrEqualToAnchor:window.leadingAnchor constant:40],
        [self.toastView.trailingAnchor constraintLessThanOrEqualToAnchor:window.trailingAnchor constant:-40],
        
        [self.toastLabel.topAnchor constraintEqualToAnchor:self.toastView.topAnchor constant:12],
        [self.toastLabel.leadingAnchor constraintEqualToAnchor:self.toastView.leadingAnchor constant:16],
        [self.toastLabel.trailingAnchor constraintEqualToAnchor:self.toastView.trailingAnchor constant:-16],
        [self.toastLabel.bottomAnchor constraintEqualToAnchor:self.toastView.bottomAnchor constant:-12]
    ]];
}

- (void)showToastWithMessage:(NSString *)message {
    if (!message || message.length == 0) {
        return;
    }
    
            // Cancel previous show and hide operations
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideToast) object:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(showToastWithMessage:) object:nil];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // Ensure toastView is initialized
        if (!self.toastView) {
            [self setupToastView];
        }
        
        // If currently showing animation, complete current animation first
        if (self.toastView.alpha > 0) {
            [UIView animateWithDuration:0.15 animations:^{
                self.toastView.alpha = 0.0;
            } completion:^(BOOL finished) {
                [self showNewToast:message];
            }];
        } else {
            [self showNewToast:message];
        }
    });
}

- (void)showNewToast:(NSString *)message {
    self.toastLabel.text = message;
    [self.toastLabel sizeToFit];
    
    // Show animation
    [UIView animateWithDuration:0.25 animations:^{
        self.toastView.alpha = 1.0;
    } completion:^(BOOL finished) {
        // Auto hide after 2 seconds
        [self performSelector:@selector(hideToast) withObject:nil afterDelay:2.0];
    }];
}

- (void)hideToast {
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.25 animations:^{
            self.toastView.alpha = 0.0;
        }];
    });
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] init];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass:[DeviceCell class] forCellReuseIdentifier:@"DeviceCell"];
    [self.view addSubview:self.tableView];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
}

- (void)startScanning {
    [self.deviceAgent startScan];
}

- (void)stopScanning {
    [self.deviceAgent stopScan];
}

- (void)refreshButtonTapped {
    [self.devices removeAllObjects];
    [self.tableView reloadData];
    [self stopScanning];
    [self startScanning];
}

- (void)bleScanResultWithBleDevices:(NSArray<BleDevice *> *)bleDevices {
    [self.devices removeAllObjects];
    
    // Sort devices by RSSI signal strength from highest to lowest
    NSArray<BleDevice *> *sortedDevices = [bleDevices sortedArrayUsingComparator:^NSComparisonResult(BleDevice *device1, BleDevice *device2) {
        // Higher RSSI values indicate stronger signal, so we sort in descending order
        if (device1.rssi > device2.rssi) {
            return NSOrderedAscending; // device1 comes first (higher RSSI)
        } else if (device1.rssi < device2.rssi) {
            return NSOrderedDescending; // device2 comes first (higher RSSI)
        } else {
            return NSOrderedSame; // same RSSI
        }
    }];
    
    [self.devices addObjectsFromArray:sortedDevices];
    [self.tableView reloadData];
}

- (void)bleAppKeyStateWithResult:(NSInteger)result{
}

- (void)bleConnectStateWithState:(NSInteger)state {
    NSString *message = @"";
    switch (state) {
        case 0:
            message = NSLocalizedString(@"device.state.disconnected", @"Device disconnected");
            break;
        case 1:
            //message = NSLocalizedString(@"device.state.connected", @"Device connected successfully");
            break;
        case 2:
            message = NSLocalizedString(@"device.state.connection.failed", @"Device connection failed");
            break;
        default:
            message = NSLocalizedString(@"device.state.unknown", @"Unknown connection status");
            break;
    }
    
    NSLog(@"bleConnectStateWithState, %@", message);
    
    if (message.length > 0) {
        [self showToastWithMessage:message];
    }
    
    if (state == 1) {
        [self showDeviceInfo:self.currentDevice];
    }
}

- (void)showDeviceInfo:(BleDevice *)device {
    if (!device) return;
    
    DeviceInfoViewController *infoVC = [[DeviceInfoViewController alloc] initWithDevice:device];
    [self.navigationController pushViewController:infoVC animated:YES];
}

-(void)bleBindWithSn:(NSString *)sn status:(NSInteger)status protVersion:(NSInteger)protVersion timezone:(NSInteger)timezone{
    
}

- (void)bleScanOverTime {
    [self.devices removeAllObjects];
    [self.tableView reloadData];
}

- (void)bleRecordStartWithSessionId:(NSInteger)sessionId start:(NSInteger)start status:(NSInteger)status scene:(NSInteger)scene startTime:(NSInteger)startTime
{
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.devices.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    DeviceCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DeviceCell" forIndexPath:indexPath];
    BleDevice *device = self.devices[indexPath.row];
    [cell configureWithDevice:device controller:self];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 140;
}

#pragma mark - Device Connection
- (void)connectToDevice:(BleDevice *)device {
    if (device) {
        
        //        if (device.bindCode != 0) {
        //            [self showToastWithMessage:@"Device already bound, cannot bind to new device"];
        //            return;
        //        }
        
        [self showToastWithMessage:NSLocalizedString(@"device.state.connecting", @"Device connecting")];
        self.currentDevice = device;
        [self.deviceAgent connectBleDeviceWithBleDevice:device];
    }
}

@end 

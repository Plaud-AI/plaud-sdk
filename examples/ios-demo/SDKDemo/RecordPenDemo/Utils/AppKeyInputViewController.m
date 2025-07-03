#import "AppKeyInputViewController.h"
#import "LocalizationHelper.h"
#import "LocalizationMacros.h"
#import <PlaudDeviceBasicSDK/PlaudDeviceBasicSDK-Swift.h>

@interface AppKeyInputViewController () <UITextViewDelegate>

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UITextField *appKeyTextField;
@property (nonatomic, strong) UITextField *appSecretTextField;
@property (nonatomic, strong) UIButton *confirmButton;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UITextView *hintTextView;
@property (nonatomic, strong) UIImageView *hintIconView;
@property (nonatomic, strong) UIView *backgroundView;

@end

@implementation AppKeyInputViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.modalPresentationStyle = UIModalPresentationCustom;
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.modalPresentationStyle = UIModalPresentationCustom;
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Set transparent background
    self.view.backgroundColor = [UIColor clearColor];
    
    // Add semi-transparent background view
    self.backgroundView = [[UIView alloc] init];
    self.backgroundView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
    self.backgroundView.alpha = 0;
    self.backgroundView.frame = self.view.bounds;
    self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.backgroundView];
    
    [self setupUI];
    
    // Enable shake detection
    [UIApplication sharedApplication].applicationSupportsShakeToEdit = YES;
    [self becomeFirstResponder];
    
    // Fill in test data
    NSString *key = [PlaudDeviceAgent getTestAppKey];
    NSString *secret = [PlaudDeviceAgent getTestAppSecret];
    
    if (key.length > 0) {
        self.appKeyTextField.text = key;
    }
    
    if (secret.length > 0) {
        self.appSecretTextField.text = secret;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Set container view initial state
    self.containerView.transform = CGAffineTransformMakeScale(1.1, 1.1);
    self.containerView.alpha = 0;
    
    // Execute animation
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.backgroundView.alpha = 1.0;
        self.containerView.transform = CGAffineTransformIdentity;
        self.containerView.alpha = 1.0;
    } completion:nil];
}

- (void)dismissWithCompletion:(void(^)(void))completion {
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.backgroundView.alpha = 0;
        self.containerView.transform = CGAffineTransformMakeScale(0.9, 0.9);
        self.containerView.alpha = 0;
    } completion:^(BOOL finished) {
        [self dismissViewControllerAnimated:NO completion:completion];
    }];
}

- (void)setupUI {
    // Container view
    self.containerView = [[UIView alloc] init];
    self.containerView.backgroundColor = [UIColor whiteColor];
    self.containerView.layer.cornerRadius = 12;
    self.containerView.layer.shadowColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.1].CGColor;
    self.containerView.layer.shadowOffset = CGSizeMake(0, 2);
    self.containerView.layer.shadowOpacity = 1;
    self.containerView.layer.shadowRadius = 4;
    self.containerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.containerView];
    
    // Title
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = LocalizedString(@"auth.appkey.title");
    self.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];
    self.titleLabel.textColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.containerView addSubview:self.titleLabel];
    
    // AppKey input field
    self.appKeyTextField = [self createStyledTextFieldWithPlaceholder:LocalizedString(@"auth.appkey.placeholder")];
    [self.containerView addSubview:self.appKeyTextField];
    
    // AppSecret input field
    self.appSecretTextField = [self createStyledTextFieldWithPlaceholder:LocalizedString(@"auth.appsecret.placeholder")];
    [self.containerView addSubview:self.appSecretTextField];
    
    // Confirm button - primary style
    self.confirmButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.confirmButton setTitle:LocalizedString(@"common.confirm") forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.confirmButton.backgroundColor = [UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:1.0];
    self.confirmButton.layer.cornerRadius = 8;
    self.confirmButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    [self.confirmButton addTarget:self action:@selector(confirmButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    self.confirmButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.containerView addSubview:self.confirmButton];
    
    // Cancel button - secondary style
    self.cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.cancelButton setTitle:LocalizedString(@"common.cancel") forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:1.0] forState:UIControlStateNormal];
    self.cancelButton.backgroundColor = [UIColor whiteColor];
    self.cancelButton.layer.cornerRadius = 8;
    self.cancelButton.layer.borderWidth = 1;
    self.cancelButton.layer.borderColor = [UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:1.0].CGColor;
    self.cancelButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    [self.cancelButton addTarget:self action:@selector(cancelButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    self.cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.containerView addSubview:self.cancelButton];
    
    // Create hint icon
    self.hintIconView = [[UIImageView alloc] init];
    if (@available(iOS 13.0, *)) {
        UIImage *infoImage = [UIImage systemImageNamed:@"info.circle"];
        self.hintIconView.image = [infoImage imageWithTintColor:[UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0]];
    } else {
        // For iOS versions below 13, use custom images or other alternatives
    }
    self.hintIconView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.containerView addSubview:self.hintIconView];
    
    // Add hint text
    self.hintTextView = [[UITextView alloc] init];
    NSString *emailAddress = @"support@plaud.ai";
    NSString *fullText = LocalizedStringWithFormat(@"auth.email.support", emailAddress);
    
    // Create paragraph style
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.firstLineHeadIndent = 20; // Icon 16 + spacing 4
    paragraphStyle.lineSpacing = 6; // Increase line spacing
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:fullText];
    [attributedString addAttribute:NSFontAttributeName
                           value:[UIFont systemFontOfSize:13]
                           range:NSMakeRange(0, fullText.length)];
    [attributedString addAttribute:NSForegroundColorAttributeName
                           value:[UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0]
                           range:NSMakeRange(0, fullText.length)];
    [attributedString addAttribute:NSParagraphStyleAttributeName
                           value:paragraphStyle
                           range:NSMakeRange(0, fullText.length)];
    
    // Add link for email address
    NSRange emailRange = [fullText rangeOfString:emailAddress];
    [attributedString addAttribute:NSLinkAttributeName
                           value:[NSString stringWithFormat:@"mailto:%@", emailAddress]
                           range:emailRange];
    
    self.hintTextView.attributedText = attributedString;
    self.hintTextView.textAlignment = NSTextAlignmentLeft;
    self.hintTextView.editable = NO;
    self.hintTextView.scrollEnabled = NO;
    self.hintTextView.backgroundColor = [UIColor clearColor];
    self.hintTextView.textContainerInset = UIEdgeInsetsMake(0, 24, 0, 24);
    self.hintTextView.textContainer.lineFragmentPadding = 0;
    
    self.hintTextView.delegate = self;
    self.hintTextView.translatesAutoresizingMaskIntoConstraints = NO;
    
    // Set link color
    self.hintTextView.linkTextAttributes = @{
        NSForegroundColorAttributeName: [UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:1.0],
        NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)
    };
    
    [self.containerView addSubview:self.hintTextView];
    
    // Set constraints
    [NSLayoutConstraint activateConstraints:@[
        // Container view constraints
        [self.containerView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.containerView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [self.containerView.widthAnchor constraintEqualToConstant:320],
        
        // Title constraints
        [self.titleLabel.topAnchor constraintEqualToAnchor:self.containerView.topAnchor constant:24],
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor constant:24],
        [self.titleLabel.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor constant:-24],
        
        // AppKey input field constraints
        [self.appKeyTextField.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:24],
        [self.appKeyTextField.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor constant:24],
        [self.appKeyTextField.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor constant:-24],
        [self.appKeyTextField.heightAnchor constraintEqualToConstant:44],
        
        // AppSecret input field constraints
        [self.appSecretTextField.topAnchor constraintEqualToAnchor:self.appKeyTextField.bottomAnchor constant:16],
        [self.appSecretTextField.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor constant:24],
        [self.appSecretTextField.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor constant:-24],
        [self.appSecretTextField.heightAnchor constraintEqualToConstant:44],
        
        // Hint icon constraints
        [self.hintIconView.topAnchor constraintEqualToAnchor:self.appSecretTextField.bottomAnchor constant:22],
        [self.hintIconView.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor constant:24],
        [self.hintIconView.widthAnchor constraintEqualToConstant:16],
        [self.hintIconView.heightAnchor constraintEqualToConstant:16],
        
        // Hint text constraints - start directly from container left
        [self.hintTextView.topAnchor constraintEqualToAnchor:self.appSecretTextField.bottomAnchor constant:20],
        [self.hintTextView.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor],
        [self.hintTextView.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor],
        
        // Button constraints
        [self.cancelButton.topAnchor constraintEqualToAnchor:self.hintTextView.bottomAnchor constant:24],
        [self.cancelButton.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor constant:24],
        [self.cancelButton.widthAnchor constraintEqualToConstant:130],
        [self.cancelButton.heightAnchor constraintEqualToConstant:44],
        [self.cancelButton.bottomAnchor constraintEqualToAnchor:self.containerView.bottomAnchor constant:-24],
        
        [self.confirmButton.topAnchor constraintEqualToAnchor:self.hintTextView.bottomAnchor constant:24],
        [self.confirmButton.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor constant:-24],
        [self.confirmButton.widthAnchor constraintEqualToConstant:130],
        [self.confirmButton.heightAnchor constraintEqualToConstant:44],
        [self.confirmButton.bottomAnchor constraintEqualToAnchor:self.containerView.bottomAnchor constant:-24],
    ]];
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction {
    if ([[UIApplication sharedApplication] canOpenURL:URL]) {
        [[UIApplication sharedApplication] openURL:URL options:@{} completionHandler:nil];
    }
    return NO;
}

- (UITextField *)createStyledTextFieldWithPlaceholder:(NSString *)placeholder {
    UITextField *textField = [[UITextField alloc] init];
    textField.placeholder = placeholder;
    textField.font = [UIFont systemFontOfSize:15];
    textField.textColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
    
    // Create left padding view
    UIView *leftPaddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, textField.frame.size.height)];
    textField.leftView = leftPaddingView;
    textField.leftViewMode = UITextFieldViewModeAlways;
    
    // Set background color and corner radius
    textField.backgroundColor = [UIColor colorWithRed:0.96 green:0.96 blue:0.96 alpha:1.0];
    textField.layer.cornerRadius = 8;
    
    // Set placeholder color
    textField.attributedPlaceholder = [[NSAttributedString alloc] 
        initWithString:placeholder 
        attributes:@{
            NSForegroundColorAttributeName: [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0]
        }];
    
    textField.translatesAutoresizingMaskIntoConstraints = NO;
    return textField;
}

#pragma mark - Button Actions

- (void)confirmButtonTapped {
    NSString *appKey = self.appKeyTextField.text;
    NSString *appSecret = self.appSecretTextField.text;
    
    if (appKey.length > 0 && appSecret.length > 0) {
        if ([self.delegate respondsToSelector:@selector(appKeyInputDidFinishWithAppKey:appSecret:)]) {
            [self dismissWithCompletion:^{
                [self.delegate appKeyInputDidFinishWithAppKey:appKey appSecret:appSecret];
            }];
        } else {
            [self dismissWithCompletion:nil];
        }
    } else {
        // Show error alert
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:LocalizedString(@"common.warning")
                                                                     message:LocalizedString(@"auth.input.empty")
                                                              preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:LocalizedString(@"common.ok")
                                                 style:UIAlertActionStyleDefault
                                               handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)cancelButtonTapped {
    if ([self.delegate respondsToSelector:@selector(appKeyInputDidCancel)]) {
        [self dismissWithCompletion:^{
            [self.delegate appKeyInputDidCancel];
        }];
    } else {
        [self dismissWithCompletion:nil];
    }
}

// Allow becoming first responder
- (BOOL)canBecomeFirstResponder {
    return YES;
}

    // Detect shake start
- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (motion == UIEventSubtypeMotionShake) {
//        // Fill in test data
    }
}

@end 

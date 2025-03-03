#import <BraintreeDropIn/BTDropInController.h>
#import "ACBTCardFormViewController.h"
#import "BTAPIClient_Internal_Category.h"
#import "BTDropInUIUtilities.h"
#import "BTUIKAppearance.h"
#import "BTUIKSwitchFormField.h"
#import "BTUIKCardListLabel.h"
#import "BTUIKViewUtil.h"

#import "UIImage+ImageWithColor.h"
#import "UIColor+Hex.h"

#import <Braintree/BraintreeCard.h>
#import <Braintree/BraintreeCore.h>
#import <Braintree/BraintreePaymentFlow.h>

@implementation ACBTCardFormConfiguration
@end

@interface ACBTCardFormViewController ()

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *scrollViewContentWrapper;
@property (nonatomic, strong) UIStackView *stackView;
@property (nonatomic, strong) UIButton *submitButton;
@property (nonatomic, strong, readwrite) BTUIKCardNumberFormField *cardNumberField;
@property (nonatomic, strong, readwrite) BTUIKExpiryFormField *expirationDateField;
@property (nonatomic, strong, readwrite) BTUIKSecurityCodeFormField *securityCodeField;
@property (nonatomic, strong, readwrite) BTUIKPostalCodeFormField *postalCodeField;
@property (nonatomic, strong) UIStackView *cardNumberErrorView;
@property (nonatomic, strong) UIStackView *cardNumberHeader;
@property (nonatomic, strong) NSArray <BTUIKFormField *> *formFields;
@property (nonatomic, strong) UIStackView *cardNumberFooter;
@property (nonatomic, strong) BTUIKCardListLabel *cardList;
@property (nonatomic, strong) BTUIKFormField *firstResponderFormField;
@property (nonatomic, strong, nullable, readwrite) BTCardCapabilities *cardCapabilities;
@end

@implementation ACBTCardFormViewController

#pragma mark - Lifecycle

- (instancetype)initWithAPIClient:(BTAPIClient *)apiClient request:(nonnull BTDropInRequest *)request {
    if (self = [super initWithAPIClient:apiClient request:request]) {
        _supportedCardTypes = [NSArray new];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.formFields = @[];
    self.view.backgroundColor = [BTUIKAppearance sharedInstance].formBackgroundColor;
    self.navigationController.navigationBar.barTintColor = [BTUIKAppearance sharedInstance].barBackgroundColor;
    self.navigationController.navigationBar.translucent = NO;
    if (@available(iOS 15, *)) {
        UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc]init];
        appearance.backgroundColor = [BTUIKAppearance sharedInstance].barBackgroundColor;

        self.navigationController.navigationBar.standardAppearance = appearance;
        self.navigationController.navigationBar.scrollEdgeAppearance = self.navigationController.navigationBar.standardAppearance;
    }
    [self.navigationController.navigationBar setTitleTextAttributes:@{
                                                                      NSForegroundColorAttributeName: [BTUIKAppearance sharedInstance].primaryTextColor
                                                                      }];

    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scrollView setAlwaysBounceVertical:NO];
    self.scrollView.scrollEnabled = YES;
    [self.view addSubview:self.scrollView];
    
    self.scrollViewContentWrapper = [[UIView alloc] init];
    self.scrollViewContentWrapper.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scrollView addSubview:self.scrollViewContentWrapper];
    
    self.stackView = [BTDropInUIUtilities newStackView];
    [self.scrollViewContentWrapper addSubview:self.stackView];
    
    NSDictionary *viewBindings = @{@"stackView":self.stackView,
                                   @"scrollView":self.scrollView,
                                   @"scrollViewContentWrapper": self.scrollViewContentWrapper};
    
    [self.scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
    [self.scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
    [self.scrollView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
    [self.scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[scrollViewContentWrapper]|"
                                                                      options:0
                                                                      metrics:[BTUIKAppearance metrics]
                                                                        views:viewBindings]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[scrollViewContentWrapper(scrollView)]|"
                                                                      options:0
                                                                      metrics:[BTUIKAppearance metrics]
                                                                        views:viewBindings]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[stackView]|"
                                                                      options:0
                                                                      metrics:[BTUIKAppearance metrics]
                                                                        views:viewBindings]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[stackView]-|"
                                                                      options:0
                                                                      metrics:[BTUIKAppearance metrics]
                                                                        views:viewBindings]];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    
    [self.view addGestureRecognizer:tapGesture];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [self setupForm];
    [self resetForm];
    [self showLoadingScreen:YES];
    [self loadConfiguration];

    self.firstResponderFormField = self.cardNumberField;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.title = BTDropInLocalizedString(CARD_DETAILS_LABEL);
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear: animated];
    if (self.firstResponderFormField) {
        [self.firstResponderFormField becomeFirstResponder];
        self.firstResponderFormField = nil;
    }
}

#pragma mark - Setup

- (void)setupForm {
    self.cardNumberField = [[BTUIKCardNumberFormField alloc] init];
    self.cardNumberField.delegate = self;
    self.cardNumberField.cardNumberDelegate = self;
    self.cardNumberField.state = BTUIKCardNumberFormFieldStateTitleWithoutValidateButton;
    self.expirationDateField = [[BTUIKExpiryFormField alloc] init];
    self.expirationDateField.delegate = self;
    self.securityCodeField = [[BTUIKSecurityCodeFormField alloc] init];
    self.securityCodeField.delegate = self;
    self.securityCodeField.textField.secureTextEntry = self.dropInRequest.shouldMaskSecurityCode;
    self.postalCodeField = [[BTUIKPostalCodeFormField alloc] init];
    self.postalCodeField.delegate = self;
    
    self.cardNumberHeader = [BTDropInUIUtilities newStackView];
    self.cardNumberHeader.layoutMargins = UIEdgeInsetsMake(0, [BTUIKAppearance verticalFormSpace], 0, [BTUIKAppearance verticalFormSpace]);
    self.cardNumberHeader.layoutMarginsRelativeArrangement = true;
    
    UILabel *summaryTitleLabel = [[UILabel alloc] init];
    summaryTitleLabel.numberOfLines = 0;
    summaryTitleLabel.textAlignment = NSTextAlignmentCenter;
    summaryTitleLabel.text = self.formConfiguration.summaryTitle;
    [BTUIKAppearance styleLabelBoldPrimary:summaryTitleLabel];
    summaryTitleLabel.hidden = [summaryTitleLabel.text length] == 0;
    [self.stackView addArrangedSubview:summaryTitleLabel];
    
    UILabel *summaryDescriptionLabel = [[UILabel alloc] init];
    summaryDescriptionLabel.numberOfLines = 0;
    summaryDescriptionLabel.textAlignment = NSTextAlignmentCenter;
    summaryDescriptionLabel.text = self.formConfiguration.summaryDescription;
    [BTUIKAppearance styleLabelPrimary:summaryDescriptionLabel];
    summaryDescriptionLabel.hidden = [summaryDescriptionLabel.text length] == 0;
    [self.stackView addArrangedSubview:summaryDescriptionLabel];
    
    UILabel *displayAmountLabel = [[UILabel alloc] init];
    displayAmountLabel.numberOfLines = 0;
    displayAmountLabel.textAlignment = NSTextAlignmentCenter;
    displayAmountLabel.text = self.formConfiguration.displayAmount;
    [BTUIKAppearance styleLabelBoldPrimary:displayAmountLabel];
    displayAmountLabel.hidden = [displayAmountLabel.text length] == 0;
    [self.stackView addArrangedSubview:displayAmountLabel];
    
    [BTDropInUIUtilities addSpacerToStackView:self.stackView beforeView:summaryTitleLabel size: [BTUIKAppearance verticalFormSpace]];

    self.formFields = @[self.cardNumberField, /*self.cardholderNameField,*/ self.expirationDateField, self.securityCodeField, self.postalCodeField/*, self.mobileCountryCodeField, self.mobilePhoneField*/];

    for (BTUIKFormField *formField in self.formFields) {
        [self.stackView addArrangedSubview:formField];
    }
    
    self.cardNumberField.labelText = @"";

    [BTDropInUIUtilities addSpacerToStackView:self.stackView beforeView:self.cardNumberField size: [BTUIKAppearance verticalFormSpace]];
    self.cardNumberFooter = [BTDropInUIUtilities newStackView];
    self.cardNumberFooter.layoutMargins = UIEdgeInsetsMake(0, [BTUIKAppearance verticalFormSpace], 0, [BTUIKAppearance verticalFormSpace]);
    self.cardNumberFooter.layoutMarginsRelativeArrangement = true;
    [self.stackView addArrangedSubview:self.cardNumberFooter];

    if (!self.dropInRequest.cardLogosDisabled) {
        self.cardList = [BTUIKCardListLabel new];
        self.cardList.translatesAutoresizingMaskIntoConstraints = NO;
        self.cardList.availablePaymentOptions = self.supportedCardTypes;
        [self.cardNumberFooter addArrangedSubview:self.cardList];
        [BTDropInUIUtilities addSpacerToStackView:self.cardNumberFooter beforeView:self.cardList size: [BTUIKAppearance horizontalFormContentPadding]];
    }

    NSUInteger indexOfCardNumberField = [self.stackView.arrangedSubviews indexOfObject:self.cardNumberField];
    [self.stackView insertArrangedSubview:self.cardNumberFooter atIndex:(indexOfCardNumberField + 1)];
    
    [self updateFormBorders];
    
    //Error labels
    self.cardNumberErrorView = [BTDropInUIUtilities newStackViewForError:@""];
    [self cardNumberErrorHidden:YES];
    
    self.submitButton = [[UIButton alloc] init];
    NSString *buttonTitle = ([self.formConfiguration.submitButtonTitle length] > 0) ? self.formConfiguration.submitButtonTitle : BTDropInLocalizedString(NEXT_ACTION);
    [self.submitButton setContentEdgeInsets:UIEdgeInsetsMake(10, 0, 10, 0)];
    [self.submitButton setTitle:buttonTitle forState:UIControlStateNormal];
    [self.submitButton addTarget:self action:@selector(submitButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.submitButton setBackgroundImage:[UIImage imageWithColor:[UIColor colorWithHex:@"2D9F86" alpha:1.0]] forState:UIControlStateNormal];
    [self.submitButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.submitButton setBackgroundImage:[UIImage imageWithColor:[UIColor colorWithHex:@"C5D4D0" alpha:1.0]] forState:UIControlStateDisabled];
    [self.submitButton setEnabled:NO];
    [self.stackView addArrangedSubview:self.submitButton];
}

- (void)submitButtonTapped {
    [self tokenizeCard];
}

- (void)configurationLoaded:(__unused BTConfiguration *)configuration error:(NSError *)error {
    [self showLoadingScreen:NO];
}

#pragma mark - Custom accessors

- (BTCardRequest *)cardRequest {
    if (![self isFormValid]) {
        return nil;
    }
    
    BTCard *card = [[BTCard alloc] init];
    card.number = self.cardNumberField.number;
    card.expirationMonth = self.expirationDateField.expirationMonth;
    card.expirationYear = self.expirationDateField.expirationYear;
    card.cvv = self.securityCodeField.securityCode;
    card.postalCode = self.postalCodeField.postalCode;
    BTCardRequest *cardRequest = [[BTCardRequest alloc] initWithCard:card];

    return cardRequest;
}

- (BOOL)shouldDisplaySaveCardToggle {
    return self.dropInRequest.allowVaultCardOverride && self.apiClient.tokenizationKey == nil;
}

#pragma mark - Public methods

- (void)resetForm {
    [self.cardList emphasizePaymentOption:BTDropInPaymentMethodTypeUnknown];
}

#pragma mark - Keyboard management

- (void)hideKeyboard {
    [self.view endEditing:YES];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    CGRect keyboardRectInWindow = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGSize keyboardSize = [self.view convertRect:keyboardRectInWindow fromView:nil].size;
    UIEdgeInsets scrollInsets = self.scrollView.contentInset;
    scrollInsets.bottom = keyboardSize.height;
    self.scrollView.contentInset = scrollInsets;
    self.scrollView.scrollIndicatorInsets = scrollInsets;
}

- (void)keyboardWillHide:(__unused NSNotification *)notification {
    UIEdgeInsets scrollInsets = self.scrollView.contentInset;
    scrollInsets.bottom = 0.0;
    self.scrollView.contentInset = scrollInsets;
    self.scrollView.scrollIndicatorInsets = scrollInsets;
}

#pragma mark - Helper methods

- (void)updateFormBorders {
    self.cardNumberField.bottomBorder = YES;
    self.cardNumberField.topBorder = YES;
    NSArray *groupedFormFields = @[self.expirationDateField, self.securityCodeField, self.postalCodeField];
    BOOL topBorderAdded = NO;
    BTUIKFormField* lastVisibleFormField;
    for (NSUInteger i = 0; i < groupedFormFields.count; i++) {
        BTUIKFormField *formField = groupedFormFields[i];
        if (!formField.hidden) {
            if (!topBorderAdded) {
                formField.topBorder = YES;
                topBorderAdded = YES;
            } else {
                formField.topBorder = NO;
            }
            formField.bottomBorder = NO;
            formField.interFieldBorder = YES;
            lastVisibleFormField = formField;
        }
    }
    if (lastVisibleFormField) {
        lastVisibleFormField.bottomBorder = YES;
    }
}


- (BOOL)isFormValid {
    __block BOOL isFormValid = YES;
    [self.formFields enumerateObjectsUsingBlock:^(BTUIKFormField * _Nonnull formField, __unused NSUInteger idx, BOOL * _Nonnull stop) {
        if (!formField.valid) {
            *stop = YES;
            isFormValid = NO;
        }
    }];
    return isFormValid;
}

- (void)updateSubmitButton {
    self.submitButton.enabled = /*!self.collapsed &&*/ [self isFormValid];
}

- (void)advanceFocusFromField:(BTUIKFormField *)currentField {
    NSUInteger currentIdx = [self.formFields indexOfObject:currentField];
    if (currentIdx != NSNotFound && currentIdx < self.formFields.count - 1) {
        [[self.formFields objectAtIndex:currentIdx + 1] becomeFirstResponder];
    }
}

- (void)fetchCardCapabilities {
    [self cardNumberErrorHidden:YES];
}

- (void)cardNumberErrorHidden:(BOOL)hidden {
    [self cardNumberErrorHidden:hidden errorString:BTDropInLocalizedString(VALID_CARD_ERROR_LABEL)];
}

- (void)cardNumberErrorHidden:(BOOL)hidden errorString:(NSString *)errorString {
    NSInteger indexOfCardNumberFormField = [self.stackView.arrangedSubviews indexOfObject:self.cardNumberField];
    if (indexOfCardNumberFormField != NSNotFound && !hidden) {
        UILabel *errorLabel = self.cardNumberErrorView.arrangedSubviews.firstObject;
        errorLabel.text = errorString;
        errorLabel.accessibilityLabel = errorString;
        errorLabel.accessibilityHint = BTDropInLocalizedString(REVIEW_AND_TRY_AGAIN);
        [self.stackView insertArrangedSubview:self.cardNumberErrorView atIndex:indexOfCardNumberFormField + 1];
        UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, errorLabel);
        [self.view layoutIfNeeded];

        // scroll so that error view is visible, if needed
        CGFloat scrollViewBottom = self.scrollView.frame.size.height - self.scrollView.contentInset.bottom;
        CGRect errorViewRect = [self.view convertRect:self.cardNumberErrorView.frame fromView:self.stackView];
        CGFloat errorViewBottom = errorViewRect.origin.y + errorViewRect.size.height;
        CGFloat diff = errorViewBottom - scrollViewBottom;

        if (diff > 0) {
            [self.scrollView setContentOffset:CGPointMake(0, self.scrollView.contentOffset.y + diff) animated:YES];
        }
    } else if (self.cardNumberErrorView.superview != nil && hidden) {
        [self.cardNumberErrorView removeFromSuperview];
    }
}

- (void)tokenizeCard {
    [self.view endEditing:YES];
    [self basicTokenization];
}

- (void)basicTokenization {
    BTCardRequest *cardRequest = self.cardRequest;
    BTCardClient *cardClient = [[BTCardClient alloc] initWithAPIClient:self.apiClient];

    UIActivityIndicatorView *spinner = [UIActivityIndicatorView new];
    spinner.activityIndicatorViewStyle = [BTUIKAppearance sharedInstance].activityIndicatorViewStyle;
    [spinner startAnimating];

    self.view.userInteractionEnabled = NO;
    __block UINavigationController *navController = self.navigationController;

    [cardClient tokenizeCard:cardRequest options:nil completion:^(BTCardNonce * _Nullable tokenizedCard, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.view.userInteractionEnabled = YES;
            
            if (error != nil) {
                NSString *message = BTDropInLocalizedString(REVIEW_AND_TRY_AGAIN);
                if (error.code == BTCardClientErrorTypeCardAlreadyExists) {
                    message = BTDropInLocalizedString(CARD_ALREADY_EXISTS);
                }
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:BTDropInLocalizedString(CARD_DETAILS_LABEL) message:message preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *alertAction = [UIAlertAction actionWithTitle:BTDropInLocalizedString(TOP_LEVEL_ERROR_ALERT_VIEW_OK_BUTTON_TEXT) style:UIAlertActionStyleDefault handler:nil];
                [alertController addAction: alertAction];
                [navController presentViewController:alertController animated:YES completion:nil];
            } else {
                [self.delegate cardTokenizationCompleted:tokenizedCard error:error sender:self];
            }
        });
    }];
}

#pragma mark - Protocol conformance
#pragma mark FormField Delegate Methods

- (void)validateButtonPressed:(__unused BTUIKFormField *)formField {
    NSNumber *cardType = @([BTUIKViewUtil paymentMethodTypeForCardType:self.cardNumberField.cardType]);
    BOOL cardSupported = [self.supportedCardTypes containsObject:cardType];

    if (!cardSupported) {
        [self cardNumberErrorHidden:NO errorString:BTDropInLocalizedString(CARD_NOT_ACCEPTED_ERROR_LABEL)];
        return;
    }

    if (!formField.valid) {
        [self cardNumberErrorHidden:NO];
        return;
    }

    if (!self.configuration) {
        return;
    }

    [self advanceFocusFromField:formField];
}

- (void)formFieldDidChange:(BTUIKFormField *)formField {
    [self updateSubmitButton];
    
    // When focus moves from card number field, display the error state if the value in the field is invalid
    if (formField == self.cardNumberField) {
        [self cardNumberErrorHidden:self.cardNumberField.displayAsValid];
    }

    if (formField == self.cardNumberField) {
        [self cardNumberErrorHidden:YES];
        BTDropInPaymentMethodType paymentMethodType = [BTUIKViewUtil paymentMethodTypeForCardType:self.cardNumberField.cardType];
        [self.cardList emphasizePaymentOption:paymentMethodType];
    }
    
    // Auto-advance fields when complete
    if (formField == self.cardNumberField && formField.text.length > 0) {
        BTUIKCardType *cardType = self.cardNumberField.cardType;
        if (cardType != nil && formField.text.length >= cardType.maxNumberLength) {
            [self validateButtonPressed:formField];
        }
    } else if (formField == self.expirationDateField) {
        if (self.expirationDateField.text.length == 5 && self.expirationDateField.valid) {
            [self advanceFocusFromField:formField];
        }
    } else if (formField == self.securityCodeField && formField.text.length > 0) {
        BTUIKCardType *cardType = self.cardNumberField.cardType;
        if (cardType != nil && formField.text.length >= cardType.validCvvLength) {
            [self advanceFocusFromField:formField];
        }
    }
}

- (BOOL)formFieldShouldReturn:(BTUIKFormField *)formField {
    return YES;
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(__unused UITextField *)textField {
    return YES;
}

@end

@implementation UIImage (ImageWithColor)

+ (UIImage *)imageWithColor:(UIColor *)color
{
    return [self imageWithColor:color frame:CGRectMake(0.0f, 0.0f, 1.0f, 1.0f)];
}

+ (UIImage *)imageWithColor:(UIColor *)color frame:(CGRect)rect
{
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end


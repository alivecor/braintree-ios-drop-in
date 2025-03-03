#import "BTDropInBaseViewController.h"

#import "BTUIKCardNumberFormField.h"
#import "BTUIKCardholderNameFormField.h"
#import "BTUIKExpiryFormField.h"
#import "BTUIKSecurityCodeFormField.h"
#import "BTUIKPostalCodeFormField.h"
#import "BTUIKMobileCountryCodeFormField.h"
#import "BTUIKMobileNumberFormField.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACBTCardFormConfiguration : NSObject

@property (nonatomic, copy) NSString *summaryTitle;
@property (nonatomic, copy) NSString *summaryDescription;
@property (nonatomic, copy) NSString *displayAmount;
@property (nonatomic, copy) NSString *submitButtonTitle;

@end

@class BTCardRequest, BTCardCapabilities, BTPaymentMethodNonce;
@protocol ACBTCardFormViewControllerDelegate, BTDropInControllerDelegate;

/// Contains form elements for entering card information.
@interface ACBTCardFormViewController : BTDropInBaseViewController <UITextFieldDelegate, BTUIKFormFieldDelegate, BTUIKCardNumberFormFieldDelegate>

@property (nonatomic, strong) ACBTCardFormConfiguration *formConfiguration;

@property (nonatomic, weak) id<ACBTCardFormViewControllerDelegate, BTDropInControllerDelegate> delegate;

/// The card number form field.
@property (nonatomic, strong, readonly) BTUIKCardNumberFormField *cardNumberField;

/// The expiration date form field.
@property (nonatomic, strong, readonly) BTUIKExpiryFormField *expirationDateField;

/// The security code (ccv) form field.
@property (nonatomic, strong, readonly) BTUIKSecurityCodeFormField *securityCodeField;

/// The postal code form field.
@property (nonatomic, strong, readonly) BTUIKPostalCodeFormField *postalCodeField;

/// If the form is valid, returns a BTCardRequest using the values of the form fields. Otherwise `nil`.
@property (nonatomic, strong, nullable, readonly) BTCardRequest *cardRequest;

/// The BTCardCapabilities used to update the form after checking the card number. Applicable when UnionPay is enabled.
@property (nonatomic, strong, nullable, readonly) BTCardCapabilities *cardCapabilities;

/// The card network types supported by this merchant
@property (nonatomic, copy) NSArray<NSNumber *> *supportedCardTypes;

@end

@protocol ACBTCardFormViewControllerDelegate <NSObject>

- (void)cardTokenizationCompleted:(BTPaymentMethodNonce * _Nullable )tokenizedCard error:(NSError * _Nullable )error sender:(ACBTCardFormViewController *) sender;

@end


NS_ASSUME_NONNULL_END

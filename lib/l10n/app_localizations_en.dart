// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Nabour';

  @override
  String get driverMode => 'Driver Mode';

  @override
  String get passengerMode => 'Passenger Mode';

  @override
  String get requestRide => 'Request Ride';

  @override
  String get acceptRide => 'Accept';

  @override
  String get declineRide => 'Decline';

  @override
  String get cancelRide => 'Cancel Ride';

  @override
  String get myLocation => 'My Location';

  @override
  String get offline => 'Offline';

  @override
  String get online => 'Online';

  @override
  String get available => 'Available';

  @override
  String get unavailable => 'Unavailable';

  @override
  String get activeRide => 'Active Ride';

  @override
  String get rideHistory => 'Ride History';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get startNavigation => 'Navigation started';

  @override
  String get navigationEnded => 'Navigation ended';

  @override
  String get arrived => 'You have arrived at your destination';

  @override
  String get routeDeviation => 'Recalculating route';

  @override
  String get preparingRoute => 'Preparing route';

  @override
  String turnLeft(String distance) {
    return 'Turn left in $distance';
  }

  @override
  String turnRight(String distance) {
    return 'Turn right in $distance';
  }

  @override
  String turnSlightLeft(String distance) {
    return 'Turn slightly left in $distance';
  }

  @override
  String turnSlightRight(String distance) {
    return 'Turn slightly right in $distance';
  }

  @override
  String continueForward(String distance) {
    return 'Continue straight for $distance';
  }

  @override
  String makeUturn(String distance) {
    return 'Make a U-turn in $distance';
  }

  @override
  String get meters => 'meters';

  @override
  String get kilometers => 'kilometers';

  @override
  String get meter => 'meter';

  @override
  String get kilometer => 'kilometer';

  @override
  String get driverHeadingToYou => 'Driver is heading to you...';

  @override
  String get driverArrived => 'Driver has arrived!';

  @override
  String get rideInProgress => 'Ride in progress';

  @override
  String get confirmDriver => 'Confirm Driver';

  @override
  String get confirmButton => 'Confirm';

  @override
  String get declineButton => 'Decline';

  @override
  String get iArrived => 'I\'ve arrived';

  @override
  String get startRide => 'Start ride';

  @override
  String get endRide => 'End Ride';

  @override
  String get waitingForPassenger => 'Waiting for passenger.';

  @override
  String get headingToPassenger => 'Heading to passenger.';

  @override
  String get communicateWithDriver => 'Communicate with driver:';

  @override
  String get call => 'Call';

  @override
  String get message => 'Message';

  @override
  String get chat => 'Chat';

  @override
  String get writeMessage => 'Write a message...';

  @override
  String get send => 'Send';

  @override
  String get emergency => 'Emergency';

  @override
  String get navigationTo => 'Navigate to';

  @override
  String get navigation => 'Navigation';

  @override
  String get chooseNavigationApp => 'Choose navigation app';

  @override
  String get googleMaps => 'Google Maps';

  @override
  String get waze => 'Waze';

  @override
  String get locationNotAvailable =>
      'Location is not available yet for sharing.';

  @override
  String get shareLocation => 'Share Location';

  @override
  String get navigateToPassenger => 'Navigate to passenger';

  @override
  String get navigateToDestination => 'Navigate to destination';

  @override
  String get rideCompleted => 'Ride completed';

  @override
  String get rideCancelled => 'Ride cancelled';

  @override
  String get rideExpired => 'Ride expired';

  @override
  String get offlineDriverMessage =>
      'You\'re unavailable as a driver. Turn on the switch to receive rides or request a ride as a passenger.';

  @override
  String get noPendingRides => 'No ride requests available at the moment.';

  @override
  String rideToDestination(String destination) {
    return 'To: $destination';
  }

  @override
  String get cost => 'Cost';

  @override
  String distance(String km) {
    return 'Distance ($km km):';
  }

  @override
  String get ron => 'RON';

  @override
  String get km => 'km';

  @override
  String get language => 'Language';

  @override
  String get romanian => 'Romanian';

  @override
  String get english => 'English';

  @override
  String get errorInitializingRide => 'Error initializing ride';

  @override
  String get errorMonitoringRide => 'Error monitoring ride';

  @override
  String get cannotOpenNavigation => 'Could not open any navigation app.';

  @override
  String get cannotMakeCall => 'Could not initiate call.';

  @override
  String get joinTeamTitle => 'Join the Nabour team!';

  @override
  String get joinTeamDescription => 'Become a partner driver. Learn more here.';

  @override
  String get youHaveActiveRide =>
      'You have an active ride. Tap to see details.';

  @override
  String get categoryStandardSubtitle =>
      'The most affordable option for your trips.';

  @override
  String get categoryFamilySubtitle => 'More space for passengers and luggage.';

  @override
  String get categoryEnergySubtitle =>
      'Travel eco-friendly with electric or hybrid vehicles.';

  @override
  String get categoryBestSubtitle =>
      'Premium experience with luxury vehicles and top drivers.';

  @override
  String get aiAssistant => 'AI Assistant';

  @override
  String get voiceSettings => 'Voice Settings';

  @override
  String get voiceDemo => 'Voice AI Demo';

  @override
  String get microphoneTest => 'Microphone Test';

  @override
  String get aiLibraryTest => 'AI Library Test';

  @override
  String get receipts => 'Receipts';

  @override
  String get driverDashboard => 'Driver Dashboard';

  @override
  String get subscriptions => 'Subscriptions';

  @override
  String get safety => 'Safety';

  @override
  String get help => 'Help';

  @override
  String get aiVoiceSettings => '🎤 AI Voice Settings';

  @override
  String get voiceAIDemo => '🗣️ Voice AI Demo';

  @override
  String get microphoneTestTool => '🔧 Microphone Test';

  @override
  String get aiLibraryTestTool => '🧠 AI Library Test';

  @override
  String get about => 'About';

  @override
  String get legal => 'Legal';

  @override
  String get logout => 'Logout';

  @override
  String get aboutNabour => 'About Nabour';

  @override
  String get evaluateApp => 'Evaluate App';

  @override
  String get howManyStars => 'How many stars do you give the Nabour app?';

  @override
  String get starSelected => 'star selected';

  @override
  String get starsSelected => 'stars selected';

  @override
  String get cancel => 'Cancel';

  @override
  String get select => 'Select';

  @override
  String ratingSentSuccessfully(String rating) {
    return '✅ Rating of $rating stars sent successfully!';
  }

  @override
  String get career => 'Career';

  @override
  String get joinOurTeam => 'Join our team';

  @override
  String get evaluateApplication => 'Evaluate application';

  @override
  String get giveStarRating => '⭐ Give a star rating';

  @override
  String get followUs => 'Follow us';

  @override
  String get legalInformation => 'Legal Information';

  @override
  String get termsConditions => 'Terms & Conditions';

  @override
  String get privacy => 'Privacy';

  @override
  String get termsConditionsTitle => 'Terms and Conditions';

  @override
  String get generalProvisions => 'General Provisions';

  @override
  String get generalProvisionsText =>
      'Canceling a ride after assigning a partner driver may incur a cancellation fee to compensate for the time and distance traveled by the driver. Cancellation is free anytime before assigning a partner driver.';

  @override
  String get standardWaitTime => 'Standard Wait Time';

  @override
  String get standardWaitTimeText =>
      'After arriving at the pickup location, the partner driver will wait for free for 5 minutes. After this period expires, additional waiting fees may apply or the ride may be canceled, applying the corresponding cancellation fee.';

  @override
  String get specificCategoryPolicies => 'Category-Specific Policies';

  @override
  String get cancellationFee => 'Cancellation Fee:';

  @override
  String get freeCancellation => 'Free Cancellation (Booked Rides):';

  @override
  String get minimumBookingTime => 'Minimum Booking Time:';

  @override
  String get friendsRideStandard => 'Nabour Standard';

  @override
  String get friendsRideEnergy => 'Nabour Energy';

  @override
  String get friendsRideBest => 'Nabour Best';

  @override
  String get friendsRideFamily => 'Nabour Family';

  @override
  String get standardCancellationFee => '30 RON';

  @override
  String get energyCancellationFee => '30 RON';

  @override
  String get bestCancellationFee => '30 RON';

  @override
  String get familyCancellationFee => '30 RON';

  @override
  String get standardFreeCancellation =>
      'At least 1 hour and 30 minutes before the scheduled time.';

  @override
  String get standardMinBooking =>
      'At least 2 hours in advance from the ride reservation time.';

  @override
  String get energyMinBooking =>
      'At least 2 hours in advance from the ride reservation time.';

  @override
  String get bestMinBooking =>
      'At least 2 hours in advance from the ride reservation time.';

  @override
  String get familyMinBooking =>
      'At least 2 hours in advance from the ride reservation time.';

  @override
  String get privacyPolicyContent =>
      'Here will be displayed the detailed content of the Privacy Policy, in accordance with GDPR regulations. The document will explain what types of personal data are collected (name, email, location, payment data, etc.), the purpose of collection (service operation, marketing, security), how data is stored and protected, retention period, and what are the users\' rights (right to access, rectification, deletion, etc.).\n\nThe complete text will be provided by a legal consultant to ensure compliance with current legislation.';

  @override
  String get wallet => 'Wallet';

  @override
  String get currentBalance => 'Current Balance';

  @override
  String get paymentMethods => 'Payment Methods';

  @override
  String get addOrManageCards => 'Add or manage cards';

  @override
  String get cash => 'Cash';

  @override
  String get selectPaymentMethod => 'Select Payment Method';

  @override
  String get vouchers => 'Vouchers';

  @override
  String get addPromoCode => 'Add a promotional code';

  @override
  String get transactionHistory => 'Transaction History';

  @override
  String get viewAllPayments => 'View all payments and receipts';

  @override
  String get canSendToContact => 'You can send to a contact person';

  @override
  String get addPaymentMethod => 'Add a payment method';

  @override
  String get rideProfiles => 'Ride Profiles';

  @override
  String get startUsing => 'Start using';

  @override
  String get friendsRideForBusiness => 'Nabour for Business';

  @override
  String get activateBusinessFeatures => 'Activate features for business trips';

  @override
  String get manageBusinessTrips => 'Manage business trips on...';

  @override
  String get requestBusinessProfileAccess =>
      'Request access to Business profile';

  @override
  String get addVoucherCode => 'Add voucher code';

  @override
  String get promotions => 'Promotions';

  @override
  String get recommendations => 'Recommendations';

  @override
  String get addReferralCode => 'Add referral code';

  @override
  String get inStoreOffers => 'In-Store Offers';

  @override
  String get offers => 'Offers';

  @override
  String get walletDetails => 'Wallet Details';

  @override
  String get walletDetailsInfo =>
      'Nabour Cash is your digital balance. You can add funds for faster payments.';

  @override
  String get addFunds => 'Add Funds';

  @override
  String get addFundsComingSoon =>
      'The add funds functionality will be available soon.';

  @override
  String get paymentMethodDetails => 'Payment Method Details';

  @override
  String get brand => 'Brand';

  @override
  String get last4Digits => 'Last 4 digits';

  @override
  String get cardholder => 'Cardholder';

  @override
  String get expiryDate => 'Expiry date';

  @override
  String get cashPaymentMethod =>
      'Payment is made directly to the driver in cash.';

  @override
  String get delete => 'Delete';

  @override
  String get deletePaymentMethodComingSoon =>
      'The delete payment method functionality will be available soon.';

  @override
  String get businessProfile => 'Business Profile';

  @override
  String get businessProfileInfo =>
      'Activate Business profile to manage business trips.';

  @override
  String get businessProfileBenefits => 'Benefits:';

  @override
  String get businessProfileBenefit1 => 'Detailed expense reports';

  @override
  String get businessProfileBenefit2 => 'Automatic billing to company';

  @override
  String get businessProfileBenefit3 => 'Manage multiple users';

  @override
  String get requestAccess => 'Request Access';

  @override
  String get businessProfileRequestSent =>
      'Business profile request has been sent. You will receive a response soon.';

  @override
  String get referralCodeInfo => 'Enter referral code to receive benefits.';

  @override
  String get enterReferralCode => 'Enter code';

  @override
  String get referralCodeApplied => 'Referral code applied successfully!';

  @override
  String get personalProfileActive => 'Personal profile is active.';

  @override
  String get inStoreOffersComingSoon =>
      'In-store offers will be available soon.';

  @override
  String get close => 'Close';

  @override
  String get paymentMethodDeleted => 'Payment method deleted successfully.';

  @override
  String get errorDeletingPaymentMethod => 'Error deleting payment method.';

  @override
  String get errorRequestingBusinessProfile =>
      'Error requesting business profile.';

  @override
  String get errorApplyingReferralCode => 'Error applying referral code.';

  @override
  String get paymentMethodsHelpTitle => 'Payment Methods';

  @override
  String get addingPaymentMethod => 'Adding a payment method:';

  @override
  String get goToWalletSection =>
      '• Go to the \"Wallet\" section in the main menu';

  @override
  String get tapAddPaymentMethod => '• Tap the \"Add a payment method\" button';

  @override
  String get selectCardOrCash => '• Select the type of method (card or cash)';

  @override
  String get enterCardDetails =>
      '• Enter card details (number, expiry date, CVV)';

  @override
  String get savePaymentMethod => '• Save the payment method';

  @override
  String get managingPaymentMethods => 'Managing payment methods:';

  @override
  String get viewAllMethodsInWallet =>
      '• View all saved methods in the \"Wallet\" section';

  @override
  String get editOrDeleteMethods => '• Edit or delete existing methods';

  @override
  String get setDefaultPaymentMethod =>
      '• Set a method as default for automatic payments';

  @override
  String get paymentMethodsTypes => 'Payment method types:';

  @override
  String get creditDebitCards => '• Credit/debit cards (Visa, Mastercard)';

  @override
  String get cashPayment => '• Cash (payment is made directly to the driver)';

  @override
  String get walletBalance => '• Nabour Cash (wallet balance)';

  @override
  String get paymentSecurity => 'Payment security:';

  @override
  String get allPaymentsSecure => '• All payments are processed securely';

  @override
  String get cardDetailsEncrypted =>
      '• Card details are encrypted and stored securely';

  @override
  String get pciCompliant =>
      '• The app complies with PCI DSS security standards';

  @override
  String get paymentMethodTip => '💡 Useful tip:';

  @override
  String get youCanSendToContact =>
      'You can send money to contacts using saved payment methods.';

  @override
  String get vouchersHelpTitle => 'Vouchers';

  @override
  String get addingVoucher => 'Adding a voucher:';

  @override
  String get tapVouchersSection => '• Tap on \"Vouchers\" section in Wallet';

  @override
  String get tapAddVoucherCode => '• Tap \"Add voucher code\"';

  @override
  String get enterVoucherCode => '• Enter the voucher code';

  @override
  String get applyVoucher => '• Tap \"Apply\" to activate the voucher';

  @override
  String get usingVouchers => 'Using vouchers:';

  @override
  String get vouchersAppliedAutomatically =>
      '• Vouchers are automatically applied to the next ride';

  @override
  String get checkVoucherStatus => '• Check voucher status in Vouchers section';

  @override
  String get voucherExpiryInfo => '• Vouchers have an expiry date';

  @override
  String get voucherTypes => 'Voucher types:';

  @override
  String get percentageDiscount => '• Percentage discount (e.g., 10% off)';

  @override
  String get fixedAmountDiscount => '• Fixed amount discount (e.g., 5 RON off)';

  @override
  String get freeRideVoucher => '• Free ride';

  @override
  String get voucherTip => '💡 Useful tip:';

  @override
  String get oneVoucherPerRide => 'You can use only one voucher per ride.';

  @override
  String get walletHelpTitle => 'Wallet';

  @override
  String get walletOverview => 'Overview:';

  @override
  String get walletOverviewInfo =>
      'The Wallet section allows you to manage payment methods, vouchers, and Nabour Cash balance.';

  @override
  String get friendsRideCash => 'Nabour Cash:';

  @override
  String get friendsRideCashInfo => '• Digital balance for fast payments';

  @override
  String get addFundsToWallet => '• You can add funds to wallet';

  @override
  String get useWalletForPayments =>
      '• You can use balance for automatic payments';

  @override
  String get walletSections => 'Available sections:';

  @override
  String get paymentMethodsSection =>
      '• Payment Methods - manage cards and cash';

  @override
  String get vouchersSection => '• Vouchers - add and manage promotional codes';

  @override
  String get rideProfilesSection => '• Ride Profiles - Personal and Business';

  @override
  String get promotionsSection =>
      '• Promotions - promotional codes and referrals';

  @override
  String get walletTip => '💡 Useful tip:';

  @override
  String get walletBalanceNeverExpires => 'Nabour Cash balance never expires.';

  @override
  String get earningsToday => 'Earnings Today';

  @override
  String get ridesToday => 'Rides Today';

  @override
  String get averageRating => 'Average Rating';

  @override
  String get lastCompletedRides => 'Last Completed Rides';

  @override
  String get allRides => 'All Rides';

  @override
  String get todayRides => 'Today\'s Rides';

  @override
  String get generateDailyReport => 'Generate Daily Report';

  @override
  String get noRidesYet => 'No rides completed yet';

  @override
  String get viewDetails => 'View Details';

  @override
  String get addTrustedContact => 'Add Trusted Contact';

  @override
  String get name => 'Name';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get phoneNumberExample => 'ex: 0712 345 678';

  @override
  String get save => 'Save';

  @override
  String contactSaved(String name) {
    return 'Contact $name has been saved.';
  }

  @override
  String get trustedContacts => 'Trusted Contacts';

  @override
  String get noContacts => 'No trusted contacts added yet';

  @override
  String get emergencyCall => 'Emergency Call';

  @override
  String get safetyFeatures => 'Safety Features';

  @override
  String get emergencyAssistance => 'Emergency Assistance';

  @override
  String get shareTrip => 'Share Trip';

  @override
  String get reportIncident => 'Report Incident';

  @override
  String get helpCenter => 'Help Center';

  @override
  String get frequentlyAskedQuestions => 'Frequently Asked Questions';

  @override
  String get contactSupport => 'Contact Support';

  @override
  String get reportProblem => 'Report a Problem';

  @override
  String get cannotRequestRide => 'Cannot request a ride';

  @override
  String get cannotRequestRideContent =>
      'If you are having trouble requesting a ride, try the following solutions:';

  @override
  String get checkInternetConnection => '2. Check internet connection';

  @override
  String get ensureGpsEnabled => '• Make sure GPS location is enabled';

  @override
  String get restartApp => '1. Restart the app';

  @override
  String get checkValidPayment => '• Check if you have a valid payment method';

  @override
  String get contactSupportIfPersists =>
      '• Contact the support team if the problem persists';

  @override
  String get pickupTimeLonger => 'Pickup time is longer than estimated';

  @override
  String get pickupTimeLongerContent =>
      'Estimated time may vary for the following reasons:';

  @override
  String get unexpectedHeavyTraffic => '• Unexpected heavy traffic';

  @override
  String get unfavorableWeather => '• Unfavorable weather conditions';

  @override
  String get driverFindingAddress =>
      '• Driver may have difficulty finding the address';

  @override
  String get specialEvents => '• Special events in your area';

  @override
  String get contactDriverDirectly =>
      'You can contact the driver directly through the app to clarify the situation.';

  @override
  String get rideDidNotHappen => 'Ride did not happen';

  @override
  String get rideDidNotHappenContent => 'If the ride did not happen, check:';

  @override
  String get rideStatusInApp => '• Ride status in the app';

  @override
  String get messagesFromDriver => '• Messages from driver';

  @override
  String get correctLocation => '• If you were at the correct location';

  @override
  String get contactSupportForRefund =>
      'For refunds, contact support with ride details.';

  @override
  String get lostItems => 'Lost Items';

  @override
  String get lostItemsContent =>
      'If you forgot something in the driver\'s car:';

  @override
  String get contactDriverImmediately =>
      '1. Contact the driver immediately through the app';

  @override
  String get describeLostItem => '2. Describe the lost item';

  @override
  String get arrangePickup => '3. Arrange a meeting for recovery';

  @override
  String get reportToSupport =>
      '4. If you cannot contact the driver, report through support';

  @override
  String get returnFeeNote =>
      'Note: A small fee may apply for returning items.';

  @override
  String get driverDeviatedRoute => 'Driver deviated from route';

  @override
  String get driverDeviatedContent => 'If the driver took a different route:';

  @override
  String get askDriverReason =>
      '• Ask the driver about the reason for the change';

  @override
  String get checkTrafficWorks =>
      '• Check if there is traffic or works on the initial route';

  @override
  String get reportIfUnjustified =>
      '• If you consider the deviation unjustified, report it';

  @override
  String get driversCanChooseAlternatives =>
      'Drivers can choose alternative routes to avoid traffic.';

  @override
  String get driverDashboardWeeklyActivityTitle => 'Community activity';

  @override
  String get driverDashboardWeeklyKudosHeader => 'Kudos';

  @override
  String get driverDashboardWeeklyTotalHelpsWeek => 'Helps this week:';

  @override
  String get emergencyAssistanceUsage => 'Using emergency assistance';

  @override
  String get emergencyAssistanceContent =>
      'The emergency function allows you to:';

  @override
  String get quickCall112 => '• Quickly call 112';

  @override
  String get sendLocationToContact =>
      '• Send your location to an emergency contact';

  @override
  String get reportIncidentToSafety =>
      '• Report an incident to the safety team';

  @override
  String get voiceSettingsSaved => 'Voice settings have been saved';

  @override
  String get availableVoiceCommands => 'Available Voice Commands';

  @override
  String get basicCommands => 'Basic commands:';

  @override
  String get wantRideToDestination => '\"I want a ride to [destination]\"';

  @override
  String get economyRideToDestination => '\"Economy ride to [destination]\"';

  @override
  String get urgentRideToDestination => '\"Urgent ride to [destination]\"';

  @override
  String get premiumRideToDestination => '\"Premium ride to [destination]\"';

  @override
  String get commandsDuringRide => 'Commands during ride:';

  @override
  String get sendMessageToDriver => '\"Send message to driver\"';

  @override
  String get whereIsDriver => '\"Where is the driver?\"';

  @override
  String get wantToPayCash => '\"I want to pay cash\"';

  @override
  String get controlCommands => 'Control commands:';

  @override
  String get heyNabour => '\"Hey Nabour\" (activation)';

  @override
  String get helpCommand => '\"Help\" (help)';

  @override
  String get cancelCommand => '\"Cancel\" (cancel)';

  @override
  String get stopCommand => '\"Stop\" (stop)';

  @override
  String get advancedHelp => 'Advanced Help';

  @override
  String get advancedFeaturesAvailable => 'Advanced features available:';

  @override
  String get automaticVoiceActivation => '   - Automatic voice activation';

  @override
  String get customActivationWord => '   - Custom activation word';

  @override
  String get realtimeDetection => '   - Real-time detection';

  @override
  String get continuousListening => 'Continuous listening';

  @override
  String get continuousListeningForCommands =>
      '   - Continuous listening for commands';

  @override
  String get realtimeProcessing => '   - Real-time processing';

  @override
  String get smartBatterySaving => '   - Smart battery saving';

  @override
  String get multiLanguageSupport => 'Multi-language support';

  @override
  String get supportFor6Languages => '   - Support for 6 languages';

  @override
  String get voiceSwitchBetweenLanguages =>
      '   - Voice switch between languages';

  @override
  String get localAccentAdaptation => '   - Local accent adaptation';

  @override
  String get privacySecurity => 'Privacy & Security';

  @override
  String get localProcessing => '   - Local processing';

  @override
  String get endToEndEncryption => '   - End-to-end encryption';

  @override
  String get fullDataControl => '   - Full data control';

  @override
  String get contactSupportForTechnical =>
      'For technical assistance, contact support.';

  @override
  String get listening => 'Listening';

  @override
  String get sayYourAnswer => 'Say your answer:';

  @override
  String get acceptOrDecline => '\"ACCEPT\" or \"DECLINE\"';

  @override
  String get greeting => 'Hello! Where would you like to go?';

  @override
  String get account => 'Account';

  @override
  String get personalInformation => 'Personal Information';

  @override
  String get changePassword => 'Change Password';

  @override
  String get security => 'Security';

  @override
  String get notifications => 'Notifications';

  @override
  String get reportGenerated => 'Report Generated';

  @override
  String get dailyReportGeneratedSuccess =>
      'Daily report has been generated successfully. Do you want to return to the main map?';

  @override
  String get stayHere => 'Stay Here';

  @override
  String get goToMap => 'Go to Map';

  @override
  String get driverOptions => 'Driver Options';

  @override
  String get generatingReport => 'Generating report...';

  @override
  String get showAll => 'Show All';

  @override
  String get noRidesMatchFilter => 'No rides match the filter.';

  @override
  String get to => 'To:';

  @override
  String get destination => 'Destination';

  @override
  String get driverModeDeactivated => 'Driver Mode Deactivated';

  @override
  String get goToMapAndActivate =>
      'Go to Map and activate the switch to receive rides.';

  @override
  String get youAreAvailable => 'You Are Available for Rides';

  @override
  String get newRidesWillAppear =>
      'New rides will appear on the map as interactive notifications.';

  @override
  String get waitingForPassengerConfirmation =>
      'Waiting for passenger confirmation';

  @override
  String get confirmedGoToPassenger => 'Confirmed - Go to passenger';

  @override
  String get earningsTodayShort => 'Earnings Today';

  @override
  String get completedRidesToday => 'Completed rides today';

  @override
  String get ridesTodayShort => 'Rides Today';

  @override
  String get averageRatingShort => 'Average Rating';

  @override
  String errorGeneratingReport(String error) {
    return 'Error generating report: $error';
  }

  @override
  String get noRidesTodayForReport => 'No completed rides today for report.';

  @override
  String get safetyCenter => 'Safety Center';

  @override
  String get addContact => 'Add contact';

  @override
  String get emergencyAssistanceButton => 'Emergency Assistance Button';

  @override
  String get emergencyAssistanceButtonDesc =>
      'During any ride, you have the 112 button in the corner of the screen to quickly contact emergency services.';

  @override
  String get tripSharing => 'Trip Sharing';

  @override
  String get tripSharingDesc =>
      'You can share ride details and route in real-time with friends or family for added safety.';

  @override
  String get verifiedDrivers => 'Verified Drivers';

  @override
  String get verifiedDriversDesc =>
      'All partner drivers go through a rigorous document and history verification process to ensure your safety.';

  @override
  String get reportIncidentTitle => 'Reporting an Incident';

  @override
  String get reportIncidentDesc =>
      'If you encounter any safety issues, you can report them directly from the app, in the Help section, and our team will investigate promptly.';

  @override
  String get noTrustedContactsYet => 'You haven\'t added trusted contacts yet.';

  @override
  String get addFamilyFriends =>
      'Quickly add family or friends who will receive notifications when you share a ride.';

  @override
  String get sendTestMessage => 'Send test message';

  @override
  String contactRemoved(String name) {
    return 'Contact $name has been removed.';
  }

  @override
  String get couldNotOpenMessages =>
      'Could not open messaging app for this contact.';

  @override
  String get testMessageBody =>
      'I\'ve set you as a trusted contact in Nabour. I will share active trips when I need help.';

  @override
  String get voiceSystemActive => 'Voice system is active';

  @override
  String get voiceSystemNotActive => 'Voice system is not active';

  @override
  String get canUseVoiceCommands => 'You can use voice commands to book rides';

  @override
  String get checkMicrophonePermissions => 'Check microphone permissions';

  @override
  String get activate => 'Activate';

  @override
  String get basicMode => 'Basic Mode';

  @override
  String get continuous => 'Continuous';

  @override
  String get on => 'ON';

  @override
  String get off => 'OFF';

  @override
  String get generalSettings => 'General Settings';

  @override
  String get continuousListeningSubtitle =>
      'Continuously listen for voice commands';

  @override
  String get voicePreferences => 'Voice Preferences';

  @override
  String get speechRate => 'Speech rate';

  @override
  String percentOfNormalSpeed(int percent) {
    return '$percent% of normal speed';
  }

  @override
  String get volume => 'Volume';

  @override
  String percentOfMaxVolume(int percent) {
    return '$percent% of maximum volume';
  }

  @override
  String get pitch => 'Pitch';

  @override
  String get lowerPitch => 'Lower pitch';

  @override
  String get normalPitch => 'Normal pitch';

  @override
  String get higherPitch => 'Higher pitch';

  @override
  String get german => 'German';

  @override
  String get french => 'French';

  @override
  String get spanish => 'Spanish';

  @override
  String get italian => 'Italian';

  @override
  String get advancedVoiceFeatures => 'Advanced Voice Features';

  @override
  String get voiceCommandTraining => 'Voice command training';

  @override
  String get voiceCommandTrainingSubtitle => 'Improve command recognition';

  @override
  String get customVoiceProfile => 'Custom voice profile';

  @override
  String get customVoiceProfileSubtitle => 'Adapt the system to your voice';

  @override
  String get multiLanguageSupportSubtitle =>
      'Switch between languages during conversation';

  @override
  String get advancedSettings => 'Advanced Settings';

  @override
  String get testMicrophone => 'Test microphone';

  @override
  String get testMicrophoneSubtitle => 'Check if microphone works correctly';

  @override
  String get testSound => 'Test sound';

  @override
  String get testSoundSubtitle => 'Check if sound works correctly';

  @override
  String get testRecognition => 'Test recognition';

  @override
  String get testRecognitionSubtitle => 'Check voice recognition';

  @override
  String get voiceCommandsHelp => 'Voice commands help';

  @override
  String get voiceCommandsHelpSubtitle => 'Complete list of available commands';

  @override
  String get privacySettings => 'Privacy';

  @override
  String get privacySettingsSubtitle => 'Manage voice data and privacy';

  @override
  String get analyticsAndImprovements => 'Analytics and improvements';

  @override
  String get analyticsAndImprovementsSubtitle =>
      'Manage voice analytics for improvements';

  @override
  String get saveSettings => 'Save Settings';

  @override
  String get voiceSystemActivatedSuccessfully =>
      'Voice system has been activated successfully!';

  @override
  String errorActivatingVoiceSystem(String error) {
    return 'Error activating voice system: $error';
  }

  @override
  String get activateVoiceSystemFirst => 'Activate voice system first.';

  @override
  String errorTestingMicrophone(String error) {
    return 'Error testing microphone: $error';
  }

  @override
  String errorTestingSound(String error) {
    return 'Error testing sound: $error';
  }

  @override
  String errorTestingRecognition(String error) {
    return 'Error testing recognition: $error';
  }

  @override
  String get voiceCommandTrainingTitle => 'Voice Command Training';

  @override
  String get voiceCommandTrainingContent =>
      'Training will improve voice command recognition. You will be asked to repeat commands multiple times to create a personalized voice profile.';

  @override
  String get later => 'Later';

  @override
  String get startTraining => 'Start Training';

  @override
  String get trainingStepsTitle => 'Training Steps';

  @override
  String get repeatCommand1 =>
      '1. Repeat the command \"I want a ride\" 3 times';

  @override
  String get repeatCommand2 => '2. Repeat the command \"Economy ride\" 3 times';

  @override
  String get repeatCommand3 => '3. Repeat the command \"Cancel ride\" 3 times';

  @override
  String get repeatCommand4 => '4. Repeat the command \"Help\" 3 times';

  @override
  String get trainingWillTakeApprox =>
      'Training will take approximately 5 minutes.';

  @override
  String get customVoiceProfileTitle => 'Custom Voice Profile';

  @override
  String get customVoiceProfileContent =>
      'Create a custom voice profile to improve recognition. The system will learn to recognize your voice and adapt to your accent.';

  @override
  String get createProfile => 'Create Profile';

  @override
  String get multiLanguageSettingsTitle => 'Multi-language Support';

  @override
  String get primaryLanguage => 'Primary language: Romanian';

  @override
  String get secondaryLanguages => 'Secondary languages:';

  @override
  String get switchBetweenLanguages =>
      'You can switch between languages by saying \"Switch to English\" or \"Change to Romanian\"';

  @override
  String get availableVoiceCommandsTitle => 'Available Voice Commands';

  @override
  String get privacySettingsTitle => 'Voice Privacy';

  @override
  String get privacySettingsLabel => 'Privacy settings:';

  @override
  String get saveVoiceHistory => 'Save voice history';

  @override
  String get saveVoiceHistorySubtitle =>
      'Store voice commands for service improvement';

  @override
  String get anonymousAnalysis => 'Anonymous analysis';

  @override
  String get anonymousAnalysisSubtitle =>
      'Allow anonymous analysis for recognition improvement';

  @override
  String get cloudSync => 'Cloud sync';

  @override
  String get cloudSyncSubtitle => 'Sync voice preferences between devices';

  @override
  String get voiceDataProcessedLocally =>
      'Voice data is processed locally on your device for maximum privacy.';

  @override
  String get analyticsSettingsTitle => 'Analytics and Improvements';

  @override
  String get analyticsSettingsLabel => 'Analytics settings:';

  @override
  String get improveRecognition => 'Improve recognition';

  @override
  String get improveRecognitionSubtitle =>
      'Allow analysis for voice recognition improvement';

  @override
  String get usageStatistics => 'Usage statistics';

  @override
  String get usageStatisticsSubtitle =>
      'Collect statistics about voice feature usage';

  @override
  String get errorReporting => 'Error reporting';

  @override
  String get errorReportingSubtitle =>
      'Automatically report voice errors for resolution';

  @override
  String get allDataAnonymized =>
      'All data is anonymized and contains no personal information.';

  @override
  String get advancedHelpTitle => 'Advanced Help';

  @override
  String get aiSpeaking => '🗣️ AI SPEAKING\n\nPlease listen...';

  @override
  String get aiListening => '🎤 AI LISTENING\n\nSPEAK NOW!';

  @override
  String get aiProcessing => '🧠 AI PROCESSING\n\nPlease wait...';

  @override
  String get waitingForResponse => 'WAITING FOR RESPONSE';

  @override
  String get voiceAssistant => 'VOICE ASSISTANT';

  @override
  String get pleaseListenToResponse => 'Please listen to the response...';

  @override
  String get speakNow => 'SPEAK NOW!';

  @override
  String get processingInformation => 'Processing information...';

  @override
  String get pleaseWait => 'Please wait...';

  @override
  String get pressButtonToStart => 'Press the button to start';

  @override
  String get newRideAudioUnavailable => '🚨 NEW RIDE! (Audio unavailable)';

  @override
  String get emergencyAssistanceUsageContent =>
      'The emergency function allows you to:';

  @override
  String get call112Quickly => '• Call 112 quickly';

  @override
  String get sendLocationToEmergencyContact =>
      '• Send your location to an emergency contact';

  @override
  String get reportIncidentToSafetyTeam =>
      '• Report an incident to the safety team';

  @override
  String get useOnlyRealEmergencies =>
      'Use this function only in real emergency situations.';

  @override
  String get reportAccidentOrUnpleasantEvent =>
      'Report accident or unpleasant event';

  @override
  String get toReportIncident => 'To report an incident:';

  @override
  String get ensureYourSafety => '1. Ensure your safety';

  @override
  String get useEmergencyFunctionInApp =>
      '2. Use the emergency function in the app';

  @override
  String get describeInDetail => '3. Describe in detail what happened';

  @override
  String get addPhotosIfPossible => '4. Add photos if possible';

  @override
  String get cooperateWithInvestigationTeam =>
      '5. Cooperate with the investigation team';

  @override
  String get falseReportsCanLead =>
      'False reports can lead to account suspension.';

  @override
  String get cleaningOrDamageFee => 'Cleaning or damage fee';

  @override
  String get cleaningFeeTitle => '🧹 Cleaning and damage fees in Nabour app';

  @override
  String get cleaningFeeIntro =>
      'At Nabour, we want all trips to be pleasant and comfortable for all our users. For this reason, we have a clear policy regarding vehicle cleanliness and responsibility for any damage.';

  @override
  String get whenFeeApplied => '🚨 When is the cleaning or damage fee applied?';

  @override
  String get spillingLiquids =>
      '1. Spilling liquids in the vehicle (water, coffee, juices, alcohol, etc.)';

  @override
  String get soilingSeatsOrFloor =>
      '2. Soiling seats or floor with mud, food or other substances';

  @override
  String get vomitingInVehicle => '3. Vomiting in the vehicle';

  @override
  String get smokingInVehicle =>
      '4. Smoking in the vehicle (including e-cigarettes)';

  @override
  String get damagingVehicleElements =>
      '5. Damaging vehicle elements (seats, belts, etc.)';

  @override
  String get leavingFoodOrTrash =>
      '6. Leaving food scraps or trash in the vehicle';

  @override
  String get persistentOdors =>
      '7. Persistent odors requiring professional deodorization';

  @override
  String get howFeeProcessWorks =>
      '⚙️ How does the fee application process work?';

  @override
  String get driverDocumentsDamage =>
      '1. Driver documents the damage with photos immediately after the ride';

  @override
  String get driverReportsIncident =>
      '2. Driver reports the incident through Nabour app within 24 hours';

  @override
  String get teamAnalyzesReport => '3. Our team analyzes the report and photos';

  @override
  String get ifFeeJustified =>
      '4. If the fee is justified, the passenger will be notified';

  @override
  String get feeChargedAutomatically =>
      '5. The fee will be charged automatically from the payment method associated with the account';

  @override
  String get passengerCanContest =>
      '6. Passenger can contest the fee within 48 hours of notification';

  @override
  String get feeAmounts => '💰 Fee amounts';

  @override
  String get lightCleaning => '🧽 Light cleaning: 50-100 RON';

  @override
  String get wipingAndVacuuming =>
      '• Wiping and vacuuming light traces of dirt';

  @override
  String get removingSmallStains => '• Removing small stains from seats';

  @override
  String get intensiveCleaning => '🧼 Intensive cleaning: 150-300 RON';

  @override
  String get professionalCleaning =>
      '• Professional cleaning for large stains or odors';

  @override
  String get deodorizationAndSpecialTreatments =>
      '• Deodorization and special treatments';

  @override
  String get repairsAndReplacements =>
      '🔧 Repairs and replacements: 200-2000+ RON';

  @override
  String get replacingDamagedSeatCovers => '• Replacing damaged seat covers';

  @override
  String get repairingDamagedComponents => '• Repairing damaged components';

  @override
  String get costsDependOnSeverity =>
      '• Costs depend on the severity of the damage';

  @override
  String get yourRightsAsPassenger => '⚖️ Your rights as a passenger';

  @override
  String get rightToReceivePhotos =>
      '✅ You have the right to receive photos and complete details of the damage';

  @override
  String get canContestFee =>
      '✅ You can contest the fee within 48 hours through the app';

  @override
  String get rightToObjectiveInvestigation =>
      '✅ You have the right to an objective investigation of your case';

  @override
  String get ifContestationJustified =>
      '✅ In case of justified contestations, the fee will be fully refunded';

  @override
  String get howToAvoidFee => '🛡️ How to avoid cleaning or damage fees';

  @override
  String get doNotConsumeFood =>
      '• Do not consume food or drinks in the vehicle';

  @override
  String get checkShoesNotDirty =>
      '• Check that shoes are not dirty before getting in';

  @override
  String get notifyDriverIfFeelingUnwell =>
      '• Notify the driver if you feel unwell and need a break';

  @override
  String get doNotSmokeInVehicle => '• Do not smoke in the vehicle';

  @override
  String get treatVehicleWithRespect =>
      '• Treat the vehicle with the same respect as if it were yours';

  @override
  String get takeTrashWithYou => '• Take trash with you at the end of the trip';

  @override
  String get contestationProcess => '📝 Contestation process';

  @override
  String get accessRideHistory =>
      '1. Access the \"Ride History\" section in the app';

  @override
  String get selectRideForContestation =>
      '2. Select the ride for which you are contesting the fee';

  @override
  String get pressContestFee =>
      '3. Press \"Contest fee\" and fill out the form';

  @override
  String get addRelevantEvidence =>
      '4. Add any relevant evidence (photos, explanations)';

  @override
  String get teamWillReanalyze =>
      '5. Our team will reanalyze the case within 72 hours';

  @override
  String get receiveDetailedResponse =>
      '6. You will receive a detailed response via email and in the app';

  @override
  String get haveQuestionsOrNeedAssistance =>
      '📞 Have questions or need assistance?';

  @override
  String get emailSupport => '📧 Email: suport@nabour.ro';

  @override
  String get phoneSupport => '📱 Phone: +40 700 NABOUR';

  @override
  String get chatInApp => '💬 Chat in app: Help section';

  @override
  String get scheduleSupport => '🕒 Schedule: Monday-Sunday, 24/7';

  @override
  String get importantToRemember => '⚠️ Important to remember';

  @override
  String get feeOnlyAppliedWithClearEvidence =>
      'The cleaning and damage fee is only applied in cases where there is clear evidence of vehicle damage or soiling. The Nabour team analyzes each case individually and ensures that all fees are justified and correct.';

  @override
  String get howToActivateDriverMode =>
      'How to activate Nabour partner driver mode';

  @override
  String get toBecomeDriverPartner =>
      'To become a Nabour driver partner, follow these steps:';

  @override
  String get checkConditions => '1. Check conditions';

  @override
  String get validLicenseRequired =>
      'You must have a valid driver\'s license, at least 2 years of experience and be at least 21 years old.';

  @override
  String get prepareDocuments => '2. Prepare documents';

  @override
  String get documentsNeeded =>
      'You need: driver\'s license, ID card, vehicle registration certificate, valid ITP and RCA insurance.';

  @override
  String get completeApplication => '3. Complete application';

  @override
  String get accessCareerSection =>
      'Access the \"Career\" section from the main menu and fill out the online form with your data.';

  @override
  String get submitDocuments => '4. Submit documents';

  @override
  String get uploadClearPhotos =>
      'Upload clear photos of all required documents through the online platform.';

  @override
  String get applicationVerification => '5. Application verification';

  @override
  String get teamWillVerify =>
      'Our team will verify the documents within 48 business hours.';

  @override
  String get receiveActivationCode => '6. Receive activation code';

  @override
  String get afterApproval =>
      'After approval, you will receive a unique code via email/SMS to activate your driver account.';

  @override
  String get activateAccount => '7. Activate account';

  @override
  String get enterCodeInApp =>
      'Enter the code in the app and start earning money by driving!';

  @override
  String get usefulTip => '💡 Useful tip:';

  @override
  String get ensureDocumentsValid =>
      'Make sure all documents are valid and photos are clear for quick processing.';

  @override
  String get ratesAndPayments => 'Rates and payments';

  @override
  String get ratesAndPaymentsInfo => 'Information about Rates and Payments';

  @override
  String get ratesCalculatedAutomatically =>
      '• Rates are calculated automatically based on distance and time';

  @override
  String get paymentMadeAutomatically =>
      '• Payment is made automatically through the saved method in the account';

  @override
  String get canSeeRateDetails =>
      '• You can see the rate details before confirming the ride';

  @override
  String get inCaseOfPaymentProblems =>
      '• In case of payment problems, contact support';

  @override
  String get forCurrentRatesDetails =>
      'For details about current rates, check in the app.';

  @override
  String get deliveryOrderRequest => 'Delivery order request';

  @override
  String get deliveryServices => 'Delivery Services';

  @override
  String get currentlyFocusedOnTransport =>
      'Currently, we are focused on passenger transport services.';

  @override
  String get deliveryServicesAvailableSoon =>
      'Delivery services will be available in the near future.';

  @override
  String get weWillNotifyYou =>
      'We will notify you when this feature becomes active!';

  @override
  String get appFunctioningProblems => 'App functioning problems';

  @override
  String get ifAppNotWorkingCorrectly => 'If the app is not working correctly:';

  @override
  String get updateAppToLatest => '3. Update the app to the latest version';

  @override
  String get restartPhone => '4. Restart the phone';

  @override
  String get reinstallAppIfPersists =>
      '5. Reinstall the app if the problem persists';

  @override
  String get ifProblemContinues =>
      'If the problem continues, send us a report through support.';

  @override
  String get forgotPassword => 'Forgot password';

  @override
  String get enterEmailAssociated =>
      'Enter the email address associated with your account.';

  @override
  String get enterValidEmail => 'Enter a valid email address.';

  @override
  String get sendingResetEmail => 'Sending reset email...';

  @override
  String get resetEmailSent =>
      'A password reset email has been sent. Check your inbox (including Spam folder)!';

  @override
  String get errorSendingResetEmail =>
      'An error occurred while sending the reset email.';

  @override
  String get noAccountWithEmail => 'No account exists with this email address.';

  @override
  String get unexpectedError => 'Unexpected error. Please try again';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get applyNow => 'Apply Now';

  @override
  String get contentComingSoon =>
      'Content for this topic will be available soon.';

  @override
  String get joinTeam => 'Join Nabour team';

  @override
  String get applyForDriver => 'Apply for Nabour Driver Partner';

  @override
  String get neighborhoodRequests => 'Neighborhood Requests';

  @override
  String get neighborhoodChat => 'Neighborhood Chat';

  @override
  String get activateDriverCode => 'Activate Driver Mode Code';

  @override
  String get activateDriverCodeTitle => 'Activate Driver Code';

  @override
  String get activateDriverCodeDescription =>
      'Enter the activation code you received to become a Nabour driver partner.';

  @override
  String get enterActivationCode => 'Please enter the activation code.';

  @override
  String get codeTooShort =>
      'The entered code is too short. Please check again.';

  @override
  String get validatingCode => 'Validating code...';

  @override
  String get codeActivatedSuccess =>
      'Code activated successfully! You are now a driver.';

  @override
  String get codeInvalidOrUsed => 'Invalid or already used code. Please check.';

  @override
  String errorValidatingCode(String error) {
    return 'Error validating code: $error';
  }

  @override
  String get lowDataMode => 'Low data mode';

  @override
  String get highContrastUI => 'High-contrast UI';

  @override
  String get assistantStatusOverlay => 'Assistant status overlay';

  @override
  String get performanceOverlay => 'Performance overlay';

  @override
  String get aiGreeting => 'Hello, where would you like to go?';

  @override
  String get aiSearchingDrivers => 'Searching for available drivers...';

  @override
  String get aiSearchingDriversInArea =>
      'Searching for available drivers in your area...';

  @override
  String aiDriverFound(int minutes) {
    return 'Found an available driver $minutes minutes away.';
  }

  @override
  String get aiBestDriverSelected =>
      'Selected the best driver for you. Sending ride request...';

  @override
  String get aiNoDriversAvailable =>
      'Sorry, but I couldn\'t find any available drivers in your area. Please try again later.';

  @override
  String get aiEverythingResolved =>
      'Perfect! I\'ve resolved everything automatically. Your ride request has been sent!';

  @override
  String get subscriptionsTitle => 'Nabour Subscriptions';

  @override
  String get recommended => 'RECOMMENDED';

  @override
  String get ronPerMonth => 'RON / month';

  @override
  String planSelected(String plan) {
    return 'You selected the $plan plan! (simulation)';
  }

  @override
  String get choosePlan => 'Choose Plan';

  @override
  String get subscriptionBasicDescription => 'For occasional trips.';

  @override
  String get subscriptionPlusDescription => 'The most popular plan.';

  @override
  String get subscriptionPremiumDescription => 'Exclusive benefits.';

  @override
  String get subscriptionBasicBenefit1 => '5% discount on 10 rides/month';

  @override
  String get subscriptionBasicBenefit2 => 'Free cancellation within 2 minutes';

  @override
  String get subscriptionPlusBenefit1 => '10% discount on all rides';

  @override
  String get subscriptionPlusBenefit2 => 'Free cancellation within 5 minutes';

  @override
  String get subscriptionPlusBenefit3 => 'Priority support 24/7';

  @override
  String get subscriptionPremiumBenefit1 => '15% discount on all rides';

  @override
  String get subscriptionPremiumBenefit2 => 'Free cancellation anytime';

  @override
  String get subscriptionPremiumBenefit3 => 'Priority support 24/7';

  @override
  String get subscriptionPremiumBenefit4 => 'Access to premium vehicles';

  @override
  String get deleteConfirmation => 'Delete Confirmation';

  @override
  String deleteRideConfirmation(String destination) {
    return 'Are you sure you want to permanently delete the ride to \"$destination\" from your history? This action is irreversible.';
  }

  @override
  String get rideDeletedSuccess => 'Ride deleted successfully!';

  @override
  String errorLoadingRole(String error) {
    return 'Error loading role: $error';
  }

  @override
  String get errorGeneric => 'Error';

  @override
  String get errorLoadingData => 'Error loading data';

  @override
  String errorDetails(String error) {
    return 'Details: $error';
  }

  @override
  String get retry => 'Retry';

  @override
  String get noRidesInPeriod => 'You have no rides in the selected period.';

  @override
  String get filterAll => 'All';

  @override
  String get filterLastMonth => 'Last Month';

  @override
  String get filterLast3Months => 'Last 3 Months';

  @override
  String get filterThisYear => 'This Year';

  @override
  String rideDate(String date) {
    return 'Date: $date';
  }

  @override
  String get deleteRide => 'Delete ride';

  @override
  String get asDriver => 'As Driver';

  @override
  String get asPassenger => 'As Passenger';

  @override
  String get errorLoadingUserRole => 'Error loading user role.';

  @override
  String get receiptsTitle => 'Your Receipts';

  @override
  String get receiptsTitlePassenger => 'Receipts (Passenger)';

  @override
  String get errorLoadingReceipts => 'Error loading receipts';

  @override
  String get noReceiptsInPeriod =>
      'You have no receipts in this category for the selected period.';

  @override
  String deleteSelectedReceipts(int count) {
    return 'Delete $count selected receipts?';
  }

  @override
  String get deleteSelectedReceiptsWarning =>
      'This action will permanently delete the selected receipts. This action cannot be undone.';

  @override
  String receiptsDeletedSuccess(int count) {
    return 'Successfully deleted $count receipts.';
  }

  @override
  String receiptsDeletedPartial(int deleted, int error) {
    return 'Deleted $deleted receipts. $error could not be deleted.';
  }

  @override
  String deleteAllReceipts(int count) {
    return 'Delete all receipts ($count)?';
  }

  @override
  String get deleteAllReceiptsWarning =>
      'This action will permanently delete ALL receipts from the selected period. This action cannot be undone.';

  @override
  String allReceiptsDeleted(int count) {
    return 'Deleted $count receipts.';
  }

  @override
  String get filterAllReceipts => 'All';

  @override
  String get generating => 'Generating...';

  @override
  String get monthlyReportPDF => 'Monthly Report PDF';

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String get selectAll => 'Select all';

  @override
  String get deselectAll => 'Deselect all';

  @override
  String get deleteSelected => 'Delete selected';

  @override
  String get deleteAll => 'Delete all';

  @override
  String get noRidesForReport =>
      'No rides in the last month to generate report.';

  @override
  String get returnToMapQuestion => 'Do you want to return to the main map?';

  @override
  String rideTo(String destination) {
    return 'Ride to: $destination';
  }

  @override
  String rideFrom(String date) {
    return 'Ride from $date';
  }

  @override
  String get from => 'From:';

  @override
  String get earningsSummary => 'Earnings Summary';

  @override
  String get totalRide => 'Total Ride:';

  @override
  String get appCommission => 'App Commission:';

  @override
  String get yourEarnings => 'Your Earnings:';

  @override
  String get activeRideDetected => 'Active ride detected';

  @override
  String get cancelPreviousRide => 'Cancel previous ride';

  @override
  String get rideAcceptedWaiting =>
      'Ride accepted! Waiting for passenger confirmation...';

  @override
  String get driverProfileLoading =>
      'Driver profile is loading, please try again...';

  @override
  String get searching => 'Searching…';

  @override
  String get searchInThisArea => 'Search in this area';

  @override
  String get declining => 'Declining...';

  @override
  String get decline => 'Decline';

  @override
  String get accepting => 'Accepting...';

  @override
  String get accept => 'Accept';

  @override
  String get addAsStop => 'Add as stop';

  @override
  String get pickupPointDeleted => 'Pickup point has been deleted';

  @override
  String get destinationDeleted => 'Destination has been deleted';

  @override
  String get selectPickupAndDestination =>
      'Select pickup point and destination';

  @override
  String get rideSummary => 'Ride Summary';

  @override
  String get couldNotLoadRideDetails => 'Could not load ride details';

  @override
  String get back => 'Back';

  @override
  String get noTip => 'No tip';

  @override
  String get routeNotLoaded => '🗺️ Could not load route automatically';

  @override
  String get rideCancelledSuccess => 'Ride has been cancelled successfully';

  @override
  String get forceCancelRide => 'Force Cancel Ride';

  @override
  String get passengerAddedStop =>
      'Passenger has added a new stop. Route has been recalculated.';

  @override
  String get stopAdded => 'Stop added! Route and cost have been updated.';

  @override
  String errorAddingStop(String error) {
    return 'Error adding stop: $error';
  }

  @override
  String get navigationWithGoogleMaps => 'Navigation with Google Maps';

  @override
  String get navigationWithWaze => 'Navigation with Waze';

  @override
  String get safetyTeamNotified =>
      'We have notified the safety team. We are with you.';

  @override
  String get sendViaApps => 'Send via apps';

  @override
  String get noTrustedContacts => 'You have no trusted contacts';

  @override
  String get manageContacts => 'Manage contacts';

  @override
  String get iAmSafe => 'I am safe';

  @override
  String get falseAlarm => 'False alarm';

  @override
  String get shareRoute => 'Share route';

  @override
  String get rideCancelledSuccessShort =>
      'Ride has been cancelled successfully';

  @override
  String get recenterMap => 'Recenter map';

  @override
  String get mapMovedTapToRecenter => 'Map moved. Tap to recenter';

  @override
  String get entrySelected => 'Entry selected.';

  @override
  String get addStop => 'Add Stop';

  @override
  String navigationBanner(String type, String modifier, String distance) {
    return 'Navigation banner. $type $modifier. Distance $distance meters.';
  }

  @override
  String entrySelectedWithLabel(String label) {
    return 'Entry selected: $label';
  }

  @override
  String get editMessage => 'Edit message';

  @override
  String get passengerNotifiedArrived =>
      '✅ Passenger has been notified that you have arrived!';

  @override
  String get cannotOpenPhoneApp => 'Cannot open phone app';

  @override
  String errorLoadingRoute(String error) {
    return 'Error loading route: $error';
  }

  @override
  String rideCancelledReason(String reason) {
    return 'Ride cancelled: $reason';
  }

  @override
  String get selectCancellationReason => 'Select cancellation reason:';

  @override
  String get backButton => 'Back';

  @override
  String get passengerNotResponding => 'Passenger not responding';

  @override
  String get technicalProblem => 'Technical problem';

  @override
  String get pickupRide => 'Pickup Ride';

  @override
  String get loadingPassengerInfo => 'Loading passenger information...';

  @override
  String get pleaseValidateAddress =>
      'Please validate the address or select it from the map.';

  @override
  String get editAddress => 'Edit Address';

  @override
  String get addNewAddress => 'Add New Address';

  @override
  String errorVoiceRecognition(String error) {
    return 'Error in voice recognition: $error';
  }

  @override
  String get updateAddress => 'Update Address';

  @override
  String get saveAddress => 'Save Address';

  @override
  String get resetPasswordButton => 'Reset Password';

  @override
  String get pleaseFillAllFields => 'Please fill in all fields correctly.';

  @override
  String get welcomeBack => '👋 Welcome back!';

  @override
  String get welcomeToNabour => 'Welcome to Nabour!';

  @override
  String get pleaseEnterValidEmail =>
      'Please enter a valid email address in the Email field for reset.';

  @override
  String get errorResettingPassword =>
      'An unexpected error occurred while resetting password.';

  @override
  String get enterValidPhoneNumber => 'Enter a valid phone number.';

  @override
  String get autoAuthCompleted => 'Automatic authentication completed';

  @override
  String errorAutoAuth(String error) {
    return 'Auto authentication error: $error';
  }

  @override
  String get enterSmsCode => 'Enter the received SMS code.';

  @override
  String get verifyAndAuthenticate => 'Verify and Authenticate';

  @override
  String get max5Stops => 'You can add a maximum of 5 stops';

  @override
  String addressNotFound(String address) {
    return 'Could not find address: $address';
  }

  @override
  String noCoordinatesForDestination(String error) {
    return 'No coordinates found for destination: $error';
  }

  @override
  String get fillBothAddresses => 'Fill in both addresses to continue';

  @override
  String get intermediateStopAdded => 'Intermediate stop added';

  @override
  String get home => 'Home';

  @override
  String get work => 'Work';

  @override
  String get edit => 'Edit';

  @override
  String get recentDestinations => 'Recent Destinations';

  @override
  String get noFavoriteAddressAdded => 'No favorite address added.';

  @override
  String get addressUpdated => 'Address has been updated!';

  @override
  String get addressSaved => 'Address has been saved!';

  @override
  String get pleaseSelectRating => 'Please select a rating before submitting.';

  @override
  String get ratingSentSuccess => 'Rating sent successfully!';

  @override
  String errorSendingRating(String error) {
    return 'Error sending rating: $error';
  }

  @override
  String get rideDetailsCompleted => 'Completed Ride Details';

  @override
  String get saveRating => 'Save Rating';

  @override
  String errorConfirmingDriver(String error) {
    return 'Error confirming driver: $error';
  }

  @override
  String errorDecliningDriver(String error) {
    return 'Error declining driver: $error';
  }

  @override
  String get backToMap => 'Back to Map';

  @override
  String get currentLocation => 'Current location';

  @override
  String get finalDestination => 'Final destination';

  @override
  String get accordingToSelection => 'According to selection';

  @override
  String get waitingResponse => '⏳ WAITING FOR RESPONSE...';

  @override
  String get waitingConfirmation =>
      '❓ WAITING FOR CONFIRMATION\n\nSay YES or NO';

  @override
  String get arrivedNotifyPassenger => 'Arrived - Notify passenger';

  @override
  String get passengerBoarding => 'Passenger boarding';

  @override
  String get route => 'Route';

  @override
  String get preferencesSaved => 'Preferences have been saved';

  @override
  String get pleaseSelectRatingBeforeSubmit =>
      'Please select a rating before submitting.';

  @override
  String get errorSubmittingRating =>
      'Error submitting rating. Please try again.';

  @override
  String get thankYouForRide => 'Thank you for the ride!';

  @override
  String get howWasExperience => 'How was your experience?';

  @override
  String get leaveCommentOptional => 'Leave a comment (optional)';

  @override
  String get thanksForRating => 'Thanks for rating!';

  @override
  String get ratePassenger => 'Rate Passenger';

  @override
  String get shortCharacterization =>
      'Brief characterization (e.g., clean, made a mess)';

  @override
  String get addPrivateNoteAboutPassenger =>
      'Add a private note about passenger...';

  @override
  String get routeUpdated => 'Route Updated';

  @override
  String get passengerAddedNewStop =>
      'Passenger has added a new stop. Route has been recalculated.';

  @override
  String get ok => 'OK';

  @override
  String get rideManagement => 'Ride Management';

  @override
  String get modifyDestination => 'Modify Destination';

  @override
  String get cannotModifyCompletedRide =>
      'You cannot modify the destination for a completed or cancelled ride.';

  @override
  String get destinationUpdatedSuccessfully =>
      'Destination updated successfully!';

  @override
  String errorUpdatingDestination(String error) {
    return 'Error updating destination: $error';
  }

  @override
  String get changeFinalLocation => 'Change final location';

  @override
  String get intermediateStop => 'Intermediate stop';

  @override
  String get mayIncludeCancellationFee => 'May include cancellation fee';

  @override
  String get viewReceipt => 'View Receipt';

  @override
  String get completeRideDetails => 'Complete ride details';

  @override
  String get rateRide => 'Rate Ride';

  @override
  String get provideDriverFeedback => 'Provide feedback to driver';

  @override
  String get communication => 'Communication';

  @override
  String get callDriver => 'Call Driver';

  @override
  String chatWith(String name) {
    return 'Chat with $name';
  }

  @override
  String get chatAvailableSoon => 'Chat will be available soon';

  @override
  String get costSummary => 'Cost Summary';

  @override
  String get baseFare => 'Base fare:';

  @override
  String time(String min) {
    return 'Time ($min min):';
  }

  @override
  String get totalPaid => 'Total Paid:';

  @override
  String get ratingGiven => 'Rating given:';

  @override
  String get noRatingGiven => 'No rating given';

  @override
  String get optionalComments => 'Optional comments...';

  @override
  String get howWasYourExperience => 'How was your experience?';

  @override
  String get routeNotLoadedAuto => '🗺️ Could not load route automatically';

  @override
  String get rideCancelledSuccessfully =>
      'Ride has been cancelled successfully.';

  @override
  String get stopAddedRouteUpdated =>
      'Stop added! Route and cost have been updated.';

  @override
  String get writeNewText => 'Write new text...';

  @override
  String get messageEditedSuccess => 'Message has been edited successfully!';

  @override
  String errorEditingMessage(String error) {
    return 'Error editing message: $error';
  }

  @override
  String errorCancelling(String error) {
    return 'Error cancelling: $error';
  }

  @override
  String get inviteFriendsDescription =>
      'Invite neighbors to join the Nabour community';

  @override
  String get splitPayment => 'Split Payment';

  @override
  String get splitPaymentDescription =>
      'Split the ride cost with other passengers';

  @override
  String get createSplitPayment => 'Create Split';

  @override
  String get splitPaymentCreated => 'Split payment created';

  @override
  String get shareLinkWithParticipants => 'Share the link with participants:';

  @override
  String get share => 'Share';

  @override
  String get splitWithHowMany => 'Split with how many?';

  @override
  String get selectNumberOfPeople => 'Select number of people';

  @override
  String get confirm => 'Confirm';

  @override
  String get acceptSplitPayment => 'Accept Split';

  @override
  String get markAsPaid => 'Mark as Paid';

  @override
  String get totalAmount => 'Total';

  @override
  String get perPerson => 'Per Person';

  @override
  String get participants => 'Participants';

  @override
  String get participant => 'Participant';

  @override
  String get paid => 'Paid';

  @override
  String get pending => 'Pending';

  @override
  String get accepted => 'Accepted';

  @override
  String get completed => 'Completed';

  @override
  String get rejected => 'Rejected';

  @override
  String get cancelled => 'Cancelled';

  @override
  String errorCreatingSplitPayment(String error) {
    return 'Error creating split payment: $error';
  }

  @override
  String errorAcceptingSplitPayment(String error) {
    return 'Error accepting split payment: $error';
  }

  @override
  String errorCompletingPayment(String error) {
    return 'Error completing payment: $error';
  }

  @override
  String get paymentCompleted => 'Payment completed';

  @override
  String get promotionCode => 'Promotion Code';

  @override
  String get enterPromotionCode => 'Enter promotion code';

  @override
  String get apply => 'Apply';

  @override
  String get promotionAppliedSuccessfully =>
      'Promotion code applied successfully';

  @override
  String get subscriptionsHelpTitle => 'Subscriptions and Promotions';

  @override
  String get subscriptionsHelpOverview =>
      'Nabour subscriptions offer exclusive benefits and discounts on rides.';

  @override
  String get subscriptionsHelpPlans => 'Available Plans:';

  @override
  String get subscriptionsHelpBasic =>
      '• Nabour Basic - 5% discount on 10 rides/month';

  @override
  String get subscriptionsHelpPlus =>
      '• Nabour Plus - 10% discount on all rides (Recommended)';

  @override
  String get subscriptionsHelpPremium =>
      '• Nabour Premium - 15% discount + exclusive benefits';

  @override
  String get subscriptionsHelpHowToSubscribe => 'How to subscribe:';

  @override
  String get subscriptionsHelpGoToMenu => '1. Go to hamburger menu';

  @override
  String get subscriptionsHelpTapSubscriptions =>
      '2. Tap \'Subscriptions and Promotions\'';

  @override
  String get subscriptionsHelpSelectPlan => '3. Select desired plan';

  @override
  String get subscriptionsHelpCompletePayment => '4. Complete payment';

  @override
  String get subscriptionsHelpPromotions => 'Active Promotions:';

  @override
  String get subscriptionsHelpPromotionsInfo =>
      'Check the \'Promotions\' section for special offers and available promotional codes.';

  @override
  String get subscriptionsHelpReferral => 'Referral Program:';

  @override
  String get subscriptionsHelpReferralInfo =>
      'Share your referral code and receive benefits for each friend who signs up.';

  @override
  String get splitPaymentHelpTitle => 'Split Payment - Cost Sharing';

  @override
  String get splitPaymentHelpOverview =>
      'Split Payment allows you to share the ride cost with other passengers.';

  @override
  String get splitPaymentHelpHowToCreate => 'How to create Split Payment:';

  @override
  String get splitPaymentHelpAfterRide =>
      '1. After completing the ride, tap \'Split Payment\'';

  @override
  String get splitPaymentHelpSelectPeople =>
      '2. Select the number of people to split with';

  @override
  String get splitPaymentHelpShareLink =>
      '3. Share the generated link with participants';

  @override
  String get splitPaymentHelpParticipantsAccept =>
      '4. Participants accept and pay their share';

  @override
  String get splitPaymentHelpHowToAccept => 'How to accept Split Payment:';

  @override
  String get splitPaymentHelpReceiveLink => '1. Receive the sharing link';

  @override
  String get splitPaymentHelpTapAccept => '2. Tap \'Accept Split\'';

  @override
  String get splitPaymentHelpSelectPayment => '3. Select payment method';

  @override
  String get splitPaymentHelpCompletePayment => '4. Complete payment';

  @override
  String get splitPaymentHelpNote =>
      'Note: Split Payment is only available for completed rides.';

  @override
  String get rideSharingHelpTitle => 'Ride Sharing - Shared Rides';

  @override
  String get rideSharingHelpOverview =>
      'Ride Sharing allows you to share your ride with other passengers going in the same direction.';

  @override
  String get rideSharingHelpHowToEnable => 'How to enable Ride Sharing:';

  @override
  String get rideSharingHelpDuringRequest =>
      '1. During ride request, enable \'Ride Sharing\' option';

  @override
  String get rideSharingHelpSystemMatches =>
      '2. System will automatically search for compatible passengers';

  @override
  String get rideSharingHelpIfMatchFound =>
      '3. If a match is found, you will be notified';

  @override
  String get rideSharingHelpBenefits => 'Benefits:';

  @override
  String get rideSharingHelpCostReduction =>
      '• Significant cost reduction for the ride';

  @override
  String get rideSharingHelpEcoFriendly => '• Environmentally friendly option';

  @override
  String get rideSharingHelpSocial => '• Opportunity to meet new people';

  @override
  String get rideSharingHelpNote =>
      'Note: Ride Sharing is only available for certain routes and in certain areas.';

  @override
  String get modifyDestinationHelpTitle => 'Modify Destination';

  @override
  String get modifyDestinationHelpOverview =>
      'You can modify the ride destination during an active ride.';

  @override
  String get modifyDestinationHelpHowToModify => 'How to modify destination:';

  @override
  String get modifyDestinationHelpDuringRide =>
      '1. During active ride, tap \'Ride Management\'';

  @override
  String get modifyDestinationHelpTapModify => '2. Tap \'Modify Destination\'';

  @override
  String get modifyDestinationHelpSelectNew => '3. Select new destination';

  @override
  String get modifyDestinationHelpConfirm => '4. Confirm modification';

  @override
  String get modifyDestinationHelpRouteRecalculated =>
      '5. Route and price will be recalculated automatically';

  @override
  String get modifyDestinationHelpLimitations => 'Limitations:';

  @override
  String get modifyDestinationHelpCannotModifyCompleted =>
      '• You cannot modify destination for completed or cancelled rides';

  @override
  String get modifyDestinationHelpPriceMayChange =>
      '• Price may vary depending on new destination';

  @override
  String get modifyDestinationHelpDriverNotified =>
      '• Driver will be automatically notified about the change';

  @override
  String get lowDataModeHelpTitle => 'Low Data Mode';

  @override
  String get lowDataModeHelpOverview =>
      'Low Data Mode reduces mobile data consumption by optimizing app functionalities.';

  @override
  String get lowDataModeHelpHowToEnable => 'How to enable Low Data Mode:';

  @override
  String get lowDataModeHelpGoToMenu => '1. Go to hamburger menu';

  @override
  String get lowDataModeHelpTapToggle => '2. Find the \'Low data mode\' option';

  @override
  String get lowDataModeHelpActivate => '3. Activate the toggle';

  @override
  String get lowDataModeHelpWhatItDoes => 'What Low Data Mode does:';

  @override
  String get lowDataModeHelpReducesImages =>
      '• Reduces image quality and caching';

  @override
  String get lowDataModeHelpLimitsAnimations =>
      '• Limits animations and visual effects';

  @override
  String get lowDataModeHelpOptimizesMaps => '• Optimizes map loading';

  @override
  String get lowDataModeHelpReducesSync =>
      '• Reduces real-time synchronization';

  @override
  String get lowDataModeHelpBenefits => 'Benefits:';

  @override
  String get lowDataModeHelpSavesData => '• Saves mobile data';

  @override
  String get lowDataModeHelpFasterLoading =>
      '• Faster loading on weak connections';

  @override
  String get lowDataModeHelpBatteryLife => '• Improves battery life';

  @override
  String get lowDataModeHelpNote =>
      'Note: Low Data Mode may affect the quality of some features, but the app remains fully functional.';

  @override
  String get highContrastUIHelpTitle => 'High-Contrast UI';

  @override
  String get highContrastUIHelpOverview =>
      'High-Contrast UI improves visibility for users with visual impairments or in low-light conditions.';

  @override
  String get highContrastUIHelpHowToEnable => 'How to enable High-Contrast UI:';

  @override
  String get highContrastUIHelpGoToMenu => '1. Go to hamburger menu';

  @override
  String get highContrastUIHelpTapToggle =>
      '2. Find the \'High-contrast UI\' option';

  @override
  String get highContrastUIHelpActivate => '3. Activate the toggle';

  @override
  String get highContrastUIHelpWhatItDoes => 'What High-Contrast UI does:';

  @override
  String get highContrastUIHelpIncreasesContrast =>
      '• Increases contrast between text and background';

  @override
  String get highContrastUIHelpBolderText =>
      '• Makes text bolder and easier to read';

  @override
  String get highContrastUIHelpClearerIcons =>
      '• Makes icons and buttons more visible';

  @override
  String get highContrastUIHelpBetterVisibility =>
      '• Improves visibility in low-light conditions';

  @override
  String get highContrastUIHelpBenefits => 'Benefits:';

  @override
  String get highContrastUIHelpAccessibility =>
      '• Improves accessibility for users with visual impairments';

  @override
  String get highContrastUIHelpReadability => '• Easier to read text';

  @override
  String get highContrastUIHelpOutdoorUse =>
      '• Better use in bright light conditions';

  @override
  String get highContrastUIHelpNote =>
      'Note: High-Contrast UI is available for both light and dark themes.';

  @override
  String get assistantStatusOverlayHelpTitle => 'Assistant Status Overlay';

  @override
  String get assistantStatusOverlayHelpOverview =>
      'Assistant Status Overlay displays a small indicator in the corner of the screen showing when the AI assistant is processing commands.';

  @override
  String get assistantStatusOverlayHelpHowToEnable =>
      'How to enable Assistant Status Overlay:';

  @override
  String get assistantStatusOverlayHelpGoToMenu => '1. Go to hamburger menu';

  @override
  String get assistantStatusOverlayHelpTapToggle =>
      '2. Find the \'Assistant status overlay\' option';

  @override
  String get assistantStatusOverlayHelpActivate => '3. Activate the toggle';

  @override
  String get assistantStatusOverlayHelpWhatItShows =>
      'What the indicator shows:';

  @override
  String get assistantStatusOverlayHelpWorking =>
      '• \'Working\' - when the AI assistant is processing commands or interacting with the user';

  @override
  String get assistantStatusOverlayHelpWaiting =>
      '• \'Waiting for commands\' - when the AI assistant is inactive and waiting for commands';

  @override
  String get assistantStatusOverlayHelpLocation =>
      'Where the indicator appears:';

  @override
  String get assistantStatusOverlayHelpTopRight =>
      '• The indicator appears in the top-right corner of the screen';

  @override
  String get assistantStatusOverlayHelpNonIntrusive =>
      '• It is non-intrusive and does not interfere with app usage';

  @override
  String get assistantStatusOverlayHelpBenefits => 'Benefits:';

  @override
  String get assistantStatusOverlayHelpVisualFeedback =>
      '• Quick visual feedback about the AI assistant\'s status';

  @override
  String get assistantStatusOverlayHelpDebugging =>
      '• Useful for debugging and understanding when AI is working';

  @override
  String get assistantStatusOverlayHelpTransparency =>
      '• Transparency about assistant activity';

  @override
  String get assistantStatusOverlayHelpNote =>
      'Note: The indicator updates automatically when you start or stop voice interaction with AI.';

  @override
  String get securityAndSafety => 'Security & Safety';

  @override
  String get changePasswordSubtitle => 'Change your account password';

  @override
  String get sessions => 'Sessions';

  @override
  String get logoutAllDevices => 'Log out from all devices';

  @override
  String get logoutAllDevicesSubtitle => 'Sign out from all connected devices';

  @override
  String get dangerZone => 'Danger zone';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountSubtitle =>
      'Permanently delete account and all associated data';

  @override
  String get confirmLogoutAllDevicesTitle => 'Log out from all devices';

  @override
  String get confirmLogoutAllDevicesContent =>
      'You will be logged out from all devices, including the current one. You will need to sign in again.';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get permanentDeleteAccount => 'Permanently delete account';

  @override
  String get attention => 'Warning! This action is irreversible.';

  @override
  String get willBeDeletedTitle => 'The following will be permanently deleted:';

  @override
  String get willBeDeletedProfile => '• Your profile';

  @override
  String get willBeDeletedRideHistory => '• Ride history';

  @override
  String get willBeDeletedData => '• All associated account data';

  @override
  String get accountPassword => 'Account password';

  @override
  String get enterPasswordConfirm => 'Enter your password to confirm.';

  @override
  String get deleteAccountButton => 'Delete account';

  @override
  String errorPrefix(Object error) {
    return 'Error: $error';
  }

  @override
  String get notificationPreferences => 'Notification Preferences';

  @override
  String get notifRideSection => 'Rides';

  @override
  String get notifRideNotifications => 'Ride notifications';

  @override
  String get notifRideNotificationsSubtitle =>
      'New requests, ride accepted, driver nearby, etc.';

  @override
  String get notifCommunicationSection => 'Communication';

  @override
  String get notifChatMessages => 'Chat messages';

  @override
  String get notifChatMessagesSubtitle =>
      'Notifications for new messages in conversations';

  @override
  String get notifMarketingSection => 'Marketing and updates';

  @override
  String get notifPromoOffers => 'Promotions and offers';

  @override
  String get notifPromoOffersSubtitle =>
      'Discounts, promo codes and special offers';

  @override
  String get notifAppUpdates => 'App updates';

  @override
  String get notifAppUpdatesSubtitle => 'News and improvements to the app';

  @override
  String get notifSafetySection => 'Safety';

  @override
  String get notifSafetyAlerts => 'Safety alerts';

  @override
  String get notifSafetyAlertsSubtitle =>
      'Important notifications related to your safety during a ride';

  @override
  String get notifSavedSuccess => 'Preferences saved successfully.';

  @override
  String notifLoadError(Object error) {
    return 'Error loading preferences: $error';
  }

  @override
  String notifSaveError(Object error) {
    return 'Error saving: $error';
  }

  @override
  String get privacyLocationSection => 'Location';

  @override
  String get privacyLocationSharing => 'Real-time location sharing';

  @override
  String get privacyLocationSharingSubtitle =>
      'Allow sharing your location with the driver during a ride';

  @override
  String get privacyProfileSection => 'Profile';

  @override
  String get privacyProfileVisibility => 'Profile visibility for drivers';

  @override
  String get privacyProfileVisibilitySubtitle =>
      'Drivers can see your profile (name, photo, rating)';

  @override
  String get privacyRideHistoryVisible => 'Ride history visible';

  @override
  String get privacyRideHistoryVisibleSubtitle =>
      'Allow displaying ride history in your public profile';

  @override
  String get privacyDataSection => 'Data and analytics';

  @override
  String get privacyAnalyticsConsent => 'Data for service improvement';

  @override
  String get privacyAnalyticsConsentSubtitle =>
      'Help us improve the app by sharing anonymous usage data';

  @override
  String get privacyGdprNote =>
      'Your data is processed in accordance with GDPR. You can request data export or deletion from the Security & Safety section.';

  @override
  String get privacySavedSuccess => 'Privacy settings saved.';

  @override
  String privacyLoadError(Object error) {
    return 'Error loading settings: $error';
  }

  @override
  String privacySaveError(Object error) {
    return 'Error saving: $error';
  }

  @override
  String get adminDocumentReview => 'Driver Document Review';

  @override
  String get noPendingApplications => 'No pending applications.';

  @override
  String get unknownApplicant => 'Unknown applicant';

  @override
  String statusLabel(Object status) {
    return 'Status: $status';
  }

  @override
  String get missingRequired => 'Missing (required)';

  @override
  String get missing => 'Missing';

  @override
  String rejectDocumentTitle(Object name) {
    return 'Reject: $name';
  }

  @override
  String get rejectReason => 'Rejection reason';

  @override
  String get rejectionHint => 'e.g. Blurry image, expired document';

  @override
  String documentApproved(Object name) {
    return '✅ $name approved';
  }

  @override
  String documentRejected(Object name) {
    return '❌ $name rejected';
  }

  @override
  String get activateDriver => 'Activate Driver';

  @override
  String get driverActivatedTitle => 'Driver Activated ✅';

  @override
  String driverActivatedContent(Object name) {
    return '$name has been activated successfully.';
  }

  @override
  String get accessCodeLabel => 'Access code:';

  @override
  String get accessCodeGenerated => 'Generated access code:';

  @override
  String get sendCodeToDriver => 'Please send this code to the driver.';

  @override
  String activationError(Object error) {
    return 'Activation error: $error';
  }

  @override
  String get approveTooltip => 'Approve';

  @override
  String get rejectTooltip => 'Reject';

  @override
  String rejectionReasonLabel(Object reason) {
    return 'Reason: $reason';
  }

  @override
  String get statusSubmitted => 'Submitted';

  @override
  String get statusUnderReview => 'Under Review';

  @override
  String get statusApproved => 'Approved';

  @override
  String get statusActivated => 'Activated';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get docStatusApproved => 'Approved';

  @override
  String get docStatusRejected => 'Rejected';

  @override
  String get docStatusPending => 'Pending';

  @override
  String docExpiresOn(Object date) {
    return 'Expires: $date';
  }

  @override
  String docExpiredLabel(Object date) {
    return 'EXPIRED ($date)';
  }

  @override
  String docExpiringSoonLabel(Object date) {
    return 'Expiring soon ($date)';
  }

  @override
  String get bePartnerDriver => 'Become a Partner Driver';

  @override
  String get applicationProgress => 'Application progress';

  @override
  String get applicationComplete =>
      'Application is complete and can be submitted!';

  @override
  String get applicationIncomplete =>
      'Complete the information and documents to continue';

  @override
  String get accountActivated => 'Account Activated 🎉';

  @override
  String accessCodeGeneratedAt(Object date) {
    return 'Generated at: $date';
  }

  @override
  String get personalInfoStep => 'Personal Information';

  @override
  String get vehicleInfoStep => 'Vehicle Information';

  @override
  String get finalDocumentsStep => 'Final Documents';

  @override
  String get fullNameLabel => 'Full Name *';

  @override
  String get ageLabel => 'Age *';

  @override
  String get carBrandLabel => 'Make *';

  @override
  String get carModelLabel => 'Model *';

  @override
  String get carColorLabel => 'Color *';

  @override
  String get carYearLabel => 'Year *';

  @override
  String get licensePlateLabel => 'License Plate *';

  @override
  String get bankAccountLabel => 'Bank Account (IBAN)';

  @override
  String get importantInfoTitle => 'Important information';

  @override
  String get applicationConfirmationText =>
      'By submitting the application, you confirm that:\n• All provided information is accurate\n• You agree to the Terms and Conditions\n• You accept document verification\n• You are at least 21 years old';

  @override
  String get applicationIncompleteWarning =>
      'Please complete all required fields and upload the necessary documents before submitting the application.';

  @override
  String get applicationSubmitSuccess =>
      'Application submitted successfully for review!';

  @override
  String applicationLoadError(Object error) {
    return 'Error loading data: $error';
  }

  @override
  String applicationSaveError(Object error) {
    return 'Error saving data: $error';
  }

  @override
  String applicationSubmitError(Object error) {
    return 'Error submitting application: $error';
  }

  @override
  String documentUploadSuccess(Object name) {
    return '$name uploaded successfully!';
  }

  @override
  String documentDeleteSuccess(Object name) {
    return '$name deleted successfully!';
  }

  @override
  String documentUploadError(Object error) {
    return 'Error uploading document: $error';
  }

  @override
  String documentDeleteError(Object error) {
    return 'Error deleting document: $error';
  }

  @override
  String get selectSourceTitle => 'Select source';

  @override
  String get selectSourceContent =>
      'Where would you like to select the image from?';

  @override
  String get cameraOption => 'Camera';

  @override
  String get galleryOption => 'Gallery';

  @override
  String get selectFileTypeTitle => 'Select file type';

  @override
  String get selectFileTypeContent =>
      'Would you like to upload an image or a PDF document?';

  @override
  String get imageOption => 'Image';

  @override
  String get pdfOption => 'PDF';

  @override
  String get requiredBadge => 'Required';

  @override
  String get documentUploadedText => 'Document uploaded successfully';

  @override
  String get tapToUploadText => 'Tap to upload the document';

  @override
  String get continueBtn => 'Continue';

  @override
  String get submitApplication => 'Submit Application';

  @override
  String get backBtn => 'Back';

  @override
  String get expiryDateTitle => 'Expiry date';

  @override
  String expiryDateQuestion(Object name) {
    return 'Would you like to set an expiry date for \"$name\"?';
  }

  @override
  String get skipExpiry => 'No, skip';

  @override
  String get photographOption => 'Take photo';

  @override
  String get selectFromGallery => 'Select from gallery';

  @override
  String get viewDocumentOption => 'View';

  @override
  String get deleteDocumentOption => 'Delete';

  @override
  String get pdfDocument => 'PDF Document';

  @override
  String get tapToOpen => 'Tap to open';

  @override
  String get errorLoadingImage => 'Error loading image';

  @override
  String get fileTooLarge => 'File is too large (max 10MB)';

  @override
  String get serviceUnavailable => 'Service temporarily unavailable';

  @override
  String get connectionError =>
      'Connection problem. Please check your internet';

  @override
  String uploadedAt(Object date) {
    return 'Uploaded: $date';
  }

  @override
  String get selectExpiryDate => 'Select expiry date';

  @override
  String get yes => 'Yes';

  @override
  String get drawerSectionActivityAccount => 'Activity & account';

  @override
  String get drawerSectionYourCommunity => 'Your community';

  @override
  String get drawerSectionMyBusiness => 'My business';

  @override
  String get drawerSectionGetInvolved => 'Get involved';

  @override
  String get drawerSectionAiPerformance => 'AI & performance';

  @override
  String get drawerSectionSupportInfo => 'Support & info';

  @override
  String get drawerSectionAddresses => 'Addresses';

  @override
  String get drawerFavoriteAddresses => 'Favorite addresses';

  @override
  String get drawerBusinessOffersTitle => 'Local offers';

  @override
  String get drawerSocialMapTitle => 'Social map';

  @override
  String get drawerSocialVisible => 'Visible';

  @override
  String get drawerSocialHidden => 'Hidden';

  @override
  String get drawerVoiceAiSettingsTitle => 'AI voice settings';

  @override
  String drawerBusinessDashboardTitle(String businessName) {
    return 'My dashboard: $businessName';
  }

  @override
  String get drawerBusinessRegisterTitle => 'Register your business';

  @override
  String get businessIntroTitle => 'My business';

  @override
  String get businessIntroBody =>
      'You need to register your business first. After that you can manage it: edit your card shown in Local offers and manage announcements (add, edit, or remove) from your business dashboard.';

  @override
  String get businessIntroContinueButton => 'Continue to registration';

  @override
  String get drawerTeamNabour => 'The Nabour team';

  @override
  String get drawerRolePassenger => 'Passenger';

  @override
  String get drawerRoleDriver => 'Driver';

  @override
  String get drawerThemeDarkLabel => 'Theme: Dark';

  @override
  String get drawerThemeLightLabel => 'Theme: Light';

  @override
  String get drawerMenuWeekReview => 'Week in Review';

  @override
  String get drawerMenuMysteryBoxActivity => 'Mystery box activity';

  @override
  String get drawerMenuTokenTransfer => 'Token transfer';

  @override
  String get drawerGroupAccountActivity => 'Account, history & activity';

  @override
  String get drawerGroupMapAddresses => 'Map & addresses';

  @override
  String get drawerGroupCommunityFeed => 'Community & discovery';

  @override
  String get drawerGroupSocialApp => 'Visibility & app';

  @override
  String get drawerGroupHelpLegal => 'Help & legal info';

  @override
  String get drawerMenuMyGarage => 'My garage';

  @override
  String get drawerMenuPlaces => 'Places';

  @override
  String get drawerMenuExplorations => 'Explorations';

  @override
  String get drawerMenuSyncContacts => 'Sync contacts';

  @override
  String get drawerSyncContactsDialogTitle => 'Why sync contacts?';

  @override
  String get drawerSyncContactsDialogBody =>
      'The map only shows people who are in your phone contacts and also use Nabour.\n\nIf you added a new contact or a friend just joined, tap Sync to refresh who can appear on the social map.';

  @override
  String get drawerSyncContactsDialogOk => 'Got it';

  @override
  String get warmupCloseTooltip => 'Close';

  @override
  String get warmupHeadline => 'Travel with\nyour neighbors';

  @override
  String get warmupShortcutsTitle => 'Shortcuts';

  @override
  String get warmupShortcutRideTitle => 'Ride';

  @override
  String get warmupShortcutRideSubtitle => 'Request now';

  @override
  String get warmupShortcutMapTitle => 'Map';

  @override
  String get warmupShortcutMapSubtitle => 'Who\'s around';

  @override
  String get warmupShortcutChatTitle => 'Chat';

  @override
  String get warmupShortcutChatSubtitle => 'Your area';

  @override
  String get warmupScheduleTitle => 'Plan ahead';

  @override
  String get warmupScheduleSubtitle =>
      'Post early — neighbors confirm when they\'re free.';

  @override
  String get warmupWhyTitle => 'Why Nabour?';

  @override
  String get warmupCtaOpenMap => 'Open map';

  @override
  String get warmupSwipeDownHint => 'Or swipe down to close';

  @override
  String get warmupHeroNeighborsTitle => 'Rides with neighbors';

  @override
  String get warmupHeroNeighborsSubtitle =>
      'Request a ride on the map; available drivers in the community can pick you up.';

  @override
  String get warmupHeroBusinessTitle => 'Local offers';

  @override
  String get warmupHeroBusinessSubtitle =>
      'Promote your business with notices visible nearby, right in the app.';

  @override
  String get warmupHeroSafetyTitle => 'Safety on the go';

  @override
  String get warmupHeroSafetySubtitle =>
      'Live route sharing, in-ride chat, and clear pickup checks.';

  @override
  String get warmupHeroChatTitle => 'Neighborhood chat';

  @override
  String get warmupHeroChatSubtitle =>
      'Talk in your area; you can also filter to people in your contacts.';

  @override
  String get warmupFeatureCommunityTitle => 'One ecosystem';

  @override
  String get warmupFeatureCommunitySubtitle =>
      'Rides, chat, and offers in one app — simpler than juggling group chats.';

  @override
  String get warmupFeatureContactsTitle => 'Trust, your way';

  @override
  String get warmupFeatureContactsSubtitle =>
      'Choose who sees you: your area or only people from your contacts.';

  @override
  String get warmupFeatureLiveTitle => 'Live on the map';

  @override
  String get warmupFeatureLiveSubtitle =>
      'Availability and status update so you quickly see who can help.';

  @override
  String get warmupFeatureSecureTitle => 'Clear and predictable';

  @override
  String get warmupFeatureSecureSubtitle =>
      'History, simple tokens for actions, and support when you need it.';

  @override
  String get drawerDefaultUserName => 'User';

  @override
  String get drawerTrialPrivilegedTitle => 'Privileged account';

  @override
  String get drawerTrialPrivilegedSubtitle =>
      'Unlimited access to all features.';

  @override
  String get drawerTrialSevenDayTitle => '7-day trial';

  @override
  String get drawerTrialPricingSubtitle =>
      'Then 10 RON/month (individual) or 15 RON/month (business).';

  @override
  String get drawerTrialDuringSubtitle =>
      'Then 10 RON/month (individual) / 15 RON/month (business).';

  @override
  String drawerTrialDaysLeftTitle(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days left in trial',
      one: '1 day left in trial',
    );
    return '$_temp0';
  }

  @override
  String get drawerTrialExpiredTitle => 'Trial ended';

  @override
  String get drawerTrialExpiredSubtitle => 'Subscribe (10/15 RON) to continue.';

  @override
  String get activateDriverCodeLabel => 'Activation code';

  @override
  String get activateDriverCodeHint => 'e.g. DRV-TEST-102';

  @override
  String get tokenShopTitle => 'Tokens & plans';

  @override
  String get tokenShopTabPlans => 'Plans';

  @override
  String get tokenShopTabTopup => 'Top-up';

  @override
  String get tokenShopTabHistory => 'History';

  @override
  String get tokenShopChoosePlanTitle => 'Choose your plan';

  @override
  String get tokenShopChoosePlanSubtitle =>
      'Tokens reset on the first day of each month';

  @override
  String get tokenShopAlreadyOnPlan => 'You\'re already on this plan.';

  @override
  String get tokenShopDowngradeContactSupport =>
      'Contact support to downgrade.';

  @override
  String tokenShopUpgradeSuccess(String planName) {
    return 'Upgraded to $planName!';
  }

  @override
  String get tokenShopErrorPaymentsNotReady =>
      'Payments aren\'t enabled on the server yet. Configure Cloud Functions (see functions/).';

  @override
  String tokenShopErrorWithMessage(String message) {
    return 'Error: $message';
  }

  @override
  String tokenShopUpgradeError(String error) {
    return 'Upgrade error: $error';
  }

  @override
  String get tokenShopMostPopular => 'MOST POPULAR';

  @override
  String get tokenShopPopularBadge => 'POPULAR';

  @override
  String get tokenShopActive => 'Active';

  @override
  String get tokenShopSelect => 'Select';

  @override
  String get tokenShopBuyExtraTitle => 'Buy extra tokens';

  @override
  String get tokenShopBuyExtraSubtitle => 'Purchased tokens never expire';

  @override
  String get tokenShopTokensWord => 'tokens';

  @override
  String tokenShopTokensAdded(int count) {
    return '+$count tokens added to your wallet!';
  }

  @override
  String get tokenShopTopupRequiresBackend =>
      'Top-up requires backend (ALLOW_UNVERIFIED_WALLET_CREDIT or real payment).';

  @override
  String get tokenShopNoTransactions => 'No transactions yet.';

  @override
  String get tokenShopPaymentMethodsTitle => 'Accepted payment methods';

  @override
  String get tokenShopPaymentSecureFooter =>
      'Payments are processed securely. We never store card details.';

  @override
  String get tokenShopPaymentMethodTitle => 'Payment method';

  @override
  String get tokenShopPay => 'Pay';

  @override
  String get tokenShopTestModeDisclaimer =>
      'Real payments are not wired yet. Pay simulates checkout: your plan and balance update via Firebase Functions. If you get an error, deploy functions or set ALLOW_UNVERIFIED_WALLET_CREDIT=true in the Firebase console.';

  @override
  String get tokenShopMethodNetopia => 'Netopia (RO card)';

  @override
  String get tokenShopMethodStripe => 'Stripe';

  @override
  String get tokenShopMethodRevolut => 'Revolut Pay';

  @override
  String get tokenShopPackageStarter => 'Starter';

  @override
  String get tokenShopPackagePopular => 'Popular';

  @override
  String get tokenShopPackageAdvanced => 'Advanced';

  @override
  String get tokenShopPackageBusiness => 'Business';

  @override
  String get tokenPlanFreeName => 'Free';

  @override
  String get tokenPlanBasicName => 'Basic';

  @override
  String get tokenPlanProName => 'Pro';

  @override
  String get tokenPlanUnlimitedName => 'Unlimited';

  @override
  String get tokenPlanPriceFree => 'Free';

  @override
  String get tokenPlanPriceBasic => '9 RON / month';

  @override
  String get tokenPlanPricePro => '29 RON / month';

  @override
  String get tokenPlanPriceUnlimited => '49 RON / month';

  @override
  String tokenShopPlanAllowanceMonthly(String allowance) {
    return '$allowance tokens / month';
  }

  @override
  String tokenShopEconomyApproxLine(int ai, int routes, int geo, int br) {
    return '≈ $ai AI · $routes routes · $geo geocoding · $br posts';
  }

  @override
  String tokenShopEconomyBusinessLine(int biz, int tokens) {
    return '≈ $biz business ads ($tokens tokens each)';
  }

  @override
  String get tokenShopEconomyUnlimited =>
      'Unlimited: AI, routes, geocoding and posts without using your monthly quota.';

  @override
  String get tokenShopStaffMenuTooltip => 'Apply staff subscription';

  @override
  String get tokenShopStaffDialogTitle =>
      'Staff subscription (authorized account)';

  @override
  String get tokenShopStaffApplied => 'Subscription applied.';

  @override
  String tokenShopTxPurchasePackage(String label, int count) {
    return 'Package $label · $count tokens';
  }

  @override
  String get appMissionTagline =>
      'Neighbors, rides, and block chat — one app on your map.';

  @override
  String get settingsSectionUpdates => 'Updates';

  @override
  String get settingsSectionInterfaceData => 'Interface & data';

  @override
  String get settingsSectionPrivacyLanguage => 'Privacy & language';

  @override
  String get settingsVisibilityExclusionsTitle => 'Visibility exclusions';

  @override
  String get settingsVisibilityExclusionsSubtitle =>
      'Choose who cannot see you on the social map';

  @override
  String get driverMenuViewDailyReport => 'View daily report';

  @override
  String get accountScreenTitle => 'Nabour account';

  @override
  String get accountDefaultNeighbor => 'Neighbor';

  @override
  String get accountDriverPartnerBadge => 'Nabour partner driver';

  @override
  String get accountMenuDriverVehicleDetails => 'Driver & vehicle details';

  @override
  String get accountMenuPersonalDetails => 'Personal details';

  @override
  String get accountMenuSecurity => 'Safety & account';

  @override
  String get accountMenuSavedAddresses => 'Saved addresses';

  @override
  String get accountMenuRidePreferences => 'Ride preferences';

  @override
  String get accountMenuRideHistory => 'Ride history';

  @override
  String get accountMenuBusinessProfile => 'Business profile';

  @override
  String get accountMenuSelfieVerification => 'Identity check (selfie)';

  @override
  String get accountMenuNotifications => 'Notifications';

  @override
  String get accountMenuPrivacy => 'Privacy';

  @override
  String get accountDeleteTitle => 'Delete account permanently';

  @override
  String get accountDeleteBody =>
      'This cannot be undone. Enter your password to confirm.';

  @override
  String get accountDeletePasswordLabel => 'Password';

  @override
  String get accountDeletePasswordError => 'Please enter your password.';

  @override
  String get accountDeleteConfirm => 'Delete account';

  @override
  String tokenWalletBalanceShort(String balance) {
    return '$balance tokens';
  }

  @override
  String tokenWalletDrawerSubline(String spent, String allowance, String when) {
    return '$spent / $allowance used · resets $when';
  }

  @override
  String tokenWalletAvailableLong(String balance) {
    return '$balance tokens available';
  }

  @override
  String tokenWalletPlanLine(String planName) {
    return '$planName plan';
  }

  @override
  String get tokenWalletUsedThisMonth => 'Used this month';

  @override
  String tokenWalletPercentUsage(String pct, String spent, String allowance) {
    return '$pct% ($spent / $allowance)';
  }

  @override
  String tokenWalletAutoReset(String when) {
    return 'Auto reset: $when';
  }

  @override
  String get tokenWalletStatTotalSpent => 'Total spent';

  @override
  String get tokenWalletStatTotalEarned => 'Total received';

  @override
  String get tokenWalletOpenShopCta => 'Tokens & plans';

  @override
  String tokenWalletResetInDays(int days) {
    return 'in $days days';
  }

  @override
  String tokenWalletResetInHours(int hours) {
    return 'in $hours h';
  }

  @override
  String get tokenWalletResetTomorrow => 'tomorrow';

  @override
  String get helpWeekReviewTitle => 'Week in Review and location history';

  @override
  String get helpWeekReviewHeader => 'How Week in Review works';

  @override
  String get helpWeekReviewIntro =>
      'Week in Review builds a visual recap of your movement over a selected period (usually the last week), with animated route playback, hotspots, and stats (km / active hours).';

  @override
  String get helpWeekReviewDataSourceTitle => 'Where the data comes from';

  @override
  String get helpWeekReviewDataSourceBody =>
      'The app uses raw location points from the backend only as input to generate the recap.';

  @override
  String get helpWeekReviewStorageTitle => 'Where recap is stored';

  @override
  String get helpWeekReviewStorageBody =>
      'Processed history, timeline, hotspots, and Week in Review exports are stored locally on your device.';

  @override
  String get helpWeekReviewDeleteTitle => 'How to delete';

  @override
  String get helpWeekReviewDeleteBody =>
      'Go to Settings -> Location history (Timeline) -> Clear local history. You can also set local retention (for example 30/60/90 days).';

  @override
  String get helpWeekReviewPrivacyNote =>
      'Privacy-first: recap data and exported files stay local on your phone. You control retention and deletion.';

  @override
  String get businessOffersNoOffersInSelectedCategory =>
      'No offers in the selected category';

  @override
  String get businessOffersNoOffersInArea => 'No offers in your area';

  @override
  String get businessOffersTryAnotherCategory => 'Try another category.';

  @override
  String get businessOffersNoNearbyOffers =>
      'Come back later for nearby offers.';

  @override
  String get businessOffersManageFilters => 'Manage filters';

  @override
  String get businessOffersResetCategory => 'Reset category';

  @override
  String get businessOffersAllCategories => 'All categories';
}

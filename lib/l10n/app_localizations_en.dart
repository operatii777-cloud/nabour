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
  String get about_titleNabour => 'About Nabour';

  @override
  String get about_evaluateApp => 'Evaluate App';

  @override
  String get about_howManyStars => 'How many stars do you give the Nabour app?';

  @override
  String get about_starSelected => 'star selected';

  @override
  String get about_starsSelected => 'stars selected';

  @override
  String get cancel => 'Cancel';

  @override
  String get select => 'Select';

  @override
  String about_ratingSentSuccessfully(String rating) {
    return '✅ Rating of $rating stars sent successfully!';
  }

  @override
  String get about_career => 'Career';

  @override
  String get about_joinOurTeam => 'Join our team';

  @override
  String get about_evaluateApplication => 'Evaluate application';

  @override
  String get about_giveStarRating => '⭐ Give a star rating';

  @override
  String get about_followUs => 'Follow us';

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
  String get career => 'Career';

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
  String get confirmedGoToPassenger => 'Confirmed. Go to passenger';

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
  String get safety_emergencyAssistanceButton => 'Emergency Assistance Button';

  @override
  String get safety_emergencyAssistanceButtonDesc =>
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
  String get rideSummary_thankYouForRide => 'Thank you for the ride!';

  @override
  String get rideSummary_howWasExperience => 'How was your experience?';

  @override
  String get rideSummary_leaveCommentOptional => 'Leave a comment (optional)';

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
  String get drawerShowHomeOnMap =>
      'Show Home (favorite) on map\n(only for you)';

  @override
  String get drawerOrientationMarkerOnMap =>
      'Orientation marker on map\n(long-press on the map after enabling)';

  @override
  String get drawerHideHomeOnMap =>
      'Hide Home from map\n(only the favorite marker)';

  @override
  String get drawerHideOrientationMarker =>
      'Hide orientation marker\n(remove pin from the map)';

  @override
  String get drawerActiveContactsOnMap => 'Active contacts on map';

  @override
  String get drawerIdCopied => 'ID copied to clipboard.';

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
  String get warmupCtaOpenMap => 'Go to map';

  @override
  String get warmupSubtitle => 'Your Neighborhood Hub';

  @override
  String warmupExampleRidesCount(String count) {
    return '$count Active Rides Nearby';
  }

  @override
  String warmupExampleDealsCount(String count) {
    return '$count New Deals Today';
  }

  @override
  String warmupExampleMessagesCount(String count) {
    return '$count New Messages';
  }

  @override
  String get warmupExampleRide1 => 'Sarah B. (2 min) → Downtown';

  @override
  String get warmupExampleRide2 => 'Mike K. (5 min) → Station';

  @override
  String get warmupExampleOffer1 => 'The Daily Grind: 20% off all coffees';

  @override
  String get warmupExampleOffer2 => 'Urban Bites: Free side with any main';

  @override
  String get warmupExampleChat1 =>
      'Alex: Anyone want to join the park walk...?';

  @override
  String get warmupExampleChat2 => 'Chloe: Heard a loud bang on Elm St...';

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
  String get about_appMissionTagline =>
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

  @override
  String get mapGhostDurationTitle => 'How long are you visible to neighbors?';

  @override
  String get mapGhostDurationSubtitle =>
      'Neighbors will see you as a bubble on the map.';

  @override
  String get mapGhostOneHourLabel => '1 hour';

  @override
  String get mapGhostOneHourSub => 'Useful for a short outing';

  @override
  String get mapGhostFourHoursLabel => '4 hours';

  @override
  String get mapGhostFourHoursSub => 'Useful for an afternoon';

  @override
  String get mapGhostUntilTomorrowLabel => 'Until tomorrow';

  @override
  String get mapGhostUntilTomorrowSub => 'Resets at midnight';

  @override
  String get mapGhostPermanentLabel => 'Permanent';

  @override
  String get mapGhostPermanentSub =>
      'You remain visible until you manually disable it';

  @override
  String get mapGhostInvisibleLabel => 'Invisible (ghost mode)';

  @override
  String get mapGhostInvisibleSub =>
      'You do not appear on the map; profile marks ghostMode in account (synced across devices).';

  @override
  String get mapDeleteMomentTitle => 'Delete this moment?';

  @override
  String get mapDeleteMomentContent =>
      'The post will disappear from the map for everyone.';

  @override
  String get mapMomentDeleted => 'Moment deleted.';

  @override
  String get mapMomentDeleteError =>
      'Could not delete the moment. Please try again.';

  @override
  String get mapDeleteOrCancelPost => 'Delete / cancel post';

  @override
  String get mapPinNameLabel => 'Name';

  @override
  String get mapPinNameHint => 'e.g.: main entrance';

  @override
  String get mapPinNameTitle => 'Marker name';

  @override
  String get mapOrientationPinSaved => 'Orientation marker saved on map.';

  @override
  String get mapEditHomeAddressTitle => 'Edit Home address';

  @override
  String get mapEditHomeAddressSubtitle =>
      'Change location from Saved addresses';

  @override
  String get mapHideHomeFromMapTitle => 'Hide Home from map';

  @override
  String get mapMoveOrientationMarkerTitle => 'Move marker';

  @override
  String mapMoveOrientationMarkerWithName(String name) {
    return '\"$name\" · then long-press on the map at the new location';
  }

  @override
  String get mapMoveOrientationMarkerNoName =>
      'Then long-press on the map at the new location';

  @override
  String get mapLongPressForNewMarker =>
      'Long-press on the map for the new marker.';

  @override
  String get mapRemoveOrientationMarkerTitle => 'Remove orientation marker';

  @override
  String get mapMarkerRemoved => 'Marker removed.';

  @override
  String get mapSaveHomeFirst =>
      'Save the \"Home\" address in favorites (with map position), then try again.';

  @override
  String get mapHomeShownForYou =>
      'Favorite Home is shown on map (only for you).';

  @override
  String get mapHomeNotShown => 'Home is not shown on map.';

  @override
  String get mapHomeNoLongerShown => 'Home is no longer shown on map.';

  @override
  String get mapNoOrientationMarker =>
      'You do not have an orientation marker on the map.';

  @override
  String get mapOrientationMarkerRemovedFromMap =>
      'Orientation marker was removed from map.';

  @override
  String get mapEmojiRemoved => 'Your emoji was removed from the map.';

  @override
  String get mapEmojiDeleteError => 'Could not delete emoji. Please try again.';

  @override
  String get mapMomentExpired => 'Expired';

  @override
  String mapMomentExpiresInMinutes(int minutes) {
    return '~$minutes min until it disappears from the map';
  }

  @override
  String get mapMomentExpiresSoon => 'Will disappear from the map soon';

  @override
  String mapArrivedAtDestination(String destination) {
    return 'You arrived at destination: $destination';
  }

  @override
  String get mapDestinationUnset => 'Destination not set';

  @override
  String mapRideBroadcastWantsToGo(String destination) {
    return 'Wants to go to: $destination';
  }

  @override
  String get mapSeeRequestAndOfferRide => 'SEE REQUEST AND OFFER RIDE';

  @override
  String mapAcceptRideError(String error) {
    return 'Error accepting ride: $error';
  }

  @override
  String get mapPickupExternalNavigation => 'Pickup: external navigation';

  @override
  String get mapDestinationExternalNavigation =>
      'Destination: external navigation';

  @override
  String get mapClosePanel => 'Close panel';

  @override
  String get mapWaitingGpsLocation => 'Waiting for GPS location...';

  @override
  String mapCreateRideError(String error) {
    return 'Error creating ride: $error';
  }

  @override
  String get mapWaitingGpsToPlaceBox =>
      'Waiting for GPS position to place the box here.';

  @override
  String get mapPlace => 'Place';

  @override
  String mapBoxPlaced(int tokens) {
    return 'Box placed! (-$tokens tokens)';
  }

  @override
  String mapPoiLoadError(String error) {
    return 'Error loading POIs: $error';
  }

  @override
  String get mapNavigateToMarkedPlace => 'Navigate to marked place';

  @override
  String get mapDeleteMarkerAndRestart => 'Delete marker and start again';

  @override
  String get mapSpotReserved => 'Spot reserved! You have 3 minutes to arrive.';

  @override
  String get mapAddToFavoriteAddresses => 'Add to favorite addresses';

  @override
  String get mapNavigateWithExternalApps => 'Navigate with Google Maps / Waze';

  @override
  String get mapSpotAlreadyReserved =>
      'Sorry, the spot has already been reserved.';

  @override
  String get chatImageTooLargePrivate =>
      'Image is still too large after compression (max ~1.8 MB). Try a smaller photo.';

  @override
  String get chatImageTooLargeGeneral => 'Image is too large (max ~7 MB).';

  @override
  String get chatImageUploadFailed => 'Could not upload image.';

  @override
  String get chatPhotoLabel => 'Photo';

  @override
  String get chatVoiceMessageLabel => 'Voice message';

  @override
  String get chatMessageSendFailed => 'Message could not be sent.';

  @override
  String get chatGifLabel => 'GIF';

  @override
  String get chatPhoneNotAvailable => 'Phone number is not available.';

  @override
  String get chatCallFailed => 'Could not start the call.';

  @override
  String get chatMessagesLoadFailed => 'Could not load messages.';

  @override
  String get chatTyping => 'typing...';

  @override
  String get chatEndToEndEncrypted => 'Messages are end-to-end encrypted.';

  @override
  String get chatToday => 'Today';

  @override
  String get chatYesterday => 'Yesterday';

  @override
  String get chatQuickReplyHere => 'I am here 👋';

  @override
  String get chatQuickReplyIn2Min => 'Coming in 2 min ⏱️';

  @override
  String get chatQuickReplyIn5Min => 'Coming in 5 min ⏱️';

  @override
  String get chatQuickReplyArrived => 'Have you arrived? 📍';

  @override
  String get chatQuickReplyThanks => 'Thanks! 🙏';

  @override
  String get chatQuickReplyOk => 'OK 👍';

  @override
  String get you => 'You';

  @override
  String get chatVoiceMessageSendFailed => 'Voice message could not be sent.';

  @override
  String get chatReply => 'Reply';

  @override
  String get chatCopy => 'Copy';

  @override
  String get chatMessageCopied => 'Message copied.';

  @override
  String get chatChooseGif => 'Choose GIF';

  @override
  String get chatSearchHint => 'Search…';

  @override
  String get privateChatNotAuthenticated => 'You are not authenticated.';

  @override
  String get privateChatReaction => 'Reaction';

  @override
  String get privateChatNewChat => 'New chat';

  @override
  String get privateChatAddContactsToChoose =>
      'Add contacts in your address book or friends so you can choose a person.';

  @override
  String get privateChatOnMap => 'On map';

  @override
  String get privateChatNoPeopleYet =>
      'You don\'t have people in contacts or confirmed friends yet.';

  @override
  String get privateChatAddContactsOrAcceptSuggestions =>
      'Add contacts or accept requests in the Suggestions tab to start private conversations.';

  @override
  String get privateChatConversationsHint =>
      'Private conversations - same messages as from a neighbor profile on the map.';

  @override
  String get privateChatOnMapNowTapToWrite => 'On map now - tap to write';

  @override
  String get privateChatTapToSendMessage => 'Tap to send a message';

  @override
  String get chatLocationLabel => 'Location';

  @override
  String get friendSuggestionsUserFallback => 'User';

  @override
  String get friendSuggestionsAlreadyFriends =>
      'You are already friends in Nabour.';

  @override
  String get friendSuggestionsRequestAlreadySent =>
      'You already sent a request to this person.';

  @override
  String get friendSuggestionsRequestSent => 'Friend request sent!';

  @override
  String get friendSuggestionsRequestPermissionDenied =>
      'We are not allowed to write this request (Firebase rules). Contact support.';

  @override
  String get friendSuggestionsRequestFailed =>
      'Could not send the request. Please try again.';

  @override
  String friendSuggestionsAcceptedFrom(String name) {
    return 'You accepted the request from $name! ✓';
  }

  @override
  String get friendSuggestionsFriendFallback => 'friend';

  @override
  String get friendSuggestionsPermissionAcceptDenied =>
      'We are not allowed to accept this request (Firebase rules).';

  @override
  String get friendSuggestionsAcceptFailed =>
      'Could not accept the request. Please try again.';

  @override
  String get friendSuggestionsRejected => 'Request rejected.';

  @override
  String get friendSuggestionsRejectFailed =>
      'Could not reject the request. Please try again.';

  @override
  String get friendSuggestionsThisUser => 'this user';

  @override
  String get friendSuggestionsRemoveTitle => 'Remove friend';

  @override
  String friendSuggestionsRemoveConfirm(String name) {
    return 'Are you sure you want to remove $name from your list? You will no longer see each other on the map as Nabour friends until you send requests again.';
  }

  @override
  String get friendSuggestionsCancel => 'Cancel';

  @override
  String get friendSuggestionsRemove => 'Remove';

  @override
  String friendSuggestionsRemovedFromList(String name) {
    return '$name was removed from your list.';
  }

  @override
  String get friendSuggestionsRemoveFailed =>
      'Could not remove. Please try again.';

  @override
  String get friendSuggestionsTabSuggestions => 'Suggestions';

  @override
  String get friendSuggestionsTabMyFriends => 'My friends';

  @override
  String get friendSuggestionsTabPrivateChat => 'Private chat';

  @override
  String get friendSuggestionsSearchHint => 'Search in contacts...';

  @override
  String friendSuggestionsIncomingRequests(int count) {
    return 'Incoming requests ($count)';
  }

  @override
  String get friendSuggestionsAddressBookSuggestions =>
      'Address book suggestions';

  @override
  String get friendSuggestionsNoConfirmedFriends =>
      'You don\'t have confirmed friends yet.\nAccept requests in Suggestions tab or send one yourself.';

  @override
  String get friendSuggestionsLoading => 'Loading…';

  @override
  String get friendSuggestionsOnMapNow => 'On map now';

  @override
  String get friendSuggestionsNabourFriend => 'Nabour friend';

  @override
  String get friendSuggestionsSendsRequest => 'sent you a friend request';

  @override
  String get friendSuggestionsReject => 'Reject';

  @override
  String get friendSuggestionsAccept => 'Accept';

  @override
  String friendSuggestionsIntroOne(int count) {
    return '$count INTRODUCTION';
  }

  @override
  String friendSuggestionsIntroMany(int count) {
    return '$count INTRODUCTIONS';
  }

  @override
  String friendSuggestionsFriendsCount(int count) {
    return '$count FRIENDS';
  }

  @override
  String get friendSuggestionsFriendsCount50Plus => '50+ FRIENDS';

  @override
  String get friendSuggestionsFriendBadge => 'Friend';

  @override
  String get friendSuggestionsAdded => 'Added';

  @override
  String get friendSuggestionsAdd => 'Add';

  @override
  String get friendSuggestionsBackOnMap => 'is back on the map';

  @override
  String get disclaimerNoPaymentsTitle =>
      'Nabour does not intermediate payments';

  @override
  String get disclaimerNoPaymentsSubtitle =>
      'The app does not intermediate payments between users.';

  @override
  String get disclaimerNoPaymentsBody =>
      'Nabour connects neighbors who want to help each other. If a driver chooses to accept or offer a gesture of appreciation, that is exclusively their personal decision and responsibility. The app does not intermediate, request, or process any type of payment.';

  @override
  String get disclaimerUsageNotice =>
      'Do not stay in the app for more than 40 minutes per day, monthly average - this can either generate costs or block your usage.';

  @override
  String get disclaimerUnderstood => 'I understand';

  @override
  String get splashStartupError =>
      'A startup error occurred.\nCheck your internet and try again.';

  @override
  String get splashRetry => 'RETRY';

  @override
  String get splashTakingLonger => 'Startup is taking longer...';

  @override
  String get splashContinueAnyway => 'CONTINUE ANYWAY';

  @override
  String get splashMadeInRomania => 'Made in Romania';

  @override
  String get settingsCommunityModeSchool => 'School / high school mode';

  @override
  String get settingsCommunityModeStandard => 'Standard (no community label)';

  @override
  String get settingsNowPlayingNotSet =>
      'Not set yet - visible in profile for friends';

  @override
  String get settingsVoiceAssistantOnMap => 'Voice assistant on map';

  @override
  String get settingsVoiceAssistantOnMapSubtitle =>
      'Map button and menu section (currently being improved)';

  @override
  String get settingsGhostModeTitle => 'Ghost mode (social map)';

  @override
  String get settingsGhostModeSubtitle =>
      'Enable \"Invisible\" from the social map menu; it stops RTDB and marks ghostMode in account.';

  @override
  String get settingsApproximateLocationTitle =>
      'Approximate location (social map)';

  @override
  String get settingsSocialMapSection => 'Social map';

  @override
  String get settingsNearbyNotificationsTitle => 'Notifications \"near me\"';

  @override
  String get settingsNearbyAlertRadiusTitle => 'Nearby alert radius';

  @override
  String settingsNearbyAlertRadiusSubtitle(int meters) {
    return '$meters m (contacts on map)';
  }

  @override
  String get settingsMusicTitle => 'Music (Spotify / Apple Music)';

  @override
  String get settingsMusicSubtitle => 'Open Spotify or Apple Music';

  @override
  String get settingsNowPlayingTitle => 'What I\'m listening now (profile)';

  @override
  String get settingsCommunityModeTitle => 'Community / school mode';

  @override
  String get settingsLocationHistoryTitle => 'Location history (Timeline)';

  @override
  String get settingsLocationHistoryStartFailed =>
      'Could not start recording. Grant location access and, on Android, \"Allow all the time\" for recording when app is not open.';

  @override
  String get settingsLocationHistoryEnabled =>
      'Location history was enabled (see Android notification while running in background).';

  @override
  String get settingsLocationHistoryDisabled =>
      'Location history was disabled.';

  @override
  String get settingsLocalHistoryRetentionTitle => 'Local history retention';

  @override
  String settingsLocalHistoryRetentionSubtitle(int days) {
    return 'Keep local data for $days days';
  }

  @override
  String get settingsDeleteLocalHistoryTitle => 'Delete local history';

  @override
  String get settingsDeleteLocalHistorySubtitle =>
      'Delete recap, cache and local timeline for this account';

  @override
  String get settingsNearbyNotificationRadiusTitle =>
      'Nearby notification radius';

  @override
  String settingsLocalHistoryRetentionSet(int days) {
    return 'Local retention was set to $days days.';
  }

  @override
  String get settingsNowPlayingSheetTitle => 'What I\'m listening now';

  @override
  String get settingsNowPlayingSongLabel => 'Song / title';

  @override
  String get settingsMusicProfileUpdated => 'Music profile updated.';

  @override
  String get settingsSaveToAccount => 'Save to account';

  @override
  String get settingsDeleteFromProfile => 'Delete from profile';

  @override
  String get settingsCommunitySheetTitle => 'Community';

  @override
  String get settingsCommunityModeSaved => 'Community mode saved.';

  @override
  String get settingsDeleteLocalHistoryConfirmTitle => 'Delete local history?';

  @override
  String get settingsDeleteLocalHistoryConfirmContent =>
      'This action deletes local recap and Week in Review cache for current account.';

  @override
  String get settingsLocalHistoryDeleted => 'Local history was deleted.';

  @override
  String tokenShopChoosePaymentMethodFor(String planName) {
    return 'Choose payment method for $planName';
  }

  @override
  String get tokenShopPayByCard => 'Pay by card';

  @override
  String tokenShopPriceWithAutoRenewal(String price) {
    return 'Price: $price (Auto-renewal)';
  }

  @override
  String get tokenShopPayWithTransferableTokens =>
      'Pay with transferable tokens';

  @override
  String tokenShopPriceInTokensNoRenewal(int tokens) {
    return 'Price: $tokens Tokens (No renewal)';
  }

  @override
  String get tokenShopInsufficientShort => 'Insufficient';

  @override
  String tokenShopPlanActivated(String planName) {
    return 'Plan $planName was activated!';
  }

  @override
  String get tokenShopUnlimitedAccessNetworkIntelligence =>
      'Absolute access to network intelligence.';

  @override
  String get tokenShopPersonalTokensSubtitle =>
      'Tokens for AI, routes and your features.';

  @override
  String get tokenShopTransferablePackagesTitle => 'TRANSFERABLE PACKAGES';

  @override
  String get tokenShopTransferablePackagesSubtitle =>
      'Real tokens that you can send to anyone.';

  @override
  String tokenShopTransferablePackageTitle(int tokens) {
    return 'Transferable package: $tokens Tokens';
  }

  @override
  String tokenShopTxPurchaseTransferablePackage(String label) {
    return 'TRANSFERABLE package purchase: $label';
  }

  @override
  String get tokenShopTransferableWalletSuffix => ' (in transferable wallet)';

  @override
  String get neighborhoodChatMuted => 'Chat muted';

  @override
  String get neighborhoodChatSoundOn => 'Sound enabled';

  @override
  String get neighborhoodChatGpsDisabled =>
      'GPS disabled. Enable location for chat.';

  @override
  String get neighborhoodChatGpsPermissionDenied => 'GPS permission denied.';

  @override
  String get neighborhoodChatInvalidServerResponse =>
      'Neighborhood chat: invalid server response (H3 roomId).';

  @override
  String neighborhoodChatFunctionsUnavailable(String code) {
    return 'Neighborhood chat: Functions unavailable ($code).';
  }

  @override
  String get neighborhoodChatActivationFailed =>
      'Could not activate neighborhood chat.';

  @override
  String get neighborhoodChatLocationResolveFailed =>
      'Could not determine location.';

  @override
  String get neighborhoodChatInappropriateMessage => 'Inappropriate message.';

  @override
  String get neighborhoodChatOnMyWay => 'I\'m on my way!';

  @override
  String get neighborhoodChatMarkedLocation => 'I marked a location on the map';

  @override
  String get neighborhoodChatTitle => 'Neighborhood chat';

  @override
  String get neighborhoodChatInviteNeighbors => 'Invite neighbors';

  @override
  String get neighborhoodChatNoAccessOrRulesChanged =>
      'You do not have access to this chat or security rules changed. Retry after re-authentication.';

  @override
  String get neighborhoodChatNoRecentMessages => 'No recent messages';

  @override
  String get neighborhoodChatEmptyHint =>
      'Say \"Hi\" to neighbors or send a location. Messages disappear after 30 minutes.';

  @override
  String get neighborhoodChatSendLocationTooltip => 'Send your location';

  @override
  String neighborhoodChatInviteText(String roomId) {
    return 'Come to Nabour neighborhood chat! We are neighbors in H3 zone: $roomId';
  }

  @override
  String get neighborhoodChatInfoBody1 =>
      'This is an ephemeral space for neighbors in the same H3 zone (approx. 1km²).';

  @override
  String get neighborhoodChatInfoBody2 =>
      '• Messages disappear automatically after 30 minutes.\n• You can send location or text messages.\n• Respect neighbors and keep the community clean!';

  @override
  String get neighborhoodChatFlyToHint =>
      'Tap for \"FlyTo\" animation to the point marked by the neighbor.';

  @override
  String get neighborhoodChatSeeOnMap => 'SEE ON MAP';

  @override
  String get placesHubTabLearned => 'Learned';

  @override
  String get placesHubTabFavorites => 'Favorites';

  @override
  String get placesHubTabRecommendations => 'Recommendations';

  @override
  String get placesHubNoLearnedPlaces =>
      'We don\'t have learned places yet. Keep the app open on the map - we detect areas where you stay longer (private, on device).';

  @override
  String placesHubFrequentArea(int minutes) {
    return 'Frequent area ($minutes accumulated min)';
  }

  @override
  String placesHubVisitsConfidence(int visits, int confidence) {
    return '$visits visits - confidence $confidence%';
  }

  @override
  String get placesHubFavoritesHint =>
      'Your saved addresses also appear on the map as \"home / work\" when you are nearby.';

  @override
  String get placesHubManageFavoriteAddresses => 'Manage favorite addresses';

  @override
  String get placesHubDiscoverNeighborhood => 'Discover the neighborhood';

  @override
  String get placesHubDiscoverNeighborhoodHint =>
      'Enable visibility on the social map to see requests, moments and neighbors. Learned places are enriched automatically from your movement.';

  @override
  String get placesHubFriendsNearbyTitle => 'Friends nearby';

  @override
  String get placesHubFriendsNearbySubtitle =>
      'On the main map you can see contacts that added you and are close.';

  @override
  String get placesHubPreviewTitle => 'Preview';

  @override
  String get rideBroadcastDeleteRequestTitle => 'Delete request';

  @override
  String get rideBroadcastDeleteRequestConfirm =>
      'Are you sure you want to delete this request from your history?';

  @override
  String get rideBroadcastFeedTitle => 'Neighborhood requests';

  @override
  String rideBroadcastActiveRadiusTooltip(int km) {
    return 'In \"Active\" tab we show requests within max $km km from your current location (when available).';
  }

  @override
  String get rideBroadcastTabActive => 'Active';

  @override
  String get rideBroadcastTabMapBubbles => 'Map bubbles';

  @override
  String get rideBroadcastTabMyHistory => 'My history';

  @override
  String get rideBroadcastVisibleOnlyForYouNoContacts =>
      'Request is visible only to you: no other Nabour users were found in your contacts with phone matching their profile.';

  @override
  String rideBroadcastVisibleForYouAndContacts(String people) {
    return 'Request is visible for you and for another $people from contacts.';
  }

  @override
  String get rideBroadcastEnableLocationForMapRequest =>
      'Enable location to place a map request.';

  @override
  String get rideBroadcastRequestRide => 'Request ride';

  @override
  String get rideBroadcastMapRequest => 'Map request';

  @override
  String rideBroadcastBubblesLoadFailed(String error) {
    return 'Could not load bubbles. Pull down to retry.\n$error';
  }

  @override
  String rideBroadcastNoBubbleInRadius(int km) {
    return 'No bubble within $km km radius';
  }

  @override
  String get rideBroadcastNoActiveBubbleHere => 'No active bubble here';

  @override
  String rideBroadcastBubblesOutsideRadiusHint(int km) {
    return 'There are active bubbles, but they are farther than $km km from your current location. Check map or refresh GPS (pull down).';
  }

  @override
  String get rideBroadcastBubblesVisibilityHint =>
      'Bubbles are visible on map for about one hour from posting, then disappear. Place one from map menu. If you just opened this screen, pull down to sync.';

  @override
  String get rideBroadcastNoPostedRequestYet => 'No request posted yet';

  @override
  String get rideBroadcastNoActiveRequest => 'No active request';

  @override
  String get rideBroadcastBeFirstHint =>
      'Be the first in your neighborhood to post a ride request.';

  @override
  String get rideBroadcastFriendPostedButNotVisibleHint =>
      'If a friend posted but you cannot see it: pull down to refresh, verify you have them in contacts with the same number as in Nabour profile, and contact permission is granted.';

  @override
  String rideBroadcastNoRequestInRadius(int km) {
    return 'No request within $km km radius';
  }

  @override
  String get rideBroadcastIncludedButFarHint =>
      'There are requests where you are included, but they are farther from your current location. Move closer or enable location for accurate filters.';

  @override
  String get rideBroadcastWaitingFriendHint =>
      'If you are waiting for a nearby friend, also verify contacts and Nabour profile with the same phone number.';

  @override
  String get rideBroadcastDeleteMapRequestTitle => 'Delete map request?';

  @override
  String get rideBroadcastDeleteMapRequestConfirm =>
      'The bubble will disappear for all neighbors; this action cannot be undone.';

  @override
  String get rideBroadcastMapBubbleDeleted => 'Map bubble deleted.';

  @override
  String rideBroadcastDeleteFailed(String error) {
    return 'Could not delete: $error';
  }

  @override
  String get rideBroadcastDeleteFromMapTooltip => 'Delete from map';

  @override
  String rideBroadcastPlaced(String value) {
    return 'Posted: $value';
  }

  @override
  String rideBroadcastExpiresMapBubble(String value) {
    return 'Expires: $value (~1 h after posting)';
  }

  @override
  String rideBroadcastDistanceFromYou(String km) {
    return 'About $km km from you';
  }

  @override
  String get rideBroadcastCancelRequestTitle => 'Cancel request';

  @override
  String get rideBroadcastCancelRequestConfirm =>
      'Are you sure you want to cancel this request?';

  @override
  String get rideBroadcastNo => 'No';

  @override
  String get rideBroadcastYesCancel => 'Yes, cancel';

  @override
  String get rideBroadcastPersonalCar => 'Personal car';

  @override
  String rideBroadcastOfferSendFailed(String error) {
    return 'Could not send offer: $error';
  }

  @override
  String rideBroadcastReplySendFailed(String error) {
    return 'Could not send reply: $error';
  }

  @override
  String get rideBroadcastDriverFallback => 'Driver';

  @override
  String get rideBroadcastConfirmRideTitle => 'Confirm ride';

  @override
  String get rideBroadcastRideCompletedQuestion => 'Was the ride completed?';

  @override
  String get rideBroadcastNotCompleted => 'Not completed';

  @override
  String get rideBroadcastCompletedYes => 'Yes, completed';

  @override
  String get rideBroadcastReasonDriverNoShow => 'Driver did not show up';

  @override
  String get rideBroadcastReasonPassengerCancelled => 'Passenger canceled';

  @override
  String get rideBroadcastReasonAnotherCar => 'Another car';

  @override
  String get rideBroadcastReasonOther => 'Other reason';

  @override
  String get rideBroadcastReasonTitle => 'Reason';

  @override
  String rideBroadcastExpiresIn(String value) {
    return 'Expires in $value';
  }

  @override
  String get rideBroadcastMyRequest => 'My request';

  @override
  String get rideBroadcastAvailableDrivers => 'Available drivers';

  @override
  String get rideBroadcastReplies => 'Replies';

  @override
  String get rideBroadcastReplyHint =>
      'You can send multiple messages - tap send for each';

  @override
  String rideBroadcastOffersOne(int count) {
    return '$count offer';
  }

  @override
  String rideBroadcastOffersMany(int count) {
    return '$count offers';
  }

  @override
  String get rideBroadcastOfferSent => 'Offer sent';

  @override
  String get rideBroadcastIOffer => 'I can offer';

  @override
  String get rideBroadcastStatusDone => '✅ Completed';

  @override
  String get rideBroadcastStatusNotDone => '❌ Not completed';

  @override
  String get rideBroadcastStatusAccepted => '🤝 Accepted';

  @override
  String get rideBroadcastStatusCancelled => '🚫 Cancelled';

  @override
  String get rideBroadcastStatusActive => '🕐 Active';

  @override
  String get rideBroadcastStatusExpired => '⏱ Expired';

  @override
  String rideBroadcastDriverWithName(String name) {
    return 'Driver: $name';
  }

  @override
  String rideBroadcastReasonWithValue(String value) {
    return 'Reason: $value';
  }

  @override
  String rideBroadcastTooManyActiveRequests(int max) {
    return 'You already have $max active requests. Close one or wait for expiration (30 min) before posting another.';
  }

  @override
  String rideBroadcastErrorWithMessage(String error) {
    return 'Error: $error';
  }

  @override
  String get rideBroadcastAskRideTitle => 'Request a ride';

  @override
  String get rideBroadcastPostVisibilityHint =>
      'Your request will be visible to people in your contacts for 30 minutes.';

  @override
  String get rideBroadcastQuickSelectOrWrite => 'Quick select or write';

  @override
  String get rideBroadcastYourMessageRequired => 'Your message *';

  @override
  String get rideBroadcastMessageHint =>
      'Where do you want to go? Any useful details...';

  @override
  String get rideBroadcastDestinationOptional => 'Destination (optional)';

  @override
  String get rideBroadcastDestinationHint => 'e.g. market, station, airport...';

  @override
  String get rideBroadcastPostRequest => 'Post request';

  @override
  String get rideBroadcastExpiresAfterThirtyMinutes =>
      'Request expires automatically after 30 minutes.';

  @override
  String get searchDriverFallback => 'Driver';

  @override
  String get searchDriverSearchingNearby => 'Searching for nearby drivers...';

  @override
  String get searchDriverFoundWaitConfirm =>
      'Driver found! Waiting for your confirmation.';

  @override
  String get searchDriverRideCancelled => 'The ride was cancelled.';

  @override
  String get searchDriverNoDriverAvailable => 'Sorry, no driver was available.';

  @override
  String searchDriverUnknownRideStatus(String status) {
    return 'Unknown ride status: $status';
  }

  @override
  String searchDriverConfirmError(String error) {
    return 'Error confirming driver: $error';
  }

  @override
  String get searchDriverDeclinedResuming =>
      'You declined the driver. Resuming search...';

  @override
  String searchDriverDeclineError(String error) {
    return 'Error declining driver: $error';
  }

  @override
  String searchDriverCancelError(String error) {
    return 'Error cancelling: $error';
  }

  @override
  String get searchDriverSearchingTitle => 'Searching drivers';

  @override
  String get searchDriverPremiumHintTitle => 'Premium Tip';

  @override
  String get searchDriverPremiumHintBody =>
      'Stay on this screen for a faster pickup.';

  @override
  String get searchDriverFoundTitle => 'Driver found';

  @override
  String get searchDriverArrivesIn => 'Arrives in';

  @override
  String get searchDriverDistanceLabel => 'Distance';

  @override
  String get searchDriverNabourDriverFallback => 'Nabour Driver';

  @override
  String get searchDriverStandardCategory => 'Standard Category';

  @override
  String get rideRequestStatusSearching => 'Searching drivers';

  @override
  String get rideRequestStatusPending => 'Pending';

  @override
  String get rideRequestStatusDriverFound => 'Driver found';

  @override
  String get rideRequestStatusAccepted => 'Accepted';

  @override
  String get rideRequestStatusDriverArrived => 'Driver arrived';

  @override
  String get rideRequestStatusInProgress => 'In progress';

  @override
  String get rideRequestStatusDriverRejected => 'Driver rejected';

  @override
  String get rideRequestStatusDriverDeclined => 'Driver declined';

  @override
  String get rideRequestTimeoutInternet =>
      'Waiting time expired. Please check your internet connection.';

  @override
  String rideRequestRouteCalcError(String error) {
    return 'Route calculation error: $error';
  }

  @override
  String get rideRequestActiveRideDetected => 'Active ride detected';

  @override
  String get rideRequestStatusLabel => 'Ride status';

  @override
  String get rideRequestIdLabel => 'Ride ID';

  @override
  String get rideRequestCancelPreviousRide => 'Cancel previous ride';

  @override
  String rideRequestCancelPreviousRideError(String error) {
    return 'Error cancelling previous ride: $error';
  }

  @override
  String rideRequestCreateRideError(String error) {
    return 'Error creating ride: $error';
  }

  @override
  String get rideRequestWhereTo => 'Where to?';

  @override
  String get rideRequestChooseRide => 'Choose a ride';

  @override
  String get rideRequestOrChooseCategory => 'or choose a category';

  @override
  String get rideRequestSearchInProgress => 'Searching...';

  @override
  String get rideRequestConfirmAndRequest => 'Confirm & Request Ride';

  @override
  String get rideRequestAnyCategoryAvailable => 'Any available category';

  @override
  String get rideRequestFastestDriverInArea =>
      'Fastest available driver in your area';

  @override
  String get rideRequestAnyCategorySubtitle => 'Fastest available driver.';

  @override
  String get rideRequestFamilySubtitle => 'Extra space for family and luggage.';

  @override
  String get rideRequestEnergySubtitle => 'Travel eco with an electric car.';

  @override
  String get rideRequestUtilitySubtitle =>
      'Van or utility (up to 3.5t). Ideal for moving.';

  @override
  String get rideRequestUserNotAuthenticated =>
      'Error: User is not authenticated.';

  @override
  String get mapArrivalInstruction => 'You arrived at destination!';

  @override
  String get mapArrivedTitle => 'You arrived!';

  @override
  String get mapFinalDestinationTitle => 'Final destination';

  @override
  String get mapOpenNavigationToDestinationHint =>
      'Open navigation app to destination. Then return to map.';

  @override
  String get mapPassengerStatusDriverFound =>
      'Driver found - waiting for your confirmation';

  @override
  String get mapPassengerStatusDriverOnWay => 'Driver is on the way to you';

  @override
  String get mapPassengerStatusDriverAtPickup =>
      'Driver at pickup - open navigation to destination';

  @override
  String get mapPassengerStatusInProgress => 'Ride in progress';

  @override
  String mapPassengerStatusGeneric(String status) {
    return 'Ride: $status';
  }

  @override
  String get mapNavigationToPickupTitle => 'Navigation to pickup';

  @override
  String get mapExternalNavigationNoRouteHint =>
      'Navigation app (no in-app route in Nabour).';

  @override
  String get mapOpenSameDestinationAsDriver =>
      'Open the same destination as the driver in your navigation app.';

  @override
  String get mapLongPressToSetLandmark => 'Long press on map to set landmark.';

  @override
  String get mapCloseCancelPlacement => 'Close (cancel placement)';

  @override
  String get mapCommunityMysteryBoxTitle => 'Community Mystery Box';

  @override
  String mapCommunityMysteryBoxDescription(int tokens) {
    return 'You place a box at current location. Cost: $tokens tokens. First user opening it on site receives the same tokens - you will be notified when this happens.';
  }

  @override
  String get mapShortMessageOptional => 'Short message (optional)';

  @override
  String get mapShortMessageHint => 'e.g. Top bonus - have fun!';

  @override
  String get mapPhoneNumberUnavailable => 'Phone number unavailable';

  @override
  String get neighborFallback => 'Neighbor';

  @override
  String mapReactionSent(String reaction) {
    return 'Reaction sent: $reaction';
  }

  @override
  String mapHonkedNeighbor(String name) {
    return 'You honked at $name!';
  }

  @override
  String mapEtaMessageToNeighbor(int minutes) {
    return '📍 I am heading your way! Estimated ETA: $minutes min.';
  }

  @override
  String mapEtaSentTo(String name) {
    return 'ETA sent to $name';
  }

  @override
  String mapNeighborhoodBubbleContext(String name) {
    return 'The bubble appears near $name on the map. Visible to neighbors for ~1 hour.';
  }

  @override
  String mapEmojiPlacedNear(String name) {
    return 'Emoji placed near $name on the map';
  }

  @override
  String get mapCannotPlaceEmoji => 'Could not place emoji on the map';

  @override
  String get mapPersonNotVisibleSendFromList =>
      'This person is not visible on the map now. You can send a friend request from the list (+).';

  @override
  String get mapContactsVisibilityHint =>
      'On the map you only see accepted friends or phone contacts who have a Nabour account. Add numbers to contacts or accept a request from Suggestions.';

  @override
  String get mapSyncingContacts => 'Syncing contacts...';

  @override
  String mapSyncComplete(int count) {
    return 'Sync complete: $count names found.';
  }

  @override
  String get mapEnableDriverProfileHint =>
      'Enable driver profile and add your car to use driver mode.';

  @override
  String mapIntermediateStopAdded(String name) {
    return '$name added as an intermediate stop';
  }

  @override
  String mapStopRemoved(String name) {
    return '$name removed from stops';
  }

  @override
  String mapNoPoiFoundInArea(String category) {
    return 'No $category found in the area';
  }

  @override
  String mapHonkReceived(String name) {
    return '📣 $name honked at you!';
  }

  @override
  String get mapCalculatingRoute => 'Calculating route...';

  @override
  String get mapCannotGetLocationEnableGps =>
      'Could not get location. Enable GPS.';

  @override
  String get mapRouteUnavailableCheckConnection =>
      'Route unavailable. Check connection.';

  @override
  String get mapContinueOnRoute => 'Continue on route.';

  @override
  String get mapAneighbor => 'A neighbor';

  @override
  String mapSosNearbyTitle(String name) {
    return '🆘 NEARBY SOS: $name';
  }

  @override
  String get mapSosNearbyBody => 'Active emergency nearby! Check radar on map.';

  @override
  String mapSosTtsAlert(String name) {
    return 'Attention! S.O.S. alert nearby from $name. Proximity radar is now active.';
  }

  @override
  String get mapCriticalZone => 'CRITICAL ZONE';

  @override
  String get mapSosActiveTitle => '🆘 S.O.S. ACTIVE';

  @override
  String get mapNoContactsInRadarCircle =>
      'None of your contacts with location in this area are inside the scan circle right now.';

  @override
  String get mapStopNavigationFirst =>
      'Stop navigation first from the top banner.';

  @override
  String get mapWaitingGpsTryAgain =>
      'Waiting for GPS position. Try again in a few seconds.';

  @override
  String get mapGpsLocationUnavailableYet =>
      'GPS location is not available yet';

  @override
  String mapSetPickupError(String error) {
    return 'Error setting pickup: $error';
  }

  @override
  String mapSetDestinationError(String error) {
    return 'Error setting destination: $error';
  }

  @override
  String mapMaxIntermediateStops(int count) {
    return 'Maximum $count intermediate stops allowed';
  }

  @override
  String get mapStopAlreadyAdded => 'This stop is already added';

  @override
  String mapAddStopError(String error) {
    return 'Error adding stop: $error';
  }

  @override
  String mapRouteCalculationError(String error) {
    return 'Route calculation error: $error';
  }

  @override
  String mapRouteSetupError(String error) {
    return 'Route setup error: $error';
  }

  @override
  String get mapCouldNotCalculateRoute => 'Could not calculate route';

  @override
  String get mapFlashlightUnavailable =>
      'Flashlight is not available on this device';

  @override
  String get mapFlashlightActivationError => 'Error activating flashlight';

  @override
  String get mapSpotAnnouncedAvailable =>
      'Spot has been announced as available.';

  @override
  String get mapCouldNotAnnounceTryAgain =>
      'Could not announce. Please try again.';

  @override
  String get mapSelectionCancelled => 'Map selection was canceled.';

  @override
  String mapNeighborNearbyTitle(String avatar, String name) {
    return '$avatar $name is nearby!';
  }

  @override
  String mapNeighborNearbyBody(int meters) {
    return 'At $meters m - social map 📍';
  }

  @override
  String mapPickupIndex(int index) {
    return 'Pickup $index';
  }

  @override
  String get mapPickupPointSelected => 'Pickup point selected';

  @override
  String get helpChatGuideTitle => 'Neighborhood Chat usage guide';

  @override
  String get helpChatGuideIntro =>
      'The neighborhood chat is designed to instantly connect you with neighbors in your vicinity.';

  @override
  String get helpChatWhoSeesTitle => 'Who sees the messages?';

  @override
  String get helpChatWhoSeesBody =>
      'Sent messages are visible to all users who are in the same geographic area as you at the time of use.';

  @override
  String get helpChatCoverageTitle => 'Radius and Coverage Area';

  @override
  String get helpChatCoverageBody =>
      'The system divides the city into hexagons with a side of approximately 3.2 km (an area of about 36 km²). It\'s a vast area, ideal to cover an entire neighborhood or a sector.';

  @override
  String get helpChatPersistenceTitle => 'Message persistence';

  @override
  String get helpChatPersistenceBody =>
      'To keep conversations fresh and relevant, messages disappear automatically after 30 minutes. There is no permanent history, the chat being intended for immediate interactions.';

  @override
  String get helpChatPrivacyTitle => 'Privacy and Safety';

  @override
  String get helpChatPrivacyBody =>
      'Chat access is validated based on your current GPS location. If you move to another part of the city, the app will automatically connect you to the specific chat for that area.';

  @override
  String get helpChatTipOMW =>
      'Tip: Use the OMW button to quickly announce to neighbors that you are on your way to them or available in the area.';

  @override
  String get helpLassoTitle => 'Lasso Tool (Magic Wand)';

  @override
  String get helpLassoBody =>
      'The Lasso tool allows you to select multiple neighbors on the map by drawing a circle around them.';

  @override
  String get helpLassoHowToTitle => 'How to use it?';

  @override
  String get helpLassoHowToBody =>
      '1. Tap the \"Magic Wand\" icon in the top right of the map.\n2. Draw a circle around the neighbors you want to contact.\n3. A menu will appear showing the captured group and options to send a broadcast request.';

  @override
  String get helpLassoTip =>
      'Tip: Use Lasso to quickly find a neighbor team for a common activity or a shared ride request!';

  @override
  String get helpRadarTitle => 'Scan button (neighbor radar)';

  @override
  String get helpRadarBody =>
      'The Scan button runs the radar overlay for about 5 seconds, then closes automatically. During this time you cannot resize the circle.';

  @override
  String get helpRadarWhatTitle => 'What does it scan?';

  @override
  String get helpRadarWhatBody =>
      'It does not scan Bluetooth, Wi‑Fi, or new devices. It lists neighbors who are already shown on the map and whose position falls inside your radar circle (distance is computed from the circle center and radius).';

  @override
  String get helpRadarResultsTitle => 'Where do results appear?';

  @override
  String get helpRadarResultsBody =>
      'If at least one neighbor is in the circle, a bottom sheet opens with the list. If there is no one, you will see a short message that no neighbors were found in the radar.';

  @override
  String get helpRadarNextTitle => 'What can you do next?';

  @override
  String get helpRadarNextBody =>
      'From the sheet you can use the group action (e.g. broadcast request) when that feature is fully enabled; until then the app may show a notice that it is being rolled out.';

  @override
  String get helpRadarTip =>
      'Tip: Move or resize the circle before tapping Scan so it covers the area you care about—only neighbors already visible on the map can appear in the results.';

  @override
  String get helpMapDropsTitle => 'Interactive Map Drops';

  @override
  String get helpMapDropsBody =>
      'Map Drops are special location markers shared in the neighborhood chat that let you travel through the map instantly.';

  @override
  String get helpMapDropsFlyTitle => 'The \"FlyTo\" Animation';

  @override
  String get helpMapDropsFlyBody =>
      'When a neighbor shares a location, tap on the interactive card in the chat. The app will close the chat and perform a cinematic flight directly to that exact spot on the map.';

  @override
  String get helpMapDropsPinsTitle => 'Transient Pins';

  @override
  String get helpMapDropsPinsBody =>
      'After the flight, you will see a pulsing pin on the map. This helps you identify exactly where the \"drop\" was made, providing precise visual context for the neighbor\'s message.';

  @override
  String get helpBoxesPurposeTitle => 'Purpose';

  @override
  String get helpBoxesPurposeBody =>
      'On the map you can use two related features tied to Nabour tokens: (1) boxes at business offers — the merchant can set an optional limit; you open them near the store and get tokens plus a discount code for the shop. (2) Community boxes — any user can place a box at their current location; someone else opens it on the spot and gets tokens; the placer is notified when it is opened.';

  @override
  String get helpBoxesTokensTitle => 'Tokens — how they move';

  @override
  String get helpBoxesTokensBody =>
      '• Placing a community box: 50 tokens are reserved via the server (stake) and recorded in your wallet history.\n• Opening a community box (as another user, within about 100 m): you receive 50 tokens; the box is marked as opened.\n• Opening a business-offer box: you receive 50 tokens and a discount code, subject to daily-per-store rules and any cap the merchant set.\n• Amounts may follow app settings; if server policy blocks crediting until payments are enabled, opening may fail with that message.';

  @override
  String get helpBoxesCommunityStepsTitle => 'Community boxes — user flow';

  @override
  String get helpBoxesCommunityStepsBody =>
      '1) From the map, place a box at your current position (you need enough tokens). Up to 20 active boxes per account.\n2) Nearby users see community boxes on the map; your own boxes are not shown to you as boxes to open.\n3) Tap a box, get close (~100 m), confirm — the server checks distance and identity.\n4) The placer receives an in-app notification entry and a push when someone opens their box.\n5) Under Menu → “Box activity” you can see summaries, your placed boxes, your opens, and opens of your boxes.';

  @override
  String get helpBoxesBusinessStepsTitle =>
      'Business-offer boxes — user & merchant flow';

  @override
  String get helpBoxesBusinessStepsBody =>
      'The merchant publishes an offer and may attach a mystery-box cap (extra token cost when creating or increasing the cap). You open the box from the map near the location; you get tokens and a redemption code. At the store, the merchant opens the business panel and uses “Validate box code” so the code is marked used. Codes are stored securely; only cloud functions create or validate them.';

  @override
  String get helpBoxesActivityScreenTitle => 'Activity screen (menu)';

  @override
  String get helpBoxesActivityScreenBody =>
      'Tabs: Summary (estimated tokens from opens and stake from placements), Placed community boxes, Your opens (community + business log), Notifications when others open your community boxes. Redemption codes are shown masked for safety.';

  @override
  String get helpBoxesPrivacyRulesTitle => 'Privacy & rules';

  @override
  String get helpBoxesPrivacyRulesBody =>
      'Sensitive collections (redemption codes, box writes) are handled on the server. Firestore rules prevent clients from forging opens or codes; reads follow authentication rules.';

  @override
  String get helpBoxesWhoTitle => 'Who does what';

  @override
  String get helpBoxesWhoBody =>
      '• Any user: browse the map, place community boxes if they have tokens, open community or business boxes when conditions are met, review “Box activity”.\n• Placer: gets notified when a community box is opened.\n• Merchant: configures offers and caps, validates discount codes after a customer opens a box.';

  @override
  String get helpBoxesNotesTitle => 'Notes';

  @override
  String get helpBoxesNotesBody =>
      'Listing many boxes around you is optimized for moderate scale; very large usage may need stronger geo indexing later. Automatic refund or expiry of community stakes if nobody opens a box is not described here and may be added later.';

  @override
  String get helpBoxesTip =>
      'Tip: If opening fails, check GPS accuracy, internet, wallet balance, and whether credits are enabled on the server for your environment.';

  @override
  String get helpTransfersP2PTitle => 'Token transfers between users';

  @override
  String get helpTransfersP2PAboutTitle => 'What it is';

  @override
  String get helpTransfersP2PAboutBody =>
      'From the side menu, open “Token transfer” to move Nabour tokens to another account or to ask someone to send you tokens. Balances and ledger entries are updated on the server; you need the other person’s user ID (Firebase UID).';

  @override
  String get helpTransfersP2PWalletTitle => 'Transferable wallet';

  @override
  String get helpTransfersP2PWalletBody =>
      'This screen shows the transferable token balance (not the same view as the monthly usage bar at the top of the menu). If the wallet is frozen or missing, transfers and requests will be blocked until the account is eligible.';

  @override
  String get helpTransfersP2PDirectTitle => 'Direct transfer';

  @override
  String get helpTransfersP2PDirectBody =>
      'You send tokens immediately to the recipient’s user ID. You cannot transfer to yourself. Amounts must be a whole number of tokens within the allowed range. An optional note can be attached.';

  @override
  String get helpTransfersP2PRequestTitle => 'Payment request';

  @override
  String get helpTransfersP2PRequestBody =>
      'You ask another user (the payer) to send you tokens. They receive a pending request and can accept or decline. If they accept, tokens move from their transferable wallet to yours. Requests expire after a limited time if not answered.';

  @override
  String get helpTransfersP2PRequestsTabTitle => 'Requests tab';

  @override
  String get helpTransfersP2PRequestsTabBody =>
      '• As payer: you can accept or decline incoming requests; you may add an optional reason when declining.\n• As requester: you can cancel a request you created while it is still pending.';

  @override
  String get helpTransfersP2PHistoryTabTitle => 'History tab';

  @override
  String get helpTransfersP2PHistoryTabBody =>
      'Shows recent direct transfers and resolved payment requests. Pull down to refresh.';

  @override
  String get helpTransfersP2PTip =>
      'Only share your user ID with people you trust. Double-check the ID before confirming a transfer or request.';

  @override
  String get helpDriverActivationStepCheckConditions => '1. Check conditions';

  @override
  String get helpDriverActivationStepCheckConditionsBody =>
      'You must have a valid driver\'s license, at least 2 years of experience, and be at least 21 years old.';

  @override
  String get helpDriverActivationStepPrepareDocs => '2. Prepare documents';

  @override
  String get helpDriverActivationStepPrepareDocsBody =>
      'You need: driver\'s license, ID card, vehicle registration certificate, valid ITP, and RCA insurance.';

  @override
  String get helpDriverActivationStepCompleteApp => '3. Complete application';

  @override
  String get helpDriverActivationStepCompleteAppBody =>
      'Access the \'Career\' section in the main menu and complete the online form with your details.';

  @override
  String get helpDriverActivationStepSubmitDocs => '4. Submit documents';

  @override
  String get helpDriverActivationStepSubmitDocsBody =>
      'Upload clear photos of all required documents through the online platform.';

  @override
  String get helpDriverActivationStepVerification =>
      '5. Application verification';

  @override
  String get helpDriverActivationStepVerificationBody =>
      'Our team will verify the documents within 48 business hours.';

  @override
  String get helpDriverActivationStepReceiveCode =>
      '6. Receive activation code';

  @override
  String get helpDriverActivationStepReceiveCodeBody =>
      'After approval, you will receive a unique code via email/SMS to activate the driver account.';

  @override
  String get helpDriverActivationStepActivateAccount => '7. Activate account';

  @override
  String get helpDriverActivationStepActivateAccountBody =>
      'Enter the code in the app and start earning money by driving!';

  @override
  String get helpDriverActivationTipHeader => '💡 Useful tip:';

  @override
  String get helpDriverActivationTipBody =>
      'Ensure all documents are valid and photos are clear for fast processing.';

  @override
  String get helpSearchHint => 'Search help articles...';

  @override
  String get helpCategoryRideIssues => 'Ride Issues';

  @override
  String get helpCategorySafetySOS => 'Safety & SOS';

  @override
  String get helpCategoryNabourFeatures => 'Nabour Features';

  @override
  String get helpCategoryPaymentsWallet => 'Payments & Wallet';

  @override
  String get helpCategorySettingsAccount => 'Settings & Account';

  @override
  String get helpStillNeedHelp => 'Still need help?';

  @override
  String get helpContactSupport => 'Contact our support team';

  @override
  String get helpContactButton => 'Contact';

  @override
  String get helpRideSharingTitle => 'Ride Sharing';

  @override
  String get chatGalleryPhoto => 'Gallery Photo';

  @override
  String get chatGif => 'GIF';

  @override
  String get driverHoursLimit => 'Driving hours limit';

  @override
  String driverHoursWarningBody(String hours, String remaining) {
    return 'You have driven $hours hours today.\nYou have $remaining hours left.\n\nConsider taking a break for your safety and the passengers\'.';
  }

  @override
  String get goOffline => 'Go Offline';

  @override
  String get driverHoursReachedLimitTitle => '10 hours limit reached';

  @override
  String get driverHoursReachedLimitBody =>
      'You have driven 10 consecutive hours.\nFor safety reasons, you have been automatically disconnected.\n\nYou can reconnect after a rest period.';

  @override
  String ridesCompletedToday(int count) {
    return '$count rides completed today.';
  }

  @override
  String viewAllRides(int count) {
    return 'View all $count rides';
  }

  @override
  String get driverSessionBannerCritical =>
      '10 hours limit reached. Please go offline.';

  @override
  String driverSessionBannerWarning(String hours, String remaining) {
    return 'Session: ${hours}h • Remaining ${remaining}h';
  }

  @override
  String driverSessionBannerNormal(String hours) {
    return 'Session: ${hours}h';
  }

  @override
  String get helpToday => 'Help Today';

  @override
  String get tokens => 'Tokens';

  @override
  String get rideSummary_thankYouGoodbye => 'Thank you and goodbye!';

  @override
  String rideSummary_tipRegistered(String amount, String currency) {
    return 'A tip of $amount $currency has been recorded.';
  }

  @override
  String rideSummary_redirectToMapInSeconds(String seconds) {
    return 'Redirecting to map in $seconds seconds...';
  }

  @override
  String get rideSummary_submitRatingButton => 'Submit Rating';

  @override
  String get rideSummary_skipRatingButton => 'Skip Rating';

  @override
  String get rideSummary_ratingSentSuccess => 'Rating sent successfully!';

  @override
  String get rideSummary_backToMap => 'Back to Map';

  @override
  String get rideSummary_rideDetails => 'Ride Details';

  @override
  String get rideSummary_distance => 'Distance';

  @override
  String get rideSummary_duration => 'Duration';

  @override
  String get rideSummary_rideCost => 'Ride Cost';

  @override
  String get rideSummary_freeRideSupport => 'Free - Neighbors Support';

  @override
  String get rideSummary_driverTipOptional => '💰 Driver Tip (optional)';

  @override
  String get rideSummary_thankDriverTipText =>
      'Thank the driver for a pleasant trip!';

  @override
  String rideSummary_otherAmountLabel(String currency) {
    return 'Other amount ($currency)';
  }

  @override
  String get rideSummary_noTipButton => 'No tip';

  @override
  String rideSummary_tipSelected(String amount, String currency) {
    return 'Tip selected: $amount $currency';
  }

  @override
  String get safety_sosButtonLabel => '112 — SOS';

  @override
  String get safety_locationUnavailable => '(location unavailable)';

  @override
  String get safety_defaultNabourUser => 'Nabour User';

  @override
  String safety_emergencySmsBody(String name, String location) {
    return '🆘 EMERGENCY! $name needs help!\nLocation: $location\nClick to see on map.';
  }

  @override
  String get safety_emergencyAlertSent =>
      '🆘 Emergency alert sent. Calling 112...';

  @override
  String safety_shareTripBody(String location) {
    return '📍 Tracking my Nabour trip!\nCurrent location: $location';
  }

  @override
  String get safety_shareTripNoLocation =>
      '🚗 I\'m riding with Nabour. Location unavailable at the moment.';

  @override
  String get safety_couldNotCreateTrackingLink =>
      'Could not create tracking link';

  @override
  String get safety_deleteContactTitle => 'Delete contact';

  @override
  String safety_deleteContactConfirmation(String name) {
    return 'Delete $name from trusted contacts?';
  }

  @override
  String get safety_emergencyButtonTitle => 'Emergency Button';

  @override
  String get safety_emergencyButtonSubtitle =>
      'Call 112 and send your location\nto all trusted contacts';

  @override
  String get safety_shareTripTitle => 'Share Trip';

  @override
  String get safety_activeRideDetected => 'Active ride detected';

  @override
  String get safety_sendCurrentLocation => 'Send current location';

  @override
  String get safety_gettingLocation => 'Getting location...';

  @override
  String get safety_shareLocationButton => 'Share location';

  @override
  String get safety_liveLinkActive => 'Live link active — re-share';

  @override
  String get safety_safeRideSharePath => 'Safe Ride Live — share path';

  @override
  String get safety_noContactsAdded => 'No contacts added';

  @override
  String get safety_addContactsDescription =>
      'Add family or friends. They will receive\nyour location in case of emergency.';

  @override
  String get rideSummary_totalCost => 'Total Cost';

  @override
  String safety_destinationLabelPrefix(String destination) {
    return 'Destination: $destination';
  }
}

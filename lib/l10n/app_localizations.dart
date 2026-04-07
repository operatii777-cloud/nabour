import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ro.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ro')
  ];

  /// No description provided for @appTitle.
  ///
  /// In ro, this message translates to:
  /// **'Nabour'**
  String get appTitle;

  /// No description provided for @driverMode.
  ///
  /// In ro, this message translates to:
  /// **'Mod Șofer'**
  String get driverMode;

  /// No description provided for @passengerMode.
  ///
  /// In ro, this message translates to:
  /// **'Mod Pasager'**
  String get passengerMode;

  /// No description provided for @requestRide.
  ///
  /// In ro, this message translates to:
  /// **'Solicită Cursă'**
  String get requestRide;

  /// No description provided for @acceptRide.
  ///
  /// In ro, this message translates to:
  /// **'Acceptă'**
  String get acceptRide;

  /// No description provided for @declineRide.
  ///
  /// In ro, this message translates to:
  /// **'Refuză'**
  String get declineRide;

  /// No description provided for @cancelRide.
  ///
  /// In ro, this message translates to:
  /// **'Anulează Cursa'**
  String get cancelRide;

  /// No description provided for @myLocation.
  ///
  /// In ro, this message translates to:
  /// **'Locația mea'**
  String get myLocation;

  /// No description provided for @offline.
  ///
  /// In ro, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @online.
  ///
  /// In ro, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @available.
  ///
  /// In ro, this message translates to:
  /// **'Disponibil'**
  String get available;

  /// No description provided for @unavailable.
  ///
  /// In ro, this message translates to:
  /// **'Indisponibil'**
  String get unavailable;

  /// No description provided for @activeRide.
  ///
  /// In ro, this message translates to:
  /// **'Cursă Activă'**
  String get activeRide;

  /// No description provided for @rideHistory.
  ///
  /// In ro, this message translates to:
  /// **'Istoric Curse'**
  String get rideHistory;

  /// No description provided for @profile.
  ///
  /// In ro, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In ro, this message translates to:
  /// **'Setări'**
  String get settings;

  /// No description provided for @startNavigation.
  ///
  /// In ro, this message translates to:
  /// **'Navigarea a început'**
  String get startNavigation;

  /// No description provided for @navigationEnded.
  ///
  /// In ro, this message translates to:
  /// **'Navigarea s-a încheiat'**
  String get navigationEnded;

  /// No description provided for @arrived.
  ///
  /// In ro, this message translates to:
  /// **'Ați ajuns la destinație'**
  String get arrived;

  /// No description provided for @routeDeviation.
  ///
  /// In ro, this message translates to:
  /// **'Recalculez traseul'**
  String get routeDeviation;

  /// No description provided for @preparingRoute.
  ///
  /// In ro, this message translates to:
  /// **'Pregătesc traseul'**
  String get preparingRoute;

  /// No description provided for @turnLeft.
  ///
  /// In ro, this message translates to:
  /// **'Virați la stânga peste {distance}'**
  String turnLeft(String distance);

  /// No description provided for @turnRight.
  ///
  /// In ro, this message translates to:
  /// **'Virați la dreapta peste {distance}'**
  String turnRight(String distance);

  /// No description provided for @turnSlightLeft.
  ///
  /// In ro, this message translates to:
  /// **'Virați ușor la stânga peste {distance}'**
  String turnSlightLeft(String distance);

  /// No description provided for @turnSlightRight.
  ///
  /// In ro, this message translates to:
  /// **'Virați ușor la dreapta peste {distance}'**
  String turnSlightRight(String distance);

  /// No description provided for @continueForward.
  ///
  /// In ro, this message translates to:
  /// **'Continuați înainte pentru {distance}'**
  String continueForward(String distance);

  /// No description provided for @makeUturn.
  ///
  /// In ro, this message translates to:
  /// **'Faceți întoarcere peste {distance}'**
  String makeUturn(String distance);

  /// No description provided for @meters.
  ///
  /// In ro, this message translates to:
  /// **'metri'**
  String get meters;

  /// No description provided for @kilometers.
  ///
  /// In ro, this message translates to:
  /// **'kilometri'**
  String get kilometers;

  /// No description provided for @meter.
  ///
  /// In ro, this message translates to:
  /// **'metru'**
  String get meter;

  /// No description provided for @kilometer.
  ///
  /// In ro, this message translates to:
  /// **'kilometru'**
  String get kilometer;

  /// No description provided for @driverHeadingToYou.
  ///
  /// In ro, this message translates to:
  /// **'Șoferul este pe drum...'**
  String get driverHeadingToYou;

  /// No description provided for @driverArrived.
  ///
  /// In ro, this message translates to:
  /// **'Șoferul a sosit!'**
  String get driverArrived;

  /// No description provided for @rideInProgress.
  ///
  /// In ro, this message translates to:
  /// **'Cursă în desfășurare'**
  String get rideInProgress;

  /// No description provided for @confirmDriver.
  ///
  /// In ro, this message translates to:
  /// **'Confirmă Șoferul'**
  String get confirmDriver;

  /// No description provided for @confirmButton.
  ///
  /// In ro, this message translates to:
  /// **'Confirmă'**
  String get confirmButton;

  /// No description provided for @declineButton.
  ///
  /// In ro, this message translates to:
  /// **'Refuză'**
  String get declineButton;

  /// No description provided for @iArrived.
  ///
  /// In ro, this message translates to:
  /// **'Am ajuns'**
  String get iArrived;

  /// No description provided for @startRide.
  ///
  /// In ro, this message translates to:
  /// **'Pornește cursa'**
  String get startRide;

  /// No description provided for @endRide.
  ///
  /// In ro, this message translates to:
  /// **'Termină Cursa'**
  String get endRide;

  /// No description provided for @waitingForPassenger.
  ///
  /// In ro, this message translates to:
  /// **'Așteaptă pasagerul.'**
  String get waitingForPassenger;

  /// No description provided for @headingToPassenger.
  ///
  /// In ro, this message translates to:
  /// **'Mergi spre pasager.'**
  String get headingToPassenger;

  /// No description provided for @communicateWithDriver.
  ///
  /// In ro, this message translates to:
  /// **'Comunică cu șoferul:'**
  String get communicateWithDriver;

  /// No description provided for @call.
  ///
  /// In ro, this message translates to:
  /// **'Sună'**
  String get call;

  /// No description provided for @message.
  ///
  /// In ro, this message translates to:
  /// **'Mesaj'**
  String get message;

  /// No description provided for @chat.
  ///
  /// In ro, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @writeMessage.
  ///
  /// In ro, this message translates to:
  /// **'Scrie un mesaj...'**
  String get writeMessage;

  /// No description provided for @send.
  ///
  /// In ro, this message translates to:
  /// **'Trimite'**
  String get send;

  /// No description provided for @emergency.
  ///
  /// In ro, this message translates to:
  /// **'Urgență'**
  String get emergency;

  /// No description provided for @navigationTo.
  ///
  /// In ro, this message translates to:
  /// **'Navighează spre'**
  String get navigationTo;

  /// No description provided for @navigation.
  ///
  /// In ro, this message translates to:
  /// **'Navigație'**
  String get navigation;

  /// No description provided for @chooseNavigationApp.
  ///
  /// In ro, this message translates to:
  /// **'Alege aplicația de navigație'**
  String get chooseNavigationApp;

  /// No description provided for @googleMaps.
  ///
  /// In ro, this message translates to:
  /// **'Google Maps'**
  String get googleMaps;

  /// No description provided for @waze.
  ///
  /// In ro, this message translates to:
  /// **'Waze'**
  String get waze;

  /// No description provided for @locationNotAvailable.
  ///
  /// In ro, this message translates to:
  /// **'Locația nu este încă disponibilă pentru partajare.'**
  String get locationNotAvailable;

  /// No description provided for @shareLocation.
  ///
  /// In ro, this message translates to:
  /// **'Partajează Locația'**
  String get shareLocation;

  /// No description provided for @navigateToPassenger.
  ///
  /// In ro, this message translates to:
  /// **'Navighează spre pasager'**
  String get navigateToPassenger;

  /// No description provided for @navigateToDestination.
  ///
  /// In ro, this message translates to:
  /// **'Navighează spre destinație'**
  String get navigateToDestination;

  /// No description provided for @rideCompleted.
  ///
  /// In ro, this message translates to:
  /// **'Cursă finalizată'**
  String get rideCompleted;

  /// No description provided for @rideCancelled.
  ///
  /// In ro, this message translates to:
  /// **'Cursă anulată'**
  String get rideCancelled;

  /// No description provided for @rideExpired.
  ///
  /// In ro, this message translates to:
  /// **'Cursă expirată'**
  String get rideExpired;

  /// No description provided for @offlineDriverMessage.
  ///
  /// In ro, this message translates to:
  /// **'Ești indisponibil ca șofer. Activează comutatorul pentru a primi curse sau solicită o cursă ca pasager.'**
  String get offlineDriverMessage;

  /// No description provided for @noPendingRides.
  ///
  /// In ro, this message translates to:
  /// **'Nicio cerere de cursă disponibilă momentan.'**
  String get noPendingRides;

  /// No description provided for @rideToDestination.
  ///
  /// In ro, this message translates to:
  /// **'Către: {destination}'**
  String rideToDestination(String destination);

  /// No description provided for @cost.
  ///
  /// In ro, this message translates to:
  /// **'Serviciu'**
  String get cost;

  /// No description provided for @distance.
  ///
  /// In ro, this message translates to:
  /// **'Distanță ({km} km):'**
  String distance(String km);

  /// No description provided for @ron.
  ///
  /// In ro, this message translates to:
  /// **'Puncte'**
  String get ron;

  /// No description provided for @km.
  ///
  /// In ro, this message translates to:
  /// **'km'**
  String get km;

  /// No description provided for @language.
  ///
  /// In ro, this message translates to:
  /// **'Limba'**
  String get language;

  /// No description provided for @romanian.
  ///
  /// In ro, this message translates to:
  /// **'Română'**
  String get romanian;

  /// No description provided for @english.
  ///
  /// In ro, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @errorInitializingRide.
  ///
  /// In ro, this message translates to:
  /// **'Eroare la inițializarea cursei'**
  String get errorInitializingRide;

  /// No description provided for @errorMonitoringRide.
  ///
  /// In ro, this message translates to:
  /// **'Eroare la monitorizarea cursei'**
  String get errorMonitoringRide;

  /// No description provided for @cannotOpenNavigation.
  ///
  /// In ro, this message translates to:
  /// **'Nu s-a putut deschide nicio aplicație de navigație.'**
  String get cannotOpenNavigation;

  /// No description provided for @cannotMakeCall.
  ///
  /// In ro, this message translates to:
  /// **'Nu s-a putut iniția apelul.'**
  String get cannotMakeCall;

  /// No description provided for @joinTeamTitle.
  ///
  /// In ro, this message translates to:
  /// **'Alătură-te echipei Nabour!'**
  String get joinTeamTitle;

  /// No description provided for @joinTeamDescription.
  ///
  /// In ro, this message translates to:
  /// **'Devino șofer partener. Află mai multe aici.'**
  String get joinTeamDescription;

  /// No description provided for @youHaveActiveRide.
  ///
  /// In ro, this message translates to:
  /// **'Ai o cursă activă. Atinge pentru a vedea detaliile.'**
  String get youHaveActiveRide;

  /// No description provided for @categoryStandardSubtitle.
  ///
  /// In ro, this message translates to:
  /// **'Cea mai accesibilă opțiune pentru călătoriile tale.'**
  String get categoryStandardSubtitle;

  /// No description provided for @categoryFamilySubtitle.
  ///
  /// In ro, this message translates to:
  /// **'Mai mult spațiu pentru pasageri și bagaje.'**
  String get categoryFamilySubtitle;

  /// No description provided for @categoryEnergySubtitle.
  ///
  /// In ro, this message translates to:
  /// **'Călătorește eco-friendly cu vehicule electrice sau hibride.'**
  String get categoryEnergySubtitle;

  /// No description provided for @categoryBestSubtitle.
  ///
  /// In ro, this message translates to:
  /// **'Experiență premium cu vehicule de lux și șoferi de top.'**
  String get categoryBestSubtitle;

  /// No description provided for @aiAssistant.
  ///
  /// In ro, this message translates to:
  /// **'Asistent AI'**
  String get aiAssistant;

  /// No description provided for @voiceSettings.
  ///
  /// In ro, this message translates to:
  /// **'Setări Vocale'**
  String get voiceSettings;

  /// No description provided for @voiceDemo.
  ///
  /// In ro, this message translates to:
  /// **'Demo Voce AI'**
  String get voiceDemo;

  /// No description provided for @microphoneTest.
  ///
  /// In ro, this message translates to:
  /// **'Test Microfon'**
  String get microphoneTest;

  /// No description provided for @aiLibraryTest.
  ///
  /// In ro, this message translates to:
  /// **'Test Biblioteca AI'**
  String get aiLibraryTest;

  /// No description provided for @receipts.
  ///
  /// In ro, this message translates to:
  /// **'Activitate'**
  String get receipts;

  /// No description provided for @driverDashboard.
  ///
  /// In ro, this message translates to:
  /// **'Panou de Bord Nabour'**
  String get driverDashboard;

  /// No description provided for @subscriptions.
  ///
  /// In ro, this message translates to:
  /// **'Abonamente'**
  String get subscriptions;

  /// No description provided for @safety.
  ///
  /// In ro, this message translates to:
  /// **'Siguranță'**
  String get safety;

  /// No description provided for @help.
  ///
  /// In ro, this message translates to:
  /// **'Ajutor'**
  String get help;

  /// No description provided for @aiVoiceSettings.
  ///
  /// In ro, this message translates to:
  /// **'🎤 Setări Vocale AI'**
  String get aiVoiceSettings;

  /// No description provided for @voiceAIDemo.
  ///
  /// In ro, this message translates to:
  /// **'🗣️ Demo Voice AI'**
  String get voiceAIDemo;

  /// No description provided for @microphoneTestTool.
  ///
  /// In ro, this message translates to:
  /// **'🔧 Test Microfon'**
  String get microphoneTestTool;

  /// No description provided for @aiLibraryTestTool.
  ///
  /// In ro, this message translates to:
  /// **'🧠 Test Biblioteca AI'**
  String get aiLibraryTestTool;

  /// No description provided for @about.
  ///
  /// In ro, this message translates to:
  /// **'Despre'**
  String get about;

  /// No description provided for @legal.
  ///
  /// In ro, this message translates to:
  /// **'Juridic'**
  String get legal;

  /// No description provided for @logout.
  ///
  /// In ro, this message translates to:
  /// **'DECONECTARE'**
  String get logout;

  /// No description provided for @aboutNabour.
  ///
  /// In ro, this message translates to:
  /// **'Despre Nabour'**
  String get aboutNabour;

  /// No description provided for @evaluateApp.
  ///
  /// In ro, this message translates to:
  /// **'Evaluează Aplicația'**
  String get evaluateApp;

  /// No description provided for @howManyStars.
  ///
  /// In ro, this message translates to:
  /// **'Câte stele dai aplicației Nabour?'**
  String get howManyStars;

  /// No description provided for @starSelected.
  ///
  /// In ro, this message translates to:
  /// **'stea selectată'**
  String get starSelected;

  /// No description provided for @starsSelected.
  ///
  /// In ro, this message translates to:
  /// **'stele selectate'**
  String get starsSelected;

  /// No description provided for @cancel.
  ///
  /// In ro, this message translates to:
  /// **'Anulează'**
  String get cancel;

  /// No description provided for @select.
  ///
  /// In ro, this message translates to:
  /// **'Selectează'**
  String get select;

  /// No description provided for @ratingSentSuccessfully.
  ///
  /// In ro, this message translates to:
  /// **'✅ Rating de {rating} stele trimis cu succes!'**
  String ratingSentSuccessfully(String rating);

  /// No description provided for @career.
  ///
  /// In ro, this message translates to:
  /// **'Carieră'**
  String get career;

  /// No description provided for @joinOurTeam.
  ///
  /// In ro, this message translates to:
  /// **'Alătură-te echipei noastre'**
  String get joinOurTeam;

  /// No description provided for @evaluateApplication.
  ///
  /// In ro, this message translates to:
  /// **'Evaluează aplicația'**
  String get evaluateApplication;

  /// No description provided for @giveStarRating.
  ///
  /// In ro, this message translates to:
  /// **'⭐ Dă un rating cu stele'**
  String get giveStarRating;

  /// No description provided for @followUs.
  ///
  /// In ro, this message translates to:
  /// **'Urmărește-ne'**
  String get followUs;

  /// No description provided for @legalInformation.
  ///
  /// In ro, this message translates to:
  /// **'Informații Juridice'**
  String get legalInformation;

  /// No description provided for @termsConditions.
  ///
  /// In ro, this message translates to:
  /// **'Termeni & Condiții'**
  String get termsConditions;

  /// No description provided for @privacy.
  ///
  /// In ro, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @termsConditionsTitle.
  ///
  /// In ro, this message translates to:
  /// **'Termeni și Condiții'**
  String get termsConditionsTitle;

  /// No description provided for @generalProvisions.
  ///
  /// In ro, this message translates to:
  /// **'Prevederi Generale'**
  String get generalProvisions;

  /// No description provided for @generalProvisionsText.
  ///
  /// In ro, this message translates to:
  /// **'Anularea unei curse după alocarea unui șofer partener poate atrage o taxă de anulare pentru a compensa timpul și distanța parcursă de către șofer. Anularea este gratuită oricând înainte de alocarea unui șofer partener.'**
  String get generalProvisionsText;

  /// No description provided for @standardWaitTime.
  ///
  /// In ro, this message translates to:
  /// **'Timp de Așteptare Standard'**
  String get standardWaitTime;

  /// No description provided for @standardWaitTimeText.
  ///
  /// In ro, this message translates to:
  /// **'După sosirea la locația de preluare, șoferul partener va aștepta gratuit timp de 5 minute. După expirarea acestui interval, se pot aplica taxe suplimentare de așteptare sau cursa poate fi anulată, aplicându-se taxa de anulare corespunzătoare.'**
  String get standardWaitTimeText;

  /// No description provided for @specificCategoryPolicies.
  ///
  /// In ro, this message translates to:
  /// **'Politici Specifice pe Categorii'**
  String get specificCategoryPolicies;

  /// No description provided for @cancellationFee.
  ///
  /// In ro, this message translates to:
  /// **'Taxă de Anulare:'**
  String get cancellationFee;

  /// No description provided for @freeCancellation.
  ///
  /// In ro, this message translates to:
  /// **'Anulare Gratuită (Curse Rezervate):'**
  String get freeCancellation;

  /// No description provided for @minimumBookingTime.
  ///
  /// In ro, this message translates to:
  /// **'Timp Minim de Rezervare:'**
  String get minimumBookingTime;

  /// No description provided for @friendsRideStandard.
  ///
  /// In ro, this message translates to:
  /// **'Nabour Standard'**
  String get friendsRideStandard;

  /// No description provided for @friendsRideEnergy.
  ///
  /// In ro, this message translates to:
  /// **'Nabour Energy'**
  String get friendsRideEnergy;

  /// No description provided for @friendsRideBest.
  ///
  /// In ro, this message translates to:
  /// **'Nabour Best'**
  String get friendsRideBest;

  /// No description provided for @friendsRideFamily.
  ///
  /// In ro, this message translates to:
  /// **'Nabour Family'**
  String get friendsRideFamily;

  /// No description provided for @standardCancellationFee.
  ///
  /// In ro, this message translates to:
  /// **'30 RON'**
  String get standardCancellationFee;

  /// No description provided for @energyCancellationFee.
  ///
  /// In ro, this message translates to:
  /// **'30 RON'**
  String get energyCancellationFee;

  /// No description provided for @bestCancellationFee.
  ///
  /// In ro, this message translates to:
  /// **'30 RON'**
  String get bestCancellationFee;

  /// No description provided for @familyCancellationFee.
  ///
  /// In ro, this message translates to:
  /// **'30 RON'**
  String get familyCancellationFee;

  /// No description provided for @standardFreeCancellation.
  ///
  /// In ro, this message translates to:
  /// **'Cu cel puțin 1 oră și 30 de minute înainte de ora programată.'**
  String get standardFreeCancellation;

  /// No description provided for @standardMinBooking.
  ///
  /// In ro, this message translates to:
  /// **'Cu cel puțin 2 ore în avans față de ora rezervării cursei.'**
  String get standardMinBooking;

  /// No description provided for @energyMinBooking.
  ///
  /// In ro, this message translates to:
  /// **'Cu cel puțin 2 ore în avans față de ora rezervării cursei.'**
  String get energyMinBooking;

  /// No description provided for @bestMinBooking.
  ///
  /// In ro, this message translates to:
  /// **'Cu cel puțin 2 ore în avans față de ora rezervării cursei.'**
  String get bestMinBooking;

  /// No description provided for @familyMinBooking.
  ///
  /// In ro, this message translates to:
  /// **'Cu cel puțin 2 ore în avans față de ora rezervării cursei.'**
  String get familyMinBooking;

  /// No description provided for @privacyPolicyContent.
  ///
  /// In ro, this message translates to:
  /// **'Aici va fi afișat conținutul detaliat al Politicii de Confidențialitate, conform normelor GDPR. Documentul va explica ce tipuri de date personale sunt colectate (nume, email, locație, date de plată, etc.), scopul colectării (funcționarea serviciului, marketing, siguranță), cum sunt stocate și protejate datele, perioada de retenție, și care sunt drepturile utilizatorilor (dreptul la acces, rectificare, ștergere, etc.).\n\nTextul complet va fi furnizat de un consultant juridic pentru a asigura conformitatea cu legislația în vigoare.'**
  String get privacyPolicyContent;

  /// No description provided for @wallet.
  ///
  /// In ro, this message translates to:
  /// **'Portofel'**
  String get wallet;

  /// No description provided for @currentBalance.
  ///
  /// In ro, this message translates to:
  /// **'Balanță Curentă'**
  String get currentBalance;

  /// No description provided for @paymentMethods.
  ///
  /// In ro, this message translates to:
  /// **'Metode de Plată'**
  String get paymentMethods;

  /// No description provided for @addOrManageCards.
  ///
  /// In ro, this message translates to:
  /// **'Adaugă sau gestionează cardurile'**
  String get addOrManageCards;

  /// No description provided for @cash.
  ///
  /// In ro, this message translates to:
  /// **'Numerar'**
  String get cash;

  /// No description provided for @selectPaymentMethod.
  ///
  /// In ro, this message translates to:
  /// **'Selectează Metoda de Plată'**
  String get selectPaymentMethod;

  /// No description provided for @vouchers.
  ///
  /// In ro, this message translates to:
  /// **'Vouchere'**
  String get vouchers;

  /// No description provided for @addPromoCode.
  ///
  /// In ro, this message translates to:
  /// **'Adaugă un cod promoțional'**
  String get addPromoCode;

  /// No description provided for @transactionHistory.
  ///
  /// In ro, this message translates to:
  /// **'Istoric Tranzacții'**
  String get transactionHistory;

  /// No description provided for @viewAllPayments.
  ///
  /// In ro, this message translates to:
  /// **'Vezi toate plățile și încasările'**
  String get viewAllPayments;

  /// No description provided for @canSendToContact.
  ///
  /// In ro, this message translates to:
  /// **'Poți trimite unei persoane de contact'**
  String get canSendToContact;

  /// No description provided for @addPaymentMethod.
  ///
  /// In ro, this message translates to:
  /// **'Adaugă o metodă de plată'**
  String get addPaymentMethod;

  /// No description provided for @rideProfiles.
  ///
  /// In ro, this message translates to:
  /// **'Profilurile curselor'**
  String get rideProfiles;

  /// No description provided for @startUsing.
  ///
  /// In ro, this message translates to:
  /// **'Începe să folosești'**
  String get startUsing;

  /// No description provided for @friendsRideForBusiness.
  ///
  /// In ro, this message translates to:
  /// **'Nabour for Business'**
  String get friendsRideForBusiness;

  /// No description provided for @activateBusinessFeatures.
  ///
  /// In ro, this message translates to:
  /// **'Activează funcțiile pentru călătorii în interes de serviciu'**
  String get activateBusinessFeatures;

  /// No description provided for @manageBusinessTrips.
  ///
  /// In ro, this message translates to:
  /// **'Gestionează curse în interes de serviciu pe...'**
  String get manageBusinessTrips;

  /// No description provided for @requestBusinessProfileAccess.
  ///
  /// In ro, this message translates to:
  /// **'Solicită accesul la profilul Business'**
  String get requestBusinessProfileAccess;

  /// No description provided for @addVoucherCode.
  ///
  /// In ro, this message translates to:
  /// **'Adaugă codul voucherului'**
  String get addVoucherCode;

  /// No description provided for @promotions.
  ///
  /// In ro, this message translates to:
  /// **'Promoţii'**
  String get promotions;

  /// No description provided for @recommendations.
  ///
  /// In ro, this message translates to:
  /// **'Recomandări'**
  String get recommendations;

  /// No description provided for @addReferralCode.
  ///
  /// In ro, this message translates to:
  /// **'Adaugă codul de recomandare'**
  String get addReferralCode;

  /// No description provided for @inStoreOffers.
  ///
  /// In ro, this message translates to:
  /// **'Oferte în magazin'**
  String get inStoreOffers;

  /// No description provided for @offers.
  ///
  /// In ro, this message translates to:
  /// **'Oferte'**
  String get offers;

  /// No description provided for @walletDetails.
  ///
  /// In ro, this message translates to:
  /// **'Detalii Portofel'**
  String get walletDetails;

  /// No description provided for @walletDetailsInfo.
  ///
  /// In ro, this message translates to:
  /// **'Nabour Cash este balanța ta digitală. Poți adăuga fonduri pentru plăți mai rapide.'**
  String get walletDetailsInfo;

  /// No description provided for @addFunds.
  ///
  /// In ro, this message translates to:
  /// **'Adaugă Fonduri'**
  String get addFunds;

  /// No description provided for @addFundsComingSoon.
  ///
  /// In ro, this message translates to:
  /// **'Funcționalitatea de adăugare fonduri va fi disponibilă în curând.'**
  String get addFundsComingSoon;

  /// No description provided for @paymentMethodDetails.
  ///
  /// In ro, this message translates to:
  /// **'Detalii Metodă de Plată'**
  String get paymentMethodDetails;

  /// No description provided for @brand.
  ///
  /// In ro, this message translates to:
  /// **'Brand'**
  String get brand;

  /// No description provided for @last4Digits.
  ///
  /// In ro, this message translates to:
  /// **'Ultimele 4 cifre'**
  String get last4Digits;

  /// No description provided for @cardholder.
  ///
  /// In ro, this message translates to:
  /// **'Titular card'**
  String get cardholder;

  /// No description provided for @expiryDate.
  ///
  /// In ro, this message translates to:
  /// **'Data expirării'**
  String get expiryDate;

  /// No description provided for @cashPaymentMethod.
  ///
  /// In ro, this message translates to:
  /// **'Plata se face direct șoferului în numerar.'**
  String get cashPaymentMethod;

  /// No description provided for @delete.
  ///
  /// In ro, this message translates to:
  /// **'Șterge'**
  String get delete;

  /// No description provided for @deletePaymentMethodComingSoon.
  ///
  /// In ro, this message translates to:
  /// **'Funcționalitatea de ștergere metodă de plată va fi disponibilă în curând.'**
  String get deletePaymentMethodComingSoon;

  /// No description provided for @businessProfile.
  ///
  /// In ro, this message translates to:
  /// **'Profil Business'**
  String get businessProfile;

  /// No description provided for @businessProfileInfo.
  ///
  /// In ro, this message translates to:
  /// **'Activează profilul Business pentru a gestiona curse în interes de serviciu.'**
  String get businessProfileInfo;

  /// No description provided for @businessProfileBenefits.
  ///
  /// In ro, this message translates to:
  /// **'Beneficii:'**
  String get businessProfileBenefits;

  /// No description provided for @businessProfileBenefit1.
  ///
  /// In ro, this message translates to:
  /// **'Rapoarte detaliate pentru cheltuieli'**
  String get businessProfileBenefit1;

  /// No description provided for @businessProfileBenefit2.
  ///
  /// In ro, this message translates to:
  /// **'Facturare automată către companie'**
  String get businessProfileBenefit2;

  /// No description provided for @businessProfileBenefit3.
  ///
  /// In ro, this message translates to:
  /// **'Gestionare multiple utilizatori'**
  String get businessProfileBenefit3;

  /// No description provided for @requestAccess.
  ///
  /// In ro, this message translates to:
  /// **'Solicită Acces'**
  String get requestAccess;

  /// No description provided for @businessProfileRequestSent.
  ///
  /// In ro, this message translates to:
  /// **'Cererea pentru profil Business a fost trimisă. Vei primi un răspuns în curând.'**
  String get businessProfileRequestSent;

  /// No description provided for @referralCodeInfo.
  ///
  /// In ro, this message translates to:
  /// **'Introdu codul de recomandare pentru a primi beneficii.'**
  String get referralCodeInfo;

  /// No description provided for @enterReferralCode.
  ///
  /// In ro, this message translates to:
  /// **'Introdu codul'**
  String get enterReferralCode;

  /// No description provided for @referralCodeApplied.
  ///
  /// In ro, this message translates to:
  /// **'Codul de recomandare a fost aplicat cu succes!'**
  String get referralCodeApplied;

  /// No description provided for @personalProfileActive.
  ///
  /// In ro, this message translates to:
  /// **'Profilul Personal este activ.'**
  String get personalProfileActive;

  /// No description provided for @inStoreOffersComingSoon.
  ///
  /// In ro, this message translates to:
  /// **'Ofertele în magazin vor fi disponibile în curând.'**
  String get inStoreOffersComingSoon;

  /// No description provided for @close.
  ///
  /// In ro, this message translates to:
  /// **'Închide'**
  String get close;

  /// No description provided for @paymentMethodDeleted.
  ///
  /// In ro, this message translates to:
  /// **'Metoda de plată a fost ștearsă cu succes.'**
  String get paymentMethodDeleted;

  /// No description provided for @errorDeletingPaymentMethod.
  ///
  /// In ro, this message translates to:
  /// **'Eroare la ștergerea metodei de plată.'**
  String get errorDeletingPaymentMethod;

  /// No description provided for @errorRequestingBusinessProfile.
  ///
  /// In ro, this message translates to:
  /// **'Eroare la trimiterea cererii pentru profil business.'**
  String get errorRequestingBusinessProfile;

  /// No description provided for @errorApplyingReferralCode.
  ///
  /// In ro, this message translates to:
  /// **'Eroare la aplicarea codului de recomandare.'**
  String get errorApplyingReferralCode;

  /// No description provided for @paymentMethodsHelpTitle.
  ///
  /// In ro, this message translates to:
  /// **'Metode de Plată'**
  String get paymentMethodsHelpTitle;

  /// No description provided for @addingPaymentMethod.
  ///
  /// In ro, this message translates to:
  /// **'Adăugarea unei metode de plată:'**
  String get addingPaymentMethod;

  /// No description provided for @goToWalletSection.
  ///
  /// In ro, this message translates to:
  /// **'• Accesează secțiunea \"Portofel\" din meniul principal'**
  String get goToWalletSection;

  /// No description provided for @tapAddPaymentMethod.
  ///
  /// In ro, this message translates to:
  /// **'• Apasă pe butonul \"Adaugă o metodă de plată\"'**
  String get tapAddPaymentMethod;

  /// No description provided for @selectCardOrCash.
  ///
  /// In ro, this message translates to:
  /// **'• Selectează tipul de metodă (card sau numerar)'**
  String get selectCardOrCash;

  /// No description provided for @enterCardDetails.
  ///
  /// In ro, this message translates to:
  /// **'• Completează detaliile cardului (număr, dată expirare, CVV)'**
  String get enterCardDetails;

  /// No description provided for @savePaymentMethod.
  ///
  /// In ro, this message translates to:
  /// **'• Salvează metoda de plată'**
  String get savePaymentMethod;

  /// No description provided for @managingPaymentMethods.
  ///
  /// In ro, this message translates to:
  /// **'Gestionarea metodelor de plată:'**
  String get managingPaymentMethods;

  /// No description provided for @viewAllMethodsInWallet.
  ///
  /// In ro, this message translates to:
  /// **'• Vezi toate metodele salvate în secțiunea \"Portofel\"'**
  String get viewAllMethodsInWallet;

  /// No description provided for @editOrDeleteMethods.
  ///
  /// In ro, this message translates to:
  /// **'• Editează sau șterge metodele existente'**
  String get editOrDeleteMethods;

  /// No description provided for @setDefaultPaymentMethod.
  ///
  /// In ro, this message translates to:
  /// **'• Setează o metodă ca implicită pentru plăți automate'**
  String get setDefaultPaymentMethod;

  /// No description provided for @paymentMethodsTypes.
  ///
  /// In ro, this message translates to:
  /// **'Tipuri de metode de plată:'**
  String get paymentMethodsTypes;

  /// No description provided for @creditDebitCards.
  ///
  /// In ro, this message translates to:
  /// **'• Carduri de credit/debit (Visa, Mastercard)'**
  String get creditDebitCards;

  /// No description provided for @cashPayment.
  ///
  /// In ro, this message translates to:
  /// **'• Numerar (plata se face direct șoferului)'**
  String get cashPayment;

  /// No description provided for @walletBalance.
  ///
  /// In ro, this message translates to:
  /// **'• Nabour Cash (balanță în portofel)'**
  String get walletBalance;

  /// No description provided for @paymentSecurity.
  ///
  /// In ro, this message translates to:
  /// **'Securitate plăți:'**
  String get paymentSecurity;

  /// No description provided for @allPaymentsSecure.
  ///
  /// In ro, this message translates to:
  /// **'• Toate plățile sunt procesate în siguranță'**
  String get allPaymentsSecure;

  /// No description provided for @cardDetailsEncrypted.
  ///
  /// In ro, this message translates to:
  /// **'• Detaliile cardurilor sunt criptate și stocate securizat'**
  String get cardDetailsEncrypted;

  /// No description provided for @pciCompliant.
  ///
  /// In ro, this message translates to:
  /// **'• Aplicația respectă standardele PCI DSS pentru securitate'**
  String get pciCompliant;

  /// No description provided for @paymentMethodTip.
  ///
  /// In ro, this message translates to:
  /// **'💡 Sfat util:'**
  String get paymentMethodTip;

  /// No description provided for @youCanSendToContact.
  ///
  /// In ro, this message translates to:
  /// **'Poți trimite bani către persoane de contact folosind metodele de plată salvate.'**
  String get youCanSendToContact;

  /// No description provided for @vouchersHelpTitle.
  ///
  /// In ro, this message translates to:
  /// **'Vouchere'**
  String get vouchersHelpTitle;

  /// No description provided for @addingVoucher.
  ///
  /// In ro, this message translates to:
  /// **'Adăugarea unui voucher:'**
  String get addingVoucher;

  /// No description provided for @tapVouchersSection.
  ///
  /// In ro, this message translates to:
  /// **'• Apasă pe secțiunea \"Vouchere\" din Portofel'**
  String get tapVouchersSection;

  /// No description provided for @tapAddVoucherCode.
  ///
  /// In ro, this message translates to:
  /// **'• Apasă pe \"Adaugă codul voucherului\"'**
  String get tapAddVoucherCode;

  /// No description provided for @enterVoucherCode.
  ///
  /// In ro, this message translates to:
  /// **'• Introdu codul voucherului'**
  String get enterVoucherCode;

  /// No description provided for @applyVoucher.
  ///
  /// In ro, this message translates to:
  /// **'• Apasă \"Aplică\" pentru a activa voucherul'**
  String get applyVoucher;

  /// No description provided for @usingVouchers.
  ///
  /// In ro, this message translates to:
  /// **'Utilizarea voucherelor:'**
  String get usingVouchers;

  /// No description provided for @vouchersAppliedAutomatically.
  ///
  /// In ro, this message translates to:
  /// **'• Voucherele se aplică automat la următoarea cursă'**
  String get vouchersAppliedAutomatically;

  /// No description provided for @checkVoucherStatus.
  ///
  /// In ro, this message translates to:
  /// **'• Verifică statusul voucherelor în secțiunea Vouchere'**
  String get checkVoucherStatus;

  /// No description provided for @voucherExpiryInfo.
  ///
  /// In ro, this message translates to:
  /// **'• Voucherele au o dată de expirare'**
  String get voucherExpiryInfo;

  /// No description provided for @voucherTypes.
  ///
  /// In ro, this message translates to:
  /// **'Tipuri de vouchere:'**
  String get voucherTypes;

  /// No description provided for @percentageDiscount.
  ///
  /// In ro, this message translates to:
  /// **'• Reducere procentuală (ex: 10% reducere)'**
  String get percentageDiscount;

  /// No description provided for @fixedAmountDiscount.
  ///
  /// In ro, this message translates to:
  /// **'• Reducere fixă (ex: 5 RON reducere)'**
  String get fixedAmountDiscount;

  /// No description provided for @freeRideVoucher.
  ///
  /// In ro, this message translates to:
  /// **'• Cursă gratuită'**
  String get freeRideVoucher;

  /// No description provided for @voucherTip.
  ///
  /// In ro, this message translates to:
  /// **'💡 Sfat util:'**
  String get voucherTip;

  /// No description provided for @oneVoucherPerRide.
  ///
  /// In ro, this message translates to:
  /// **'Poți folosi un singur voucher per cursă.'**
  String get oneVoucherPerRide;

  /// No description provided for @walletHelpTitle.
  ///
  /// In ro, this message translates to:
  /// **'Portofel'**
  String get walletHelpTitle;

  /// No description provided for @walletOverview.
  ///
  /// In ro, this message translates to:
  /// **'Prezentare generală:'**
  String get walletOverview;

  /// No description provided for @walletOverviewInfo.
  ///
  /// In ro, this message translates to:
  /// **'Secțiunea Portofel îți permite să gestionezi metodele de plată, voucherele, și balanța Nabour Cash.'**
  String get walletOverviewInfo;

  /// No description provided for @friendsRideCash.
  ///
  /// In ro, this message translates to:
  /// **'Nabour Cash:'**
  String get friendsRideCash;

  /// No description provided for @friendsRideCashInfo.
  ///
  /// In ro, this message translates to:
  /// **'• Balanță digitală pentru plăți rapide'**
  String get friendsRideCashInfo;

  /// No description provided for @addFundsToWallet.
  ///
  /// In ro, this message translates to:
  /// **'• Poți adăuga fonduri în portofel'**
  String get addFundsToWallet;

  /// No description provided for @useWalletForPayments.
  ///
  /// In ro, this message translates to:
  /// **'• Poți folosi balanța pentru plăți automate'**
  String get useWalletForPayments;

  /// No description provided for @walletSections.
  ///
  /// In ro, this message translates to:
  /// **'Secțiuni disponibile:'**
  String get walletSections;

  /// No description provided for @paymentMethodsSection.
  ///
  /// In ro, this message translates to:
  /// **'• Metode de plată - gestionează cardurile și numerarul'**
  String get paymentMethodsSection;

  /// No description provided for @vouchersSection.
  ///
  /// In ro, this message translates to:
  /// **'• Vouchere - adaugă și gestionează coduri promoționale'**
  String get vouchersSection;

  /// No description provided for @rideProfilesSection.
  ///
  /// In ro, this message translates to:
  /// **'• Profilurile curselor - Personal și Business'**
  String get rideProfilesSection;

  /// No description provided for @promotionsSection.
  ///
  /// In ro, this message translates to:
  /// **'• Promoții - coduri promoționale și recomandări'**
  String get promotionsSection;

  /// No description provided for @walletTip.
  ///
  /// In ro, this message translates to:
  /// **'💡 Sfat util:'**
  String get walletTip;

  /// No description provided for @walletBalanceNeverExpires.
  ///
  /// In ro, this message translates to:
  /// **'Balanța Nabour Cash nu expiră niciodată.'**
  String get walletBalanceNeverExpires;

  /// No description provided for @earningsToday.
  ///
  /// In ro, this message translates to:
  /// **'Sprijin Oferit Astăzi'**
  String get earningsToday;

  /// No description provided for @ridesToday.
  ///
  /// In ro, this message translates to:
  /// **'Vecini Ajutați'**
  String get ridesToday;

  /// No description provided for @averageRating.
  ///
  /// In ro, this message translates to:
  /// **'Rating Comunitate'**
  String get averageRating;

  /// No description provided for @lastCompletedRides.
  ///
  /// In ro, this message translates to:
  /// **'Ultimele Curse Finalizate'**
  String get lastCompletedRides;

  /// No description provided for @allRides.
  ///
  /// In ro, this message translates to:
  /// **'Toate Cursele'**
  String get allRides;

  /// No description provided for @todayRides.
  ///
  /// In ro, this message translates to:
  /// **'Cursele de Astăzi'**
  String get todayRides;

  /// No description provided for @generateDailyReport.
  ///
  /// In ro, this message translates to:
  /// **'Generează Raport Zilnic'**
  String get generateDailyReport;

  /// No description provided for @noRidesYet.
  ///
  /// In ro, this message translates to:
  /// **'Nicio cursă finalizată încă'**
  String get noRidesYet;

  /// No description provided for @viewDetails.
  ///
  /// In ro, this message translates to:
  /// **'Vezi Detalii'**
  String get viewDetails;

  /// No description provided for @addTrustedContact.
  ///
  /// In ro, this message translates to:
  /// **'Adaugă contact de încredere'**
  String get addTrustedContact;

  /// No description provided for @name.
  ///
  /// In ro, this message translates to:
  /// **'Nume'**
  String get name;

  /// No description provided for @phoneNumber.
  ///
  /// In ro, this message translates to:
  /// **'Număr de telefon'**
  String get phoneNumber;

  /// No description provided for @phoneNumberExample.
  ///
  /// In ro, this message translates to:
  /// **'ex: 0712 345 678'**
  String get phoneNumberExample;

  /// No description provided for @save.
  ///
  /// In ro, this message translates to:
  /// **'Salvează'**
  String get save;

  /// No description provided for @contactSaved.
  ///
  /// In ro, this message translates to:
  /// **'Contactul {name} a fost salvat.'**
  String contactSaved(String name);

  /// No description provided for @trustedContacts.
  ///
  /// In ro, this message translates to:
  /// **'Contacte de încredere'**
  String get trustedContacts;

  /// No description provided for @noContacts.
  ///
  /// In ro, this message translates to:
  /// **'Niciun contact de încredere adăugat încă'**
  String get noContacts;

  /// No description provided for @emergencyCall.
  ///
  /// In ro, this message translates to:
  /// **'Apel de Urgență'**
  String get emergencyCall;

  /// No description provided for @safetyFeatures.
  ///
  /// In ro, this message translates to:
  /// **'Funcții de Siguranță'**
  String get safetyFeatures;

  /// No description provided for @emergencyAssistance.
  ///
  /// In ro, this message translates to:
  /// **'Asistență de Urgență'**
  String get emergencyAssistance;

  /// No description provided for @shareTrip.
  ///
  /// In ro, this message translates to:
  /// **'Partajează Cursa'**
  String get shareTrip;

  /// No description provided for @reportIncident.
  ///
  /// In ro, this message translates to:
  /// **'Raportează Incident'**
  String get reportIncident;

  /// No description provided for @helpCenter.
  ///
  /// In ro, this message translates to:
  /// **'Centru de Ajutor'**
  String get helpCenter;

  /// No description provided for @frequentlyAskedQuestions.
  ///
  /// In ro, this message translates to:
  /// **'Întrebări Frecvente'**
  String get frequentlyAskedQuestions;

  /// No description provided for @contactSupport.
  ///
  /// In ro, this message translates to:
  /// **'Contactează Suportul'**
  String get contactSupport;

  /// No description provided for @reportProblem.
  ///
  /// In ro, this message translates to:
  /// **'Raportează o problemă'**
  String get reportProblem;

  /// No description provided for @cannotRequestRide.
  ///
  /// In ro, this message translates to:
  /// **'Nu pot solicita o cursă'**
  String get cannotRequestRide;

  /// No description provided for @cannotRequestRideContent.
  ///
  /// In ro, this message translates to:
  /// **'Dacă întâmpinați probleme la solicitarea unei curse, încercați următoarele soluții:'**
  String get cannotRequestRideContent;

  /// No description provided for @checkInternetConnection.
  ///
  /// In ro, this message translates to:
  /// **'2. Verificați conexiunea la internet'**
  String get checkInternetConnection;

  /// No description provided for @ensureGpsEnabled.
  ///
  /// In ro, this message translates to:
  /// **'• Asigurați-vă că locația GPS este activată'**
  String get ensureGpsEnabled;

  /// No description provided for @restartApp.
  ///
  /// In ro, this message translates to:
  /// **'1. Restartați aplicația'**
  String get restartApp;

  /// No description provided for @checkValidPayment.
  ///
  /// In ro, this message translates to:
  /// **'• Verificați dacă aveți o metodă de plată validă'**
  String get checkValidPayment;

  /// No description provided for @contactSupportIfPersists.
  ///
  /// In ro, this message translates to:
  /// **'• Contactați echipa de suport dacă problema persistă'**
  String get contactSupportIfPersists;

  /// No description provided for @pickupTimeLonger.
  ///
  /// In ro, this message translates to:
  /// **'Timpul de preluare este mai mare decât cel estimat'**
  String get pickupTimeLonger;

  /// No description provided for @pickupTimeLongerContent.
  ///
  /// In ro, this message translates to:
  /// **'Timpul estimat poate varia din următoarele motive:'**
  String get pickupTimeLongerContent;

  /// No description provided for @unexpectedHeavyTraffic.
  ///
  /// In ro, this message translates to:
  /// **'• Trafic intens neașteptat'**
  String get unexpectedHeavyTraffic;

  /// No description provided for @unfavorableWeather.
  ///
  /// In ro, this message translates to:
  /// **'• Condiții meteorologice nefavorabile'**
  String get unfavorableWeather;

  /// No description provided for @driverFindingAddress.
  ///
  /// In ro, this message translates to:
  /// **'• Șoferul poate avea dificultăți în găsirea adresei'**
  String get driverFindingAddress;

  /// No description provided for @specialEvents.
  ///
  /// In ro, this message translates to:
  /// **'• Evenimente speciale în zona dvs.'**
  String get specialEvents;

  /// No description provided for @contactDriverDirectly.
  ///
  /// In ro, this message translates to:
  /// **'Puteți contacta șoferul direct prin aplicație pentru a clarifica situația.'**
  String get contactDriverDirectly;

  /// No description provided for @rideDidNotHappen.
  ///
  /// In ro, this message translates to:
  /// **'Cursa nu a avut loc'**
  String get rideDidNotHappen;

  /// No description provided for @rideDidNotHappenContent.
  ///
  /// In ro, this message translates to:
  /// **'Dacă cursa nu a avut loc, verificați:'**
  String get rideDidNotHappenContent;

  /// No description provided for @rideStatusInApp.
  ///
  /// In ro, this message translates to:
  /// **'• Statusul cursei în aplicație'**
  String get rideStatusInApp;

  /// No description provided for @messagesFromDriver.
  ///
  /// In ro, this message translates to:
  /// **'• Mesajele de la șofer'**
  String get messagesFromDriver;

  /// No description provided for @correctLocation.
  ///
  /// In ro, this message translates to:
  /// **'• Dacă ați fost la locația corectă'**
  String get correctLocation;

  /// No description provided for @contactSupportForRefund.
  ///
  /// In ro, this message translates to:
  /// **'Pentru rambursări, contactați suportul cu detaliile cursei.'**
  String get contactSupportForRefund;

  /// No description provided for @lostItems.
  ///
  /// In ro, this message translates to:
  /// **'Obiecte pierdute'**
  String get lostItems;

  /// No description provided for @lostItemsContent.
  ///
  /// In ro, this message translates to:
  /// **'Dacă ați uitat ceva în mașina șoferului:'**
  String get lostItemsContent;

  /// No description provided for @contactDriverImmediately.
  ///
  /// In ro, this message translates to:
  /// **'1. Contactați imediat șoferul prin aplicație'**
  String get contactDriverImmediately;

  /// No description provided for @describeLostItem.
  ///
  /// In ro, this message translates to:
  /// **'2. Descrieți obiectul pierdut'**
  String get describeLostItem;

  /// No description provided for @arrangePickup.
  ///
  /// In ro, this message translates to:
  /// **'3. Stabiliți o întâlnire pentru recuperare'**
  String get arrangePickup;

  /// No description provided for @reportToSupport.
  ///
  /// In ro, this message translates to:
  /// **'4. Dacă nu reușiți să contactați șoferul, raportați prin suport'**
  String get reportToSupport;

  /// No description provided for @returnFeeNote.
  ///
  /// In ro, this message translates to:
  /// **'Notă: Poate fi aplicată o taxă mică pentru returnarea obiectelor.'**
  String get returnFeeNote;

  /// No description provided for @driverDeviatedRoute.
  ///
  /// In ro, this message translates to:
  /// **'Șoferul a deviat de la traseu'**
  String get driverDeviatedRoute;

  /// No description provided for @driverDeviatedContent.
  ///
  /// In ro, this message translates to:
  /// **'Dacă șoferul a luat o rută diferită:'**
  String get driverDeviatedContent;

  /// No description provided for @askDriverReason.
  ///
  /// In ro, this message translates to:
  /// **'• Întrebați șoferul despre motivul schimbării'**
  String get askDriverReason;

  /// No description provided for @checkTrafficWorks.
  ///
  /// In ro, this message translates to:
  /// **'• Verificați dacă există trafic sau lucrări pe traseul inițial'**
  String get checkTrafficWorks;

  /// No description provided for @reportIfUnjustified.
  ///
  /// In ro, this message translates to:
  /// **'• Dacă considerați că devierea este nejustificată, raportați'**
  String get reportIfUnjustified;

  /// No description provided for @driversCanChooseAlternatives.
  ///
  /// In ro, this message translates to:
  /// **'Șoferii pot alege rute alternative pentru a evita traficul.'**
  String get driversCanChooseAlternatives;

  /// No description provided for @driverDashboardWeeklyActivityTitle.
  ///
  /// In ro, this message translates to:
  /// **'Activitate în comunitate'**
  String get driverDashboardWeeklyActivityTitle;

  /// No description provided for @driverDashboardWeeklyKudosHeader.
  ///
  /// In ro, this message translates to:
  /// **'Aprecieri'**
  String get driverDashboardWeeklyKudosHeader;

  /// No description provided for @driverDashboardWeeklyTotalHelpsWeek.
  ///
  /// In ro, this message translates to:
  /// **'Total ajutoare săptămână:'**
  String get driverDashboardWeeklyTotalHelpsWeek;

  /// No description provided for @emergencyAssistanceUsage.
  ///
  /// In ro, this message translates to:
  /// **'Utilizarea asistenței de urgență'**
  String get emergencyAssistanceUsage;

  /// No description provided for @emergencyAssistanceContent.
  ///
  /// In ro, this message translates to:
  /// **'Funcția de urgență vă permite să:'**
  String get emergencyAssistanceContent;

  /// No description provided for @quickCall112.
  ///
  /// In ro, this message translates to:
  /// **'• Apelați rapid 112'**
  String get quickCall112;

  /// No description provided for @sendLocationToContact.
  ///
  /// In ro, this message translates to:
  /// **'• Trimiteți locația dvs. unui contact de urgență'**
  String get sendLocationToContact;

  /// No description provided for @reportIncidentToSafety.
  ///
  /// In ro, this message translates to:
  /// **'• Raportați un incident către echipa de siguranță'**
  String get reportIncidentToSafety;

  /// No description provided for @voiceSettingsSaved.
  ///
  /// In ro, this message translates to:
  /// **'Setările vocale au fost salvate'**
  String get voiceSettingsSaved;

  /// No description provided for @availableVoiceCommands.
  ///
  /// In ro, this message translates to:
  /// **'Comenzi Vocale Disponibile'**
  String get availableVoiceCommands;

  /// No description provided for @basicCommands.
  ///
  /// In ro, this message translates to:
  /// **'Comenzi de bază:'**
  String get basicCommands;

  /// No description provided for @wantRideToDestination.
  ///
  /// In ro, this message translates to:
  /// **'\"Vreau o cursă la [destinație]\"'**
  String get wantRideToDestination;

  /// No description provided for @economyRideToDestination.
  ///
  /// In ro, this message translates to:
  /// **'\"Cursă economică la [destinație]\"'**
  String get economyRideToDestination;

  /// No description provided for @urgentRideToDestination.
  ///
  /// In ro, this message translates to:
  /// **'\"Cursă urgentă la [destinație]\"'**
  String get urgentRideToDestination;

  /// No description provided for @premiumRideToDestination.
  ///
  /// In ro, this message translates to:
  /// **'\"Cursă premium la [destinație]\"'**
  String get premiumRideToDestination;

  /// No description provided for @commandsDuringRide.
  ///
  /// In ro, this message translates to:
  /// **'Comenzi în timpul cursei:'**
  String get commandsDuringRide;

  /// No description provided for @sendMessageToDriver.
  ///
  /// In ro, this message translates to:
  /// **'\"Trimite mesaj șoferului\"'**
  String get sendMessageToDriver;

  /// No description provided for @whereIsDriver.
  ///
  /// In ro, this message translates to:
  /// **'\"Unde este șoferul?\"'**
  String get whereIsDriver;

  /// No description provided for @wantToPayCash.
  ///
  /// In ro, this message translates to:
  /// **'\"Vreau să plătesc cash\"'**
  String get wantToPayCash;

  /// No description provided for @controlCommands.
  ///
  /// In ro, this message translates to:
  /// **'Comenzi de control:'**
  String get controlCommands;

  /// No description provided for @heyNabour.
  ///
  /// In ro, this message translates to:
  /// **'\"Hey Nabour\" (activare)'**
  String get heyNabour;

  /// No description provided for @helpCommand.
  ///
  /// In ro, this message translates to:
  /// **'\"Ajutor\" (ajutor)'**
  String get helpCommand;

  /// No description provided for @cancelCommand.
  ///
  /// In ro, this message translates to:
  /// **'\"Anulează\" (anulare)'**
  String get cancelCommand;

  /// No description provided for @stopCommand.
  ///
  /// In ro, this message translates to:
  /// **'\"Stop\" (oprire)'**
  String get stopCommand;

  /// No description provided for @advancedHelp.
  ///
  /// In ro, this message translates to:
  /// **'Ajutor Avansat'**
  String get advancedHelp;

  /// No description provided for @advancedFeaturesAvailable.
  ///
  /// In ro, this message translates to:
  /// **'Funcții avansate disponibile:'**
  String get advancedFeaturesAvailable;

  /// No description provided for @automaticVoiceActivation.
  ///
  /// In ro, this message translates to:
  /// **'   - Activare vocală automată'**
  String get automaticVoiceActivation;

  /// No description provided for @customActivationWord.
  ///
  /// In ro, this message translates to:
  /// **'   - Personalizare cuvânt activare'**
  String get customActivationWord;

  /// No description provided for @realtimeDetection.
  ///
  /// In ro, this message translates to:
  /// **'   - Detectare în timp real'**
  String get realtimeDetection;

  /// No description provided for @continuousListening.
  ///
  /// In ro, this message translates to:
  /// **'Ascultare continuă'**
  String get continuousListening;

  /// No description provided for @continuousListeningForCommands.
  ///
  /// In ro, this message translates to:
  /// **'   - Ascultare continuă pentru comenzi'**
  String get continuousListeningForCommands;

  /// No description provided for @realtimeProcessing.
  ///
  /// In ro, this message translates to:
  /// **'   - Procesare în timp real'**
  String get realtimeProcessing;

  /// No description provided for @smartBatterySaving.
  ///
  /// In ro, this message translates to:
  /// **'   - Economie baterie inteligentă'**
  String get smartBatterySaving;

  /// No description provided for @multiLanguageSupport.
  ///
  /// In ro, this message translates to:
  /// **'Suport multi-limbă'**
  String get multiLanguageSupport;

  /// No description provided for @supportFor6Languages.
  ///
  /// In ro, this message translates to:
  /// **'   - Suport pentru 6 limbi'**
  String get supportFor6Languages;

  /// No description provided for @voiceSwitchBetweenLanguages.
  ///
  /// In ro, this message translates to:
  /// **'   - Comutare vocală între limbi'**
  String get voiceSwitchBetweenLanguages;

  /// No description provided for @localAccentAdaptation.
  ///
  /// In ro, this message translates to:
  /// **'   - Adaptare accent local'**
  String get localAccentAdaptation;

  /// No description provided for @privacySecurity.
  ///
  /// In ro, this message translates to:
  /// **'Privacy & Security'**
  String get privacySecurity;

  /// No description provided for @localProcessing.
  ///
  /// In ro, this message translates to:
  /// **'   - Procesare locală'**
  String get localProcessing;

  /// No description provided for @endToEndEncryption.
  ///
  /// In ro, this message translates to:
  /// **'   - Criptare end-to-end'**
  String get endToEndEncryption;

  /// No description provided for @fullDataControl.
  ///
  /// In ro, this message translates to:
  /// **'   - Control total asupra datelor'**
  String get fullDataControl;

  /// No description provided for @contactSupportForTechnical.
  ///
  /// In ro, this message translates to:
  /// **'Pentru asistență tehnică, contactați suportul.'**
  String get contactSupportForTechnical;

  /// No description provided for @listening.
  ///
  /// In ro, this message translates to:
  /// **'Vă Ascult'**
  String get listening;

  /// No description provided for @sayYourAnswer.
  ///
  /// In ro, this message translates to:
  /// **'Spuneți răspunsul:'**
  String get sayYourAnswer;

  /// No description provided for @acceptOrDecline.
  ///
  /// In ro, this message translates to:
  /// **'\"ACCEPT\" sau \"REFUZ\"'**
  String get acceptOrDecline;

  /// No description provided for @greeting.
  ///
  /// In ro, this message translates to:
  /// **'Salutare! Unde doriți să mergeți?'**
  String get greeting;

  /// No description provided for @account.
  ///
  /// In ro, this message translates to:
  /// **'Cont'**
  String get account;

  /// No description provided for @personalInformation.
  ///
  /// In ro, this message translates to:
  /// **'Informații Personale'**
  String get personalInformation;

  /// No description provided for @changePassword.
  ///
  /// In ro, this message translates to:
  /// **'Schimbă Parola'**
  String get changePassword;

  /// No description provided for @security.
  ///
  /// In ro, this message translates to:
  /// **'Securitate'**
  String get security;

  /// No description provided for @notifications.
  ///
  /// In ro, this message translates to:
  /// **'Notificări'**
  String get notifications;

  /// No description provided for @reportGenerated.
  ///
  /// In ro, this message translates to:
  /// **'Raport Generat'**
  String get reportGenerated;

  /// No description provided for @dailyReportGeneratedSuccess.
  ///
  /// In ro, this message translates to:
  /// **'Raportul zilnic a fost generat cu succes. Doriți să vă întoarceți la harta principală?'**
  String get dailyReportGeneratedSuccess;

  /// No description provided for @stayHere.
  ///
  /// In ro, this message translates to:
  /// **'Rămân aici'**
  String get stayHere;

  /// No description provided for @goToMap.
  ///
  /// In ro, this message translates to:
  /// **'Mergi la Hartă'**
  String get goToMap;

  /// No description provided for @driverOptions.
  ///
  /// In ro, this message translates to:
  /// **'Opțiuni Șofer'**
  String get driverOptions;

  /// No description provided for @generatingReport.
  ///
  /// In ro, this message translates to:
  /// **'Generez raport...'**
  String get generatingReport;

  /// No description provided for @showAll.
  ///
  /// In ro, this message translates to:
  /// **'Arată Toate'**
  String get showAll;

  /// No description provided for @noRidesMatchFilter.
  ///
  /// In ro, this message translates to:
  /// **'Nu există nicio cursă care să corespundă filtrului.'**
  String get noRidesMatchFilter;

  /// No description provided for @to.
  ///
  /// In ro, this message translates to:
  /// **'Către:'**
  String get to;

  /// No description provided for @destination.
  ///
  /// In ro, this message translates to:
  /// **'Destinație'**
  String get destination;

  /// No description provided for @driverModeDeactivated.
  ///
  /// In ro, this message translates to:
  /// **'Modul Șofer Dezactivat'**
  String get driverModeDeactivated;

  /// No description provided for @goToMapAndActivate.
  ///
  /// In ro, this message translates to:
  /// **'Mergi la Hartă și activează switch-ul pentru a primi curse.'**
  String get goToMapAndActivate;

  /// No description provided for @youAreAvailable.
  ///
  /// In ro, this message translates to:
  /// **'Ești Disponibil pentru Curse'**
  String get youAreAvailable;

  /// No description provided for @newRidesWillAppear.
  ///
  /// In ro, this message translates to:
  /// **'Cursele noi vor apărea pe hartă ca notificări interactive.'**
  String get newRidesWillAppear;

  /// No description provided for @waitingForPassengerConfirmation.
  ///
  /// In ro, this message translates to:
  /// **'Aștepți confirmarea pasagerului'**
  String get waitingForPassengerConfirmation;

  /// No description provided for @confirmedGoToPassenger.
  ///
  /// In ro, this message translates to:
  /// **'Confirmată - Mergi spre pasager'**
  String get confirmedGoToPassenger;

  /// No description provided for @earningsTodayShort.
  ///
  /// In ro, this message translates to:
  /// **'Fapte Bune'**
  String get earningsTodayShort;

  /// No description provided for @completedRidesToday.
  ///
  /// In ro, this message translates to:
  /// **'Vecini ajutați azi'**
  String get completedRidesToday;

  /// No description provided for @ridesTodayShort.
  ///
  /// In ro, this message translates to:
  /// **'Ajutor'**
  String get ridesTodayShort;

  /// No description provided for @averageRatingShort.
  ///
  /// In ro, this message translates to:
  /// **'Rating'**
  String get averageRatingShort;

  /// No description provided for @errorGeneratingReport.
  ///
  /// In ro, this message translates to:
  /// **'Eroare la generarea raportului: {error}'**
  String errorGeneratingReport(String error);

  /// No description provided for @noRidesTodayForReport.
  ///
  /// In ro, this message translates to:
  /// **'Nu există curse finalizate astăzi pentru raport.'**
  String get noRidesTodayForReport;

  /// No description provided for @safetyCenter.
  ///
  /// In ro, this message translates to:
  /// **'Centrul de Siguranță'**
  String get safetyCenter;

  /// No description provided for @addContact.
  ///
  /// In ro, this message translates to:
  /// **'Adaugă contact'**
  String get addContact;

  /// No description provided for @emergencyAssistanceButton.
  ///
  /// In ro, this message translates to:
  /// **'Butonul de Asistență de Urgență'**
  String get emergencyAssistanceButton;

  /// No description provided for @emergencyAssistanceButtonDesc.
  ///
  /// In ro, this message translates to:
  /// **'În timpul oricărei curse, aveți la dispoziție butonul 112 în colțul ecranului pentru a contacta rapid serviciile de urgență.'**
  String get emergencyAssistanceButtonDesc;

  /// No description provided for @tripSharing.
  ///
  /// In ro, this message translates to:
  /// **'Partajarea Traseului'**
  String get tripSharing;

  /// No description provided for @tripSharingDesc.
  ///
  /// In ro, this message translates to:
  /// **'Puteți partaja detaliile cursei și traseul în timp real cu prietenii sau familia pentru un plus de siguranță.'**
  String get tripSharingDesc;

  /// No description provided for @verifiedDrivers.
  ///
  /// In ro, this message translates to:
  /// **'Șoferi Verificați'**
  String get verifiedDrivers;

  /// No description provided for @verifiedDriversDesc.
  ///
  /// In ro, this message translates to:
  /// **'Toți șoferii parteneri trec printr-un proces riguros de verificare a documentelor și a istoricului pentru a asigura siguranța dumneavoastră.'**
  String get verifiedDriversDesc;

  /// No description provided for @reportIncidentTitle.
  ///
  /// In ro, this message translates to:
  /// **'Raportarea unui Incident'**
  String get reportIncidentTitle;

  /// No description provided for @reportIncidentDesc.
  ///
  /// In ro, this message translates to:
  /// **'Dacă întâmpinați orice problemă de siguranță, o puteți raporta direct din aplicație, din secțiunea Ajutor, iar echipa noastră va investiga prompt.'**
  String get reportIncidentDesc;

  /// No description provided for @noTrustedContactsYet.
  ///
  /// In ro, this message translates to:
  /// **'Nu ați adăugat încă persoane de încredere.'**
  String get noTrustedContactsYet;

  /// No description provided for @addFamilyFriends.
  ///
  /// In ro, this message translates to:
  /// **'Adăugați rapid familia sau prietenii care vor primi notificări atunci când partajați o cursă.'**
  String get addFamilyFriends;

  /// No description provided for @sendTestMessage.
  ///
  /// In ro, this message translates to:
  /// **'Trimite mesaj de test'**
  String get sendTestMessage;

  /// No description provided for @contactRemoved.
  ///
  /// In ro, this message translates to:
  /// **'Contactul {name} a fost eliminat.'**
  String contactRemoved(String name);

  /// No description provided for @couldNotOpenMessages.
  ///
  /// In ro, this message translates to:
  /// **'Nu am putut deschide aplicația de mesaje pentru acest contact.'**
  String get couldNotOpenMessages;

  /// No description provided for @testMessageBody.
  ///
  /// In ro, this message translates to:
  /// **'Te-am setat ca persoană de încredere în Nabour. Voi partaja călătoriile active când am nevoie de ajutor.'**
  String get testMessageBody;

  /// No description provided for @voiceSystemActive.
  ///
  /// In ro, this message translates to:
  /// **'Sistemul vocal este activ'**
  String get voiceSystemActive;

  /// No description provided for @voiceSystemNotActive.
  ///
  /// In ro, this message translates to:
  /// **'Sistemul vocal nu este activ'**
  String get voiceSystemNotActive;

  /// No description provided for @canUseVoiceCommands.
  ///
  /// In ro, this message translates to:
  /// **'Puteți folosi comenzi vocale pentru a rezerva curse'**
  String get canUseVoiceCommands;

  /// No description provided for @checkMicrophonePermissions.
  ///
  /// In ro, this message translates to:
  /// **'Verificați permisiunile pentru microfon'**
  String get checkMicrophonePermissions;

  /// No description provided for @activate.
  ///
  /// In ro, this message translates to:
  /// **'Activează'**
  String get activate;

  /// No description provided for @basicMode.
  ///
  /// In ro, this message translates to:
  /// **'Basic Mode'**
  String get basicMode;

  /// No description provided for @continuous.
  ///
  /// In ro, this message translates to:
  /// **'Continuous'**
  String get continuous;

  /// No description provided for @on.
  ///
  /// In ro, this message translates to:
  /// **'ON'**
  String get on;

  /// No description provided for @off.
  ///
  /// In ro, this message translates to:
  /// **'OFF'**
  String get off;

  /// No description provided for @generalSettings.
  ///
  /// In ro, this message translates to:
  /// **'Setări Generale'**
  String get generalSettings;

  /// No description provided for @continuousListeningSubtitle.
  ///
  /// In ro, this message translates to:
  /// **'Ascultă continuu pentru comenzi vocale'**
  String get continuousListeningSubtitle;

  /// No description provided for @voicePreferences.
  ///
  /// In ro, this message translates to:
  /// **'Preferințe Vocale'**
  String get voicePreferences;

  /// No description provided for @speechRate.
  ///
  /// In ro, this message translates to:
  /// **'Viteza de vorbire'**
  String get speechRate;

  /// No description provided for @percentOfNormalSpeed.
  ///
  /// In ro, this message translates to:
  /// **'{percent}% din viteza normală'**
  String percentOfNormalSpeed(int percent);

  /// No description provided for @volume.
  ///
  /// In ro, this message translates to:
  /// **'Volumul'**
  String get volume;

  /// No description provided for @percentOfMaxVolume.
  ///
  /// In ro, this message translates to:
  /// **'{percent}% din volumul maxim'**
  String percentOfMaxVolume(int percent);

  /// No description provided for @pitch.
  ///
  /// In ro, this message translates to:
  /// **'Tonul'**
  String get pitch;

  /// No description provided for @lowerPitch.
  ///
  /// In ro, this message translates to:
  /// **'Ton mai jos'**
  String get lowerPitch;

  /// No description provided for @normalPitch.
  ///
  /// In ro, this message translates to:
  /// **'Ton normal'**
  String get normalPitch;

  /// No description provided for @higherPitch.
  ///
  /// In ro, this message translates to:
  /// **'Ton mai înalt'**
  String get higherPitch;

  /// No description provided for @german.
  ///
  /// In ro, this message translates to:
  /// **'Deutsch'**
  String get german;

  /// No description provided for @french.
  ///
  /// In ro, this message translates to:
  /// **'Français'**
  String get french;

  /// No description provided for @spanish.
  ///
  /// In ro, this message translates to:
  /// **'Español'**
  String get spanish;

  /// No description provided for @italian.
  ///
  /// In ro, this message translates to:
  /// **'Italiano'**
  String get italian;

  /// No description provided for @advancedVoiceFeatures.
  ///
  /// In ro, this message translates to:
  /// **'Funcții Vocale Avansate'**
  String get advancedVoiceFeatures;

  /// No description provided for @voiceCommandTraining.
  ///
  /// In ro, this message translates to:
  /// **'Antrenare comenzi vocale'**
  String get voiceCommandTraining;

  /// No description provided for @voiceCommandTrainingSubtitle.
  ///
  /// In ro, this message translates to:
  /// **'Îmbunătățește recunoașterea comenzilor'**
  String get voiceCommandTrainingSubtitle;

  /// No description provided for @customVoiceProfile.
  ///
  /// In ro, this message translates to:
  /// **'Profil vocal personalizat'**
  String get customVoiceProfile;

  /// No description provided for @customVoiceProfileSubtitle.
  ///
  /// In ro, this message translates to:
  /// **'Adaptează sistemul la vocea dvs'**
  String get customVoiceProfileSubtitle;

  /// No description provided for @multiLanguageSupportSubtitle.
  ///
  /// In ro, this message translates to:
  /// **'Comutați între limbi în timpul conversației'**
  String get multiLanguageSupportSubtitle;

  /// No description provided for @advancedSettings.
  ///
  /// In ro, this message translates to:
  /// **'Setări Avansate'**
  String get advancedSettings;

  /// No description provided for @testMicrophone.
  ///
  /// In ro, this message translates to:
  /// **'Testează microfonul'**
  String get testMicrophone;

  /// No description provided for @testMicrophoneSubtitle.
  ///
  /// In ro, this message translates to:
  /// **'Verifică dacă microfonul funcționează corect'**
  String get testMicrophoneSubtitle;

  /// No description provided for @testSound.
  ///
  /// In ro, this message translates to:
  /// **'Testează sunetul'**
  String get testSound;

  /// No description provided for @testSoundSubtitle.
  ///
  /// In ro, this message translates to:
  /// **'Verifică dacă sunetul funcționează corect'**
  String get testSoundSubtitle;

  /// No description provided for @testRecognition.
  ///
  /// In ro, this message translates to:
  /// **'Testează recunoașterea'**
  String get testRecognition;

  /// No description provided for @testRecognitionSubtitle.
  ///
  /// In ro, this message translates to:
  /// **'Verifică recunoașterea vocală'**
  String get testRecognitionSubtitle;

  /// No description provided for @voiceCommandsHelp.
  ///
  /// In ro, this message translates to:
  /// **'Ajutor comenzi vocale'**
  String get voiceCommandsHelp;

  /// No description provided for @voiceCommandsHelpSubtitle.
  ///
  /// In ro, this message translates to:
  /// **'Lista completă de comenzi disponibile'**
  String get voiceCommandsHelpSubtitle;

  /// No description provided for @privacySettings.
  ///
  /// In ro, this message translates to:
  /// **'Confidențialitate'**
  String get privacySettings;

  /// No description provided for @privacySettingsSubtitle.
  ///
  /// In ro, this message translates to:
  /// **'Gestionați datele vocale și confidențialitatea'**
  String get privacySettingsSubtitle;

  /// No description provided for @analyticsAndImprovements.
  ///
  /// In ro, this message translates to:
  /// **'Analiză și îmbunătățiri'**
  String get analyticsAndImprovements;

  /// No description provided for @analyticsAndImprovementsSubtitle.
  ///
  /// In ro, this message translates to:
  /// **'Gestionați analiza vocală pentru îmbunătățiri'**
  String get analyticsAndImprovementsSubtitle;

  /// No description provided for @saveSettings.
  ///
  /// In ro, this message translates to:
  /// **'Salvează Setările'**
  String get saveSettings;

  /// No description provided for @voiceSystemActivatedSuccessfully.
  ///
  /// In ro, this message translates to:
  /// **'Sistemul vocal a fost activat cu succes!'**
  String get voiceSystemActivatedSuccessfully;

  /// No description provided for @errorActivatingVoiceSystem.
  ///
  /// In ro, this message translates to:
  /// **'Eroare la activarea sistemului vocal: {error}'**
  String errorActivatingVoiceSystem(String error);

  /// No description provided for @activateVoiceSystemFirst.
  ///
  /// In ro, this message translates to:
  /// **'Activează mai întâi sistemul vocal.'**
  String get activateVoiceSystemFirst;

  /// No description provided for @errorTestingMicrophone.
  ///
  /// In ro, this message translates to:
  /// **'Eroare la testarea microfonului: {error}'**
  String errorTestingMicrophone(String error);

  /// No description provided for @errorTestingSound.
  ///
  /// In ro, this message translates to:
  /// **'Eroare la testarea sunetului: {error}'**
  String errorTestingSound(String error);

  /// No description provided for @errorTestingRecognition.
  ///
  /// In ro, this message translates to:
  /// **'Eroare la testarea recunoașterii: {error}'**
  String errorTestingRecognition(String error);

  /// No description provided for @voiceCommandTrainingTitle.
  ///
  /// In ro, this message translates to:
  /// **'Antrenare Comenzi Vocale'**
  String get voiceCommandTrainingTitle;

  /// No description provided for @voiceCommandTrainingContent.
  ///
  /// In ro, this message translates to:
  /// **'Antrenarea va îmbunătăți recunoașterea comenzilor vocale. Vă va fi cerut să repetați comenzi multiple ori pentru a crea un profil vocal personalizat.'**
  String get voiceCommandTrainingContent;

  /// No description provided for @later.
  ///
  /// In ro, this message translates to:
  /// **'Mai târziu'**
  String get later;

  /// No description provided for @startTraining.
  ///
  /// In ro, this message translates to:
  /// **'Începe Antrenarea'**
  String get startTraining;

  /// No description provided for @trainingStepsTitle.
  ///
  /// In ro, this message translates to:
  /// **'Pași Antrenare'**
  String get trainingStepsTitle;

  /// No description provided for @repeatCommand1.
  ///
  /// In ro, this message translates to:
  /// **'1. Repetați comanda \"Vreau o cursă\" de 3 ori'**
  String get repeatCommand1;

  /// No description provided for @repeatCommand2.
  ///
  /// In ro, this message translates to:
  /// **'2. Repetați comanda \"Cursă economică\" de 3 ori'**
  String get repeatCommand2;

  /// No description provided for @repeatCommand3.
  ///
  /// In ro, this message translates to:
  /// **'3. Repetați comanda \"Anulează cursă\" de 3 ori'**
  String get repeatCommand3;

  /// No description provided for @repeatCommand4.
  ///
  /// In ro, this message translates to:
  /// **'4. Repetați comanda \"Ajutor\" de 3 ori'**
  String get repeatCommand4;

  /// No description provided for @trainingWillTakeApprox.
  ///
  /// In ro, this message translates to:
  /// **'Antrenarea va dura aproximativ 5 minute.'**
  String get trainingWillTakeApprox;

  /// No description provided for @customVoiceProfileTitle.
  ///
  /// In ro, this message translates to:
  /// **'Profil Vocal Personalizat'**
  String get customVoiceProfileTitle;

  /// No description provided for @customVoiceProfileContent.
  ///
  /// In ro, this message translates to:
  /// **'Creați un profil vocal personalizat pentru a îmbunătăți recunoașterea. Sistemul va învăța să vă recunoască vocea și să se adapteze la accentul dvs.'**
  String get customVoiceProfileContent;

  /// No description provided for @createProfile.
  ///
  /// In ro, this message translates to:
  /// **'Creează Profil'**
  String get createProfile;

  /// No description provided for @multiLanguageSettingsTitle.
  ///
  /// In ro, this message translates to:
  /// **'Suport Multi-limbă'**
  String get multiLanguageSettingsTitle;

  /// No description provided for @primaryLanguage.
  ///
  /// In ro, this message translates to:
  /// **'Limba principală: Română'**
  String get primaryLanguage;

  /// No description provided for @secondaryLanguages.
  ///
  /// In ro, this message translates to:
  /// **'Limbi secundare:'**
  String get secondaryLanguages;

  /// No description provided for @switchBetweenLanguages.
  ///
  /// In ro, this message translates to:
  /// **'Puteți comuta între limbi spunând \"Switch to English\" sau \"Schimbă în română\"'**
  String get switchBetweenLanguages;

  /// No description provided for @availableVoiceCommandsTitle.
  ///
  /// In ro, this message translates to:
  /// **'Comenzi Vocale Disponibile'**
  String get availableVoiceCommandsTitle;

  /// No description provided for @privacySettingsTitle.
  ///
  /// In ro, this message translates to:
  /// **'Confidențialitate Vocală'**
  String get privacySettingsTitle;

  /// No description provided for @privacySettingsLabel.
  ///
  /// In ro, this message translates to:
  /// **'Setări confidențialitate:'**
  String get privacySettingsLabel;

  /// No description provided for @saveVoiceHistory.
  ///
  /// In ro, this message translates to:
  /// **'Salvează istoricul vocal'**
  String get saveVoiceHistory;

  /// No description provided for @saveVoiceHistorySubtitle.
  ///
  /// In ro, this message translates to:
  /// **'Stochează comenzile vocale pentru îmbunătățirea serviciului'**
  String get saveVoiceHistorySubtitle;

  /// No description provided for @anonymousAnalysis.
  ///
  /// In ro, this message translates to:
  /// **'Analiză anonimă'**
  String get anonymousAnalysis;

  /// No description provided for @anonymousAnalysisSubtitle.
  ///
  /// In ro, this message translates to:
  /// **'Permite analiza anonimă pentru îmbunătățirea recunoașterii'**
  String get anonymousAnalysisSubtitle;

  /// No description provided for @cloudSync.
  ///
  /// In ro, this message translates to:
  /// **'Sincronizare cloud'**
  String get cloudSync;

  /// No description provided for @cloudSyncSubtitle.
  ///
  /// In ro, this message translates to:
  /// **'Sincronizează preferințele vocale între dispozitive'**
  String get cloudSyncSubtitle;

  /// No description provided for @voiceDataProcessedLocally.
  ///
  /// In ro, this message translates to:
  /// **'Datele vocale sunt procesate local pe dispozitivul dvs pentru confidențialitate maximă.'**
  String get voiceDataProcessedLocally;

  /// No description provided for @analyticsSettingsTitle.
  ///
  /// In ro, this message translates to:
  /// **'Analiză și Îmbunătățiri'**
  String get analyticsSettingsTitle;

  /// No description provided for @analyticsSettingsLabel.
  ///
  /// In ro, this message translates to:
  /// **'Setări analiză:'**
  String get analyticsSettingsLabel;

  /// No description provided for @improveRecognition.
  ///
  /// In ro, this message translates to:
  /// **'Îmbunătățire recunoaștere'**
  String get improveRecognition;

  /// No description provided for @improveRecognitionSubtitle.
  ///
  /// In ro, this message translates to:
  /// **'Permite analiza pentru îmbunătățirea recunoașterii vocale'**
  String get improveRecognitionSubtitle;

  /// No description provided for @usageStatistics.
  ///
  /// In ro, this message translates to:
  /// **'Statistici utilizare'**
  String get usageStatistics;

  /// No description provided for @usageStatisticsSubtitle.
  ///
  /// In ro, this message translates to:
  /// **'Colectează statistici despre utilizarea funcțiilor vocale'**
  String get usageStatisticsSubtitle;

  /// No description provided for @errorReporting.
  ///
  /// In ro, this message translates to:
  /// **'Raportare erori'**
  String get errorReporting;

  /// No description provided for @errorReportingSubtitle.
  ///
  /// In ro, this message translates to:
  /// **'Raportează automat erorile vocale pentru rezolvare'**
  String get errorReportingSubtitle;

  /// No description provided for @allDataAnonymized.
  ///
  /// In ro, this message translates to:
  /// **'Toate datele sunt anonimizate și nu conțin informații personale.'**
  String get allDataAnonymized;

  /// No description provided for @advancedHelpTitle.
  ///
  /// In ro, this message translates to:
  /// **'Ajutor Avansat'**
  String get advancedHelpTitle;

  /// No description provided for @aiSpeaking.
  ///
  /// In ro, this message translates to:
  /// **'🗣️ AI VORBEȘTE\n\nVă rog ascultați...'**
  String get aiSpeaking;

  /// No description provided for @aiListening.
  ///
  /// In ro, this message translates to:
  /// **'🎤 AI ASCULTĂ\n\nVORBIȚI ACUM!'**
  String get aiListening;

  /// No description provided for @aiProcessing.
  ///
  /// In ro, this message translates to:
  /// **'🧠 AI PROCESEAZĂ\n\nVă rog așteptați...'**
  String get aiProcessing;

  /// No description provided for @waitingForResponse.
  ///
  /// In ro, this message translates to:
  /// **'AȘTEPT RĂSPUNS'**
  String get waitingForResponse;

  /// No description provided for @voiceAssistant.
  ///
  /// In ro, this message translates to:
  /// **'ASISTENT VOCAL'**
  String get voiceAssistant;

  /// No description provided for @pleaseListenToResponse.
  ///
  /// In ro, this message translates to:
  /// **'Vă rog ascultați răspunsul...'**
  String get pleaseListenToResponse;

  /// No description provided for @speakNow.
  ///
  /// In ro, this message translates to:
  /// **'VORBIȚI ACUM!'**
  String get speakNow;

  /// No description provided for @processingInformation.
  ///
  /// In ro, this message translates to:
  /// **'Procesez informația...'**
  String get processingInformation;

  /// No description provided for @pleaseWait.
  ///
  /// In ro, this message translates to:
  /// **'Vă rog așteptați...'**
  String get pleaseWait;

  /// No description provided for @pressButtonToStart.
  ///
  /// In ro, this message translates to:
  /// **'Apăsați butonul pentru a începe'**
  String get pressButtonToStart;

  /// No description provided for @newRideAudioUnavailable.
  ///
  /// In ro, this message translates to:
  /// **'🚨 CURSĂ NOUĂ! (Audio indisponibil)'**
  String get newRideAudioUnavailable;

  /// No description provided for @emergencyAssistanceUsageContent.
  ///
  /// In ro, this message translates to:
  /// **'Funcția de urgență vă permite să:'**
  String get emergencyAssistanceUsageContent;

  /// No description provided for @call112Quickly.
  ///
  /// In ro, this message translates to:
  /// **'• Apelați rapid 112'**
  String get call112Quickly;

  /// No description provided for @sendLocationToEmergencyContact.
  ///
  /// In ro, this message translates to:
  /// **'• Trimiteți locația dvs. unui contact de urgență'**
  String get sendLocationToEmergencyContact;

  /// No description provided for @reportIncidentToSafetyTeam.
  ///
  /// In ro, this message translates to:
  /// **'• Raportați un incident către echipa de siguranță'**
  String get reportIncidentToSafetyTeam;

  /// No description provided for @useOnlyRealEmergencies.
  ///
  /// In ro, this message translates to:
  /// **'Utilizați această funcție doar în situații reale de urgență.'**
  String get useOnlyRealEmergencies;

  /// No description provided for @reportAccidentOrUnpleasantEvent.
  ///
  /// In ro, this message translates to:
  /// **'Raportează accident sau eveniment neplăcut'**
  String get reportAccidentOrUnpleasantEvent;

  /// No description provided for @toReportIncident.
  ///
  /// In ro, this message translates to:
  /// **'Pentru a raporta un incident:'**
  String get toReportIncident;

  /// No description provided for @ensureYourSafety.
  ///
  /// In ro, this message translates to:
  /// **'1. Asigurați-vă de siguranța dvs'**
  String get ensureYourSafety;

  /// No description provided for @useEmergencyFunctionInApp.
  ///
  /// In ro, this message translates to:
  /// **'2. Folosiți funcția de urgență din aplicație'**
  String get useEmergencyFunctionInApp;

  /// No description provided for @describeInDetail.
  ///
  /// In ro, this message translates to:
  /// **'3. Descrieți detaliat ce s-a întâmplat'**
  String get describeInDetail;

  /// No description provided for @addPhotosIfPossible.
  ///
  /// In ro, this message translates to:
  /// **'4. Adăugați fotografii dacă este posibil'**
  String get addPhotosIfPossible;

  /// No description provided for @cooperateWithInvestigationTeam.
  ///
  /// In ro, this message translates to:
  /// **'5. Cooperați cu echipa de investigații'**
  String get cooperateWithInvestigationTeam;

  /// No description provided for @falseReportsCanLead.
  ///
  /// In ro, this message translates to:
  /// **'Raporturile false pot duce la suspendarea contului.'**
  String get falseReportsCanLead;

  /// No description provided for @cleaningOrDamageFee.
  ///
  /// In ro, this message translates to:
  /// **'Taxă curățenie sau daune'**
  String get cleaningOrDamageFee;

  /// No description provided for @cleaningFeeTitle.
  ///
  /// In ro, this message translates to:
  /// **'🧹 Taxa pentru curățenie și daune în aplicația Nabour'**
  String get cleaningFeeTitle;

  /// No description provided for @cleaningFeeIntro.
  ///
  /// In ro, this message translates to:
  /// **'La Nabour, ne dorim ca toate călătoriile să fie plăcute și confortabile pentru toți utilizatorii noștri. Din acest motiv, avem o politică clară privind curățenia vehiculelor și responsabilitatea pentru eventualele daune.'**
  String get cleaningFeeIntro;

  /// No description provided for @whenFeeApplied.
  ///
  /// In ro, this message translates to:
  /// **'🚨 Când se aplică taxa pentru curățenie sau daune?'**
  String get whenFeeApplied;

  /// No description provided for @spillingLiquids.
  ///
  /// In ro, this message translates to:
  /// **'1. Vărsarea de lichide în vehicul (apă, cafea, sucuri, alcool, etc.)'**
  String get spillingLiquids;

  /// No description provided for @soilingSeatsOrFloor.
  ///
  /// In ro, this message translates to:
  /// **'2. Murdărirea scaunelor sau podelei cu noroi, mâncare sau alte substanțe'**
  String get soilingSeatsOrFloor;

  /// No description provided for @vomitingInVehicle.
  ///
  /// In ro, this message translates to:
  /// **'3. Vărsături în vehicul'**
  String get vomitingInVehicle;

  /// No description provided for @smokingInVehicle.
  ///
  /// In ro, this message translates to:
  /// **'4. Fumatul în vehicul (inclusiv țigări electronice)'**
  String get smokingInVehicle;

  /// No description provided for @damagingVehicleElements.
  ///
  /// In ro, this message translates to:
  /// **'5. Deteriorarea unor elemente din vehicul (scaune, centuri, etc.)'**
  String get damagingVehicleElements;

  /// No description provided for @leavingFoodOrTrash.
  ///
  /// In ro, this message translates to:
  /// **'6. Lăsarea de resturi de mâncare sau gunoi în vehicul'**
  String get leavingFoodOrTrash;

  /// No description provided for @persistentOdors.
  ///
  /// In ro, this message translates to:
  /// **'7. Mirosuri persistente care necesită dezodorizare profesională'**
  String get persistentOdors;

  /// No description provided for @howFeeProcessWorks.
  ///
  /// In ro, this message translates to:
  /// **'⚙️ Cum funcționează procesul de aplicare a taxei?'**
  String get howFeeProcessWorks;

  /// No description provided for @driverDocumentsDamage.
  ///
  /// In ro, this message translates to:
  /// **'1. Șoferul documentează paguba prin fotografii imediat după cursă'**
  String get driverDocumentsDamage;

  /// No description provided for @driverReportsIncident.
  ///
  /// In ro, this message translates to:
  /// **'2. Șoferul raportează incidentul prin aplicația Nabour în maxim 24 de ore'**
  String get driverReportsIncident;

  /// No description provided for @teamAnalyzesReport.
  ///
  /// In ro, this message translates to:
  /// **'3. Echipa noastră analizează raportul și fotografiile'**
  String get teamAnalyzesReport;

  /// No description provided for @ifFeeJustified.
  ///
  /// In ro, this message translates to:
  /// **'4. În cazul în care taxa este justificată, pasagerul va fi notificat'**
  String get ifFeeJustified;

  /// No description provided for @feeChargedAutomatically.
  ///
  /// In ro, this message translates to:
  /// **'5. Taxa va fi prelevată automat din metoda de plată asociată contului'**
  String get feeChargedAutomatically;

  /// No description provided for @passengerCanContest.
  ///
  /// In ro, this message translates to:
  /// **'6. Pasagerul poate contesta taxa în termen de 48 de ore de la notificare'**
  String get passengerCanContest;

  /// No description provided for @feeAmounts.
  ///
  /// In ro, this message translates to:
  /// **'💰 Cuantumul taxelor'**
  String get feeAmounts;

  /// No description provided for @lightCleaning.
  ///
  /// In ro, this message translates to:
  /// **'🧽 Curățenie ușoară: 50-100 RON'**
  String get lightCleaning;

  /// No description provided for @wipingAndVacuuming.
  ///
  /// In ro, this message translates to:
  /// **'• Ștergerea și aspirarea urmelor ușoare de murdărie'**
  String get wipingAndVacuuming;

  /// No description provided for @removingSmallStains.
  ///
  /// In ro, this message translates to:
  /// **'• Îndepărtarea petelor mici de pe scaune'**
  String get removingSmallStains;

  /// No description provided for @intensiveCleaning.
  ///
  /// In ro, this message translates to:
  /// **'🧼 Curățenie intensivă: 150-300 RON'**
  String get intensiveCleaning;

  /// No description provided for @professionalCleaning.
  ///
  /// In ro, this message translates to:
  /// **'• Curățare profesională pentru pete mari sau mirosuri'**
  String get professionalCleaning;

  /// No description provided for @deodorizationAndSpecialTreatments.
  ///
  /// In ro, this message translates to:
  /// **'• Dezodorizare și tratamente speciale'**
  String get deodorizationAndSpecialTreatments;

  /// No description provided for @repairsAndReplacements.
  ///
  /// In ro, this message translates to:
  /// **'Reparații și înlocuiri'**
  String get repairsAndReplacements;

  /// No description provided for @replacingDamagedSeatCovers.
  ///
  /// In ro, this message translates to:
  /// **'• Înlocuirea huselor de scaune deteriorate'**
  String get replacingDamagedSeatCovers;

  /// No description provided for @repairingDamagedComponents.
  ///
  /// In ro, this message translates to:
  /// **'• Repararea componentelor deteriorate'**
  String get repairingDamagedComponents;

  /// No description provided for @costsDependOnSeverity.
  ///
  /// In ro, this message translates to:
  /// **'• Costurile variază în funcție de gravitate'**
  String get costsDependOnSeverity;

  /// No description provided for @yourRightsAsPassenger.
  ///
  /// In ro, this message translates to:
  /// **'⚖️ Drepturile dvs. ca pasager'**
  String get yourRightsAsPassenger;

  /// No description provided for @rightToReceivePhotos.
  ///
  /// In ro, this message translates to:
  /// **'✅ Aveți dreptul să primiți fotografiile și detaliile complete ale daunelor'**
  String get rightToReceivePhotos;

  /// No description provided for @canContestFee.
  ///
  /// In ro, this message translates to:
  /// **'✅ Puteți contesta taxa în termen de 48 de ore prin aplicație'**
  String get canContestFee;

  /// No description provided for @rightToObjectiveInvestigation.
  ///
  /// In ro, this message translates to:
  /// **'✅ Aveți dreptul la o investigație obiectivă a cazului dvs.'**
  String get rightToObjectiveInvestigation;

  /// No description provided for @ifContestationJustified.
  ///
  /// In ro, this message translates to:
  /// **'✅ În cazul contestațiilor justificate, taxa va fi returnată integral'**
  String get ifContestationJustified;

  /// No description provided for @howToAvoidFee.
  ///
  /// In ro, this message translates to:
  /// **'🛡️ Cum să evitați taxa pentru curățenie sau daune'**
  String get howToAvoidFee;

  /// No description provided for @doNotConsumeFood.
  ///
  /// In ro, this message translates to:
  /// **'• Nu consumați mâncare sau băuturi în vehicul'**
  String get doNotConsumeFood;

  /// No description provided for @checkShoesNotDirty.
  ///
  /// In ro, this message translates to:
  /// **'• Verificați că încălțămintea nu este murdară înainte de a urca'**
  String get checkShoesNotDirty;

  /// No description provided for @notifyDriverIfFeelingUnwell.
  ///
  /// In ro, this message translates to:
  /// **'• Anunțați șoferul dacă vă simțiți rău și aveți nevoie de o pauză'**
  String get notifyDriverIfFeelingUnwell;

  /// No description provided for @doNotSmokeInVehicle.
  ///
  /// In ro, this message translates to:
  /// **'• Nu fumați în vehicul'**
  String get doNotSmokeInVehicle;

  /// No description provided for @treatVehicleWithRespect.
  ///
  /// In ro, this message translates to:
  /// **'• Tratați vehiculul cu același respect ca și cum ar fi al dvs.'**
  String get treatVehicleWithRespect;

  /// No description provided for @takeTrashWithYou.
  ///
  /// In ro, this message translates to:
  /// **'• Duceți gunoiul cu dvs. la sfârșitul călătoriei'**
  String get takeTrashWithYou;

  /// No description provided for @contestationProcess.
  ///
  /// In ro, this message translates to:
  /// **'📝 Procesul de contestare'**
  String get contestationProcess;

  /// No description provided for @accessRideHistory.
  ///
  /// In ro, this message translates to:
  /// **'1. Accesați secțiunea \"Istoric călătorii\" din aplicație'**
  String get accessRideHistory;

  /// No description provided for @selectRideForContestation.
  ///
  /// In ro, this message translates to:
  /// **'2. Selectați călătoria pentru care contestați taxa'**
  String get selectRideForContestation;

  /// No description provided for @pressContestFee.
  ///
  /// In ro, this message translates to:
  /// **'3. Apăsați pe \"Contestă taxa\" și completați formularul'**
  String get pressContestFee;

  /// No description provided for @addRelevantEvidence.
  ///
  /// In ro, this message translates to:
  /// **'4. Adăugați orice dovezi relevante (fotografii, explicații)'**
  String get addRelevantEvidence;

  /// No description provided for @teamWillReanalyze.
  ///
  /// In ro, this message translates to:
  /// **'5. Echipa noastră va reanaliza cazul în maxim 72 de ore'**
  String get teamWillReanalyze;

  /// No description provided for @receiveDetailedResponse.
  ///
  /// In ro, this message translates to:
  /// **'6. Veți primi un răspuns detaliat prin email și în aplicație'**
  String get receiveDetailedResponse;

  /// No description provided for @haveQuestionsOrNeedAssistance.
  ///
  /// In ro, this message translates to:
  /// **'📞 Aveți întrebări sau aveți nevoie de asistență?'**
  String get haveQuestionsOrNeedAssistance;

  /// No description provided for @emailSupport.
  ///
  /// In ro, this message translates to:
  /// **'📧 Email: suport@nabour.ro'**
  String get emailSupport;

  /// No description provided for @phoneSupport.
  ///
  /// In ro, this message translates to:
  /// **'📱 Telefon: +40 700 NABOUR'**
  String get phoneSupport;

  /// No description provided for @chatInApp.
  ///
  /// In ro, this message translates to:
  /// **'💬 Chat în aplicație: Secțiunea \"Ajutor\"'**
  String get chatInApp;

  /// No description provided for @scheduleSupport.
  ///
  /// In ro, this message translates to:
  /// **'🕒 Program: Luni-Duminică, 24/7'**
  String get scheduleSupport;

  /// No description provided for @importantToRemember.
  ///
  /// In ro, this message translates to:
  /// **'⚠️ Important de reținut'**
  String get importantToRemember;

  /// No description provided for @feeOnlyAppliedWithClearEvidence.
  ///
  /// In ro, this message translates to:
  /// **'Taxa pentru curățenie și daune se aplică doar în cazurile în care există dovezi clare ale deteriorării sau murdăririi vehiculului. Echipa Nabour analizează fiecare caz individual și se asigură că toate taxele sunt justificate și corecte.'**
  String get feeOnlyAppliedWithClearEvidence;

  /// No description provided for @howToActivateDriverMode.
  ///
  /// In ro, this message translates to:
  /// **'Cum activez modul șofer partener Nabour'**
  String get howToActivateDriverMode;

  /// No description provided for @toBecomeDriverPartner.
  ///
  /// In ro, this message translates to:
  /// **'Pentru a deveni șofer partener Nabour, urmează acești pași:'**
  String get toBecomeDriverPartner;

  /// No description provided for @checkConditions.
  ///
  /// In ro, this message translates to:
  /// **'1. Verifică condițiile'**
  String get checkConditions;

  /// No description provided for @validLicenseRequired.
  ///
  /// In ro, this message translates to:
  /// **'Trebuie să ai permis de conducere valabil, experiență de minim 2 ani și vârsta de minim 21 de ani.'**
  String get validLicenseRequired;

  /// No description provided for @prepareDocuments.
  ///
  /// In ro, this message translates to:
  /// **'2. Pregătește documentele'**
  String get prepareDocuments;

  /// No description provided for @documentsNeeded.
  ///
  /// In ro, this message translates to:
  /// **'Ai nevoie de: permis de conducere, carte de identitate, certificat de înmatriculare auto, ITP valabil și asigurarea RCA.'**
  String get documentsNeeded;

  /// No description provided for @completeApplication.
  ///
  /// In ro, this message translates to:
  /// **'3. Completează aplicația'**
  String get completeApplication;

  /// No description provided for @accessCareerSection.
  ///
  /// In ro, this message translates to:
  /// **'Accesează secțiunea \"Carieră\" din meniul principal și completează formularul online cu datele tale.'**
  String get accessCareerSection;

  /// No description provided for @submitDocuments.
  ///
  /// In ro, this message translates to:
  /// **'4. Transmite documentele'**
  String get submitDocuments;

  /// No description provided for @uploadClearPhotos.
  ///
  /// In ro, this message translates to:
  /// **'Încarcă fotografii clare cu toate documentele necesare prin platforma online.'**
  String get uploadClearPhotos;

  /// No description provided for @applicationVerification.
  ///
  /// In ro, this message translates to:
  /// **'5. Verificarea aplicației'**
  String get applicationVerification;

  /// No description provided for @teamWillVerify.
  ///
  /// In ro, this message translates to:
  /// **'Echipa noastră va verifica documentele în maxim 48 de ore lucrătoare.'**
  String get teamWillVerify;

  /// No description provided for @receiveActivationCode.
  ///
  /// In ro, this message translates to:
  /// **'6. Primește codul de activare'**
  String get receiveActivationCode;

  /// No description provided for @afterApproval.
  ///
  /// In ro, this message translates to:
  /// **'După aprobare, vei primi un cod unic prin email/SMS pentru activarea contului de șofer.'**
  String get afterApproval;

  /// No description provided for @activateAccount.
  ///
  /// In ro, this message translates to:
  /// **'7. Activează contul'**
  String get activateAccount;

  /// No description provided for @enterCodeInApp.
  ///
  /// In ro, this message translates to:
  /// **'Introdu codul în aplicație și începe să câștigi bani conducând!'**
  String get enterCodeInApp;

  /// No description provided for @usefulTip.
  ///
  /// In ro, this message translates to:
  /// **'💡 Sfat util:'**
  String get usefulTip;

  /// No description provided for @ensureDocumentsValid.
  ///
  /// In ro, this message translates to:
  /// **'Asigură-te că toate documentele sunt valabile și fotografiile sunt clare pentru o procesare rapidă.'**
  String get ensureDocumentsValid;

  /// No description provided for @ratesAndPayments.
  ///
  /// In ro, this message translates to:
  /// **'Tarife și plăți'**
  String get ratesAndPayments;

  /// No description provided for @ratesAndPaymentsInfo.
  ///
  /// In ro, this message translates to:
  /// **'Informații despre Tarife și Plăți'**
  String get ratesAndPaymentsInfo;

  /// No description provided for @ratesCalculatedAutomatically.
  ///
  /// In ro, this message translates to:
  /// **'• Tarifele sunt calculate automat în funcție de distanță și timp'**
  String get ratesCalculatedAutomatically;

  /// No description provided for @paymentMadeAutomatically.
  ///
  /// In ro, this message translates to:
  /// **'• Plata se face automat prin metoda salvată în cont'**
  String get paymentMadeAutomatically;

  /// No description provided for @canSeeRateDetails.
  ///
  /// In ro, this message translates to:
  /// **'• Puteți vedea detaliile tarifului înainte de a confirma cursa'**
  String get canSeeRateDetails;

  /// No description provided for @inCaseOfPaymentProblems.
  ///
  /// In ro, this message translates to:
  /// **'• În caz de probleme cu plata, contactați suportul'**
  String get inCaseOfPaymentProblems;

  /// No description provided for @forCurrentRatesDetails.
  ///
  /// In ro, this message translates to:
  /// **'Pentru detalii despre tarifele actuale, verificați în aplicație.'**
  String get forCurrentRatesDetails;

  /// No description provided for @deliveryOrderRequest.
  ///
  /// In ro, this message translates to:
  /// **'Solicitare comandă livrare'**
  String get deliveryOrderRequest;

  /// No description provided for @deliveryServices.
  ///
  /// In ro, this message translates to:
  /// **'Servicii de Livrare'**
  String get deliveryServices;

  /// No description provided for @currentlyFocusedOnTransport.
  ///
  /// In ro, this message translates to:
  /// **'Momentan, ne concentrăm pe serviciile de transport persoane.'**
  String get currentlyFocusedOnTransport;

  /// No description provided for @deliveryServicesAvailableSoon.
  ///
  /// In ro, this message translates to:
  /// **'Serviciile de livrare vor fi disponibile în viitorul apropiat.'**
  String get deliveryServicesAvailableSoon;

  /// No description provided for @weWillNotifyYou.
  ///
  /// In ro, this message translates to:
  /// **'Vă vom anunța când această funcție va fi activă!'**
  String get weWillNotifyYou;

  /// No description provided for @appFunctioningProblems.
  ///
  /// In ro, this message translates to:
  /// **'Probleme de funcționare a aplicației'**
  String get appFunctioningProblems;

  /// No description provided for @ifAppNotWorkingCorrectly.
  ///
  /// In ro, this message translates to:
  /// **'Dacă aplicația nu funcționează corect:'**
  String get ifAppNotWorkingCorrectly;

  /// No description provided for @updateAppToLatest.
  ///
  /// In ro, this message translates to:
  /// **'3. Actualizați aplicația la cea mai recentă versiune'**
  String get updateAppToLatest;

  /// No description provided for @restartPhone.
  ///
  /// In ro, this message translates to:
  /// **'4. Restartați telefonul'**
  String get restartPhone;

  /// No description provided for @reinstallAppIfPersists.
  ///
  /// In ro, this message translates to:
  /// **'5. Reinstalați aplicația dacă problema persistă'**
  String get reinstallAppIfPersists;

  /// No description provided for @ifProblemContinues.
  ///
  /// In ro, this message translates to:
  /// **'Dacă problema continuă, trimiteți-ne un raport prin suport.'**
  String get ifProblemContinues;

  /// No description provided for @forgotPassword.
  ///
  /// In ro, this message translates to:
  /// **'Am uitat parola'**
  String get forgotPassword;

  /// No description provided for @enterEmailAssociated.
  ///
  /// In ro, this message translates to:
  /// **'Introduceți adresa de email asociată contului dumneavoastră.'**
  String get enterEmailAssociated;

  /// No description provided for @enterValidEmail.
  ///
  /// In ro, this message translates to:
  /// **'Introduceți o adresă de email validă.'**
  String get enterValidEmail;

  /// No description provided for @sendingResetEmail.
  ///
  /// In ro, this message translates to:
  /// **'Se trimite emailul de resetare...'**
  String get sendingResetEmail;

  /// No description provided for @resetEmailSent.
  ///
  /// In ro, this message translates to:
  /// **'Un email de resetare a parolei a fost trimis. Verificați-vă inbox-ul (inclusiv folderul Spam)!'**
  String get resetEmailSent;

  /// No description provided for @errorSendingResetEmail.
  ///
  /// In ro, this message translates to:
  /// **'A apărut o eroare la trimiterea email-ului de resetare.'**
  String get errorSendingResetEmail;

  /// No description provided for @noAccountWithEmail.
  ///
  /// In ro, this message translates to:
  /// **'Nu există niciun cont cu această adresă de email.'**
  String get noAccountWithEmail;

  /// No description provided for @unexpectedError.
  ///
  /// In ro, this message translates to:
  /// **'Eroare neașteptată. Încercați din nou'**
  String get unexpectedError;

  /// No description provided for @resetPassword.
  ///
  /// In ro, this message translates to:
  /// **'Resetare Parolă'**
  String get resetPassword;

  /// No description provided for @applyNow.
  ///
  /// In ro, this message translates to:
  /// **'Aplică acum'**
  String get applyNow;

  /// No description provided for @contentComingSoon.
  ///
  /// In ro, this message translates to:
  /// **'Conținutul pentru acest subiect va fi disponibil în curând.'**
  String get contentComingSoon;

  /// No description provided for @joinTeam.
  ///
  /// In ro, this message translates to:
  /// **'Alătură-te echipei Nabour'**
  String get joinTeam;

  /// No description provided for @applyForDriver.
  ///
  /// In ro, this message translates to:
  /// **'Mașina mea'**
  String get applyForDriver;

  /// No description provided for @neighborhoodRequests.
  ///
  /// In ro, this message translates to:
  /// **'Cereri din cartier'**
  String get neighborhoodRequests;

  /// No description provided for @neighborhoodChat.
  ///
  /// In ro, this message translates to:
  /// **'Chat de cartier'**
  String get neighborhoodChat;

  /// No description provided for @activateDriverCode.
  ///
  /// In ro, this message translates to:
  /// **'Activare cod mod Șofer Nabour'**
  String get activateDriverCode;

  /// No description provided for @activateDriverCodeTitle.
  ///
  /// In ro, this message translates to:
  /// **'Activare Cod Șofer'**
  String get activateDriverCodeTitle;

  /// No description provided for @activateDriverCodeDescription.
  ///
  /// In ro, this message translates to:
  /// **'Introduceți codul de activare primit pentru a deveni șofer partener Nabour.'**
  String get activateDriverCodeDescription;

  /// No description provided for @enterActivationCode.
  ///
  /// In ro, this message translates to:
  /// **'Vă rugăm introduceți codul de activare.'**
  String get enterActivationCode;

  /// No description provided for @codeTooShort.
  ///
  /// In ro, this message translates to:
  /// **'Codul introdus este prea scurt. Verificați din nou.'**
  String get codeTooShort;

  /// No description provided for @validatingCode.
  ///
  /// In ro, this message translates to:
  /// **'Validez codul...'**
  String get validatingCode;

  /// No description provided for @codeActivatedSuccess.
  ///
  /// In ro, this message translates to:
  /// **'Codul a fost activat cu succes! Acum sunteți șofer.'**
  String get codeActivatedSuccess;

  /// No description provided for @codeInvalidOrUsed.
  ///
  /// In ro, this message translates to:
  /// **'Cod invalid sau deja utilizat. Vă rugăm verificați.'**
  String get codeInvalidOrUsed;

  /// No description provided for @errorValidatingCode.
  ///
  /// In ro, this message translates to:
  /// **'Eroare la validarea codului: {error}'**
  String errorValidatingCode(String error);

  /// No description provided for @lowDataMode.
  ///
  /// In ro, this message translates to:
  /// **'Mod date reduse'**
  String get lowDataMode;

  /// No description provided for @highContrastUI.
  ///
  /// In ro, this message translates to:
  /// **'Interfață contrast ridicat'**
  String get highContrastUI;

  /// No description provided for @assistantStatusOverlay.
  ///
  /// In ro, this message translates to:
  /// **'Suprapunere status asistent'**
  String get assistantStatusOverlay;

  /// No description provided for @performanceOverlay.
  ///
  /// In ro, this message translates to:
  /// **'Suprapunere performanță'**
  String get performanceOverlay;

  /// No description provided for @aiGreeting.
  ///
  /// In ro, this message translates to:
  /// **'Salut, unde doriți să mergeți?'**
  String get aiGreeting;

  /// No description provided for @aiSearchingDrivers.
  ///
  /// In ro, this message translates to:
  /// **'Caut șoferi disponibili...'**
  String get aiSearchingDrivers;

  /// No description provided for @aiSearchingDriversInArea.
  ///
  /// In ro, this message translates to:
  /// **'Caut șoferi disponibili în zonă...'**
  String get aiSearchingDriversInArea;

  /// No description provided for @aiDriverFound.
  ///
  /// In ro, this message translates to:
  /// **'Am găsit un șofer disponibil la {minutes} minute distanță.'**
  String aiDriverFound(int minutes);

  /// No description provided for @aiBestDriverSelected.
  ///
  /// In ro, this message translates to:
  /// **'Am selectat cel mai bun șofer pentru dumneavoastră. Trimit cererea de cursă...'**
  String get aiBestDriverSelected;

  /// No description provided for @aiNoDriversAvailable.
  ///
  /// In ro, this message translates to:
  /// **'Îmi pare rău, dar nu am găsit șoferi disponibili în zona dumneavoastră. Te rugăm să revii mai târziu.'**
  String get aiNoDriversAvailable;

  /// No description provided for @aiEverythingResolved.
  ///
  /// In ro, this message translates to:
  /// **'Perfect! Am rezolvat totul automat. Cererea dvs. de cursă a fost trimisă!'**
  String get aiEverythingResolved;

  /// No description provided for @subscriptionsTitle.
  ///
  /// In ro, this message translates to:
  /// **'Abonamente Nabour'**
  String get subscriptionsTitle;

  /// No description provided for @recommended.
  ///
  /// In ro, this message translates to:
  /// **'RECOMANDAT'**
  String get recommended;

  /// No description provided for @ronPerMonth.
  ///
  /// In ro, this message translates to:
  /// **'RON / lună'**
  String get ronPerMonth;

  /// No description provided for @planSelected.
  ///
  /// In ro, this message translates to:
  /// **'Ai selectat planul {plan}! (simulare)'**
  String planSelected(String plan);

  /// No description provided for @choosePlan.
  ///
  /// In ro, this message translates to:
  /// **'Alege Planul'**
  String get choosePlan;

  /// No description provided for @subscriptionBasicDescription.
  ///
  /// In ro, this message translates to:
  /// **'Pentru călătorii ocazionali.'**
  String get subscriptionBasicDescription;

  /// No description provided for @subscriptionPlusDescription.
  ///
  /// In ro, this message translates to:
  /// **'Cel mai popular plan.'**
  String get subscriptionPlusDescription;

  /// No description provided for @subscriptionPremiumDescription.
  ///
  /// In ro, this message translates to:
  /// **'Beneficii exclusive.'**
  String get subscriptionPremiumDescription;

  /// No description provided for @subscriptionBasicBenefit1.
  ///
  /// In ro, this message translates to:
  /// **'5% reducere la 10 curse/lună'**
  String get subscriptionBasicBenefit1;

  /// No description provided for @subscriptionBasicBenefit2.
  ///
  /// In ro, this message translates to:
  /// **'Anulare gratuită în 2 minute'**
  String get subscriptionBasicBenefit2;

  /// No description provided for @subscriptionPlusBenefit1.
  ///
  /// In ro, this message translates to:
  /// **'10% reducere la toate cursele'**
  String get subscriptionPlusBenefit1;

  /// No description provided for @subscriptionPlusBenefit2.
  ///
  /// In ro, this message translates to:
  /// **'Anulare gratuită în 5 minute'**
  String get subscriptionPlusBenefit2;

  /// No description provided for @subscriptionPlusBenefit3.
  ///
  /// In ro, this message translates to:
  /// **'Suport prioritar 24/7'**
  String get subscriptionPlusBenefit3;

  /// No description provided for @subscriptionPremiumBenefit1.
  ///
  /// In ro, this message translates to:
  /// **'15% reducere la toate cursele'**
  String get subscriptionPremiumBenefit1;

  /// No description provided for @subscriptionPremiumBenefit2.
  ///
  /// In ro, this message translates to:
  /// **'Anulare gratuită oricând'**
  String get subscriptionPremiumBenefit2;

  /// No description provided for @subscriptionPremiumBenefit3.
  ///
  /// In ro, this message translates to:
  /// **'Suport prioritar 24/7'**
  String get subscriptionPremiumBenefit3;

  /// No description provided for @subscriptionPremiumBenefit4.
  ///
  /// In ro, this message translates to:
  /// **'Acces la mașini premium'**
  String get subscriptionPremiumBenefit4;

  /// No description provided for @deleteConfirmation.
  ///
  /// In ro, this message translates to:
  /// **'Confirmare Ștergere'**
  String get deleteConfirmation;

  /// No description provided for @deleteRideConfirmation.
  ///
  /// In ro, this message translates to:
  /// **'Sunteți sigur că doriți să ștergeți definitiv cursa către \"{destination}\" din istoricul dumneavoastră? Această acțiune este ireversibilă.'**
  String deleteRideConfirmation(String destination);

  /// No description provided for @rideDeletedSuccess.
  ///
  /// In ro, this message translates to:
  /// **'Cursa a fost ștearsă cu succes!'**
  String get rideDeletedSuccess;

  /// No description provided for @errorLoadingRole.
  ///
  /// In ro, this message translates to:
  /// **'Eroare la încărcarea rolului: {error}'**
  String errorLoadingRole(String error);

  /// No description provided for @errorGeneric.
  ///
  /// In ro, this message translates to:
  /// **'Eroare'**
  String get errorGeneric;

  /// No description provided for @errorLoadingData.
  ///
  /// In ro, this message translates to:
  /// **'Eroare la încărcarea datelor'**
  String get errorLoadingData;

  /// No description provided for @errorDetails.
  ///
  /// In ro, this message translates to:
  /// **'Detalii: {error}'**
  String errorDetails(String error);

  /// No description provided for @retry.
  ///
  /// In ro, this message translates to:
  /// **'Reîncearcă'**
  String get retry;

  /// No description provided for @noRidesInPeriod.
  ///
  /// In ro, this message translates to:
  /// **'Nu aveți nicio cursă în perioada selectată.'**
  String get noRidesInPeriod;

  /// No description provided for @filterAll.
  ///
  /// In ro, this message translates to:
  /// **'Tot'**
  String get filterAll;

  /// No description provided for @filterLastMonth.
  ///
  /// In ro, this message translates to:
  /// **'Ultima Lună'**
  String get filterLastMonth;

  /// No description provided for @filterLast3Months.
  ///
  /// In ro, this message translates to:
  /// **'Ultimele 3 Luni'**
  String get filterLast3Months;

  /// No description provided for @filterThisYear.
  ///
  /// In ro, this message translates to:
  /// **'Anul Acesta'**
  String get filterThisYear;

  /// No description provided for @rideDate.
  ///
  /// In ro, this message translates to:
  /// **'Data: {date}'**
  String rideDate(String date);

  /// No description provided for @deleteRide.
  ///
  /// In ro, this message translates to:
  /// **'Șterge cursa'**
  String get deleteRide;

  /// No description provided for @asDriver.
  ///
  /// In ro, this message translates to:
  /// **'Ca Șofer'**
  String get asDriver;

  /// No description provided for @asPassenger.
  ///
  /// In ro, this message translates to:
  /// **'Ca Pasager'**
  String get asPassenger;

  /// No description provided for @errorLoadingUserRole.
  ///
  /// In ro, this message translates to:
  /// **'Eroare la încărcarea rolului utilizatorului.'**
  String get errorLoadingUserRole;

  /// No description provided for @receiptsTitle.
  ///
  /// In ro, this message translates to:
  /// **'Chitantele Tale'**
  String get receiptsTitle;

  /// No description provided for @receiptsTitlePassenger.
  ///
  /// In ro, this message translates to:
  /// **'Chitante (Pasager)'**
  String get receiptsTitlePassenger;

  /// No description provided for @errorLoadingReceipts.
  ///
  /// In ro, this message translates to:
  /// **'Eroare la încărcarea chitanțelor'**
  String get errorLoadingReceipts;

  /// No description provided for @noReceiptsInPeriod.
  ///
  /// In ro, this message translates to:
  /// **'Nu aveți nicio chitanță în această categorie pentru perioada selectată.'**
  String get noReceiptsInPeriod;

  /// No description provided for @deleteSelectedReceipts.
  ///
  /// In ro, this message translates to:
  /// **'Șterge {count} chitante selectate?'**
  String deleteSelectedReceipts(int count);

  /// No description provided for @deleteSelectedReceiptsWarning.
  ///
  /// In ro, this message translates to:
  /// **'Această acțiune va șterge permanent chitanțele selectate. Acțiunea nu poate fi anulată.'**
  String get deleteSelectedReceiptsWarning;

  /// No description provided for @receiptsDeletedSuccess.
  ///
  /// In ro, this message translates to:
  /// **'Au fost șterse cu succes {count} chitante.'**
  String receiptsDeletedSuccess(int count);

  /// No description provided for @receiptsDeletedPartial.
  ///
  /// In ro, this message translates to:
  /// **'Au fost șterse {deleted} chitante. {error} nu au putut fi șterse.'**
  String receiptsDeletedPartial(int deleted, int error);

  /// No description provided for @deleteAllReceipts.
  ///
  /// In ro, this message translates to:
  /// **'Șterge toate chitanțele ({count})?'**
  String deleteAllReceipts(int count);

  /// No description provided for @deleteAllReceiptsWarning.
  ///
  /// In ro, this message translates to:
  /// **'Această acțiune va șterge permanent TOATE chitanțele din perioada selectată. Acțiunea nu poate fi anulată.'**
  String get deleteAllReceiptsWarning;

  /// No description provided for @allReceiptsDeleted.
  ///
  /// In ro, this message translates to:
  /// **'Au fost șterse {count} chitante.'**
  String allReceiptsDeleted(int count);

  /// No description provided for @filterAllReceipts.
  ///
  /// In ro, this message translates to:
  /// **'Toate'**
  String get filterAllReceipts;

  /// No description provided for @generating.
  ///
  /// In ro, this message translates to:
  /// **'Generez...'**
  String get generating;

  /// No description provided for @monthlyReportPDF.
  ///
  /// In ro, this message translates to:
  /// **'Raport Lunar PDF'**
  String get monthlyReportPDF;

  /// No description provided for @selectedCount.
  ///
  /// In ro, this message translates to:
  /// **'{count} selectate'**
  String selectedCount(int count);

  /// No description provided for @selectAll.
  ///
  /// In ro, this message translates to:
  /// **'Selectează tot'**
  String get selectAll;

  /// No description provided for @deselectAll.
  ///
  /// In ro, this message translates to:
  /// **'Deselectează tot'**
  String get deselectAll;

  /// No description provided for @deleteSelected.
  ///
  /// In ro, this message translates to:
  /// **'Șterge selectate'**
  String get deleteSelected;

  /// No description provided for @deleteAll.
  ///
  /// In ro, this message translates to:
  /// **'Șterge toate'**
  String get deleteAll;

  /// No description provided for @noRidesForReport.
  ///
  /// In ro, this message translates to:
  /// **'Nu există curse în ultima lună pentru a genera raportul.'**
  String get noRidesForReport;

  /// No description provided for @returnToMapQuestion.
  ///
  /// In ro, this message translates to:
  /// **'Doriți să vă întoarceți la harta principală?'**
  String get returnToMapQuestion;

  /// No description provided for @rideTo.
  ///
  /// In ro, this message translates to:
  /// **'Cursă către: {destination}'**
  String rideTo(String destination);

  /// No description provided for @rideFrom.
  ///
  /// In ro, this message translates to:
  /// **'Ride from {date}'**
  String rideFrom(String date);

  /// No description provided for @from.
  ///
  /// In ro, this message translates to:
  /// **'De la:'**
  String get from;

  /// No description provided for @earningsSummary.
  ///
  /// In ro, this message translates to:
  /// **'Sumar Câștiguri'**
  String get earningsSummary;

  /// No description provided for @totalRide.
  ///
  /// In ro, this message translates to:
  /// **'Total Cursă:'**
  String get totalRide;

  /// No description provided for @appCommission.
  ///
  /// In ro, this message translates to:
  /// **'Comision Aplicație:'**
  String get appCommission;

  /// No description provided for @yourEarnings.
  ///
  /// In ro, this message translates to:
  /// **'Câștigul Tău:'**
  String get yourEarnings;

  /// No description provided for @activeRideDetected.
  ///
  /// In ro, this message translates to:
  /// **'Cursă activă detectată'**
  String get activeRideDetected;

  /// No description provided for @cancelPreviousRide.
  ///
  /// In ro, this message translates to:
  /// **'Anulează cursa precedentă'**
  String get cancelPreviousRide;

  /// No description provided for @rideAcceptedWaiting.
  ///
  /// In ro, this message translates to:
  /// **'Cursă acceptată! Așteptăm confirmarea pasagerului...'**
  String get rideAcceptedWaiting;

  /// No description provided for @driverProfileLoading.
  ///
  /// In ro, this message translates to:
  /// **'Profilul șofer se încarcă, încercați din nou...'**
  String get driverProfileLoading;

  /// No description provided for @searching.
  ///
  /// In ro, this message translates to:
  /// **'Se caută…'**
  String get searching;

  /// No description provided for @searchInThisArea.
  ///
  /// In ro, this message translates to:
  /// **'Caută în această zonă'**
  String get searchInThisArea;

  /// No description provided for @declining.
  ///
  /// In ro, this message translates to:
  /// **'Refuz...'**
  String get declining;

  /// No description provided for @decline.
  ///
  /// In ro, this message translates to:
  /// **'Refuză'**
  String get decline;

  /// No description provided for @accepting.
  ///
  /// In ro, this message translates to:
  /// **'Accept...'**
  String get accepting;

  /// No description provided for @accept.
  ///
  /// In ro, this message translates to:
  /// **'Acceptă'**
  String get accept;

  /// No description provided for @addAsStop.
  ///
  /// In ro, this message translates to:
  /// **'Adaugă ca oprire'**
  String get addAsStop;

  /// No description provided for @pickupPointDeleted.
  ///
  /// In ro, this message translates to:
  /// **'Punctul de plecare a fost șters'**
  String get pickupPointDeleted;

  /// No description provided for @destinationDeleted.
  ///
  /// In ro, this message translates to:
  /// **'Destinația a fost ștearsă'**
  String get destinationDeleted;

  /// No description provided for @selectPickupAndDestination.
  ///
  /// In ro, this message translates to:
  /// **'Selectează punctul de plecare și destinația'**
  String get selectPickupAndDestination;

  /// No description provided for @rideSummary.
  ///
  /// In ro, this message translates to:
  /// **'Sumar Cursă'**
  String get rideSummary;

  /// No description provided for @couldNotLoadRideDetails.
  ///
  /// In ro, this message translates to:
  /// **'Nu s-au putut încărca detaliile cursei'**
  String get couldNotLoadRideDetails;

  /// No description provided for @back.
  ///
  /// In ro, this message translates to:
  /// **'Înapoi'**
  String get back;

  /// No description provided for @noTip.
  ///
  /// In ro, this message translates to:
  /// **'Fără bacșiș'**
  String get noTip;

  /// No description provided for @routeNotLoaded.
  ///
  /// In ro, this message translates to:
  /// **'🗺️ Nu s-a putut încărca traseul automat'**
  String get routeNotLoaded;

  /// No description provided for @rideCancelledSuccess.
  ///
  /// In ro, this message translates to:
  /// **'Cursa a fost anulată cu succes'**
  String get rideCancelledSuccess;

  /// No description provided for @forceCancelRide.
  ///
  /// In ro, this message translates to:
  /// **'Anulează Forțat Cursa'**
  String get forceCancelRide;

  /// No description provided for @passengerAddedStop.
  ///
  /// In ro, this message translates to:
  /// **'Pasagerul a adăugat o nouă oprire. Ruta a fost recalculată.'**
  String get passengerAddedStop;

  /// No description provided for @stopAdded.
  ///
  /// In ro, this message translates to:
  /// **'Oprire adăugată! Traseul și costul au fost actualizate.'**
  String get stopAdded;

  /// No description provided for @errorAddingStop.
  ///
  /// In ro, this message translates to:
  /// **'Eroare la adăugarea opririi: {error}'**
  String errorAddingStop(String error);

  /// No description provided for @navigationWithGoogleMaps.
  ///
  /// In ro, this message translates to:
  /// **'Navigație cu Google Maps'**
  String get navigationWithGoogleMaps;

  /// No description provided for @navigationWithWaze.
  ///
  /// In ro, this message translates to:
  /// **'Navigație cu Waze'**
  String get navigationWithWaze;

  /// No description provided for @safetyTeamNotified.
  ///
  /// In ro, this message translates to:
  /// **'Am notificat echipa de siguranță. Suntem alături de tine.'**
  String get safetyTeamNotified;

  /// No description provided for @sendViaApps.
  ///
  /// In ro, this message translates to:
  /// **'Trimite prin aplicații'**
  String get sendViaApps;

  /// No description provided for @noTrustedContacts.
  ///
  /// In ro, this message translates to:
  /// **'Nu aveți contacte de încredere'**
  String get noTrustedContacts;

  /// No description provided for @manageContacts.
  ///
  /// In ro, this message translates to:
  /// **'Gestionează contacte'**
  String get manageContacts;

  /// No description provided for @iAmSafe.
  ///
  /// In ro, this message translates to:
  /// **'Sunt în siguranță'**
  String get iAmSafe;

  /// No description provided for @falseAlarm.
  ///
  /// In ro, this message translates to:
  /// **'Alarmă falsă'**
  String get falseAlarm;

  /// No description provided for @shareRoute.
  ///
  /// In ro, this message translates to:
  /// **'Partajează traseul'**
  String get shareRoute;

  /// No description provided for @rideCancelledSuccessShort.
  ///
  /// In ro, this message translates to:
  /// **'Cursa a fost anulată cu succes'**
  String get rideCancelledSuccessShort;

  /// No description provided for @recenterMap.
  ///
  /// In ro, this message translates to:
  /// **'Recentrează harta'**
  String get recenterMap;

  /// No description provided for @mapMovedTapToRecenter.
  ///
  /// In ro, this message translates to:
  /// **'Mișcat harta. Atinge pentru recentrare'**
  String get mapMovedTapToRecenter;

  /// No description provided for @entrySelected.
  ///
  /// In ro, this message translates to:
  /// **'Intrare selectată.'**
  String get entrySelected;

  /// No description provided for @addStop.
  ///
  /// In ro, this message translates to:
  /// **'Adaugă Oprire'**
  String get addStop;

  /// No description provided for @navigationBanner.
  ///
  /// In ro, this message translates to:
  /// **'Banner navigație. {type} {modifier}. Distanță {distance} metri.'**
  String navigationBanner(String type, String modifier, String distance);

  /// No description provided for @entrySelectedWithLabel.
  ///
  /// In ro, this message translates to:
  /// **'Intrare selectată: {label}'**
  String entrySelectedWithLabel(String label);

  /// No description provided for @editMessage.
  ///
  /// In ro, this message translates to:
  /// **'Editează mesajul'**
  String get editMessage;

  /// No description provided for @passengerNotifiedArrived.
  ///
  /// In ro, this message translates to:
  /// **'✅ Pasagerul a fost notificat că ai ajuns!'**
  String get passengerNotifiedArrived;

  /// No description provided for @cannotOpenPhoneApp.
  ///
  /// In ro, this message translates to:
  /// **'Nu se poate deschide aplicația de telefon'**
  String get cannotOpenPhoneApp;

  /// No description provided for @errorLoadingRoute.
  ///
  /// In ro, this message translates to:
  /// **'Eroare la încărcarea rutei: {error}'**
  String errorLoadingRoute(String error);

  /// No description provided for @rideCancelledReason.
  ///
  /// In ro, this message translates to:
  /// **'Cursa anulată: {reason}'**
  String rideCancelledReason(String reason);

  /// No description provided for @selectCancellationReason.
  ///
  /// In ro, this message translates to:
  /// **'Selectează motivul anulării:'**
  String get selectCancellationReason;

  /// No description provided for @backButton.
  ///
  /// In ro, this message translates to:
  /// **'Înapoi'**
  String get backButton;

  /// No description provided for @passengerNotResponding.
  ///
  /// In ro, this message translates to:
  /// **'Pasager nu răspunde'**
  String get passengerNotResponding;

  /// No description provided for @technicalProblem.
  ///
  /// In ro, this message translates to:
  /// **'Problemă tehnică'**
  String get technicalProblem;

  /// No description provided for @pickupRide.
  ///
  /// In ro, this message translates to:
  /// **'Preluare Cursă'**
  String get pickupRide;

  /// No description provided for @loadingPassengerInfo.
  ///
  /// In ro, this message translates to:
  /// **'Se încarcă informațiile pasagerului...'**
  String get loadingPassengerInfo;

  /// No description provided for @pleaseValidateAddress.
  ///
  /// In ro, this message translates to:
  /// **'Te rugăm să validezi adresa sau să o selectezi de pe hartă.'**
  String get pleaseValidateAddress;

  /// No description provided for @editAddress.
  ///
  /// In ro, this message translates to:
  /// **'Editează Adresa'**
  String get editAddress;

  /// No description provided for @addNewAddress.
  ///
  /// In ro, this message translates to:
  /// **'Adaugă Adresă Nouă'**
  String get addNewAddress;

  /// No description provided for @errorVoiceRecognition.
  ///
  /// In ro, this message translates to:
  /// **'Eroare la recunoașterea vocală: {error}'**
  String errorVoiceRecognition(String error);

  /// No description provided for @updateAddress.
  ///
  /// In ro, this message translates to:
  /// **'Actualizează Adresa'**
  String get updateAddress;

  /// No description provided for @saveAddress.
  ///
  /// In ro, this message translates to:
  /// **'Salvează Adresa'**
  String get saveAddress;

  /// No description provided for @resetPasswordButton.
  ///
  /// In ro, this message translates to:
  /// **'Resetează Parola'**
  String get resetPasswordButton;

  /// No description provided for @pleaseFillAllFields.
  ///
  /// In ro, this message translates to:
  /// **'Vă rugăm completați corect toate câmpurile.'**
  String get pleaseFillAllFields;

  /// No description provided for @welcomeBack.
  ///
  /// In ro, this message translates to:
  /// **'👋 Bun venit înapoi!'**
  String get welcomeBack;

  /// No description provided for @welcomeToNabour.
  ///
  /// In ro, this message translates to:
  /// **'Bun venit în Nabour!'**
  String get welcomeToNabour;

  /// No description provided for @pleaseEnterValidEmail.
  ///
  /// In ro, this message translates to:
  /// **'Vă rugăm introduceți o adresă de email validă în câmpul de Email pentru resetare.'**
  String get pleaseEnterValidEmail;

  /// No description provided for @errorResettingPassword.
  ///
  /// In ro, this message translates to:
  /// **'A apărut o eroare neașteptată la resetarea parolei.'**
  String get errorResettingPassword;

  /// No description provided for @enterValidPhoneNumber.
  ///
  /// In ro, this message translates to:
  /// **'Introduceți un număr de telefon valid.'**
  String get enterValidPhoneNumber;

  /// No description provided for @autoAuthCompleted.
  ///
  /// In ro, this message translates to:
  /// **'Autentificare automată finalizată'**
  String get autoAuthCompleted;

  /// No description provided for @errorAutoAuth.
  ///
  /// In ro, this message translates to:
  /// **'Eroare autentificare automată: {error}'**
  String errorAutoAuth(String error);

  /// No description provided for @enterSmsCode.
  ///
  /// In ro, this message translates to:
  /// **'Introduceți codul SMS primit.'**
  String get enterSmsCode;

  /// No description provided for @verifyAndAuthenticate.
  ///
  /// In ro, this message translates to:
  /// **'Verifică și autentifică'**
  String get verifyAndAuthenticate;

  /// No description provided for @max5Stops.
  ///
  /// In ro, this message translates to:
  /// **'Poți adăuga maximum 5 opriri'**
  String get max5Stops;

  /// No description provided for @addressNotFound.
  ///
  /// In ro, this message translates to:
  /// **'Nu s-a putut găsi adresa: {address}'**
  String addressNotFound(String address);

  /// No description provided for @noCoordinatesForDestination.
  ///
  /// In ro, this message translates to:
  /// **'Nu s-au găsit coordonate pentru destinație: {error}'**
  String noCoordinatesForDestination(String error);

  /// No description provided for @fillBothAddresses.
  ///
  /// In ro, this message translates to:
  /// **'Completează ambele adrese pentru a continua'**
  String get fillBothAddresses;

  /// No description provided for @intermediateStopAdded.
  ///
  /// In ro, this message translates to:
  /// **'Oprire intermediară adăugată'**
  String get intermediateStopAdded;

  /// No description provided for @home.
  ///
  /// In ro, this message translates to:
  /// **'Acasă'**
  String get home;

  /// No description provided for @work.
  ///
  /// In ro, this message translates to:
  /// **'Serviciu'**
  String get work;

  /// No description provided for @edit.
  ///
  /// In ro, this message translates to:
  /// **'Editează'**
  String get edit;

  /// No description provided for @recentDestinations.
  ///
  /// In ro, this message translates to:
  /// **'Destinații Recente'**
  String get recentDestinations;

  /// No description provided for @noFavoriteAddressAdded.
  ///
  /// In ro, this message translates to:
  /// **'Nicio adresă favorită adăugată.'**
  String get noFavoriteAddressAdded;

  /// No description provided for @addressUpdated.
  ///
  /// In ro, this message translates to:
  /// **'Adresa a fost actualizată!'**
  String get addressUpdated;

  /// No description provided for @addressSaved.
  ///
  /// In ro, this message translates to:
  /// **'Adresa a fost salvată!'**
  String get addressSaved;

  /// No description provided for @pleaseSelectRating.
  ///
  /// In ro, this message translates to:
  /// **'Te rugăm selectează un rating înainte de a trimite.'**
  String get pleaseSelectRating;

  /// No description provided for @ratingSentSuccess.
  ///
  /// In ro, this message translates to:
  /// **'Evaluare trimisă cu succes!'**
  String get ratingSentSuccess;

  /// No description provided for @errorSendingRating.
  ///
  /// In ro, this message translates to:
  /// **'Eroare la trimiterea evaluării: {error}'**
  String errorSendingRating(String error);

  /// No description provided for @rideDetailsCompleted.
  ///
  /// In ro, this message translates to:
  /// **'Detalii Cursă Finalizată'**
  String get rideDetailsCompleted;

  /// No description provided for @saveRating.
  ///
  /// In ro, this message translates to:
  /// **'Salvează Evaluarea'**
  String get saveRating;

  /// No description provided for @errorConfirmingDriver.
  ///
  /// In ro, this message translates to:
  /// **'Eroare la confirmarea șoferului: {error}'**
  String errorConfirmingDriver(String error);

  /// No description provided for @errorDecliningDriver.
  ///
  /// In ro, this message translates to:
  /// **'Eroare la refuzarea șoferului: {error}'**
  String errorDecliningDriver(String error);

  /// No description provided for @backToMap.
  ///
  /// In ro, this message translates to:
  /// **'Înapoi la Hartă'**
  String get backToMap;

  /// No description provided for @currentLocation.
  ///
  /// In ro, this message translates to:
  /// **'Locația actuală'**
  String get currentLocation;

  /// No description provided for @finalDestination.
  ///
  /// In ro, this message translates to:
  /// **'Destinație finală'**
  String get finalDestination;

  /// No description provided for @accordingToSelection.
  ///
  /// In ro, this message translates to:
  /// **'Conform selecției'**
  String get accordingToSelection;

  /// No description provided for @waitingResponse.
  ///
  /// In ro, this message translates to:
  /// **'⏳ AȘTEPT RĂSPUNS...'**
  String get waitingResponse;

  /// No description provided for @waitingConfirmation.
  ///
  /// In ro, this message translates to:
  /// **'❓ AȘTEPT CONFIRMARE\n\nSpuneți DA sau NU'**
  String get waitingConfirmation;

  /// No description provided for @arrivedNotifyPassenger.
  ///
  /// In ro, this message translates to:
  /// **'Am ajuns - Anunță pasagerul'**
  String get arrivedNotifyPassenger;

  /// No description provided for @passengerBoarding.
  ///
  /// In ro, this message translates to:
  /// **'Pasagerul se îmbarcă'**
  String get passengerBoarding;

  /// No description provided for @route.
  ///
  /// In ro, this message translates to:
  /// **'Rută'**
  String get route;

  /// No description provided for @preferencesSaved.
  ///
  /// In ro, this message translates to:
  /// **'Preferințele au fost salvate'**
  String get preferencesSaved;

  /// No description provided for @pleaseSelectRatingBeforeSubmit.
  ///
  /// In ro, this message translates to:
  /// **'Vă rugăm selectați un rating înainte de a trimite.'**
  String get pleaseSelectRatingBeforeSubmit;

  /// No description provided for @errorSubmittingRating.
  ///
  /// In ro, this message translates to:
  /// **'Eroare la trimiterea evaluării. Încercați din nou.'**
  String get errorSubmittingRating;

  /// No description provided for @thankYouForRide.
  ///
  /// In ro, this message translates to:
  /// **'Vă mulțumim pentru călătorie!'**
  String get thankYouForRide;

  /// No description provided for @howWasExperience.
  ///
  /// In ro, this message translates to:
  /// **'Cum a fost experiența?'**
  String get howWasExperience;

  /// No description provided for @leaveCommentOptional.
  ///
  /// In ro, this message translates to:
  /// **'Lasă un comentariu (opțional)'**
  String get leaveCommentOptional;

  /// No description provided for @thanksForRating.
  ///
  /// In ro, this message translates to:
  /// **'Mulțumim pentru evaluare!'**
  String get thanksForRating;

  /// No description provided for @ratePassenger.
  ///
  /// In ro, this message translates to:
  /// **'Evaluează Pasagerul'**
  String get ratePassenger;

  /// No description provided for @shortCharacterization.
  ///
  /// In ro, this message translates to:
  /// **'Scurtă caracterizare (ex: curat, a murdărit mașina)'**
  String get shortCharacterization;

  /// No description provided for @addPrivateNoteAboutPassenger.
  ///
  /// In ro, this message translates to:
  /// **'Adaugă o notă privată despre pasager...'**
  String get addPrivateNoteAboutPassenger;

  /// No description provided for @routeUpdated.
  ///
  /// In ro, this message translates to:
  /// **'Traseu Actualizat'**
  String get routeUpdated;

  /// No description provided for @passengerAddedNewStop.
  ///
  /// In ro, this message translates to:
  /// **'Pasagerul a adăugat o nouă oprire. Ruta a fost recalculată.'**
  String get passengerAddedNewStop;

  /// No description provided for @ok.
  ///
  /// In ro, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @rideManagement.
  ///
  /// In ro, this message translates to:
  /// **'Gestionare Cursă'**
  String get rideManagement;

  /// No description provided for @modifyDestination.
  ///
  /// In ro, this message translates to:
  /// **'Modifică Destinația'**
  String get modifyDestination;

  /// No description provided for @cannotModifyCompletedRide.
  ///
  /// In ro, this message translates to:
  /// **'Nu poți modifica destinația pentru o cursă finalizată sau anulată.'**
  String get cannotModifyCompletedRide;

  /// No description provided for @destinationUpdatedSuccessfully.
  ///
  /// In ro, this message translates to:
  /// **'Destinația a fost actualizată cu succes!'**
  String get destinationUpdatedSuccessfully;

  /// No description provided for @errorUpdatingDestination.
  ///
  /// In ro, this message translates to:
  /// **'Eroare la actualizarea destinației: {error}'**
  String errorUpdatingDestination(String error);

  /// No description provided for @changeFinalLocation.
  ///
  /// In ro, this message translates to:
  /// **'Schimbă locația finală'**
  String get changeFinalLocation;

  /// No description provided for @intermediateStop.
  ///
  /// In ro, this message translates to:
  /// **'Oprire intermediară'**
  String get intermediateStop;

  /// No description provided for @mayIncludeCancellationFee.
  ///
  /// In ro, this message translates to:
  /// **'Poate include taxă de anulare'**
  String get mayIncludeCancellationFee;

  /// No description provided for @viewReceipt.
  ///
  /// In ro, this message translates to:
  /// **'Vizualizează Chitanța'**
  String get viewReceipt;

  /// No description provided for @completeRideDetails.
  ///
  /// In ro, this message translates to:
  /// **'Detalii complete ale cursei'**
  String get completeRideDetails;

  /// No description provided for @rateRide.
  ///
  /// In ro, this message translates to:
  /// **'Evaluează Cursa'**
  String get rateRide;

  /// No description provided for @provideDriverFeedback.
  ///
  /// In ro, this message translates to:
  /// **'Oferă feedback șoferului'**
  String get provideDriverFeedback;

  /// No description provided for @communication.
  ///
  /// In ro, this message translates to:
  /// **'Comunicare'**
  String get communication;

  /// No description provided for @callDriver.
  ///
  /// In ro, this message translates to:
  /// **'Sună Șoferul'**
  String get callDriver;

  /// No description provided for @chatWith.
  ///
  /// In ro, this message translates to:
  /// **'Chat cu {name}'**
  String chatWith(String name);

  /// No description provided for @chatAvailableSoon.
  ///
  /// In ro, this message translates to:
  /// **'Chat-ul va fi disponibil în curând'**
  String get chatAvailableSoon;

  /// No description provided for @costSummary.
  ///
  /// In ro, this message translates to:
  /// **'Sumar Cost'**
  String get costSummary;

  /// No description provided for @baseFare.
  ///
  /// In ro, this message translates to:
  /// **'Tarif de bază:'**
  String get baseFare;

  /// No description provided for @time.
  ///
  /// In ro, this message translates to:
  /// **'Timp ({min} min):'**
  String time(String min);

  /// No description provided for @totalPaid.
  ///
  /// In ro, this message translates to:
  /// **'Total Plătit:'**
  String get totalPaid;

  /// No description provided for @ratingGiven.
  ///
  /// In ro, this message translates to:
  /// **'Rating acordat:'**
  String get ratingGiven;

  /// No description provided for @noRatingGiven.
  ///
  /// In ro, this message translates to:
  /// **'Niciun rating acordat'**
  String get noRatingGiven;

  /// No description provided for @optionalComments.
  ///
  /// In ro, this message translates to:
  /// **'Comentarii opționale...'**
  String get optionalComments;

  /// No description provided for @howWasYourExperience.
  ///
  /// In ro, this message translates to:
  /// **'Cum a fost experiența ta?'**
  String get howWasYourExperience;

  /// No description provided for @routeNotLoadedAuto.
  ///
  /// In ro, this message translates to:
  /// **'🗺️ Nu s-a putut încărca traseul automat'**
  String get routeNotLoadedAuto;

  /// No description provided for @rideCancelledSuccessfully.
  ///
  /// In ro, this message translates to:
  /// **'Cursa a fost anulată cu succes.'**
  String get rideCancelledSuccessfully;

  /// No description provided for @stopAddedRouteUpdated.
  ///
  /// In ro, this message translates to:
  /// **'Oprire adăugată! Traseul și costul au fost actualizate.'**
  String get stopAddedRouteUpdated;

  /// No description provided for @writeNewText.
  ///
  /// In ro, this message translates to:
  /// **'Scrie noul text...'**
  String get writeNewText;

  /// No description provided for @messageEditedSuccess.
  ///
  /// In ro, this message translates to:
  /// **'Mesajul a fost editat cu succes!'**
  String get messageEditedSuccess;

  /// No description provided for @errorEditingMessage.
  ///
  /// In ro, this message translates to:
  /// **'Eroare la editarea mesajului: {error}'**
  String errorEditingMessage(String error);

  /// No description provided for @errorCancelling.
  ///
  /// In ro, this message translates to:
  /// **'Eroare la anulare: {error}'**
  String errorCancelling(String error);

  /// No description provided for @inviteFriendsDescription.
  ///
  /// In ro, this message translates to:
  /// **'Invită vecini să se alăture comunității Nabour'**
  String get inviteFriendsDescription;

  /// No description provided for @splitPayment.
  ///
  /// In ro, this message translates to:
  /// **'Împărțire Misiune'**
  String get splitPayment;

  /// No description provided for @splitPaymentDescription.
  ///
  /// In ro, this message translates to:
  /// **'Invită vecinii să se alăture drumului tău'**
  String get splitPaymentDescription;

  /// No description provided for @createSplitPayment.
  ///
  /// In ro, this message translates to:
  /// **'Creează Împărțire'**
  String get createSplitPayment;

  /// No description provided for @splitPaymentCreated.
  ///
  /// In ro, this message translates to:
  /// **'Împărțirea a fost creată'**
  String get splitPaymentCreated;

  /// No description provided for @shareLinkWithParticipants.
  ///
  /// In ro, this message translates to:
  /// **'Partajează link-ul cu participanții:'**
  String get shareLinkWithParticipants;

  /// No description provided for @share.
  ///
  /// In ro, this message translates to:
  /// **'Partajează'**
  String get share;

  /// No description provided for @splitWithHowMany.
  ///
  /// In ro, this message translates to:
  /// **'Cu câți să împărți?'**
  String get splitWithHowMany;

  /// No description provided for @selectNumberOfPeople.
  ///
  /// In ro, this message translates to:
  /// **'Selectează numărul de persoane'**
  String get selectNumberOfPeople;

  /// No description provided for @confirm.
  ///
  /// In ro, this message translates to:
  /// **'Confirmă'**
  String get confirm;

  /// No description provided for @acceptSplitPayment.
  ///
  /// In ro, this message translates to:
  /// **'Acceptă Împărțirea'**
  String get acceptSplitPayment;

  /// No description provided for @markAsPaid.
  ///
  /// In ro, this message translates to:
  /// **'Marchează ca Plătit'**
  String get markAsPaid;

  /// No description provided for @totalAmount.
  ///
  /// In ro, this message translates to:
  /// **'Total'**
  String get totalAmount;

  /// No description provided for @perPerson.
  ///
  /// In ro, this message translates to:
  /// **'Per Persoană'**
  String get perPerson;

  /// No description provided for @participants.
  ///
  /// In ro, this message translates to:
  /// **'Participanți'**
  String get participants;

  /// No description provided for @participant.
  ///
  /// In ro, this message translates to:
  /// **'Participant'**
  String get participant;

  /// No description provided for @paid.
  ///
  /// In ro, this message translates to:
  /// **'Plătit'**
  String get paid;

  /// No description provided for @pending.
  ///
  /// In ro, this message translates to:
  /// **'În așteptare'**
  String get pending;

  /// No description provided for @accepted.
  ///
  /// In ro, this message translates to:
  /// **'Acceptat'**
  String get accepted;

  /// No description provided for @completed.
  ///
  /// In ro, this message translates to:
  /// **'Finalizat'**
  String get completed;

  /// No description provided for @rejected.
  ///
  /// In ro, this message translates to:
  /// **'Respins'**
  String get rejected;

  /// No description provided for @cancelled.
  ///
  /// In ro, this message translates to:
  /// **'Anulat'**
  String get cancelled;

  /// No description provided for @errorCreatingSplitPayment.
  ///
  /// In ro, this message translates to:
  /// **'Eroare la crearea împărțirii: {error}'**
  String errorCreatingSplitPayment(String error);

  /// No description provided for @errorAcceptingSplitPayment.
  ///
  /// In ro, this message translates to:
  /// **'Eroare la acceptarea împărțirii: {error}'**
  String errorAcceptingSplitPayment(String error);

  /// No description provided for @errorCompletingPayment.
  ///
  /// In ro, this message translates to:
  /// **'Eroare la finalizarea plății: {error}'**
  String errorCompletingPayment(String error);

  /// No description provided for @paymentCompleted.
  ///
  /// In ro, this message translates to:
  /// **'Misiune îndeplinită'**
  String get paymentCompleted;

  /// No description provided for @promotionCode.
  ///
  /// In ro, this message translates to:
  /// **'Cod Promoțional'**
  String get promotionCode;

  /// No description provided for @enterPromotionCode.
  ///
  /// In ro, this message translates to:
  /// **'Introdu codul promoțional'**
  String get enterPromotionCode;

  /// No description provided for @apply.
  ///
  /// In ro, this message translates to:
  /// **'Aplică'**
  String get apply;

  /// No description provided for @promotionAppliedSuccessfully.
  ///
  /// In ro, this message translates to:
  /// **'Cod promoțional aplicat cu succes'**
  String get promotionAppliedSuccessfully;

  /// No description provided for @subscriptionsHelpTitle.
  ///
  /// In ro, this message translates to:
  /// **'Abonamente și Promoții'**
  String get subscriptionsHelpTitle;

  /// No description provided for @subscriptionsHelpOverview.
  ///
  /// In ro, this message translates to:
  /// **'Abonamentele Nabour vă oferă beneficii exclusive și reduceri la curse.'**
  String get subscriptionsHelpOverview;

  /// No description provided for @subscriptionsHelpPlans.
  ///
  /// In ro, this message translates to:
  /// **'Planuri Disponibile:'**
  String get subscriptionsHelpPlans;

  /// No description provided for @subscriptionsHelpBasic.
  ///
  /// In ro, this message translates to:
  /// **'• Nabour Basic - 5% reducere la 10 curse/lună'**
  String get subscriptionsHelpBasic;

  /// No description provided for @subscriptionsHelpPlus.
  ///
  /// In ro, this message translates to:
  /// **'• Nabour Plus - 10% reducere la toate cursele (Recomandat)'**
  String get subscriptionsHelpPlus;

  /// No description provided for @subscriptionsHelpPremium.
  ///
  /// In ro, this message translates to:
  /// **'• Nabour Premium - 15% reducere + beneficii exclusive'**
  String get subscriptionsHelpPremium;

  /// No description provided for @subscriptionsHelpHowToSubscribe.
  ///
  /// In ro, this message translates to:
  /// **'Cum să vă abonați:'**
  String get subscriptionsHelpHowToSubscribe;

  /// No description provided for @subscriptionsHelpGoToMenu.
  ///
  /// In ro, this message translates to:
  /// **'1. Accesați meniul hamburger'**
  String get subscriptionsHelpGoToMenu;

  /// No description provided for @subscriptionsHelpTapSubscriptions.
  ///
  /// In ro, this message translates to:
  /// **'2. Apăsați pe \'Abonamente și Promoții\''**
  String get subscriptionsHelpTapSubscriptions;

  /// No description provided for @subscriptionsHelpSelectPlan.
  ///
  /// In ro, this message translates to:
  /// **'3. Selectați planul dorit'**
  String get subscriptionsHelpSelectPlan;

  /// No description provided for @subscriptionsHelpCompletePayment.
  ///
  /// In ro, this message translates to:
  /// **'4. Completați plata'**
  String get subscriptionsHelpCompletePayment;

  /// No description provided for @subscriptionsHelpPromotions.
  ///
  /// In ro, this message translates to:
  /// **'Promoții Active:'**
  String get subscriptionsHelpPromotions;

  /// No description provided for @subscriptionsHelpPromotionsInfo.
  ///
  /// In ro, this message translates to:
  /// **'Verificați secțiunea \'Promoții\' pentru oferte speciale și coduri promoționale disponibile.'**
  String get subscriptionsHelpPromotionsInfo;

  /// No description provided for @subscriptionsHelpReferral.
  ///
  /// In ro, this message translates to:
  /// **'Program de Recomandare:'**
  String get subscriptionsHelpReferral;

  /// No description provided for @subscriptionsHelpReferralInfo.
  ///
  /// In ro, this message translates to:
  /// **'Partajați codul dvs. de recomandare și primiți beneficii pentru fiecare prieten care se înscrie.'**
  String get subscriptionsHelpReferralInfo;

  /// No description provided for @splitPaymentHelpTitle.
  ///
  /// In ro, this message translates to:
  /// **'Split Payment - Împărțirea Costului'**
  String get splitPaymentHelpTitle;

  /// No description provided for @splitPaymentHelpOverview.
  ///
  /// In ro, this message translates to:
  /// **'Split Payment vă permite să împărțiți costul cursei cu alți pasageri.'**
  String get splitPaymentHelpOverview;

  /// No description provided for @splitPaymentHelpHowToCreate.
  ///
  /// In ro, this message translates to:
  /// **'Cum să creați Split Payment:'**
  String get splitPaymentHelpHowToCreate;

  /// No description provided for @splitPaymentHelpAfterRide.
  ///
  /// In ro, this message translates to:
  /// **'1. După finalizarea cursei, apăsați pe \'Split Payment\''**
  String get splitPaymentHelpAfterRide;

  /// No description provided for @splitPaymentHelpSelectPeople.
  ///
  /// In ro, this message translates to:
  /// **'2. Selectați numărul de persoane cu care împărțiți'**
  String get splitPaymentHelpSelectPeople;

  /// No description provided for @splitPaymentHelpShareLink.
  ///
  /// In ro, this message translates to:
  /// **'3. Partajați linkul generat cu participanții'**
  String get splitPaymentHelpShareLink;

  /// No description provided for @splitPaymentHelpParticipantsAccept.
  ///
  /// In ro, this message translates to:
  /// **'4. Participanții acceptă și plătesc partea lor'**
  String get splitPaymentHelpParticipantsAccept;

  /// No description provided for @splitPaymentHelpHowToAccept.
  ///
  /// In ro, this message translates to:
  /// **'Cum să acceptați Split Payment:'**
  String get splitPaymentHelpHowToAccept;

  /// No description provided for @splitPaymentHelpReceiveLink.
  ///
  /// In ro, this message translates to:
  /// **'1. Primirea linkului de partajare'**
  String get splitPaymentHelpReceiveLink;

  /// No description provided for @splitPaymentHelpTapAccept.
  ///
  /// In ro, this message translates to:
  /// **'2. Apăsați pe \'Accept Split\''**
  String get splitPaymentHelpTapAccept;

  /// No description provided for @splitPaymentHelpSelectPayment.
  ///
  /// In ro, this message translates to:
  /// **'3. Selectați metoda de plată'**
  String get splitPaymentHelpSelectPayment;

  /// No description provided for @splitPaymentHelpCompletePayment.
  ///
  /// In ro, this message translates to:
  /// **'4. Completați plata'**
  String get splitPaymentHelpCompletePayment;

  /// No description provided for @splitPaymentHelpNote.
  ///
  /// In ro, this message translates to:
  /// **'Notă: Split Payment este disponibil doar pentru curse finalizate.'**
  String get splitPaymentHelpNote;

  /// No description provided for @rideSharingHelpTitle.
  ///
  /// In ro, this message translates to:
  /// **'Ride Sharing - Curse Partajate'**
  String get rideSharingHelpTitle;

  /// No description provided for @rideSharingHelpOverview.
  ///
  /// In ro, this message translates to:
  /// **'Ride Sharing vă permite să partajați cursa cu alți pasageri care merg în aceeași direcție.'**
  String get rideSharingHelpOverview;

  /// No description provided for @rideSharingHelpHowToEnable.
  ///
  /// In ro, this message translates to:
  /// **'Cum să activați Ride Sharing:'**
  String get rideSharingHelpHowToEnable;

  /// No description provided for @rideSharingHelpDuringRequest.
  ///
  /// In ro, this message translates to:
  /// **'1. În timpul solicitării cursei, activați opțiunea \'Ride Sharing\''**
  String get rideSharingHelpDuringRequest;

  /// No description provided for @rideSharingHelpSystemMatches.
  ///
  /// In ro, this message translates to:
  /// **'2. Sistemul va căuta automat alți pasageri compatibili'**
  String get rideSharingHelpSystemMatches;

  /// No description provided for @rideSharingHelpIfMatchFound.
  ///
  /// In ro, this message translates to:
  /// **'3. Dacă se găsește un match, veți fi notificat'**
  String get rideSharingHelpIfMatchFound;

  /// No description provided for @rideSharingHelpBenefits.
  ///
  /// In ro, this message translates to:
  /// **'Beneficii:'**
  String get rideSharingHelpBenefits;

  /// No description provided for @rideSharingHelpCostReduction.
  ///
  /// In ro, this message translates to:
  /// **'• Reducere semnificativă a costului cursei'**
  String get rideSharingHelpCostReduction;

  /// No description provided for @rideSharingHelpEcoFriendly.
  ///
  /// In ro, this message translates to:
  /// **'• Opțiune prietenoasă cu mediul'**
  String get rideSharingHelpEcoFriendly;

  /// No description provided for @rideSharingHelpSocial.
  ///
  /// In ro, this message translates to:
  /// **'• Oportunitate de a cunoaște oameni noi'**
  String get rideSharingHelpSocial;

  /// No description provided for @rideSharingHelpNote.
  ///
  /// In ro, this message translates to:
  /// **'Notă: Ride Sharing este disponibil doar pentru anumite rute și în anumite zone.'**
  String get rideSharingHelpNote;

  /// No description provided for @modifyDestinationHelpTitle.
  ///
  /// In ro, this message translates to:
  /// **'Modificare Destinație'**
  String get modifyDestinationHelpTitle;

  /// No description provided for @modifyDestinationHelpOverview.
  ///
  /// In ro, this message translates to:
  /// **'Puteți modifica destinația cursei în timpul cursei active.'**
  String get modifyDestinationHelpOverview;

  /// No description provided for @modifyDestinationHelpHowToModify.
  ///
  /// In ro, this message translates to:
  /// **'Cum să modificați destinația:'**
  String get modifyDestinationHelpHowToModify;

  /// No description provided for @modifyDestinationHelpDuringRide.
  ///
  /// In ro, this message translates to:
  /// **'1. În timpul cursei active, apăsați pe \'Gestionare Cursă\''**
  String get modifyDestinationHelpDuringRide;

  /// No description provided for @modifyDestinationHelpTapModify.
  ///
  /// In ro, this message translates to:
  /// **'2. Apăsați pe \'Modifică Destinația\''**
  String get modifyDestinationHelpTapModify;

  /// No description provided for @modifyDestinationHelpSelectNew.
  ///
  /// In ro, this message translates to:
  /// **'3. Selectați noua destinație'**
  String get modifyDestinationHelpSelectNew;

  /// No description provided for @modifyDestinationHelpConfirm.
  ///
  /// In ro, this message translates to:
  /// **'4. Confirmați modificarea'**
  String get modifyDestinationHelpConfirm;

  /// No description provided for @modifyDestinationHelpRouteRecalculated.
  ///
  /// In ro, this message translates to:
  /// **'5. Ruta și prețul vor fi recalculate automat'**
  String get modifyDestinationHelpRouteRecalculated;

  /// No description provided for @modifyDestinationHelpLimitations.
  ///
  /// In ro, this message translates to:
  /// **'Limitări:'**
  String get modifyDestinationHelpLimitations;

  /// No description provided for @modifyDestinationHelpCannotModifyCompleted.
  ///
  /// In ro, this message translates to:
  /// **'• Nu puteți modifica destinația pentru curse finalizate sau anulate'**
  String get modifyDestinationHelpCannotModifyCompleted;

  /// No description provided for @modifyDestinationHelpPriceMayChange.
  ///
  /// In ro, this message translates to:
  /// **'• Prețul poate varia în funcție de noua destinație'**
  String get modifyDestinationHelpPriceMayChange;

  /// No description provided for @modifyDestinationHelpDriverNotified.
  ///
  /// In ro, this message translates to:
  /// **'• Șoferul va fi notificat automat despre modificare'**
  String get modifyDestinationHelpDriverNotified;

  /// No description provided for @lowDataModeHelpTitle.
  ///
  /// In ro, this message translates to:
  /// **'Mod Date Reduse'**
  String get lowDataModeHelpTitle;

  /// No description provided for @lowDataModeHelpOverview.
  ///
  /// In ro, this message translates to:
  /// **'Modul Date Reduse reduce consumul de date mobile optimizând funcționalitățile aplicației.'**
  String get lowDataModeHelpOverview;

  /// No description provided for @lowDataModeHelpHowToEnable.
  ///
  /// In ro, this message translates to:
  /// **'Cum să activați Mod Date Reduse:'**
  String get lowDataModeHelpHowToEnable;

  /// No description provided for @lowDataModeHelpGoToMenu.
  ///
  /// In ro, this message translates to:
  /// **'1. Accesați meniul hamburger'**
  String get lowDataModeHelpGoToMenu;

  /// No description provided for @lowDataModeHelpTapToggle.
  ///
  /// In ro, this message translates to:
  /// **'2. Găsiți opțiunea \'Mod date reduse\''**
  String get lowDataModeHelpTapToggle;

  /// No description provided for @lowDataModeHelpActivate.
  ///
  /// In ro, this message translates to:
  /// **'3. Activați toggle-ul'**
  String get lowDataModeHelpActivate;

  /// No description provided for @lowDataModeHelpWhatItDoes.
  ///
  /// In ro, this message translates to:
  /// **'Ce face Mod Date Reduse:'**
  String get lowDataModeHelpWhatItDoes;

  /// No description provided for @lowDataModeHelpReducesImages.
  ///
  /// In ro, this message translates to:
  /// **'• Reduce calitatea imaginilor și cache-ul'**
  String get lowDataModeHelpReducesImages;

  /// No description provided for @lowDataModeHelpLimitsAnimations.
  ///
  /// In ro, this message translates to:
  /// **'• Limitează animațiile și efectele vizuale'**
  String get lowDataModeHelpLimitsAnimations;

  /// No description provided for @lowDataModeHelpOptimizesMaps.
  ///
  /// In ro, this message translates to:
  /// **'• Optimizează încărcarea hărților'**
  String get lowDataModeHelpOptimizesMaps;

  /// No description provided for @lowDataModeHelpReducesSync.
  ///
  /// In ro, this message translates to:
  /// **'• Reduce sincronizarea în timp real'**
  String get lowDataModeHelpReducesSync;

  /// No description provided for @lowDataModeHelpBenefits.
  ///
  /// In ro, this message translates to:
  /// **'Beneficii:'**
  String get lowDataModeHelpBenefits;

  /// No description provided for @lowDataModeHelpSavesData.
  ///
  /// In ro, this message translates to:
  /// **'• Economisește date mobile'**
  String get lowDataModeHelpSavesData;

  /// No description provided for @lowDataModeHelpFasterLoading.
  ///
  /// In ro, this message translates to:
  /// **'• Încărcare mai rapidă pe conexiuni slabe'**
  String get lowDataModeHelpFasterLoading;

  /// No description provided for @lowDataModeHelpBatteryLife.
  ///
  /// In ro, this message translates to:
  /// **'• Îmbunătățește durata bateriei'**
  String get lowDataModeHelpBatteryLife;

  /// No description provided for @lowDataModeHelpNote.
  ///
  /// In ro, this message translates to:
  /// **'Notă: Mod Date Reduse poate afecta calitatea anumitor funcții, dar aplicația rămâne complet funcțională.'**
  String get lowDataModeHelpNote;

  /// No description provided for @highContrastUIHelpTitle.
  ///
  /// In ro, this message translates to:
  /// **'Interfață Contrast Ridicat'**
  String get highContrastUIHelpTitle;

  /// No description provided for @highContrastUIHelpOverview.
  ///
  /// In ro, this message translates to:
  /// **'Interfața cu Contrast Ridicat îmbunătățește vizibilitatea pentru utilizatorii cu deficiențe de vedere sau în condiții de lumină slabă.'**
  String get highContrastUIHelpOverview;

  /// No description provided for @highContrastUIHelpHowToEnable.
  ///
  /// In ro, this message translates to:
  /// **'Cum să activați Interfața cu Contrast Ridicat:'**
  String get highContrastUIHelpHowToEnable;

  /// No description provided for @highContrastUIHelpGoToMenu.
  ///
  /// In ro, this message translates to:
  /// **'1. Accesați meniul hamburger'**
  String get highContrastUIHelpGoToMenu;

  /// No description provided for @highContrastUIHelpTapToggle.
  ///
  /// In ro, this message translates to:
  /// **'2. Găsiți opțiunea \'Interfață contrast ridicat\''**
  String get highContrastUIHelpTapToggle;

  /// No description provided for @highContrastUIHelpActivate.
  ///
  /// In ro, this message translates to:
  /// **'3. Activați toggle-ul'**
  String get highContrastUIHelpActivate;

  /// No description provided for @highContrastUIHelpWhatItDoes.
  ///
  /// In ro, this message translates to:
  /// **'Ce face Interfața cu Contrast Ridicat:'**
  String get highContrastUIHelpWhatItDoes;

  /// No description provided for @highContrastUIHelpIncreasesContrast.
  ///
  /// In ro, this message translates to:
  /// **'• Mărește contrastul între text și fundal'**
  String get highContrastUIHelpIncreasesContrast;

  /// No description provided for @highContrastUIHelpBolderText.
  ///
  /// In ro, this message translates to:
  /// **'• Face textul mai bold și mai ușor de citit'**
  String get highContrastUIHelpBolderText;

  /// No description provided for @highContrastUIHelpClearerIcons.
  ///
  /// In ro, this message translates to:
  /// **'• Face iconițele și butoanele mai vizibile'**
  String get highContrastUIHelpClearerIcons;

  /// No description provided for @highContrastUIHelpBetterVisibility.
  ///
  /// In ro, this message translates to:
  /// **'• Îmbunătățește vizibilitatea în condiții de lumină slabă'**
  String get highContrastUIHelpBetterVisibility;

  /// No description provided for @highContrastUIHelpBenefits.
  ///
  /// In ro, this message translates to:
  /// **'Beneficii:'**
  String get highContrastUIHelpBenefits;

  /// No description provided for @highContrastUIHelpAccessibility.
  ///
  /// In ro, this message translates to:
  /// **'• Îmbunătățește accesibilitatea pentru utilizatori cu deficiențe de vedere'**
  String get highContrastUIHelpAccessibility;

  /// No description provided for @highContrastUIHelpReadability.
  ///
  /// In ro, this message translates to:
  /// **'• Text mai ușor de citit'**
  String get highContrastUIHelpReadability;

  /// No description provided for @highContrastUIHelpOutdoorUse.
  ///
  /// In ro, this message translates to:
  /// **'• Utilizare mai bună în condiții de lumină puternică'**
  String get highContrastUIHelpOutdoorUse;

  /// No description provided for @highContrastUIHelpNote.
  ///
  /// In ro, this message translates to:
  /// **'Notă: Interfața cu Contrast Ridicat este disponibilă atât pentru tema clară, cât și pentru tema întunecată.'**
  String get highContrastUIHelpNote;

  /// No description provided for @assistantStatusOverlayHelpTitle.
  ///
  /// In ro, this message translates to:
  /// **'Suprapunere Status Asistent'**
  String get assistantStatusOverlayHelpTitle;

  /// No description provided for @assistantStatusOverlayHelpOverview.
  ///
  /// In ro, this message translates to:
  /// **'Suprapunerea Status Asistent afișează un indicator mic în colțul ecranului care arată când asistentul AI procesează comenzi.'**
  String get assistantStatusOverlayHelpOverview;

  /// No description provided for @assistantStatusOverlayHelpHowToEnable.
  ///
  /// In ro, this message translates to:
  /// **'Cum să activați Suprapunerea Status Asistent:'**
  String get assistantStatusOverlayHelpHowToEnable;

  /// No description provided for @assistantStatusOverlayHelpGoToMenu.
  ///
  /// In ro, this message translates to:
  /// **'1. Accesați meniul hamburger'**
  String get assistantStatusOverlayHelpGoToMenu;

  /// No description provided for @assistantStatusOverlayHelpTapToggle.
  ///
  /// In ro, this message translates to:
  /// **'2. Găsiți opțiunea \'Suprapunere status asistent\''**
  String get assistantStatusOverlayHelpTapToggle;

  /// No description provided for @assistantStatusOverlayHelpActivate.
  ///
  /// In ro, this message translates to:
  /// **'3. Activați toggle-ul'**
  String get assistantStatusOverlayHelpActivate;

  /// No description provided for @assistantStatusOverlayHelpWhatItShows.
  ///
  /// In ro, this message translates to:
  /// **'Ce afișează indicatorul:'**
  String get assistantStatusOverlayHelpWhatItShows;

  /// No description provided for @assistantStatusOverlayHelpWorking.
  ///
  /// In ro, this message translates to:
  /// **'• \'Lucrez\' - când asistentul AI procesează comenzi sau interacționează cu utilizatorul'**
  String get assistantStatusOverlayHelpWorking;

  /// No description provided for @assistantStatusOverlayHelpWaiting.
  ///
  /// In ro, this message translates to:
  /// **'• \'Aștept comenzi\' - când asistentul AI este inactiv și așteaptă comenzi'**
  String get assistantStatusOverlayHelpWaiting;

  /// No description provided for @assistantStatusOverlayHelpLocation.
  ///
  /// In ro, this message translates to:
  /// **'Unde apare indicatorul:'**
  String get assistantStatusOverlayHelpLocation;

  /// No description provided for @assistantStatusOverlayHelpTopRight.
  ///
  /// In ro, this message translates to:
  /// **'• Indicatorul apare în colțul din dreapta sus al ecranului'**
  String get assistantStatusOverlayHelpTopRight;

  /// No description provided for @assistantStatusOverlayHelpNonIntrusive.
  ///
  /// In ro, this message translates to:
  /// **'• Este non-intruziv și nu interferează cu utilizarea aplicației'**
  String get assistantStatusOverlayHelpNonIntrusive;

  /// No description provided for @assistantStatusOverlayHelpBenefits.
  ///
  /// In ro, this message translates to:
  /// **'Beneficii:'**
  String get assistantStatusOverlayHelpBenefits;

  /// No description provided for @assistantStatusOverlayHelpVisualFeedback.
  ///
  /// In ro, this message translates to:
  /// **'• Feedback vizual rapid despre starea asistentului AI'**
  String get assistantStatusOverlayHelpVisualFeedback;

  /// No description provided for @assistantStatusOverlayHelpDebugging.
  ///
  /// In ro, this message translates to:
  /// **'• Util pentru debugging și înțelegerea când AI-ul lucrează'**
  String get assistantStatusOverlayHelpDebugging;

  /// No description provided for @assistantStatusOverlayHelpTransparency.
  ///
  /// In ro, this message translates to:
  /// **'• Transparență despre activitatea asistentului'**
  String get assistantStatusOverlayHelpTransparency;

  /// No description provided for @assistantStatusOverlayHelpNote.
  ///
  /// In ro, this message translates to:
  /// **'Notă: Indicatorul se actualizează automat când pornești sau oprești interacțiunea vocală cu AI-ul.'**
  String get assistantStatusOverlayHelpNote;

  /// No description provided for @securityAndSafety.
  ///
  /// In ro, this message translates to:
  /// **'Siguranță și Securitate'**
  String get securityAndSafety;

  /// No description provided for @changePasswordSubtitle.
  ///
  /// In ro, this message translates to:
  /// **'Modifică parola contului tău'**
  String get changePasswordSubtitle;

  /// No description provided for @sessions.
  ///
  /// In ro, this message translates to:
  /// **'Sesiuni'**
  String get sessions;

  /// No description provided for @logoutAllDevices.
  ///
  /// In ro, this message translates to:
  /// **'Deconectare de pe toate dispozitivele'**
  String get logoutAllDevices;

  /// No description provided for @logoutAllDevicesSubtitle.
  ///
  /// In ro, this message translates to:
  /// **'Ieșire din cont pe toate dispozitivele conectate'**
  String get logoutAllDevicesSubtitle;

  /// No description provided for @dangerZone.
  ///
  /// In ro, this message translates to:
  /// **'Zonă periculoasă'**
  String get dangerZone;

  /// No description provided for @deleteAccount.
  ///
  /// In ro, this message translates to:
  /// **'Ștergere cont'**
  String get deleteAccount;

  /// No description provided for @deleteAccountSubtitle.
  ///
  /// In ro, this message translates to:
  /// **'Șterge permanent contul și toate datele asociate'**
  String get deleteAccountSubtitle;

  /// No description provided for @confirmLogoutAllDevicesTitle.
  ///
  /// In ro, this message translates to:
  /// **'Deconectare de pe toate dispozitivele'**
  String get confirmLogoutAllDevicesTitle;

  /// No description provided for @confirmLogoutAllDevicesContent.
  ///
  /// In ro, this message translates to:
  /// **'Vei fi deconectat de pe toate dispozitivele, inclusiv cel curent. Va trebui să te autentifici din nou.'**
  String get confirmLogoutAllDevicesContent;

  /// No description provided for @disconnect.
  ///
  /// In ro, this message translates to:
  /// **'Deconectează'**
  String get disconnect;

  /// No description provided for @permanentDeleteAccount.
  ///
  /// In ro, this message translates to:
  /// **'Ștergere cont permanent'**
  String get permanentDeleteAccount;

  /// No description provided for @attention.
  ///
  /// In ro, this message translates to:
  /// **'Atenție! Această acțiune este ireversibilă.'**
  String get attention;

  /// No description provided for @willBeDeletedTitle.
  ///
  /// In ro, this message translates to:
  /// **'Vor fi șterse definitiv:'**
  String get willBeDeletedTitle;

  /// No description provided for @willBeDeletedProfile.
  ///
  /// In ro, this message translates to:
  /// **'• Profilul tău'**
  String get willBeDeletedProfile;

  /// No description provided for @willBeDeletedRideHistory.
  ///
  /// In ro, this message translates to:
  /// **'• Istoricul curselor'**
  String get willBeDeletedRideHistory;

  /// No description provided for @willBeDeletedData.
  ///
  /// In ro, this message translates to:
  /// **'• Toate datele asociate contului'**
  String get willBeDeletedData;

  /// No description provided for @accountPassword.
  ///
  /// In ro, this message translates to:
  /// **'Parola contului'**
  String get accountPassword;

  /// No description provided for @enterPasswordConfirm.
  ///
  /// In ro, this message translates to:
  /// **'Introduceți parola pentru confirmare.'**
  String get enterPasswordConfirm;

  /// No description provided for @deleteAccountButton.
  ///
  /// In ro, this message translates to:
  /// **'Ștergere cont'**
  String get deleteAccountButton;

  /// No description provided for @errorPrefix.
  ///
  /// In ro, this message translates to:
  /// **'Eroare: {error}'**
  String errorPrefix(Object error);

  /// No description provided for @notificationPreferences.
  ///
  /// In ro, this message translates to:
  /// **'Preferințe notificări'**
  String get notificationPreferences;

  /// No description provided for @notifRideSection.
  ///
  /// In ro, this message translates to:
  /// **'Curse'**
  String get notifRideSection;

  /// No description provided for @notifRideNotifications.
  ///
  /// In ro, this message translates to:
  /// **'Notificări curse'**
  String get notifRideNotifications;

  /// No description provided for @notifRideNotificationsSubtitle.
  ///
  /// In ro, this message translates to:
  /// **'Solicitări noi, cursă acceptată, șofer în apropiere etc.'**
  String get notifRideNotificationsSubtitle;

  /// No description provided for @notifCommunicationSection.
  ///
  /// In ro, this message translates to:
  /// **'Comunicare'**
  String get notifCommunicationSection;

  /// No description provided for @notifChatMessages.
  ///
  /// In ro, this message translates to:
  /// **'Mesaje chat'**
  String get notifChatMessages;

  /// No description provided for @notifChatMessagesSubtitle.
  ///
  /// In ro, this message translates to:
  /// **'Notificări pentru mesaje noi din conversații'**
  String get notifChatMessagesSubtitle;

  /// No description provided for @notifMarketingSection.
  ///
  /// In ro, this message translates to:
  /// **'Marketing și actualizări'**
  String get notifMarketingSection;

  /// No description provided for @notifPromoOffers.
  ///
  /// In ro, this message translates to:
  /// **'Promoții și oferte'**
  String get notifPromoOffers;

  /// No description provided for @notifPromoOffersSubtitle.
  ///
  /// In ro, this message translates to:
  /// **'Reduceri, coduri promoționale și oferte speciale'**
  String get notifPromoOffersSubtitle;

  /// No description provided for @notifAppUpdates.
  ///
  /// In ro, this message translates to:
  /// **'Actualizări aplicație'**
  String get notifAppUpdates;

  /// No description provided for @notifAppUpdatesSubtitle.
  ///
  /// In ro, this message translates to:
  /// **'Noutăți și îmbunătățiri ale aplicației'**
  String get notifAppUpdatesSubtitle;

  /// No description provided for @notifSafetySection.
  ///
  /// In ro, this message translates to:
  /// **'Siguranță'**
  String get notifSafetySection;

  /// No description provided for @notifSafetyAlerts.
  ///
  /// In ro, this message translates to:
  /// **'Alerte de siguranță'**
  String get notifSafetyAlerts;

  /// No description provided for @notifSafetyAlertsSubtitle.
  ///
  /// In ro, this message translates to:
  /// **'Notificări importante legate de siguranța ta în cursă'**
  String get notifSafetyAlertsSubtitle;

  /// No description provided for @notifSavedSuccess.
  ///
  /// In ro, this message translates to:
  /// **'Preferințe salvate cu succes.'**
  String get notifSavedSuccess;

  /// No description provided for @notifLoadError.
  ///
  /// In ro, this message translates to:
  /// **'Eroare la încărcarea preferințelor: {error}'**
  String notifLoadError(Object error);

  /// No description provided for @notifSaveError.
  ///
  /// In ro, this message translates to:
  /// **'Eroare la salvare: {error}'**
  String notifSaveError(Object error);

  /// No description provided for @privacyLocationSection.
  ///
  /// In ro, this message translates to:
  /// **'Locație'**
  String get privacyLocationSection;

  /// No description provided for @privacyLocationSharing.
  ///
  /// In ro, this message translates to:
  /// **'Partajare locație în timp real'**
  String get privacyLocationSharing;

  /// No description provided for @privacyLocationSharingSubtitle.
  ///
  /// In ro, this message translates to:
  /// **'Permite partajarea locației tale cu șoferul în timpul cursei'**
  String get privacyLocationSharingSubtitle;

  /// No description provided for @privacyProfileSection.
  ///
  /// In ro, this message translates to:
  /// **'Profil'**
  String get privacyProfileSection;

  /// No description provided for @privacyProfileVisibility.
  ///
  /// In ro, this message translates to:
  /// **'Vizibilitate profil pentru șoferi'**
  String get privacyProfileVisibility;

  /// No description provided for @privacyProfileVisibilitySubtitle.
  ///
  /// In ro, this message translates to:
  /// **'Șoferii pot vedea profilul tău (nume, fotografie, rating)'**
  String get privacyProfileVisibilitySubtitle;

  /// No description provided for @privacyRideHistoryVisible.
  ///
  /// In ro, this message translates to:
  /// **'Istoricul curselor vizibil'**
  String get privacyRideHistoryVisible;

  /// No description provided for @privacyRideHistoryVisibleSubtitle.
  ///
  /// In ro, this message translates to:
  /// **'Permite afișarea istoricului curselor în profilul tău public'**
  String get privacyRideHistoryVisibleSubtitle;

  /// No description provided for @privacyDataSection.
  ///
  /// In ro, this message translates to:
  /// **'Date și analiză'**
  String get privacyDataSection;

  /// No description provided for @privacyAnalyticsConsent.
  ///
  /// In ro, this message translates to:
  /// **'Date pentru îmbunătățirea serviciului'**
  String get privacyAnalyticsConsent;

  /// No description provided for @privacyAnalyticsConsentSubtitle.
  ///
  /// In ro, this message translates to:
  /// **'Ajută-ne să îmbunătățim aplicația prin partajarea datelor de utilizare anonime'**
  String get privacyAnalyticsConsentSubtitle;

  /// No description provided for @privacyGdprNote.
  ///
  /// In ro, this message translates to:
  /// **'Datele tale sunt procesate conform GDPR. Poți solicita exportul sau ștergerea datelor din secțiunea Siguranță și Securitate.'**
  String get privacyGdprNote;

  /// No description provided for @privacySavedSuccess.
  ///
  /// In ro, this message translates to:
  /// **'Setări de confidențialitate salvate.'**
  String get privacySavedSuccess;

  /// No description provided for @privacyLoadError.
  ///
  /// In ro, this message translates to:
  /// **'Eroare la încărcarea setărilor: {error}'**
  String privacyLoadError(Object error);

  /// No description provided for @privacySaveError.
  ///
  /// In ro, this message translates to:
  /// **'Eroare la salvare: {error}'**
  String privacySaveError(Object error);

  /// No description provided for @adminDocumentReview.
  ///
  /// In ro, this message translates to:
  /// **'Verificare Documente Șoferi'**
  String get adminDocumentReview;

  /// No description provided for @noPendingApplications.
  ///
  /// In ro, this message translates to:
  /// **'Nu există aplicații în așteptare.'**
  String get noPendingApplications;

  /// No description provided for @unknownApplicant.
  ///
  /// In ro, this message translates to:
  /// **'Aplicant necunoscut'**
  String get unknownApplicant;

  /// No description provided for @statusLabel.
  ///
  /// In ro, this message translates to:
  /// **'Status: {status}'**
  String statusLabel(Object status);

  /// No description provided for @missingRequired.
  ///
  /// In ro, this message translates to:
  /// **'Lipsă (obligatoriu)'**
  String get missingRequired;

  /// No description provided for @missing.
  ///
  /// In ro, this message translates to:
  /// **'Lipsă'**
  String get missing;

  /// No description provided for @rejectDocumentTitle.
  ///
  /// In ro, this message translates to:
  /// **'Respinge: {name}'**
  String rejectDocumentTitle(Object name);

  /// No description provided for @rejectReason.
  ///
  /// In ro, this message translates to:
  /// **'Motiv respingere'**
  String get rejectReason;

  /// No description provided for @rejectionHint.
  ///
  /// In ro, this message translates to:
  /// **'ex. Imagine neclară, document expirat'**
  String get rejectionHint;

  /// No description provided for @documentApproved.
  ///
  /// In ro, this message translates to:
  /// **'✅ {name} aprobat'**
  String documentApproved(Object name);

  /// No description provided for @documentRejected.
  ///
  /// In ro, this message translates to:
  /// **'❌ {name} respins'**
  String documentRejected(Object name);

  /// No description provided for @activateDriver.
  ///
  /// In ro, this message translates to:
  /// **'Activează Șofer'**
  String get activateDriver;

  /// No description provided for @driverActivatedTitle.
  ///
  /// In ro, this message translates to:
  /// **'Șofer Activat ✅'**
  String get driverActivatedTitle;

  /// No description provided for @driverActivatedContent.
  ///
  /// In ro, this message translates to:
  /// **'{name} a fost activat cu succes.'**
  String driverActivatedContent(Object name);

  /// No description provided for @accessCodeLabel.
  ///
  /// In ro, this message translates to:
  /// **'Cod de acces:'**
  String get accessCodeLabel;

  /// No description provided for @accessCodeGenerated.
  ///
  /// In ro, this message translates to:
  /// **'Cod de acces generat:'**
  String get accessCodeGenerated;

  /// No description provided for @sendCodeToDriver.
  ///
  /// In ro, this message translates to:
  /// **'Transmiteți acest cod șoferului.'**
  String get sendCodeToDriver;

  /// No description provided for @activationError.
  ///
  /// In ro, this message translates to:
  /// **'Eroare la activare: {error}'**
  String activationError(Object error);

  /// No description provided for @approveTooltip.
  ///
  /// In ro, this message translates to:
  /// **'Aprobă'**
  String get approveTooltip;

  /// No description provided for @rejectTooltip.
  ///
  /// In ro, this message translates to:
  /// **'Respinge'**
  String get rejectTooltip;

  /// No description provided for @rejectionReasonLabel.
  ///
  /// In ro, this message translates to:
  /// **'Motiv: {reason}'**
  String rejectionReasonLabel(Object reason);

  /// No description provided for @statusSubmitted.
  ///
  /// In ro, this message translates to:
  /// **'Trimis'**
  String get statusSubmitted;

  /// No description provided for @statusUnderReview.
  ///
  /// In ro, this message translates to:
  /// **'În revizuire'**
  String get statusUnderReview;

  /// No description provided for @statusApproved.
  ///
  /// In ro, this message translates to:
  /// **'Aprobat'**
  String get statusApproved;

  /// No description provided for @statusActivated.
  ///
  /// In ro, this message translates to:
  /// **'Activat'**
  String get statusActivated;

  /// No description provided for @statusRejected.
  ///
  /// In ro, this message translates to:
  /// **'Respins'**
  String get statusRejected;

  /// No description provided for @docStatusApproved.
  ///
  /// In ro, this message translates to:
  /// **'Aprobat'**
  String get docStatusApproved;

  /// No description provided for @docStatusRejected.
  ///
  /// In ro, this message translates to:
  /// **'Respins'**
  String get docStatusRejected;

  /// No description provided for @docStatusPending.
  ///
  /// In ro, this message translates to:
  /// **'În așteptare'**
  String get docStatusPending;

  /// No description provided for @docExpiresOn.
  ///
  /// In ro, this message translates to:
  /// **'Expiră: {date}'**
  String docExpiresOn(Object date);

  /// No description provided for @docExpiredLabel.
  ///
  /// In ro, this message translates to:
  /// **'EXPIRAT ({date})'**
  String docExpiredLabel(Object date);

  /// No description provided for @docExpiringSoonLabel.
  ///
  /// In ro, this message translates to:
  /// **'Expiră în curând ({date})'**
  String docExpiringSoonLabel(Object date);

  /// No description provided for @bePartnerDriver.
  ///
  /// In ro, this message translates to:
  /// **'Devino Șofer Partener'**
  String get bePartnerDriver;

  /// No description provided for @applicationProgress.
  ///
  /// In ro, this message translates to:
  /// **'Progres aplicație'**
  String get applicationProgress;

  /// No description provided for @applicationComplete.
  ///
  /// In ro, this message translates to:
  /// **'Aplicația este completă și poate fi trimisă!'**
  String get applicationComplete;

  /// No description provided for @applicationIncomplete.
  ///
  /// In ro, this message translates to:
  /// **'Completați informațiile și documentele pentru a continua'**
  String get applicationIncomplete;

  /// No description provided for @accountActivated.
  ///
  /// In ro, this message translates to:
  /// **'Cont Activat 🎉'**
  String get accountActivated;

  /// No description provided for @accessCodeGeneratedAt.
  ///
  /// In ro, this message translates to:
  /// **'Generat la: {date}'**
  String accessCodeGeneratedAt(Object date);

  /// No description provided for @personalInfoStep.
  ///
  /// In ro, this message translates to:
  /// **'Informații Personale'**
  String get personalInfoStep;

  /// No description provided for @vehicleInfoStep.
  ///
  /// In ro, this message translates to:
  /// **'Informații Autovehicul'**
  String get vehicleInfoStep;

  /// No description provided for @finalDocumentsStep.
  ///
  /// In ro, this message translates to:
  /// **'Documente Finale'**
  String get finalDocumentsStep;

  /// No description provided for @fullNameLabel.
  ///
  /// In ro, this message translates to:
  /// **'Nume Complet *'**
  String get fullNameLabel;

  /// No description provided for @ageLabel.
  ///
  /// In ro, this message translates to:
  /// **'Vârstă *'**
  String get ageLabel;

  /// No description provided for @carBrandLabel.
  ///
  /// In ro, this message translates to:
  /// **'Marcă *'**
  String get carBrandLabel;

  /// No description provided for @carModelLabel.
  ///
  /// In ro, this message translates to:
  /// **'Model *'**
  String get carModelLabel;

  /// No description provided for @carColorLabel.
  ///
  /// In ro, this message translates to:
  /// **'Culoare *'**
  String get carColorLabel;

  /// No description provided for @carYearLabel.
  ///
  /// In ro, this message translates to:
  /// **'An Fabricație *'**
  String get carYearLabel;

  /// No description provided for @licensePlateLabel.
  ///
  /// In ro, this message translates to:
  /// **'Număr Înmatriculare *'**
  String get licensePlateLabel;

  /// No description provided for @bankAccountLabel.
  ///
  /// In ro, this message translates to:
  /// **'Cont Bancar (IBAN)'**
  String get bankAccountLabel;

  /// No description provided for @importantInfoTitle.
  ///
  /// In ro, this message translates to:
  /// **'Informații importante'**
  String get importantInfoTitle;

  /// No description provided for @applicationConfirmationText.
  ///
  /// In ro, this message translates to:
  /// **'Prin trimiterea aplicației, confirmați că:\n• Toate informațiile furnizate sunt corecte\n• Sunteți de acord cu Termenii și Condițiile\n• Acceptați verificarea documentelor\n• Aveți cel puțin 21 de ani împliniți'**
  String get applicationConfirmationText;

  /// No description provided for @applicationIncompleteWarning.
  ///
  /// In ro, this message translates to:
  /// **'Vă rugăm să completați toate câmpurile obligatorii și să încărcați documentele necesare înainte de a trimite aplicația.'**
  String get applicationIncompleteWarning;

  /// No description provided for @applicationSubmitSuccess.
  ///
  /// In ro, this message translates to:
  /// **'Aplicația a fost trimisă cu succes pentru verificare!'**
  String get applicationSubmitSuccess;

  /// No description provided for @applicationLoadError.
  ///
  /// In ro, this message translates to:
  /// **'Eroare la încărcarea datelor: {error}'**
  String applicationLoadError(Object error);

  /// No description provided for @applicationSaveError.
  ///
  /// In ro, this message translates to:
  /// **'Eroare la salvarea datelor: {error}'**
  String applicationSaveError(Object error);

  /// No description provided for @applicationSubmitError.
  ///
  /// In ro, this message translates to:
  /// **'Eroare la trimiterea aplicației: {error}'**
  String applicationSubmitError(Object error);

  /// No description provided for @documentUploadSuccess.
  ///
  /// In ro, this message translates to:
  /// **'{name} a fost încărcat cu succes!'**
  String documentUploadSuccess(Object name);

  /// No description provided for @documentDeleteSuccess.
  ///
  /// In ro, this message translates to:
  /// **'{name} a fost șters cu succes!'**
  String documentDeleteSuccess(Object name);

  /// No description provided for @documentUploadError.
  ///
  /// In ro, this message translates to:
  /// **'Eroare la încărcarea documentului: {error}'**
  String documentUploadError(Object error);

  /// No description provided for @documentDeleteError.
  ///
  /// In ro, this message translates to:
  /// **'Eroare la ștergerea documentului: {error}'**
  String documentDeleteError(Object error);

  /// No description provided for @selectSourceTitle.
  ///
  /// In ro, this message translates to:
  /// **'Selectează sursa'**
  String get selectSourceTitle;

  /// No description provided for @selectSourceContent.
  ///
  /// In ro, this message translates to:
  /// **'De unde dorești să selectezi imaginea?'**
  String get selectSourceContent;

  /// No description provided for @cameraOption.
  ///
  /// In ro, this message translates to:
  /// **'Cameră'**
  String get cameraOption;

  /// No description provided for @galleryOption.
  ///
  /// In ro, this message translates to:
  /// **'Galerie'**
  String get galleryOption;

  /// No description provided for @selectFileTypeTitle.
  ///
  /// In ro, this message translates to:
  /// **'Selectează tipul fișierului'**
  String get selectFileTypeTitle;

  /// No description provided for @selectFileTypeContent.
  ///
  /// In ro, this message translates to:
  /// **'Dorești să încarci o imagine sau un document PDF?'**
  String get selectFileTypeContent;

  /// No description provided for @imageOption.
  ///
  /// In ro, this message translates to:
  /// **'Imagine'**
  String get imageOption;

  /// No description provided for @pdfOption.
  ///
  /// In ro, this message translates to:
  /// **'PDF'**
  String get pdfOption;

  /// No description provided for @requiredBadge.
  ///
  /// In ro, this message translates to:
  /// **'Obligatoriu'**
  String get requiredBadge;

  /// No description provided for @documentUploadedText.
  ///
  /// In ro, this message translates to:
  /// **'Document încărcat cu succes'**
  String get documentUploadedText;

  /// No description provided for @tapToUploadText.
  ///
  /// In ro, this message translates to:
  /// **'Apasă pentru a încărca documentul'**
  String get tapToUploadText;

  /// No description provided for @continueBtn.
  ///
  /// In ro, this message translates to:
  /// **'Continuă'**
  String get continueBtn;

  /// No description provided for @submitApplication.
  ///
  /// In ro, this message translates to:
  /// **'Trimite Aplicația'**
  String get submitApplication;

  /// No description provided for @backBtn.
  ///
  /// In ro, this message translates to:
  /// **'Înapoi'**
  String get backBtn;

  /// No description provided for @expiryDateTitle.
  ///
  /// In ro, this message translates to:
  /// **'Dată expirare'**
  String get expiryDateTitle;

  /// No description provided for @expiryDateQuestion.
  ///
  /// In ro, this message translates to:
  /// **'Doriți să setați data de expirare pentru \"{name}\"?'**
  String expiryDateQuestion(Object name);

  /// No description provided for @skipExpiry.
  ///
  /// In ro, this message translates to:
  /// **'Nu, sari peste'**
  String get skipExpiry;

  /// No description provided for @photographOption.
  ///
  /// In ro, this message translates to:
  /// **'Fotografiază'**
  String get photographOption;

  /// No description provided for @selectFromGallery.
  ///
  /// In ro, this message translates to:
  /// **'Selectează din galerie'**
  String get selectFromGallery;

  /// No description provided for @viewDocumentOption.
  ///
  /// In ro, this message translates to:
  /// **'Vizualizează'**
  String get viewDocumentOption;

  /// No description provided for @deleteDocumentOption.
  ///
  /// In ro, this message translates to:
  /// **'Șterge'**
  String get deleteDocumentOption;

  /// No description provided for @pdfDocument.
  ///
  /// In ro, this message translates to:
  /// **'Document PDF'**
  String get pdfDocument;

  /// No description provided for @tapToOpen.
  ///
  /// In ro, this message translates to:
  /// **'Apasă pentru a deschide'**
  String get tapToOpen;

  /// No description provided for @errorLoadingImage.
  ///
  /// In ro, this message translates to:
  /// **'Eroare la încărcarea imaginii'**
  String get errorLoadingImage;

  /// No description provided for @fileTooLarge.
  ///
  /// In ro, this message translates to:
  /// **'Fișierul este prea mare (max 10MB)'**
  String get fileTooLarge;

  /// No description provided for @serviceUnavailable.
  ///
  /// In ro, this message translates to:
  /// **'Serviciul nu este disponibil temporar'**
  String get serviceUnavailable;

  /// No description provided for @connectionError.
  ///
  /// In ro, this message translates to:
  /// **'Problemă de conexiune. Verificați internetul'**
  String get connectionError;

  /// No description provided for @uploadedAt.
  ///
  /// In ro, this message translates to:
  /// **'Încărcat: {date}'**
  String uploadedAt(Object date);

  /// No description provided for @selectExpiryDate.
  ///
  /// In ro, this message translates to:
  /// **'Selectați data de expirare'**
  String get selectExpiryDate;

  /// No description provided for @yes.
  ///
  /// In ro, this message translates to:
  /// **'Da'**
  String get yes;

  /// No description provided for @drawerSectionActivityAccount.
  ///
  /// In ro, this message translates to:
  /// **'Activitate și cont'**
  String get drawerSectionActivityAccount;

  /// No description provided for @drawerSectionYourCommunity.
  ///
  /// In ro, this message translates to:
  /// **'Comunitatea ta'**
  String get drawerSectionYourCommunity;

  /// No description provided for @drawerSectionMyBusiness.
  ///
  /// In ro, this message translates to:
  /// **'Afacerea mea'**
  String get drawerSectionMyBusiness;

  /// No description provided for @drawerSectionGetInvolved.
  ///
  /// In ro, this message translates to:
  /// **'Implicare'**
  String get drawerSectionGetInvolved;

  /// No description provided for @drawerSectionAiPerformance.
  ///
  /// In ro, this message translates to:
  /// **'AI și performanță'**
  String get drawerSectionAiPerformance;

  /// No description provided for @drawerSectionSupportInfo.
  ///
  /// In ro, this message translates to:
  /// **'Suport și informații'**
  String get drawerSectionSupportInfo;

  /// No description provided for @drawerSectionAddresses.
  ///
  /// In ro, this message translates to:
  /// **'Adrese'**
  String get drawerSectionAddresses;

  /// No description provided for @drawerFavoriteAddresses.
  ///
  /// In ro, this message translates to:
  /// **'Adrese favorite'**
  String get drawerFavoriteAddresses;

  /// No description provided for @drawerBusinessOffersTitle.
  ///
  /// In ro, this message translates to:
  /// **'Oferte din cartier'**
  String get drawerBusinessOffersTitle;

  /// No description provided for @drawerSocialMapTitle.
  ///
  /// In ro, this message translates to:
  /// **'Harta socială'**
  String get drawerSocialMapTitle;

  /// No description provided for @drawerSocialVisible.
  ///
  /// In ro, this message translates to:
  /// **'Vizibil'**
  String get drawerSocialVisible;

  /// No description provided for @drawerSocialHidden.
  ///
  /// In ro, this message translates to:
  /// **'Ascuns'**
  String get drawerSocialHidden;

  /// No description provided for @drawerVoiceAiSettingsTitle.
  ///
  /// In ro, this message translates to:
  /// **'Setări voce AI'**
  String get drawerVoiceAiSettingsTitle;

  /// No description provided for @drawerBusinessDashboardTitle.
  ///
  /// In ro, this message translates to:
  /// **'Panoul meu: {businessName}'**
  String drawerBusinessDashboardTitle(String businessName);

  /// No description provided for @drawerBusinessRegisterTitle.
  ///
  /// In ro, this message translates to:
  /// **'Înregistrează-ți afacerea'**
  String get drawerBusinessRegisterTitle;

  /// No description provided for @businessIntroTitle.
  ///
  /// In ro, this message translates to:
  /// **'Afacerea mea'**
  String get businessIntroTitle;

  /// No description provided for @businessIntroBody.
  ///
  /// In ro, this message translates to:
  /// **'Trebuie mai întâi să îți înregistrezi afacerea. După înregistrare o poți administra: editezi cardul afișat în Oferte din cartier și gestionezi anunțurile (adaugi, modifici sau ștergi) din Panoul de business.'**
  String get businessIntroBody;

  /// No description provided for @businessIntroContinueButton.
  ///
  /// In ro, this message translates to:
  /// **'Continuă la înregistrare'**
  String get businessIntroContinueButton;

  /// No description provided for @drawerTeamNabour.
  ///
  /// In ro, this message translates to:
  /// **'Echipa Nabour'**
  String get drawerTeamNabour;

  /// No description provided for @drawerRolePassenger.
  ///
  /// In ro, this message translates to:
  /// **'Pasager'**
  String get drawerRolePassenger;

  /// No description provided for @drawerRoleDriver.
  ///
  /// In ro, this message translates to:
  /// **'Șofer'**
  String get drawerRoleDriver;

  /// No description provided for @drawerThemeDarkLabel.
  ///
  /// In ro, this message translates to:
  /// **'Temă: întunecată'**
  String get drawerThemeDarkLabel;

  /// No description provided for @drawerThemeLightLabel.
  ///
  /// In ro, this message translates to:
  /// **'Temă: deschisă'**
  String get drawerThemeLightLabel;

  /// No description provided for @drawerMenuWeekReview.
  ///
  /// In ro, this message translates to:
  /// **'Recap săptămână'**
  String get drawerMenuWeekReview;

  /// No description provided for @drawerMenuMysteryBoxActivity.
  ///
  /// In ro, this message translates to:
  /// **'Activitate cutii'**
  String get drawerMenuMysteryBoxActivity;

  /// No description provided for @drawerMenuMyGarage.
  ///
  /// In ro, this message translates to:
  /// **'Garajul meu'**
  String get drawerMenuMyGarage;

  /// No description provided for @drawerMenuPlaces.
  ///
  /// In ro, this message translates to:
  /// **'Locuri'**
  String get drawerMenuPlaces;

  /// No description provided for @drawerMenuExplorations.
  ///
  /// In ro, this message translates to:
  /// **'Explorări'**
  String get drawerMenuExplorations;

  /// No description provided for @drawerMenuSyncContacts.
  ///
  /// In ro, this message translates to:
  /// **'Sincronizează contactele'**
  String get drawerMenuSyncContacts;

  /// No description provided for @drawerSyncContactsDialogTitle.
  ///
  /// In ro, this message translates to:
  /// **'De ce sincronizare?'**
  String get drawerSyncContactsDialogTitle;

  /// No description provided for @drawerSyncContactsDialogBody.
  ///
  /// In ro, this message translates to:
  /// **'Aplicația îți arată pe hartă doar persoanele care sunt în agenda ta și care folosesc Nabour.\n\nDacă ai adăugat un contact nou sau un prieten tocmai s-a înscris, apasă „Sincronizează” pentru a actualiza lista de vizibilitate pe harta socială.'**
  String get drawerSyncContactsDialogBody;

  /// No description provided for @drawerSyncContactsDialogOk.
  ///
  /// In ro, this message translates to:
  /// **'Înțeles'**
  String get drawerSyncContactsDialogOk;

  /// No description provided for @warmupCloseTooltip.
  ///
  /// In ro, this message translates to:
  /// **'Închide'**
  String get warmupCloseTooltip;

  /// No description provided for @warmupHeadline.
  ///
  /// In ro, this message translates to:
  /// **'Călătorește cu\nvecinii tăi'**
  String get warmupHeadline;

  /// No description provided for @warmupShortcutsTitle.
  ///
  /// In ro, this message translates to:
  /// **'Scurtături'**
  String get warmupShortcutsTitle;

  /// No description provided for @warmupShortcutRideTitle.
  ///
  /// In ro, this message translates to:
  /// **'Cursă'**
  String get warmupShortcutRideTitle;

  /// No description provided for @warmupShortcutRideSubtitle.
  ///
  /// In ro, this message translates to:
  /// **'Cere acum'**
  String get warmupShortcutRideSubtitle;

  /// No description provided for @warmupShortcutMapTitle.
  ///
  /// In ro, this message translates to:
  /// **'Hartă'**
  String get warmupShortcutMapTitle;

  /// No description provided for @warmupShortcutMapSubtitle.
  ///
  /// In ro, this message translates to:
  /// **'Disponibili în zonă'**
  String get warmupShortcutMapSubtitle;

  /// No description provided for @warmupShortcutChatTitle.
  ///
  /// In ro, this message translates to:
  /// **'Chat'**
  String get warmupShortcutChatTitle;

  /// No description provided for @warmupShortcutChatSubtitle.
  ///
  /// In ro, this message translates to:
  /// **'Cartierul tău'**
  String get warmupShortcutChatSubtitle;

  /// No description provided for @warmupScheduleTitle.
  ///
  /// In ro, this message translates to:
  /// **'Planifică mai târziu'**
  String get warmupScheduleTitle;

  /// No description provided for @warmupScheduleSubtitle.
  ///
  /// In ro, this message translates to:
  /// **'Anunță din timp — vecinii confirmă când sunt liberi.'**
  String get warmupScheduleSubtitle;

  /// No description provided for @warmupWhyTitle.
  ///
  /// In ro, this message translates to:
  /// **'De ce Nabour?'**
  String get warmupWhyTitle;

  /// No description provided for @warmupCtaOpenMap.
  ///
  /// In ro, this message translates to:
  /// **'Deschide harta'**
  String get warmupCtaOpenMap;

  /// No description provided for @warmupSwipeDownHint.
  ///
  /// In ro, this message translates to:
  /// **'Sau trage în jos pentru a închide'**
  String get warmupSwipeDownHint;

  /// No description provided for @warmupHeroNeighborsTitle.
  ///
  /// In ro, this message translates to:
  /// **'Curse între vecini'**
  String get warmupHeroNeighborsTitle;

  /// No description provided for @warmupHeroNeighborsSubtitle.
  ///
  /// In ro, this message translates to:
  /// **'Cere o cursă pe hartă; șoferii disponibili din comunitate te pot prelua.'**
  String get warmupHeroNeighborsSubtitle;

  /// No description provided for @warmupHeroBusinessTitle.
  ///
  /// In ro, this message translates to:
  /// **'Oferte locale'**
  String get warmupHeroBusinessTitle;

  /// No description provided for @warmupHeroBusinessSubtitle.
  ///
  /// In ro, this message translates to:
  /// **'Promovează afacerea cu anunțuri vizibile în zonă, direct din app.'**
  String get warmupHeroBusinessSubtitle;

  /// No description provided for @warmupHeroSafetyTitle.
  ///
  /// In ro, this message translates to:
  /// **'Siguranță la drum'**
  String get warmupHeroSafetyTitle;

  /// No description provided for @warmupHeroSafetySubtitle.
  ///
  /// In ro, this message translates to:
  /// **'Partajare traseu live, chat în cursă și verificări clare la îmbarcare.'**
  String get warmupHeroSafetySubtitle;

  /// No description provided for @warmupHeroChatTitle.
  ///
  /// In ro, this message translates to:
  /// **'Chat de cartier'**
  String get warmupHeroChatTitle;

  /// No description provided for @warmupHeroChatSubtitle.
  ///
  /// In ro, this message translates to:
  /// **'Conversații în zona ta; poți filtra și după contactele din telefon.'**
  String get warmupHeroChatSubtitle;

  /// No description provided for @warmupFeatureCommunityTitle.
  ///
  /// In ro, this message translates to:
  /// **'Ecosistem unificat'**
  String get warmupFeatureCommunityTitle;

  /// No description provided for @warmupFeatureCommunitySubtitle.
  ///
  /// In ro, this message translates to:
  /// **'Curse, chat și oferte într-o singură aplicație — mai simplu decât să sari între grupuri.'**
  String get warmupFeatureCommunitySubtitle;

  /// No description provided for @warmupFeatureContactsTitle.
  ///
  /// In ro, this message translates to:
  /// **'Încredere controlată'**
  String get warmupFeatureContactsTitle;

  /// No description provided for @warmupFeatureContactsSubtitle.
  ///
  /// In ro, this message translates to:
  /// **'Alege cine te vede: comunitatea din zonă sau doar oameni din agendă.'**
  String get warmupFeatureContactsSubtitle;

  /// No description provided for @warmupFeatureLiveTitle.
  ///
  /// In ro, this message translates to:
  /// **'Live pe hartă'**
  String get warmupFeatureLiveTitle;

  /// No description provided for @warmupFeatureLiveSubtitle.
  ///
  /// In ro, this message translates to:
  /// **'Disponibilitate și status actualizate, ca să știi rapid cine poate ajuta.'**
  String get warmupFeatureLiveSubtitle;

  /// No description provided for @warmupFeatureSecureTitle.
  ///
  /// In ro, this message translates to:
  /// **'Transparent și previzibil'**
  String get warmupFeatureSecureTitle;

  /// No description provided for @warmupFeatureSecureSubtitle.
  ///
  /// In ro, this message translates to:
  /// **'Istoric, tokeni clari pentru acțiuni și suport când ai nevoie.'**
  String get warmupFeatureSecureSubtitle;

  /// No description provided for @drawerDefaultUserName.
  ///
  /// In ro, this message translates to:
  /// **'Utilizator'**
  String get drawerDefaultUserName;

  /// No description provided for @drawerTrialPrivilegedTitle.
  ///
  /// In ro, this message translates to:
  /// **'Cont privilegiat'**
  String get drawerTrialPrivilegedTitle;

  /// No description provided for @drawerTrialPrivilegedSubtitle.
  ///
  /// In ro, this message translates to:
  /// **'Acces nelimitat la toate funcționalitățile.'**
  String get drawerTrialPrivilegedSubtitle;

  /// No description provided for @drawerTrialSevenDayTitle.
  ///
  /// In ro, this message translates to:
  /// **'7 zile trial'**
  String get drawerTrialSevenDayTitle;

  /// No description provided for @drawerTrialPricingSubtitle.
  ///
  /// In ro, this message translates to:
  /// **'Apoi 10 RON/lună (PF) sau 15 RON/lună (firme).'**
  String get drawerTrialPricingSubtitle;

  /// No description provided for @drawerTrialDuringSubtitle.
  ///
  /// In ro, this message translates to:
  /// **'Apoi 10 RON/lună (PF) / 15 RON/lună (firme).'**
  String get drawerTrialDuringSubtitle;

  /// No description provided for @drawerTrialDaysLeftTitle.
  ///
  /// In ro, this message translates to:
  /// **'{count, plural, =1{O zi rămasă din trial} other{{count} zile rămase din trial}}'**
  String drawerTrialDaysLeftTitle(num count);

  /// No description provided for @drawerTrialExpiredTitle.
  ///
  /// In ro, this message translates to:
  /// **'Trial expirat'**
  String get drawerTrialExpiredTitle;

  /// No description provided for @drawerTrialExpiredSubtitle.
  ///
  /// In ro, this message translates to:
  /// **'Abonează-te (10/15 RON) pentru a continua.'**
  String get drawerTrialExpiredSubtitle;

  /// No description provided for @activateDriverCodeLabel.
  ///
  /// In ro, this message translates to:
  /// **'Cod de activare'**
  String get activateDriverCodeLabel;

  /// No description provided for @activateDriverCodeHint.
  ///
  /// In ro, this message translates to:
  /// **'Ex: DRV-TEST-102'**
  String get activateDriverCodeHint;

  /// No description provided for @tokenShopTitle.
  ///
  /// In ro, this message translates to:
  /// **'Tokeni și planuri'**
  String get tokenShopTitle;

  /// No description provided for @tokenShopTabPlans.
  ///
  /// In ro, this message translates to:
  /// **'Planuri'**
  String get tokenShopTabPlans;

  /// No description provided for @tokenShopTabTopup.
  ///
  /// In ro, this message translates to:
  /// **'Top-up'**
  String get tokenShopTabTopup;

  /// No description provided for @tokenShopTabHistory.
  ///
  /// In ro, this message translates to:
  /// **'Istoric'**
  String get tokenShopTabHistory;

  /// No description provided for @tokenShopChoosePlanTitle.
  ///
  /// In ro, this message translates to:
  /// **'Alege planul tău'**
  String get tokenShopChoosePlanTitle;

  /// No description provided for @tokenShopChoosePlanSubtitle.
  ///
  /// In ro, this message translates to:
  /// **'Tokenii se resetează în prima zi a fiecărei luni'**
  String get tokenShopChoosePlanSubtitle;

  /// No description provided for @tokenShopAlreadyOnPlan.
  ///
  /// In ro, this message translates to:
  /// **'Deja ești pe acest plan.'**
  String get tokenShopAlreadyOnPlan;

  /// No description provided for @tokenShopDowngradeContactSupport.
  ///
  /// In ro, this message translates to:
  /// **'Contactează suportul pentru downgrade.'**
  String get tokenShopDowngradeContactSupport;

  /// No description provided for @tokenShopUpgradeSuccess.
  ///
  /// In ro, this message translates to:
  /// **'Upgrade la {planName} realizat!'**
  String tokenShopUpgradeSuccess(String planName);

  /// No description provided for @tokenShopErrorPaymentsNotReady.
  ///
  /// In ro, this message translates to:
  /// **'Plățile nu sunt încă activate pe server. Configurează Cloud Functions (vezi functions/).'**
  String get tokenShopErrorPaymentsNotReady;

  /// No description provided for @tokenShopErrorWithMessage.
  ///
  /// In ro, this message translates to:
  /// **'Eroare: {message}'**
  String tokenShopErrorWithMessage(String message);

  /// No description provided for @tokenShopUpgradeError.
  ///
  /// In ro, this message translates to:
  /// **'Eroare upgrade: {error}'**
  String tokenShopUpgradeError(String error);

  /// No description provided for @tokenShopMostPopular.
  ///
  /// In ro, this message translates to:
  /// **'CEL MAI POPULAR'**
  String get tokenShopMostPopular;

  /// No description provided for @tokenShopPopularBadge.
  ///
  /// In ro, this message translates to:
  /// **'POPULAR'**
  String get tokenShopPopularBadge;

  /// No description provided for @tokenShopActive.
  ///
  /// In ro, this message translates to:
  /// **'Activ'**
  String get tokenShopActive;

  /// No description provided for @tokenShopSelect.
  ///
  /// In ro, this message translates to:
  /// **'Selectează'**
  String get tokenShopSelect;

  /// No description provided for @tokenShopBuyExtraTitle.
  ///
  /// In ro, this message translates to:
  /// **'Cumpără tokeni extra'**
  String get tokenShopBuyExtraTitle;

  /// No description provided for @tokenShopBuyExtraSubtitle.
  ///
  /// In ro, this message translates to:
  /// **'Tokenii cumpărați nu expiră niciodată'**
  String get tokenShopBuyExtraSubtitle;

  /// No description provided for @tokenShopTokensWord.
  ///
  /// In ro, this message translates to:
  /// **'tokeni'**
  String get tokenShopTokensWord;

  /// No description provided for @tokenShopTokensAdded.
  ///
  /// In ro, this message translates to:
  /// **'+{count} tokeni adăugați în cont!'**
  String tokenShopTokensAdded(int count);

  /// No description provided for @tokenShopTopupRequiresBackend.
  ///
  /// In ro, this message translates to:
  /// **'Top-up necesită backend (ALLOW_UNVERIFIED_WALLET_CREDIT sau plată reală).'**
  String get tokenShopTopupRequiresBackend;

  /// No description provided for @tokenShopNoTransactions.
  ///
  /// In ro, this message translates to:
  /// **'Nicio tranzacție încă.'**
  String get tokenShopNoTransactions;

  /// No description provided for @tokenShopPaymentMethodsTitle.
  ///
  /// In ro, this message translates to:
  /// **'Metode de plată acceptate'**
  String get tokenShopPaymentMethodsTitle;

  /// No description provided for @tokenShopPaymentSecureFooter.
  ///
  /// In ro, this message translates to:
  /// **'Plățile sunt procesate securizat. Nu stocăm datele cardului.'**
  String get tokenShopPaymentSecureFooter;

  /// No description provided for @tokenShopPaymentMethodTitle.
  ///
  /// In ro, this message translates to:
  /// **'Metodă de plată'**
  String get tokenShopPaymentMethodTitle;

  /// No description provided for @tokenShopPay.
  ///
  /// In ro, this message translates to:
  /// **'Plătește'**
  String get tokenShopPay;

  /// No description provided for @tokenShopTestModeDisclaimer.
  ///
  /// In ro, this message translates to:
  /// **'Plățile reale nu sunt încă conectate. „Plătește” simulează tranzacția: planul și tokenii se actualizează prin server (Firebase Functions). Dacă apare eroare, rulează „firebase deploy --only functions” sau setează parametrul ALLOW_UNVERIFIED_WALLET_CREDIT=true în consolă.'**
  String get tokenShopTestModeDisclaimer;

  /// No description provided for @tokenShopMethodNetopia.
  ///
  /// In ro, this message translates to:
  /// **'Netopia (card RO)'**
  String get tokenShopMethodNetopia;

  /// No description provided for @tokenShopMethodStripe.
  ///
  /// In ro, this message translates to:
  /// **'Stripe'**
  String get tokenShopMethodStripe;

  /// No description provided for @tokenShopMethodRevolut.
  ///
  /// In ro, this message translates to:
  /// **'Revolut Pay'**
  String get tokenShopMethodRevolut;

  /// No description provided for @tokenShopPackageStarter.
  ///
  /// In ro, this message translates to:
  /// **'Starter'**
  String get tokenShopPackageStarter;

  /// No description provided for @tokenShopPackagePopular.
  ///
  /// In ro, this message translates to:
  /// **'Popular'**
  String get tokenShopPackagePopular;

  /// No description provided for @tokenShopPackageAdvanced.
  ///
  /// In ro, this message translates to:
  /// **'Avansat'**
  String get tokenShopPackageAdvanced;

  /// No description provided for @tokenShopPackageBusiness.
  ///
  /// In ro, this message translates to:
  /// **'Business'**
  String get tokenShopPackageBusiness;

  /// No description provided for @tokenPlanFreeName.
  ///
  /// In ro, this message translates to:
  /// **'Gratuit'**
  String get tokenPlanFreeName;

  /// No description provided for @tokenPlanBasicName.
  ///
  /// In ro, this message translates to:
  /// **'Basic'**
  String get tokenPlanBasicName;

  /// No description provided for @tokenPlanProName.
  ///
  /// In ro, this message translates to:
  /// **'Pro'**
  String get tokenPlanProName;

  /// No description provided for @tokenPlanUnlimitedName.
  ///
  /// In ro, this message translates to:
  /// **'Unlimited'**
  String get tokenPlanUnlimitedName;

  /// No description provided for @tokenPlanPriceFree.
  ///
  /// In ro, this message translates to:
  /// **'Gratuit'**
  String get tokenPlanPriceFree;

  /// No description provided for @tokenPlanPriceBasic.
  ///
  /// In ro, this message translates to:
  /// **'9 RON / lună'**
  String get tokenPlanPriceBasic;

  /// No description provided for @tokenPlanPricePro.
  ///
  /// In ro, this message translates to:
  /// **'29 RON / lună'**
  String get tokenPlanPricePro;

  /// No description provided for @tokenPlanPriceUnlimited.
  ///
  /// In ro, this message translates to:
  /// **'49 RON / lună'**
  String get tokenPlanPriceUnlimited;

  /// No description provided for @tokenShopPlanAllowanceMonthly.
  ///
  /// In ro, this message translates to:
  /// **'{allowance} tokeni / lună'**
  String tokenShopPlanAllowanceMonthly(String allowance);

  /// No description provided for @tokenShopEconomyApproxLine.
  ///
  /// In ro, this message translates to:
  /// **'≈ {ai} AI · {routes} rute · {geo} geocodări · {br} postări'**
  String tokenShopEconomyApproxLine(int ai, int routes, int geo, int br);

  /// No description provided for @tokenShopEconomyBusinessLine.
  ///
  /// In ro, this message translates to:
  /// **'≈ {biz} anunțuri business ({tokens} tokeni/anunț)'**
  String tokenShopEconomyBusinessLine(int biz, int tokens);

  /// No description provided for @tokenShopEconomyUnlimited.
  ///
  /// In ro, this message translates to:
  /// **'Nelimitat: AI, rute, geocodare și postări fără consum din cotă lunară.'**
  String get tokenShopEconomyUnlimited;

  /// No description provided for @tokenShopStaffMenuTooltip.
  ///
  /// In ro, this message translates to:
  /// **'Setare abonament staff'**
  String get tokenShopStaffMenuTooltip;

  /// No description provided for @tokenShopStaffDialogTitle.
  ///
  /// In ro, this message translates to:
  /// **'Abonament staff (cont autorizat)'**
  String get tokenShopStaffDialogTitle;

  /// No description provided for @tokenShopStaffApplied.
  ///
  /// In ro, this message translates to:
  /// **'Abonament aplicat.'**
  String get tokenShopStaffApplied;

  /// No description provided for @tokenShopTxPurchasePackage.
  ///
  /// In ro, this message translates to:
  /// **'Pachet {label} · {count} tokeni'**
  String tokenShopTxPurchasePackage(String label, int count);

  /// No description provided for @appMissionTagline.
  ///
  /// In ro, this message translates to:
  /// **'Vecini, curse și chat de cartier — într-o singură aplicație, pe harta ta.'**
  String get appMissionTagline;

  /// No description provided for @settingsSectionUpdates.
  ///
  /// In ro, this message translates to:
  /// **'Actualizări'**
  String get settingsSectionUpdates;

  /// No description provided for @settingsSectionInterfaceData.
  ///
  /// In ro, this message translates to:
  /// **'Interfață și date'**
  String get settingsSectionInterfaceData;

  /// No description provided for @settingsSectionPrivacyLanguage.
  ///
  /// In ro, this message translates to:
  /// **'Confidențialitate și limbă'**
  String get settingsSectionPrivacyLanguage;

  /// No description provided for @settingsVisibilityExclusionsTitle.
  ///
  /// In ro, this message translates to:
  /// **'Excluderi vizibilitate'**
  String get settingsVisibilityExclusionsTitle;

  /// No description provided for @settingsVisibilityExclusionsSubtitle.
  ///
  /// In ro, this message translates to:
  /// **'Alege cine nu te poate vedea pe harta socială'**
  String get settingsVisibilityExclusionsSubtitle;

  /// No description provided for @driverMenuViewDailyReport.
  ///
  /// In ro, this message translates to:
  /// **'Vezi raportul zilnic'**
  String get driverMenuViewDailyReport;

  /// No description provided for @accountScreenTitle.
  ///
  /// In ro, this message translates to:
  /// **'Cont Nabour'**
  String get accountScreenTitle;

  /// No description provided for @accountDefaultNeighbor.
  ///
  /// In ro, this message translates to:
  /// **'Vecin'**
  String get accountDefaultNeighbor;

  /// No description provided for @accountDriverPartnerBadge.
  ///
  /// In ro, this message translates to:
  /// **'Șofer partener Nabour'**
  String get accountDriverPartnerBadge;

  /// No description provided for @accountMenuDriverVehicleDetails.
  ///
  /// In ro, this message translates to:
  /// **'Detalii șofer și autovehicul'**
  String get accountMenuDriverVehicleDetails;

  /// No description provided for @accountMenuPersonalDetails.
  ///
  /// In ro, this message translates to:
  /// **'Date personale'**
  String get accountMenuPersonalDetails;

  /// No description provided for @accountMenuSecurity.
  ///
  /// In ro, this message translates to:
  /// **'Siguranță și cont'**
  String get accountMenuSecurity;

  /// No description provided for @accountMenuSavedAddresses.
  ///
  /// In ro, this message translates to:
  /// **'Adrese salvate'**
  String get accountMenuSavedAddresses;

  /// No description provided for @accountMenuRidePreferences.
  ///
  /// In ro, this message translates to:
  /// **'Preferințe cursă'**
  String get accountMenuRidePreferences;

  /// No description provided for @accountMenuRideHistory.
  ///
  /// In ro, this message translates to:
  /// **'Istoric curse'**
  String get accountMenuRideHistory;

  /// No description provided for @accountMenuBusinessProfile.
  ///
  /// In ro, this message translates to:
  /// **'Profil business'**
  String get accountMenuBusinessProfile;

  /// No description provided for @accountMenuSelfieVerification.
  ///
  /// In ro, this message translates to:
  /// **'Verificare identitate (selfie)'**
  String get accountMenuSelfieVerification;

  /// No description provided for @accountMenuNotifications.
  ///
  /// In ro, this message translates to:
  /// **'Notificări'**
  String get accountMenuNotifications;

  /// No description provided for @accountMenuPrivacy.
  ///
  /// In ro, this message translates to:
  /// **'Confidențialitate'**
  String get accountMenuPrivacy;

  /// No description provided for @accountDeleteTitle.
  ///
  /// In ro, this message translates to:
  /// **'Șterge contul definitiv'**
  String get accountDeleteTitle;

  /// No description provided for @accountDeleteBody.
  ///
  /// In ro, this message translates to:
  /// **'Acțiunea este ireversibilă. Introdu parola pentru a confirma.'**
  String get accountDeleteBody;

  /// No description provided for @accountDeletePasswordLabel.
  ///
  /// In ro, this message translates to:
  /// **'Parolă'**
  String get accountDeletePasswordLabel;

  /// No description provided for @accountDeletePasswordError.
  ///
  /// In ro, this message translates to:
  /// **'Introdu parola.'**
  String get accountDeletePasswordError;

  /// No description provided for @accountDeleteConfirm.
  ///
  /// In ro, this message translates to:
  /// **'Șterge contul'**
  String get accountDeleteConfirm;

  /// No description provided for @tokenWalletBalanceShort.
  ///
  /// In ro, this message translates to:
  /// **'{balance} tokeni'**
  String tokenWalletBalanceShort(String balance);

  /// No description provided for @tokenWalletDrawerSubline.
  ///
  /// In ro, this message translates to:
  /// **'{spent} / {allowance} folosiți · reset {when}'**
  String tokenWalletDrawerSubline(String spent, String allowance, String when);

  /// No description provided for @tokenWalletAvailableLong.
  ///
  /// In ro, this message translates to:
  /// **'{balance} tokeni disponibili'**
  String tokenWalletAvailableLong(String balance);

  /// No description provided for @tokenWalletPlanLine.
  ///
  /// In ro, this message translates to:
  /// **'Plan {planName}'**
  String tokenWalletPlanLine(String planName);

  /// No description provided for @tokenWalletUsedThisMonth.
  ///
  /// In ro, this message translates to:
  /// **'Folosit luna aceasta'**
  String get tokenWalletUsedThisMonth;

  /// No description provided for @tokenWalletPercentUsage.
  ///
  /// In ro, this message translates to:
  /// **'{pct}% ({spent} / {allowance})'**
  String tokenWalletPercentUsage(String pct, String spent, String allowance);

  /// No description provided for @tokenWalletAutoReset.
  ///
  /// In ro, this message translates to:
  /// **'Reset automat: {when}'**
  String tokenWalletAutoReset(String when);

  /// No description provided for @tokenWalletStatTotalSpent.
  ///
  /// In ro, this message translates to:
  /// **'Total consumat'**
  String get tokenWalletStatTotalSpent;

  /// No description provided for @tokenWalletStatTotalEarned.
  ///
  /// In ro, this message translates to:
  /// **'Total primit'**
  String get tokenWalletStatTotalEarned;

  /// No description provided for @tokenWalletOpenShopCta.
  ///
  /// In ro, this message translates to:
  /// **'Tokeni și planuri'**
  String get tokenWalletOpenShopCta;

  /// No description provided for @tokenWalletResetInDays.
  ///
  /// In ro, this message translates to:
  /// **'în {days} zile'**
  String tokenWalletResetInDays(int days);

  /// No description provided for @tokenWalletResetInHours.
  ///
  /// In ro, this message translates to:
  /// **'în {hours} h'**
  String tokenWalletResetInHours(int hours);

  /// No description provided for @tokenWalletResetTomorrow.
  ///
  /// In ro, this message translates to:
  /// **'mâine'**
  String get tokenWalletResetTomorrow;

  /// No description provided for @helpWeekReviewTitle.
  ///
  /// In ro, this message translates to:
  /// **'Week in Review și istoricul locațiilor'**
  String get helpWeekReviewTitle;

  /// No description provided for @helpWeekReviewHeader.
  ///
  /// In ro, this message translates to:
  /// **'Cum funcționează Week in Review'**
  String get helpWeekReviewHeader;

  /// No description provided for @helpWeekReviewIntro.
  ///
  /// In ro, this message translates to:
  /// **'Week in Review construiește un recap vizual al deplasărilor tale pe o perioadă selectată (de obicei ultima săptămână), cu traseu animat, hotspot-uri și statistici (km / ore active).'**
  String get helpWeekReviewIntro;

  /// No description provided for @helpWeekReviewDataSourceTitle.
  ///
  /// In ro, this message translates to:
  /// **'De unde se iau datele'**
  String get helpWeekReviewDataSourceTitle;

  /// No description provided for @helpWeekReviewDataSourceBody.
  ///
  /// In ro, this message translates to:
  /// **'Aplicația folosește punctele brute de locație din backend doar ca sursă de input pentru generarea recap-ului.'**
  String get helpWeekReviewDataSourceBody;

  /// No description provided for @helpWeekReviewStorageTitle.
  ///
  /// In ro, this message translates to:
  /// **'Unde se stochează recap-ul'**
  String get helpWeekReviewStorageTitle;

  /// No description provided for @helpWeekReviewStorageBody.
  ///
  /// In ro, this message translates to:
  /// **'Istoricul procesat, timeline-ul, hotspot-urile și exporturile Week in Review sunt stocate local, pe dispozitivul tău.'**
  String get helpWeekReviewStorageBody;

  /// No description provided for @helpWeekReviewDeleteTitle.
  ///
  /// In ro, this message translates to:
  /// **'Cum se șterge'**
  String get helpWeekReviewDeleteTitle;

  /// No description provided for @helpWeekReviewDeleteBody.
  ///
  /// In ro, this message translates to:
  /// **'Mergi în Setări -> Istoric locație (Timeline) -> Șterge istoricul local. Poți seta și retenția locală (ex: 30/60/90 zile).'**
  String get helpWeekReviewDeleteBody;

  /// No description provided for @helpWeekReviewPrivacyNote.
  ///
  /// In ro, this message translates to:
  /// **'Privacy-first: recap-ul și fișierele exportate rămân locale pe telefon. Tu controlezi retenția și ștergerea lor.'**
  String get helpWeekReviewPrivacyNote;

  /// No description provided for @businessOffersNoOffersInSelectedCategory.
  ///
  /// In ro, this message translates to:
  /// **'Nu există oferte în categoria selectată'**
  String get businessOffersNoOffersInSelectedCategory;

  /// No description provided for @businessOffersNoOffersInArea.
  ///
  /// In ro, this message translates to:
  /// **'Nu există oferte în zona ta'**
  String get businessOffersNoOffersInArea;

  /// No description provided for @businessOffersTryAnotherCategory.
  ///
  /// In ro, this message translates to:
  /// **'Încearcă o altă categorie.'**
  String get businessOffersTryAnotherCategory;

  /// No description provided for @businessOffersNoNearbyOffers.
  ///
  /// In ro, this message translates to:
  /// **'Revino mai târziu pentru oferte noi în apropiere.'**
  String get businessOffersNoNearbyOffers;

  /// No description provided for @businessOffersManageFilters.
  ///
  /// In ro, this message translates to:
  /// **'Gestionează filtrele'**
  String get businessOffersManageFilters;

  /// No description provided for @businessOffersResetCategory.
  ///
  /// In ro, this message translates to:
  /// **'Resetează categoria'**
  String get businessOffersResetCategory;

  /// No description provided for @businessOffersAllCategories.
  ///
  /// In ro, this message translates to:
  /// **'Toate categoriile'**
  String get businessOffersAllCategories;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ro'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ro':
      return AppLocalizationsRo();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}

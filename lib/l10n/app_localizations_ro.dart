// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Romanian Moldavian Moldovan (`ro`).
class AppLocalizationsRo extends AppLocalizations {
  AppLocalizationsRo([String locale = 'ro']) : super(locale);

  @override
  String get appTitle => 'Nabour';

  @override
  String get driverMode => 'Mod Șofer';

  @override
  String get passengerMode => 'Mod Pasager';

  @override
  String get requestRide => 'Solicită Cursă';

  @override
  String get acceptRide => 'Acceptă';

  @override
  String get declineRide => 'Refuză';

  @override
  String get cancelRide => 'Anulează Cursa';

  @override
  String get myLocation => 'Locația mea';

  @override
  String get offline => 'Offline';

  @override
  String get online => 'Online';

  @override
  String get available => 'Disponibil';

  @override
  String get unavailable => 'Indisponibil';

  @override
  String get activeRide => 'Cursă Activă';

  @override
  String get rideHistory => 'Istoric Curse';

  @override
  String get profile => 'Profil';

  @override
  String get settings => 'Setări';

  @override
  String get startNavigation => 'Navigarea a început';

  @override
  String get navigationEnded => 'Navigarea s-a încheiat';

  @override
  String get arrived => 'Ați ajuns la destinație';

  @override
  String get routeDeviation => 'Recalculez traseul';

  @override
  String get preparingRoute => 'Pregătesc traseul';

  @override
  String turnLeft(String distance) {
    return 'Virați la stânga peste $distance';
  }

  @override
  String turnRight(String distance) {
    return 'Virați la dreapta peste $distance';
  }

  @override
  String turnSlightLeft(String distance) {
    return 'Virați ușor la stânga peste $distance';
  }

  @override
  String turnSlightRight(String distance) {
    return 'Virați ușor la dreapta peste $distance';
  }

  @override
  String continueForward(String distance) {
    return 'Continuați înainte pentru $distance';
  }

  @override
  String makeUturn(String distance) {
    return 'Faceți întoarcere peste $distance';
  }

  @override
  String get meters => 'metri';

  @override
  String get kilometers => 'kilometri';

  @override
  String get meter => 'metru';

  @override
  String get kilometer => 'kilometru';

  @override
  String get driverHeadingToYou => 'Șoferul este pe drum...';

  @override
  String get driverArrived => 'Șoferul a sosit!';

  @override
  String get rideInProgress => 'Cursă în desfășurare';

  @override
  String get confirmDriver => 'Confirmă Șoferul';

  @override
  String get confirmButton => 'Confirmă';

  @override
  String get declineButton => 'Refuză';

  @override
  String get iArrived => 'Am ajuns';

  @override
  String get startRide => 'Pornește cursa';

  @override
  String get endRide => 'Termină Cursa';

  @override
  String get waitingForPassenger => 'Așteaptă pasagerul.';

  @override
  String get headingToPassenger => 'Mergi spre pasager.';

  @override
  String get communicateWithDriver => 'Comunică cu șoferul:';

  @override
  String get call => 'Sună';

  @override
  String get message => 'Mesaj';

  @override
  String get chat => 'Chat';

  @override
  String get writeMessage => 'Scrie un mesaj...';

  @override
  String get send => 'Trimite';

  @override
  String get emergency => 'Urgență';

  @override
  String get navigationTo => 'Navighează spre';

  @override
  String get navigation => 'Navigație';

  @override
  String get chooseNavigationApp => 'Alege aplicația de navigație';

  @override
  String get googleMaps => 'Google Maps';

  @override
  String get waze => 'Waze';

  @override
  String get locationNotAvailable =>
      'Locația nu este încă disponibilă pentru partajare.';

  @override
  String get shareLocation => 'Partajează Locația';

  @override
  String get navigateToPassenger => 'Navighează spre pasager';

  @override
  String get navigateToDestination => 'Navighează spre destinație';

  @override
  String get rideCompleted => 'Cursă finalizată';

  @override
  String get rideCancelled => 'Cursă anulată';

  @override
  String get rideExpired => 'Cursă expirată';

  @override
  String get offlineDriverMessage =>
      'Ești indisponibil ca șofer. Activează comutatorul pentru a primi curse sau solicită o cursă ca pasager.';

  @override
  String get noPendingRides => 'Nicio cerere de cursă disponibilă momentan.';

  @override
  String rideToDestination(String destination) {
    return 'Către: $destination';
  }

  @override
  String get cost => 'Serviciu';

  @override
  String distance(String km) {
    return 'Distanță ($km km):';
  }

  @override
  String get ron => 'Puncte';

  @override
  String get km => 'km';

  @override
  String get language => 'Limba';

  @override
  String get romanian => 'Română';

  @override
  String get english => 'English';

  @override
  String get errorInitializingRide => 'Eroare la inițializarea cursei';

  @override
  String get errorMonitoringRide => 'Eroare la monitorizarea cursei';

  @override
  String get cannotOpenNavigation =>
      'Nu s-a putut deschide nicio aplicație de navigație.';

  @override
  String get cannotMakeCall => 'Nu s-a putut iniția apelul.';

  @override
  String get joinTeamTitle => 'Alătură-te echipei Nabour!';

  @override
  String get joinTeamDescription =>
      'Devino șofer partener. Află mai multe aici.';

  @override
  String get youHaveActiveRide =>
      'Ai o cursă activă. Atinge pentru a vedea detaliile.';

  @override
  String get categoryStandardSubtitle =>
      'Cea mai accesibilă opțiune pentru călătoriile tale.';

  @override
  String get categoryFamilySubtitle =>
      'Mai mult spațiu pentru pasageri și bagaje.';

  @override
  String get categoryEnergySubtitle =>
      'Călătorește eco-friendly cu vehicule electrice sau hibride.';

  @override
  String get categoryBestSubtitle =>
      'Experiență premium cu vehicule de lux și șoferi de top.';

  @override
  String get aiAssistant => 'Asistent AI';

  @override
  String get voiceSettings => 'Setări Vocale';

  @override
  String get voiceDemo => 'Demo Voce AI';

  @override
  String get microphoneTest => 'Test Microfon';

  @override
  String get aiLibraryTest => 'Test Biblioteca AI';

  @override
  String get receipts => 'Activitate';

  @override
  String get driverDashboard => 'Panou de Bord Nabour';

  @override
  String get subscriptions => 'Abonamente';

  @override
  String get safety => 'Siguranță';

  @override
  String get help => 'Ajutor';

  @override
  String get aiVoiceSettings => '🎤 Setări Vocale AI';

  @override
  String get voiceAIDemo => '🗣️ Demo Voice AI';

  @override
  String get microphoneTestTool => '🔧 Test Microfon';

  @override
  String get aiLibraryTestTool => '🧠 Test Biblioteca AI';

  @override
  String get about => 'Despre';

  @override
  String get legal => 'Juridic';

  @override
  String get logout => 'DECONECTARE';

  @override
  String get about_titleNabour => 'Despre Nabour';

  @override
  String get about_evaluateApp => 'Evaluează Aplicația';

  @override
  String get about_howManyStars => 'Câte stele dai aplicației Nabour?';

  @override
  String get about_starSelected => 'stea selectată';

  @override
  String get about_starsSelected => 'stele selectate';

  @override
  String get cancel => 'Anulează';

  @override
  String get select => 'Selectează';

  @override
  String about_ratingSentSuccessfully(String rating) {
    return '✅ Rating de $rating stele trimis cu succes!';
  }

  @override
  String get about_career => 'Carieră';

  @override
  String get about_joinOurTeam => 'Alătură-te echipei noastre';

  @override
  String get about_evaluateApplication => 'Evaluează aplicația';

  @override
  String get about_giveStarRating => '⭐ Dă un rating cu stele';

  @override
  String get about_followUs => 'Urmărește-ne';

  @override
  String get legalInformation => 'Informații Juridice';

  @override
  String get termsConditions => 'Termeni & Condiții';

  @override
  String get privacy => 'Privacy';

  @override
  String get termsConditionsTitle => 'Termeni și Condiții';

  @override
  String get generalProvisions => 'Prevederi Generale';

  @override
  String get generalProvisionsText =>
      'Anularea unei curse după alocarea unui șofer partener poate atrage o taxă de anulare pentru a compensa timpul și distanța parcursă de către șofer. Anularea este gratuită oricând înainte de alocarea unui șofer partener.';

  @override
  String get standardWaitTime => 'Timp de Așteptare Standard';

  @override
  String get standardWaitTimeText =>
      'După sosirea la locația de preluare, șoferul partener va aștepta gratuit timp de 5 minute. După expirarea acestui interval, se pot aplica taxe suplimentare de așteptare sau cursa poate fi anulată, aplicându-se taxa de anulare corespunzătoare.';

  @override
  String get specificCategoryPolicies => 'Politici Specifice pe Categorii';

  @override
  String get cancellationFee => 'Taxă de Anulare:';

  @override
  String get freeCancellation => 'Anulare Gratuită (Curse Rezervate):';

  @override
  String get minimumBookingTime => 'Timp Minim de Rezervare:';

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
      'Cu cel puțin 1 oră și 30 de minute înainte de ora programată.';

  @override
  String get standardMinBooking =>
      'Cu cel puțin 2 ore în avans față de ora rezervării cursei.';

  @override
  String get energyMinBooking =>
      'Cu cel puțin 2 ore în avans față de ora rezervării cursei.';

  @override
  String get bestMinBooking =>
      'Cu cel puțin 2 ore în avans față de ora rezervării cursei.';

  @override
  String get familyMinBooking =>
      'Cu cel puțin 2 ore în avans față de ora rezervării cursei.';

  @override
  String get privacyPolicyContent =>
      'Aici va fi afișat conținutul detaliat al Politicii de Confidențialitate, conform normelor GDPR. Documentul va explica ce tipuri de date personale sunt colectate (nume, email, locație, date de plată, etc.), scopul colectării (funcționarea serviciului, marketing, siguranță), cum sunt stocate și protejate datele, perioada de retenție, și care sunt drepturile utilizatorilor (dreptul la acces, rectificare, ștergere, etc.).\n\nTextul complet va fi furnizat de un consultant juridic pentru a asigura conformitatea cu legislația în vigoare.';

  @override
  String get wallet => 'Portofel';

  @override
  String get currentBalance => 'Balanță Curentă';

  @override
  String get paymentMethods => 'Metode de Plată';

  @override
  String get addOrManageCards => 'Adaugă sau gestionează cardurile';

  @override
  String get cash => 'Numerar';

  @override
  String get selectPaymentMethod => 'Selectează Metoda de Plată';

  @override
  String get vouchers => 'Vouchere';

  @override
  String get addPromoCode => 'Adaugă un cod promoțional';

  @override
  String get transactionHistory => 'Istoric Tranzacții';

  @override
  String get viewAllPayments => 'Vezi toate plățile și încasările';

  @override
  String get canSendToContact => 'Poți trimite unei persoane de contact';

  @override
  String get addPaymentMethod => 'Adaugă o metodă de plată';

  @override
  String get rideProfiles => 'Profilurile curselor';

  @override
  String get startUsing => 'Începe să folosești';

  @override
  String get friendsRideForBusiness => 'Nabour for Business';

  @override
  String get activateBusinessFeatures =>
      'Activează funcțiile pentru călătorii în interes de serviciu';

  @override
  String get manageBusinessTrips =>
      'Gestionează curse în interes de serviciu pe...';

  @override
  String get requestBusinessProfileAccess =>
      'Solicită accesul la profilul Business';

  @override
  String get addVoucherCode => 'Adaugă codul voucherului';

  @override
  String get promotions => 'Promoţii';

  @override
  String get recommendations => 'Recomandări';

  @override
  String get addReferralCode => 'Adaugă codul de recomandare';

  @override
  String get inStoreOffers => 'Oferte în magazin';

  @override
  String get offers => 'Oferte';

  @override
  String get walletDetails => 'Detalii Portofel';

  @override
  String get walletDetailsInfo =>
      'Nabour Cash este balanța ta digitală. Poți adăuga fonduri pentru plăți mai rapide.';

  @override
  String get addFunds => 'Adaugă Fonduri';

  @override
  String get addFundsComingSoon =>
      'Funcționalitatea de adăugare fonduri va fi disponibilă în curând.';

  @override
  String get paymentMethodDetails => 'Detalii Metodă de Plată';

  @override
  String get brand => 'Brand';

  @override
  String get last4Digits => 'Ultimele 4 cifre';

  @override
  String get cardholder => 'Titular card';

  @override
  String get expiryDate => 'Data expirării';

  @override
  String get cashPaymentMethod => 'Plata se face direct șoferului în numerar.';

  @override
  String get delete => 'Șterge';

  @override
  String get deletePaymentMethodComingSoon =>
      'Funcționalitatea de ștergere metodă de plată va fi disponibilă în curând.';

  @override
  String get businessProfile => 'Profil Business';

  @override
  String get businessProfileInfo =>
      'Activează profilul Business pentru a gestiona curse în interes de serviciu.';

  @override
  String get businessProfileBenefits => 'Beneficii:';

  @override
  String get businessProfileBenefit1 => 'Rapoarte detaliate pentru cheltuieli';

  @override
  String get businessProfileBenefit2 => 'Facturare automată către companie';

  @override
  String get businessProfileBenefit3 => 'Gestionare multiple utilizatori';

  @override
  String get requestAccess => 'Solicită Acces';

  @override
  String get businessProfileRequestSent =>
      'Cererea pentru profil Business a fost trimisă. Vei primi un răspuns în curând.';

  @override
  String get referralCodeInfo =>
      'Introdu codul de recomandare pentru a primi beneficii.';

  @override
  String get enterReferralCode => 'Introdu codul';

  @override
  String get referralCodeApplied =>
      'Codul de recomandare a fost aplicat cu succes!';

  @override
  String get personalProfileActive => 'Profilul Personal este activ.';

  @override
  String get inStoreOffersComingSoon =>
      'Ofertele în magazin vor fi disponibile în curând.';

  @override
  String get close => 'Închide';

  @override
  String get paymentMethodDeleted =>
      'Metoda de plată a fost ștearsă cu succes.';

  @override
  String get errorDeletingPaymentMethod =>
      'Eroare la ștergerea metodei de plată.';

  @override
  String get errorRequestingBusinessProfile =>
      'Eroare la trimiterea cererii pentru profil business.';

  @override
  String get errorApplyingReferralCode =>
      'Eroare la aplicarea codului de recomandare.';

  @override
  String get paymentMethodsHelpTitle => 'Metode de Plată';

  @override
  String get addingPaymentMethod => 'Adăugarea unei metode de plată:';

  @override
  String get goToWalletSection =>
      '• Accesează secțiunea \"Portofel\" din meniul principal';

  @override
  String get tapAddPaymentMethod =>
      '• Apasă pe butonul \"Adaugă o metodă de plată\"';

  @override
  String get selectCardOrCash =>
      '• Selectează tipul de metodă (card sau numerar)';

  @override
  String get enterCardDetails =>
      '• Completează detaliile cardului (număr, dată expirare, CVV)';

  @override
  String get savePaymentMethod => '• Salvează metoda de plată';

  @override
  String get managingPaymentMethods => 'Gestionarea metodelor de plată:';

  @override
  String get viewAllMethodsInWallet =>
      '• Vezi toate metodele salvate în secțiunea \"Portofel\"';

  @override
  String get editOrDeleteMethods => '• Editează sau șterge metodele existente';

  @override
  String get setDefaultPaymentMethod =>
      '• Setează o metodă ca implicită pentru plăți automate';

  @override
  String get paymentMethodsTypes => 'Tipuri de metode de plată:';

  @override
  String get creditDebitCards => '• Carduri de credit/debit (Visa, Mastercard)';

  @override
  String get cashPayment => '• Numerar (plata se face direct șoferului)';

  @override
  String get walletBalance => '• Nabour Cash (balanță în portofel)';

  @override
  String get paymentSecurity => 'Securitate plăți:';

  @override
  String get allPaymentsSecure => '• Toate plățile sunt procesate în siguranță';

  @override
  String get cardDetailsEncrypted =>
      '• Detaliile cardurilor sunt criptate și stocate securizat';

  @override
  String get pciCompliant =>
      '• Aplicația respectă standardele PCI DSS pentru securitate';

  @override
  String get paymentMethodTip => '💡 Sfat util:';

  @override
  String get youCanSendToContact =>
      'Poți trimite bani către persoane de contact folosind metodele de plată salvate.';

  @override
  String get vouchersHelpTitle => 'Vouchere';

  @override
  String get addingVoucher => 'Adăugarea unui voucher:';

  @override
  String get tapVouchersSection =>
      '• Apasă pe secțiunea \"Vouchere\" din Portofel';

  @override
  String get tapAddVoucherCode => '• Apasă pe \"Adaugă codul voucherului\"';

  @override
  String get enterVoucherCode => '• Introdu codul voucherului';

  @override
  String get applyVoucher => '• Apasă \"Aplică\" pentru a activa voucherul';

  @override
  String get usingVouchers => 'Utilizarea voucherelor:';

  @override
  String get vouchersAppliedAutomatically =>
      '• Voucherele se aplică automat la următoarea cursă';

  @override
  String get checkVoucherStatus =>
      '• Verifică statusul voucherelor în secțiunea Vouchere';

  @override
  String get voucherExpiryInfo => '• Voucherele au o dată de expirare';

  @override
  String get voucherTypes => 'Tipuri de vouchere:';

  @override
  String get percentageDiscount => '• Reducere procentuală (ex: 10% reducere)';

  @override
  String get fixedAmountDiscount => '• Reducere fixă (ex: 5 RON reducere)';

  @override
  String get freeRideVoucher => '• Cursă gratuită';

  @override
  String get voucherTip => '💡 Sfat util:';

  @override
  String get oneVoucherPerRide => 'Poți folosi un singur voucher per cursă.';

  @override
  String get walletHelpTitle => 'Portofel';

  @override
  String get walletOverview => 'Prezentare generală:';

  @override
  String get walletOverviewInfo =>
      'Secțiunea Portofel îți permite să gestionezi metodele de plată, voucherele, și balanța Nabour Cash.';

  @override
  String get friendsRideCash => 'Nabour Cash:';

  @override
  String get friendsRideCashInfo => '• Balanță digitală pentru plăți rapide';

  @override
  String get addFundsToWallet => '• Poți adăuga fonduri în portofel';

  @override
  String get useWalletForPayments =>
      '• Poți folosi balanța pentru plăți automate';

  @override
  String get walletSections => 'Secțiuni disponibile:';

  @override
  String get paymentMethodsSection =>
      '• Metode de plată - gestionează cardurile și numerarul';

  @override
  String get vouchersSection =>
      '• Vouchere - adaugă și gestionează coduri promoționale';

  @override
  String get rideProfilesSection =>
      '• Profilurile curselor - Personal și Business';

  @override
  String get promotionsSection =>
      '• Promoții - coduri promoționale și recomandări';

  @override
  String get walletTip => '💡 Sfat util:';

  @override
  String get walletBalanceNeverExpires =>
      'Balanța Nabour Cash nu expiră niciodată.';

  @override
  String get earningsToday => 'Sprijin Oferit Astăzi';

  @override
  String get ridesToday => 'Vecini Ajutați';

  @override
  String get averageRating => 'Rating Comunitate';

  @override
  String get lastCompletedRides => 'Ultimele Curse Finalizate';

  @override
  String get allRides => 'Toate Cursele';

  @override
  String get todayRides => 'Cursele de Astăzi';

  @override
  String get generateDailyReport => 'Generează Raport Zilnic';

  @override
  String get noRidesYet => 'Nicio cursă finalizată încă';

  @override
  String get viewDetails => 'Vezi Detalii';

  @override
  String get addTrustedContact => 'Adaugă contact de încredere';

  @override
  String get name => 'Nume';

  @override
  String get phoneNumber => 'Număr de telefon';

  @override
  String get phoneNumberExample => 'ex: 0712 345 678';

  @override
  String get save => 'Salvează';

  @override
  String contactSaved(String name) {
    return 'Contactul $name a fost salvat.';
  }

  @override
  String get trustedContacts => 'Contacte de încredere';

  @override
  String get noContacts => 'Niciun contact de încredere adăugat încă';

  @override
  String get emergencyCall => 'Apel de Urgență';

  @override
  String get safetyFeatures => 'Funcții de Siguranță';

  @override
  String get emergencyAssistance => 'Asistență de Urgență';

  @override
  String get shareTrip => 'Partajează Cursa';

  @override
  String get reportIncident => 'Raportează Incident';

  @override
  String get helpCenter => 'Centru de Ajutor';

  @override
  String get frequentlyAskedQuestions => 'Întrebări Frecvente';

  @override
  String get contactSupport => 'Contactează Suportul';

  @override
  String get reportProblem => 'Raportează o problemă';

  @override
  String get career => 'Carieră';

  @override
  String get cannotRequestRide => 'Nu pot solicita o cursă';

  @override
  String get cannotRequestRideContent =>
      'Dacă întâmpinați probleme la solicitarea unei curse, încercați următoarele soluții:';

  @override
  String get checkInternetConnection => '2. Verificați conexiunea la internet';

  @override
  String get ensureGpsEnabled => '• Asigurați-vă că locația GPS este activată';

  @override
  String get restartApp => '1. Restartați aplicația';

  @override
  String get checkValidPayment =>
      '• Verificați dacă aveți o metodă de plată validă';

  @override
  String get contactSupportIfPersists =>
      '• Contactați echipa de suport dacă problema persistă';

  @override
  String get pickupTimeLonger =>
      'Timpul de preluare este mai mare decât cel estimat';

  @override
  String get pickupTimeLongerContent =>
      'Timpul estimat poate varia din următoarele motive:';

  @override
  String get unexpectedHeavyTraffic => '• Trafic intens neașteptat';

  @override
  String get unfavorableWeather => '• Condiții meteorologice nefavorabile';

  @override
  String get driverFindingAddress =>
      '• Șoferul poate avea dificultăți în găsirea adresei';

  @override
  String get specialEvents => '• Evenimente speciale în zona dvs.';

  @override
  String get contactDriverDirectly =>
      'Puteți contacta șoferul direct prin aplicație pentru a clarifica situația.';

  @override
  String get rideDidNotHappen => 'Cursa nu a avut loc';

  @override
  String get rideDidNotHappenContent => 'Dacă cursa nu a avut loc, verificați:';

  @override
  String get rideStatusInApp => '• Statusul cursei în aplicație';

  @override
  String get messagesFromDriver => '• Mesajele de la șofer';

  @override
  String get correctLocation => '• Dacă ați fost la locația corectă';

  @override
  String get contactSupportForRefund =>
      'Pentru rambursări, contactați suportul cu detaliile cursei.';

  @override
  String get lostItems => 'Obiecte pierdute';

  @override
  String get lostItemsContent => 'Dacă ați uitat ceva în mașina șoferului:';

  @override
  String get contactDriverImmediately =>
      '1. Contactați imediat șoferul prin aplicație';

  @override
  String get describeLostItem => '2. Descrieți obiectul pierdut';

  @override
  String get arrangePickup => '3. Stabiliți o întâlnire pentru recuperare';

  @override
  String get reportToSupport =>
      '4. Dacă nu reușiți să contactați șoferul, raportați prin suport';

  @override
  String get returnFeeNote =>
      'Notă: Poate fi aplicată o taxă mică pentru returnarea obiectelor.';

  @override
  String get driverDeviatedRoute => 'Șoferul a deviat de la traseu';

  @override
  String get driverDeviatedContent => 'Dacă șoferul a luat o rută diferită:';

  @override
  String get askDriverReason => '• Întrebați șoferul despre motivul schimbării';

  @override
  String get checkTrafficWorks =>
      '• Verificați dacă există trafic sau lucrări pe traseul inițial';

  @override
  String get reportIfUnjustified =>
      '• Dacă considerați că devierea este nejustificată, raportați';

  @override
  String get driversCanChooseAlternatives =>
      'Șoferii pot alege rute alternative pentru a evita traficul.';

  @override
  String get driverDashboardWeeklyActivityTitle => 'Activitate în comunitate';

  @override
  String get driverDashboardWeeklyKudosHeader => 'Aprecieri';

  @override
  String get driverDashboardWeeklyTotalHelpsWeek => 'Total ajutoare săptămână:';

  @override
  String get emergencyAssistanceUsage => 'Utilizarea asistenței de urgență';

  @override
  String get emergencyAssistanceContent => 'Funcția de urgență vă permite să:';

  @override
  String get quickCall112 => '• Apelați rapid 112';

  @override
  String get sendLocationToContact =>
      '• Trimiteți locația dvs. unui contact de urgență';

  @override
  String get reportIncidentToSafety =>
      '• Raportați un incident către echipa de siguranță';

  @override
  String get voiceSettingsSaved => 'Setările vocale au fost salvate';

  @override
  String get availableVoiceCommands => 'Comenzi Vocale Disponibile';

  @override
  String get basicCommands => 'Comenzi de bază:';

  @override
  String get wantRideToDestination => '\"Vreau o cursă la [destinație]\"';

  @override
  String get economyRideToDestination => '\"Cursă economică la [destinație]\"';

  @override
  String get urgentRideToDestination => '\"Cursă urgentă la [destinație]\"';

  @override
  String get premiumRideToDestination => '\"Cursă premium la [destinație]\"';

  @override
  String get commandsDuringRide => 'Comenzi în timpul cursei:';

  @override
  String get sendMessageToDriver => '\"Trimite mesaj șoferului\"';

  @override
  String get whereIsDriver => '\"Unde este șoferul?\"';

  @override
  String get wantToPayCash => '\"Vreau să plătesc cash\"';

  @override
  String get controlCommands => 'Comenzi de control:';

  @override
  String get heyNabour => '\"Hey Nabour\" (activare)';

  @override
  String get helpCommand => '\"Ajutor\" (ajutor)';

  @override
  String get cancelCommand => '\"Anulează\" (anulare)';

  @override
  String get stopCommand => '\"Stop\" (oprire)';

  @override
  String get advancedHelp => 'Ajutor Avansat';

  @override
  String get advancedFeaturesAvailable => 'Funcții avansate disponibile:';

  @override
  String get automaticVoiceActivation => '   - Activare vocală automată';

  @override
  String get customActivationWord => '   - Personalizare cuvânt activare';

  @override
  String get realtimeDetection => '   - Detectare în timp real';

  @override
  String get continuousListening => 'Ascultare continuă';

  @override
  String get continuousListeningForCommands =>
      '   - Ascultare continuă pentru comenzi';

  @override
  String get realtimeProcessing => '   - Procesare în timp real';

  @override
  String get smartBatterySaving => '   - Economie baterie inteligentă';

  @override
  String get multiLanguageSupport => 'Suport multi-limbă';

  @override
  String get supportFor6Languages => '   - Suport pentru 6 limbi';

  @override
  String get voiceSwitchBetweenLanguages => '   - Comutare vocală între limbi';

  @override
  String get localAccentAdaptation => '   - Adaptare accent local';

  @override
  String get privacySecurity => 'Privacy & Security';

  @override
  String get localProcessing => '   - Procesare locală';

  @override
  String get endToEndEncryption => '   - Criptare end-to-end';

  @override
  String get fullDataControl => '   - Control total asupra datelor';

  @override
  String get contactSupportForTechnical =>
      'Pentru asistență tehnică, contactați suportul.';

  @override
  String get listening => 'Vă Ascult';

  @override
  String get sayYourAnswer => 'Spuneți răspunsul:';

  @override
  String get acceptOrDecline => '\"ACCEPT\" sau \"REFUZ\"';

  @override
  String get greeting => 'Salutare! Unde doriți să mergeți?';

  @override
  String get account => 'Cont';

  @override
  String get personalInformation => 'Informații Personale';

  @override
  String get changePassword => 'Schimbă Parola';

  @override
  String get security => 'Securitate';

  @override
  String get notifications => 'Notificări';

  @override
  String get reportGenerated => 'Raport Generat';

  @override
  String get dailyReportGeneratedSuccess =>
      'Raportul zilnic a fost generat cu succes. Doriți să vă întoarceți la harta principală?';

  @override
  String get stayHere => 'Rămân aici';

  @override
  String get goToMap => 'Mergi la Hartă';

  @override
  String get driverOptions => 'Opțiuni Șofer';

  @override
  String get generatingReport => 'Generez raport...';

  @override
  String get showAll => 'Arată Toate';

  @override
  String get noRidesMatchFilter =>
      'Nu există nicio cursă care să corespundă filtrului.';

  @override
  String get to => 'Către:';

  @override
  String get destination => 'Destinație';

  @override
  String get driverModeDeactivated => 'Modul Șofer Dezactivat';

  @override
  String get goToMapAndActivate =>
      'Mergi la Hartă și activează switch-ul pentru a primi curse.';

  @override
  String get youAreAvailable => 'Ești Disponibil pentru Curse';

  @override
  String get newRidesWillAppear =>
      'Cursele noi vor apărea pe hartă ca notificări interactive.';

  @override
  String get waitingForPassengerConfirmation =>
      'Așteaptă confirmarea pasagerului';

  @override
  String get confirmedGoToPassenger => 'Confirmat. Mergi la pasager';

  @override
  String get earningsTodayShort => 'Fapte Bune';

  @override
  String get completedRidesToday => 'Vecini ajutați azi';

  @override
  String get ridesTodayShort => 'Ajutor';

  @override
  String get averageRatingShort => 'Rating';

  @override
  String errorGeneratingReport(String error) {
    return 'Eroare la generarea raportului: $error';
  }

  @override
  String get noRidesTodayForReport =>
      'Nu există curse finalizate astăzi pentru raport.';

  @override
  String get safetyCenter => 'Centrul de Siguranță';

  @override
  String get addContact => 'Adaugă contact';

  @override
  String get safety_emergencyAssistanceButton =>
      'Butonul de Asistență de Urgență';

  @override
  String get safety_emergencyAssistanceButtonDesc =>
      'În timpul oricărei curse, aveți la dispoziție butonul 112 în colțul ecranului pentru a contacta rapid serviciile de urgență.';

  @override
  String get tripSharing => 'Partajarea Traseului';

  @override
  String get tripSharingDesc =>
      'Puteți partaja detaliile cursei și traseul în timp real cu prietenii sau familia pentru un plus de siguranță.';

  @override
  String get verifiedDrivers => 'Șoferi Verificați';

  @override
  String get verifiedDriversDesc =>
      'Toți șoferii parteneri trec printr-un proces riguros de verificare a documentelor și a istoricului pentru a asigura siguranța dumneavoastră.';

  @override
  String get reportIncidentTitle => 'Raportarea unui Incident';

  @override
  String get reportIncidentDesc =>
      'Dacă întâmpinați orice problemă de siguranță, o puteți raporta direct din aplicație, din secțiunea Ajutor, iar echipa noastră va investiga prompt.';

  @override
  String get noTrustedContactsYet =>
      'Nu ați adăugat încă persoane de încredere.';

  @override
  String get addFamilyFriends =>
      'Adăugați rapid familia sau prietenii care vor primi notificări atunci când partajați o cursă.';

  @override
  String get sendTestMessage => 'Trimite mesaj de test';

  @override
  String contactRemoved(String name) {
    return 'Contactul $name a fost eliminat.';
  }

  @override
  String get couldNotOpenMessages =>
      'Nu am putut deschide aplicația de mesaje pentru acest contact.';

  @override
  String get testMessageBody =>
      'Te-am setat ca persoană de încredere în Nabour. Voi partaja călătoriile active când am nevoie de ajutor.';

  @override
  String get voiceSystemActive => 'Sistemul vocal este activ';

  @override
  String get voiceSystemNotActive => 'Sistemul vocal nu este activ';

  @override
  String get canUseVoiceCommands =>
      'Puteți folosi comenzi vocale pentru a rezerva curse';

  @override
  String get checkMicrophonePermissions =>
      'Verificați permisiunile pentru microfon';

  @override
  String get activate => 'Activează';

  @override
  String get basicMode => 'Basic Mode';

  @override
  String get continuous => 'Continuous';

  @override
  String get on => 'ON';

  @override
  String get off => 'OFF';

  @override
  String get generalSettings => 'Setări Generale';

  @override
  String get continuousListeningSubtitle =>
      'Ascultă continuu pentru comenzi vocale';

  @override
  String get voicePreferences => 'Preferințe Vocale';

  @override
  String get speechRate => 'Viteza de vorbire';

  @override
  String percentOfNormalSpeed(int percent) {
    return '$percent% din viteza normală';
  }

  @override
  String get volume => 'Volumul';

  @override
  String percentOfMaxVolume(int percent) {
    return '$percent% din volumul maxim';
  }

  @override
  String get pitch => 'Tonul';

  @override
  String get lowerPitch => 'Ton mai jos';

  @override
  String get normalPitch => 'Ton normal';

  @override
  String get higherPitch => 'Ton mai înalt';

  @override
  String get german => 'Deutsch';

  @override
  String get french => 'Français';

  @override
  String get spanish => 'Español';

  @override
  String get italian => 'Italiano';

  @override
  String get advancedVoiceFeatures => 'Funcții Vocale Avansate';

  @override
  String get voiceCommandTraining => 'Antrenare comenzi vocale';

  @override
  String get voiceCommandTrainingSubtitle =>
      'Îmbunătățește recunoașterea comenzilor';

  @override
  String get customVoiceProfile => 'Profil vocal personalizat';

  @override
  String get customVoiceProfileSubtitle => 'Adaptează sistemul la vocea dvs';

  @override
  String get multiLanguageSupportSubtitle =>
      'Comutați între limbi în timpul conversației';

  @override
  String get advancedSettings => 'Setări Avansate';

  @override
  String get testMicrophone => 'Testează microfonul';

  @override
  String get testMicrophoneSubtitle =>
      'Verifică dacă microfonul funcționează corect';

  @override
  String get testSound => 'Testează sunetul';

  @override
  String get testSoundSubtitle => 'Verifică dacă sunetul funcționează corect';

  @override
  String get testRecognition => 'Testează recunoașterea';

  @override
  String get testRecognitionSubtitle => 'Verifică recunoașterea vocală';

  @override
  String get voiceCommandsHelp => 'Ajutor comenzi vocale';

  @override
  String get voiceCommandsHelpSubtitle =>
      'Lista completă de comenzi disponibile';

  @override
  String get privacySettings => 'Confidențialitate';

  @override
  String get privacySettingsSubtitle =>
      'Gestionați datele vocale și confidențialitatea';

  @override
  String get analyticsAndImprovements => 'Analiză și îmbunătățiri';

  @override
  String get analyticsAndImprovementsSubtitle =>
      'Gestionați analiza vocală pentru îmbunătățiri';

  @override
  String get saveSettings => 'Salvează Setările';

  @override
  String get voiceSystemActivatedSuccessfully =>
      'Sistemul vocal a fost activat cu succes!';

  @override
  String errorActivatingVoiceSystem(String error) {
    return 'Eroare la activarea sistemului vocal: $error';
  }

  @override
  String get activateVoiceSystemFirst => 'Activează mai întâi sistemul vocal.';

  @override
  String errorTestingMicrophone(String error) {
    return 'Eroare la testarea microfonului: $error';
  }

  @override
  String errorTestingSound(String error) {
    return 'Eroare la testarea sunetului: $error';
  }

  @override
  String errorTestingRecognition(String error) {
    return 'Eroare la testarea recunoașterii: $error';
  }

  @override
  String get voiceCommandTrainingTitle => 'Antrenare Comenzi Vocale';

  @override
  String get voiceCommandTrainingContent =>
      'Antrenarea va îmbunătăți recunoașterea comenzilor vocale. Vă va fi cerut să repetați comenzi multiple ori pentru a crea un profil vocal personalizat.';

  @override
  String get later => 'Mai târziu';

  @override
  String get startTraining => 'Începe Antrenarea';

  @override
  String get trainingStepsTitle => 'Pași Antrenare';

  @override
  String get repeatCommand1 => '1. Repetați comanda \"Vreau o cursă\" de 3 ori';

  @override
  String get repeatCommand2 =>
      '2. Repetați comanda \"Cursă economică\" de 3 ori';

  @override
  String get repeatCommand3 =>
      '3. Repetați comanda \"Anulează cursă\" de 3 ori';

  @override
  String get repeatCommand4 => '4. Repetați comanda \"Ajutor\" de 3 ori';

  @override
  String get trainingWillTakeApprox =>
      'Antrenarea va dura aproximativ 5 minute.';

  @override
  String get customVoiceProfileTitle => 'Profil Vocal Personalizat';

  @override
  String get customVoiceProfileContent =>
      'Creați un profil vocal personalizat pentru a îmbunătăți recunoașterea. Sistemul va învăța să vă recunoască vocea și să se adapteze la accentul dvs.';

  @override
  String get createProfile => 'Creează Profil';

  @override
  String get multiLanguageSettingsTitle => 'Suport Multi-limbă';

  @override
  String get primaryLanguage => 'Limba principală: Română';

  @override
  String get secondaryLanguages => 'Limbi secundare:';

  @override
  String get switchBetweenLanguages =>
      'Puteți comuta între limbi spunând \"Switch to English\" sau \"Schimbă în română\"';

  @override
  String get availableVoiceCommandsTitle => 'Comenzi Vocale Disponibile';

  @override
  String get privacySettingsTitle => 'Confidențialitate Vocală';

  @override
  String get privacySettingsLabel => 'Setări confidențialitate:';

  @override
  String get saveVoiceHistory => 'Salvează istoricul vocal';

  @override
  String get saveVoiceHistorySubtitle =>
      'Stochează comenzile vocale pentru îmbunătățirea serviciului';

  @override
  String get anonymousAnalysis => 'Analiză anonimă';

  @override
  String get anonymousAnalysisSubtitle =>
      'Permite analiza anonimă pentru îmbunătățirea recunoașterii';

  @override
  String get cloudSync => 'Sincronizare cloud';

  @override
  String get cloudSyncSubtitle =>
      'Sincronizează preferințele vocale între dispozitive';

  @override
  String get voiceDataProcessedLocally =>
      'Datele vocale sunt procesate local pe dispozitivul dvs pentru confidențialitate maximă.';

  @override
  String get analyticsSettingsTitle => 'Analiză și Îmbunătățiri';

  @override
  String get analyticsSettingsLabel => 'Setări analiză:';

  @override
  String get improveRecognition => 'Îmbunătățire recunoaștere';

  @override
  String get improveRecognitionSubtitle =>
      'Permite analiza pentru îmbunătățirea recunoașterii vocale';

  @override
  String get usageStatistics => 'Statistici utilizare';

  @override
  String get usageStatisticsSubtitle =>
      'Colectează statistici despre utilizarea funcțiilor vocale';

  @override
  String get errorReporting => 'Raportare erori';

  @override
  String get errorReportingSubtitle =>
      'Raportează automat erorile vocale pentru rezolvare';

  @override
  String get allDataAnonymized =>
      'Toate datele sunt anonimizate și nu conțin informații personale.';

  @override
  String get advancedHelpTitle => 'Ajutor Avansat';

  @override
  String get aiSpeaking => '🗣️ AI VORBEȘTE\n\nVă rog ascultați...';

  @override
  String get aiListening => '🎤 AI ASCULTĂ\n\nVORBIȚI ACUM!';

  @override
  String get aiProcessing => '🧠 AI PROCESEAZĂ\n\nVă rog așteptați...';

  @override
  String get waitingForResponse => 'AȘTEPT RĂSPUNS';

  @override
  String get voiceAssistant => 'ASISTENT VOCAL';

  @override
  String get pleaseListenToResponse => 'Vă rog ascultați răspunsul...';

  @override
  String get speakNow => 'VORBIȚI ACUM!';

  @override
  String get processingInformation => 'Procesez informația...';

  @override
  String get pleaseWait => 'Vă rog așteptați...';

  @override
  String get pressButtonToStart => 'Apăsați butonul pentru a începe';

  @override
  String get newRideAudioUnavailable => '🚨 CURSĂ NOUĂ! (Audio indisponibil)';

  @override
  String get emergencyAssistanceUsageContent =>
      'Funcția de urgență vă permite să:';

  @override
  String get call112Quickly => '• Apelați rapid 112';

  @override
  String get sendLocationToEmergencyContact =>
      '• Trimiteți locația dvs. unui contact de urgență';

  @override
  String get reportIncidentToSafetyTeam =>
      '• Raportați un incident către echipa de siguranță';

  @override
  String get useOnlyRealEmergencies =>
      'Utilizați această funcție doar în situații reale de urgență.';

  @override
  String get reportAccidentOrUnpleasantEvent =>
      'Raportează accident sau eveniment neplăcut';

  @override
  String get toReportIncident => 'Pentru a raporta un incident:';

  @override
  String get ensureYourSafety => '1. Asigurați-vă de siguranța dvs';

  @override
  String get useEmergencyFunctionInApp =>
      '2. Folosiți funcția de urgență din aplicație';

  @override
  String get describeInDetail => '3. Descrieți detaliat ce s-a întâmplat';

  @override
  String get addPhotosIfPossible => '4. Adăugați fotografii dacă este posibil';

  @override
  String get cooperateWithInvestigationTeam =>
      '5. Cooperați cu echipa de investigații';

  @override
  String get falseReportsCanLead =>
      'Raporturile false pot duce la suspendarea contului.';

  @override
  String get cleaningOrDamageFee => 'Taxă curățenie sau daune';

  @override
  String get cleaningFeeTitle =>
      '🧹 Taxa pentru curățenie și daune în aplicația Nabour';

  @override
  String get cleaningFeeIntro =>
      'La Nabour, ne dorim ca toate călătoriile să fie plăcute și confortabile pentru toți utilizatorii noștri. Din acest motiv, avem o politică clară privind curățenia vehiculelor și responsabilitatea pentru eventualele daune.';

  @override
  String get whenFeeApplied =>
      '🚨 Când se aplică taxa pentru curățenie sau daune?';

  @override
  String get spillingLiquids =>
      '1. Vărsarea de lichide în vehicul (apă, cafea, sucuri, alcool, etc.)';

  @override
  String get soilingSeatsOrFloor =>
      '2. Murdărirea scaunelor sau podelei cu noroi, mâncare sau alte substanțe';

  @override
  String get vomitingInVehicle => '3. Vărsături în vehicul';

  @override
  String get smokingInVehicle =>
      '4. Fumatul în vehicul (inclusiv țigări electronice)';

  @override
  String get damagingVehicleElements =>
      '5. Deteriorarea unor elemente din vehicul (scaune, centuri, etc.)';

  @override
  String get leavingFoodOrTrash =>
      '6. Lăsarea de resturi de mâncare sau gunoi în vehicul';

  @override
  String get persistentOdors =>
      '7. Mirosuri persistente care necesită dezodorizare profesională';

  @override
  String get howFeeProcessWorks =>
      '⚙️ Cum funcționează procesul de aplicare a taxei?';

  @override
  String get driverDocumentsDamage =>
      '1. Șoferul documentează paguba prin fotografii imediat după cursă';

  @override
  String get driverReportsIncident =>
      '2. Șoferul raportează incidentul prin aplicația Nabour în maxim 24 de ore';

  @override
  String get teamAnalyzesReport =>
      '3. Echipa noastră analizează raportul și fotografiile';

  @override
  String get ifFeeJustified =>
      '4. În cazul în care taxa este justificată, pasagerul va fi notificat';

  @override
  String get feeChargedAutomatically =>
      '5. Taxa va fi prelevată automat din metoda de plată asociată contului';

  @override
  String get passengerCanContest =>
      '6. Pasagerul poate contesta taxa în termen de 48 de ore de la notificare';

  @override
  String get feeAmounts => '💰 Cuantumul taxelor';

  @override
  String get lightCleaning => '🧽 Curățenie ușoară: 50-100 RON';

  @override
  String get wipingAndVacuuming =>
      '• Ștergerea și aspirarea urmelor ușoare de murdărie';

  @override
  String get removingSmallStains => '• Îndepărtarea petelor mici de pe scaune';

  @override
  String get intensiveCleaning => '🧼 Curățenie intensivă: 150-300 RON';

  @override
  String get professionalCleaning =>
      '• Curățare profesională pentru pete mari sau mirosuri';

  @override
  String get deodorizationAndSpecialTreatments =>
      '• Dezodorizare și tratamente speciale';

  @override
  String get repairsAndReplacements => 'Reparații și înlocuiri';

  @override
  String get replacingDamagedSeatCovers =>
      '• Înlocuirea huselor de scaune deteriorate';

  @override
  String get repairingDamagedComponents =>
      '• Repararea componentelor deteriorate';

  @override
  String get costsDependOnSeverity =>
      '• Costurile variază în funcție de gravitate';

  @override
  String get yourRightsAsPassenger => '⚖️ Drepturile dvs. ca pasager';

  @override
  String get rightToReceivePhotos =>
      '✅ Aveți dreptul să primiți fotografiile și detaliile complete ale daunelor';

  @override
  String get canContestFee =>
      '✅ Puteți contesta taxa în termen de 48 de ore prin aplicație';

  @override
  String get rightToObjectiveInvestigation =>
      '✅ Aveți dreptul la o investigație obiectivă a cazului dvs.';

  @override
  String get ifContestationJustified =>
      '✅ În cazul contestațiilor justificate, taxa va fi returnată integral';

  @override
  String get howToAvoidFee =>
      '🛡️ Cum să evitați taxa pentru curățenie sau daune';

  @override
  String get doNotConsumeFood =>
      '• Nu consumați mâncare sau băuturi în vehicul';

  @override
  String get checkShoesNotDirty =>
      '• Verificați că încălțămintea nu este murdară înainte de a urca';

  @override
  String get notifyDriverIfFeelingUnwell =>
      '• Anunțați șoferul dacă vă simțiți rău și aveți nevoie de o pauză';

  @override
  String get doNotSmokeInVehicle => '• Nu fumați în vehicul';

  @override
  String get treatVehicleWithRespect =>
      '• Tratați vehiculul cu același respect ca și cum ar fi al dvs.';

  @override
  String get takeTrashWithYou =>
      '• Duceți gunoiul cu dvs. la sfârșitul călătoriei';

  @override
  String get contestationProcess => '📝 Procesul de contestare';

  @override
  String get accessRideHistory =>
      '1. Accesați secțiunea \"Istoric călătorii\" din aplicație';

  @override
  String get selectRideForContestation =>
      '2. Selectați călătoria pentru care contestați taxa';

  @override
  String get pressContestFee =>
      '3. Apăsați pe \"Contestă taxa\" și completați formularul';

  @override
  String get addRelevantEvidence =>
      '4. Adăugați orice dovezi relevante (fotografii, explicații)';

  @override
  String get teamWillReanalyze =>
      '5. Echipa noastră va reanaliza cazul în maxim 72 de ore';

  @override
  String get receiveDetailedResponse =>
      '6. Veți primi un răspuns detaliat prin email și în aplicație';

  @override
  String get haveQuestionsOrNeedAssistance =>
      '📞 Aveți întrebări sau aveți nevoie de asistență?';

  @override
  String get emailSupport => '📧 Email: suport@nabour.ro';

  @override
  String get phoneSupport => '📱 Telefon: +40 700 NABOUR';

  @override
  String get chatInApp => '💬 Chat în aplicație: Secțiunea \"Ajutor\"';

  @override
  String get scheduleSupport => '🕒 Program: Luni-Duminică, 24/7';

  @override
  String get importantToRemember => '⚠️ Important de reținut';

  @override
  String get feeOnlyAppliedWithClearEvidence =>
      'Taxa pentru curățenie și daune se aplică doar în cazurile în care există dovezi clare ale deteriorării sau murdăririi vehiculului. Echipa Nabour analizează fiecare caz individual și se asigură că toate taxele sunt justificate și corecte.';

  @override
  String get howToActivateDriverMode =>
      'Cum activez modul șofer partener Nabour';

  @override
  String get toBecomeDriverPartner =>
      'Pentru a deveni șofer partener Nabour, urmează acești pași:';

  @override
  String get checkConditions => '1. Verifică condițiile';

  @override
  String get validLicenseRequired =>
      'Trebuie să ai permis de conducere valabil, experiență de minim 2 ani și vârsta de minim 21 de ani.';

  @override
  String get prepareDocuments => '2. Pregătește documentele';

  @override
  String get documentsNeeded =>
      'Ai nevoie de: permis de conducere, carte de identitate, certificat de înmatriculare auto, ITP valabil și asigurarea RCA.';

  @override
  String get completeApplication => '3. Completează aplicația';

  @override
  String get accessCareerSection =>
      'Accesează secțiunea \"Carieră\" din meniul principal și completează formularul online cu datele tale.';

  @override
  String get submitDocuments => '4. Transmite documentele';

  @override
  String get uploadClearPhotos =>
      'Încarcă fotografii clare cu toate documentele necesare prin platforma online.';

  @override
  String get applicationVerification => '5. Verificarea aplicației';

  @override
  String get teamWillVerify =>
      'Echipa noastră va verifica documentele în maxim 48 de ore lucrătoare.';

  @override
  String get receiveActivationCode => '6. Primește codul de activare';

  @override
  String get afterApproval =>
      'După aprobare, vei primi un cod unic prin email/SMS pentru activarea contului de șofer.';

  @override
  String get activateAccount => '7. Activează contul';

  @override
  String get enterCodeInApp =>
      'Introdu codul în aplicație și începe să câștigi bani conducând!';

  @override
  String get usefulTip => '💡 Sfat util:';

  @override
  String get ensureDocumentsValid =>
      'Asigură-te că toate documentele sunt valabile și fotografiile sunt clare pentru o procesare rapidă.';

  @override
  String get ratesAndPayments => 'Tarife și plăți';

  @override
  String get ratesAndPaymentsInfo => 'Informații despre Tarife și Plăți';

  @override
  String get ratesCalculatedAutomatically =>
      '• Tarifele sunt calculate automat în funcție de distanță și timp';

  @override
  String get paymentMadeAutomatically =>
      '• Plata se face automat prin metoda salvată în cont';

  @override
  String get canSeeRateDetails =>
      '• Puteți vedea detaliile tarifului înainte de a confirma cursa';

  @override
  String get inCaseOfPaymentProblems =>
      '• În caz de probleme cu plata, contactați suportul';

  @override
  String get forCurrentRatesDetails =>
      'Pentru detalii despre tarifele actuale, verificați în aplicație.';

  @override
  String get deliveryOrderRequest => 'Solicitare comandă livrare';

  @override
  String get deliveryServices => 'Servicii de Livrare';

  @override
  String get currentlyFocusedOnTransport =>
      'Momentan, ne concentrăm pe serviciile de transport persoane.';

  @override
  String get deliveryServicesAvailableSoon =>
      'Serviciile de livrare vor fi disponibile în viitorul apropiat.';

  @override
  String get weWillNotifyYou =>
      'Vă vom anunța când această funcție va fi activă!';

  @override
  String get appFunctioningProblems => 'Probleme de funcționare a aplicației';

  @override
  String get ifAppNotWorkingCorrectly =>
      'Dacă aplicația nu funcționează corect:';

  @override
  String get updateAppToLatest =>
      '3. Actualizați aplicația la cea mai recentă versiune';

  @override
  String get restartPhone => '4. Restartați telefonul';

  @override
  String get reinstallAppIfPersists =>
      '5. Reinstalați aplicația dacă problema persistă';

  @override
  String get ifProblemContinues =>
      'Dacă problema continuă, trimiteți-ne un raport prin suport.';

  @override
  String get forgotPassword => 'Am uitat parola';

  @override
  String get enterEmailAssociated =>
      'Introduceți adresa de email asociată contului dumneavoastră.';

  @override
  String get enterValidEmail => 'Introduceți o adresă de email validă.';

  @override
  String get sendingResetEmail => 'Se trimite emailul de resetare...';

  @override
  String get resetEmailSent =>
      'Un email de resetare a parolei a fost trimis. Verificați-vă inbox-ul (inclusiv folderul Spam)!';

  @override
  String get errorSendingResetEmail =>
      'A apărut o eroare la trimiterea email-ului de resetare.';

  @override
  String get noAccountWithEmail =>
      'Nu există niciun cont cu această adresă de email.';

  @override
  String get unexpectedError => 'Eroare neașteptată. Încercați din nou';

  @override
  String get resetPassword => 'Resetare Parolă';

  @override
  String get applyNow => 'Aplică acum';

  @override
  String get contentComingSoon =>
      'Conținutul pentru acest subiect va fi disponibil în curând.';

  @override
  String get joinTeam => 'Alătură-te echipei Nabour';

  @override
  String get applyForDriver => 'Mașina mea';

  @override
  String get neighborhoodRequests => 'Cereri din cartier';

  @override
  String get neighborhoodChat => 'Chat de cartier';

  @override
  String get activateDriverCode => 'Activare cod mod Șofer Nabour';

  @override
  String get activateDriverCodeTitle => 'Activare Cod Șofer';

  @override
  String get activateDriverCodeDescription =>
      'Introduceți codul de activare primit pentru a deveni șofer partener Nabour.';

  @override
  String get enterActivationCode => 'Vă rugăm introduceți codul de activare.';

  @override
  String get codeTooShort =>
      'Codul introdus este prea scurt. Verificați din nou.';

  @override
  String get validatingCode => 'Validez codul...';

  @override
  String get codeActivatedSuccess =>
      'Codul a fost activat cu succes! Acum sunteți șofer.';

  @override
  String get codeInvalidOrUsed =>
      'Cod invalid sau deja utilizat. Vă rugăm verificați.';

  @override
  String errorValidatingCode(String error) {
    return 'Eroare la validarea codului: $error';
  }

  @override
  String get lowDataMode => 'Mod date reduse';

  @override
  String get highContrastUI => 'Interfață contrast ridicat';

  @override
  String get assistantStatusOverlay => 'Suprapunere status asistent';

  @override
  String get performanceOverlay => 'Suprapunere performanță';

  @override
  String get aiGreeting => 'Salut, unde doriți să mergeți?';

  @override
  String get aiSearchingDrivers => 'Caut șoferi disponibili...';

  @override
  String get aiSearchingDriversInArea => 'Caut șoferi disponibili în zonă...';

  @override
  String aiDriverFound(int minutes) {
    return 'Am găsit un șofer disponibil la $minutes minute distanță.';
  }

  @override
  String get aiBestDriverSelected =>
      'Am selectat cel mai bun șofer pentru dumneavoastră. Trimit cererea de cursă...';

  @override
  String get aiNoDriversAvailable =>
      'Îmi pare rău, dar nu am găsit șoferi disponibili în zona dumneavoastră. Te rugăm să revii mai târziu.';

  @override
  String get aiEverythingResolved =>
      'Perfect! Am rezolvat totul automat. Cererea dvs. de cursă a fost trimisă!';

  @override
  String get subscriptionsTitle => 'Abonamente Nabour';

  @override
  String get recommended => 'RECOMANDAT';

  @override
  String get ronPerMonth => 'RON / lună';

  @override
  String planSelected(String plan) {
    return 'Ai selectat planul $plan! (simulare)';
  }

  @override
  String get choosePlan => 'Alege Planul';

  @override
  String get subscriptionBasicDescription => 'Pentru călătorii ocazionali.';

  @override
  String get subscriptionPlusDescription => 'Cel mai popular plan.';

  @override
  String get subscriptionPremiumDescription => 'Beneficii exclusive.';

  @override
  String get subscriptionBasicBenefit1 => '5% reducere la 10 curse/lună';

  @override
  String get subscriptionBasicBenefit2 => 'Anulare gratuită în 2 minute';

  @override
  String get subscriptionPlusBenefit1 => '10% reducere la toate cursele';

  @override
  String get subscriptionPlusBenefit2 => 'Anulare gratuită în 5 minute';

  @override
  String get subscriptionPlusBenefit3 => 'Suport prioritar 24/7';

  @override
  String get subscriptionPremiumBenefit1 => '15% reducere la toate cursele';

  @override
  String get subscriptionPremiumBenefit2 => 'Anulare gratuită oricând';

  @override
  String get subscriptionPremiumBenefit3 => 'Suport prioritar 24/7';

  @override
  String get subscriptionPremiumBenefit4 => 'Acces la mașini premium';

  @override
  String get deleteConfirmation => 'Confirmare Ștergere';

  @override
  String deleteRideConfirmation(String destination) {
    return 'Sunteți sigur că doriți să ștergeți definitiv cursa către \"$destination\" din istoricul dumneavoastră? Această acțiune este ireversibilă.';
  }

  @override
  String get rideDeletedSuccess => 'Cursa a fost ștearsă cu succes!';

  @override
  String errorLoadingRole(String error) {
    return 'Eroare la încărcarea rolului: $error';
  }

  @override
  String get errorGeneric => 'Eroare';

  @override
  String get errorLoadingData => 'Eroare la încărcarea datelor';

  @override
  String errorDetails(String error) {
    return 'Detalii: $error';
  }

  @override
  String get retry => 'Reîncearcă';

  @override
  String get noRidesInPeriod => 'Nu aveți nicio cursă în perioada selectată.';

  @override
  String get filterAll => 'Tot';

  @override
  String get filterLastMonth => 'Ultima Lună';

  @override
  String get filterLast3Months => 'Ultimele 3 Luni';

  @override
  String get filterThisYear => 'Anul Acesta';

  @override
  String rideDate(String date) {
    return 'Data: $date';
  }

  @override
  String get deleteRide => 'Șterge cursa';

  @override
  String get asDriver => 'Ca Șofer';

  @override
  String get asPassenger => 'Ca Pasager';

  @override
  String get errorLoadingUserRole =>
      'Eroare la încărcarea rolului utilizatorului.';

  @override
  String get receiptsTitle => 'Chitantele Tale';

  @override
  String get receiptsTitlePassenger => 'Chitante (Pasager)';

  @override
  String get errorLoadingReceipts => 'Eroare la încărcarea chitanțelor';

  @override
  String get noReceiptsInPeriod =>
      'Nu aveți nicio chitanță în această categorie pentru perioada selectată.';

  @override
  String deleteSelectedReceipts(int count) {
    return 'Șterge $count chitante selectate?';
  }

  @override
  String get deleteSelectedReceiptsWarning =>
      'Această acțiune va șterge permanent chitanțele selectate. Acțiunea nu poate fi anulată.';

  @override
  String receiptsDeletedSuccess(int count) {
    return 'Au fost șterse cu succes $count chitante.';
  }

  @override
  String receiptsDeletedPartial(int deleted, int error) {
    return 'Au fost șterse $deleted chitante. $error nu au putut fi șterse.';
  }

  @override
  String deleteAllReceipts(int count) {
    return 'Șterge toate chitanțele ($count)?';
  }

  @override
  String get deleteAllReceiptsWarning =>
      'Această acțiune va șterge permanent TOATE chitanțele din perioada selectată. Acțiunea nu poate fi anulată.';

  @override
  String allReceiptsDeleted(int count) {
    return 'Au fost șterse $count chitante.';
  }

  @override
  String get filterAllReceipts => 'Toate';

  @override
  String get generating => 'Generez...';

  @override
  String get monthlyReportPDF => 'Raport Lunar PDF';

  @override
  String selectedCount(int count) {
    return '$count selectate';
  }

  @override
  String get selectAll => 'Selectează tot';

  @override
  String get deselectAll => 'Deselectează tot';

  @override
  String get deleteSelected => 'Șterge selectate';

  @override
  String get deleteAll => 'Șterge toate';

  @override
  String get noRidesForReport =>
      'Nu există curse în ultima lună pentru a genera raportul.';

  @override
  String get returnToMapQuestion =>
      'Doriți să vă întoarceți la harta principală?';

  @override
  String rideTo(String destination) {
    return 'Cursă către: $destination';
  }

  @override
  String rideFrom(String date) {
    return 'Ride from $date';
  }

  @override
  String get from => 'De la:';

  @override
  String get earningsSummary => 'Sumar Câștiguri';

  @override
  String get totalRide => 'Total Cursă:';

  @override
  String get appCommission => 'Comision Aplicație:';

  @override
  String get yourEarnings => 'Câștigul Tău:';

  @override
  String get activeRideDetected => 'Cursă activă detectată';

  @override
  String get cancelPreviousRide => 'Anulează cursa precedentă';

  @override
  String get rideAcceptedWaiting =>
      'Cursă acceptată! Așteptăm confirmarea pasagerului...';

  @override
  String get driverProfileLoading =>
      'Profilul șofer se încarcă, încercați din nou...';

  @override
  String get searching => 'Se caută…';

  @override
  String get searchInThisArea => 'Caută în această zonă';

  @override
  String get declining => 'Refuz...';

  @override
  String get decline => 'Refuză';

  @override
  String get accepting => 'Accept...';

  @override
  String get accept => 'Acceptă';

  @override
  String get addAsStop => 'Adaugă ca oprire';

  @override
  String get pickupPointDeleted => 'Punctul de plecare a fost șters';

  @override
  String get destinationDeleted => 'Destinația a fost ștearsă';

  @override
  String get selectPickupAndDestination =>
      'Selectează punctul de plecare și destinația';

  @override
  String get rideSummary => 'Sumar Cursă';

  @override
  String get couldNotLoadRideDetails =>
      'Nu s-au putut încărca detaliile cursei';

  @override
  String get back => 'Înapoi';

  @override
  String get noTip => 'Fără bacșiș';

  @override
  String get routeNotLoaded => '🗺️ Nu s-a putut încărca traseul automat';

  @override
  String get rideCancelledSuccess => 'Cursa a fost anulată cu succes';

  @override
  String get forceCancelRide => 'Anulează Forțat Cursa';

  @override
  String get passengerAddedStop =>
      'Pasagerul a adăugat o nouă oprire. Ruta a fost recalculată.';

  @override
  String get stopAdded =>
      'Oprire adăugată! Traseul și costul au fost actualizate.';

  @override
  String errorAddingStop(String error) {
    return 'Eroare la adăugarea opririi: $error';
  }

  @override
  String get navigationWithGoogleMaps => 'Navigație cu Google Maps';

  @override
  String get navigationWithWaze => 'Navigație cu Waze';

  @override
  String get safetyTeamNotified =>
      'Am notificat echipa de siguranță. Suntem alături de tine.';

  @override
  String get sendViaApps => 'Trimite prin aplicații';

  @override
  String get noTrustedContacts => 'Nu aveți contacte de încredere';

  @override
  String get manageContacts => 'Gestionează contacte';

  @override
  String get iAmSafe => 'Sunt în siguranță';

  @override
  String get falseAlarm => 'Alarmă falsă';

  @override
  String get shareRoute => 'Partajează traseul';

  @override
  String get rideCancelledSuccessShort => 'Cursa a fost anulată cu succes';

  @override
  String get recenterMap => 'Recentrează harta';

  @override
  String get mapMovedTapToRecenter => 'Mișcat harta. Atinge pentru recentrare';

  @override
  String get entrySelected => 'Intrare selectată.';

  @override
  String get addStop => 'Adaugă Oprire';

  @override
  String navigationBanner(String type, String modifier, String distance) {
    return 'Banner navigație. $type $modifier. Distanță $distance metri.';
  }

  @override
  String entrySelectedWithLabel(String label) {
    return 'Intrare selectată: $label';
  }

  @override
  String get editMessage => 'Editează mesajul';

  @override
  String get passengerNotifiedArrived =>
      '✅ Pasagerul a fost notificat că ai ajuns!';

  @override
  String get cannotOpenPhoneApp => 'Nu se poate deschide aplicația de telefon';

  @override
  String errorLoadingRoute(String error) {
    return 'Eroare la încărcarea rutei: $error';
  }

  @override
  String rideCancelledReason(String reason) {
    return 'Cursa anulată: $reason';
  }

  @override
  String get selectCancellationReason => 'Selectează motivul anulării:';

  @override
  String get backButton => 'Înapoi';

  @override
  String get passengerNotResponding => 'Pasager nu răspunde';

  @override
  String get technicalProblem => 'Problemă tehnică';

  @override
  String get pickupRide => 'Preluare Cursă';

  @override
  String get loadingPassengerInfo => 'Se încarcă informațiile pasagerului...';

  @override
  String get pleaseValidateAddress =>
      'Te rugăm să validezi adresa sau să o selectezi de pe hartă.';

  @override
  String get editAddress => 'Editează Adresa';

  @override
  String get addNewAddress => 'Adaugă Adresă Nouă';

  @override
  String errorVoiceRecognition(String error) {
    return 'Eroare la recunoașterea vocală: $error';
  }

  @override
  String get updateAddress => 'Actualizează Adresa';

  @override
  String get saveAddress => 'Salvează Adresa';

  @override
  String get resetPasswordButton => 'Resetează Parola';

  @override
  String get pleaseFillAllFields =>
      'Vă rugăm completați corect toate câmpurile.';

  @override
  String get welcomeBack => '👋 Bun venit înapoi!';

  @override
  String get welcomeToNabour => 'Bun venit în Nabour!';

  @override
  String get pleaseEnterValidEmail =>
      'Vă rugăm introduceți o adresă de email validă în câmpul de Email pentru resetare.';

  @override
  String get errorResettingPassword =>
      'A apărut o eroare neașteptată la resetarea parolei.';

  @override
  String get enterValidPhoneNumber => 'Introduceți un număr de telefon valid.';

  @override
  String get autoAuthCompleted => 'Autentificare automată finalizată';

  @override
  String errorAutoAuth(String error) {
    return 'Eroare autentificare automată: $error';
  }

  @override
  String get enterSmsCode => 'Introduceți codul SMS primit.';

  @override
  String get verifyAndAuthenticate => 'Verifică și autentifică';

  @override
  String get max5Stops => 'Poți adăuga maximum 5 opriri';

  @override
  String addressNotFound(String address) {
    return 'Nu s-a putut găsi adresa: $address';
  }

  @override
  String noCoordinatesForDestination(String error) {
    return 'Nu s-au găsit coordonate pentru destinație: $error';
  }

  @override
  String get fillBothAddresses => 'Completează ambele adrese pentru a continua';

  @override
  String get intermediateStopAdded => 'Oprire intermediară adăugată';

  @override
  String get home => 'Acasă';

  @override
  String get work => 'Serviciu';

  @override
  String get edit => 'Editează';

  @override
  String get recentDestinations => 'Destinații Recente';

  @override
  String get noFavoriteAddressAdded => 'Nicio adresă favorită adăugată.';

  @override
  String get addressUpdated => 'Adresa a fost actualizată!';

  @override
  String get addressSaved => 'Adresa a fost salvată!';

  @override
  String get pleaseSelectRating =>
      'Te rugăm selectează un rating înainte de a trimite.';

  @override
  String get ratingSentSuccess => 'Evaluare trimisă cu succes!';

  @override
  String errorSendingRating(String error) {
    return 'Eroare la trimiterea evaluării: $error';
  }

  @override
  String get rideDetailsCompleted => 'Detalii Cursă Finalizată';

  @override
  String get saveRating => 'Salvează Evaluarea';

  @override
  String errorConfirmingDriver(String error) {
    return 'Eroare la confirmarea șoferului: $error';
  }

  @override
  String errorDecliningDriver(String error) {
    return 'Eroare la refuzarea șoferului: $error';
  }

  @override
  String get backToMap => 'Înapoi la Hartă';

  @override
  String get currentLocation => 'Locația actuală';

  @override
  String get finalDestination => 'Destinație finală';

  @override
  String get accordingToSelection => 'Conform selecției';

  @override
  String get waitingResponse => '⏳ AȘTEPT RĂSPUNS...';

  @override
  String get waitingConfirmation => '❓ AȘTEPT CONFIRMARE\n\nSpuneți DA sau NU';

  @override
  String get arrivedNotifyPassenger => 'Am ajuns - Anunță pasagerul';

  @override
  String get passengerBoarding => 'Pasagerul se îmbarcă';

  @override
  String get route => 'Rută';

  @override
  String get preferencesSaved => 'Preferințele au fost salvate';

  @override
  String get pleaseSelectRatingBeforeSubmit =>
      'Vă rugăm selectați un rating înainte de a trimite.';

  @override
  String get errorSubmittingRating =>
      'Eroare la trimiterea evaluării. Încercați din nou.';

  @override
  String get rideSummary_thankYouForRide => 'Vă mulțumim pentru călătorie!';

  @override
  String get rideSummary_howWasExperience => 'Cum a fost experiența?';

  @override
  String get rideSummary_leaveCommentOptional =>
      'Lasă un comentariu (opțional)';

  @override
  String get thanksForRating => 'Mulțumim pentru evaluare!';

  @override
  String get ratePassenger => 'Evaluează Pasagerul';

  @override
  String get shortCharacterization =>
      'Scurtă caracterizare (ex: curat, a murdărit mașina)';

  @override
  String get addPrivateNoteAboutPassenger =>
      'Adaugă o notă privată despre pasager...';

  @override
  String get routeUpdated => 'Traseu Actualizat';

  @override
  String get passengerAddedNewStop =>
      'Pasagerul a adăugat o nouă oprire. Ruta a fost recalculată.';

  @override
  String get ok => 'OK';

  @override
  String get rideManagement => 'Gestionare Cursă';

  @override
  String get modifyDestination => 'Modifică Destinația';

  @override
  String get cannotModifyCompletedRide =>
      'Nu poți modifica destinația pentru o cursă finalizată sau anulată.';

  @override
  String get destinationUpdatedSuccessfully =>
      'Destinația a fost actualizată cu succes!';

  @override
  String errorUpdatingDestination(String error) {
    return 'Eroare la actualizarea destinației: $error';
  }

  @override
  String get changeFinalLocation => 'Schimbă locația finală';

  @override
  String get intermediateStop => 'Oprire intermediară';

  @override
  String get mayIncludeCancellationFee => 'Poate include taxă de anulare';

  @override
  String get viewReceipt => 'Vizualizează Chitanța';

  @override
  String get completeRideDetails => 'Detalii complete ale cursei';

  @override
  String get rateRide => 'Evaluează Cursa';

  @override
  String get provideDriverFeedback => 'Oferă feedback șoferului';

  @override
  String get communication => 'Comunicare';

  @override
  String get callDriver => 'Sună Șoferul';

  @override
  String chatWith(String name) {
    return 'Chat cu $name';
  }

  @override
  String get chatAvailableSoon => 'Chat-ul va fi disponibil în curând';

  @override
  String get costSummary => 'Sumar Cost';

  @override
  String get baseFare => 'Tarif de bază:';

  @override
  String time(String min) {
    return 'Timp ($min min):';
  }

  @override
  String get totalPaid => 'Total Plătit:';

  @override
  String get ratingGiven => 'Rating acordat:';

  @override
  String get noRatingGiven => 'Niciun rating acordat';

  @override
  String get optionalComments => 'Comentarii opționale...';

  @override
  String get howWasYourExperience => 'Cum a fost experiența ta?';

  @override
  String get routeNotLoadedAuto => '🗺️ Nu s-a putut încărca traseul automat';

  @override
  String get rideCancelledSuccessfully => 'Cursa a fost anulată cu succes.';

  @override
  String get stopAddedRouteUpdated =>
      'Oprire adăugată! Traseul și costul au fost actualizate.';

  @override
  String get writeNewText => 'Scrie noul text...';

  @override
  String get messageEditedSuccess => 'Mesajul a fost editat cu succes!';

  @override
  String errorEditingMessage(String error) {
    return 'Eroare la editarea mesajului: $error';
  }

  @override
  String errorCancelling(String error) {
    return 'Eroare la anulare: $error';
  }

  @override
  String get inviteFriendsDescription =>
      'Invită vecini să se alăture comunității Nabour';

  @override
  String get splitPayment => 'Împărțire Misiune';

  @override
  String get splitPaymentDescription =>
      'Invită vecinii să se alăture drumului tău';

  @override
  String get createSplitPayment => 'Creează Împărțire';

  @override
  String get splitPaymentCreated => 'Împărțirea a fost creată';

  @override
  String get shareLinkWithParticipants =>
      'Partajează link-ul cu participanții:';

  @override
  String get share => 'Partajează';

  @override
  String get splitWithHowMany => 'Cu câți să împărți?';

  @override
  String get selectNumberOfPeople => 'Selectează numărul de persoane';

  @override
  String get confirm => 'Confirmă';

  @override
  String get acceptSplitPayment => 'Acceptă Împărțirea';

  @override
  String get markAsPaid => 'Marchează ca Plătit';

  @override
  String get totalAmount => 'Total';

  @override
  String get perPerson => 'Per Persoană';

  @override
  String get participants => 'Participanți';

  @override
  String get participant => 'Participant';

  @override
  String get paid => 'Plătit';

  @override
  String get pending => 'În așteptare';

  @override
  String get accepted => 'Acceptat';

  @override
  String get completed => 'Finalizat';

  @override
  String get rejected => 'Respins';

  @override
  String get cancelled => 'Anulat';

  @override
  String errorCreatingSplitPayment(String error) {
    return 'Eroare la crearea împărțirii: $error';
  }

  @override
  String errorAcceptingSplitPayment(String error) {
    return 'Eroare la acceptarea împărțirii: $error';
  }

  @override
  String errorCompletingPayment(String error) {
    return 'Eroare la finalizarea plății: $error';
  }

  @override
  String get paymentCompleted => 'Misiune îndeplinită';

  @override
  String get promotionCode => 'Cod Promoțional';

  @override
  String get enterPromotionCode => 'Introdu codul promoțional';

  @override
  String get apply => 'Aplică';

  @override
  String get promotionAppliedSuccessfully =>
      'Cod promoțional aplicat cu succes';

  @override
  String get subscriptionsHelpTitle => 'Abonamente și Promoții';

  @override
  String get subscriptionsHelpOverview =>
      'Abonamentele Nabour vă oferă beneficii exclusive și reduceri la curse.';

  @override
  String get subscriptionsHelpPlans => 'Planuri Disponibile:';

  @override
  String get subscriptionsHelpBasic =>
      '• Nabour Basic - 5% reducere la 10 curse/lună';

  @override
  String get subscriptionsHelpPlus =>
      '• Nabour Plus - 10% reducere la toate cursele (Recomandat)';

  @override
  String get subscriptionsHelpPremium =>
      '• Nabour Premium - 15% reducere + beneficii exclusive';

  @override
  String get subscriptionsHelpHowToSubscribe => 'Cum să vă abonați:';

  @override
  String get subscriptionsHelpGoToMenu => '1. Accesați meniul hamburger';

  @override
  String get subscriptionsHelpTapSubscriptions =>
      '2. Apăsați pe \'Abonamente și Promoții\'';

  @override
  String get subscriptionsHelpSelectPlan => '3. Selectați planul dorit';

  @override
  String get subscriptionsHelpCompletePayment => '4. Completați plata';

  @override
  String get subscriptionsHelpPromotions => 'Promoții Active:';

  @override
  String get subscriptionsHelpPromotionsInfo =>
      'Verificați secțiunea \'Promoții\' pentru oferte speciale și coduri promoționale disponibile.';

  @override
  String get subscriptionsHelpReferral => 'Program de Recomandare:';

  @override
  String get subscriptionsHelpReferralInfo =>
      'Partajați codul dvs. de recomandare și primiți beneficii pentru fiecare prieten care se înscrie.';

  @override
  String get splitPaymentHelpTitle => 'Split Payment - Împărțirea Costului';

  @override
  String get splitPaymentHelpOverview =>
      'Split Payment vă permite să împărțiți costul cursei cu alți pasageri.';

  @override
  String get splitPaymentHelpHowToCreate => 'Cum să creați Split Payment:';

  @override
  String get splitPaymentHelpAfterRide =>
      '1. După finalizarea cursei, apăsați pe \'Split Payment\'';

  @override
  String get splitPaymentHelpSelectPeople =>
      '2. Selectați numărul de persoane cu care împărțiți';

  @override
  String get splitPaymentHelpShareLink =>
      '3. Partajați linkul generat cu participanții';

  @override
  String get splitPaymentHelpParticipantsAccept =>
      '4. Participanții acceptă și plătesc partea lor';

  @override
  String get splitPaymentHelpHowToAccept => 'Cum să acceptați Split Payment:';

  @override
  String get splitPaymentHelpReceiveLink => '1. Primirea linkului de partajare';

  @override
  String get splitPaymentHelpTapAccept => '2. Apăsați pe \'Accept Split\'';

  @override
  String get splitPaymentHelpSelectPayment => '3. Selectați metoda de plată';

  @override
  String get splitPaymentHelpCompletePayment => '4. Completați plata';

  @override
  String get splitPaymentHelpNote =>
      'Notă: Split Payment este disponibil doar pentru curse finalizate.';

  @override
  String get rideSharingHelpTitle => 'Ride Sharing - Curse Partajate';

  @override
  String get rideSharingHelpOverview =>
      'Ride Sharing vă permite să partajați cursa cu alți pasageri care merg în aceeași direcție.';

  @override
  String get rideSharingHelpHowToEnable => 'Cum să activați Ride Sharing:';

  @override
  String get rideSharingHelpDuringRequest =>
      '1. În timpul solicitării cursei, activați opțiunea \'Ride Sharing\'';

  @override
  String get rideSharingHelpSystemMatches =>
      '2. Sistemul va căuta automat alți pasageri compatibili';

  @override
  String get rideSharingHelpIfMatchFound =>
      '3. Dacă se găsește un match, veți fi notificat';

  @override
  String get rideSharingHelpBenefits => 'Beneficii:';

  @override
  String get rideSharingHelpCostReduction =>
      '• Reducere semnificativă a costului cursei';

  @override
  String get rideSharingHelpEcoFriendly => '• Opțiune prietenoasă cu mediul';

  @override
  String get rideSharingHelpSocial => '• Oportunitate de a cunoaște oameni noi';

  @override
  String get rideSharingHelpNote =>
      'Notă: Ride Sharing este disponibil doar pentru anumite rute și în anumite zone.';

  @override
  String get modifyDestinationHelpTitle => 'Modificare Destinație';

  @override
  String get modifyDestinationHelpOverview =>
      'Puteți modifica destinația cursei în timpul cursei active.';

  @override
  String get modifyDestinationHelpHowToModify =>
      'Cum să modificați destinația:';

  @override
  String get modifyDestinationHelpDuringRide =>
      '1. În timpul cursei active, apăsați pe \'Gestionare Cursă\'';

  @override
  String get modifyDestinationHelpTapModify =>
      '2. Apăsați pe \'Modifică Destinația\'';

  @override
  String get modifyDestinationHelpSelectNew => '3. Selectați noua destinație';

  @override
  String get modifyDestinationHelpConfirm => '4. Confirmați modificarea';

  @override
  String get modifyDestinationHelpRouteRecalculated =>
      '5. Ruta și prețul vor fi recalculate automat';

  @override
  String get modifyDestinationHelpLimitations => 'Limitări:';

  @override
  String get modifyDestinationHelpCannotModifyCompleted =>
      '• Nu puteți modifica destinația pentru curse finalizate sau anulate';

  @override
  String get modifyDestinationHelpPriceMayChange =>
      '• Prețul poate varia în funcție de noua destinație';

  @override
  String get modifyDestinationHelpDriverNotified =>
      '• Șoferul va fi notificat automat despre modificare';

  @override
  String get lowDataModeHelpTitle => 'Mod Date Reduse';

  @override
  String get lowDataModeHelpOverview =>
      'Modul Date Reduse reduce consumul de date mobile optimizând funcționalitățile aplicației.';

  @override
  String get lowDataModeHelpHowToEnable => 'Cum să activați Mod Date Reduse:';

  @override
  String get lowDataModeHelpGoToMenu => '1. Accesați meniul hamburger';

  @override
  String get lowDataModeHelpTapToggle =>
      '2. Găsiți opțiunea \'Mod date reduse\'';

  @override
  String get lowDataModeHelpActivate => '3. Activați toggle-ul';

  @override
  String get lowDataModeHelpWhatItDoes => 'Ce face Mod Date Reduse:';

  @override
  String get lowDataModeHelpReducesImages =>
      '• Reduce calitatea imaginilor și cache-ul';

  @override
  String get lowDataModeHelpLimitsAnimations =>
      '• Limitează animațiile și efectele vizuale';

  @override
  String get lowDataModeHelpOptimizesMaps =>
      '• Optimizează încărcarea hărților';

  @override
  String get lowDataModeHelpReducesSync =>
      '• Reduce sincronizarea în timp real';

  @override
  String get lowDataModeHelpBenefits => 'Beneficii:';

  @override
  String get lowDataModeHelpSavesData => '• Economisește date mobile';

  @override
  String get lowDataModeHelpFasterLoading =>
      '• Încărcare mai rapidă pe conexiuni slabe';

  @override
  String get lowDataModeHelpBatteryLife => '• Îmbunătățește durata bateriei';

  @override
  String get lowDataModeHelpNote =>
      'Notă: Mod Date Reduse poate afecta calitatea anumitor funcții, dar aplicația rămâne complet funcțională.';

  @override
  String get highContrastUIHelpTitle => 'Interfață Contrast Ridicat';

  @override
  String get highContrastUIHelpOverview =>
      'Interfața cu Contrast Ridicat îmbunătățește vizibilitatea pentru utilizatorii cu deficiențe de vedere sau în condiții de lumină slabă.';

  @override
  String get highContrastUIHelpHowToEnable =>
      'Cum să activați Interfața cu Contrast Ridicat:';

  @override
  String get highContrastUIHelpGoToMenu => '1. Accesați meniul hamburger';

  @override
  String get highContrastUIHelpTapToggle =>
      '2. Găsiți opțiunea \'Interfață contrast ridicat\'';

  @override
  String get highContrastUIHelpActivate => '3. Activați toggle-ul';

  @override
  String get highContrastUIHelpWhatItDoes =>
      'Ce face Interfața cu Contrast Ridicat:';

  @override
  String get highContrastUIHelpIncreasesContrast =>
      '• Mărește contrastul între text și fundal';

  @override
  String get highContrastUIHelpBolderText =>
      '• Face textul mai bold și mai ușor de citit';

  @override
  String get highContrastUIHelpClearerIcons =>
      '• Face iconițele și butoanele mai vizibile';

  @override
  String get highContrastUIHelpBetterVisibility =>
      '• Îmbunătățește vizibilitatea în condiții de lumină slabă';

  @override
  String get highContrastUIHelpBenefits => 'Beneficii:';

  @override
  String get highContrastUIHelpAccessibility =>
      '• Îmbunătățește accesibilitatea pentru utilizatori cu deficiențe de vedere';

  @override
  String get highContrastUIHelpReadability => '• Text mai ușor de citit';

  @override
  String get highContrastUIHelpOutdoorUse =>
      '• Utilizare mai bună în condiții de lumină puternică';

  @override
  String get highContrastUIHelpNote =>
      'Notă: Interfața cu Contrast Ridicat este disponibilă atât pentru tema clară, cât și pentru tema întunecată.';

  @override
  String get assistantStatusOverlayHelpTitle => 'Suprapunere Status Asistent';

  @override
  String get assistantStatusOverlayHelpOverview =>
      'Suprapunerea Status Asistent afișează un indicator mic în colțul ecranului care arată când asistentul AI procesează comenzi.';

  @override
  String get assistantStatusOverlayHelpHowToEnable =>
      'Cum să activați Suprapunerea Status Asistent:';

  @override
  String get assistantStatusOverlayHelpGoToMenu =>
      '1. Accesați meniul hamburger';

  @override
  String get assistantStatusOverlayHelpTapToggle =>
      '2. Găsiți opțiunea \'Suprapunere status asistent\'';

  @override
  String get assistantStatusOverlayHelpActivate => '3. Activați toggle-ul';

  @override
  String get assistantStatusOverlayHelpWhatItShows =>
      'Ce afișează indicatorul:';

  @override
  String get assistantStatusOverlayHelpWorking =>
      '• \'Lucrez\' - când asistentul AI procesează comenzi sau interacționează cu utilizatorul';

  @override
  String get assistantStatusOverlayHelpWaiting =>
      '• \'Aștept comenzi\' - când asistentul AI este inactiv și așteaptă comenzi';

  @override
  String get assistantStatusOverlayHelpLocation => 'Unde apare indicatorul:';

  @override
  String get assistantStatusOverlayHelpTopRight =>
      '• Indicatorul apare în colțul din dreapta sus al ecranului';

  @override
  String get assistantStatusOverlayHelpNonIntrusive =>
      '• Este non-intruziv și nu interferează cu utilizarea aplicației';

  @override
  String get assistantStatusOverlayHelpBenefits => 'Beneficii:';

  @override
  String get assistantStatusOverlayHelpVisualFeedback =>
      '• Feedback vizual rapid despre starea asistentului AI';

  @override
  String get assistantStatusOverlayHelpDebugging =>
      '• Util pentru debugging și înțelegerea când AI-ul lucrează';

  @override
  String get assistantStatusOverlayHelpTransparency =>
      '• Transparență despre activitatea asistentului';

  @override
  String get assistantStatusOverlayHelpNote =>
      'Notă: Indicatorul se actualizează automat când pornești sau oprești interacțiunea vocală cu AI-ul.';

  @override
  String get securityAndSafety => 'Siguranță și Securitate';

  @override
  String get changePasswordSubtitle => 'Modifică parola contului tău';

  @override
  String get sessions => 'Sesiuni';

  @override
  String get logoutAllDevices => 'Deconectare de pe toate dispozitivele';

  @override
  String get logoutAllDevicesSubtitle =>
      'Ieșire din cont pe toate dispozitivele conectate';

  @override
  String get dangerZone => 'Zonă periculoasă';

  @override
  String get deleteAccount => 'Ștergere cont';

  @override
  String get deleteAccountSubtitle =>
      'Șterge permanent contul și toate datele asociate';

  @override
  String get confirmLogoutAllDevicesTitle =>
      'Deconectare de pe toate dispozitivele';

  @override
  String get confirmLogoutAllDevicesContent =>
      'Vei fi deconectat de pe toate dispozitivele, inclusiv cel curent. Va trebui să te autentifici din nou.';

  @override
  String get disconnect => 'Deconectează';

  @override
  String get permanentDeleteAccount => 'Ștergere cont permanent';

  @override
  String get attention => 'Atenție! Această acțiune este ireversibilă.';

  @override
  String get willBeDeletedTitle => 'Vor fi șterse definitiv:';

  @override
  String get willBeDeletedProfile => '• Profilul tău';

  @override
  String get willBeDeletedRideHistory => '• Istoricul curselor';

  @override
  String get willBeDeletedData => '• Toate datele asociate contului';

  @override
  String get accountPassword => 'Parola contului';

  @override
  String get enterPasswordConfirm => 'Introduceți parola pentru confirmare.';

  @override
  String get deleteAccountButton => 'Ștergere cont';

  @override
  String errorPrefix(Object error) {
    return 'Eroare: $error';
  }

  @override
  String get notificationPreferences => 'Preferințe notificări';

  @override
  String get notifRideSection => 'Curse';

  @override
  String get notifRideNotifications => 'Notificări curse';

  @override
  String get notifRideNotificationsSubtitle =>
      'Solicitări noi, cursă acceptată, șofer în apropiere etc.';

  @override
  String get notifCommunicationSection => 'Comunicare';

  @override
  String get notifChatMessages => 'Mesaje chat';

  @override
  String get notifChatMessagesSubtitle =>
      'Notificări pentru mesaje noi din conversații';

  @override
  String get notifMarketingSection => 'Marketing și actualizări';

  @override
  String get notifPromoOffers => 'Promoții și oferte';

  @override
  String get notifPromoOffersSubtitle =>
      'Reduceri, coduri promoționale și oferte speciale';

  @override
  String get notifAppUpdates => 'Actualizări aplicație';

  @override
  String get notifAppUpdatesSubtitle =>
      'Noutăți și îmbunătățiri ale aplicației';

  @override
  String get notifSafetySection => 'Siguranță';

  @override
  String get notifSafetyAlerts => 'Alerte de siguranță';

  @override
  String get notifSafetyAlertsSubtitle =>
      'Notificări importante legate de siguranța ta în cursă';

  @override
  String get notifSavedSuccess => 'Preferințe salvate cu succes.';

  @override
  String notifLoadError(Object error) {
    return 'Eroare la încărcarea preferințelor: $error';
  }

  @override
  String notifSaveError(Object error) {
    return 'Eroare la salvare: $error';
  }

  @override
  String get privacyLocationSection => 'Locație';

  @override
  String get privacyLocationSharing => 'Partajare locație în timp real';

  @override
  String get privacyLocationSharingSubtitle =>
      'Permite partajarea locației tale cu șoferul în timpul cursei';

  @override
  String get privacyProfileSection => 'Profil';

  @override
  String get privacyProfileVisibility => 'Vizibilitate profil pentru șoferi';

  @override
  String get privacyProfileVisibilitySubtitle =>
      'Șoferii pot vedea profilul tău (nume, fotografie, rating)';

  @override
  String get privacyRideHistoryVisible => 'Istoricul curselor vizibil';

  @override
  String get privacyRideHistoryVisibleSubtitle =>
      'Permite afișarea istoricului curselor în profilul tău public';

  @override
  String get privacyDataSection => 'Date și analiză';

  @override
  String get privacyAnalyticsConsent => 'Date pentru îmbunătățirea serviciului';

  @override
  String get privacyAnalyticsConsentSubtitle =>
      'Ajută-ne să îmbunătățim aplicația prin partajarea datelor de utilizare anonime';

  @override
  String get privacyGdprNote =>
      'Datele tale sunt procesate conform GDPR. Poți solicita exportul sau ștergerea datelor din secțiunea Siguranță și Securitate.';

  @override
  String get privacySavedSuccess => 'Setări de confidențialitate salvate.';

  @override
  String privacyLoadError(Object error) {
    return 'Eroare la încărcarea setărilor: $error';
  }

  @override
  String privacySaveError(Object error) {
    return 'Eroare la salvare: $error';
  }

  @override
  String get adminDocumentReview => 'Verificare Documente Șoferi';

  @override
  String get noPendingApplications => 'Nu există aplicații în așteptare.';

  @override
  String get unknownApplicant => 'Aplicant necunoscut';

  @override
  String statusLabel(Object status) {
    return 'Status: $status';
  }

  @override
  String get missingRequired => 'Lipsă (obligatoriu)';

  @override
  String get missing => 'Lipsă';

  @override
  String rejectDocumentTitle(Object name) {
    return 'Respinge: $name';
  }

  @override
  String get rejectReason => 'Motiv respingere';

  @override
  String get rejectionHint => 'ex. Imagine neclară, document expirat';

  @override
  String documentApproved(Object name) {
    return '✅ $name aprobat';
  }

  @override
  String documentRejected(Object name) {
    return '❌ $name respins';
  }

  @override
  String get activateDriver => 'Activează Șofer';

  @override
  String get driverActivatedTitle => 'Șofer Activat ✅';

  @override
  String driverActivatedContent(Object name) {
    return '$name a fost activat cu succes.';
  }

  @override
  String get accessCodeLabel => 'Cod de acces:';

  @override
  String get accessCodeGenerated => 'Cod de acces generat:';

  @override
  String get sendCodeToDriver => 'Transmiteți acest cod șoferului.';

  @override
  String activationError(Object error) {
    return 'Eroare la activare: $error';
  }

  @override
  String get approveTooltip => 'Aprobă';

  @override
  String get rejectTooltip => 'Respinge';

  @override
  String rejectionReasonLabel(Object reason) {
    return 'Motiv: $reason';
  }

  @override
  String get statusSubmitted => 'Trimis';

  @override
  String get statusUnderReview => 'În revizuire';

  @override
  String get statusApproved => 'Aprobat';

  @override
  String get statusActivated => 'Activat';

  @override
  String get statusRejected => 'Respins';

  @override
  String get docStatusApproved => 'Aprobat';

  @override
  String get docStatusRejected => 'Respins';

  @override
  String get docStatusPending => 'În așteptare';

  @override
  String docExpiresOn(Object date) {
    return 'Expiră: $date';
  }

  @override
  String docExpiredLabel(Object date) {
    return 'EXPIRAT ($date)';
  }

  @override
  String docExpiringSoonLabel(Object date) {
    return 'Expiră în curând ($date)';
  }

  @override
  String get bePartnerDriver => 'Devino Șofer Partener';

  @override
  String get applicationProgress => 'Progres aplicație';

  @override
  String get applicationComplete =>
      'Aplicația este completă și poate fi trimisă!';

  @override
  String get applicationIncomplete =>
      'Completați informațiile și documentele pentru a continua';

  @override
  String get accountActivated => 'Cont Activat 🎉';

  @override
  String accessCodeGeneratedAt(Object date) {
    return 'Generat la: $date';
  }

  @override
  String get personalInfoStep => 'Informații Personale';

  @override
  String get vehicleInfoStep => 'Informații Autovehicul';

  @override
  String get finalDocumentsStep => 'Documente Finale';

  @override
  String get fullNameLabel => 'Nume Complet *';

  @override
  String get ageLabel => 'Vârstă *';

  @override
  String get carBrandLabel => 'Marcă *';

  @override
  String get carModelLabel => 'Model *';

  @override
  String get carColorLabel => 'Culoare *';

  @override
  String get carYearLabel => 'An Fabricație *';

  @override
  String get licensePlateLabel => 'Număr Înmatriculare *';

  @override
  String get bankAccountLabel => 'Cont Bancar (IBAN)';

  @override
  String get importantInfoTitle => 'Informații importante';

  @override
  String get applicationConfirmationText =>
      'Prin trimiterea aplicației, confirmați că:\n• Toate informațiile furnizate sunt corecte\n• Sunteți de acord cu Termenii și Condițiile\n• Acceptați verificarea documentelor\n• Aveți cel puțin 21 de ani împliniți';

  @override
  String get applicationIncompleteWarning =>
      'Vă rugăm să completați toate câmpurile obligatorii și să încărcați documentele necesare înainte de a trimite aplicația.';

  @override
  String get applicationSubmitSuccess =>
      'Aplicația a fost trimisă cu succes pentru verificare!';

  @override
  String applicationLoadError(Object error) {
    return 'Eroare la încărcarea datelor: $error';
  }

  @override
  String applicationSaveError(Object error) {
    return 'Eroare la salvarea datelor: $error';
  }

  @override
  String applicationSubmitError(Object error) {
    return 'Eroare la trimiterea aplicației: $error';
  }

  @override
  String documentUploadSuccess(Object name) {
    return '$name a fost încărcat cu succes!';
  }

  @override
  String documentDeleteSuccess(Object name) {
    return '$name a fost șters cu succes!';
  }

  @override
  String documentUploadError(Object error) {
    return 'Eroare la încărcarea documentului: $error';
  }

  @override
  String documentDeleteError(Object error) {
    return 'Eroare la ștergerea documentului: $error';
  }

  @override
  String get selectSourceTitle => 'Selectează sursa';

  @override
  String get selectSourceContent => 'De unde dorești să selectezi imaginea?';

  @override
  String get cameraOption => 'Cameră';

  @override
  String get galleryOption => 'Galerie';

  @override
  String get selectFileTypeTitle => 'Selectează tipul fișierului';

  @override
  String get selectFileTypeContent =>
      'Dorești să încarci o imagine sau un document PDF?';

  @override
  String get imageOption => 'Imagine';

  @override
  String get pdfOption => 'PDF';

  @override
  String get requiredBadge => 'Obligatoriu';

  @override
  String get documentUploadedText => 'Document încărcat cu succes';

  @override
  String get tapToUploadText => 'Apasă pentru a încărca documentul';

  @override
  String get continueBtn => 'Continuă';

  @override
  String get submitApplication => 'Trimite Aplicația';

  @override
  String get backBtn => 'Înapoi';

  @override
  String get expiryDateTitle => 'Dată expirare';

  @override
  String expiryDateQuestion(Object name) {
    return 'Doriți să setați data de expirare pentru \"$name\"?';
  }

  @override
  String get skipExpiry => 'Nu, sari peste';

  @override
  String get photographOption => 'Fotografiază';

  @override
  String get selectFromGallery => 'Selectează din galerie';

  @override
  String get viewDocumentOption => 'Vizualizează';

  @override
  String get deleteDocumentOption => 'Șterge';

  @override
  String get pdfDocument => 'Document PDF';

  @override
  String get tapToOpen => 'Apasă pentru a deschide';

  @override
  String get errorLoadingImage => 'Eroare la încărcarea imaginii';

  @override
  String get fileTooLarge => 'Fișierul este prea mare (max 10MB)';

  @override
  String get serviceUnavailable => 'Serviciul nu este disponibil temporar';

  @override
  String get connectionError => 'Problemă de conexiune. Verificați internetul';

  @override
  String uploadedAt(Object date) {
    return 'Încărcat: $date';
  }

  @override
  String get selectExpiryDate => 'Selectați data de expirare';

  @override
  String get yes => 'Da';

  @override
  String get drawerSectionActivityAccount => 'Activitate și cont';

  @override
  String get drawerSectionYourCommunity => 'Comunitatea ta';

  @override
  String get drawerSectionMyBusiness => 'Afacerea mea';

  @override
  String get drawerSectionGetInvolved => 'Implicare';

  @override
  String get drawerSectionAiPerformance => 'AI și performanță';

  @override
  String get drawerSectionSupportInfo => 'Suport și informații';

  @override
  String get drawerSectionAddresses => 'Adrese';

  @override
  String get drawerFavoriteAddresses => 'Adrese favorite';

  @override
  String get drawerBusinessOffersTitle => 'Oferte din cartier';

  @override
  String get drawerSocialMapTitle => 'Harta socială';

  @override
  String get drawerSocialVisible => 'Vizibil';

  @override
  String get drawerSocialHidden => 'Ascuns';

  @override
  String get drawerVoiceAiSettingsTitle => 'Setări voce AI';

  @override
  String drawerBusinessDashboardTitle(String businessName) {
    return 'Panoul meu: $businessName';
  }

  @override
  String get drawerBusinessRegisterTitle => 'Înregistrează-ți afacerea';

  @override
  String get businessIntroTitle => 'Afacerea mea';

  @override
  String get businessIntroBody =>
      'Trebuie mai întâi să îți înregistrezi afacerea. După înregistrare o poți administra: editezi cardul afișat în Oferte din cartier și gestionezi anunțurile (adaugi, modifici sau ștergi) din Panoul de business.';

  @override
  String get businessIntroContinueButton => 'Continuă la înregistrare';

  @override
  String get drawerTeamNabour => 'Echipa Nabour';

  @override
  String get drawerRolePassenger => 'Pasager';

  @override
  String get drawerRoleDriver => 'Șofer';

  @override
  String get drawerThemeDarkLabel => 'Temă: întunecată';

  @override
  String get drawerThemeLightLabel => 'Temă: deschisă';

  @override
  String get drawerMenuWeekReview => 'Recap săptămână';

  @override
  String get drawerMenuMysteryBoxActivity => 'Activitate cutii';

  @override
  String get drawerMenuTokenTransfer => 'Transfer tokeni';

  @override
  String get drawerGroupAccountActivity => 'Cont, istoric și activitate';

  @override
  String get drawerGroupMapAddresses => 'Hartă și adrese';

  @override
  String get drawerGroupCommunityFeed => 'Comunitate și descoperiri';

  @override
  String get drawerGroupSocialApp => 'Vizibilitate și aplicație';

  @override
  String get drawerGroupHelpLegal => 'Ajutor și informații legale';

  @override
  String get drawerMenuMyGarage => 'Garajul meu';

  @override
  String get drawerMenuPlaces => 'Locuri';

  @override
  String get drawerMenuExplorations => 'Explorări';

  @override
  String get drawerMenuSyncContacts => 'Sincronizează contactele';

  @override
  String get drawerShowHomeOnMap =>
      'Afișează Acasă (favorite) pe hartă\n(doar pentru tine)';

  @override
  String get drawerOrientationMarkerOnMap =>
      'Reper orientare pe hartă\n(ține apăsat pe hartă după activare)';

  @override
  String get drawerHideHomeOnMap =>
      'Ascunde Acasă de pe hartă\n(doar markerul favorite)';

  @override
  String get drawerHideOrientationMarker =>
      'Ascunde reper orientare\n(elimină acul de pe hartă)';

  @override
  String get drawerActiveContactsOnMap => 'Contacte active pe hartă';

  @override
  String get drawerIdCopied => 'ID copiat în clipboard.';

  @override
  String get drawerSyncContactsDialogTitle => 'De ce sincronizare?';

  @override
  String get drawerSyncContactsDialogBody =>
      'Aplicația îți arată pe hartă doar persoanele care sunt în agenda ta și care folosesc Nabour.\n\nDacă ai adăugat un contact nou sau un prieten tocmai s-a înscris, apasă „Sincronizează” pentru a actualiza lista de vizibilitate pe harta socială.';

  @override
  String get drawerSyncContactsDialogOk => 'Înțeles';

  @override
  String get warmupCloseTooltip => 'Închide';

  @override
  String get warmupHeadline => 'Călătorește cu\nvecinii tăi';

  @override
  String get warmupShortcutsTitle => 'Scurtături';

  @override
  String get warmupShortcutRideTitle => 'Cursă';

  @override
  String get warmupShortcutRideSubtitle => 'Cere acum';

  @override
  String get warmupShortcutMapTitle => 'Hartă';

  @override
  String get warmupShortcutMapSubtitle => 'Disponibili în zonă';

  @override
  String get warmupShortcutChatTitle => 'Chat';

  @override
  String get warmupShortcutChatSubtitle => 'Cartierul tău';

  @override
  String get warmupScheduleTitle => 'Planifică mai târziu';

  @override
  String get warmupScheduleSubtitle =>
      'Anunță din timp — vecinii confirmă când sunt liberi.';

  @override
  String get warmupWhyTitle => 'De ce Nabour?';

  @override
  String get warmupCtaOpenMap => 'Mergi la hartă';

  @override
  String get warmupSubtitle => 'Centrul comunității tale';

  @override
  String warmupExampleRidesCount(String count) {
    return '$count Curse Active în Apropiere';
  }

  @override
  String warmupExampleDealsCount(String count) {
    return '$count Oferte Noi Astăzi';
  }

  @override
  String warmupExampleMessagesCount(String count) {
    return '$count Mesaje Noi';
  }

  @override
  String get warmupExampleRide1 => 'Sarah B. (2 min) → Centru';

  @override
  String get warmupExampleRide2 => 'Mihai K. (5 min) → Gară';

  @override
  String get warmupExampleOffer1 => 'The Daily Grind: 20% reducere la cafea';

  @override
  String get warmupExampleOffer2 =>
      'Urban Bites: Garnitură gratis la orice fel';

  @override
  String get warmupExampleChat1 => 'Alex: Cine vrea la o plimbare în parc...?';

  @override
  String get warmupExampleChat2 => 'Chloe: S-a auzit un zgomot pe Elm St...';

  @override
  String get warmupSwipeDownHint => 'Sau trage în jos pentru a închide';

  @override
  String get warmupHeroNeighborsTitle => 'Curse între vecini';

  @override
  String get warmupHeroNeighborsSubtitle =>
      'Cere o cursă pe hartă; șoferii disponibili din comunitate te pot prelua.';

  @override
  String get warmupHeroBusinessTitle => 'Oferte locale';

  @override
  String get warmupHeroBusinessSubtitle =>
      'Promovează afacerea cu anunțuri vizibile în zonă, direct din app.';

  @override
  String get warmupHeroSafetyTitle => 'Siguranță la drum';

  @override
  String get warmupHeroSafetySubtitle =>
      'Partajare traseu live, chat în cursă și verificări clare la îmbarcare.';

  @override
  String get warmupHeroChatTitle => 'Chat de cartier';

  @override
  String get warmupHeroChatSubtitle =>
      'Conversații în zona ta; poți filtra și după contactele din telefon.';

  @override
  String get warmupFeatureCommunityTitle => 'Ecosistem unificat';

  @override
  String get warmupFeatureCommunitySubtitle =>
      'Curse, chat și oferte într-o singură aplicație — mai simplu decât să sari între grupuri.';

  @override
  String get warmupFeatureContactsTitle => 'Încredere controlată';

  @override
  String get warmupFeatureContactsSubtitle =>
      'Alege cine te vede: comunitatea din zonă sau doar oameni din agendă.';

  @override
  String get warmupFeatureLiveTitle => 'Live pe hartă';

  @override
  String get warmupFeatureLiveSubtitle =>
      'Disponibilitate și status actualizate, ca să știi rapid cine poate ajuta.';

  @override
  String get warmupFeatureSecureTitle => 'Transparent și previzibil';

  @override
  String get warmupFeatureSecureSubtitle =>
      'Istoric, tokeni clari pentru acțiuni și suport când ai nevoie.';

  @override
  String get drawerDefaultUserName => 'Utilizator';

  @override
  String get drawerTrialPrivilegedTitle => 'Cont privilegiat';

  @override
  String get drawerTrialPrivilegedSubtitle =>
      'Acces nelimitat la toate funcționalitățile.';

  @override
  String get drawerTrialSevenDayTitle => '7 zile trial';

  @override
  String get drawerTrialPricingSubtitle =>
      'Apoi 10 RON/lună (PF) sau 15 RON/lună (firme).';

  @override
  String get drawerTrialDuringSubtitle =>
      'Apoi 10 RON/lună (PF) / 15 RON/lună (firme).';

  @override
  String drawerTrialDaysLeftTitle(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zile rămase din trial',
      one: 'O zi rămasă din trial',
    );
    return '$_temp0';
  }

  @override
  String get drawerTrialExpiredTitle => 'Trial expirat';

  @override
  String get drawerTrialExpiredSubtitle =>
      'Abonează-te (10/15 RON) pentru a continua.';

  @override
  String get activateDriverCodeLabel => 'Cod de activare';

  @override
  String get activateDriverCodeHint => 'Ex: DRV-TEST-102';

  @override
  String get tokenShopTitle => 'Tokeni și planuri';

  @override
  String get tokenShopTabPlans => 'Planuri';

  @override
  String get tokenShopTabTopup => 'Top-up';

  @override
  String get tokenShopTabHistory => 'Istoric';

  @override
  String get tokenShopChoosePlanTitle => 'Alege planul tău';

  @override
  String get tokenShopChoosePlanSubtitle =>
      'Tokenii se resetează în prima zi a fiecărei luni';

  @override
  String get tokenShopAlreadyOnPlan => 'Deja ești pe acest plan.';

  @override
  String get tokenShopDowngradeContactSupport =>
      'Contactează suportul pentru downgrade.';

  @override
  String tokenShopUpgradeSuccess(String planName) {
    return 'Upgrade la $planName realizat!';
  }

  @override
  String get tokenShopErrorPaymentsNotReady =>
      'Plățile nu sunt încă activate pe server. Configurează Cloud Functions (vezi functions/).';

  @override
  String tokenShopErrorWithMessage(String message) {
    return 'Eroare: $message';
  }

  @override
  String tokenShopUpgradeError(String error) {
    return 'Eroare upgrade: $error';
  }

  @override
  String get tokenShopMostPopular => 'CEL MAI POPULAR';

  @override
  String get tokenShopPopularBadge => 'POPULAR';

  @override
  String get tokenShopActive => 'Activ';

  @override
  String get tokenShopSelect => 'Selectează';

  @override
  String get tokenShopBuyExtraTitle => 'Cumpără tokeni extra';

  @override
  String get tokenShopBuyExtraSubtitle =>
      'Tokenii cumpărați nu expiră niciodată';

  @override
  String get tokenShopTokensWord => 'tokeni';

  @override
  String tokenShopTokensAdded(int count) {
    return '+$count tokeni adăugați în cont!';
  }

  @override
  String get tokenShopTopupRequiresBackend =>
      'Top-up necesită backend (ALLOW_UNVERIFIED_WALLET_CREDIT sau plată reală).';

  @override
  String get tokenShopNoTransactions => 'Nicio tranzacție încă.';

  @override
  String get tokenShopPaymentMethodsTitle => 'Metode de plată acceptate';

  @override
  String get tokenShopPaymentSecureFooter =>
      'Plățile sunt procesate securizat. Nu stocăm datele cardului.';

  @override
  String get tokenShopPaymentMethodTitle => 'Metodă de plată';

  @override
  String get tokenShopPay => 'Plătește';

  @override
  String get tokenShopTestModeDisclaimer =>
      'Plățile reale nu sunt încă conectate. „Plătește” simulează tranzacția: planul și tokenii se actualizează prin server (Firebase Functions). Dacă apare eroare, rulează „firebase deploy --only functions” sau setează parametrul ALLOW_UNVERIFIED_WALLET_CREDIT=true în consolă.';

  @override
  String get tokenShopMethodNetopia => 'Netopia (card RO)';

  @override
  String get tokenShopMethodStripe => 'Stripe';

  @override
  String get tokenShopMethodRevolut => 'Revolut Pay';

  @override
  String get tokenShopPackageStarter => 'Starter';

  @override
  String get tokenShopPackagePopular => 'Popular';

  @override
  String get tokenShopPackageAdvanced => 'Avansat';

  @override
  String get tokenShopPackageBusiness => 'Business';

  @override
  String get tokenPlanFreeName => 'Gratuit';

  @override
  String get tokenPlanBasicName => 'Basic';

  @override
  String get tokenPlanProName => 'Pro';

  @override
  String get tokenPlanUnlimitedName => 'Unlimited';

  @override
  String get tokenPlanPriceFree => 'Gratuit';

  @override
  String get tokenPlanPriceBasic => '9 RON / lună';

  @override
  String get tokenPlanPricePro => '29 RON / lună';

  @override
  String get tokenPlanPriceUnlimited => '49 RON / lună';

  @override
  String tokenShopPlanAllowanceMonthly(String allowance) {
    return '$allowance tokeni / lună';
  }

  @override
  String tokenShopEconomyApproxLine(int ai, int routes, int geo, int br) {
    return '≈ $ai AI · $routes rute · $geo geocodări · $br postări';
  }

  @override
  String tokenShopEconomyBusinessLine(int biz, int tokens) {
    return '≈ $biz anunțuri business ($tokens tokeni/anunț)';
  }

  @override
  String get tokenShopEconomyUnlimited =>
      'Nelimitat: AI, rute, geocodare și postări fără consum din cotă lunară.';

  @override
  String get tokenShopStaffMenuTooltip => 'Setare abonament staff';

  @override
  String get tokenShopStaffDialogTitle => 'Abonament staff (cont autorizat)';

  @override
  String get tokenShopStaffApplied => 'Abonament aplicat.';

  @override
  String tokenShopTxPurchasePackage(String label, int count) {
    return 'Pachet $label · $count tokeni';
  }

  @override
  String get about_appMissionTagline =>
      'Vecini, curse și chat de cartier — într-o singură aplicație, pe harta ta.';

  @override
  String get settingsSectionUpdates => 'Actualizări';

  @override
  String get settingsSectionInterfaceData => 'Interfață și date';

  @override
  String get settingsSectionPrivacyLanguage => 'Confidențialitate și limbă';

  @override
  String get settingsVisibilityExclusionsTitle => 'Excluderi vizibilitate';

  @override
  String get settingsVisibilityExclusionsSubtitle =>
      'Alege cine nu te poate vedea pe harta socială';

  @override
  String get driverMenuViewDailyReport => 'Vezi raportul zilnic';

  @override
  String get accountScreenTitle => 'Cont Nabour';

  @override
  String get accountDefaultNeighbor => 'Vecin';

  @override
  String get accountDriverPartnerBadge => 'Șofer partener Nabour';

  @override
  String get accountMenuDriverVehicleDetails => 'Detalii șofer și autovehicul';

  @override
  String get accountMenuPersonalDetails => 'Date personale';

  @override
  String get accountMenuSecurity => 'Siguranță și cont';

  @override
  String get accountMenuSavedAddresses => 'Adrese salvate';

  @override
  String get accountMenuRidePreferences => 'Preferințe cursă';

  @override
  String get accountMenuRideHistory => 'Istoric curse';

  @override
  String get accountMenuBusinessProfile => 'Profil business';

  @override
  String get accountMenuSelfieVerification => 'Verificare identitate (selfie)';

  @override
  String get accountMenuNotifications => 'Notificări';

  @override
  String get accountMenuPrivacy => 'Confidențialitate';

  @override
  String get accountDeleteTitle => 'Șterge contul definitiv';

  @override
  String get accountDeleteBody =>
      'Acțiunea este ireversibilă. Introdu parola pentru a confirma.';

  @override
  String get accountDeletePasswordLabel => 'Parolă';

  @override
  String get accountDeletePasswordError => 'Introdu parola.';

  @override
  String get accountDeleteConfirm => 'Șterge contul';

  @override
  String tokenWalletBalanceShort(String balance) {
    return '$balance tokeni';
  }

  @override
  String tokenWalletDrawerSubline(String spent, String allowance, String when) {
    return '$spent / $allowance folosiți · reset $when';
  }

  @override
  String tokenWalletAvailableLong(String balance) {
    return '$balance tokeni disponibili';
  }

  @override
  String tokenWalletPlanLine(String planName) {
    return 'Plan $planName';
  }

  @override
  String get tokenWalletUsedThisMonth => 'Folosit luna aceasta';

  @override
  String tokenWalletPercentUsage(String pct, String spent, String allowance) {
    return '$pct% ($spent / $allowance)';
  }

  @override
  String tokenWalletAutoReset(String when) {
    return 'Reset automat: $when';
  }

  @override
  String get tokenWalletStatTotalSpent => 'Total consumat';

  @override
  String get tokenWalletStatTotalEarned => 'Total primit';

  @override
  String get tokenWalletOpenShopCta => 'Tokeni și planuri';

  @override
  String tokenWalletResetInDays(int days) {
    return 'în $days zile';
  }

  @override
  String tokenWalletResetInHours(int hours) {
    return 'în $hours h';
  }

  @override
  String get tokenWalletResetTomorrow => 'mâine';

  @override
  String get helpWeekReviewTitle => 'Week in Review și istoricul locațiilor';

  @override
  String get helpWeekReviewHeader => 'Cum funcționează Week in Review';

  @override
  String get helpWeekReviewIntro =>
      'Week in Review construiește un recap vizual al deplasărilor tale pe o perioadă selectată (de obicei ultima săptămână), cu traseu animat, hotspot-uri și statistici (km / ore active).';

  @override
  String get helpWeekReviewDataSourceTitle => 'De unde se iau datele';

  @override
  String get helpWeekReviewDataSourceBody =>
      'Aplicația folosește punctele brute de locație din backend doar ca sursă de input pentru generarea recap-ului.';

  @override
  String get helpWeekReviewStorageTitle => 'Unde se stochează recap-ul';

  @override
  String get helpWeekReviewStorageBody =>
      'Istoricul procesat, timeline-ul, hotspot-urile și exporturile Week in Review sunt stocate local, pe dispozitivul tău.';

  @override
  String get helpWeekReviewDeleteTitle => 'Cum se șterge';

  @override
  String get helpWeekReviewDeleteBody =>
      'Mergi în Setări -> Istoric locație (Timeline) -> Șterge istoricul local. Poți seta și retenția locală (ex: 30/60/90 zile).';

  @override
  String get helpWeekReviewPrivacyNote =>
      'Privacy-first: recap-ul și fișierele exportate rămân locale pe telefon. Tu controlezi retenția și ștergerea lor.';

  @override
  String get businessOffersNoOffersInSelectedCategory =>
      'Nu există oferte în categoria selectată';

  @override
  String get businessOffersNoOffersInArea => 'Nu există oferte în zona ta';

  @override
  String get businessOffersTryAnotherCategory => 'Încearcă o altă categorie.';

  @override
  String get businessOffersNoNearbyOffers =>
      'Revino mai târziu pentru oferte noi în apropiere.';

  @override
  String get businessOffersManageFilters => 'Gestionează filtrele';

  @override
  String get businessOffersResetCategory => 'Resetează categoria';

  @override
  String get businessOffersAllCategories => 'Toate categoriile';

  @override
  String get mapGhostDurationTitle => 'Cât timp ești vizibil vecinilor?';

  @override
  String get mapGhostDurationSubtitle =>
      'Vecinii te vor vedea ca bulă pe hartă.';

  @override
  String get mapGhostOneHourLabel => '1 oră';

  @override
  String get mapGhostOneHourSub => 'Util pentru o ieșire scurtă';

  @override
  String get mapGhostFourHoursLabel => '4 ore';

  @override
  String get mapGhostFourHoursSub => 'Util pentru o după-amiază';

  @override
  String get mapGhostUntilTomorrowLabel => 'Până mâine';

  @override
  String get mapGhostUntilTomorrowSub => 'Se resetează la miezul nopții';

  @override
  String get mapGhostPermanentLabel => 'Permanent';

  @override
  String get mapGhostPermanentSub => 'Rămâi vizibil până dezactivezi manual';

  @override
  String get mapGhostInvisibleLabel => 'Invizibil (mod fantomă)';

  @override
  String get mapGhostInvisibleSub =>
      'Nu apari pe hartă; profilul marchează ghostMode în cont (sync între dispozitive).';

  @override
  String get mapDeleteMomentTitle => 'Ștergi momentul?';

  @override
  String get mapDeleteMomentContent =>
      'Postarea va dispărea de pe hartă pentru toți.';

  @override
  String get mapMomentDeleted => 'Momentul a fost șters.';

  @override
  String get mapMomentDeleteError => 'Nu s-a putut șterge. Încearcă din nou.';

  @override
  String get mapDeleteOrCancelPost => 'Șterge / anulează postarea';

  @override
  String get mapPinNameLabel => 'Denumire';

  @override
  String get mapPinNameHint => 'ex.: intrarea principală';

  @override
  String get mapPinNameTitle => 'Denumire reper';

  @override
  String get mapOrientationPinSaved =>
      'Reperul de orientare a fost salvat pe hartă.';

  @override
  String get mapEditHomeAddressTitle => 'Editează adresa Acasă';

  @override
  String get mapEditHomeAddressSubtitle => 'Schimbi poziția din Adrese salvate';

  @override
  String get mapHideHomeFromMapTitle => 'Ascunde Acasă de pe hartă';

  @override
  String get mapMoveOrientationMarkerTitle => 'Mută reperul';

  @override
  String mapMoveOrientationMarkerWithName(String name) {
    return '„$name” · apoi ține apăsat pe hartă la noul loc';
  }

  @override
  String get mapMoveOrientationMarkerNoName =>
      'Apoi ține apăsat pe hartă la noul loc';

  @override
  String get mapLongPressForNewMarker =>
      'Ține apăsat pe hartă pentru noul reper.';

  @override
  String get mapRemoveOrientationMarkerTitle => 'Elimină reperul de orientare';

  @override
  String get mapMarkerRemoved => 'Reperul a fost eliminat.';

  @override
  String get mapSaveHomeFirst =>
      'Salvează adresa „Acasă” în favorite (cu poziție pe hartă), apoi încearcă din nou.';

  @override
  String get mapHomeShownForYou =>
      'Acasă din favorite este afișată pe hartă (doar pentru tine).';

  @override
  String get mapHomeNotShown => 'Acasă nu este afișată pe hartă.';

  @override
  String get mapHomeNoLongerShown => 'Acasă nu mai este afișată pe hartă.';

  @override
  String get mapNoOrientationMarker => 'Nu ai un reper de orientare pe hartă.';

  @override
  String get mapOrientationMarkerRemovedFromMap =>
      'Reperul de orientare a fost eliminat de pe hartă.';

  @override
  String get mapEmojiRemoved => 'Emoji-ul tău a fost scos de pe hartă';

  @override
  String get mapEmojiDeleteError =>
      'Nu am putut șterge emoji-ul. Încearcă din nou.';

  @override
  String get mapMomentExpired => 'Expirat';

  @override
  String mapMomentExpiresInMinutes(int minutes) {
    return '~$minutes min până dispare de pe hartă';
  }

  @override
  String get mapMomentExpiresSoon => 'Dispare în curând de pe hartă';

  @override
  String mapArrivedAtDestination(String destination) {
    return 'Ai ajuns la destinație: $destination';
  }

  @override
  String get mapDestinationUnset => 'Destinație nestabilită';

  @override
  String mapRideBroadcastWantsToGo(String destination) {
    return 'Vrea să meargă la: $destination';
  }

  @override
  String get mapSeeRequestAndOfferRide => 'VEZI CEREREA ȘI OFERĂ CURSĂ';

  @override
  String mapAcceptRideError(String error) {
    return 'Eroare la acceptarea cursei: $error';
  }

  @override
  String get mapPickupExternalNavigation => 'Pickup: navigație externă';

  @override
  String get mapDestinationExternalNavigation =>
      'Destinație: navigație externă';

  @override
  String get mapClosePanel => 'Închide panoul';

  @override
  String get mapWaitingGpsLocation => 'Așteptăm localizarea GPS...';

  @override
  String mapCreateRideError(String error) {
    return 'Eroare la crearea cursei: $error';
  }

  @override
  String get mapWaitingGpsToPlaceBox =>
      'Așteptăm poziția GPS pentru a plasa cutia aici.';

  @override
  String get mapPlace => 'Plasează';

  @override
  String mapBoxPlaced(int tokens) {
    return 'Cutie plasată! (-$tokens tokeni)';
  }

  @override
  String mapPoiLoadError(String error) {
    return 'Eroare la încărcarea POI-urilor: $error';
  }

  @override
  String get mapNavigateToMarkedPlace => 'Navighează la locul marcat';

  @override
  String get mapDeleteMarkerAndRestart => 'Șterge marcajul și începe din nou';

  @override
  String get mapSpotReserved => 'Loc rezervat! Ai 3 minute să ajungi.';

  @override
  String get mapAddToFavoriteAddresses => 'Adaugă la adrese favorite';

  @override
  String get mapNavigateWithExternalApps => 'Navighează cu Google Maps / Waze';

  @override
  String get mapSpotAlreadyReserved =>
      'Ne pare rău, locul a fost deja rezervat.';

  @override
  String get chatImageTooLargePrivate =>
      'Imaginea e încă prea mare după compresie (max ~1,8 MB). Încearcă o poză mai mică.';

  @override
  String get chatImageTooLargeGeneral => 'Imaginea e prea mare (max ~7 MB).';

  @override
  String get chatImageUploadFailed => 'Nu s-a putut încărca imaginea.';

  @override
  String get chatPhotoLabel => 'Fotografie';

  @override
  String get chatVoiceMessageLabel => 'Mesaj vocal';

  @override
  String get chatMessageSendFailed => 'Mesajul nu a putut fi trimis.';

  @override
  String get chatGifLabel => 'GIF';

  @override
  String get chatPhoneNotAvailable => 'Numărul de telefon nu este disponibil.';

  @override
  String get chatCallFailed => 'Nu s-a putut iniția apelul.';

  @override
  String get chatMessagesLoadFailed => 'Nu s-au putut încărca mesajele.';

  @override
  String get chatTyping => 'scrie...';

  @override
  String get chatEndToEndEncrypted => 'Mesajele sunt criptate end-to-end.';

  @override
  String get chatToday => 'Astăzi';

  @override
  String get chatYesterday => 'Ieri';

  @override
  String get chatQuickReplyHere => 'Sunt aici 👋';

  @override
  String get chatQuickReplyIn2Min => 'Vin în 2 min ⏱️';

  @override
  String get chatQuickReplyIn5Min => 'Vin în 5 min ⏱️';

  @override
  String get chatQuickReplyArrived => 'Ai ajuns? 📍';

  @override
  String get chatQuickReplyThanks => 'Mulțumesc! 🙏';

  @override
  String get chatQuickReplyOk => 'OK 👍';

  @override
  String get you => 'Tu';

  @override
  String get chatVoiceMessageSendFailed =>
      'Mesajul vocal nu a putut fi trimis.';

  @override
  String get chatReply => 'Răspunde';

  @override
  String get chatCopy => 'Copiază';

  @override
  String get chatMessageCopied => 'Mesaj copiat.';

  @override
  String get chatChooseGif => 'Alege GIF';

  @override
  String get chatSearchHint => 'Caută…';

  @override
  String get privateChatNotAuthenticated => 'Nu ești autentificat.';

  @override
  String get privateChatReaction => 'Reacție';

  @override
  String get privateChatNewChat => 'Chat nou';

  @override
  String get privateChatAddContactsToChoose =>
      'Adaugă contacte în agendă sau prieteni ca să poți alege o persoană.';

  @override
  String get privateChatOnMap => 'Pe hartă';

  @override
  String get privateChatNoPeopleYet =>
      'Nu ai încă persoane în agendă sau prieteni confirmați.';

  @override
  String get privateChatAddContactsOrAcceptSuggestions =>
      'Adaugă contacte sau acceptă cereri în tab-ul Sugestii ca să poți începe conversații private.';

  @override
  String get privateChatConversationsHint =>
      'Conversații private — aceleași mesaje ca din profilul unui vecin pe hartă.';

  @override
  String get privateChatOnMapNowTapToWrite =>
      'Pe hartă acum — apasă pentru a scrie';

  @override
  String get privateChatTapToSendMessage => 'Apasă pentru a trimite un mesaj';

  @override
  String get chatLocationLabel => 'Locație';

  @override
  String get friendSuggestionsUserFallback => 'Utilizator';

  @override
  String get friendSuggestionsAlreadyFriends =>
      'Sunteți deja prieteni în Nabour.';

  @override
  String get friendSuggestionsRequestAlreadySent =>
      'Ai trimis deja o cerere către această persoană.';

  @override
  String get friendSuggestionsRequestSent => 'Cerere de prietenie trimisă!';

  @override
  String get friendSuggestionsRequestPermissionDenied =>
      'Nu avem voie să scriem cererea (reguli Firebase). Contactează suportul.';

  @override
  String get friendSuggestionsRequestFailed =>
      'Nu am putut trimite cererea. Încearcă din nou.';

  @override
  String friendSuggestionsAcceptedFrom(String name) {
    return 'Ai acceptat cererea de la $name! ✓';
  }

  @override
  String get friendSuggestionsFriendFallback => 'prieten';

  @override
  String get friendSuggestionsPermissionAcceptDenied =>
      'Nu avem voie să acceptăm (reguli Firebase).';

  @override
  String get friendSuggestionsAcceptFailed =>
      'Nu am putut accepta cererea. Încearcă din nou.';

  @override
  String get friendSuggestionsRejected => 'Cererea a fost refuzată.';

  @override
  String get friendSuggestionsRejectFailed =>
      'Nu am putut refuza cererea. Încearcă din nou.';

  @override
  String get friendSuggestionsThisUser => 'acest utilizator';

  @override
  String get friendSuggestionsRemoveTitle => 'Elimină din prieteni';

  @override
  String friendSuggestionsRemoveConfirm(String name) {
    return 'Sigur vrei să îl elimini pe $name din lista ta? Nu vei mai vedea reciproc pe hartă ca prieteni Nabour până nu retrimiteți cereri.';
  }

  @override
  String get friendSuggestionsCancel => 'Anulează';

  @override
  String get friendSuggestionsRemove => 'Elimină';

  @override
  String friendSuggestionsRemovedFromList(String name) {
    return '$name a fost eliminat din lista ta.';
  }

  @override
  String get friendSuggestionsRemoveFailed =>
      'Nu am putut elimina. Încearcă din nou.';

  @override
  String get friendSuggestionsTabSuggestions => 'Sugestii';

  @override
  String get friendSuggestionsTabMyFriends => 'Prietenii mei';

  @override
  String get friendSuggestionsTabPrivateChat => 'Chat individual';

  @override
  String get friendSuggestionsSearchHint => 'Caută în agendă...';

  @override
  String friendSuggestionsIncomingRequests(int count) {
    return 'Cereri primite ($count)';
  }

  @override
  String get friendSuggestionsAddressBookSuggestions => 'Sugestii din agendă';

  @override
  String get friendSuggestionsNoConfirmedFriends =>
      'Nu ai încă prieteni confirmați.\nAcceptă cereri în tab-ul Sugestii sau trimite tu o cerere.';

  @override
  String get friendSuggestionsLoading => 'Se încarcă…';

  @override
  String get friendSuggestionsOnMapNow => 'Pe hartă acum';

  @override
  String get friendSuggestionsNabourFriend => 'Prieten Nabour';

  @override
  String get friendSuggestionsSendsRequest =>
      'îți trimite o cerere de prietenie';

  @override
  String get friendSuggestionsReject => 'Refuză';

  @override
  String get friendSuggestionsAccept => 'Acceptă';

  @override
  String friendSuggestionsIntroOne(int count) {
    return '$count INTRODUCERE';
  }

  @override
  String friendSuggestionsIntroMany(int count) {
    return '$count INTRODUCERI';
  }

  @override
  String friendSuggestionsFriendsCount(int count) {
    return '$count DE PRIETENI';
  }

  @override
  String get friendSuggestionsFriendsCount50Plus => '50+ DE PRIETENI';

  @override
  String get friendSuggestionsFriendBadge => 'Prieten';

  @override
  String get friendSuggestionsAdded => 'Adăugat';

  @override
  String get friendSuggestionsAdd => 'Adaugă';

  @override
  String get friendSuggestionsBackOnMap => 'este din nou pe hartă';

  @override
  String get disclaimerNoPaymentsTitle => 'Nabour nu intermediază plăți';

  @override
  String get disclaimerNoPaymentsSubtitle =>
      'Aplicația nu intermediază plăți între utilizatori.';

  @override
  String get disclaimerNoPaymentsBody =>
      'Nabour conectează vecini care vor să se ajute reciproc. Dacă un șofer alege să accepte sau să ofere un gest de apreciere, aceasta este exclusiv decizia și responsabilitatea sa personală. Aplicația nu intermediază, nu solicită și nu procesează niciun fel de plată.';

  @override
  String get disclaimerUsageNotice =>
      'Nu sta în aplicație mai mult de 40 de minute pe zi, în medie pe lună — aceasta fie generează costuri, fie te blochează la utilizare.';

  @override
  String get disclaimerUnderstood => 'Am înțeles';

  @override
  String get splashStartupError =>
      'A apărut o eroare la pornire.\nVerifică internetul și încearcă din nou.';

  @override
  String get splashRetry => 'REÎNCEARCĂ';

  @override
  String get splashTakingLonger => 'Pornirea durează mai mult...';

  @override
  String get splashContinueAnyway => 'CONTINUĂ ORICUM';

  @override
  String get splashMadeInRomania => 'Fabricat în România';

  @override
  String get settingsCommunityModeSchool => 'Mod școală / liceu';

  @override
  String get settingsCommunityModeStandard =>
      'Standard (fără etichetă comunitate)';

  @override
  String get settingsNowPlayingNotSet =>
      'Nu e setat — vizibil în profil pentru prieteni';

  @override
  String get settingsVoiceAssistantOnMap => 'Asistent vocal pe hartă';

  @override
  String get settingsVoiceAssistantOnMapSubtitle =>
      'Buton pe hartă și secțiunea din meniu (în curs de îmbunătățiri)';

  @override
  String get settingsGhostModeTitle => 'Mod fantomă (hartă socială)';

  @override
  String get settingsGhostModeSubtitle =>
      'Activezi „Invizibil” din meniul hărții sociale; oprește RTDB și marchează ghostMode în cont.';

  @override
  String get settingsApproximateLocationTitle =>
      'Locație aproximativă (hartă socială)';

  @override
  String get settingsSocialMapSection => 'Hartă socială';

  @override
  String get settingsNearbyNotificationsTitle => 'Notificări „aproape de mine”';

  @override
  String get settingsNearbyAlertRadiusTitle => 'Rază alertă apropiere';

  @override
  String settingsNearbyAlertRadiusSubtitle(int meters) {
    return '$meters m (contacte pe hartă)';
  }

  @override
  String get settingsMusicTitle => 'Muzică (Spotify / Apple Music)';

  @override
  String get settingsMusicSubtitle => 'Deschide Spotify sau Apple Music';

  @override
  String get settingsNowPlayingTitle => 'Ce ascult acum (profil)';

  @override
  String get settingsCommunityModeTitle => 'Mod comunitate / școală';

  @override
  String get settingsLocationHistoryTitle => 'Istoric locație (Timeline)';

  @override
  String get settingsLocationHistoryStartFailed =>
      'Nu s-a putut porni înregistrarea. Acordă acces la locație și, pe Android, „Permite tot timpul” pentru înregistrare când aplicația nu e deschisă.';

  @override
  String get settingsLocationHistoryEnabled =>
      'Istoricul locației a fost activat (vezi notificarea pe Android când rulează în fundal).';

  @override
  String get settingsLocationHistoryDisabled =>
      'Istoricul locației a fost dezactivat.';

  @override
  String get settingsLocalHistoryRetentionTitle => 'Retenție istoric local';

  @override
  String settingsLocalHistoryRetentionSubtitle(int days) {
    return 'Păstrează datele locale $days zile';
  }

  @override
  String get settingsDeleteLocalHistoryTitle => 'Șterge istoricul local';

  @override
  String get settingsDeleteLocalHistorySubtitle =>
      'Șterge recap, cache și timeline local pentru acest cont';

  @override
  String get settingsNearbyNotificationRadiusTitle =>
      'Rază notificare apropiere';

  @override
  String settingsLocalHistoryRetentionSet(int days) {
    return 'Retenția locală a fost setată la $days zile.';
  }

  @override
  String get settingsNowPlayingSheetTitle => 'Ce ascult acum';

  @override
  String get settingsNowPlayingSongLabel => 'Piesă / titlu';

  @override
  String get settingsMusicProfileUpdated => 'Profil muzical actualizat.';

  @override
  String get settingsSaveToAccount => 'Salvează în cont';

  @override
  String get settingsDeleteFromProfile => 'Șterge din profil';

  @override
  String get settingsCommunitySheetTitle => 'Comunitate';

  @override
  String get settingsCommunityModeSaved => 'Mod comunitate salvat.';

  @override
  String get settingsDeleteLocalHistoryConfirmTitle =>
      'Ștergi istoricul local?';

  @override
  String get settingsDeleteLocalHistoryConfirmContent =>
      'Această acțiune șterge recap-ul și cache-ul local Week in Review pentru contul curent.';

  @override
  String get settingsLocalHistoryDeleted => 'Istoricul local a fost șters.';

  @override
  String tokenShopChoosePaymentMethodFor(String planName) {
    return 'Alege metoda de plată pentru $planName';
  }

  @override
  String get tokenShopPayByCard => 'Plată cu cardul';

  @override
  String tokenShopPriceWithAutoRenewal(String price) {
    return 'Preț: $price (Reînnoire automată)';
  }

  @override
  String get tokenShopPayWithTransferableTokens =>
      'Plătește cu tokeni transferabili';

  @override
  String tokenShopPriceInTokensNoRenewal(int tokens) {
    return 'Preț: $tokens tokeni (Fără reînnoire)';
  }

  @override
  String get tokenShopInsufficientShort => 'Insuficient';

  @override
  String tokenShopPlanActivated(String planName) {
    return 'Planul $planName a fost activat!';
  }

  @override
  String get tokenShopUnlimitedAccessNetworkIntelligence =>
      'Acces absolut la inteligența rețelei.';

  @override
  String get tokenShopPersonalTokensSubtitle =>
      'Tokeni pentru AI, rute și funcțiile tale.';

  @override
  String get tokenShopTransferablePackagesTitle => 'PACHETE TRANSFERABILE';

  @override
  String get tokenShopTransferablePackagesSubtitle =>
      'Tokeni reali pe care îi poți trimite oricui.';

  @override
  String tokenShopTransferablePackageTitle(int tokens) {
    return 'Pachet transferabil: $tokens tokeni';
  }

  @override
  String tokenShopTxPurchaseTransferablePackage(String label) {
    return 'Cumpărare pachet TRANSFERABIL: $label';
  }

  @override
  String get tokenShopTransferableWalletSuffix =>
      ' (în portofelul transferabil)';

  @override
  String get neighborhoodChatMuted => 'Chat silențios';

  @override
  String get neighborhoodChatSoundOn => 'Sunet activat';

  @override
  String get neighborhoodChatGpsDisabled =>
      'GPS dezactivat. Activează locația pentru chat.';

  @override
  String get neighborhoodChatGpsPermissionDenied => 'Permisiune GPS refuzată.';

  @override
  String get neighborhoodChatInvalidServerResponse =>
      'Chat cartier: răspuns invalid de la server (roomId H3).';

  @override
  String neighborhoodChatFunctionsUnavailable(String code) {
    return 'Chat cartier: Functions indisponibile ($code).';
  }

  @override
  String get neighborhoodChatActivationFailed => 'Nu s-a putut activa chat-ul.';

  @override
  String get neighborhoodChatLocationResolveFailed =>
      'Nu s-a putut determina locația.';

  @override
  String get neighborhoodChatInappropriateMessage => 'Mesaj inadecvat.';

  @override
  String get neighborhoodChatOnMyWay => 'Sunt pe drum!';

  @override
  String get neighborhoodChatMarkedLocation => 'Am marcat o locație pe hartă';

  @override
  String get neighborhoodChatTitle => 'Chat cartier';

  @override
  String get neighborhoodChatInviteNeighbors => 'Invită vecini';

  @override
  String get neighborhoodChatNoAccessOrRulesChanged =>
      'Nu ai acces la acest chat sau regulile de securitate s-au schimbat. Reîncearcă după ce te autentifici din nou.';

  @override
  String get neighborhoodChatNoRecentMessages => 'Niciun mesaj recent';

  @override
  String get neighborhoodChatEmptyHint =>
      'Spune „Bună” vecinilor sau trimite o locație. Mesajele dispar după 30 minute.';

  @override
  String get neighborhoodChatSendLocationTooltip => 'Trimite locația ta';

  @override
  String neighborhoodChatInviteText(String roomId) {
    return 'Vino în chat-ul cartierului Nabour! Suntem vecini în zona H3: $roomId';
  }

  @override
  String get neighborhoodChatInfoBody1 =>
      'Acesta este un spațiu efemer pentru vecinii din aceeași zonă H3 (aprox. 1km²).';

  @override
  String get neighborhoodChatInfoBody2 =>
      '• Mesajele dispar automat după 30 de minute.\n• Poți trimite locația sau mesaje text.\n• Respectă vecinii și păstrează comunitatea curată!';

  @override
  String get neighborhoodChatFlyToHint =>
      'Apasă pentru animația \"FlyTo\" către punctul marcat de vecin.';

  @override
  String get neighborhoodChatSeeOnMap => 'VEZI PE HARTĂ';

  @override
  String get placesHubTabLearned => 'Învățate';

  @override
  String get placesHubTabFavorites => 'Favorite';

  @override
  String get placesHubTabRecommendations => 'Recomandări';

  @override
  String get placesHubNoLearnedPlaces =>
      'Încă nu avem locuri învățate. Rămâi cu aplicația deschisă pe hartă — detectăm zonele unde stai mai mult (confidențial, pe telefon).';

  @override
  String placesHubFrequentArea(int minutes) {
    return 'Zonă frecventată ($minutes min acumulate)';
  }

  @override
  String placesHubVisitsConfidence(int visits, int confidence) {
    return '$visits vizite · încredere $confidence%';
  }

  @override
  String get placesHubFavoritesHint =>
      'Adresele tale salvate apar și pe hartă ca „acasă / serviciu” când ești aproape.';

  @override
  String get placesHubManageFavoriteAddresses => 'Gestionează adrese favorite';

  @override
  String get placesHubDiscoverNeighborhood => 'Descoperă cartierul';

  @override
  String get placesHubDiscoverNeighborhoodHint =>
      'Activează vizibilitatea pe harta socială ca să vezi cereri, momente și vecini. Locurile învățate se îmbogățesc automat din mișcarea ta.';

  @override
  String get placesHubFriendsNearbyTitle => 'Prieteni în zonă';

  @override
  String get placesHubFriendsNearbySubtitle =>
      'Pe harta principală vezi contactele care te-au adăugat și sunt aproape.';

  @override
  String get placesHubPreviewTitle => 'Previzualizare';

  @override
  String get rideBroadcastDeleteRequestTitle => 'Șterge cererea';

  @override
  String get rideBroadcastDeleteRequestConfirm =>
      'Ești sigur că vrei să ștergi această cerere din istoricul tău?';

  @override
  String get rideBroadcastFeedTitle => 'Cereri din cartier';

  @override
  String rideBroadcastActiveRadiusTooltip(int km) {
    return 'În tab-ul „Active” afișăm cererile în cel mult $km km față de locația ta curentă (când locația e disponibilă).';
  }

  @override
  String get rideBroadcastTabActive => 'Active';

  @override
  String get rideBroadcastTabMapBubbles => 'Bule pe hartă';

  @override
  String get rideBroadcastTabMyHistory => 'Istoricul meu';

  @override
  String get rideBroadcastVisibleOnlyForYouNoContacts =>
      'Cererea e vizibilă doar pentru tine: în agendă nu am găsit alți utilizatori Nabour cu numărul din profilul lor.';

  @override
  String rideBroadcastVisibleForYouAndContacts(String people) {
    return 'Cererea e vizibilă pentru tine și pentru încă $people din agendă.';
  }

  @override
  String get rideBroadcastEnableLocationForMapRequest =>
      'Activează locația ca să plasezi o cerere pe hartă.';

  @override
  String get rideBroadcastRequestRide => 'Cer o cursă';

  @override
  String get rideBroadcastMapRequest => 'Cerere pe hartă';

  @override
  String rideBroadcastBubblesLoadFailed(String error) {
    return 'Nu s-au putut încărca bulele. Trage în jos pentru reîncercare.\n$error';
  }

  @override
  String rideBroadcastNoBubbleInRadius(int km) {
    return 'Nicio bulă în raza de $km km';
  }

  @override
  String get rideBroadcastNoActiveBubbleHere => 'Nicio bulă activă aici';

  @override
  String rideBroadcastBubblesOutsideRadiusHint(int km) {
    return 'Există bule active, dar sunt peste $km km față de locația curentă. Verifică pe hartă sau actualizează GPS-ul (trage în jos).';
  }

  @override
  String get rideBroadcastBubblesVisibilityHint =>
      'Bulele sunt vizibile pe hartă cam o oră de la plasare, apoi dispar. Plasează una din meniul hărții. Dacă tocmai ai deschis ecranul, trage în jos pentru sincron.';

  @override
  String get rideBroadcastNoPostedRequestYet => 'Nicio cerere postată încă';

  @override
  String get rideBroadcastNoActiveRequest => 'Nicio cerere activă';

  @override
  String get rideBroadcastBeFirstHint =>
      'Fii primul din cartier care postează o cerere de cursă.';

  @override
  String get rideBroadcastFriendPostedButNotVisibleHint =>
      'Dacă un prieten a postat dar nu vezi: trage în jos pentru reîmprospătare, verifică că îl ai în agendă cu același număr ca în profilul Nabour și că ai permisiune la contacte.';

  @override
  String rideBroadcastNoRequestInRadius(int km) {
    return 'Nicio cerere în raza de $km km';
  }

  @override
  String get rideBroadcastIncludedButFarHint =>
      'Există cereri în care ești inclus, dar sunt mai departe față de locația ta curentă. Te apropii sau pornești locația pentru filtre corecte.';

  @override
  String get rideBroadcastWaitingFriendHint =>
      'Dacă aștepți de la un prieten apropiat, verifică și agendă + profilul Nabour cu același număr.';

  @override
  String get rideBroadcastDeleteMapRequestTitle =>
      'Ștergi cererea de pe hartă?';

  @override
  String get rideBroadcastDeleteMapRequestConfirm =>
      'Bula dispare pentru toți vecinii; acțiunea nu poate fi anulată.';

  @override
  String get rideBroadcastMapBubbleDeleted =>
      'Bula a fost ștearsă de pe hartă.';

  @override
  String rideBroadcastDeleteFailed(String error) {
    return 'Nu s-a putut șterge: $error';
  }

  @override
  String get rideBroadcastDeleteFromMapTooltip => 'Șterge de pe hartă';

  @override
  String rideBroadcastPlaced(String value) {
    return 'Plasată: $value';
  }

  @override
  String rideBroadcastExpiresMapBubble(String value) {
    return 'Expiră: $value (≈1 h după plasare)';
  }

  @override
  String rideBroadcastDistanceFromYou(String km) {
    return 'La ~$km km față de tine';
  }

  @override
  String get rideBroadcastCancelRequestTitle => 'Anulează cererea';

  @override
  String get rideBroadcastCancelRequestConfirm =>
      'Ești sigur că vrei să anulezi această cerere?';

  @override
  String get rideBroadcastNo => 'Nu';

  @override
  String get rideBroadcastYesCancel => 'Da, anulează';

  @override
  String get rideBroadcastPersonalCar => 'Mașină personală';

  @override
  String rideBroadcastOfferSendFailed(String error) {
    return 'Nu s-a putut trimite oferta: $error';
  }

  @override
  String rideBroadcastReplySendFailed(String error) {
    return 'Nu s-a putut trimite răspunsul: $error';
  }

  @override
  String get rideBroadcastDriverFallback => 'Șofer';

  @override
  String get rideBroadcastConfirmRideTitle => 'Confirmă cursa';

  @override
  String get rideBroadcastRideCompletedQuestion => 'Cursa s-a efectuat?';

  @override
  String get rideBroadcastNotCompleted => 'Nu s-a efectuat';

  @override
  String get rideBroadcastCompletedYes => 'Da, s-a efectuat';

  @override
  String get rideBroadcastReasonDriverNoShow => 'Șoferul nu a mai venit';

  @override
  String get rideBroadcastReasonPassengerCancelled => 'Pasagerul a anulat';

  @override
  String get rideBroadcastReasonAnotherCar => 'Altă mașină';

  @override
  String get rideBroadcastReasonOther => 'Alt motiv';

  @override
  String get rideBroadcastReasonTitle => 'Motivul';

  @override
  String rideBroadcastExpiresIn(String value) {
    return 'Expiră în $value';
  }

  @override
  String get rideBroadcastMyRequest => 'Cererea mea';

  @override
  String get rideBroadcastAvailableDrivers => 'Șoferi disponibili';

  @override
  String get rideBroadcastReplies => 'Răspunsuri';

  @override
  String get rideBroadcastReplyHint =>
      'Poți trimite mai multe mesaje - apasă trimitere pentru fiecare';

  @override
  String rideBroadcastOffersOne(int count) {
    return '$count ofertă';
  }

  @override
  String rideBroadcastOffersMany(int count) {
    return '$count oferte';
  }

  @override
  String get rideBroadcastOfferSent => 'Ofertă trimisă';

  @override
  String get rideBroadcastIOffer => 'Mă ofer';

  @override
  String get rideBroadcastStatusDone => '✅ Efectuată';

  @override
  String get rideBroadcastStatusNotDone => '❌ Neefectuată';

  @override
  String get rideBroadcastStatusAccepted => '🤝 Acceptată';

  @override
  String get rideBroadcastStatusCancelled => '🚫 Anulată';

  @override
  String get rideBroadcastStatusActive => '🕐 Activă';

  @override
  String get rideBroadcastStatusExpired => '⏱ Expirată';

  @override
  String rideBroadcastDriverWithName(String name) {
    return 'Șofer: $name';
  }

  @override
  String rideBroadcastReasonWithValue(String value) {
    return 'Motiv: $value';
  }

  @override
  String rideBroadcastTooManyActiveRequests(int max) {
    return 'Ai deja $max cereri active. Închide sau așteaptă expirarea uneia (30 min) înainte de o nouă postare.';
  }

  @override
  String rideBroadcastErrorWithMessage(String error) {
    return 'Eroare: $error';
  }

  @override
  String get rideBroadcastAskRideTitle => 'Cer o cursă';

  @override
  String get rideBroadcastPostVisibilityHint =>
      'Cererea ta va fi vizibilă persoanelor din agenda ta timp de 30 de minute.';

  @override
  String get rideBroadcastQuickSelectOrWrite => 'Selectează rapid sau scrie';

  @override
  String get rideBroadcastYourMessageRequired => 'Mesajul tău *';

  @override
  String get rideBroadcastMessageHint =>
      'Unde vrei să mergi? Orice detaliu util...';

  @override
  String get rideBroadcastDestinationOptional => 'Destinație (opțional)';

  @override
  String get rideBroadcastDestinationHint =>
      'ex: supermarket, stație, aeroport...';

  @override
  String get rideBroadcastPostRequest => 'Postează cererea';

  @override
  String get rideBroadcastExpiresAfterThirtyMinutes =>
      'Cererea expiră automat după 30 de minute.';

  @override
  String get searchDriverFallback => 'Șofer';

  @override
  String get searchDriverSearchingNearby => 'Se caută șoferi în apropiere...';

  @override
  String get searchDriverFoundWaitConfirm =>
      'Șofer găsit! Așteaptă confirmarea ta.';

  @override
  String get searchDriverRideCancelled => 'Cursa a fost anulată.';

  @override
  String get searchDriverNoDriverAvailable =>
      'Ne pare rău, niciun șofer nu a fost disponibil.';

  @override
  String searchDriverUnknownRideStatus(String status) {
    return 'Stare cursă necunoscută: $status';
  }

  @override
  String searchDriverConfirmError(String error) {
    return 'Eroare la confirmarea șoferului: $error';
  }

  @override
  String get searchDriverDeclinedResuming =>
      'Ai refuzat șoferul. Se reia căutarea...';

  @override
  String searchDriverDeclineError(String error) {
    return 'Eroare la refuzarea șoferului: $error';
  }

  @override
  String searchDriverCancelError(String error) {
    return 'Eroare la anulare: $error';
  }

  @override
  String get searchDriverSearchingTitle => 'Se caută șoferi';

  @override
  String get searchDriverPremiumHintTitle => 'Sugestie Premium';

  @override
  String get searchDriverPremiumHintBody =>
      'Rămâi pe ecran pentru o preluare mai rapidă.';

  @override
  String get searchDriverFoundTitle => 'Șofer găsit';

  @override
  String get searchDriverArrivesIn => 'Sosește în';

  @override
  String get searchDriverDistanceLabel => 'Distanță';

  @override
  String get searchDriverNabourDriverFallback => 'Șofer Nabour';

  @override
  String get searchDriverStandardCategory => 'Categoria Standard';

  @override
  String get rideRequestStatusSearching => 'Căutare șoferi';

  @override
  String get rideRequestStatusPending => 'În așteptare';

  @override
  String get rideRequestStatusDriverFound => 'Șofer găsit';

  @override
  String get rideRequestStatusAccepted => 'Acceptată';

  @override
  String get rideRequestStatusDriverArrived => 'Șoferul a ajuns';

  @override
  String get rideRequestStatusInProgress => 'În curs';

  @override
  String get rideRequestStatusDriverRejected => 'Șofer respins';

  @override
  String get rideRequestStatusDriverDeclined => 'Șofer a refuzat';

  @override
  String get rideRequestTimeoutInternet =>
      'A expirat timpul de așteptare. Te rugăm să verifici conexiunea la internet.';

  @override
  String rideRequestRouteCalcError(String error) {
    return 'Eroare la calcularea rutei: $error';
  }

  @override
  String get rideRequestActiveRideDetected => 'Cursă activă detectată';

  @override
  String get rideRequestStatusLabel => 'Status cursă';

  @override
  String get rideRequestIdLabel => 'ID cursă';

  @override
  String get rideRequestCancelPreviousRide => 'Anulează cursa precedentă';

  @override
  String rideRequestCancelPreviousRideError(String error) {
    return 'Eroare la anularea cursei precedente: $error';
  }

  @override
  String rideRequestCreateRideError(String error) {
    return 'Eroare la crearea cursei: $error';
  }

  @override
  String get rideRequestWhereTo => 'Unde mergem?';

  @override
  String get rideRequestChooseRide => 'Alege o cursă';

  @override
  String get rideRequestOrChooseCategory => 'sau alege categoria';

  @override
  String get rideRequestSearchInProgress => 'Căutare în curs...';

  @override
  String get rideRequestConfirmAndRequest => 'Confirmă și solicită cursa';

  @override
  String get rideRequestAnyCategoryAvailable => 'Orice categorie disponibilă';

  @override
  String get rideRequestFastestDriverInArea =>
      'Cel mai rapid șofer disponibil din zonă';

  @override
  String get rideRequestAnyCategorySubtitle =>
      'Cel mai rapid șofer disponibil.';

  @override
  String get rideRequestFamilySubtitle =>
      'Spațiu extra pentru familie și bagaje.';

  @override
  String get rideRequestEnergySubtitle =>
      'Călătorește eco cu o mașină electrică.';

  @override
  String get rideRequestUtilitySubtitle =>
      'Dubă sau utilitar (până la 3.5t). Ideal pentru mutări.';

  @override
  String get rideRequestUserNotAuthenticated =>
      'Eroare: Utilizatorul nu este autentificat.';

  @override
  String get mapArrivalInstruction => 'Ai sosit la destinație!';

  @override
  String get mapArrivedTitle => 'Ai sosit!';

  @override
  String get mapFinalDestinationTitle => 'Destinație finală';

  @override
  String get mapOpenNavigationToDestinationHint =>
      'Deschide în aplicația de navigație spre destinație. Revii apoi la hartă.';

  @override
  String get mapPassengerStatusDriverFound =>
      'Șofer găsit - așteaptă confirmarea ta';

  @override
  String get mapPassengerStatusDriverOnWay => 'Șofer în drum spre tine';

  @override
  String get mapPassengerStatusDriverAtPickup =>
      'Șofer la pickup - deschide navigația spre destinație';

  @override
  String get mapPassengerStatusInProgress => 'Cursă în desfășurare';

  @override
  String mapPassengerStatusGeneric(String status) {
    return 'Cursă: $status';
  }

  @override
  String get mapNavigationToPickupTitle => 'Navigare spre pickup';

  @override
  String get mapExternalNavigationNoRouteHint =>
      'Aplicație de navigație (fără rută în Nabour).';

  @override
  String get mapOpenSameDestinationAsDriver =>
      'Deschide aceeași destinație ca și șoferul în app-ul de navigație.';

  @override
  String get mapLongPressToSetLandmark =>
      'Ține apăsat pe hartă pentru a fixa reperul.';

  @override
  String get mapCloseCancelPlacement => 'Închide (anulează plasarea)';

  @override
  String get mapCommunityMysteryBoxTitle => 'Mystery Box comunitar';

  @override
  String mapCommunityMysteryBoxDescription(int tokens) {
    return 'Plasezi o cutie la locația curentă. Cost: $tokens tokeni. Primul utilizator care o deschide la fața locului primește aceiași tokeni - tu vei primi o notificare când se întâmplă.';
  }

  @override
  String get mapShortMessageOptional => 'Mesaj scurt (opțional)';

  @override
  String get mapShortMessageHint => 'ex: Bonus pe vârf - distracție plăcută!';

  @override
  String get mapPhoneNumberUnavailable => 'Număr de telefon indisponibil';

  @override
  String get neighborFallback => 'Vecin';

  @override
  String mapReactionSent(String reaction) {
    return 'Reacție trimisă: $reaction';
  }

  @override
  String mapHonkedNeighbor(String name) {
    return 'L-ai claxonat pe $name!';
  }

  @override
  String mapEtaMessageToNeighbor(int minutes) {
    return '📍 Vin spre tine! ETA estimat: $minutes min.';
  }

  @override
  String mapEtaSentTo(String name) {
    return 'ETA trimis lui $name';
  }

  @override
  String mapNeighborhoodBubbleContext(String name) {
    return 'Bula apare lângă $name pe hartă. Vizibilă vecinilor ~1 oră.';
  }

  @override
  String mapEmojiPlacedNear(String name) {
    return 'Emoji plasat lângă $name pe hartă';
  }

  @override
  String get mapCannotPlaceEmoji => 'Nu am putut plasa emoji-ul pe hartă';

  @override
  String get mapPersonNotVisibleSendFromList =>
      'Persoana nu e vizibilă pe hartă acum. Poți trimite cerere de prietenie din listă (+).';

  @override
  String get mapContactsVisibilityHint =>
      'Pe hartă apar doar prietenii acceptați sau contactele din telefon care au cont Nabour. Adaugă numerele în agendă sau acceptă o cerere din Sugestii.';

  @override
  String get mapSyncingContacts => 'Sincronizez contactele...';

  @override
  String mapSyncComplete(int count) {
    return 'Sincronizare completă: $count nume găsite.';
  }

  @override
  String get mapEnableDriverProfileHint =>
      'Activează profilul de șofer și adaugă mașina ca să folosești modul șofer.';

  @override
  String mapIntermediateStopAdded(String name) {
    return '$name adăugat ca oprire intermediară';
  }

  @override
  String mapStopRemoved(String name) {
    return '$name eliminat din opriri';
  }

  @override
  String mapNoPoiFoundInArea(String category) {
    return 'Niciun $category găsit în zonă';
  }

  @override
  String mapHonkReceived(String name) {
    return '📣 $name te-a claxonat!';
  }

  @override
  String get mapCalculatingRoute => 'Se calculează traseul...';

  @override
  String get mapCannotGetLocationEnableGps =>
      'Nu am putut obține locația. Activează GPS-ul.';

  @override
  String get mapRouteUnavailableCheckConnection =>
      'Traseu indisponibil. Verifică conexiunea.';

  @override
  String get mapContinueOnRoute => 'Continuă pe traseu.';

  @override
  String get mapAneighbor => 'Un vecin';

  @override
  String mapSosNearbyTitle(String name) {
    return '🆘 SOS PROXIMITATE: $name';
  }

  @override
  String get mapSosNearbyBody =>
      'Urgență activă în apropiere! Verifică radarul pe hartă.';

  @override
  String mapSosTtsAlert(String name) {
    return 'Atenție! ALERTĂ S.O.S. în apropiere de la $name. Radarul de proximitate este activat.';
  }

  @override
  String get mapCriticalZone => 'ZONĂ CRITICĂ';

  @override
  String get mapSosActiveTitle => '🆘 S.O.S. ACTIV';

  @override
  String get mapNoContactsInRadarCircle =>
      'Nimeni din contactele tale cu poziție în zonă nu e în cercul de scanare acum.';

  @override
  String get mapStopNavigationFirst =>
      'Oprește mai întâi navigarea din bannerul de sus.';

  @override
  String get mapWaitingGpsTryAgain =>
      'Așteptăm poziția GPS. Încearcă din nou în câteva secunde.';

  @override
  String get mapGpsLocationUnavailableYet =>
      'Locația GPS nu este disponibilă încă';

  @override
  String mapSetPickupError(String error) {
    return 'Eroare la setarea pickup: $error';
  }

  @override
  String mapSetDestinationError(String error) {
    return 'Eroare la setarea destinației: $error';
  }

  @override
  String mapMaxIntermediateStops(int count) {
    return 'Maximum $count opriri intermediare permise';
  }

  @override
  String get mapStopAlreadyAdded => 'Această oprire este deja adăugată';

  @override
  String mapAddStopError(String error) {
    return 'Eroare la adăugarea opririi: $error';
  }

  @override
  String mapRouteCalculationError(String error) {
    return 'Eroare la calcularea rutei: $error';
  }

  @override
  String mapRouteSetupError(String error) {
    return 'Eroare la configurarea rutei: $error';
  }

  @override
  String get mapCouldNotCalculateRoute => 'Nu s-a putut calcula ruta';

  @override
  String get mapFlashlightUnavailable =>
      'Lanterna nu este disponibilă pe acest dispozitiv';

  @override
  String get mapFlashlightActivationError => 'Eroare la activarea lanternei';

  @override
  String get mapSpotAnnouncedAvailable => 'Locul a fost anunțat disponibil.';

  @override
  String get mapCouldNotAnnounceTryAgain =>
      'Nu s-a putut anunța. Încearcă din nou.';

  @override
  String get mapSelectionCancelled => 'Selecția pe hartă a fost anulată.';

  @override
  String mapNeighborNearbyTitle(String avatar, String name) {
    return '$avatar $name e aproape!';
  }

  @override
  String mapNeighborNearbyBody(int meters) {
    return 'La $meters m - harta socială 📍';
  }

  @override
  String mapPickupIndex(int index) {
    return 'Pickup $index';
  }

  @override
  String get mapPickupPointSelected => 'Punct de preluare selectat';

  @override
  String get helpChatGuideTitle => 'Ghid utilizare Chat Cartier';

  @override
  String get helpChatGuideIntro =>
      'Chat-ul de cartier este conceput să te conecteze instantaneu cu vecinii aflați în proximitatea ta.';

  @override
  String get helpChatWhoSeesTitle => 'Cine vede mesajele?';

  @override
  String get helpChatWhoSeesBody =>
      'Mesajele trimise sunt vizibile pentru toți utilizatorii care se află în aceeași zonă geografică cu tine în momentul utilizării.';

  @override
  String get helpChatCoverageTitle => 'Raza și Aria de acoperire';

  @override
  String get helpChatCoverageBody =>
      'Sistemul împarte orașul în hexagoane cu latura de aproximativ 3.2 km (o suprafață de circa 36 km²). Este o zonă vastă, ideală pentru a acoperi un cartier întreg sau un sector.';

  @override
  String get helpChatPersistenceTitle => 'Persistența mesajelor';

  @override
  String get helpChatPersistenceBody =>
      'Pentru a păstra conversațiile proaspete și relevante, mesajele dispar automat după 30 de minute. Nu există un istoric permanent, chat-ul fiind destinat interacțiunilor imediate.';

  @override
  String get helpChatPrivacyTitle => 'Confidențialitate și Siguranță';

  @override
  String get helpChatPrivacyBody =>
      'Accesul la chat este validat pe baza locației tale GPS actuale. Dacă te muți într-o altă parte a orașului, aplicația te va conecta automat la chat-ul specific acelei zone.';

  @override
  String get helpChatTipOMW =>
      'Sfat: Folosește butonul OMW pentru a anunța rapid vecinii că ești în drum spre ei sau ești disponibil în zonă.';

  @override
  String get helpLassoTitle => 'Instrumentul Lasso (Bagheta Magică)';

  @override
  String get helpLassoBody =>
      'Instrumentul Lasso îți permite să selectezi mai mulți vecini de pe hartă dintr-o singură mișcare, prin încercuirea lor.';

  @override
  String get helpLassoHowToTitle => 'Cum se folosește?';

  @override
  String get helpLassoHowToBody =>
      '1. Apasă pe pictograma \"Baghetă Magică\" din colțul dreapta-sus al hărții.\n2. Desenează un cerc cu degetul în jurul vecinilor pe care vrei să îi contactezi.\n3. Se va deschide un meniu cu grupul capturat și opțiuni pentru a le trimite o cerere de tip \"Broadcast\".';

  @override
  String get helpLassoTip =>
      'Sfat: Folosește Lasso pentru a găsi rapid o echipă de vecini pentru o activitate comună sau o cerere de transport partajat!';

  @override
  String get helpRadarTitle => 'Butonul Scanează (radar vecini)';

  @override
  String get helpRadarBody =>
      'Butonul Scanează pornește scanarea în overlay-ul radar timp de aproximativ 5 secunde, apoi se închide automat. În acest interval nu poți redimensiona cercul.';

  @override
  String get helpRadarWhatTitle => 'Ce „scanează”?';

  @override
  String get helpRadarWhatBody =>
      'Nu este scanare Bluetooth, Wi‑Fi sau de dispozitive noi. Aplicația listează vecinii care sunt deja afișați pe hartă și se află în interiorul cercului radar (distanța se calculează față de centrul și raza cercului).';

  @override
  String get helpRadarResultsTitle => 'Unde apar rezultatele?';

  @override
  String get helpRadarResultsBody =>
      'Dacă există cel puțin un vecin în cerc, se deschide o foaie de jos cu lista. Dacă nu e nimeni, vei vedea un mesaj scurt că nu s-a găsit niciun vecin în radar.';

  @override
  String get helpRadarNextTitle => 'Ce poți face după?';

  @override
  String get helpRadarNextBody =>
      'Din foaia de jos poți folosi acțiunea de grup (ex. cerere broadcast) când funcția este complet activă; până atunci aplicația poate afișa un mesaj că este în curs de activare.';

  @override
  String get helpRadarTip =>
      'Sfat: Mută sau mărește cercul înainte de Scanează, ca să acoperi zona care te interesează—în rezultate pot apărea doar vecinii deja vizibili pe hartă.';

  @override
  String get helpMapDropsTitle => 'Interactive Map Drops (Locații în Chat)';

  @override
  String get helpMapDropsBody =>
      'Map Drops sunt marcaje de locație partajate în chat-ul de cartier, care îți permit să călătorești instantaneu pe hartă.';

  @override
  String get helpMapDropsFlyTitle => 'Animația Cinematică \"FlyTo\"';

  @override
  String get helpMapDropsFlyBody =>
      'Atunci când un vecin partajează o locație, apasă pe cardul interactiv din chat. Aplicația va închide chat-ul și va executa un zbor cinematic direct către acel punct exact pe hartă.';

  @override
  String get helpMapDropsPinsTitle => 'Pini Temporari';

  @override
  String get helpMapDropsPinsBody =>
      'După finalizarea zborului, vei vedea un pin pulsatoriu pe hartă. Acesta te ajută să identifici exact locul unde a fost făcut \"drop-ul\", oferind context vizual precis pentru mesajul vecinului.';

  @override
  String get helpBoxesPurposeTitle => 'La ce servesc';

  @override
  String get helpBoxesPurposeBody =>
      'Pe hartă există două tipuri de cutii legate de tokenii Nabour: (1) cutii la oferte business — comerciantul poate seta un plafon opțional; le deschizi lângă magazin și primești tokeni plus un cod de reducere la acel magazin. (2) cutii comunitare — orice utilizator poate plasa o cutie la locația sa curentă; altcineva o deschide la fața locului și primește tokeni; plasatorul este informat când cutia e deschisă.';

  @override
  String get helpBoxesTokensTitle => 'Tokeni — cum se colectează și cheltuiesc';

  @override
  String get helpBoxesTokensBody =>
      '• Plasare cutie comunitară: 50 de tokeni sunt reținuți prin server (garanție) și apar în istoricul portofelului.\n• Deschidere cutie comunitară (alt utilizator, la aprox. 100 m): primești 50 de tokeni; cutia este marcată deschisă.\n• Deschidere cutie la ofertă business: primești 50 de tokeni și un cod de reducere, cu respectarea regulii o deschidere pe zi per magazin și a plafonului setat de comerciant.\n• Dacă politica serverului blochează creditarea până la integrarea plăților, deschiderea poate eșua cu mesajul corespunzător.';

  @override
  String get helpBoxesCommunityStepsTitle => 'Cutii comunitare — pașii';

  @override
  String get helpBoxesCommunityStepsBody =>
      '1) De pe hartă, plasezi o cutie la poziția curentă (ai nevoie de tokeni suficienți). Limită: până la 20 de cutii active per cont.\n2) Utilizatorii din apropiere văd cutiile pe hartă; propriile tale cutii nu îți apar ca să le deschizi tu.\n3) Apeși pe cutie, te apropii (aprox. 100 m), confirmi — serverul verifică distanța și identitatea.\n4) Plasatorul primește înregistrare în notificări și o notificare push când cineva deschide cutia.\n5) Din meniu → „Activitate cutii” vezi rezumatul, cutiile plasate, deschiderile tale și deschiderile la cutiile tale.';

  @override
  String get helpBoxesBusinessStepsTitle =>
      'Cutii la oferte business — utilizator și comerciant';

  @override
  String get helpBoxesBusinessStepsBody =>
      'Comerciantul publică o ofertă și poate atașa un plafon de cutii (cost suplimentar în tokeni la publicare sau la mărirea plafonului). Deschizi cutia de pe hartă, lângă locație; primești tokeni și un cod de reducere. În magazin, comerciantul deschide panoul business și folosește „Validează cod” astfel încât codul să fie marcat folosit. Codurile sunt păstrate securizat; doar funcțiile cloud le creează sau validează.';

  @override
  String get helpBoxesActivityScreenTitle =>
      'Ecranul „Activitate cutii” (meniu)';

  @override
  String get helpBoxesActivityScreenBody =>
      'File: Rezumat (estimări tokeni din deschideri și din plasări), Plasate (comunitate), Deschise de tine (comunitate + business), Deschideri la cutiile tale (notificări). Codurile de reducere sunt afișate parțial mascate.';

  @override
  String get helpBoxesPrivacyRulesTitle => 'Confidențialitate și reguli';

  @override
  String get helpBoxesPrivacyRulesBody =>
      'Operațiile sensibile (coduri de reducere, deschideri) se fac pe server. Regulile Firestore împiedică falsificarea din aplicație; citirile respectă autentificarea.';

  @override
  String get helpBoxesWhoTitle => 'Cine ce face';

  @override
  String get helpBoxesWhoBody =>
      '• Orice utilizator: hartă, plasare cutii comunitare dacă are tokeni, deschidere cutii când distanța și regulile permit, meniul „Activitate cutii”.\n• Plasator: primește notificări la deschiderea cutiilor comunitare.\n• Comerciant: configurează certificatele și plafoanele, validează codurile după ce clientul a deschis cutia.';

  @override
  String get helpBoxesNotesTitle => 'Note';

  @override
  String get helpBoxesNotesBody =>
      'Listarea cutiilor din jur este potrivită pentru volum moderat; la scară foarte mare poate fi nevoie de indexare geografică mai strictă. Expirarea sau returnarea automată a garanției dacă nimeni nu deschide o cutie comunitară nu este inclusă aici și poate fi adăugată ulterior.';

  @override
  String get helpBoxesTip =>
      'Sfat: Dacă deschiderea eșuează, verifică precizia GPS, conexiunea, soldul tokenilor și dacă creditarea este activă pe server în mediul tău.';

  @override
  String get helpTransfersP2PTitle => 'Transfer de tokeni între utilizatori';

  @override
  String get helpTransfersP2PAboutTitle => 'Despre funcție';

  @override
  String get helpTransfersP2PAboutBody =>
      'Din meniul lateral, deschide „Transfer tokeni” pentru a trimite tokeni Nabour către alt cont sau pentru a cere cuiva să îți trimită tokeni. Soldurile și înregistrările din jurnal sunt actualizate pe server; ai nevoie de ID-ul de utilizator al celeilalte persoane (UID Firebase).';

  @override
  String get helpTransfersP2PWalletTitle => 'Portofel transferabil';

  @override
  String get helpTransfersP2PWalletBody =>
      'Acest ecran arată soldul de tokeni transferabili (nu este același indicator ca bara de utilizare lunară din partea de sus a meniului). Dacă portofelul lipsește sau este înghețat, transferurile și cererile sunt blocate până când contul este eligibil.';

  @override
  String get helpTransfersP2PDirectTitle => 'Transfer direct';

  @override
  String get helpTransfersP2PDirectBody =>
      'Trimite tokeni imediat către ID-ul destinatarului. Nu poți transfera către propriul cont. Suma trebuie să fie un număr întreg de tokeni, în intervalul permis. Poți adăuga o notă opțională.';

  @override
  String get helpTransfersP2PRequestTitle => 'Cerere de plată';

  @override
  String get helpTransfersP2PRequestBody =>
      'Ceri altui utilizator (plătitorul) să îți trimită tokeni. Acesta primește o cerere în așteptare și poate accepta sau refuza. La acceptare, tokenii se mută din portofelul său transferabil în al tău. Cererile pot expira dacă nu primesc răspuns la timp.';

  @override
  String get helpTransfersP2PRequestsTabTitle => 'Filă „Cereri”';

  @override
  String get helpTransfersP2PRequestsTabBody =>
      '• Ca plătitor: poți accepta sau refuza cererile primite; la refuz poți adăuga un motiv opțional.\n• Ca inițiator al cererii: poți anula o cerere creată de tine cât timp este în așteptare.';

  @override
  String get helpTransfersP2PHistoryTabTitle => 'Filă „Istoric”';

  @override
  String get helpTransfersP2PHistoryTabBody =>
      'Afișează transferurile directe recente și cererile de plată rezolvate. Trage în jos pentru reîmprospătare.';

  @override
  String get helpTransfersP2PTip =>
      'Distribuie ID-ul de utilizator doar persoanelor în care ai încredere. Verifică din nou ID-ul înainte de a confirma un transfer sau o cerere.';

  @override
  String get helpDriverActivationStepCheckConditions =>
      '1. Verifică condițiile';

  @override
  String get helpDriverActivationStepCheckConditionsBody =>
      'Trebuie să ai permis de conducere valabil, experiență de minim 2 ani și vârsta de minim 21 de ani.';

  @override
  String get helpDriverActivationStepPrepareDocs => '2. Pregătește documentele';

  @override
  String get helpDriverActivationStepPrepareDocsBody =>
      'Ai nevoie de: permis de conducere, carte de identitate, certificat de înmatriculare auto, ITP valabil și asigurarea RCA.';

  @override
  String get helpDriverActivationStepCompleteApp => '3. Completează aplicația';

  @override
  String get helpDriverActivationStepCompleteAppBody =>
      'Accesează secțiunea \"Carieră\" din meniul principal și completează formularul online cu datele tale.';

  @override
  String get helpDriverActivationStepSubmitDocs => '4. Transmite documentele';

  @override
  String get helpDriverActivationStepSubmitDocsBody =>
      'Încarcă fotografii clare cu toate documentele necesare prin platforma online.';

  @override
  String get helpDriverActivationStepVerification =>
      '5. Verificarea aplicației';

  @override
  String get helpDriverActivationStepVerificationBody =>
      'Echipa noastră va verifica documentele în maxim 48 de ore lucrătoare.';

  @override
  String get helpDriverActivationStepReceiveCode =>
      '6. Primește codul de activare';

  @override
  String get helpDriverActivationStepReceiveCodeBody =>
      'După aprobare, vei primi un cod unic prin email/SMS pentru activarea contului de șofer.';

  @override
  String get helpDriverActivationStepActivateAccount => '7. Activează contul';

  @override
  String get helpDriverActivationStepActivateAccountBody =>
      'Introdu codul în aplicație și începe să câștigi bani conducând!';

  @override
  String get helpDriverActivationTipHeader => '💡 Sfat util:';

  @override
  String get helpDriverActivationTipBody =>
      'Asigură-te că toate documentele sunt valabile și fotografiile sunt clare pentru o procesare rapidă.';

  @override
  String get helpSearchHint => 'Caută în articole...';

  @override
  String get helpCategoryRideIssues => 'Probleme de cursă';

  @override
  String get helpCategorySafetySOS => 'Siguranță & SOS';

  @override
  String get helpCategoryNabourFeatures => 'Funcții Nabour';

  @override
  String get helpCategoryPaymentsWallet => 'Plăți & Portofel';

  @override
  String get helpCategorySettingsAccount => 'Setări & Cont';

  @override
  String get helpStillNeedHelp => 'Ai nevoie de ajutor?';

  @override
  String get helpContactSupport => 'Contactează echipa de suport';

  @override
  String get helpContactButton => 'Contactează';

  @override
  String get helpRideSharingTitle => 'Curse Partajate';

  @override
  String get chatGalleryPhoto => 'Fotografie din galerie';

  @override
  String get chatGif => 'GIF';

  @override
  String get driverHoursLimit => 'Limită ore condus';

  @override
  String driverHoursWarningBody(String hours, String remaining) {
    return 'Ai condus $hours ore astăzi.\nMai ai $remaining ore disponibile.\n\nConsideră o pauză pentru siguranța ta și a pasagerilor.';
  }

  @override
  String get goOffline => 'Ieși offline';

  @override
  String get driverHoursReachedLimitTitle => 'Limită de 10 ore atinsă';

  @override
  String get driverHoursReachedLimitBody =>
      'Ai condus 10 ore consecutive.\nDin motive de siguranță ai fost deconectat automat.\n\nTe poți reconecta după o perioadă de odihnă.';

  @override
  String ridesCompletedToday(int count) {
    return '$count curse finalizate azi.';
  }

  @override
  String viewAllRides(int count) {
    return 'Vezi toate cele $count curse';
  }

  @override
  String get driverSessionBannerCritical =>
      'Limită de 10 ore atinsă. Te rog ieși offline.';

  @override
  String driverSessionBannerWarning(String hours, String remaining) {
    return 'Sesiune: ${hours}h • Rămân ${remaining}h';
  }

  @override
  String driverSessionBannerNormal(String hours) {
    return 'Sesiune: ${hours}h';
  }

  @override
  String get helpToday => 'Ajutor Azi';

  @override
  String get tokens => 'Tokeni';

  @override
  String get rideSummary_thankYouGoodbye => 'Vă mulțumim și la revedere!';

  @override
  String rideSummary_tipRegistered(String amount, String currency) {
    return 'Bacșișul de $amount $currency a fost înregistrat.';
  }

  @override
  String rideSummary_redirectToMapInSeconds(String seconds) {
    return 'Te redirecționăm la hartă în $seconds secunde...';
  }

  @override
  String get rideSummary_submitRatingButton => 'Trimite Evaluarea';

  @override
  String get rideSummary_skipRatingButton => 'Omite evaluarea';

  @override
  String get rideSummary_ratingSentSuccess =>
      'Evaluarea a fost trimisă cu succes!';

  @override
  String get rideSummary_backToMap => 'Înapoi la hartă';

  @override
  String get rideSummary_rideDetails => 'Detalii Cursă';

  @override
  String get rideSummary_distance => 'Distanța';

  @override
  String get rideSummary_duration => 'Durata';

  @override
  String get rideSummary_rideCost => 'Cost Cursă';

  @override
  String get rideSummary_freeRideSupport => 'Gratuit - Sprijin Vecini';

  @override
  String get rideSummary_driverTipOptional =>
      '💰 Bacșiș pentru șofer (opțional)';

  @override
  String get rideSummary_thankDriverTipText =>
      'Mulțumește șoferului pentru o călătorie plăcută!';

  @override
  String rideSummary_otherAmountLabel(String currency) {
    return 'Altă sumă ($currency)';
  }

  @override
  String get rideSummary_noTipButton => 'Fără bacșiș';

  @override
  String rideSummary_tipSelected(String amount, String currency) {
    return 'Bacșiș selectat: $amount $currency';
  }

  @override
  String get safety_sosButtonLabel => '112 — SOS';

  @override
  String get safety_locationUnavailable => '(locație indisponibilă)';

  @override
  String get safety_defaultNabourUser => 'Utilizator Nabour';

  @override
  String safety_emergencySmsBody(String name, String location) {
    return '🆘 URGENȚĂ! $name are nevoie de ajutor!\nLocație: $location\nApăsați linkul pentru a vedea pe hartă.';
  }

  @override
  String get safety_emergencyAlertSent =>
      '🆘 Alertă de urgență trimisă. Se apelează 112...';

  @override
  String safety_shareTripBody(String location) {
    return '📍 Urmăresc călătoria mea cu Nabour!\nLocația mea curentă: $location';
  }

  @override
  String get safety_shareTripNoLocation =>
      '🚗 Călătoresc cu Nabour. Locația nu este disponibilă momentan.';

  @override
  String get safety_couldNotCreateTrackingLink =>
      'Nu s-a putut crea link-ul de urmărire';

  @override
  String get safety_deleteContactTitle => 'Șterge contact';

  @override
  String safety_deleteContactConfirmation(String name) {
    return 'Ștergi \"$name\" din contactele de încredere?';
  }

  @override
  String get safety_emergencyButtonTitle => 'Buton de urgență';

  @override
  String get safety_emergencyButtonSubtitle =>
      'Apelează 112 și trimite locația ta\ntuturor contactelor de încredere';

  @override
  String get safety_shareTripTitle => 'Partajează călătoria';

  @override
  String get safety_activeRideDetected => 'Cursă activă detectată';

  @override
  String get safety_sendCurrentLocation => 'Trimite locația ta curentă';

  @override
  String get safety_gettingLocation => 'Se obține locația...';

  @override
  String get safety_shareLocationButton => 'Partajează locația';

  @override
  String get safety_liveLinkActive => 'Link live activ — reîmpartășește';

  @override
  String get safety_safeRideSharePath => 'Safe Ride Live — partajează traseu';

  @override
  String get safety_noContactsAdded => 'Niciun contact adăugat';

  @override
  String get safety_addContactsDescription =>
      'Adaugă familia sau prietenii. Ei vor primi\nlocația ta în caz de urgență.';

  @override
  String get rideSummary_totalCost => 'Cost Total';

  @override
  String safety_destinationLabelPrefix(String destination) {
    return 'Destinație: $destination';
  }
}

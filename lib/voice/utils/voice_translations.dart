import 'package:shared_preferences/shared_preferences.dart';
import 'package:nabour_app/utils/logger.dart';

/// ✅ Helper pentru traduceri în modulul AI vocal (fără BuildContext)
class VoiceTranslations {
  static Future<String> _getCurrentLanguageCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString('locale');
      return code ?? 'ro'; // Default română
    } catch (e) {
      Logger.error('Error getting language: $e', tag: 'VOICE_TRANSLATIONS', error: e);
      return 'ro'; // Default română
    }
  }
  
  /// Obține mesajul de salut
  static Future<String> getGreeting() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en' ? 'Hello, where would you like to go?' : 'Salut, unde doriți să mergeți?';
  }
  
  /// Obține mesajul "Caut șoferi disponibili..."
  static Future<String> getSearchingDrivers() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en' ? 'Searching for available drivers...' : 'Caut șoferi disponibili...';
  }
  
  /// Obține mesajul "Caut șoferi disponibili în zonă..."
  static Future<String> getSearchingDriversInArea() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en' ? 'Searching for available drivers in your area...' : 'Caut șoferi disponibili în zonă...';
  }
  
  /// Obține mesajul "Am găsit un șofer disponibil la X minute distanță"
  static Future<String> getDriverFound(int minutes) async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en' 
        ? 'Found an available driver $minutes minutes away.'
        : 'Am găsit un șofer disponibil la $minutes minute distanță.';
  }

  /// Obține mesajul "Am găsit un șofer disponibil: $driverName"
  static Future<String> getDriverFoundSimple(String driverName, String carInfo) async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en' 
        ? 'Found a driver: $driverName with $carInfo.'
        : 'Veste excelentă! Am găsit un șofer disponibil: $driverName cu $carInfo.';
  }
  
  /// Obține mesajul "Nu am găsit șoferi disponibili"
  static Future<String> getNoDriversAvailable() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en'
        ? 'Sorry, but I couldn\'t find any available drivers in your area. Please try again later.'
        : 'Îmi pare rău, dar nu am găsit șoferi disponibili în zona dumneavoastră. Te rugăm să revii mai târziu.';
  }
  
  /// Obține mesajul "Perfect! Am rezolvat totul..."
  static Future<String> getEverythingResolved(String driverName, int etaMinutes) async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en'
        ? 'Perfect! I\'ve resolved everything. $driverName is arriving in $etaMinutes minutes. Thank you for using Nabour!'
        : 'Perfect! Am rezolvat totul. $driverName vine în $etaMinutes minute. Vă mulțumim că ați folosit Nabour!';
  }
  
  /// Obține mesajul "Perfect! Șoferul a fost notificat..."
  static Future<String> getDriverNotified() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en'
        ? 'Perfect! The driver has been notified. Have a pleasant trip!'
        : 'Perfect! Șoferul a fost notificat. Călătorie plăcută!';
  }
  
  /// Obține mesajul "Îmi pare rău, nu am putut găsi adresa..."
  static Future<String> getAddressNotFound(String address) async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en'
        ? 'Sorry, I couldn\'t find the address "$address". Please specify a clearer address or a known location.'
        : 'Îmi pare rău, nu am putut găsi adresa "$address". Vă rog să specificați o adresă mai clară sau un loc cunoscut.';
  }
  
  /// Obține mesajul "Perfect! Completez adresele..."
  static Future<String> getCompletingAddresses() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en'
        ? 'Perfect! I\'m completing the addresses and sending the request to drivers.'
        : 'Perfect! Completez adresele și trimit solicitarea către șoferi.';
  }
  
  /// Obține mesajul "Perfect! Am înțeles destinația..."
  static Future<String> getDestinationUnderstood() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en'
        ? 'Perfect! I understood the destination. I\'m processing everything automatically - detecting location, searching for drivers and making the reservation.'
        : 'Perfect! Am înțeles destinația. Procesez totul automat - detectez locația, caut șoferi și fac rezervarea.';
  }
  
  /// Obține mesajul "Vă rog să îmi spuneți unde doriți să mergeți"
  static Future<String> getPleaseSpecifyDestination() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en'
        ? 'Please tell me where you would like to go.'
        : 'Vă rog să îmi spuneți unde doriți să mergeți.';
  }
  
  /// Obține mesajul "Nu am înțeles. Puteți să repetați destinația?"
  static Future<String> getDidNotUnderstandRepeatDestination() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en'
        ? 'I didn\'t understand. Can you repeat the destination?'
        : 'Nu am înțeles. Puteți să repetați destinația?';
  }

  /// Răspunsuri scurte, fluente (conversație naturală, scop: cursă)
  static Future<String> getFluentGreeting() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en' ? 'Hi! Where do you want to go?' : 'Salut! Unde vrei să mergi?';
  }
  static Future<String> getFluentSmallTalk() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en' ? 'Anytime! Where do you want to go?' : 'Cu plăcere! Unde vrei să mergi?';
  }
  static Future<String> getFluentHelp() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en' ? 'I help you book a ride. Where do you want to go?' : 'Te ajut să comanzi o cursă. Unde vrei să mergi?';
  }
  static Future<String> getFluentAppInfo() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en' ? 'I\'m the Nabour assistant. Where do you want to go?' : 'Sunt asistentul Nabour. Unde vrei să mergi?';
  }
  static Future<String> getFluentUnknown() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en' ? 'Let me help you with a ride. Where are we going?' : 'Hai să te ajut cu o cursă. Unde mergem?';
  }
  static Future<String> getFluentStatus() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en' ? 'Checking. Where do you want to go?' : 'Verific. Unde vrei să mergi?';
  }
  static Future<String> getFluentPayment() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en' ? 'You can pay cash or card. Where do you want to go?' : 'Poți plăti cash sau card. Unde vrei să mergi?';
  }
  static Future<String> getFluentReject() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en' ? 'No problem. Where do you want to go?' : 'Ok. Unde vrei să mergi?';
  }
  
  /// Obține mesajul "Înțeleg că nu confirmați..."
  static Future<String> getNotConfirmedPleaseSpecify() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en'
        ? 'I understand you don\'t confirm. Please specify again where you would like to go.'
        : 'Înțeleg că nu confirmați. Vă rog să specificați din nou unde doriți să mergeți.';
  }
  
  /// Obține mesajul pentru confirmare
  static Future<String> getConfirmationMessage(String? languageCode) async {
    final lang = languageCode ?? await _getCurrentLanguageCode();
    return lang == 'en'
        ? 'Perfect! I understood the confirmation. Continuing with driver search...'
        : 'Perfect! Am înțeles confirmarea. Continuă cu căutarea șoferilor...';
  }
  
  /// Obține mesajul pentru clarificare
  static Future<String> getClarificationQuestion([String? languageCode]) async {
    final lang = languageCode ?? await _getCurrentLanguageCode();
    return lang == 'en'
        ? 'I didn\'t understand the response. Please answer "yes" to continue or "no" to specify the destination again.'
        : 'Nu am înțeles răspunsul. Vă rog să răspundeți cu "da" pentru a continua sau "nu" pentru a specifica din nou destinația.';
  }
  
  /// Obține mesajul "Excelent! Trimit solicitarea către șoferi..."
  static Future<String> getSendingRequestToDrivers() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en'
        ? 'Excellent! Sending the request to drivers...'
        : 'Excelent! Trimit solicitarea către șoferi...';
  }
  
  /// Obține mesajul "Excelent! Solicitarea a fost trimisă..."
  static Future<String> getRequestSentToDrivers() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en'
        ? 'Excellent! The request has been sent to drivers. We are waiting for a response...'
        : 'Excelent! Solicitarea a fost trimisă către șoferi. Așteptăm răspunsul...';
  }
  
  /// Obține mesajul pentru prețul cursei (gratuit în Nabour)
  static Future<String> getRidePrice() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en'
        ? 'Rides in Nabour are free community services.'
        : 'Cursele în Nabour sunt gratuite, oferite de vecini pentru vecini.';
  }
  
  /// Obține mesajul "Cursa a început. Călătorie plăcută!"
  static Future<String> getRideStartedEnjoyTrip() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en'
        ? 'The ride has started. Have a pleasant trip!'
        : 'Cursa a început. Călătorie plăcută!';
  }

  /// Obține mesajul "Șoferul este în drum spre tine."
  static Future<String> getDriverEnRoute() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en'
        ? 'The driver is on the way to your location.'
        : 'Șoferul este în drum spre locația ta.';
  }

  /// Obține mesajul "Șoferul a ajuns la locul de preluare."
  static Future<String> getDriverArrived() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en'
        ? 'The driver has arrived at the pickup location.'
        : 'Șoferul a ajuns la locul de preluare.';
  }

  /// Obține mesajul "Cursa s-a încheiat cu succes."
  static Future<String> getRideCompleted() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en'
        ? 'The trip has been successfully completed. Thank you for using Nabour!'
        : 'Călătoria s-a încheiat cu succes. Vă mulțumim că ați folosit Nabour!';
  }
  
  /// Obține mesajul pentru șofer acceptat
  static Future<String> getDriverAcceptedMessage(String driverName, String car, String carColor, String plate, int eta) async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en'
        ? 'Excellent news! $driverName with $car $carColor $plate has accepted the ride and will arrive in approximately $eta minutes.'
        : 'Veste excelentă! $driverName cu $car $carColor $plate a acceptat cursa și va ajunge în aproximativ $eta minute.';
  }
  
  /// Obține mesajul "Detectez locația curentă..."
  static Future<String> getDetectingCurrentLocation() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en'
        ? 'Detecting your current location...'
        : 'Detectez locația curentă...';
  }
  
  /// Obține mesajul "Pregătesc cursa..."
  static Future<String> getCalculatingPrice() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en'
        ? 'Preparing the ride details...'
        : 'Pregătesc detaliile cursei...';
  }
  
  /// Obține mesajul "Verific adresa destinației..."
  static Future<String> getVerifyingDestination() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en'
        ? 'Verifying the destination address...'
        : 'Verific adresa destinației...';
  }
  
  /// Obține mesajul "Procesez informațiile..."
  static Future<String> getProcessingInformation() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en'
        ? 'Processing the information...'
        : 'Procesez informațiile...';
  }
  
  /// Obține mesajul pentru confirmarea destinației
  static Future<String> getDestinationWithPrice(String destination) async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en'
        ? 'I understand! You want to go to $destination. Do you confirm?'
        : 'Am înțeles! Doriți să mergeți la $destination. Confirmați?';
  }
  
  /// Obține mesajul pentru confirmarea pickup-ului
  static Future<String> getPickupConfirmation(String pickup) async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en'
        ? 'Perfect! I understood that pickup is from $pickup. Searching for available drivers...'
        : 'Perfect! Am înțeles că preluarea se face de la $pickup. Caut șoferi disponibili...';
  }
  
  /// Obține mesajul pentru confirmarea generală
  static Future<String> getGeneralConfirmation() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en'
        ? 'Perfect! I understood the confirmation. Continuing with driver search...'
        : 'Perfect! Am înțeles confirmarea. Continuă cu căutarea șoferilor...';
  }
  
  /// Obține mesajul pentru confirmarea finală a cursei
  static Future<String> getFinalRideConfirmation() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en'
        ? 'Perfect! Sending the request to drivers...'
        : 'Perfect! Trimit cererea către șoferi...';
  }
  
  /// Obține mesajul pentru eroare "Nu am putut..."
  static Future<String> getErrorCouldNot(String action) async {
    final lang = await _getCurrentLanguageCode();
    final actionEn = lang == 'en' ? action : action; // Poate fi tradus mai târziu
    return lang == 'en'
        ? 'I couldn\'t $actionEn. Please try again.'
        : 'Nu am putut $action. Vă rugăm să încercați din nou.';
  }
  
  /// Obține mesajul pentru eroare "Nu am putut găsi șoferi"
  static Future<String> getErrorCouldNotFindDrivers() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en'
        ? 'I couldn\'t find available drivers at this time. We will try again immediately.'
        : 'Nu am putut găsi șoferi disponibili în acest moment. Încercăm din nou imediat.';
  }

  // ─── Active Ride Voice Commands ───────────────────────────────────────────

  /// Comanda vocală "sună șoferul" / "call driver"
  static Future<String> getCallDriverCommand() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en' ? 'call driver' : 'sună șoferul';
  }

  /// Comanda vocală "anulează cursa" / "cancel ride"
  static Future<String> getCancelRideCommand() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en' ? 'cancel ride' : 'anulează cursa';
  }

  /// Comanda vocală "trimite locația" / "share location"
  static Future<String> getShareLocationCommand() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en' ? 'share location' : 'trimite locația';
  }

  /// Confirmare TTS după recunoașterea comenzii "sună șoferul"
  static Future<String> getCallingDriverConfirmation() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en' ? 'Calling driver...' : 'Apelăm șoferul...';
  }

  /// Confirmare TTS după recunoașterea comenzii "anulează cursa"
  static Future<String> getCancelRideConfirmation() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en' ? 'Opening cancellation dialog...' : 'Deschid dialogul de anulare...';
  }

  /// Confirmare TTS după recunoașterea comenzii "trimite locația"
  static Future<String> getSharingLocationConfirmation() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en' ? 'Sharing your location...' : 'Partajăm locația ta...';
  }

  /// Mesaj scurt pentru comenzile vocale în timpul cursei (UI pe hartă).
  static Future<String> getActiveRideVoiceHint() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en'
        ? 'Say: "call driver", "cancel ride" or "share location"'
        : 'Spuneți: "sună șoferul", "anulează cursa" sau "trimite locația"';
  }

  /// Titlul panoului de comenzi vocale
  static Future<String> getVoiceCommandTitle() async {
    final lang = await _getCurrentLanguageCode();
    return lang == 'en' ? 'Voice Commands' : 'Comenzi vocale';
  }

  /// Mesajul de fallback când asistentul vocal nu înțelege
  static String getVoiceFallbackMessage({String languageCode = 'ro'}) {
    return languageCode == 'en'
        ? 'Voice assistant could not understand. Use manual input.'
        : 'Asistentul vocal nu a putut înțelege. Folosiți introducerea manuală.';
  }

  /// Eticheta câmpului de input manual
  static String getManualInputLabel({String languageCode = 'ro'}) {
    return languageCode == 'en' ? 'Type your command...' : 'Scrieți comanda...';
  }

  /// Butonul de trimitere manual
  static String getManualInputSendButton({String languageCode = 'ro'}) {
    return languageCode == 'en' ? 'Send' : 'Trimite';
  }

  /// Butonul de reîncercare a asistentului vocal
  static String getRetryVoiceButton({String languageCode = 'ro'}) {
    return languageCode == 'en' ? 'Retry voice' : 'Reîncearcă vocal';
  }

  /// Verifică dacă textul recunoscut conține comanda "sună șoferul"
  static bool matchesCallDriver(String text, {String languageCode = 'ro'}) {
    final lower = text.toLowerCase().trim();
    if (languageCode == 'en') {
      return lower.contains('call driver') || lower.contains('call the driver') || lower.contains('phone driver');
    }
    return lower.contains('sună șoferul') ||
        lower.contains('suna soferul') ||
        lower.contains('sună soferul') ||
        lower.contains('apelează șoferul') ||
        lower.contains('apeleaza soferul');
  }

  /// Verifică dacă textul recunoscut conține comanda "anulează cursa"
  static bool matchesCancelRide(String text, {String languageCode = 'ro'}) {
    final lower = text.toLowerCase().trim();
    if (languageCode == 'en') {
      return lower.contains('cancel ride') || lower.contains('cancel the ride') || lower.contains('cancel trip');
    }
    return lower.contains('anulează cursa') ||
        lower.contains('anuleaza cursa') ||
        lower.contains('anulare cursă') ||
        lower.contains('anulare cursa');
  }

  /// Verifică dacă textul recunoscut conține comanda "trimite locația"
  static bool matchesShareLocation(String text, {String languageCode = 'ro'}) {
    final lower = text.toLowerCase().trim();
    if (languageCode == 'en') {
      return lower.contains('share location') || lower.contains('send location') || lower.contains('share my location');
    }
    return lower.contains('trimite locația') ||
        lower.contains('trimite locatia') ||
        lower.contains('partajează locația') ||
        lower.contains('partajeaza locatia') ||
        lower.contains('trimite loc');
  }
}


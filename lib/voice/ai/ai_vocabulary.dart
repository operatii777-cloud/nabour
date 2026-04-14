// lib/voice/ai/ai_vocabulary.dart
// Biblioteca completă de cuvinte și fraze pentru AI Voice Assistant

class AIVocabulary {
  // 🚗 COMENZI PRINCIPALE - RIDE BOOKING
  static const Map<String, String> rideCommands = {
    // Comenzi de bază - cursă imediată
    'vrei să merg': 'booking_immediate',
    'vreau să merg': 'booking_immediate',
    'comandă o cursă': 'booking_immediate',
    'caut o cursă': 'booking_immediate',
    'vrei să mă duc': 'booking_immediate',
    'vreau să mă duc': 'booking_immediate',
    'vreau să plec acum': 'booking_immediate',
    'am nevoie de o cursă acum': 'booking_immediate',
    
    // Rezervări - cursă pentru mai târziu (30+ minute)
    'rezervă o cursă': 'booking_scheduled',
    'vreau să rezerv': 'booking_scheduled',
    'programează o cursă': 'booking_scheduled',
    'rezervare pentru mai târziu': 'booking_scheduled',
    'vreau să programez': 'booking_scheduled',
    
    // Destinații populare
    'universitate': 'destination_university',
    'centru': 'destination_center',
    'aeroport': 'destination_airport',
    'gara': 'destination_station',
    'mall': 'destination_mall',
    'spital': 'destination_hospital',
    'bancă': 'destination_bank',
    'restaurant': 'destination_restaurant',
    'benzinărie': 'destination_gas_station',
    'farmacie': 'destination_pharmacy',
    
    // Puncte de preluare
    'ia-mă de aici': 'pickup_current',
    'ia-mă de acasă': 'pickup_home',
    'ia-mă de la': 'pickup_specific',
    'ia-mă de la birou': 'pickup_office',
    'ia-mă de la facultate': 'pickup_university',
    'preluarea se face de la': 'pickup_specific',
    'punctul de preluare este la': 'pickup_specific',
    'să mă iei de la': 'pickup_specific',
    'să mă preiei de la': 'pickup_specific',
    
    // Timp și programare
    'acum': 'time_now',
    'imediat': 'time_now',
    'peste 10 minute': 'time_delayed',
    'peste o oră': 'time_delayed',
    'mâine': 'time_tomorrow',
    'azi': 'time_today',
  };

  // 🗣️ COMENZI VOCALE - VOICE CONTROL
  static const Map<String, String> voiceCommands = {
    // Control microfon
    'hey nabour': 'wake_word',
    'ascultă': 'start_listening',
    'oprește': 'stop_listening',
    'taci': 'stop_speaking',
    'mai tare': 'volume_up',
    'mai încet': 'volume_down',
    'mai rapid': 'speed_up',
    'mai lent': 'speed_down',
    
    // Navigare vocală
    'arată harta': 'show_map',
    'ascunde harta': 'hide_map',
    'mărește': 'zoom_in',
    'micșorează': 'zoom_out',
    'rotire': 'rotate_map',
    'resetare': 'reset_map',
    
    // Comutare ecrane
    'meniu principal': 'main_menu',
    'setări': 'settings',
    'istoric': 'history',
    'profil': 'profile',
    'ajutor': 'help',
  };

  // 💰 COMENZI DE PLATĂ - PAYMENT
  static const Map<String, String> paymentCommands = {
    // Metode de plată
    'card': 'payment_card',
    'cash': 'payment_cash',
    'numerar': 'payment_cash',
    'bani': 'payment_cash',
    'voucher': 'payment_voucher',
    'cod promoțional': 'payment_promo',
    
    // Detalii plată
    'confirmă plata': 'confirm_payment',
    'anulează plata': 'cancel_payment',
    'schimbă metoda': 'change_payment_method',
    'verifică soldul': 'check_balance',
    'istoric plăți': 'payment_history',
  };

  // 🚨 COMENZI DE URGENȚĂ - EMERGENCY
  static const Map<String, String> emergencyCommands = {
    // Situații de urgență
    'ajutor': 'emergency_help',
    'urgență': 'emergency_urgent',
    'pericol': 'emergency_danger',
    'accident': 'emergency_accident',
    'bolnav': 'emergency_sick',
    'rănit': 'emergency_injured',
    
    // Acțiuni de urgență - România (112)
    'cheamă ajutor': 'emergency_call_112',
    'sună la 112': 'emergency_call_112',
    'cheamă 112': 'emergency_call_112',
    'urgență 112': 'emergency_call_112',
    'ajutor 112': 'emergency_call_112',
    'anulează cursă': 'emergency_cancel_ride',
  };

  // 📱 COMENZI DE APLICAȚIE - APP CONTROL
  static const Map<String, String> appCommands = {
    // Funcții de bază
    'deschide': 'app_open',
    'închide': 'app_close',
    'minimizează': 'app_minimize',
    'maximizează': 'app_maximize',
    
    // Navigare în aplicație
    'înapoi': 'navigation_back',
    'înainte': 'navigation_forward',
    'acasă': 'navigation_home',
    'sus': 'navigation_up',
    'jos': 'navigation_down',
    
    // Setări aplicație
    'tema': 'settings_theme',
    'limba': 'settings_language',
    'sunetul': 'settings_sound',
    'notificările': 'settings_notifications',
    'privacy': 'settings_privacy',
  };

  // 🌍 COMENZI MULTILINGVE - MULTILINGUAL
  static const Map<String, String> multilingualCommands = {
    // Română
    'română': 'language_ro',
    'român': 'language_ro',
    
    // Engleză
    'english': 'language_en',
    'engleză': 'language_en',
    
    // Maghiară
    'maghiară': 'language_hu',
    'hungarian': 'language_hu',
    
    // Germană
    'germană': 'language_de',
    'deutsch': 'language_de',
    
    // Franceză
    'franceză': 'language_fr',
    'français': 'language_fr',
  };

  // 🤝 CONVERSAȚII DE CURTOAZIE - POLITE CONVERSATION
  static const Map<String, String> politeCommands = {
    // Salutări
    'bună ziua': 'greeting_formal',
    'bună dimineața': 'greeting_morning',
    'bună seara': 'greeting_evening',
    'salut': 'greeting_casual',
    'salutare': 'greeting_casual',
    'hello': 'greeting_english',
    'hi': 'greeting_english',
    
    // Mulțumiri
    'vă mulțumesc': 'thanks_formal',
    'mulțumesc': 'thanks_casual',
    'mersi': 'thanks_casual',
    'thank you': 'thanks_english',
    'mulțumesc frumos': 'thanks_formal',
    'vă mulțumesc mult': 'thanks_formal',
    
    // Întrebări de curtoazie
    'unde doriți să mergeți': 'ask_destination_polite',
    'unde ați dori să mergeți': 'ask_destination_formal',
    'care este destinația': 'ask_destination_neutral',
    'care este destinația dumneavoastră': 'ask_destination_formal',
    'unde vă duc': 'ask_destination_casual',
    
    // Oferiri de serviciu
    'dacă doriți pot să caut alt tip de autoturism': 'offer_vehicle_change',
    'pot să vă ofer o altă opțiune': 'offer_alternative',
    'pot să vă ajut cu altceva': 'offer_help',
    'mai aveți nevoie de ceva': 'ask_more_help',
    'vreți să schimbăm ceva': 'offer_change',
    'este în regulă pentru dumneavoastră': 'confirm_satisfaction',
    
    // Confirmări polite
    'perfect': 'confirm_perfect',
    'foarte bine': 'confirm_good',
    'excelent': 'confirm_excellent',
    'în regulă': 'confirm_ok',
    'sunt de acord': 'confirm_agree',
    'da, este bine': 'confirm_yes',
    
    // Scuze
    'îmi pare rău': 'apology',
    'scuzați-mă': 'apology_formal',
    'scuze': 'apology_casual',
    'ne cerem scuze': 'apology_formal',
    
    // Rămas bun
    'la revedere': 'goodbye',
    'pe curând': 'goodbye_casual',
    'drum bun': 'wish_good_trip',
    'călătorie plăcută': 'wish_pleasant_trip',
    'să aveți o zi frumoasă': 'wish_good_day',
  };

  // 🎯 RĂSPUNSURI AI - AI RESPONSES
  static const Map<String, String> aiResponses = {
    // Confirmări
    'confirm_booking': 'Perfect! Am înțeles că vrei să faci o rezervare. Spune-mi unde vrei să mergi.',
    'confirm_destination': 'Excelent! Destinația ta este: {destination}. Confirmă cu "da" sau "nu".',
    'confirm_pickup': 'Înțeleg! Punctul de ridicare este: {pickup}. Confirmă cu "da" sau "nu".',
    'confirm_payment': 'Bun! Metoda de plată: {payment}. Confirmă cu "da" sau "nu".',
    
    // Întrebări de clarificare
    'ask_destination': 'Unde vrei să mergi? Spune-mi destinația exactă.',
    'ask_pickup': 'De unde vrei să pleci? Spune-mi punctul de ridicare.',
    'ask_time': 'Când vrei să pleci? Spune-mi timpul exact.',
    'ask_payment': 'Cum vrei să plătești? Card, cash sau voucher?',
    
    // Răspunsuri de succes
    'success_booking': 'Excelent! Cursa ta a fost confirmată. Șoferul va ajunge în {time} minute.',
    'success_payment': 'Perfect! Plata a fost procesată cu succes. Mulțumesc!',
    'success_cancellation': 'Înțeleg! Cursa a fost anulată. Poți să faci o nouă rezervare.',
    
    // Răspunsuri de eroare
    'error_booking': 'Ne pare rău! Nu am putut procesa rezervarea. Încearcă din nou.',
    'error_payment': 'Eroare la plată! Verifică metoda de plată și încearcă din nou.',
    'error_location': 'Nu am înțeles locația! Poți să repeți mai clar?',
    
    // Răspunsuri de curtoazie
    'greeting_response': 'Bună ziua! Sunt asistentul Nabour. Cu ce vă pot ajuta?',
    'thanks_response': 'Cu mare plăcere! Sunt aici să vă ajut oricând.',
    'goodbye_response': 'La revedere! Vă doresc călătorie plăcută și o zi frumoasă!',
    'apology_response': 'Nu vă faceți griji! Să vedem cum vă pot ajuta.',
    'offer_help_response': 'Desigur! Vă pot ajuta să găsiți o altă opțiune de transport.',
    'confirm_satisfaction_response': 'Da, totul pare perfect! Să procedez cu confirmarea?',
  };

  // 🔍 PATTERN-URI DE RECUNOAȘTERE - RECOGNITION PATTERNS
  static const Map<String, List<String>> recognitionPatterns = {
    // Pattern-uri pentru destinații
    'destination_patterns': [
      'vreau să merg la {location}',
      'vreau să mă duc la {location}',
      'comandă o cursă la {location}',
      'rezervă o cursă la {location}',
      'du-mă la {location}',
    ],
    
    // Pattern-uri pentru timp
    'time_patterns': [
      'acum',
      'imediat',
      'peste {minutes} minute',
      'peste {hours} ore',
      'mâine',
      'azi',
    ],
    
    // Pattern-uri pentru plată
    'payment_patterns': [
      'plătește cu {method}',
      'vrei să plătești cu {method}',
      'metoda de plată {method}',
      'folosește {method}',
    ],
    
    // Pattern-uri pentru preluare
    'pickup_patterns': [
      'ia-mă de la {location}',
      'ia-mă de aici',
      'preluarea se face de la {location}',
      'punctul de preluare este la {location}',
      'să mă iei de la {location}',
      'să mă preiei de la {location}',
    ],
    
    // Pattern-uri pentru conversații de curtoazie
    'polite_patterns': [
      'bună {time_of_day}',
      '{thanks} {formality}',
      'unde {formality} să {action}',
      'dacă doriți pot să {offer}',
      '{polite_response}',
    ],
  };

  // 📚 FRASE COMPLETE - COMPLETE PHRASES
  static const List<String> completePhrases = [
    // Fraze de rezervare și comandă
    'Vreau să fac o rezervare pentru o cursă la universitate',
    'Comandă o cursă de la birou la centru',
    'Rezervă o cursă pentru mâine dimineață',
    'Vreau să merg de la gară la aeroport',
    'Ia-mă de la facultate și du-mă la mall',
    'Preluarea se face de la hotelul Radisson',
    'Punctul de preluare este la stația de metrou',
    
    // Fraze de plată
    'Vreau să plătesc cu cardul',
    'Confirm plata cu numerar',
    'Folosește voucherul meu',
    'Schimbă metoda de plată',
    
    // Fraze de urgență
    'Am nevoie de ajutor urgent',
    'Sunt într-o situație de pericol',
    'Sună la 112 imediat',
    'Anulează cursă de urgență',
    
    // Fraze de conversație politicoasă
    'Bună ziua, cu ce vă pot ajuta?',
    'Vă mulțumesc frumos pentru serviciu',
    'Unde doriți să mergeți astăzi?',
    'Dacă doriți pot să caut alt tip de autoturism',
    'Pot să vă ajut cu altceva?',
    'Este în regulă pentru dumneavoastră?',
    'La revedere și călătorie plăcută!',
    
    // Fraze de setări
    'Schimbă limba în engleză',
    'Activează tema întunecată',
    'Mărește volumul sunetului',
    'Dezactivează notificările',
  ];



  // 🎨 STILURI VOCALE - VOICE STYLES
  static const Map<String, Map<String, dynamic>> voiceStyles = {
    'friendly': {
      'speech_rate': 0.9,
      'pitch': 1.1,
      'volume': 0.8,
      'tone': 'Warm and welcoming',
    },
    'professional': {
      'speech_rate': 1.0,
      'pitch': 1.0,
      'volume': 0.9,
      'tone': 'Clear and authoritative',
    },
    'casual': {
      'speech_rate': 1.1,
      'pitch': 0.9,
      'volume': 0.7,
      'tone': 'Easy-going and natural',
    },
    'urgent': {
      'speech_rate': 1.2,
      'pitch': 1.3,
      'volume': 1.0,
      'tone': 'Alert and attention-grabbing',
    },
  };

  // 📍 BIBLIOTECA COMPLETĂ DE LOCAȚII BUCUREȘTI + ILFOV
  // Complete location database for Bucharest metropolitan area

  // 🚉 TRANSPORT & MOBILITATE - TRANSPORT & MOBILITY
  static const Map<String, Map<String, String>> transportLocations = {
    'bucuresti': {
      // Gări - Train Stations
      'gara de nord': 'Gara de Nord, Sector 1, București',
      'gara de est': 'Gara de Est, Sector 2, București',
      'gara progresul': 'Gara Progresul, Sector 4, București',
      'gara basarab': 'Gara Basarab, Sector 1, București',
      'gara filaret': 'Gara Filaret, Sector 4, București',
      
      // Aeroporturi - Airports
      'aeroportul otopeni': 'Aeroportul Internațional Henri Coandă, Otopeni',
      'aeroportul baneasa': 'Aeroportul Băneasa - Aurel Vlaicu, București',
      
      // Metrou - Metro Stations
      'metroul universitate': 'Stația de Metrou Universitate, Sector 1',
      'metroul piata romana': 'Stația de Metrou Piața Romană, Sector 1',
      'metroul piata unirii': 'Stația de Metrou Piața Unirii, Sector 3',
      'metroul piata victoriei': 'Stația de Metrou Piața Victoriei, Sector 1',
      'metroul gara de nord': 'Stația de Metrou Gara de Nord, Sector 1',
      'metroul piata muncii': 'Stația de Metrou Piața Muncii, Sector 4',
      'metroul eroilor': 'Stația de Metrou Eroilor, Sector 1',
      'metroul piata sudului': 'Stația de Metrou Piața Sudului, Sector 4',
      'metroul piata obor': 'Stația de Metrou Piața Obor, Sector 2',
      'metroul tineretului': 'Stația de Metrou Tineretului, Sector 4',
      'metroul constantin brancusi': 'Stația de Metrou Constantin Brâncuși, Sector 4',
      'metroul gorjului': 'Stația de Metrou Gorjului, Sector 5',
      'metroul eroilor revolutiei': 'Stația de Metrou Eroilor Revoluției, Sector 1',
      'metroul drumul taberei': 'Stația de Metrou Drumul Taberei, Sector 6',
      'metroul militari': 'Stația de Metrou Militari, Sector 6',
      'metroul berceni': 'Stația de Metrou Berceni, Sector 4',
      'metroul pantelimon': 'Stația de Metrou Pantelimon, Sector 2',
      'metroul titan': 'Stația de Metrou Titan, Sector 3',
      'metroul colentina': 'Stația de Metrou Colentina, Sector 2',
      'metroul baneasa': 'Stația de Metrou Băneasa, Sector 1',
      'metroul grivita': 'Stația de Metrou Grivița, Sector 1',
      'metroul floreasca': 'Stația de Metrou Floreasca, Sector 1',
      
      // Tramvai - Tram Stations
      'tramvai 1 mai': 'Stația de Tramvai 1 Mai, Sector 1',
      'tramvai piata unirii': 'Stația de Tramvai Piața Unirii, Sector 3',
      'tramvai piata victoriei': 'Stația de Tramvai Piața Victoriei, Sector 1',
      'tramvai eroilor': 'Stația de Tramvai Eroilor, Sector 1',
      
      // Autobuz - Bus Hubs
      'autobuz piata unirii': 'Hub Autobuz Piața Unirii, Sector 3',
      'autobuz piata victoriei': 'Hub Autobuz Piața Victoriei, Sector 1',
      'autobuz gara de nord': 'Hub Autobuz Gara de Nord, Sector 1',
      'autobuz piata muncii': 'Hub Autobuz Piața Muncii, Sector 4',
      'autobuz piata sudului': 'Hub Autobuz Piața Sudului, Sector 4',
      'autobuz piata obor': 'Hub Autobuz Piața Obor, Sector 2',
      'autobuz piata romana': 'Hub Autobuz Piața Romană, Sector 1',
      'autobuz universitate': 'Hub Autobuz Universitate, Sector 1',
      'autobuz eroilor': 'Hub Autobuz Eroilor, Sector 1',
      'autobuz drumul taberei': 'Hub Autobuz Drumul Taberei, Sector 6',
      'autobuz militari': 'Hub Autobuz Militari, Sector 6',
      'autobuz berceni': 'Hub Autobuz Berceni, Sector 4',
      'autobuz pantelimon': 'Hub Autobuz Pantelimon, Sector 2',
      'autobuz titan': 'Hub Autobuz Titan, Sector 3',
      'autobuz colentina': 'Hub Autobuz Colentina, Sector 2',
    },
    'ilfov': {
      // Gări - Train Stations
      'gara buftea': 'Gara Buftea, Ilfov',
      'gara chitila': 'Gara Chitila, Ilfov',
      'gara mogosoaia': 'Gara Mogoșoaia, Ilfov',
      'gara snagov': 'Gara Snagov, Ilfov',
      'gara voluntari': 'Gara Voluntari, Ilfov',
      
      // Aeroporturi - Airports
      'aeroportul henri coanda': 'Aeroportul Internațional Henri Coandă, Otopeni, Ilfov',
      
      // Autobuz - Bus Lines
      'autobuz 301': 'Linia RATB 301 - București - Buftea',
      'autobuz 302': 'Linia RATB 302 - București - Otopeni',
      'autobuz 303': 'Linia RATB 303 - București - Mogoșoaia',
      'autobuz 304': 'Linia RATB 304 - București - Snagov',
    },
  };

  // 🏪 SHOPPING & COMERȚ - SHOPPING & COMMERCE
  static const Map<String, Map<String, String>> shoppingLocations = {
    'bucuresti': {
      // Mall-uri - Shopping Malls
      'mall baneasa': 'Mall Băneasa Shopping Center, Sector 1',
      'mall afi': 'AFI Palace Cotroceni, Sector 5',
      'mall unirea': 'Centrul Comercial Unirea, Sector 3',
      'mall plaza romania': 'Plaza România, Sector 1',
      'mall promenada': 'Promenada Mall, Sector 1',
      'mall sun plaza': 'Sun Plaza, Sector 4',
      'mall bucuresti mall': 'București Mall, Sector 4',
      'mall liberty center': 'Liberty Center, Sector 1',
      'mall parklake': 'Mall ParkLake, Sector 6',
      'mall titan': 'Mall Titan, Sector 3',
      'mall colosseum': 'Mall Colosseum, Sector 4',
      'mall vitan': 'Mall Vitan, Sector 4',
      'mall plaza muncii': 'Mall Plaza Muncii, Sector 4',
      'mall plaza victoriei': 'Mall Plaza Victoriei, Sector 1',
      'mall plaza universitate': 'Mall Plaza Universitate, Sector 1',
      'mall plaza romana': 'Mall Plaza Romană, Sector 1',
      'mall plaza unirii': 'Mall Plaza Unirii, Sector 3',
      'mall plaza obor': 'Mall Plaza Obor, Sector 2',
      'mall mega mall': 'Mega Mall, Bulevardul Pierre de Coubertin 3-5, Sector 4',
      'mall veranda': 'Veranda Mall, Calea Floreasca 246B, Sector 1',
      'mall city mall': 'City Mall, Bulevardul Timișoara 26, Sector 6',
      'mall jolie ville': 'Jolie Ville Galleria, Strada Buzești 50-52, Sector 1',
      'mall europa retail park': 'Europa Retail Park, Bulevardul Glina 2, Sector 4',
      'mall militari shopping': 'Militari Shopping Center, Bulevardul Iuliu Maniu 558, Sector 6',
      
      // Supermarketuri - Supermarkets
      'carrefour orhideea': 'Carrefour Orhideea, Sector 1',
      'carrefour baneasa': 'Carrefour Băneasa, Sector 1',
      'carrefour piata unirii': 'Carrefour Piața Unirii, Sector 3',
      'carrefour piata muncii': 'Carrefour Piața Muncii, Sector 4',
      'carrefour piata sudului': 'Carrefour Piața Sudului, Sector 4',
      'carrefour eroilor': 'Carrefour Eroilor, Sector 1',
      'carrefour universitate': 'Carrefour Universitate, Sector 1',
      'carrefour piata romana': 'Carrefour Piața Romană, Sector 1',
      
      'mega image universitate': 'Mega Image Universitate, Sector 1',
      'mega image piata romana': 'Mega Image Piața Romană, Sector 1',
      'mega image piata unirii': 'Mega Image Piața Unirii, Sector 3',
      'mega image piata muncii': 'Mega Image Piața Muncii, Sector 4',
      'mega image eroilor': 'Mega Image Eroilor, Sector 1',
      'mega image piata sudului': 'Mega Image Piața Sudului, Sector 4',
      'mega image piata obor': 'Mega Image Piața Obor, Sector 2',
      'mega image piata victoriei': 'Mega Image Piața Victoriei, Sector 1',
      
      'kaufland piata muncii': 'Kaufland Piața Muncii, Sector 4',
      'kaufland eroilor': 'Kaufland Eroilor, Sector 1',
      'kaufland piata sudului': 'Kaufland Piața Sudului, Sector 4',
      'kaufland piata obor': 'Kaufland Piața Obor, Sector 2',
      'kaufland piata unirii': 'Kaufland Piața Unirii, Sector 3',
      'kaufland universitate': 'Kaufland Universitate, Sector 1',
      
      'lidl piata sudului': 'Lidl Piața Sudului, Sector 4',
      'lidl piata muncii': 'Lidl Piața Muncii, Sector 4',
      'lidl eroilor': 'Lidl Eroilor, Sector 1',
      'lidl universitate': 'Lidl Universitate, Sector 1',
      'lidl piata romana': 'Lidl Piața Romană, Sector 1',
      'lidl piata unirii': 'Lidl Piața Unirii, Sector 3',
      'lidl piata obor': 'Lidl Piața Obor, Sector 2',
      'lidl piata victoriei': 'Lidl Piața Victoriei, Sector 1',
      'lidl drumul taberei': 'Lidl Drumul Taberei, Sector 6',
      'lidl militari': 'Lidl Militari, Sector 6',
      'lidl berceni': 'Lidl Berceni, Sector 4',
      'lidl pantelimon': 'Lidl Pantelimon, Sector 2',
      'lidl titan': 'Lidl Titan, Sector 3',
      'lidl colentina': 'Lidl Colentina, Sector 2',
      
      // Carrefour - Hypermarketuri suplimentare
      'carrefour colentina': 'Carrefour Colentina, Bulevardul Ștefan cel Mare 5, Sector 2',
      'carrefour militari': 'Carrefour Militari, Bulevardul Iuliu Maniu 558, Sector 6',
      
      // Kaufland - Hypermarketuri suplimentare
      'kaufland vitan': 'Kaufland Vitan, Calea Vitan 55-59, Sector 4',
      'kaufland baneasa': 'Kaufland Băneasa, Șoseaua Băneasa 42, Sector 1',
      'kaufland colosseum': 'Kaufland Colosseum, Strada Râmnicu Vâlcea 4, Sector 1',
      
      // Auchan - Hypermarketuri
      'auchan titan': 'Auchan Titan, Bulevardul 1 Decembrie 1918 33, Sector 3',
      'auchan militari': 'Auchan Militari, Bulevardul Iuliu Maniu 444, Sector 6',
      
      // Cora - Hypermarketuri
      'cora pantelimon': 'Cora Pantelimon, Șoseaua Pantelimon 302, Sector 2',
      'cora lujerului': 'Cora Lujerului, Bulevardul Timișoara 26, Sector 6',
      
      // Piețe - Markets
      'piata obor': 'Piața Obor, Sector 2',
      'piata amzei': 'Piața Amzei, Sector 1',
      'piata matache': 'Piața Matache, Sector 1',
      'piata colței': 'Piața Colței, Sector 3',
      'piata unirii': 'Piața Unirii, Sector 3',
      'piata victoriei': 'Piața Victoriei, Sector 1',
      'piata romana': 'Piața Romană, Sector 1',
      'piata universitatii': 'Piața Universității, Sector 1',
      'piata floreasca': 'Piața Floreasca, Sector 1',
      'piata dorobanti': 'Piața Dorobanți, Sector 1',
      'piata gemeni': 'Piața Gemeni, Bulevardul Ion Mihalache, Sector 1',
      'piata berceni': 'Piața Berceni, Calea Berceni, Sector 4',
      'piata 16 februarie': 'Piața 16 Februarie, Strada 16 Februarie, Sector 1',
      'piata crangasi': 'Piața Crângași, Piața Crângași, Sector 6',
      
      // Centru comercial - Shopping District
      'lipscani': 'Strada Lipscani, Centrul Vechi, Sector 3',
      'calea victoriei': 'Calea Victoriei, Sector 1',
      'strada stefan cel mare': 'Strada Ștefan cel Mare, Sector 1',
      
      // Benzinării - Gas Stations
      'petrom universitate': 'Petrom Universitate, Sector 1',
      'petrom piata romana': 'Petrom Piața Romană, Sector 1',
      'petrom piata unirii': 'Petrom Piața Unirii, Sector 3',
      'petrom piata muncii': 'Petrom Piața Muncii, Sector 4',
      'petrom piata sudului': 'Petrom Piața Sudului, Sector 4',
      'petrom piata obor': 'Petrom Piața Obor, Sector 2',
      'petrom eroilor': 'Petrom Eroilor, Sector 1',
      'petrom gara de nord': 'Petrom Gara de Nord, Sector 1',
      'petrom drumul taberei': 'Petrom Drumul Taberei, Sector 6',
      'petrom militari': 'Petrom Militari, Sector 6',
      'petrom berceni': 'Petrom Berceni, Sector 4',
      'petrom pantelimon': 'Petrom Pantelimon, Sector 2',
      'petrom titan': 'Petrom Titan, Sector 3',
      'petrom colentina': 'Petrom Colentina, Sector 2',
      
      'rompetrol universitate': 'Rompetrol Universitate, Sector 1',
      'rompetrol piata romana': 'Rompetrol Piața Romană, Sector 1',
      'rompetrol piata unirii': 'Rompetrol Piața Unirii, Sector 3',
      'rompetrol piata muncii': 'Rompetrol Piața Muncii, Sector 4',
      'rompetrol piata sudului': 'Rompetrol Piața Sudului, Sector 4',
      'rompetrol piata obor': 'Rompetrol Piața Obor, Sector 2',
      'rompetrol eroilor': 'Rompetrol Eroilor, Sector 1',
      'rompetrol gara de nord': 'Rompetrol Gara de Nord, Sector 1',
      
      'moll universitate': 'Moll Universitate, Sector 1',
      'moll piata romana': 'Moll Piața Romană, Sector 1',
      'moll piata unirii': 'Moll Piața Unirii, Sector 3',
      'moll piata muncii': 'Moll Piața Muncii, Sector 4',
      'moll piata sudului': 'Moll Piața Sudului, Sector 4',
      'moll piata obor': 'Moll Piața Obor, Sector 2',
      'moll eroilor': 'Moll Eroilor, Sector 1',
      'moll gara de nord': 'Moll Gara de Nord, Sector 1',
      
      // OMV - Stații de carburanți
      'omv herastrau': 'OMV Herăstrău, Șoseaua Nordului 42, Sector 1',
      'omv aviatorilor': 'OMV Aviatorilor, Bulevardul Aviatorilor 72, Sector 1',
      'omv colentina': 'OMV Colentina, Șoseaua Colentina 85, Sector 2',
      'omv doamna ghica': 'OMV Doamna Ghica, Bulevardul Doamna Ghica 4, Sector 2',
      'omv aparatorii patriei': 'OMV Aparatorii Patriei, Bulevardul Aparatorii Patriei 35, Sector 4',
      
      // MOL - Stații de carburanți
      'mol pipera': 'MOL Pipera, Șoseaua de Circumvalație 4, Sector 2',
      'mol berceni': 'MOL Berceni, Calea Berceni 100, Sector 4',
      
      // LUKOIL - Stații de carburanți
      'lukoil grozavesti': 'LUKOIL Grozăvești, Strada Grozăvești 61, Sector 6',
      'lukoil drumul taberei': 'LUKOIL Drumul Taberei, Bulevardul Timișoara 58, Sector 6',
      'lukoil colentina': 'LUKOIL Colentina, Șoseaua Colentina 120, Sector 2',
      
      // Rompetrol - Stații suplimentare
      'rompetrol unirii': 'Rompetrol Unirii, Bulevardul Unirii 65, Sector 3',
      'rompetrol stefan cel mare': 'Rompetrol Stefan cel Mare, Bulevardul Ștefan cel Mare 126, Sector 2',
      'rompetrol calea calarasi': 'Rompetrol Calea Călărași, Calea Călărași 256, Sector 3',
      
      // Petrom - Stații suplimentare
      'petrom victoriei': 'Petrom Victoriei, Calea Victoriei 155, Sector 1',
      'petrom floreasca': 'Petrom Floreasca, Calea Floreasca 169, Sector 1',
      'petrom baneasa': 'Petrom Băneasa, Șoseaua Bucureștii Noi 235, Sector 1',
      'petrom progresul': 'Petrom Progresul, Calea Progresului 220, Sector 4',
      'petrom vitan': 'Petrom Vitan, Calea Vitan 230, Sector 4',
    },
    'ilfov': {
      // Mall-uri - Shopping Malls
      'mall baneasa ilfov': 'Mall Băneasa Shopping Center, Ilfov',
      'mall promenada ilfov': 'Promenada Mall, Ilfov',
      
      // Supermarketuri - Supermarkets
      'carrefour buftea': 'Carrefour Buftea, Ilfov',
      'carrefour otopeni': 'Carrefour Otopeni, Ilfov',
      'mega image mogosoaia': 'Mega Image Mogoșoaia, Ilfov',
      'kaufland snagov': 'Kaufland Snagov, Ilfov',
      'lidl voluntari': 'Lidl Voluntari, Ilfov',
      
      // Benzinării Ilfov
      'mol otopeni': 'MOL Otopeni, Calea București 165, Otopeni, Ilfov',
      
      // Piețe - Markets
      'piata buftea': 'Piața Buftea, Ilfov',
      'piata otopeni': 'Piața Otopeni, Ilfov',
      'piata mogosoaia': 'Piața Mogoșoaia, Ilfov',
    },
  };

  // 🍽️ RESTAURANTE & CAFENELE - RESTAURANTS & CAFES
  static const Map<String, Map<String, String>> restaurantLocations = {
    'bucuresti': {
      // Restaurante românești - Romanian Restaurants
      'hanu lui manuc': 'Hanu\' lui Manuc, Strada Franceză 62, Sector 3',
      'caru cu bere': 'Caru\' cu Bere, Strada Stavropoleos 5, Sector 3',
      'casa doina': 'Casa Doina, Șoseaua Kiseleff 4, Sector 1',
      'restaurant dobrogea': 'Restaurant Dobrogea, Strada Lipscani 26, Sector 3',
      'restaurant pescăruș': 'Restaurant Pescăruș, Strada Smârdan 11, Sector 3',
      'restaurant la mama': 'Restaurant La Mama, Strada Lipscani 15, Sector 3',
      'restaurant bucuresti': 'Restaurant București, Strada Smârdan 30, Sector 3',
      'restaurant crama domneasca': 'Crama Domnească, Strada Franceză 62, Sector 3',
      'restaurant hanu berarilor': 'Hanu Berarilor, Strada Poenaru Bordea 2, Sector 3',
      'restaurant casa veche': 'Casa Veche, Strada Smârdan 12, Sector 3',
      'restaurant tratoria': 'Trattoria, Strada Lipscani 20, Sector 3',
      'restaurant pescărușul': 'Pescărușul, Strada Smârdan 25, Sector 3',
      
      // Restaurante internaționale - International Restaurants
      'hard rock cafe': 'Hard Rock Cafe, Strada Lipscani 28, Sector 3',
      'mcdonalds universitate': 'McDonald\'s Universitate, Sector 1',
      'mcdonalds piata unirii': 'McDonald\'s Piața Unirii, Sector 3',
      'kfc piata romana': 'KFC Piața Romană, Sector 1',
      'pizza hut piata victoriei': 'Pizza Hut Piața Victoriei, Sector 1',
      'subway eroilor': 'Subway Eroilor, Sector 1',
      
      // Cafenele - Cafes
      'starbucks universitate': 'Starbucks Universitate, Sector 1',
      'starbucks piata romana': 'Starbucks Piața Romană, Sector 1',
      'teds coffee': 'Teds Coffee, Strada Lipscani 15, Sector 3',
      'origo': 'Origo, Strada Lipscani 9, Sector 3',
      'the coffee shop': 'The Coffee Shop, Strada Smârdan 30, Sector 3',
      
      // Fast-food - Fast Food
      'burger king piata muncii': 'Burger King Piața Muncii, Sector 4',
      'dominos pizza eroilor': 'Domino\'s Pizza Eroilor, Sector 1',
    },
    'ilfov': {
      // Restaurante - Restaurants
      'restaurant baneasa': 'Restaurant Băneasa, Ilfov',
      'hanul din mogosoaia': 'Hanul din Mogoșoaia, Ilfov',
      'restaurant snagov': 'Restaurant Snagov, Ilfov',
      
      // Cafenele - Cafes
      'cafeneaua din otopeni': 'Cafeneaua din Otopeni, Ilfov',
      'starbucks baneasa': 'Starbucks Băneasa, Ilfov',
      
      // Fast-food - Fast Food
      'mcdonalds otopeni': 'McDonald\'s Otopeni, Ilfov',
      'kfc buftea': 'KFC Buftea, Ilfov',
      'pizza hut mogosoaia': 'Pizza Hut Mogoșoaia, Ilfov',
    },
  };

  // 🏟️ SPORT & RECREERE - SPORTS & RECREATION
  static const Map<String, Map<String, String>> sportsLocations = {
    'bucuresti': {
      // Stadioane - Stadiums
      'arena nationala': 'Arena Națională, Sector 2',
      'stadionul steaua': 'Stadionul Steaua, Sector 1',
      'stadionul dinamo': 'Stadionul Dinamo, Sector 1',
      'stadionul rapid': 'Stadionul Rapid, Sector 4',
      'stadionul giulesti': 'Stadionul Giulești, Sector 1',
      
      // Săli de sport - Sports Halls
      'sala polivalenta': 'Sala Polivalentă, Sector 1',
      'sala dinamo': 'Sala Dinamo, Sector 1',
      'sala rapid': 'Sala Rapid, Sector 4',
      'sala steaua': 'Sala Steaua, Sector 1',
      
      // Parcuri - Parks
      'parcul herastrau': 'Parcul Herăstrău, Sector 1',
      'parcul cismigiu': 'Parcul Cismigiu, Sector 1',
      'parcul carol': 'Parcul Carol, Sector 4',
      'parcul tineretului': 'Parcul Tineretului, Sector 4',
      'parcul kiseleff': 'Parcul Kiseleff, Sector 1',
      'parcul ior': 'Parcul IOR, Sector 3',
      'parcul alexandru ioan cuza': 'Parcul Alexandru Ioan Cuza, Sector 1',
      'parcul drumul taberei': 'Parcul Drumul Taberei, Sector 6',
      'parcul tei': 'Parcul Tei, Sector 2',
      'parcul pantelimon': 'Parcul Pantelimon, Sector 2',
      'parcul titan': 'Parcul Titan, Sector 3',
      'parcul colentina': 'Parcul Colentina, Sector 2',
      'parcul berceni': 'Parcul Berceni, Sector 4',
      'parcul militari': 'Parcul Militari, Sector 6',
      'parcul baneasa': 'Parcul Băneasa, Sector 1',
      'parcul grivita': 'Parcul Grivița, Sector 1',
      'parcul floreasca': 'Parcul Floreasca, Sector 1',
      'parcul bordei': 'Parcul Bordei, Calea Plevnei, Sector 1',
      'parcul circului': 'Parcul Circului, Aleea Circului, Sector 1',
      'parcul plumbuita': 'Parcul Plumbuita, Strada Plumbuita, Sector 2',
      'parcul moghioros': 'Parcul Moghioroș, Strada Moghioroș, Sector 1',
      'gradina icoanei': 'Grădina Icoanei, Strada Icoanei, Sector 2',
      'parcul amzei': 'Parcul Amzei, Bulevardul Aviatorilor, Sector 1',
      'parcul izvor': 'Parcul Izvor, Strada Izvor, Sector 5',
      
      // Piscine - Swimming Pools
      'piscina dinamo': 'Piscina Dinamo, Sector 1',
      'piscina steaua': 'Piscina Steaua, Sector 1',
      'piscina rapid': 'Piscina Rapid, Sector 4',
    },
    'ilfov': {
      // Stadioane - Stadiums
      'stadionul buftea': 'Stadionul Buftea, Ilfov',
      'stadionul otopeni': 'Stadionul Otopeni, Ilfov',
      'stadionul mogosoaia': 'Stadionul Mogoșoaia, Ilfov',
      
      // Parcuri - Parks
      'parcul din buftea': 'Parcul din Buftea, Ilfov',
      'parcul din mogosoaia': 'Parcul din Mogoșoaia, Ilfov',
      'parcul snagov': 'Parcul Snagov, Ilfov',
      
      // Săli de sport - Sports Halls
      'sala de sport buftea': 'Sala de sport Buftea, Ilfov',
      'complexul sportiv otopeni': 'Complexul sportiv Otopeni, Ilfov',
    },
  };

  // 🏛️ INSTITUȚII PUBLICE - PUBLIC INSTITUTIONS
  static const Map<String, Map<String, String>> institutionLocations = {
    'bucuresti': {
      // Ministere - Ministries
      'ministerul justitiei': 'Ministerul Justiției, Strada Apolodor 17, Sector 5',
      'ministerul finantelor': 'Ministerul Finanțelor, Strada Apolodor 17, Sector 5',
      'ministerul educatiei': 'Ministerul Educației, Strada Geniului 28-30, Sector 6',
      'ministerul sanatatii': 'Ministerul Sănătății, Strada Cristian Popișteanu 17-23, Sector 1',
      'ministerul transporturilor': 'Ministerul Transporturilor, Strada Dinicu Golescu 38, Sector 1',
      'ministerul afacerilor externe': 'Ministerul Afacerilor Externe, Strada Apolodor 17, Sector 5',
      
      // Primăria București - Bucharest City Hall
      'primaria bucuresti': 'Primăria Municipiului București, Strada General Dona 1, Sector 1',
      'palatul primariei': 'Palatul Primăriei, Strada General Dona 1, Sector 1',
      
      // Prefectura București - Bucharest Prefecture
      'prefectura bucuresti': 'Prefectura Municipiului București, Strada Demetru I. Dobrescu 2, Sector 1',
      'palatul prefecturii': 'Palatul Prefecturii, Strada Demetru I. Dobrescu 2, Sector 1',
      
      // Consiliul General - General Council
      'consiliul general bucuresti': 'Consiliul General al Municipiului București, Strada General Dona 1, Sector 1',
    },
    'ilfov': {
      // Consiliul Județean Ilfov - Ilfov County Council
      'consiliul județean ilfov': 'Consiliul Județean Ilfov, Buftea',
      'palatul consiliului ilfov': 'Palatul Consiliului Județean Ilfov, Buftea',
      
      // Primării - City Halls
      'primaria voluntari': 'Primăria Voluntari, Strada Voluntarilor 2, Voluntari, Ilfov',
      'primaria otopeni': 'Primăria Otopeni, Calea București 76, Otopeni, Ilfov',
      'primaria bragadiru': 'Primăria Bragadiru, Strada Argeșului 66, Bragadiru, Ilfov',
      'primaria chiajna': 'Primăria Chiajna, Strada București 107A, Chiajna, Ilfov',
      'primaria popesti leordeni': 'Primăria Popești-Leordeni, Strada Amurgului 1, Popești-Leordeni, Ilfov',
      'primaria pantelimon': 'Primăria Pantelimon, Strada Eroilor 17, Pantelimon, Ilfov',
      'primaria buftea': 'Primăria Buftea, Ilfov',
      'primaria mogosoaia': 'Primăria Mogoșoaia, Ilfov',
      'primaria snagov': 'Primăria Snagov, Ilfov',
      
      // Prefectura Ilfov - Ilfov Prefecture
      'prefectura ilfov': 'Prefectura Județului Ilfov, Buftea',
    },
  };

  // 🏥 SĂNĂTATE & MEDICAL - HEALTH & MEDICAL
  static const Map<String, Map<String, String>> medicalLocations = {
    'bucuresti': {
      // Spitale - Hospitals
      'spitalul floreasca': 'Spitalul Clinic de Urgență Floreasca, Sector 1',
      'spitalul pantelimon': 'Spitalul Clinic de Urgență Pantelimon, Sector 2',
      'spitalul coltea': 'Spitalul Colțea, Sector 3',
      'spitalul fundeni': 'Institutul Clinic Fundeni, Sector 2',
      'spitalul elias': 'Spitalul Clinic de Urgență Elias, Sector 4',
      'spitalul universitar': 'Spitalul Universitar de Urgență București, Sector 1',
      'spitalul bagdasar': 'Spitalul Clinic de Urgență Bagdasar-Arseni, Sector 4',
      
      // Clinici private - Private Clinics
      'clinica medlife': 'Clinica Medlife, Sector 1',
      'clinica regina maria': 'Clinica Regina Maria, Sector 1',
      'clinica sanador': 'Clinica Sanador, Sector 1',
      'clinica medicover': 'Clinica Medicover, Sector 1',
      'clinica euroclinic': 'Clinica Euroclinic, Sector 1',
      
      // Policlinici - Polyclinics
      'policlinica universitate': 'Policlinica Universitate, Sector 1',
      'policlinica piata romana': 'Policlinica Piața Romană, Sector 1',
      'policlinica piata unirii': 'Policlinica Piața Unirii, Sector 3',
      'policlinica piata muncii': 'Policlinica Piața Muncii, Sector 4',
      'policlinica piata sudului': 'Policlinica Piața Sudului, Sector 4',
      'policlinica piata obor': 'Policlinica Piața Obor, Sector 2',
      'policlinica eroilor': 'Policlinica Eroilor, Sector 1',
      'policlinica gara de nord': 'Policlinica Gara de Nord, Sector 1',
      'policlinica drumul taberei': 'Policlinica Drumul Taberei, Sector 6',
      'policlinica militari': 'Policlinica Militari, Sector 6',
      'policlinica berceni': 'Policlinica Berceni, Sector 4',
      'policlinica pantelimon': 'Policlinica Pantelimon, Sector 2',
      'policlinica titan': 'Policlinica Titan, Sector 3',
      'policlinica colentina': 'Policlinica Colentina, Sector 2',
      
      // Centru Medical
      'centrul medical universitate': 'Centrul Medical Universitate, Sector 1',
      'centrul medical piata romana': 'Centrul Medical Piața Romană, Sector 1',
      'centrul medical piata unirii': 'Centrul Medical Piața Unirii, Sector 3',
      'centrul medical piata muncii': 'Centrul Medical Piața Muncii, Sector 4',
      'centrul medical piata sudului': 'Centrul Medical Piața Sudului, Sector 4',
      'centrul medical piata obor': 'Centrul Medical Piața Obor, Sector 2',
      'centrul medical eroilor': 'Centrul Medical Eroilor, Sector 1',
      'centrul medical gara de nord': 'Centrul Medical Gara de Nord, Sector 1',
      
      // Farmacii - Pharmacies
      'farmacia sensiblu': 'Farmacia Sensiblu, Sector 1',
      'farmacia dona': 'Farmacia Dona, Sector 1',
      'farmacia helpnet': 'Farmacia HelpNet, Sector 1',
      'farmacia catena': 'Farmacia Catena, Sector 1',
      
      // Farmacii Non-Stop - 24/7 Pharmacies
      'farmacia non stop universitate': 'Farmacia Non-Stop Universitate, Sector 1',
      'farmacia non stop piata romana': 'Farmacia Non-Stop Piața Romană, Sector 1',
      'farmacia non stop piata unirii': 'Farmacia Non-Stop Piața Unirii, Sector 3',
      'farmacia non stop piata muncii': 'Farmacia Non-Stop Piața Muncii, Sector 4',
      'farmacia non stop piata sudului': 'Farmacia Non-Stop Piața Sudului, Sector 4',
      'farmacia non stop piata obor': 'Farmacia Non-Stop Piața Obor, Sector 2',
      'farmacia non stop eroilor': 'Farmacia Non-Stop Eroilor, Sector 1',
      'farmacia non stop gara de nord': 'Farmacia Non-Stop Gara de Nord, Sector 1',
      'farmacia non stop drumul taberei': 'Farmacia Non-Stop Drumul Taberei, Sector 6',
      'farmacia non stop militari': 'Farmacia Non-Stop Militari, Sector 6',
      'farmacia non stop berceni': 'Farmacia Non-Stop Berceni, Sector 4',
      'farmacia non stop pantelimon': 'Farmacia Non-Stop Pantelimon, Sector 2',
      'farmacia non stop titan': 'Farmacia Non-Stop Titan, Sector 3',
      'farmacia non stop colentina': 'Farmacia Non-Stop Colentina, Sector 2',
      
      // Farmacii Sensiblu
      'farmacia sensiblu universitate': 'Farmacia Sensiblu Universitate, Sector 1',
      'farmacia sensiblu piata romana': 'Farmacia Sensiblu Piața Romană, Sector 1',
      'farmacia sensiblu piata unirii': 'Farmacia Sensiblu Piața Unirii, Sector 3',
      'farmacia sensiblu piata muncii': 'Farmacia Sensiblu Piața Muncii, Sector 4',
      'farmacia sensiblu piata sudului': 'Farmacia Sensiblu Piața Sudului, Sector 4',
      'farmacia sensiblu piata obor': 'Farmacia Sensiblu Piața Obor, Sector 2',
      'farmacia sensiblu eroilor': 'Farmacia Sensiblu Eroilor, Sector 1',
      'farmacia sensiblu gara de nord': 'Farmacia Sensiblu Gara de Nord, Sector 1',
      
      // Farmacii Catena
      'farmacia catena universitate': 'Farmacia Catena Universitate, Sector 1',
      'farmacia catena piata romana': 'Farmacia Catena Piața Romană, Sector 1',
      'farmacia catena piata unirii': 'Farmacia Catena Piața Unirii, Sector 3',
      'farmacia catena piata muncii': 'Farmacia Catena Piața Muncii, Sector 4',
      'farmacia catena piata sudului': 'Farmacia Catena Piața Sudului, Sector 4',
      'farmacia catena piata obor': 'Farmacia Catena Piața Obor, Sector 2',
      'farmacia catena eroilor': 'Farmacia Catena Eroilor, Sector 1',
      'farmacia catena gara de nord': 'Farmacia Catena Gara de Nord, Sector 1',
    },
    'ilfov': {
      // Spitale - Hospitals
      'spitalul buftea': 'Spitalul Buftea, Ilfov',
      'spitalul otopeni': 'Spitalul Otopeni, Ilfov',
      'spitalul mogosoaia': 'Spitalul Mogoșoaia, Ilfov',
      
      // Clinici - Clinics
      'clinica medlife buftea': 'Clinica Medlife Buftea, Ilfov',
      'clinica regina maria otopeni': 'Clinica Regina Maria Otopeni, Ilfov',
      'clinica sanador mogosoaia': 'Clinica Sanador Mogoșoaia, Ilfov',
      
      // Farmacii - Pharmacies
      'farmacia sensiblu buftea': 'Farmacia Sensiblu Buftea, Ilfov',
      'farmacia dona otopeni': 'Farmacia Dona Otopeni, Ilfov',
      'farmacia helpnet mogosoaia': 'Farmacia HelpNet Mogoșoaia, Ilfov',
    },
  };

  // 🎓 EDUCAȚIE & CULTURĂ - EDUCATION & CULTURE
  static const Map<String, Map<String, String>> educationLocations = {
    'bucuresti': {
      // Universități - Universities
      'universitatea din bucuresti': 'Universitatea din București, Strada Mihail Kogălniceanu 36-46, Sector 5',
      'academia de studii economice': 'Academia de Studii Economice, Piața Romană 6, Sector 1',
      'universitatea politehnica': 'Universitatea Politehnica din București, Splaiul Independenței 313, Sector 6',
      'universitatea de medicina': 'Universitatea de Medicină și Farmacie Carol Davila, Strada Dionisie Lupu 37, Sector 1',
      'universitatea de arhitectura': 'Universitatea de Arhitectură și Urbanism Ion Mincu, Strada Academiei 18-20, Sector 1',
      'universitatea nationala de arte': 'Universitatea Națională de Arte București, Strada General Budișteanu 19, Sector 1',
      'universitatea de stiinte agronomice': 'Universitatea de Științe Agronomice și Medicină Veterinară, Bulevardul Mărăști 59, Sector 1',
      'universitatea de stiinte politice': 'Universitatea de Științe Politice și Administrative, Strada Povernei 6, Sector 1',
      'universitatea de stiinte economice': 'Universitatea de Științe Economice, Strada Piața Romană 6, Sector 1',
      'universitatea de stiinte fizice': 'Universitatea de Științe Fizice, Strada Atomistilor 405, Sector 1',
      'universitatea de stiinte chimice': 'Universitatea de Științe Chimice, Strada Atomistilor 405, Sector 1',
      
      // Facultăți - Faculties
      'facultatea de drept': 'Facultatea de Drept, Universitatea din București, Strada Mihail Kogălniceanu 36-46, Sector 5',
      'facultatea de litere': 'Facultatea de Litere, Universitatea din București, Strada Mihail Kogălniceanu 36-46, Sector 5',
      'facultatea de matematica': 'Facultatea de Matematică și Informatică, Universitatea din București, Strada Mihail Kogălniceanu 36-46, Sector 5',
      'facultatea de fizica': 'Facultatea de Fizică, Universitatea din București, Strada Atomistilor 405, Sector 1',
      'facultatea de chimie': 'Facultatea de Chimie, Universitatea din București, Strada Atomistilor 405, Sector 1',
      'facultatea de biologie': 'Facultatea de Biologie, Universitatea din București, Strada Mihail Kogălniceanu 36-46, Sector 5',
      'facultatea de istorie': 'Facultatea de Istorie, Universitatea din București, Strada Mihail Kogălniceanu 36-46, Sector 5',
      'facultatea de filozofie': 'Facultatea de Filozofie, Universitatea din București, Strada Mihail Kogălniceanu 36-46, Sector 5',
      'facultatea de psihologie': 'Facultatea de Psihologie și Științe ale Educației, Universitatea din București, Strada Mihail Kogălniceanu 36-46, Sector 5',
      'facultatea de sociologie': 'Facultatea de Sociologie și Asistență Socială, Universitatea din București, Strada Mihail Kogălniceanu 36-46, Sector 5',
      
      // Școli Generale - General Schools
      'scoala gimnaziala 1 mai': 'Școala Gimnazială 1 Mai, Sector 1',
      'scoala gimnaziala universitate': 'Școala Gimnazială Universitate, Sector 1',
      'scoala gimnaziala piata romana': 'Școala Gimnazială Piața Romană, Sector 1',
      'scoala gimnaziala piata victoriei': 'Școala Gimnazială Piața Victoriei, Sector 1',
      'scoala gimnaziala piata unirii': 'Școala Gimnazială Piața Unirii, Sector 3',
      'scoala gimnaziala piata muncii': 'Școala Gimnazială Piața Muncii, Sector 4',
      'scoala gimnaziala piata sudului': 'Școala Gimnazială Piața Sudului, Sector 4',
      'scoala gimnaziala piata obor': 'Școala Gimnazială Piața Obor, Sector 2',
      'scoala gimnaziala eroilor': 'Școala Gimnazială Eroilor, Sector 1',
      'scoala gimnaziala drumul taberei': 'Școala Gimnazială Drumul Taberei, Sector 6',
      'scoala gimnaziala militari': 'Școala Gimnazială Militari, Sector 6',
      'scoala gimnaziala berceni': 'Școala Gimnazială Berceni, Sector 4',
      'scoala gimnaziala pantelimon': 'Școala Gimnazială Pantelimon, Sector 2',
      'scoala gimnaziala titan': 'Școala Gimnazială Titan, Sector 3',
      'scoala gimnaziala colentina': 'Școala Gimnazială Colentina, Sector 2',
      
      // Muzee - Museums
      'muzeul national de arta': 'Muzeul Național de Artă al României, Calea Victoriei 49-53, Sector 1',
      'muzeul de istorie': 'Muzeul Național de Istorie a României, Calea Victoriei 12, Sector 3',
      'muzeul taranului roman': 'Muzeul Țăranului Român, Șoseaua Kiseleff 3, Sector 1',
      'muzeul satului': 'Muzeul Național al Satului Dimitrie Gusti, Șoseaua Kiseleff 28-30, Sector 1',
      'muzeul geologie': 'Muzeul Național de Geologie, Strada Șos. Kiseleff 2, Sector 1',
      'muzeul national cotroceni': 'Muzeul Național Cotroceni, Bulevardul Geniului 1, Sector 5',
      'muzeul de istorie naturala antipa': 'Muzeul de Istorie Naturală Grigore Antipa, Șoseaua Kiseleff 1, Sector 1',
      'muzeul de arta contemporana': 'Muzeul de Artă Contemporană, Strada Izvor 2-4, Sector 5',
      'muzeul militar national': 'Muzeul Militar Național, Strada Mircea Vulcănescu 125-127, Sector 1',
      'muzeul municipiului bucuresti': 'Muzeul Municipiului București, Bulevardul Ion C. Brătianu 2, Sector 3',
      'casa memoriala george enescu': 'Casa Memorială George Enescu, Calea Victoriei 141, Sector 1',
      'casa memoriala mihail sadoveanu': 'Casa Memorială Mihail Sadoveanu, Strada Dacia 35, Sector 1',
      'casa memoriala caragiale': 'Casa Memorială I.L. Caragiale, Strada I.L. Caragiale 4, Sector 1',
      
      // Teatre - Theaters
      'teatrul national': 'Teatrul Național București, Bulevardul Nicolae Bălcescu 2, Sector 1',
      'teatrul bulandra': 'Teatrul Bulandra, Strada Strada Biserica Amzei 13, Sector 1',
      'teatrul odeon': 'Teatrul Odeon, Strada Amzei 13, Sector 1',
      'teatrul notara': 'Teatrul Nottara, Bulevardul Dacia 18, Sector 1',
      'opera nationala': 'Opera Națională București, Bulevardul Mihail Kogălniceanu 70-72, Sector 5',
      'teatrul de opereta': 'Teatrul de Operetă, Strada Constantin Mille 20, Sector 1',
      'teatrul foarte mic': 'Teatrul Foarte Mic, Strada Constantin Mille 12, Sector 1',
      'sala palatului': 'Sala Palatului, Strada Ion Campineanu 28, Sector 1',
      'arenele romane': 'Arenele Romane, Parcul Carol, Sector 4',
      'teatrul de vara herastrau': 'Teatrul de Vară Herăstrău, Șoseaua Nordului, Sector 1',
      'teatrul verde': 'Teatrul Verde, Parcul Cișmigiu, Sector 1',
      
      // Cinema - Cinemas
      'cinema city afi': 'Cinema City AFI Cotroceni, Bulevardul Vasile Milea 4, Sector 6',
      'cinema city plaza': 'Cinema City Plaza România, Calea Vitan 55-59, Sector 4',
      'cinema city sun plaza': 'Cinema City Sun Plaza, Calea Văcărești 391, Sector 4',
      'cinema city parklake': 'Cinema City ParkLake, Strada Liviu Rebreanu 4, Sector 3',
      'movieplex baneasa': 'Movieplex Băneasa, Șoseaua Bucureștii Noi 42D, Sector 1',
      'movieplex promenada': 'Movieplex Promenada, Calea Floreasca 246B, Sector 1',
      'cinema elvire popesco': 'Cinema Elvire Popesco, Strada Ion Campineanu 21, Sector 1',
      'cinema studio': 'Cinema Studio, Strada Iuliu Barasch 12, Sector 3',
      'cinema patria': 'Cinema Patria, Bulevardul Magheru 12-14, Sector 1',
    },
    'ilfov': {
      // Școli - Schools
      'scoala gimnaziala buftea': 'Școala Gimnazială Buftea, Ilfov',
      'liceul teoretic otopeni': 'Liceul Teoretic Otopeni, Ilfov',
      'scoala mogosoaia': 'Școala Mogoșoaia, Ilfov',
      
      // Muzee - Museums
      'muzeul din buftea': 'Muzeul din Buftea, Ilfov',
      'muzeul din mogosoaia': 'Muzeul din Mogoșoaia, Ilfov',
      
      // Biblioteci - Libraries
      'biblioteca județeana ilfov': 'Biblioteca Județeană Ilfov, Buftea',
      'biblioteca otopeni': 'Biblioteca Otopeni, Ilfov',
    },
  };

  // 🏨 HOTELURI & CĂZĂRI - HOTELS & ACCOMMODATION
  static const Map<String, Map<String, String>> hotelLocations = {
    'bucuresti': {
      // Hoteluri 5 stele - 5 Star Hotels
      'hotel intercontinental': 'Hotel Intercontinental, Bulevardul Nicolae Bălcescu 4, Sector 1',
      'hotel athenee palace': 'Hotel Athenee Palace Hilton, Strada Episcopiei 1-3, Sector 1',
      'hotel radisson blu': 'Radisson Blu Hotel, Strada Calea Victoriei 63-81, Sector 1',
      'hotel novotel': 'Novotel Bucharest City Centre, Strada Calea Victoriei 37B, Sector 1',
      'hotel jw marriott': 'JW Marriott Bucharest Grand Hotel, Calea 13 Septembrie 90, Sector 5',
      
      // Hoteluri 4 stele - 4 Star Hotels
      'hotel ramada': 'Ramada Bucharest City Centre, Strada Strada Lipscani 89, Sector 3',
      'hotel hilton garden inn': 'Hilton Garden Inn Bucharest Old Town, Strada Doamnei 12, Sector 3',
      'hotel grand hotel continental': 'Grand Hotel Continental, Strada Strada Lipscani 4, Sector 3',
      'hotel cismigiu': 'Hotel Cismigiu, Bulevardul Regina Elisabeta 38, Sector 5',
      'hotel crystal palace': 'Crystal Palace Hotel, Strada Slanic 2, Sector 1',
      'hotel howard johnson': 'Howard Johnson Grand Plaza, Calea Dorobanți 5-7, Sector 1',
      
      // Hosteluri - Hostels
      'hostel podstel': 'Podstel Bucharest, Strada Strada Lipscani 12, Sector 3',
      'hostel first hostel': 'First Hostel, Strada Strada Lipscani 15, Sector 3',
    },
    'ilfov': {
      // Hoteluri - Hotels
      'hotel baneasa': 'Hotel Băneasa, Ilfov',
      'hotel otopeni': 'Hotel Otopeni, Ilfov',
      'pensiunea din mogosoaia': 'Pensiunea din Mogoșoaia, Ilfov',
      
      // Complexe turistice - Tourist Complexes
      'complexul turistic buftea': 'Complexul turistic Buftea, Ilfov',
      'complexul turistic snagov': 'Complexul turistic Snagov, Ilfov',
    },
  };

  // 📮 OFICII POȘTALE - POST OFFICES
  static const Map<String, Map<String, String>> postalLocations = {
    'bucuresti': {
      // Sector 1
      'oficiul postal 1 amzei': 'Oficiul Poștal 1 Amzei, Bulevardul Dacia 58, Sector 1',
      'oficiul postal 2 floreasca': 'Oficiul Poștal 2 Floreasca, Piața Floreasca 1, Sector 1',
      'oficiul postal 3 aviatorilor': 'Oficiul Poștal 3 Aviatorilor, Bulevardul Aviatorilor 45, Sector 1',
      
      // Sector 2
      'oficiul postal 4 obor': 'Oficiul Poștal 4 Obor, Piața Obor 4, Sector 2',
      'oficiul postal 5 colentina': 'Oficiul Poștal 5 Colentina, Șoseaua Colentina 45, Sector 2',
      
      // Sector 3
      'oficiul postal 6 unirii': 'Oficiul Poștal 6 Unirii, Piața Unirii 16, Sector 3',
      'oficiul postal 7 vitan': 'Oficiul Poștal 7 Vitan, Calea Vitan 104, Sector 3',
      
      // Sector 4
      'oficiul postal 8 tineretului': 'Oficiul Poștal 8 Tineretului, Piața Tineretului 1, Sector 4',
      'oficiul postal 9 berceni': 'Oficiul Poștal 9 Berceni, Calea Berceni 15, Sector 4',
      
      // Sector 5
      'oficiul postal 10 cotroceni': 'Oficiul Poștal 10 Cotroceni, Bulevardul Eroilor 27, Sector 5',
      'oficiul postal 11 rahova': 'Oficiul Poștal 11 Rahova, Calea Rahovei 266, Sector 5',
      
      // Sector 6
      'oficiul postal 12 crangasi': 'Oficiul Poștal 12 Crângași, Piața Crângași 16, Sector 6',
      'oficiul postal 13 militari': 'Oficiul Poștal 13 Militari, Bulevardul Iuliu Maniu 245, Sector 6',
    },
    'ilfov': {
      'oficiul postal otopeni': 'Oficiul Poștal Otopeni, Calea București 50, Otopeni, Ilfov',
      'oficiul postal voluntari': 'Oficiul Poștal Voluntari, Strada Voluntarilor 10, Voluntari, Ilfov',
      'oficiul postal buftea': 'Oficiul Poștal Buftea, Strada Republicii 25, Buftea, Ilfov',
    },
  };

  // 🏦 SERVICII FINANCIARE - FINANCIAL SERVICES
  static const Map<String, Map<String, String>> financialLocations = {
    'bucuresti': {
      // Bănci - Banks
      'bcr central': 'Banca Comercială Română - Sediul Central, Strada Doamnei 10, Sector 3',
      'brd central': 'BRD - Groupe Société Générale, Piața Charles de Gaulle 1-3, Sector 1',
      'raiffeisen central': 'Raiffeisen Bank, Strada Strada Lipscani 1, Sector 3',
      'ing central': 'ING Bank, Strada Strada Lipscani 1, Sector 3',
      'unicredit central': 'UniCredit Bank, Strada Strada Lipscani 1, Sector 3',
      
      // Case de schimb - Exchange Offices
      'cec central': 'Casa de Economii și Consemnațiuni, Strada Doamnei 10, Sector 3',
      'banca transilvania central': 'Banca Transilvania, Strada Strada Lipscani 1, Sector 3',
      
      // Asigurări - Insurance
      'allianz central': 'Allianz Țiriac, Strada Strada Lipscani 1, Sector 3',
      'generali central': 'Generali România, Strada Strada Lipscani 1, Sector 3',
      'groupama central': 'Groupama Asigurări, Strada Strada Lipscani 1, Sector 3',
    },
    'ilfov': {
      // Bănci - Banks
      'bcr buftea': 'BCR Buftea, Ilfov',
      'brd otopeni': 'BRD Otopeni, Ilfov',
      'raiffeisen mogosoaia': 'Raiffeisen Mogoșoaia, Ilfov',
      
      // Case de schimb - Exchange Offices
      'cec buftea': 'CEC Buftea, Ilfov',
      'banca transilvania otopeni': 'Banca Transilvania Otopeni, Ilfov',
      
      // Asigurări - Insurance
      'allianz ilfov': 'Allianz Ilfov, Ilfov',
      'generali ilfov': 'Generali Ilfov, Ilfov',
    },
  };

  // 🚔 SERVICII PUBLICE - PUBLIC SERVICES
  static const Map<String, Map<String, String>> publicServiceLocations = {
    'bucuresti': {
      // Poliție - Police
      'politia municipiului bucuresti': 'Direcția Generală de Poliție a Municipiului București, Strada Ștefan cel Mare 12, Sector 2',
      'sectia 1 politie': 'Secția 1 Poliție, Strada General Gheorghe Manu 6-8, Sector 1',
      'sectia 2 politie': 'Secția 2 Poliție, Strada Barbu Văcărescu 164, Sector 2',
      'sectia 3 politie': 'Secția 3 Poliție, Bulevardul Unirii 55, Sector 3',
      'sectia 4 politie': 'Secția 4 Poliție, Strada Turnu Măgurele 80, Sector 4',
      'sectia 5 politie': 'Secția 5 Poliție, Strada Progresului 151, Sector 5',
      'sectia 6 politie': 'Secția 6 Poliție, Strada Luterana 2, Sector 1',
      'brigada rutiera': 'Brigada Rutieră București, Strada Ștefan cel Mare 12, Sector 2',
      'serviciul rutier sector 1': 'Serviciul Rutier Sector 1, Calea Victoriei 125, Sector 1',
      'serviciul rutier sector 2': 'Serviciul Rutier Sector 2, Bulevardul Lascăr Catargiu 15, Sector 1',
      'politia de frontiera': 'Inspectoratul General al Poliției de Frontieră, Strada Apolodor 17, Sector 5',
      'politia de frontiera otopeni': 'Poliția de Frontieră Otopeni, Calea București 224E, Otopeni, Ilfov',
      
      // Pompieri - Firefighters
      'isu bucuresti': 'Inspectoratul pentru Situații de Urgență București, Strada Făgărașului 12, Sector 3',
      'detasament pompieri victoriei': 'Detașament 1 Pompieri Victoriei, Calea Victoriei 190, Sector 1',
      'detasament pompieri floreasca': 'Detașament 2 Pompieri Floreasca, Strada Dr. Staicovici 35, Sector 1',
      'detasament pompieri colentina': 'Detașament 3 Pompieri Colentina, Șoseaua Colentina 78, Sector 2',
      'detasament pompieri berceni': 'Detașament 4 Pompieri Berceni, Strada Drumul Gazarului 51, Sector 4',
      'detasament pompieri dealul spirii': 'Detașament 5 Pompieri Dealul Spirii, Bulevardul Libertății 99, Sector 5',
      'detasament pompieri crangasi': 'Detașament 6 Pompieri Crângași, Strada Construcțiilor 15, Sector 6',
      'centrul smurd': 'Centrul SMURD București, Strada Făgărașului 12, Sector 3',
      'subcentrul smurd floreasca': 'Subcentrul SMURD Floreasca, Calea Floreasca 8, Sector 1',
      
      // Ambulanță - Ambulance
      'smurd bucuresti': 'SMURD București, Strada Strada Lipscani 1',
      'ambulanta bucuresti': 'Ambulanța București, Strada Strada Lipscani 1',
    },
    'ilfov': {
      // Poliție - Police
      'sectia de politie buftea': 'Secția de Poliție Buftea, Ilfov',
      'sectia de politie otopeni': 'Secția de Poliție Otopeni, Ilfov',
      'sectia de politie mogosoaia': 'Secția de Poliție Mogoșoaia, Ilfov',
      
      // Pompieri - Firefighters
      'sectia de pompieri buftea': 'Secția de Pompieri Buftea, Ilfov',
      'sectia de pompieri otopeni': 'Secția de Pompieri Otopeni, Ilfov',
      
      // Ambulanță - Ambulance
      'smurd ilfov': 'SMURD Ilfov, Ilfov',
      'ambulanta județeana ilfov': 'Ambulanța Județeană Ilfov, Ilfov',
    },
  };

  // 🎯 FUNCȚII DE CĂUTARE LOCAȚII - LOCATION SEARCH FUNCTIONS
  
  /// Caută locații după județ și categorie
  static List<String> searchLocationsByCounty(String county, String category, String query) {
    final results = <String>[];
    final lowerQuery = query.toLowerCase();
    
    Map<String, String>? categoryMap;
    
    switch (category) {
      case 'transport':
        categoryMap = transportLocations[county.toLowerCase()];
        break;
      case 'shopping':
        categoryMap = shoppingLocations[county.toLowerCase()];
        break;
      case 'restaurante':
        categoryMap = restaurantLocations[county.toLowerCase()];
        break;
      case 'sport':
        categoryMap = sportsLocations[county.toLowerCase()];
        break;
      case 'institutii':
        categoryMap = institutionLocations[county.toLowerCase()];
        break;
      case 'medical':
        categoryMap = medicalLocations[county.toLowerCase()];
        break;
      case 'educatie':
        categoryMap = educationLocations[county.toLowerCase()];
        break;
      case 'hoteluri':
        categoryMap = hotelLocations[county.toLowerCase()];
        break;
      case 'servicii':
        categoryMap = financialLocations[county.toLowerCase()];
        break;
      case 'public':
        categoryMap = publicServiceLocations[county.toLowerCase()];
        break;
      case 'posta':
      case 'postale':
        categoryMap = postalLocations[county.toLowerCase()];
        break;
    }
    
    if (categoryMap != null) {
      for (final entry in categoryMap.entries) {
        if (entry.key.contains(lowerQuery) || entry.value.toLowerCase().contains(lowerQuery)) {
          results.add('${entry.key}: ${entry.value}');
        }
      }
    }
    
    return results;
  }
  
  /// Obține toate locațiile dintr-o categorie pentru un județ
  static Map<String, String> getLocationsByCategory(String county, String category) {
    switch (category) {
      case 'transport':
        return transportLocations[county.toLowerCase()] ?? {};
      case 'shopping':
        return shoppingLocations[county.toLowerCase()] ?? {};
      case 'restaurante':
        return restaurantLocations[county.toLowerCase()] ?? {};
      case 'sport':
        return sportsLocations[county.toLowerCase()] ?? {};
      case 'institutii':
        return institutionLocations[county.toLowerCase()] ?? {};
      case 'medical':
        return medicalLocations[county.toLowerCase()] ?? {};
      case 'educatie':
        return educationLocations[county.toLowerCase()] ?? {};
      case 'hoteluri':
        return hotelLocations[county.toLowerCase()] ?? {};
      case 'servicii':
        return financialLocations[county.toLowerCase()] ?? {};
      case 'public':
        return publicServiceLocations[county.toLowerCase()] ?? {};
      case 'posta':
      case 'postale':
        return postalLocations[county.toLowerCase()] ?? {};
      default:
        return {};
    }
  }
  
  /// Obține toate categoriile disponibile
  static List<String> getAvailableCategories() {
    return [
      'transport',
      'shopping', 
      'restaurante',
      'sport',
      'institutii',
      'medical',
      'educatie',
      'hoteluri',
      'servicii',
      'public',
      'posta',
    ];
  }
  
  /// Obține toate județele disponibile
  static List<String> getAvailableCounties() {
    return ['bucuresti', 'ilfov'];
  }
  
  /// Caută locații în toate județele
  static List<String> searchAllLocations(String query) {
    final results = <String>[];
    
    for (final county in getAvailableCounties()) {
      for (final category in getAvailableCategories()) {
        final countyResults = searchLocationsByCounty(county, category, query);
        results.addAll(countyResults.map((result) => '[$county] $result'));
      }
    }
    
    return results;
  }
  
  /// Obține locațiile populare dintr-un județ
  static List<String> getPopularDestinationsInCounty(String county) {
    final popular = <String>[];
    
    // Adaugă locații populare din fiecare categorie
    final transport = getLocationsByCategory(county, 'transport');
    if (transport.isNotEmpty) {
      popular.addAll(transport.values.take(3));
    }
    
    final shopping = getLocationsByCategory(county, 'shopping');
    if (shopping.isNotEmpty) {
      popular.addAll(shopping.values.take(3));
    }
    
    final restaurants = getLocationsByCategory(county, 'restaurante');
    if (restaurants.isNotEmpty) {
      popular.addAll(restaurants.values.take(3));
    }
    
    return popular;
  }
  
  /// Obține toate locațiile dintr-un județ
  static Map<String, Map<String, String>> getAllLocationsInCounty(String county) {
    final allLocations = <String, Map<String, String>>{};
    
    for (final category in getAvailableCategories()) {
      final locations = getLocationsByCategory(county, category);
      if (locations.isNotEmpty) {
        allLocations[category] = locations;
      }
    }
    
    return allLocations;
  }

  // 🧠 SISTEMUL DE ÎNȚELEGERE NATURALĂ - NATURAL LANGUAGE UNDERSTANDING (NLU)
  
  /// Identifică intenția utilizatorului din comanda vocală
  static String? getCommandType(String input) {
    final lowerInput = input.toLowerCase();
    final isRomanianLocalContext = _isRomanianLocalContext(lowerInput);
    
    // Verifică toate tipurile de comenzi
    for (final entry in rideCommands.entries) {
      if (!isRomanianLocalContext &&
          _ambiguousDestinationCommandKeys.contains(entry.key)) {
        continue;
      }
      if (lowerInput.contains(entry.key)) return entry.value;
    }
    
    for (final entry in voiceCommands.entries) {
      if (lowerInput.contains(entry.key)) return entry.value;
    }
    
    for (final entry in paymentCommands.entries) {
      if (lowerInput.contains(entry.key)) return entry.value;
    }
    
    for (final entry in emergencyCommands.entries) {
      if (lowerInput.contains(entry.key)) return entry.value;
    }
    
    for (final entry in appCommands.entries) {
      if (lowerInput.contains(entry.key)) return entry.value;
    }
    
    for (final entry in multilingualCommands.entries) {
      if (lowerInput.contains(entry.key)) return entry.value;
    }
    
    return null; // Comandă necunoscută
  }

  /// Obține sugestii pentru input parțial
  static List<String> getSuggestions(String partialInput) {
    final lowerInput = partialInput.toLowerCase();
    final suggestions = <String>[];
    
    // Adaugă sugestii din toate categoriile
    for (final key in rideCommands.keys) {
      if (key.contains(lowerInput)) suggestions.add(key);
    }
    
    for (final key in voiceCommands.keys) {
      if (key.contains(lowerInput)) suggestions.add(key);
    }
    
    for (final key in paymentCommands.keys) {
      if (key.contains(lowerInput)) suggestions.add(key);
    }
    
    // Returnează primele 5 sugestii
    return suggestions.take(5).toList();
  }

  /// Obține răspunsul AI pentru o cheie dată
  static String getResponse(String key, [Map<String, String>? variables]) {
    final response = aiResponses[key];
    if (response == null) return 'Nu am înțeles comanda. Poți să repeți?';
    
    if (variables != null) {
      String result = response;
      for (final entry in variables.entries) {
        result = result.replaceAll('{${entry.key}}', entry.value);
      }
      return result;
    }
    
    return response;
  }

  /// Obține stilul vocal pentru un nume dat
  static Map<String, dynamic> getVoiceStyle(String styleName) {
    return voiceStyles[styleName] ?? voiceStyles['friendly']!;
  }

  // 🎯 SISTEMUL AVANSAT DE ÎNȚELEGERE INTENȚII - ADVANCED INTENT RECOGNITION
  
  /// Identifică intenția principală din comanda vocală
  static String recognizeIntent(String command) {
    final lowerCommand = command.toLowerCase();
    
    // 🚗 INTENȚIA DE REZERVARE CURSA
    if (_containsAny(lowerCommand, [
      'vreau să merg la',
      'du-mă la',
      'vreau să comand o cursă la',
      'vreau la',
      'vreau să mă duc la',
      'caut o cursă la',
      'rezervă o cursă la',
      'vreau să fac o comandă',
      'comandă cursă',
      'rezervare cursă',
      'vreau să plec la',
      'să merg la',
      'să mă duc la',
    ])) {
      return 'BOOK_RIDE';
    }
    
    // 🚇 INTENȚIA DE CĂUTARE TRANSPORT
    if (_containsAny(lowerCommand, [
      'care este cea mai apropiată stație de metrou',
      'unde este cea mai apropiată stație',
      'stația de metrou cea mai apropiată',
      'gara cea mai apropiată',
      'autobuzul cel mai apropiat',
      'tramvaiul cel mai apropiat',
      'stația cea mai apropiată',
      'transportul cel mai apropiat',
      'metroul cel mai apropiat',
      'găsește stația',
      'caut stația',
      'unde este stația',
    ])) {
      return 'FIND_NEAREST_TRANSPORT';
    }
    
    // 📍 INTENȚIA DE LOCALIZARE
    if (_containsAny(lowerCommand, [
      'vreau la aeroport',
      'unde este',
      'caut',
      'arătă-mi',
      'localizează',
      'găsește',
      'poziția',
      'locația',
      'adresa',
      'coordonatele',
      'pe hartă',
      'în zonă',
    ])) {
      return 'LOCATE_PLACE';
    }
    
    // 🕐 INTENȚIA DE PROGRAMARE
    if (_containsAny(lowerCommand, [
      'acum',
      'imediat',
      'peste 10 minute',
      'peste o oră',
      'mâine',
      'azi',
      'programează',
      'planifică',
      'rezervă pentru',
      'la ce oră',
      'când',
      'program',
    ])) {
      return 'SCHEDULE_RIDE';
    }
    
    // 💰 INTENȚIA DE PLATĂ
    if (_containsAny(lowerCommand, [
      'cât costă',
      'prețul',
      'tariful',
      'plătesc cu',
      'metoda de plată',
      'card',
      'numerar',
      'voucher',
      'cod promoțional',
      'factura',
      'chitanța',
      'plata',
    ])) {
      return 'PAYMENT_INFO';
    }
    
    // 🚨 INTENȚIA DE URGENȚĂ
    if (_containsAny(lowerCommand, [
      'ajutor',
      'urgență',
      'pericol',
      'accident',
      'bolnav',
      'rănit',
      'cheamă ajutor',
      'sosire rapidă',
      'imediat',
      'rapid',
      'urgent',
      'sănătate',
    ])) {
      return 'EMERGENCY';
    }
    
    // 🗣️ INTENȚIA DE CONTROL VOCAL
    if (_containsAny(lowerCommand, [
      'hey nabour',
      'ascultă',
      'oprește',
      'taci',
      'mai tare',
      'mai încet',
      'mai rapid',
      'mai lent',
      'arată harta',
      'ascunde harta',
      'mărește',
      'micșorează',
    ])) {
      return 'VOICE_CONTROL';
    }
    
    // 📱 INTENȚIA DE CONTROL APLICAȚIE
    if (_containsAny(lowerCommand, [
      'meniu principal',
      'setări',
      'istoric',
      'profil',
      'ajutor',
      'deschide',
      'închide',
      'schimbă',
      'resetează',
      'configurare',
      'preferințe',
    ])) {
      return 'APP_CONTROL';
    }
    
    // 🌍 INTENȚIA MULTILINGVĂ
    if (_containsAny(lowerCommand, [
      'schimbă limba',
      'limba română',
      'limba engleză',
      'tradu în română',
      'tradu în engleză',
      'english',
      'română',
      'limba',
      'traducere',
      'idiom',
      'language',
    ])) {
      return 'MULTILINGUAL';
    }
    
    // 🤝 INTENȚIA DE CONVERSAȚIE POLITICOASĂ
    if (_containsAny(lowerCommand, [
      'bună ziua',
      'bună dimineața',
      'bună seara',
      'salut',
      'hello',
      'hi',
      'mulțumesc',
      'vă mulțumesc',
      'mersi',
      'thank you',
      'unde doriți să mergeți',
      'unde ați dori să mergeți',
      'care este destinația',
      'unde vă duc',
      'dacă doriți pot să caut alt tip de autoturism',
      'pot să vă ofer o altă opțiune',
      'pot să vă ajut cu altceva',
      'mai aveți nevoie de ceva',
      'este în regulă pentru dumneavoastră',
      'perfect',
      'foarte bine',
      'excelent',
      'în regulă',
      'îmi pare rău',
      'scuzați-mă',
      'scuze',
      'la revedere',
      'pe curând',
      'drum bun',
      'călătorie plăcută',
      'să aveți o zi frumoasă',
    ])) {
      return 'POLITE_CONVERSATION';
    }
    
    return 'UNKNOWN_INTENT';
  }
  
  /// Extrage entitățile (destinația, timpul, etc.) din comandă
  static Map<String, String> extractEntities(String command) {
    final entities = <String, String>{};
    final lowerCommand = command.toLowerCase();
    
    // 🎯 Extrage destinația
    final destinationPatterns = [
      'la ',
      'până la ',
      'spre ',
      'către ',
      'în ',
      'pe ',
    ];
    
    for (final pattern in destinationPatterns) {
      if (lowerCommand.contains(pattern)) {
        final startIndex = lowerCommand.indexOf(pattern) + pattern.length;
        final endIndex = lowerCommand.indexOf(' ', startIndex);
        if (endIndex == -1) {
          entities['destination'] = command.substring(startIndex);
        } else {
          entities['destination'] = command.substring(startIndex, endIndex);
        }
        break;
      }
    }
    
    // 🕐 Extrage timpul
    final timePatterns = [
      'acum',
      'imediat',
      'peste 10 minute',
      'peste o oră',
      'mâine',
      'azi',
      'dimineața',
      'prânzul',
      'seara',
      'noaptea',
    ];
    
    for (final pattern in timePatterns) {
      if (lowerCommand.contains(pattern)) {
        entities['time'] = pattern;
        break;
      }
    }
    
    // 💰 Extrage metoda de plată
    final paymentPatterns = [
      'card',
      'numerar',
      'bani',
      'voucher',
      'cod promoțional',
      'paypal',
      'apple pay',
      'google pay',
    ];
    
    for (final pattern in paymentPatterns) {
      if (lowerCommand.contains(pattern)) {
        entities['payment_method'] = pattern;
        break;
      }
    }
    
    // 🤝 Extrage tipul de conversație politicoasă
    if (_containsAny(lowerCommand, ['bună ziua', 'bună dimineața', 'bună seara', 'salut', 'hello', 'hi'])) {
      entities['conversation_type'] = 'greeting';
    } else if (_containsAny(lowerCommand, ['mulțumesc', 'vă mulțumesc', 'mersi', 'thank you'])) {
      entities['conversation_type'] = 'thanks';
    } else if (_containsAny(lowerCommand, ['unde doriți să mergeți', 'unde ați dori să mergeți', 'care este destinația', 'unde vă duc'])) {
      entities['conversation_type'] = 'ask_destination';
    } else if (_containsAny(lowerCommand, ['dacă doriți pot să caut alt tip', 'pot să vă ofer o altă opțiune', 'pot să vă ajut cu altceva'])) {
      entities['conversation_type'] = 'offer_help';
    } else if (_containsAny(lowerCommand, ['perfect', 'foarte bine', 'excelent', 'în regulă'])) {
      entities['conversation_type'] = 'confirm';
    } else if (_containsAny(lowerCommand, ['îmi pare rău', 'scuzați-mă', 'scuze'])) {
      entities['conversation_type'] = 'apology';
    } else if (_containsAny(lowerCommand, ['la revedere', 'pe curând', 'drum bun', 'călătorie plăcută'])) {
      entities['conversation_type'] = 'goodbye';
    }
    
    return entities;
  }
  
  /// Procesează comanda vocală și returnează răspunsul
  static Map<String, dynamic> processVoiceCommand(String command) {
    final intent = recognizeIntent(command);
    final entities = extractEntities(command);
    
    return {
      'intent': intent,
      'entities': entities,
      'confidence': _calculateConfidence(command, intent),
      'suggestions': _getIntentSuggestions(intent),
      'response': _generateResponse(intent, entities),
    };
  }
  
  /// Calculează încrederea în recunoașterea intenției
  static double _calculateConfidence(String command, String intent) {
    if (intent == 'UNKNOWN_INTENT') return 0.0;
    
    // Logica de calcul a încrederii
    double confidence = 0.5; // Bază
    
    // Bonus pentru comenzi clare
    if (command.length > 10) confidence += 0.2;
    if (command.contains('la ')) confidence += 0.1;
    if (command.contains('vreau')) confidence += 0.1;
    if (command.contains('du-mă')) confidence += 0.1;
    
    return confidence.clamp(0.0, 1.0);
  }
  
  /// Obține sugestii pentru o intenție
  static List<String> _getIntentSuggestions(String intent) {
    switch (intent) {
      case 'BOOK_RIDE':
        return [
          'Specifică destinația: "Vreau să merg la Mall Băneasa"',
          'Specifică timpul: "Vreau să merg acum la universitate"',
          'Specifică metoda de plată: "Vreau să merg cu cardul la aeroport"',
        ];
      case 'FIND_NEAREST_TRANSPORT':
        return [
          'Specifică tipul de transport: "Care este cea mai apropiată stație de metrou?"',
          'Specifică zona: "Unde este cea mai apropiată gară în centru?"',
        ];
      case 'LOCATE_PLACE':
        return [
          'Specifică locația: "Unde este Mall AFI?"',
          'Specifică zona: "Caut un restaurant în centru"',
        ];
      case 'POLITE_CONVERSATION':
        return [
          'Răspund la salutare: "Bună ziua! Cu ce vă pot ajuta?"',
          'Confirmă serviciul: "Desigur, vă pot ajuta cu plăcere!"',
          'Ofer ajutor suplimentar: "Mai aveți nevoie de ceva?"',
        ];
      default:
        return ['Poți să repeți comanda mai clar?'];
    }
  }
  
  /// Generează răspunsul pentru o intenție
  static String _generateResponse(String intent, Map<String, String> entities) {
    switch (intent) {
      case 'BOOK_RIDE':
        final destination = entities['destination'];
        if (destination != null) {
          return 'Înțeleg că vrei să mergi la $destination. Să verific disponibilitatea...';
        }
        return 'Înțeleg că vrei să rezervi o cursă. Unde vrei să mergi?';
        
      case 'FIND_NEAREST_TRANSPORT':
        return 'Să găsesc cea mai apropiată stație de transport pentru tine...';
        
      case 'LOCATE_PLACE':
        final destination = entities['destination'];
        if (destination != null) {
          return 'Să localizez $destination pe hartă...';
        }
        return 'Ce locație vrei să localizez?';
        
      case 'SCHEDULE_RIDE':
        final time = entities['time'];
        if (time != null) {
          return 'Înțeleg că vrei să programezi o cursă pentru $time. Să verific opțiunile...';
        }
        return 'Pentru ce oră vrei să programezi cursa?';
        
      case 'PAYMENT_INFO':
        return 'Să verific informațiile de plată pentru tine...';
        
      case 'EMERGENCY':
        return 'Înțeleg că ai o urgență. Să te ajut imediat...';
        
      case 'VOICE_CONTROL':
        return 'Înțeleg comanda de control vocal. Să o execut...';
        
      case 'APP_CONTROL':
        return 'Înțeleg comanda de control a aplicației. Să o execut...';
        
      case 'MULTILINGUAL':
        return 'Înțeleg că vrei să schimbi limba. Să o fac...';
        
      case 'POLITE_CONVERSATION':
        // Analizăm entitățile pentru a determina tipul de conversație politicoasă
        final conversationType = entities['conversation_type'] ?? 'general';
        
        switch (conversationType) {
          case 'greeting':
            return 'Bună ziua! Sunt asistentul Nabour. Cu ce vă pot ajuta?';
          case 'thanks':
            return 'Cu mare plăcere! Sunt aici să vă ajut oricând aveți nevoie.';
          case 'ask_destination':
            return 'Vă rog să-mi spuneți destinația dorită și vă voi găsi cea mai bună opțiune.';
          case 'offer_help':
            return 'Desigur! Vă pot ajuta să găsiți cea mai potrivită opțiune pentru dumneavoastră.';
          case 'confirm':
            return 'Excelent! Să procedez cu confirmarea și să finalizez rezervarea.';
          case 'apology':
            return 'Nu vă faceți griji deloc! Să vedem cum vă pot ajuta mai bine.';
          case 'goodbye':
            return 'La revedere! Vă doresc călătorie plăcută și să aveți o zi frumoasă!';
          default:
            return 'Cu plăcere! Cu ce vă pot ajuta astăzi?';
        }
        
      default:
        return 'Nu am înțeles comanda. Poți să repeți mai clar?';
    }
  }
  
  /// Helper method pentru verificarea multiplelor pattern-uri
  static bool _containsAny(String text, List<String> patterns) {
    for (final pattern in patterns) {
      if (text.contains(pattern)) return true;
    }
    return false;
  }

  static bool _isRomanianLocalContext(String text) {
    const localSignals = <String>{
      'romania',
      'românia',
      'bucuresti',
      'bucurești',
      'ilfov',
      'otopeni',
      'piata unirii',
      'piața unirii',
      'gara de nord',
      'henri coanda',
      'henri coandă',
    };
    for (final signal in localSignals) {
      if (text.contains(signal)) return true;
    }
    return false;
  }

  static const Set<String> _ambiguousDestinationCommandKeys = <String>{
    'universitate',
    'centru',
    'aeroport',
    'gara',
    'mall',
    'spital',
    'bancă',
    'restaurant',
    'benzinărie',
    'farmacie',
  };

}
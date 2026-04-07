// 🗺️ Bază de date locală cu locații importante din București și Ilfov
// Această bază de date permite recunoașterea rapidă a destinațiilor comune
// fără a necesita apeluri API la geocoding sau Gemini AI

class BucharestLocation {
  final String name;
  final double latitude;
  final double longitude;
  final String category;
  final List<String> aliases; // Variante de nume pentru căutare

  const BucharestLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.category,
    this.aliases = const [],
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'category': category,
      };
}

class BucharestLocationsDatabase {
  static final Map<String, BucharestLocation> _locations = {};

  /// Inițializează baza de date cu toate locațiile
  static void initialize() {
    if (_locations.isNotEmpty) return; // Deja inițializată

    // 🏥 SPITALE
    _addHospital('Spitalul Clinic de Urgență Floreasca', 44.4500, 26.1080, [
      'Floreasca', 'Spitalul Floreasca', 'Spital Floreasca', 'Floreasca Hospital',
    ]);
    _addHospital('Spitalul Clinic Fundeni', 44.4200, 26.0900, [
      'Fundeni', 'Spitalul Fundeni', 'Spital Fundeni', 'Fundeni Hospital',
    ]);
    _addHospital('Spitalul Colțea', 44.4320, 26.1000, [
      'Colțea', 'Spitalul Colțea', 'Spital Colțea', 'Colțea Hospital',
    ]);
    _addHospital('Spitalul Universitar de Urgență București', 44.4350, 26.1020, [
      'Spitalul de Urgență', 'Spital Urgență', 'SUUB', 'Spitalul Universitar Urgență',
    ]);
    _addHospital('Spitalul Pantelimon', 44.4500, 26.1200, [
      'Pantelimon', 'Spitalul Pantelimon', 'Spital Pantelimon',
    ]);
    _addHospital('Spitalul Elias', 44.4200, 26.1100, [
      'Elias', 'Spitalul Elias', 'Spital Elias', 'Elias Hospital',
    ]);
    _addHospital('Spitalul Militar Central', 44.4400, 26.0950, [
      'Spitalul Militar', 'Spital Militar', 'Militar Central',
    ]);
    _addHospital('Spitalul Monza', 44.4600, 26.1050, [
      'Monza', 'Spitalul Monza', 'Spital Monza',
    ]);
    _addHospital('Spitalul Sanador', 44.4300, 26.0850, [
      'Sanador', 'Spitalul Sanador', 'Spital Sanador',
    ]);
    _addHospital('Spitalul Medlife', 44.4400, 26.1000, [
      'Medlife', 'Spitalul Medlife', 'Spital Medlife',
    ]);

    // 🚂 GĂRI
    _addStation('Gara de Nord', 44.4478, 26.0758, [
      'Gara Nord', 'Gara de Nord București', 'Nord', 'Gară Nord',
      // ✅ NOU: Alias-uri în engleză
      'North Station', 'Bucharest North Station', 'Train Station', 'Railway Station',
    ]);
    _addStation('Gara Obor', 44.4500, 26.1300, [
      'Gara Obor', 'Obor', 'Gară Obor',
    ]);
    _addStation('Gara Basarab', 44.4480, 26.0700, [
      'Gara Basarab', 'Basarab', 'Gară Basarab',
    ]);
    _addStation('Gara Progresul', 44.4000, 26.1000, [
      'Gara Progresul', 'Progresul', 'Gară Progresul',
    ]);
    _addStation('Gara Băneasa', 44.5100, 26.0800, [
      'Gara Băneasa', 'Băneasa', 'Gară Băneasa',
    ]);

    // 🚌 AUTOGĂRI
    _addStation('Autogara Filaret', 44.4200, 26.1050, [
      'Autogara Filaret', 'Filaret', 'Autogară Filaret', 'Gara Filaret',
    ]);
    _addStation('Autogara Băneasa', 44.5100, 26.0800, [
      'Autogara Băneasa', 'Autogară Băneasa',
    ]);
    _addStation('Autogara Militari', 44.4400, 26.0200, [
      'Autogara Militari', 'Autogară Militari',
    ]);

    // 🚇 STAȚII DE METROU (Principale)
    // Linia M1
    _addStation('Stația Piața Victoriei', 44.4518, 26.0970, [
      'Piața Victoriei', 'Piata Victoriei', 'Victoriei', 'Metrou Victoriei',
    ]);
    _addStation('Stația Piața Unirii', 44.4268, 26.1025, [
      'Piața Unirii', 'Piata Unirii', 'Unirii', 'Metrou Unirii',
    ]);
    _addStation('Stația Universitate', 44.4355, 26.1008, [
      'Universitate', 'Stația Universitate', 'Metrou Universitate',
    ]);
    _addStation('Stația Gara de Nord', 44.4478, 26.0758, [
      'Metrou Gara de Nord', 'Metrou Nord',
    ]);
    _addStation('Stația Dristor', 44.4200, 26.1200, [
      'Dristor', 'Stația Dristor', 'Metrou Dristor',
    ]);
    _addStation('Stația Pipera', 44.4800, 26.1000, [
      'Pipera', 'Stația Pipera', 'Metrou Pipera',
    ]);
    _addStation('Stația Pantelimon', 44.4500, 26.1200, [
      'Pantelimon Metro', 'Metrou Pantelimon',
    ]);
    _addStation('Stația Crângași', 44.4400, 26.0300, [
      'Crângași', 'Stația Crângași', 'Metrou Crângași',
    ]);
    _addStation('Stația Berceni', 44.4000, 26.0800, [
      'Berceni', 'Stația Berceni', 'Metrou Berceni',
    ]);
    _addStation('Stația Eroilor', 44.4400, 26.0900, [
      'Eroilor', 'Stația Eroilor', 'Metrou Eroilor',
    ]);
    _addStation('Stația Piața Romană', 44.4400, 26.1000, [
      'Piața Romană', 'Piata Romana', 'Metrou Romană',
    ]);
    _addStation('Stația Obor', 44.4500, 26.1300, [
      'Obor', 'Stația Obor', 'Metrou Obor',
    ]);
    _addStation('Stația Titan', 44.4100, 26.1100, [
      'Titan', 'Stația Titan', 'Metrou Titan',
    ]);
    _addStation('Stația Aviatorilor', 44.4600, 26.0800, [
      'Aviatorilor', 'Stația Aviatorilor', 'Metrou Aviatorilor',
    ]);
    _addStation('Stația Aurel Vlaicu', 44.4700, 26.0900, [
      'Aurel Vlaicu', 'Stația Aurel Vlaicu', 'Metrou Aurel Vlaicu',
    ]);
    _addStation('Stația Piața Sudului', 44.4000, 26.1000, [
      'Piața Sudului', 'Piata Sudului', 'Metrou Sudului',
    ]);

    // 🏛️ MINISTERE
    _addGovernment('Ministerul Afacerilor Externe', 44.4500, 26.0950, [
      'MAE', 'Ministerul Externe', 'Minister Externe', 'Externe',
    ]);
    _addGovernment('Ministerul Sănătății', 44.4400, 26.1000, [
      'Ministerul Sănătății', 'Minister Sănătate', 'MS', 'Sănătate',
    ]);
    _addGovernment('Ministerul Educației', 44.4350, 26.1020, [
      'Ministerul Educației', 'Minister Educație', 'MEC', 'Educație',
    ]);
    _addGovernment('Ministerul Finanțelor', 44.4300, 26.0980, [
      'Ministerul Finanțelor', 'Minister Finanțe', 'MF', 'Finanțe',
    ]);
    _addGovernment('Ministerul Transporturilor', 44.4400, 26.0950, [
      'Ministerul Transporturilor', 'Minister Transport', 'MT', 'Transport',
    ]);
    _addGovernment('Ministerul Justiției', 44.4320, 26.1000, [
      'Ministerul Justiției', 'Minister Justiție', 'MJ', 'Justiție',
    ]);
    _addGovernment('Ministerul Apărării', 44.4500, 26.0900, [
      'Ministerul Apărării', 'Minister Apărare', 'MApN', 'Apărare',
    ]);
    _addGovernment('Ministerul Economiei', 44.4300, 26.1000, [
      'Ministerul Economiei', 'Minister Economie', 'ME', 'Economie',
    ]);
    _addGovernment('Palatul Victoria', 44.4518, 26.0970, [
      'Palatul Victoria', 'Palat Victoria', 'Guvern', 'Primăria Generală',
    ]);

    // 🏛️ AMBASADE (Principale)
    _addEmbassy('Ambasada SUA', 44.4600, 26.0800, [
      'Ambasada SUA', 'Ambasada Americii', 'US Embassy', 'SUA',
    ]);
    _addEmbassy('Ambasada Germaniei', 44.4500, 26.0900, [
      'Ambasada Germaniei', 'Ambasada Germană', 'German Embassy', 'Germania',
    ]);
    _addEmbassy('Ambasada Franței', 44.4400, 26.1000, [
      'Ambasada Franței', 'Ambasada Franceză', 'French Embassy', 'Franța',
    ]);
    _addEmbassy('Ambasada Marii Britanii', 44.4350, 26.1020, [
      'Ambasada Marii Britanii', 'Ambasada Britanică', 'UK Embassy', 'Marea Britanie',
    ]);
    _addEmbassy('Ambasada Italiei', 44.4300, 26.0980, [
      'Ambasada Italiei', 'Ambasada Italiană', 'Italian Embassy', 'Italia',
    ]);
    _addEmbassy('Ambasada Spaniei', 44.4400, 26.0950, [
      'Ambasada Spaniei', 'Ambasada Spaniolă', 'Spanish Embassy', 'Spania',
    ]);

    // 🎓 UNIVERSITĂȚI
    _addUniversity('Universitatea din București', 44.4355, 26.1008, [
      'Universitatea București', 'UB', 'Universitate', 'Facultatea de Litere',
    ]);
    _addUniversity('Universitatea Politehnica București', 44.4400, 26.0500, [
      'Politehnica', 'UPB', 'Politehnică', 'Universitatea Politehnică',
    ]);
    _addUniversity('Universitatea de Medicină și Farmacie Carol Davila', 44.4320, 26.1000, [
      'Carol Davila', 'UMFCD', 'Medicină', 'Farmacie',
    ]);
    _addUniversity('Academia de Studii Economice', 44.4350, 26.1020, [
      'ASE', 'Academia Economică', 'Studii Economice', 'Economică',
    ]);
    _addUniversity('Universitatea Națională de Arte', 44.4300, 26.0980, [
      'UNArte', 'Arte', 'Universitatea de Arte',
    ]);

    // 🛍️ MALL-URI
    _addMall('Mall Băneasa', 44.5072, 26.0769, [
      'Băneasa', 'Mall Băneasa', 'Shopping Băneasa',
      // ✅ NOU: Alias-uri în engleză
      'Baneasa Mall', 'Shopping Baneasa',
    ]);
    _addMall('Plaza Romania', 44.4486, 26.0188, [
      'Plaza Romania', 'Plaza România', 'Shopping Plaza',
      // ✅ NOU: Alias-uri în engleză
      'Plaza Romania Mall', 'Shopping Plaza Romania',
    ]);
    _addMall('AFI Palace Cotroceni', 44.4300, 26.0500, [
      'AFI Cotroceni', 'AFI Palace', 'Cotroceni', 'Mall Cotroceni',
      // ✅ NOU: Alias-uri în engleză
      'AFI Palace', 'AFI Mall', 'Cotroceni Mall',
    ]);
    _addMall('Mega Mall', 44.4400, 26.0800, [
      'Mega Mall', 'MegaMall', 'Shopping Mega',
    ]);
    _addMall('ParkLake', 44.4000, 26.0600, [
      'ParkLake', 'Park Lake', 'Shopping ParkLake',
    ]);
    _addMall('Sun Plaza', 44.4200, 26.0700, [
      'Sun Plaza', 'SunPlaza', 'Shopping Sun',
    ]);
    _addMall('Promenada Mall', 44.4500, 26.0900, [
      'Promenada', 'Promenada Mall', 'Shopping Promenada',
    ]);
    _addMall('București Mall', 44.4300, 26.1000, [
      'București Mall', 'Bucharest Mall', 'Shopping București',
    ]);

    // ✈️ AEROPORTURI
    _addAirport('Aeroportul Henri Coandă', 44.5721, 26.0691, [
      'Aeroport Otopeni', 'Otopeni', 'Aeroport', 'Henri Coandă', 'Henri Coanda',
      'Aeroportul Otopeni', 'Aeroport București', 'București Airport',
      // ✅ NOU: Alias-uri în engleză
      'Airport', 'Bucharest Airport', 'Henri Coanda Airport', 'Otopeni Airport',
      'Airport Henri Coanda', 'Bucharest Henri Coanda Airport',
    ]);
    _addAirport('Aeroportul Băneasa', 44.5030, 26.0780, [
      'Aeroport Băneasa', 'Băneasa Airport', 'Aurel Vlaicu',
    ]);

    // 🏛️ LOCAȚII IMPORTANTE
    _addLandmark('Piața Universității', 44.4355, 26.1008, [
      'Universitate', 'Piața Universității', 'Piata Universitatii',
      // ✅ NOU: Alias-uri în engleză
      'University Square', 'University Square Bucharest',
    ]);
    _addLandmark('Aleea Barajul Dunării', 44.4200, 26.1100, [
      'Barajul Dunării', 'Aleea Barajul Dunării', 'Barajul Dunarii', 'Aleea Barajul Dunarii',
      'Baraj Dunării', 'Baraj Dunarii', 'Dunării', 'Dunarii',
    ]);
    _addLandmark('Aleea Barajul Sadului', 44.4150, 26.1050, [
      'Barajul Sadului', 'Aleea Barajul Sadului', 'Barajul Sadului', 'Aleea Barajul Sadului',
      'Baraj Sadului', 'Sadului', 'Baraj Sad',
    ]);
    _addLandmark('Centrul Vechi', 44.4323, 26.0999, [
      'Centrul Vechi', 'Centru Vechi', 'Old Town', 'Lipscani',
      // ✅ NOU: Alias-uri în engleză
      'Old Town Bucharest', 'Historic Center', 'City Center', 'Downtown',
    ]);
    _addLandmark('Herastrau Park', 44.4684, 26.0831, [
      'Herăstrău', 'Herastrau', 'Parcul Herăstrău', 'Parcul Herastrau',
    ]);
    _addLandmark('Parcul Cismigiu', 44.4320, 26.0950, [
      'Cismigiu', 'Parcul Cismigiu', 'Cismigiu Park',
    ]);
    _addLandmark('Parcul Carol', 44.4100, 26.1000, [
      'Parcul Carol', 'Carol Park', 'Carol I',
    ]);
    _addLandmark('Arcul de Triumf', 44.4670, 26.0780, [
      'Arcul de Triumf', 'Arcul Triumf', 'Triumf',
      // ✅ NOU: Alias-uri în engleză
      'Triumphal Arch', 'Arch of Triumph', 'Triumph Arch',
    ]);
    
    // ✅ NOU: Ateneul Român
    _addLandmark('Ateneul Român', 44.4412, 26.0979, [
      'Ateneul Român', 'Ateneul', 'Ateneul Roman',
      // ✅ NOU: Alias-uri în engleză
      'Romanian Athenaeum', 'Athenaeum', 'Bucharest Athenaeum',
    ]);
    
    // ✅ NOU: Piața Revoluției
    _addLandmark('Piața Revoluției', 44.4411, 26.0975, [
      'Piața Revoluției', 'Piata Revolutiei', 'Revoluției', 'Revolutiei',
      // ✅ NOU: Alias-uri în engleză
      'Revolution Square', 'Revolution Square Bucharest',
    ]);
    
    // ✅ NOU: Hanul lui Manuc (Strada Franceză, Centrul Vechi)
    _addLandmark('Hanul lui Manuc', 44.4323, 26.0999, [
      'Hanul lui Manuc', 'Han Manuc', 'Manuc', 'Hanul Manuc',
      // ✅ NOU: Alias-uri în engleză
      'Manuc\'s Inn', 'Manuc Inn', 'Manuc\'s Tavern', 'Manuc\'s Hotel',
    ]);
    
    // ✅ NOU: Templul Coral (Strada Sfânta Vineri)
    _addLandmark('Templul Coral', 44.4320, 26.0995, [
      'Templul Coral', 'Templul Coral București', 'Coral', 'Sinagoga Coral',
      // ✅ NOU: Alias-uri în engleză
      'Choral Temple', 'Coral Temple', 'Great Synagogue Bucharest', 'Bucharest Choral Temple',
    ]);
    
    // ✅ NOU: Palatul CEC (Calea Victoriei)
    _addLandmark('Palatul CEC', 44.4320, 26.1000, [
      'Palatul CEC', 'CEC', 'Palat CEC', 'Banca CEC', 'CEC București',
      // ✅ NOU: Alias-uri în engleză
      'CEC Palace', 'CEC Bank', 'CEC Bank Palace', 'CEC Building',
    ]);
    
    // ✅ NOU: Memorialul Holocaustului (Strada Ion Brezoianu)
    _addLandmark('Memorialul Holocaustului', 44.4320, 26.1005, [
      'Memorialul Holocaustului', 'Memorial Holocaust', 'Holocaust', 'Memorialul Evreiesc',
      // ✅ NOU: Alias-uri în engleză
      'Holocaust Memorial', 'Holocaust Memorial Bucharest', 'Memorial of the Holocaust', 'Jewish Memorial',
    ]);
    
    // ✅ NOU: Cimitirul Bellu (Șoseaua Olteniței)
    _addLandmark('Cimitirul Bellu', 44.4000, 26.1000, [
      'Cimitirul Bellu', 'Bellu', 'Cimitir Bellu', 'Cimitirul Bellu București', 'Bellu Cemetery',
      // ✅ NOU: Alias-uri în engleză
      'Bellu Cemetery', 'Bellu Cemetery Bucharest', 'Bellu Graveyard', 'Bellu Memorial Cemetery',
    ]);
    
    // ✅ NOU: Palatul Cercului Militar Național (Calea Victoriei)
    _addLandmark('Palatul Cercului Militar Național', 44.4400, 26.0950, [
      'Palatul Cercului Militar Național', 'Cercul Militar', 'Palatul Militar', 'Cercul Militar Național',
      // ✅ NOU: Alias-uri în engleză
      'National Military Circle Palace', 'Military Circle Palace', 'National Military Circle', 'Military Palace',
    ]);
    
    // ✅ NOU: Foișorul de Foc (Parcul Carol)
    _addLandmark('Foișorul de Foc', 44.4100, 26.1000, [
      'Foișorul de Foc', 'Foisorul de Foc', 'Foișor', 'Foisor', 'Foișorul de Foc București',
      // ✅ NOU: Alias-uri în engleză
      'Fire Watchtower', 'Fire Tower', 'Watchtower', 'Fire Watch Tower', 'Bucharest Fire Tower',
    ]);
    
    // ✅ NOU: Galeria de Artă Hanul cu Tei (Strada Hanul cu Tei)
    _addLandmark('Galeria de Artă Hanul cu Tei', 44.4300, 26.0980, [
      'Galeria de Artă Hanul cu Tei', 'Hanul cu Tei', 'Galeria Hanul cu Tei', 'Han cu Tei',
      // ✅ NOU: Alias-uri în engleză
      'Linden Tree Inn Art Gallery', 'Hanul cu Tei Gallery', 'Linden Inn Gallery', 'Linden Tree Gallery',
    ]);
    
    // ✅ NOU: Biserica Kretzulescu (Calea Victoriei)
    _addLandmark('Biserica Kretzulescu', 44.4400, 26.0970, [
      'Biserica Kretzulescu', 'Kretzulescu', 'Biserica Kretzulescu București', 'Kretzulescu Church',
      // ✅ NOU: Alias-uri în engleză
      'Kretzulescu Church', 'Kretzulescu Orthodox Church', 'Kretzulescu Church Bucharest', 'Kretzulescu Orthodox',
    ]);
    
    // 🎓 ȘCOLI GENERALE ȘI LICEE
    _addSchool('Colegiul Național "Sfântul Sava"', 44.4398, 26.0961, [
      'Sfântul Sava', 'Sf. Sava', 'Colegiul Sfântul Sava', 'Sava',
      // ✅ NOU: Alias-uri în engleză
      'Saint Sava National College', 'Sf. Sava College', 'Sava National College',
    ]);
    _addSchool('Colegiul Național "I.L. Caragiale"', 44.4487, 26.0863, [
      'I.L. Caragiale', 'Caragiale', 'Colegiul Caragiale', 'Liceul Caragiale',
      // ✅ NOU: Alias-uri în engleză
      'I.L. Caragiale National College', 'Caragiale College', 'Caragiale National College',
    ]);
    _addSchool('Colegiul Național "Gheorghe Lazăr"', 44.4356, 26.0967, [
      'Gheorghe Lazăr', 'Lazăr', 'Colegiul Lazăr', 'Liceul Lazăr',
      // ✅ NOU: Alias-uri în engleză
      'Gheorghe Lazăr National College', 'Lazăr College', 'Lazăr National College',
    ]);
    _addSchool('Colegiul Național de Informatică "Tudor Vianu"', 44.4602, 26.0869, [
      'Tudor Vianu', 'Vianu', 'Colegiul Vianu', 'Liceul Vianu', 'Informatică Vianu',
      // ✅ NOU: Alias-uri în engleză
      'Tudor Vianu National College', 'Vianu College', 'Tudor Vianu Informatics College',
    ]);
    _addSchool('Colegiul Național "Mihai Viteazul"', 44.4397, 26.1189, [
      'Mihai Viteazul', 'Viteazul', 'Colegiul Viteazul', 'Liceul Viteazul',
      // ✅ NOU: Alias-uri în engleză
      'Mihai Viteazul National College', 'Viteazul College', 'Mihai Viteazul College',
    ]);
    _addSchool('Colegiul Național "Spiru Haret"', 44.4392, 26.0965, [
      'Spiru Haret', 'Haret', 'Colegiul Haret', 'Liceul Haret',
      // ✅ NOU: Alias-uri în engleză
      'Spiru Haret National College', 'Haret College', 'Spiru Haret College',
    ]);
    
    // 🏥 POLICLINICI
    _addHospital('Policlinica "Dr. Victor Gomoiu"', 44.4400, 26.1000, [
      'Policlinica Gomoiu', 'Gomoiu', 'Policlinica Victor Gomoiu', 'Dr. Gomoiu',
      // ✅ NOU: Alias-uri în engleză
      'Dr. Victor Gomoiu Polyclinic', 'Gomoiu Polyclinic', 'Victor Gomoiu Clinic',
    ]);
    _addHospital('Policlinica "Dr. Ion Cantacuzino"', 44.4300, 26.0980, [
      'Policlinica Cantacuzino', 'Cantacuzino', 'Policlinica Ion Cantacuzino',
      // ✅ NOU: Alias-uri în engleză
      'Dr. Ion Cantacuzino Polyclinic', 'Cantacuzino Polyclinic', 'Ion Cantacuzino Clinic',
    ]);
    _addHospital('Policlinica "Dr. Carol Davila"', 44.4320, 26.1000, [
      'Policlinica Carol Davila', 'Carol Davila', 'Policlinica Davila',
      // ✅ NOU: Alias-uri în engleză
      'Dr. Carol Davila Polyclinic', 'Carol Davila Polyclinic', 'Davila Clinic',
    ]);
    
    // 🏛️ PRIMĂRII ȘI INSTITUȚII PUBLICE
    _addGovernment('Primăria Sectorului 1', 44.4500, 26.1000, [
      'Primăria Sector 1', 'Primăria Sectorului 1', 'Sector 1',
      // ✅ NOU: Alias-uri în engleză
      'Sector 1 City Hall', 'Sector 1 Town Hall', 'Sector 1 Municipality',
    ]);
    _addGovernment('Primăria Sectorului 2', 44.4400, 26.1100, [
      'Primăria Sector 2', 'Primăria Sectorului 2', 'Sector 2',
      // ✅ NOU: Alias-uri în engleză
      'Sector 2 City Hall', 'Sector 2 Town Hall', 'Sector 2 Municipality',
    ]);
    _addGovernment('Primăria Sectorului 3', 44.4200, 26.1200, [
      'Primăria Sector 3', 'Primăria Sectorului 3', 'Sector 3',
      // ✅ NOU: Alias-uri în engleză
      'Sector 3 City Hall', 'Sector 3 Town Hall', 'Sector 3 Municipality',
    ]);
    _addGovernment('Primăria Sectorului 4', 44.4000, 26.1000, [
      'Primăria Sector 4', 'Primăria Sectorului 4', 'Sector 4',
      // ✅ NOU: Alias-uri în engleză
      'Sector 4 City Hall', 'Sector 4 Town Hall', 'Sector 4 Municipality',
    ]);
    _addGovernment('Primăria Sectorului 5', 44.4100, 26.0800, [
      'Primăria Sector 5', 'Primăria Sectorului 5', 'Sector 5',
      // ✅ NOU: Alias-uri în engleză
      'Sector 5 City Hall', 'Sector 5 Town Hall', 'Sector 5 Municipality',
    ]);
    _addGovernment('Primăria Sectorului 6', 44.4300, 26.0500, [
      'Primăria Sector 6', 'Primăria Sectorului 6', 'Sector 6',
      // ✅ NOU: Alias-uri în engleză
      'Sector 6 City Hall', 'Sector 6 Town Hall', 'Sector 6 Municipality',
    ]);
    _addGovernment('Prefectura Municipiului București', 44.4270, 26.0870, [
      'Prefectura București', 'Prefectura', 'Prefectura Municipiului',
      // ✅ NOU: Alias-uri în engleză
      'Bucharest Prefecture', 'Prefecture', 'Bucharest County Prefecture',
    ]);
    _addGovernment('Guvernul României', 44.4518, 26.0970, [
      'Guvern', 'Guvernul', 'Palatul Victoria', 'Victoria',
      // ✅ NOU: Alias-uri în engleză
      'Romanian Government', 'Government', 'Victoria Palace', 'Government Palace',
    ]);
    
    // 🌳 PARCURI (Adăugare mai multe)
    _addLandmark('Parcul Tineretului', 44.4100, 26.1000, [
      'Parcul Tineretului', 'Tineretului', 'Tineretului Park',
      // ✅ NOU: Alias-uri în engleză
      'Youth Park', 'Tineretului Park', 'Youth Park Bucharest',
    ]);
    _addLandmark('Parcul IOR', 44.4000, 26.1100, [
      'Parcul IOR', 'IOR', 'Parcul IOR București',
      // ✅ NOU: Alias-uri în engleză
      'IOR Park', 'IOR Park Bucharest', 'Industrial Park IOR',
    ]);
    _addLandmark('Parcul Kiseleff', 44.4680, 26.0800, [
      'Parcul Kiseleff', 'Kiseleff', 'Parcul Kiseleff București',
      // ✅ NOU: Alias-uri în engleză
      'Kiseleff Park', 'Kiseleff Park Bucharest', 'Kiseleff Gardens',
    ]);
    
    // ⚽ STADIOANE DE FOTBAL
    _addLandmark('Arena Națională', 44.4370, 26.1550, [
      'Arena Națională', 'Arena Nationala', 'Stadionul Național', 'Stadion Național',
      // ✅ NOU: Alias-uri în engleză
      'National Arena', 'National Stadium', 'Bucharest National Arena', 'Romania National Stadium',
    ]);
    _addLandmark('Stadionul Steaua', 44.4400, 26.0700, [
      'Stadionul Steaua', 'Stadion Steaua', 'Steaua', 'Arena Steaua',
      // ✅ NOU: Alias-uri în engleză
      'Steaua Stadium', 'Steaua Arena', 'Steaua Bucharest Stadium',
    ]);
    _addLandmark('Stadionul Dinamo', 44.4500, 26.0800, [
      'Stadionul Dinamo', 'Stadion Dinamo', 'Dinamo', 'Arena Dinamo',
      // ✅ NOU: Alias-uri în engleză
      'Dinamo Stadium', 'Dinamo Arena', 'Dinamo Bucharest Stadium',
    ]);
    
    // 🎭 SĂLI DE SPECTACOLE ȘI TEATRE
    _addLandmark('Sala Palatului', 44.4400, 26.0950, [
      'Sala Palatului', 'Palatul', 'Sala Palatului București',
      // ✅ NOU: Alias-uri în engleză
      'Palace Hall', 'Palace Concert Hall', 'Bucharest Palace Hall',
    ]);
    _addLandmark('Opera Națională București', 44.4400, 26.0950, [
      'Opera Națională', 'Opera', 'Opera București', 'Opera Română',
      // ✅ NOU: Alias-uri în engleză
      'National Opera', 'Bucharest Opera', 'Romanian National Opera', 'Opera House',
    ]);
    _addLandmark('Teatrul Național "Ion Luca Caragiale"', 44.4320, 26.1000, [
      'Teatrul Național', 'Teatru Național', 'Teatru', 'Teatrul Caragiale',
      // ✅ NOU: Alias-uri în engleză
      'National Theatre', 'Caragiale National Theatre', 'National Theatre Bucharest', 'Theatre',
    ]);
    _addLandmark('Teatrul Bulandra', 44.4350, 26.1020, [
      'Teatrul Bulandra', 'Bulandra', 'Teatru Bulandra',
      // ✅ NOU: Alias-uri în engleză
      'Bulandra Theatre', 'Bulandra Theater', 'Bulandra Theatre Bucharest',
    ]);
    _addLandmark('Teatrul Odeon', 44.4320, 26.0990, [
      'Teatrul Odeon', 'Odeon', 'Teatru Odeon',
      // ✅ NOU: Alias-uri în engleză
      'Odeon Theatre', 'Odeon Theater', 'Odeon Theatre Bucharest',
    ]);
    
    // 🛒 SUPERMARKETURI - LOCAȚII SPECIFICE CU ADRESE ȘI COORDONATE PRECISE
    
    // Carrefour
    _addMall('Carrefour Orhideea', 44.4500, 26.0900, [
      'Carrefour Orhideea', 'Carrefour Orhideea Mall', 'Mall Orhideea', 'Orhideea',
      // ✅ NOU: Alias-uri în engleză
      'Carrefour Orhideea', 'Carrefour Orhideea Mall', 'Orhideea Mall',
    ]);
    _addMall('Carrefour Băneasa', 44.5000, 26.0800, [
      'Carrefour Băneasa', 'Carrefour Baneasa', 'Mall Băneasa', 'Băneasa Shopping City',
      // ✅ NOU: Alias-uri în engleză
      'Carrefour Baneasa', 'Baneasa Shopping City', 'Carrefour Baneasa Mall',
    ]);
    
    // Mega Image - Locații specifice
    _addMall('Mega Image C. A. Rosetti', 44.4406, 26.1035, [
      'Mega Image Rosetti', 'Mega Image C. A. Rosetti', 'Mega Image Strada Rosetti',
      // ✅ NOU: Alias-uri în engleză
      'Mega Image Rosetti', 'Mega Image C. A. Rosetti Street',
    ]);
    _addMall('Mega Image Ion Mihalache 92', 44.4602, 26.0665, [
      'Mega Image Ion Mihalache', 'Mega Image Mihalache 92', 'Mega Image Domenii',
      // ✅ NOU: Alias-uri în engleză
      'Mega Image Ion Mihalache', 'Mega Image Mihalache 92',
    ]);
    _addMall('Mega Image Icoanei', 44.4411, 26.1065, [
      'Mega Image Icoanei', 'Mega Image Strada Icoanei',
      // ✅ NOU: Alias-uri în engleză
      'Mega Image Icoanei', 'Mega Image Icoanei Street',
    ]);
    _addMall('Mega Image Lacul Tei 73', 44.4575, 26.1173, [
      'Mega Image Lacul Tei', 'Mega Image Lacul Tei 73', 'Mega Image Tei',
      // ✅ NOU: Alias-uri în engleză
      'Mega Image Lacul Tei', 'Mega Image Tei Lake',
    ]);
    _addMall('Mega Image Constantin Brâncoveanu', 44.3987, 26.1034, [
      'Mega Image Brâncoveanu', 'Mega Image Constantin Brâncoveanu', 'Mega Image Brancoveanu',
      // ✅ NOU: Alias-uri în engleză
      'Mega Image Brancoveanu', 'Mega Image Constantin Brancoveanu',
    ]);
    _addMall('Mega Image Cotroceni', 44.4356, 26.0734, [
      'Mega Image Cotroceni', 'Mega Image Elefterie',
      // ✅ NOU: Alias-uri în engleză
      'Mega Image Cotroceni',
    ]);
    _addMall('Mega Image Piața Gemenii', 44.4445, 26.1073, [
      'Mega Image Gemenii', 'Mega Image Piata Gemenii', 'Mega Image Vasile Lascar',
      // ✅ NOU: Alias-uri în engleză
      'Mega Image Gemenii', 'Mega Image Twins Square',
    ]);
    _addMall('Mega Image Piața Vitan', 44.4198, 26.1234, [
      'Mega Image Vitan', 'Mega Image Piata Vitan', 'Mega Image Calea Vitan',
      // ✅ NOU: Alias-uri în engleză
      'Mega Image Vitan', 'Mega Image Vitan Square',
    ]);
    
    // Lidl - Locații specifice
    _addMall('Lidl Alexandru Șerbănescu', 44.4810, 26.0860, [
      'Lidl Șerbănescu', 'Lidl Serbanescu', 'Lidl Alexandru Serbanescu',
      // ✅ NOU: Alias-uri în engleză
      'Lidl Serbanescu', 'Lidl Alexandru Serbanescu',
    ]);
    _addMall('Lidl Drumul Gazarului', 44.3885, 26.1032, [
      'Lidl Gazarului', 'Lidl Drumul Gazarului', 'Lidl Sector 4',
      // ✅ NOU: Alias-uri în engleză
      'Lidl Gazarului', 'Lidl Gazarului Road',
    ]);
    _addMall('Lidl Serg. Ștefan Crișan', 44.4487, 26.0512, [
      'Lidl Crișan', 'Lidl Crisan', 'Lidl Stefan Crisan', 'Lidl Sector 6',
      // ✅ NOU: Alias-uri în engleză
      'Lidl Crisan', 'Lidl Stefan Crisan',
    ]);
    _addMall('Lidl Doina', 44.4189, 26.0734, [
      'Lidl Doina', 'Lidl Strada Doina', 'Lidl Sector 5',
      // ✅ NOU: Alias-uri în engleză
      'Lidl Doina', 'Lidl Doina Street',
    ]);
    _addMall('Lidl Iuliu Maniu', 44.4356, 26.0519, [
      'Lidl Maniu', 'Lidl Iuliu Maniu', 'Lidl Sector 6',
      // ✅ NOU: Alias-uri în engleză
      'Lidl Maniu', 'Lidl Iuliu Maniu Boulevard',
    ]);
    _addMall('Lidl Timișoara', 44.4267, 26.0254, [
      'Lidl Timișoara', 'Lidl Bulevardul Timisoara', 'Lidl Sector 6 Timisoara',
      // ✅ NOU: Alias-uri în engleză
      'Lidl Timisoara', 'Lidl Timisoara Boulevard',
    ]);
    _addMall('Lidl Mureș', 44.4601, 26.0678, [
      'Lidl Mureș', 'Lidl Strada Mures', 'Lidl Sector 1',
      // ✅ NOU: Alias-uri în engleză
      'Lidl Mures', 'Lidl Mures Street',
    ]);
    
    // Kaufland - Locații specifice
    _addMall('Kaufland Militari', 44.4350, 26.0410, [
      'Kaufland Militari', 'Kaufland Iuliu Maniu', 'Kaufland Sector 6',
      // ✅ NOU: Alias-uri în engleză
      'Kaufland Militari', 'Kaufland Iuliu Maniu Boulevard',
    ]);
    _addMall('Kaufland Băneasa', 44.5000, 26.0800, [
      'Kaufland Băneasa', 'Kaufland Baneasa', 'Kaufland Sector 1',
      // ✅ NOU: Alias-uri în engleză
      'Kaufland Baneasa',
    ]);
    _addMall('Kaufland Vitan', 44.4198, 26.1234, [
      'Kaufland Vitan', 'Kaufland Calea Vitan', 'Kaufland Sector 3',
      // ✅ NOU: Alias-uri în engleză
      'Kaufland Vitan', 'Kaufland Vitan Road',
    ]);
    _addMall('Kaufland Pantelimon', 44.4000, 26.1000, [
      'Kaufland Pantelimon', 'Kaufland Sector 2',
      // ✅ NOU: Alias-uri în engleză
      'Kaufland Pantelimon',
    ]);
    
    // Profi - Locații specifice
    _addMall('Profi Unirii', 44.4268, 26.1025, [
      'Profi Unirii', 'Profi Piata Unirii', 'Profi Sector 3',
      // ✅ NOU: Alias-uri în engleză
      'Profi Unirii', 'Profi Union Square',
    ]);
    _addMall('Profi Victoriei', 44.4549, 26.0852, [
      'Profi Victoriei', 'Profi Piata Victoriei', 'Profi Sector 1',
      // ✅ NOU: Alias-uri în engleză
      'Profi Victoriei', 'Profi Victory Square',
    ]);
    _addMall('Profi Romană', 44.4479, 26.0979, [
      'Profi Romană', 'Profi Piata Romana', 'Profi Sector 1',
      // ✅ NOU: Alias-uri în engleză
      'Profi Romana', 'Profi Roman Square',
    ]);
    _addMall('Profi Obor', 44.4542, 26.1342, [
      'Profi Obor', 'Profi Piata Obor', 'Profi Sector 2',
      // ✅ NOU: Alias-uri în engleză
      'Profi Obor', 'Profi Obor Market',
    ]);
    
    // 🍽️ RESTAURANTE POPULARE
    _addLandmark('Caru\' cu Bere', 44.4323, 26.0999, [
      'Caru\' cu Bere', 'Caru cu Bere', 'Caru\' cu Bere București',
      // ✅ NOU: Alias-uri în engleză
      'Caru\' cu Bere', 'Beer Cart', 'Caru cu Bere Restaurant',
    ]);
    _addLandmark('La Mama', 44.4320, 26.0995, [
      'La Mama', 'Restaurant La Mama', 'La Mama București',
      // ✅ NOU: Alias-uri în engleză
      'La Mama', 'At Mom\'s', 'La Mama Restaurant',
    ]);
    _addLandmark('Hanul lui Manuc Restaurant', 44.4323, 26.0999, [
      'Restaurant Hanul lui Manuc', 'Hanul lui Manuc Restaurant', 'Restaurant Manuc',
      // ✅ NOU: Alias-uri în engleză
      'Manuc\'s Inn Restaurant', 'Manuc Restaurant', 'Manuc\'s Tavern Restaurant',
    ]);
    _addLandmark('Casa Doina', 44.4680, 26.0800, [
      'Casa Doina', 'Restaurant Casa Doina', 'Doina',
      // ✅ NOU: Alias-uri în engleză
      'Casa Doina', 'Doina Restaurant', 'Casa Doina Restaurant',
    ]);
    _addLandmark('The Artist', 44.4400, 26.0970, [
      'The Artist', 'Restaurant The Artist', 'The Artist București',
      // ✅ NOU: Alias-uri în engleză
      'The Artist', 'The Artist Restaurant', 'Artist Restaurant',
    ]);
    _addLandmark('Beca\'s Kitchen', 44.4350, 26.1000, [
      'Beca\'s Kitchen', 'Becas Kitchen', 'Beca Kitchen',
      // ✅ NOU: Alias-uri în engleză
      'Beca\'s Kitchen', 'Beca Kitchen', 'Becas Kitchen Restaurant',
    ]);
    
    // 🍔 MCDONALD'S - LOCAȚII SPECIFICE BUCUREȘTI ȘI ILFOV
    _addLandmark('McDonald\'s Unirea', 44.4268, 26.1025, [
      'McDonald\'s Unirea', 'McDonald Unirea', 'McDonald\'s Piata Unirii', 'McDonalds Unirea',
      // ✅ NOU: Alias-uri în engleză
      'McDonald\'s Unirea', 'McDonald\'s Union Square', 'McDonald\'s Unirii',
    ]);
    _addLandmark('McDonald\'s Veranda Mall', 44.4562, 26.1275, [
      'McDonald\'s Veranda', 'McDonald Veranda', 'McDonald\'s Veranda Mall', 'McDonalds Veranda',
      // ✅ NOU: Alias-uri în engleză
      'McDonald\'s Veranda', 'McDonald\'s Veranda Mall',
    ]);
    _addLandmark('McDonald\'s Romană', 44.4445, 26.0969, [
      'McDonald\'s Romană', 'McDonald Romana', 'McDonald\'s Piata Romana', 'McDonalds Romana',
      // ✅ NOU: Alias-uri în engleză
      'McDonald\'s Romana', 'McDonald\'s Roman Square',
    ]);
    _addLandmark('McDonald\'s Dristor DT', 44.4231, 26.1412, [
      'McDonald\'s Dristor', 'McDonald Dristor', 'McDonald\'s Dristor Drive-Thru', 'McDonalds Dristor',
      // ✅ NOU: Alias-uri în engleză
      'McDonald\'s Dristor', 'McDonald\'s Dristor Drive-Thru',
    ]);
    _addLandmark('McDonald\'s Brâncoveanu DT', 44.3986, 26.1147, [
      'McDonald\'s Brâncoveanu', 'McDonald Brancoveanu', 'McDonald\'s Constantin Brancoveanu', 'McDonalds Brancoveanu',
      // ✅ NOU: Alias-uri în engleză
      'McDonald\'s Brancoveanu', 'McDonald\'s Constantin Brancoveanu Drive-Thru',
    ]);
    _addLandmark('McDonald\'s Morarilor DT', 44.4392, 26.1558, [
      'McDonald\'s Morarilor', 'McDonald Morarilor', 'McDonald\'s Morarilor Drive-Thru', 'McDonalds Morarilor',
      // ✅ NOU: Alias-uri în engleză
      'McDonald\'s Morarilor', 'McDonald\'s Morarilor Drive-Thru',
    ]);
    _addLandmark('McDonald\'s Păcii DT', 44.4350, 26.0153, [
      'McDonald\'s Păcii', 'McDonald Pacii', 'McDonald\'s Pacii Drive-Thru', 'McDonalds Pacii',
      // ✅ NOU: Alias-uri în engleză
      'McDonald\'s Pacii', 'McDonald\'s Pacii Drive-Thru',
    ]);
    _addLandmark('McDonald\'s Buzești DT', 44.4485, 26.0824, [
      'McDonald\'s Buzești', 'McDonald Buzesti', 'McDonald\'s Buzesti Drive-Thru', 'McDonalds Buzesti',
      // ✅ NOU: Alias-uri în engleză
      'McDonald\'s Buzesti', 'McDonald\'s Buzesti Drive-Thru',
    ]);
    _addLandmark('McDonald\'s Vitan Mall', 44.4195, 26.1312, [
      'McDonald\'s Vitan', 'McDonald Vitan', 'McDonald\'s Vitan Mall', 'McDonalds Vitan',
      // ✅ NOU: Alias-uri în engleză
      'McDonald\'s Vitan', 'McDonald\'s Vitan Mall',
    ]);
    _addLandmark('McDonald\'s Orhideea', 44.4397, 26.0678, [
      'McDonald\'s Orhideea', 'McDonald Orhideea', 'McDonalds Orhideea',
      // ✅ NOU: Alias-uri în engleză
      'McDonald\'s Orhideea', 'McDonald\'s Orhideea Mall',
    ]);
    _addLandmark('McDonald\'s Plaza Mall', 44.4301, 26.0512, [
      'McDonald\'s Plaza', 'McDonald Plaza', 'McDonald\'s Plaza Mall', 'McDonalds Plaza',
      // ✅ NOU: Alias-uri în engleză
      'McDonald\'s Plaza', 'McDonald\'s Plaza Mall',
    ]);
    _addLandmark('McDonald\'s Sun Plaza', 44.3975, 26.1123, [
      'McDonald\'s Sun Plaza', 'McDonald Sun Plaza', 'McDonalds Sun Plaza',
      // ✅ NOU: Alias-uri în engleză
      'McDonald\'s Sun Plaza', 'McDonald\'s Sun Plaza Mall',
    ]);
    _addLandmark('McDonald\'s AFI Cotroceni', 44.4307, 26.0541, [
      'McDonald\'s AFI', 'McDonald AFI', 'McDonald\'s AFI Cotroceni', 'McDonalds AFI',
      // ✅ NOU: Alias-uri în engleză
      'McDonald\'s AFI', 'McDonald\'s AFI Cotroceni Mall',
    ]);
    _addLandmark('McDonald\'s ParkLake', 44.4218, 26.1527, [
      'McDonald\'s ParkLake', 'McDonald ParkLake', 'McDonalds ParkLake',
      // ✅ NOU: Alias-uri în engleză
      'McDonald\'s ParkLake', 'McDonald\'s ParkLake Mall',
    ]);
    _addLandmark('McDonald\'s Promenada', 44.4745, 26.1012, [
      'McDonald\'s Promenada', 'McDonald Promenada', 'McDonalds Promenada',
      // ✅ NOU: Alias-uri în engleză
      'McDonald\'s Promenada', 'McDonald\'s Promenada Mall',
    ]);
    _addLandmark('McDonald\'s Pipera', 44.4932, 26.1038, [
      'McDonald\'s Pipera', 'McDonald Pipera', 'McDonald\'s Pipera Ilfov', 'McDonalds Pipera',
      // ✅ NOU: Alias-uri în engleză
      'McDonald\'s Pipera', 'McDonald\'s Pipera Ilfov',
    ]);
    _addLandmark('McDonald\'s Otopeni', 44.5323, 26.0408, [
      'McDonald\'s Otopeni', 'McDonald Otopeni', 'McDonald\'s Otopeni Ilfov', 'McDonalds Otopeni',
      // ✅ NOU: Alias-uri în engleză
      'McDonald\'s Otopeni', 'McDonald\'s Otopeni Ilfov',
    ]);
    
    // 🍗 KFC - LOCAȚII SPECIFICE BUCUREȘTI ȘI ILFOV
    _addLandmark('KFC Dorobanți', 44.4532, 26.0975, [
      'KFC Dorobanți', 'KFC Dorobanti', 'KFC Calea Dorobanti',
      // ✅ NOU: Alias-uri în engleză
      'KFC Dorobanti', 'KFC Dorobanti Road',
    ]);
    _addLandmark('KFC Băneasa', 44.4956, 26.0789, [
      'KFC Băneasa', 'KFC Baneasa', 'KFC Sector 1',
      // ✅ NOU: Alias-uri în engleză
      'KFC Baneasa', 'KFC Baneasa Bucharest',
    ]);
    _addLandmark('KFC Unirii', 44.4268, 26.1025, [
      'KFC Unirii', 'KFC Unirea', 'KFC Piata Unirii',
      // ✅ NOU: Alias-uri în engleză
      'KFC Unirii', 'KFC Union Square',
    ]);
    _addLandmark('KFC Militari', 44.4355, 26.0098, [
      'KFC Militari', 'KFC Iuliu Maniu', 'KFC Sector 6',
      // ✅ NOU: Alias-uri în engleză
      'KFC Militari', 'KFC Iuliu Maniu Boulevard',
    ]);
    _addLandmark('KFC ParkLake', 44.4218, 26.1527, [
      'KFC ParkLake', 'KFC Park Lake', 'KFC Sector 3',
      // ✅ NOU: Alias-uri în engleză
      'KFC ParkLake', 'KFC ParkLake Mall',
    ]);
    _addLandmark('KFC Sun Plaza', 44.3976, 26.1123, [
      'KFC Sun Plaza', 'KFC Sun', 'KFC Sector 4',
      // ✅ NOU: Alias-uri în engleză
      'KFC Sun Plaza', 'KFC Sun Plaza Mall',
    ]);
    _addLandmark('KFC Piața Romană', 44.4445, 26.0969, [
      'KFC Romană', 'KFC Romana', 'KFC Piata Romana',
      // ✅ NOU: Alias-uri în engleză
      'KFC Romana', 'KFC Roman Square',
    ]);
    _addLandmark('KFC Cora Pantelimon', 44.4645, 26.1030, [
      'KFC Pantelimon', 'KFC Cora Pantelimon', 'KFC Sector 2',
      // ✅ NOU: Alias-uri în engleză
      'KFC Pantelimon', 'KFC Cora Pantelimon',
    ]);
    _addLandmark('KFC Otopeni', 44.5330, 26.0500, [
      'KFC Otopeni', 'KFC Otopeni Ilfov', 'KFC Aeroport',
      // ✅ NOU: Alias-uri în engleză
      'KFC Otopeni', 'KFC Otopeni Ilfov', 'KFC Airport',
    ]);
    _addLandmark('Casa Poporului', 44.4270, 26.0870, [
      'Casa Poporului', 'Palatul Parlamentului', 'Parlament', 'Palatul',
    ]);
    _addLandmark('Muzeul Național de Istorie', 44.4320, 26.0990, [
      'Muzeul Istoriei', 'Muzeul Național', 'Istorie',
    ]);
    _addLandmark('Muzeul Național de Artă', 44.4300, 26.0980, [
      'Muzeul de Artă', 'Muzeul Artă', 'Artă',
    ]);
    _addLandmark('Teatrul Național', 44.4320, 26.1000, [
      'Teatrul Național', 'Teatru Național', 'Teatru',
    ]);
    _addLandmark('Opera Națională', 44.4400, 26.0950, [
      'Opera', 'Opera Națională', 'Opera Română',
    ]);

    // 🏢 CLĂDIRI IMPORTANTE
    _addLandmark('Tower Center', 44.4500, 26.1000, [
      'Tower Center', 'Tower', 'Centru Tower',
    ]);
    _addLandmark('World Trade Center', 44.4400, 26.0900, [
      'WTC', 'World Trade Center', 'Trade Center',
    ]);
    _addLandmark('Bursa de Valori', 44.4300, 26.1000, [
      'Bursa', 'Bursa de Valori', 'Stock Exchange',
    ]);
  }

  static void _addHospital(String name, double lat, double lon, List<String> aliases) {
    _addLocation(name, lat, lon, 'hospital', aliases);
  }

  static void _addStation(String name, double lat, double lon, List<String> aliases) {
    _addLocation(name, lat, lon, 'station', aliases);
  }

  static void _addGovernment(String name, double lat, double lon, List<String> aliases) {
    _addLocation(name, lat, lon, 'government', aliases);
  }

  static void _addEmbassy(String name, double lat, double lon, List<String> aliases) {
    _addLocation(name, lat, lon, 'embassy', aliases);
  }

  static void _addUniversity(String name, double lat, double lon, List<String> aliases) {
    _addLocation(name, lat, lon, 'university', aliases);
  }

  static void _addMall(String name, double lat, double lon, List<String> aliases) {
    _addLocation(name, lat, lon, 'mall', aliases);
  }

  static void _addAirport(String name, double lat, double lon, List<String> aliases) {
    _addLocation(name, lat, lon, 'airport', aliases);
  }

  static void _addLandmark(String name, double lat, double lon, List<String> aliases) {
    _addLocation(name, lat, lon, 'landmark', aliases);
  }

  static void _addSchool(String name, double lat, double lon, List<String> aliases) {
    _addLocation(name, lat, lon, 'school', aliases);
  }

  static void _addLocation(String name, double lat, double lon, String category, List<String> aliases) {
    final location = BucharestLocation(
      name: name,
      latitude: lat,
      longitude: lon,
      category: category,
      aliases: aliases,
    );

    // Adaugă numele principal
    _locations[name.toLowerCase()] = location;

    // Adaugă toate alias-urile
    for (final alias in aliases) {
      _locations[alias.toLowerCase()] = location;
    }
  }

  /// Caută o locație în baza de date
  static Map<String, dynamic>? findLocation(String query) {
    if (_locations.isEmpty) {
      initialize();
    }

    final normalizedQuery = query.toLowerCase().trim();

    // Caută exact
    if (_locations.containsKey(normalizedQuery)) {
      return _locations[normalizedQuery]!.toMap();
    }

    // Caută parțial (query conține cheia sau cheia conține query)
    for (final entry in _locations.entries) {
      final key = entry.key;
      if (normalizedQuery.contains(key) || key.contains(normalizedQuery)) {
        return entry.value.toMap();
      }
    }

    return null;
  }

  /// Obține toate locațiile dintr-o categorie
  static List<Map<String, dynamic>> getLocationsByCategory(String category) {
    if (_locations.isEmpty) {
      initialize();
    }

    return _locations.values
        .where((loc) => loc.category == category)
        .map((loc) => loc.toMap())
        .toList();
  }

  /// Obține numărul total de locații
  static int get totalLocations {
    if (_locations.isEmpty) {
      initialize();
    }
    return _locations.length;
  }
}


import 'package:flutter/material.dart';

// O clasă care centralizează tot conținutul pentru articolele de ajutor.
class HelpContent {
  static final Map<String, List<Widget>> articles = {
    // --- Categoria: Asistență Cursă ---
    'Nu pot solicita o cursă': [
      _buildParagraph(
        'Dacă întâmpinați probleme la solicitarea unei curse, vă rugăm să verificați următoarele puncte:',
      ),
      _buildListItem('Asigurați-vă că aveți o conexiune la internet stabilă (Wi-Fi sau date mobile).'),
      _buildListItem('Verificați dacă serviciile de localizare (GPS) ale telefonului sunt activate și aplicația are permisiunea de a le folosi.'),
      _buildListItem('Reporniți aplicația. O simplă repornire poate rezolva probleme temporare de comunicare.'),
      _buildListItem('Asigurați-vă că aveți o metodă de plată validă înregistrată în secțiunea "Portofel".'),
    ],
    'Timpul de preluare este mai mare decât cel estimat': [
      _buildParagraph(
        'Timpul estimat de sosire (ETA) este calculat pe baza condițiilor de trafic în timp real și a distanței. Cu toate acestea, pot apărea întârzieri neprevăzute din cauza unor factori precum blocaje în trafic, condiții meteo nefavorabile sau devieri de traseu.',
      ),
       _buildParagraph(
        'Vă recomandăm să urmăriți locația șoferului pe hartă. Dacă întârzierea este semnificativă, puteți contacta șoferul direct prin intermediul funcției de chat sau apel din aplicație pentru a obține o actualizare.',
      ),
    ],
    'Cursa nu a avut loc': [
      _buildParagraph('Dacă o cursă a fost marcată ca finalizată, dar nu a avut loc, sau dacă șoferul a anulat după ce a pornit, vă rugăm să ne contactați imediat prin secțiunea de suport a cursei respective din "Istoric Curse". Vom investiga situația și vom lua măsurile corespunzătoare, inclusiv rambursarea plății, dacă este cazul.'),
    ],
    'Utilizarea asistenței de urgență': [
      _buildParagraph('Butonul de siguranță "112" este disponibil pe ecranul de cursă activă atât pentru pasageri, cât și pentru șoferi. Acest buton este destinat exclusiv situațiilor de urgență reală.'),
      _buildParagraph('La apăsare, butonul va iniția un apel telefonic direct către numărul unic de urgență 112. Folosiți această funcție cu responsabilitate.'),
    ],
    'Obiecte pierdute': [
       _buildParagraph(
        'Dacă ați uitat un obiect în mașina șoferului, cea mai rapidă metodă de a-l recupera este să contactați direct șoferul. Puteți face acest lucru din detaliile cursei, în secțiunea "Istoric Curse", timp de 24 de ore după finalizarea călătoriei.'),
       _buildParagraph(
        'Dacă au trecut mai mult de 24 de ore sau nu puteți contacta șoferul, vă rugăm să ne scrieți la adresa de suport, furnizând cât mai multe detalii despre cursă și obiectul pierdut.'),
    ],
     'Raportează accident sau eveniment neplăcut': [
       _buildParagraph(
        'Siguranța dumneavoastră este prioritatea noastră absolută. Dacă ați fost implicat într-un accident sau un eveniment neplăcut în timpul cursei, vă rugăm să urmați acești pași:'),
      _buildListItem('Asigurați-vă că sunteți într-un loc sigur. Dacă este necesar, contactați imediat serviciile de urgență la 112.'),
      _buildListItem('Raportați incidentul echipei noastre de suport cât mai curând posibil, oferind toate detaliile relevante. Vom investiga situația cu maximă prioritate.'),
    ],
    // --- Alte categorii (placeholder) ---
    'Solicitare comandă livrare': [_buildParagraph('Funcționalitatea de livrare (FriendsDelivery) va fi disponibilă în curând!')],
    'Probleme de funcționare a aplicației': [_buildParagraph('Dacă întâmpinați erori tehnice, vă rugăm să încercați să reporniți aplicația. Dacă problema persistă, contactați suportul tehnic la support@friendsride.ro, specificând modelul telefonului și versiunea sistemului de operare.')],
    'Șoferul a deviat de la traseu': [_buildParagraph('Aplicația oferă o rută optimă, dar șoferul poate alege un traseu alternativ pe baza experienței sale pentru a evita blocajele. Dacă devierea este nejustificată și duce la un cost semnificativ mai mare, vă rugăm să ne semnalați acest lucru din detaliile cursei, în istoric.')],
    
    // --- MODIFICARE: Conținut actualizat pentru Taxa de Curățenie ---
    'Taxă curățenie sau daune': [
      _buildParagraph('Pentru a menține mașinile curate și sigure pentru toți, se poate aplica o taxă suplimentară dacă un pasager murdărește grav sau deteriorează vehiculul.'),
      _buildSubheading('Când se aplică?'),
      _buildListItem('Vărsături, mâncare sau băuturi vărsate'),
      _buildListItem('Noroi pe scaune, urme de animale'),
      _buildListItem('Zgârieturi, ruperea tapițeriei sau alte daune'),
      _buildSubheading('Cum funcționează?'),
      _buildListItem('Șoferul trimite dovezi (foto).'),
      _buildListItem('Verificăm cererea.'),
      _buildListItem('Dacă e justificată, taxa e retrasă automat din contul pasagerului.'),
      _buildSubheading('Cât poate costa?'),
      _buildListItem('Curățenie ușoară: 30–70 lei'),
      _buildListItem('Curățenie profesională: 100–400 lei'),
      _buildListItem('Daune materiale: 200–1.000+ lei'),
      _buildParagraph('Pasagerii pot contesta taxa din aplicație în 48 de ore.'),
    ],
    // --- FINAL MODIFICARE ---
    
    'Tarife și plăți': [_buildParagraph('Tarifele noastre sunt calculate dinamic pe baza unei sumei de pornire, a distanței parcurse și a duratei călătoriei. Puteți vedea o estimare a costului înainte de a confirma cursa. Toate plățile sunt procesate în siguranță prin intermediul aplicației.')],
    'Transfer de tokeni între utilizatori': [
      _buildParagraph(
        'Din meniul lateral, „Transfer tokeni” deschide ecranul unde poți trimite tokeni direct către ID-ul altui utilizator sau poți crea o cerere prin care soliciți tokeni de la cineva. Soldul transferabil este gestionat pe server; verifică ID-ul înainte de a confirma.',
      ),
      _buildParagraph(
        'La cereri de plată: plătitorul poate accepta sau refuza; tu poți anula cererea ta cât timp este în așteptare. În fila Istoric vezi transferurile și cererile încheiate.',
      ),
    ],
  };

  static Padding _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(text, style: const TextStyle(fontSize: 16, height: 1.5)),
    );
  }

  // NOU: Funcție pentru subtitluri
  static Padding _buildSubheading(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  static Padding _buildListItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
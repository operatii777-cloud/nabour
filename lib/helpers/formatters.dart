// Acest fișier conține funcții helper pentru formatarea diverselor date în aplicație.

/// Formatează o durată dată în minute totale într-un șir de caractere
/// lizibil pentru utilizator, în limba română, incluzând zile, ore și minute.
///
/// [totalMinutes] - Durata totală în minute.
/// Returnează un string formatat (ex: "1 zi, 2 ore și 30 de minute").
String formatTravelDuration(int totalMinutes) {
  // Gestionează cazurile în care durata este mai mică de un minut.
  if (totalMinutes < 1) {
    return "mai puțin de un minut";
  }

  // Dacă durata este sub o oră, afișează doar minutele.
  if (totalMinutes < 60) {
    return "$totalMinutes ${totalMinutes == 1 ? 'minut' : 'minute'}";
  }

  // Constante pentru calcul
  const int minutesInADay = 24 * 60;
  const int minutesInAnHour = 60;

  // Calculează zilele, orele și minutele rămase
  final int days = totalMinutes ~/ minutesInADay;
  final int remainingMinutesAfterDays = totalMinutes % minutesInADay;
  final int hours = remainingMinutesAfterDays ~/ minutesInAnHour;
  final int minutes = remainingMinutesAfterDays % minutesInAnHour;

  final List<String> parts = [];

  // Adaugă zilele în listă, dacă există
  if (days > 0) {
    parts.add("$days ${days == 1 ? 'zi' : 'zile'}");
  }

  // Adaugă orele în listă, dacă există
  if (hours > 0) {
    parts.add("$hours ${hours == 1 ? 'oră' : 'ore'}");
  }

  // Adaugă minutele în listă, dacă există
  if (minutes > 0) {
    parts.add("$minutes ${minutes == 1 ? 'minut' : 'minute'}");
  }

  // Combină părțile într-un text natural
  if (parts.isEmpty) {
    return "Timp necunoscut";
  } else if (parts.length == 1) {
    return parts.first;
  } else if (parts.length == 2) {
    return parts.join(' și ');
  } else {
    // Pentru cazuri precum "1 zi, 5 ore și 10 minute"
    final String lastPart = parts.removeLast();
    return "${parts.join(', ')} și $lastPart";
  }
}

/*
--- CUM SĂ UTILIZEZI ACEST FIȘIER ÎN `friendsride_app` ---

1.  **Plasează fișierul:** Asigură-te că acest fișier (`formatters.dart`) se află
    în directorul `lib/helpers/` al proiectului tău Flutter. Dacă directorul
    `helpers` nu există, creează-l.

2.  **Importă fișierul:** În orice fișier Dart unde dorești să formatezi durata
    (de ex: `map_screen.dart` sau `active_ride_screen.dart`), adaugă următoarea
    linie de import în partea de sus:

    import 'package:nabour_app/helpers/formatters.dart';

3.  **Apelează funcția:**
    // Presupunând că ai o variabilă cu durata în minute
    int durataInMinute = 150; 
    
    // Apelează funcția pentru a obține textul formatat
    String timpAfisat = formatTravelDuration(durataInMinute);
    
    // Acum poți folosi `timpAfisat` într-un widget Text pentru a-l arăta utilizatorului.
    // De exemplu: Text(timpAfisat) va afișa "2 ore și 30 de minute".
*/

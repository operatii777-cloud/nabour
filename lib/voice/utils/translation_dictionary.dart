/// 🧠 Translation Dictionary - Contains common phrases for ride-hailing RO<->EN
class TranslationDictionary {
  static final List<Map<String, String>> roToEn = [
    // Greeting & Politeness
    {'pattern': 'buna', 'translation': 'Hello', 'category': 'greeting'},
    {'pattern': 'buna ziua', 'translation': 'Good day', 'category': 'greeting'},
    {'pattern': 'salut', 'translation': 'Hi', 'category': 'greeting'},
    {'pattern': 'salut, ce faci', 'translation': 'Hi, how are you?', 'category': 'small_talk'},
    {'pattern': 'ce mai faci', 'translation': 'How are you?', 'category': 'small_talk'},
    {'pattern': 'cum esti', 'translation': 'How are you?', 'category': 'small_talk'},
    {'pattern': 'multumesc', 'translation': 'Thank you', 'category': 'politeness'},
    {'pattern': 'multumesc mult', 'translation': 'Thank you very much', 'category': 'politeness'},
    {'pattern': 'mersi', 'translation': 'Thanks', 'category': 'politeness'},
    {'pattern': 'cu placere', 'translation': 'You\'re welcome', 'category': 'politeness'},
    {'pattern': 'scuze', 'translation': 'Sorry', 'category': 'politeness'},
    {'pattern': 'o zi buna', 'translation': 'Have a nice day', 'category': 'politeness'},
    
    // Time & Delays
    {'pattern': 'ajung in {n} minute', 'translation': 'I\'ll arrive in {n} minutes', 'category': 'time'},
    {'pattern': 'intarzii putin', 'translation': 'I\'m running a bit late', 'category': 'time'},
    {'pattern': 'poti sa mai astepti {n} minute', 'translation': 'Can you wait for {n} more minutes?', 'category': 'time'},
    {'pattern': 'sunt gata poti veni', 'translation': 'I\'m ready, you can come', 'category': 'time'},
    
    // Location & Orientation
    {'pattern': 'sunt la destinatie', 'translation': 'I\'m at the destination', 'category': 'location'},
    {'pattern': 'sunt la colt', 'translation': 'I\'m at the corner', 'category': 'location'},
    {'pattern': 'sunt in fata cladirii', 'translation': 'I\'m in front of the building', 'category': 'location'},
    {'pattern': 'poti opri aici', 'translation': 'Can you stop here?', 'category': 'location'},
    {'pattern': 'te vad', 'translation': 'I see you', 'category': 'location'},
    {'pattern': 'nu te vad', 'translation': 'I don\'t see you', 'category': 'location'},
    {'pattern': 'unde esti', 'translation': 'Where are you?', 'category': 'location'},
    
    // Ride & Details
    {'pattern': 'unde mergem', 'translation': 'Where are we going?', 'category': 'ride'},
    {'pattern': 'am schimbat destinatia', 'translation': 'I changed the destination', 'category': 'ride'},
    {'pattern': 'vreau sa opresc aici', 'translation': 'I want to stop here', 'category': 'ride'},
    {'pattern': 'vreau sa adaug o oprire', 'translation': 'I want to add a stop', 'category': 'ride'},
    
    // Payment & Fare
    {'pattern': 'platesc cash', 'translation': 'I\'ll pay cash', 'category': 'payment'},
    {'pattern': 'platesc cu cardul', 'translation': 'I\'ll pay by card', 'category': 'payment'},
    {'pattern': 'tariful este prea mare', 'translation': 'The fare is too high', 'category': 'fare'},
    {'pattern': 'poti sa imi trimiti chitanta', 'translation': 'Can you send me the receipt?', 'category': 'fare'},
    
    // Core Confirmations
    {'pattern': 'da', 'translation': 'Yes', 'category': 'confirmation'},
    {'pattern': 'nu', 'translation': 'No', 'category': 'confirmation'},
    {'pattern': 'sigur', 'translation': 'Sure', 'category': 'confirmation'},
    {'pattern': 'bine', 'translation': 'Fine/OK', 'category': 'confirmation'},
    {'pattern': 'perfect', 'translation': 'Perfect', 'category': 'confirmation'},
    {'pattern': 'confirm', 'translation': 'Confirm', 'category': 'confirmation'},
    {'pattern': 'imediat', 'translation': 'Immediately/Right away', 'category': 'time'},
    
    // Specific Ride Requests
    {'pattern': 'sunt pe drum', 'translation': 'I\'m on my way', 'category': 'status'},
    {'pattern': 'am ajuns', 'translation': 'I have arrived', 'category': 'status'},
    {'pattern': 'te astept', 'translation': 'I\'m waiting for you', 'category': 'status'},
    {'pattern': 'vin acum', 'translation': 'I\'m coming now', 'category': 'time'},
    {'pattern': 'poti sa ma suni', 'translation': 'Can you call me?', 'category': 'communication'},
    {'pattern': 'numărul meu este {n}', 'translation': 'My number is {n}', 'category': 'communication'},

    // App / Assistant Questions (RO -> EN)
    {'pattern': 'ce poti sa faci', 'translation': 'What can you do?', 'category': 'app_help'},
    {'pattern': 'cum functionezi', 'translation': 'How do you work?', 'category': 'app_help'},
    {'pattern': 'cum comand o cursa', 'translation': 'How do I request a ride?', 'category': 'app_help'},
    {'pattern': 'cum pot comanda o cursa', 'translation': 'How can I request a ride?', 'category': 'app_help'},
    {'pattern': 'ce este nabour', 'translation': 'What is Nabour?', 'category': 'app_info'},
    {'pattern': 'cine te a facut', 'translation': 'Who created you?', 'category': 'app_info'},
  ];

  static final List<Map<String, String>> enToRo = [
    // Greeting & Politeness
    {'pattern': 'hello', 'translation': 'Bună', 'category': 'greeting'},
    {'pattern': 'good day', 'translation': 'Bună ziua', 'category': 'greeting'},
    {'pattern': 'hi', 'translation': 'Salut', 'category': 'greeting'},
    {'pattern': 'hi, how are you', 'translation': 'Salut, ce faci?', 'category': 'small_talk'},
    {'pattern': 'how are you', 'translation': 'Ce mai faci?', 'category': 'small_talk'},
    {'pattern': 'thank you', 'translation': 'Mulțumesc', 'category': 'politeness'},
    {'pattern': 'thank you very much', 'translation': 'Mulțumesc mult', 'category': 'politeness'},
    {'pattern': 'thanks', 'translation': 'Mersi', 'category': 'politeness'},
    {'pattern': 'you are welcome', 'translation': 'Cu plăcere', 'category': 'politeness'},
    {'pattern': 'sorry', 'translation': 'Scuze', 'category': 'politeness'},
    {'pattern': 'have a nice day', 'translation': 'O zi bună', 'category': 'politeness'},
    
    // Time & Delays
    {'pattern': 'i will arrive in {n} minutes', 'translation': 'Ajung în {n} minute', 'category': 'time'},
    {'pattern': 'i am running a bit late', 'translation': 'Întârzii puțin', 'category': 'time'},
    {'pattern': 'can you wait for {n} more minutes', 'translation': 'Poți să mai aștepți {n} minute?', 'category': 'time'},
    {'pattern': 'i am ready you can come', 'translation': 'Sunt gata, poți veni', 'category': 'time'},
    
    // Location & Orientation
    {'pattern': 'i am at the destination', 'translation': 'Sunt la destinație', 'category': 'location'},
    {'pattern': 'i am at the corner', 'translation': 'Sunt la colț', 'category': 'location'},
    {'pattern': 'i am in front of the building', 'translation': 'Sunt în fața clădirii', 'category': 'location'},
    {'pattern': 'can you stop here', 'translation': 'Poți opri aici?', 'category': 'location'},
    {'pattern': 'i see you', 'translation': 'Te văd', 'category': 'location'},
    {'pattern': 'i do not see you', 'translation': 'Nu te văd', 'category': 'location'},
    {'pattern': 'where are you', 'translation': 'Unde ești?', 'category': 'location'},
    
    // Ride & Details
    {'pattern': 'where are we going', 'translation': 'Unde mergem?', 'category': 'ride'},
    {'pattern': 'i changed the destination', 'translation': 'Am schimbat destinația', 'category': 'ride'},
    {'pattern': 'i want to stop here', 'translation': 'Vreau să opresc aici', 'category': 'ride'},
    {'pattern': 'i want to add a stop', 'translation': 'Vreau să adaug o oprire', 'category': 'ride'},
    
    // Payment & Fare
    {'pattern': 'i will pay cash', 'translation': 'Plătesc cash', 'category': 'payment'},
    {'pattern': 'i will pay by card', 'translation': 'Plătesc cu cardul', 'category': 'payment'},
    {'pattern': 'the fare is too high', 'translation': 'Tariful este prea mare', 'category': 'fare'},
    {'pattern': 'can you send me the receipt', 'translation': 'Poți să îmi trimiți chitanța?', 'category': 'fare'},
    
    // Core Confirmations
    {'pattern': 'yes', 'translation': 'Da', 'category': 'confirmation'},
    {'pattern': 'no', 'translation': 'Nu', 'category': 'confirmation'},
    {'pattern': 'sure', 'translation': 'Sigur', 'category': 'confirmation'},
    {'pattern': 'fine', 'translation': 'Bine', 'category': 'confirmation'},
    {'pattern': 'ok', 'translation': 'OK', 'category': 'confirmation'},
    {'pattern': 'perfect', 'translation': 'Perfect', 'category': 'confirmation'},
    {'pattern': 'confirm', 'translation': 'Confirm', 'category': 'confirmation'},
    {'pattern': 'immediately', 'translation': 'Imediat', 'category': 'time'},
    
    // Specific Ride Requests
    {'pattern': 'i am on my way', 'translation': 'Sunt pe drum', 'category': 'status'},
    {'pattern': 'i have arrived', 'translation': 'Am ajuns', 'category': 'status'},
    {'pattern': 'i am waiting for you', 'translation': 'Te aștept', 'category': 'status'},
    {'pattern': 'i am coming now', 'translation': 'Vin acum', 'category': 'time'},
    {'pattern': 'can you call me', 'translation': 'Poți să mă suni?', 'category': 'communication'},
    {'pattern': 'my number is {n}', 'translation': 'Numărul meu este {n}', 'category': 'communication'},

    // App / Assistant Questions (EN -> RO)
    {'pattern': 'what can you do', 'translation': 'Ce poți să faci?', 'category': 'app_help'},
    {'pattern': 'how do you work', 'translation': 'Cum funcționezi?', 'category': 'app_help'},
    {'pattern': 'how do i request a ride', 'translation': 'Cum comand o cursă?', 'category': 'app_help'},
    {'pattern': 'how can i request a ride', 'translation': 'Cum pot comanda o cursă?', 'category': 'app_help'},
    {'pattern': 'what is nabour', 'translation': 'Ce este Nabour?', 'category': 'app_info'},
    {'pattern': 'who created you', 'translation': 'Cine te-a făcut?', 'category': 'app_info'},
  ];
}

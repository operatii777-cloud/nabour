import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adaugă un Card Nou'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Câmp pentru Numele de pe Card
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Nume de pe Card',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) => (value ?? '').isEmpty ? 'Numele este obligatoriu' : null,
              ),
              const SizedBox(height: 20),
              // Câmp pentru Numărul Cardului
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Număr Card',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.credit_card),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(16),
                  _CardNumberInputFormatter(),
                ],
                 validator: (value) => (value?.replaceAll(' ', '').length ?? 0) != 16 ? 'Introduceți un număr de card valid' : null,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  // Câmp pentru Data de Expirare
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Expiră (LL/AA)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                       keyboardType: TextInputType.number,
                       inputFormatters: [
                         FilteringTextInputFormatter.digitsOnly,
                         LengthLimitingTextInputFormatter(4),
                         _CardDateInputFormatter(),
                       ],
                       // AICI ESTE VALIDAREA COMPLEXĂ
                       validator: (value) {
                         if (value == null || value.length != 5) {
                           return 'Data invalidă';
                         }
                         final parts = value.split('/');
                         if (parts.length != 2) return 'Format invalid';

                         final month = int.tryParse(parts[0]);
                         final year = int.tryParse(parts[1]);

                         if (month == null || year == null) return 'Format invalid';
                         if (month < 1 || month > 12) return 'Lună invalidă';

                         final currentYear = DateTime.now().year % 100; // Anul curent (ultimele 2 cifre)
                         final currentMonth = DateTime.now().month;
                         
                         if (year < currentYear || (year == currentYear && month < currentMonth)) {
                           return 'Card expirat';
                         }
                         return null;
                       },
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Câmp pentru CVV
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'CVV',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      validator: (value) => (value?.length ?? 0) != 3 ? 'CVV invalid' : null,
                      obscureText: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.save_alt_outlined),
                label: const Text('Salvează Cardul'),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Simulare salvare
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cardul a fost salvat cu succes (simulare).'), backgroundColor: Colors.green),
                    );
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  )
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// Formatter ajutător pentru numărul cardului (adaugă spații)
class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;
    if (text.length > 16) text = text.substring(0, 16);
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      final nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write(' ');
      }
    }
    final string = buffer.toString();
    return newValue.copyWith(text: string, selection: TextSelection.collapsed(offset: string.length));
  }
}

// Formatter ajutător pentru data de expirare (adaugă '/')
class _CardDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;
    if (text.length == 2 && oldValue.text.length == 1) {
      text += '/';
    }
    return newValue.copyWith(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

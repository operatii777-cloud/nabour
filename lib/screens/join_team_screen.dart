import 'package:flutter/material.dart';

class JoinTeamScreen extends StatelessWidget {
  const JoinTeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alătură-te Echipei Nabour'),
      ),
      // CORECȚIE: Am eliminat 'const'-ul de aici pentru a permite apelarea funcțiilor
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Alătură-te echipei Nabour',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Bun venit! Pentru a te înregistra ca partener Nabour, ai nevoie de câteva informații de bază:',
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('Procesul de Înregistrare:'),
            const SizedBox(height: 8),
            const Text(
              '1. Specificații autovehicul\n'
              '   — Marca, modelul, anul fabricației, numărul de înmatriculare, ITP valabil, asigurare RCA.\n\n'
              '2. Fotografie șofer\n'
              '   — O fotografie clară a conducătorului auto.\n\n'
              '3. Fotografie autovehicul\n'
              '   — O fotografie clară a mașinii (față/lateral).\n\n'
              '4. Așteptați validarea contului de către echipa noastră.',
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text(
                'Vă mulțumim pentru interes și vă urăm bun venit în echipă!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Funcție ajutătoare pentru a formata titlurile de secțiune
  static Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
      ),
    );
  }

}

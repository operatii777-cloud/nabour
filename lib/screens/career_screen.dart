import 'package:flutter/material.dart';

class CareerScreen extends StatelessWidget {
  const CareerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carieră la Nabour'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               Icon(Icons.work_history_outlined, size: 80, color: Colors.blueGrey),
               SizedBox(height: 20),
               Text(
                'Alătură-te Echipei Noastre!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
               SizedBox(height: 12),
               Text(
                'Momentan nu există posturi deschise. Aici vor fi afișate oportunitățile de carieră pentru a face parte din echipa care dezvoltă și administrează Nabour. Vă mulțumim pentru interes!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

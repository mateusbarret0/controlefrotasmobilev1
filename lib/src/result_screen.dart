import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  // Nome da rota para navegação nomeada
  static const routeName = '/result';

  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Recebe os dados passados como argumento pela rota
    final String scannedData =
        ModalRoute.of(context)?.settings.arguments as String? ??
        'Nenhum dado recebido';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado do Scan'),
        backgroundColor: Colors.grey[850], // Mesma cor da tela de scan
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Dado do QR Code Lido:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  // Permite copiar o texto
                  scannedData,
                  style: const TextStyle(fontSize: 18, color: Colors.black),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                  ); // Volta para a tela anterior (scanner)
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Cor do botão
                ),
                child: const Text('Escanear Novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

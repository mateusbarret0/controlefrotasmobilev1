import 'package:flutter/material.dart';

class ConsultaViagensScreen extends StatefulWidget {
  final Map<String, dynamic> userInfo;
  const ConsultaViagensScreen({super.key, required this.userInfo});

  @override
  State<ConsultaViagensScreen> createState() => _ConsultaViagensScreenState();
}

class _ConsultaViagensScreenState extends State<ConsultaViagensScreen> {
  // Lista de viagens com status dinâmico
  final List<Map<String, dynamic>> viagens = [
    {
      'numero': '01',
      'veiculo': 'Mercedes-Benz 413 Van',
      'saida': '23/08/2024 - 12:30',
      'chegada': '23/08/2024 - 13:30',
      'km': '27km',
      'paradas': '2',
      'status': 'pendente',
    },
    {
      'numero': '02',
      'veiculo': 'Fiat Ducato Minibus',
      'saida': '15/09/2024 - 15:00',
      'chegada': '15/09/2024 - 17:00',
      'km': '53km',
      'paradas': '5',
      'status': 'pendente',
    },
    {
      'numero': '03',
      'veiculo': 'Ford Transit - 2021',
      'saida': '02/02/2024 - 18:30',
      'chegada': '02/02/2024 - 20:00',
      'km': '84km',
      'paradas': '4',
      'status': 'pendente',
    },
  ];

  void atualizarStatus(int index, String novoStatus) {
    setState(() {
      viagens[index]['status'] = novoStatus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isSupervisor = widget.userInfo['id_tipo_usuario'] == 1;

    return Scaffold(
      backgroundColor: const Color(0xFF2B2B2B),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF424242),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Voltar',
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.userInfo['nome']?.toString() ??
                                'Nome não disponível',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.userInfo['descricao']?.toString() ??
                                'Descrição não disponível',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.settings, color: Colors.blue),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: const Row(
                  children: [
                    Expanded(
                      child: TextField(
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Pesquisar viagem',
                          hintStyle: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    Icon(Icons.search, color: Colors.white),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: viagens.length,
                  itemBuilder: (context, index) {
                    final viagem = viagens[index];
                    return _ViagemCard(
                      numero: viagem['numero'],
                      veiculo: viagem['veiculo'],
                      saida: viagem['saida'],
                      chegada: viagem['chegada'],
                      km: viagem['km'],
                      paradas: viagem['paradas'],
                      status: viagem['status'],
                      isSupervisor: isSupervisor,
                      onAprovar: () => atualizarStatus(index, 'aprovada'),
                      onReprovar: () => atualizarStatus(index, 'reprovada'),
                    );
                  },
                ),
              ),
              const Center(
                child: Text(
                  'ALFAID v2.8.15 - BETA',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _ViagemCard extends StatelessWidget {
  final String numero;
  final String veiculo;
  final String saida;
  final String chegada;
  final String km;
  final String paradas;
  final String status;
  final bool isSupervisor;
  final VoidCallback onAprovar;
  final VoidCallback onReprovar;

  const _ViagemCard({
    required this.numero,
    required this.veiculo,
    required this.saida,
    required this.chegada,
    required this.km,
    required this.paradas,
    required this.status,
    required this.isSupervisor,
    required this.onAprovar,
    required this.onReprovar,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusTexto;

    switch (status) {
      case 'aprovada':
        statusColor = Colors.green;
        statusTexto = 'Aprovada';
        break;
      case 'reprovada':
        statusColor = Colors.red;
        statusTexto = 'Reprovada';
        break;
      default:
        statusColor = Colors.grey;
        statusTexto = 'Pendente';
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF424242),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ... (Title Row, Veículo, Saída, Chegada, Km - unchanged) ...
          Row(
            children: [
              Text(
                'Viagem - $numero',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  border: Border.all(color: statusColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusTexto,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Veículo: $veiculo',
            style: const TextStyle(color: Colors.white),
          ),
          Text('Saída: $saida', style: const TextStyle(color: Colors.white)),
          Text(
            'Chegada: $chegada',
            style: const TextStyle(color: Colors.white),
          ),
          Text(
            'Km percorrido: $km',
            style: const TextStyle(color: Colors.white),
          ),
          Text(
            'Paradas realizadas: $paradas',
            style: const TextStyle(color: Colors.white),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(), // Pushes buttons to the right
              if (isSupervisor) ...[
                // Buttons on the right
                IconButton(
                  iconSize: 30,
                  icon: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                  ),
                  onPressed: onAprovar,
                  tooltip: 'Aprovar',
                  // Add padding/constraints if icons feel too close to edge
                  constraints: const BoxConstraints(), // Remove default padding
                  padding: EdgeInsets.zero, // Remove default padding
                ),
                const SizedBox(
                  width: 4,
                ), // Optional small space between buttons
                IconButton(
                  iconSize: 30,
                  icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                  onPressed: onReprovar,
                  tooltip: 'Reprovar',
                  // Add padding/constraints if icons feel too close to edge
                  constraints: const BoxConstraints(), // Remove default padding
                  padding: EdgeInsets.zero, // Remove default padding
                ),
              ],
            ],
          ),
          // --- MODIFICATION END ---
          // Remove the old SizedBox(height: 6) and the old button Row
        ],
      ),
    );
  }
}

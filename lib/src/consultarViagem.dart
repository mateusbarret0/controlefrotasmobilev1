import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api.dart';

class ConsultaViagensScreen extends StatefulWidget {
  final Map<String, dynamic> userInfo;
  const ConsultaViagensScreen({super.key, required this.userInfo});

  @override
  State<ConsultaViagensScreen> createState() => _ConsultaViagensScreenState();
}

class _ConsultaViagensScreenState extends State<ConsultaViagensScreen> {
  List<Map<String, dynamic>> viagens = [];
  List<Map<String, dynamic>> viagensFiltradas = [];
  bool isLoading = true;
  late int codMotorista;
  String filtroGeral = '';

  @override
  void initState() {
    super.initState();
    codMotorista = widget.userInfo['data']['cod_usur'];
    _fetchViagens();
  }

  Future<void> _fetchViagens() async {
    try {
      final fetchedViagens = await ApiService().fetchViagens(codMotorista);
      setState(() {
        viagens = fetchedViagens;
        viagensFiltradas = fetchedViagens;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar viagens: $e')));
    }
  }

  void _filtrarViagens() {
    setState(() {
      viagensFiltradas =
          viagens.where((viagem) {
            final codRota = viagem['cod_rota'].toString();
            final nomeVeiculo = '${viagem['modelo']} - ${viagem['placa']}';
            final dataPartida = DateFormat(
              'dd/MM/yyyy',
            ).format(DateTime.parse(viagem['data_hora_partida']));

            final filtroLower = filtroGeral.toLowerCase();

            return codRota.contains(filtroLower) ||
                nomeVeiculo.toLowerCase().contains(filtroLower) ||
                dataPartida.contains(filtroLower);
          }).toList();
    });
  }

  void atualizarStatus(int index, String novoStatus, {String? motivo}) async {
    final codRota = viagensFiltradas[index]['cod_rota'];

    try {
      final response = await ApiService().atualizarStatusRota(
        codRota,
        novoStatus,
        motivo: motivo,
      );

      if (!mounted) return;
      if (response['success']) {
        setState(() {
          viagensFiltradas[index]['status_rota'] = novoStatus;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "Status atualizado com sucesso!",
              style: TextStyle(fontSize: 14),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar status: ${response['message']}'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro de conexão: $e')));
    }
  }

  Future<void> mostrarModalReprovacao(int index) async {
    String motivo = '';
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Motivo da Reprovação',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color.fromRGBO(66, 66, 66, 1),
          content: TextField(
            onChanged: (value) => motivo = value,
            decoration: InputDecoration(
              hintText: "Digite o motivo",
              hintStyle: TextStyle(color: Colors.white),
            ),
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                atualizarStatus(index, 'reprovada', motivo: motivo);
              },
              child: Text(
                'Confirmar',
                style: TextStyle(color: Colors.blueAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isSupervisor = widget.userInfo['data']['id_tipo_usuario'] == 1;
    print("viagens: $viagensFiltradas");

    return Scaffold(
      backgroundColor: const Color(0xFF2B2B2B),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _buildHeader(),
              const SizedBox(height: 12),
              _buildSearchBar(),
              const SizedBox(height: 12),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Expanded(child: _buildViagensList(isSupervisor)),
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

  Widget _buildHeader() {
    return Container(
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
                  widget.userInfo['data']['nome']?.toString() ??
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
                  widget.userInfo['data']['descricao']?.toString() ??
                      'Descrição não disponível',
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.settings, color: Colors.blue),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Pesquisar viagem:',
                hintStyle: TextStyle(color: Colors.white),
              ),
              onChanged: (value) {
                filtroGeral = value;
                _filtrarViagens();
              },
            ),
          ),
          const Icon(Icons.search, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildViagensList(bool isSupervisor) {
    return ListView.builder(
      itemCount: viagensFiltradas.length,
      itemBuilder: (context, index) {
        final viagem = viagensFiltradas[index];

        final DateFormat formatter = DateFormat('dd/MM/yyyy - HH:mm:ss');
        final String formattedSaida = formatter.format(
          DateTime.parse(viagem['data_hora_partida']),
        );
        final String formattedChegada = formatter.format(
          DateTime.parse(viagem['data_hora_chegada']),
        );

        return _ViagemCard(
          numero: viagem['cod_rota'].toString(),
          veiculo: '${viagem['modelo']} - ${viagem['placa']}',
          saida: formattedSaida,
          chegada: formattedChegada,
          km: viagem['km_percorrido'].toString(),
          paradas: viagem['num_paradas'].toString(),
          status: viagem['status_rota'] ?? 'Pendente',
          isSupervisor: isSupervisor,
          onAprovar: () => atualizarStatus(index, 'aprovada'),
          onReprovar: () => mostrarModalReprovacao(index),
        );
      },
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
              const Spacer(),
              if (isSupervisor) ...[
                IconButton(
                  iconSize: 30,
                  icon: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                  ),
                  onPressed: onAprovar,
                  tooltip: 'Aprovar',
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 4),
                IconButton(
                  iconSize: 30,
                  icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                  onPressed: onReprovar,
                  tooltip: 'Reprovar',
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

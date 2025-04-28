import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api.dart';
import '../src/viagemDetalhes.dart';

class ConsultaViagensScreen extends StatefulWidget {
  final Map<String, dynamic> userInfo;
  final List<dynamic> steps;
  const ConsultaViagensScreen({
    super.key,
    required this.userInfo,
    this.steps = const [],
  });

  @override
  State<ConsultaViagensScreen> createState() => _ConsultaViagensScreenState();
}

class _ConsultaViagensScreenState extends State<ConsultaViagensScreen> {
  List<Map<String, dynamic>> viagens = [];
  List<Map<String, dynamic>> viagensFiltradas = [];
  bool isLoading = true;
  late int codMotorista;
  late int idTipoUsuario;
  String filtroGeral = '';

  @override
  void initState() {
    super.initState();
    codMotorista = widget.userInfo['data']['cod_usur'];
    idTipoUsuario = widget.userInfo['data']['id_tipo_usuario'];
    _fetchViagens();
  }

  Future<void> _fetchViagens() async {
    print("AQUI BURRO DE TETA: ${widget.userInfo}");
    try {
      final fetchedViagens = await ApiService().fetchViagens(
        codMotorista,
        idTipoUsuario,
      );
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
    final codSuperv = widget.userInfo['data']['cod_usur'];
    try {
      final response = await ApiService().atualizarStatusRota(
        codRota,
        codSuperv,
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
                atualizarStatus(index, 'Reprovado', motivo: motivo);
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
          // const Icon(Icons.settings, color: Colors.blue),
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
    if (viagensFiltradas.isEmpty && !isLoading) {
      return Center(
        child: Text(
          'Nenhuma viagem encontrada.',
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: viagensFiltradas.length,
      itemBuilder: (context, index) {
        final viagem = viagensFiltradas[index];

        final DateFormat formatter = DateFormat('dd/MM/yyyy - HH:mm:ss');
        final String formattedSaida =
            viagem['data_hora_partida'] != null
                ? formatter.format(DateTime.parse(viagem['data_hora_partida']))
                : 'N/A';
        final String formattedChegada =
            viagem['data_hora_chegada'] != null
                ? formatter.format(DateTime.parse(viagem['data_hora_chegada']))
                : 'N/A';

        return _ViagemCard(
          key: ValueKey(viagem['cod_rota']),
          numero: viagem['cod_rota']?.toString() ?? 'N/A',
          veiculo: '${viagem['modelo'] ?? 'N/A'} - ${viagem['placa'] ?? 'N/A'}',
          saida: formattedSaida,
          chegada: formattedChegada,
          km: viagem['km_percorrido']?.toString() ?? 'N/A',
          paradas: viagem['num_paradas']?.toString() ?? 'N/A',
          status: viagem['status_rota']?.toString() ?? 'Pendente',
          isSupervisor: isSupervisor,
          onAprovar: () => atualizarStatus(index, 'Aprovado'),
          onReprovar: () => mostrarModalReprovacao(index),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ViagemDetalhesScreen(viagemData: viagem),
              ),
            );
          },
        );
      },
    );
  }
}

class _ViagemCard extends StatelessWidget {
  final ValueKey key;
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
  final VoidCallback onTap;

  const _ViagemCard({
    required this.key,
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
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusTexto;

    switch (status) {
      case 'Aprovado':
        statusColor = Colors.green;
        statusTexto = 'Aprovado';
        break;
      case 'Reprovado':
        statusColor = Colors.red;
        statusTexto = 'Reprovado';
        break;
      default:
        statusColor = const Color.fromARGB(255, 255, 200, 0);
        statusTexto = status;
        break;
    }

    final bool isActionable = status != 'Aprovado' && status != 'Reprovado';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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
                    icon: Icon(
                      Icons.check_circle_outline,
                      color: isActionable ? Colors.green : Colors.grey,
                    ),
                    onPressed: isActionable ? onAprovar : null,
                    tooltip: isActionable ? 'Aprovar' : 'Status já definido',
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    iconSize: 30,
                    icon: Icon(
                      Icons.cancel_outlined,
                      color: isActionable ? Colors.red : Colors.grey,
                    ),
                    onPressed: isActionable ? onReprovar : null,
                    tooltip: isActionable ? 'Reprovar' : 'Status já definido',
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

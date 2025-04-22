import 'package:controlefrotasmobilev1/src/consultarViagem.dart';
import 'package:controlefrotasmobilev1/src/login.dart';
import 'package:flutter/material.dart';
import 'vincularVeiculo.dart';
import '../services/api.dart';

class Menu extends StatefulWidget {
  final Map<String, dynamic> userData;

  const Menu({super.key, required this.userData});

  @override
  _MenuState createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  late Map<String, dynamic> userInfo;
  bool _isLoading = false;
  bool aceitouTermo = false;

  @override
  void initState() {
    super.initState();
    userInfo =
        widget.userData['data'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(widget.userData['data'])
            : {};

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarEExibirTermos();
    });
  }

  void _verificarEExibirTermos() {
    if (!mounted) return;
    final termoAceito = userInfo['data']['termo'];
    if (termoAceito == null || termoAceito.toString().toLowerCase() != 's') {
      _mostrarTermoDeResponsabilidade();
    }
  }

  Future<void> _mostrarTermoDeResponsabilidade() async {
    if (!mounted) return;

    final aceitou = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromRGBO(66, 66, 66, 1),
          title: const Text(
            'Termo de Responsabilidade',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const SingleChildScrollView(
            child: Text(
              'Ao continuar, você declara estar ciente de que é responsável pelo uso adequado dos veículos da frota e pelo registro fiel das rotas realizadas durante sua operação, seguindo as normas e procedimentos estabelecidos pela empresa.',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          actions: [
            TextButton(
              onPressed:
                  _isLoading ? null : () => Navigator.of(context).pop(true),
              child: const Text(
                'ACEITO',
                style: TextStyle(color: Colors.blueAccent),
              ),
            ),
            TextButton(
              onPressed:
                  _isLoading ? null : () => Navigator.of(context).pop(false),
              child: const Text(
                'NÃO ACEITO',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    final String statusTermo = (aceitou == true) ? 'S' : 'N';

    setState(() => _isLoading = true);
    await _atualizarStatusTermo(statusTermo);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _atualizarStatusTermo(String status) async {
    final id = userInfo['data']['cod_usur'];
    if (id == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "Erro crítico: ID do usuário ausente. Contate o suporte.",
              style: TextStyle(fontSize: 14),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 3),
          ),
        );

        _navegarParaLogin();
      }
      return;
    }

    try {
      final api = ApiService();
      final result = await api.atualizarTermo(id, status);

      if (!mounted) return;

      if (result['success'] == true) {
        if (status == 'S') {
          setState(() {
            userInfo['data']['termo'] = 's';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                "Termo de responsabilidade aceito com sucesso!",
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                "Você precisa aceitar o termo de responsabilidade para continuar.",
                style: TextStyle(fontSize: 14),
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
          _navegarParaLogin();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Erro ao salvar atualização do termo (${status == 'S' ? 'Aceite' : 'Recusa'}): ${result['message']}",
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        _navegarParaLogin();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "Erro de conexão ao atualizar termo. Verifique sua internet.",
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
      _navegarParaLogin();
    }
  }

  void _navegarParaLogin() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Você precisa aceitar o termo de responsabilidade para continuar.",
            style: TextStyle(fontSize: 14),
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String nome =
        userInfo['data']['nome']?.toString() ?? 'Nome Indisponível';
    final String descricao =
        userInfo['data']['descricao']?.toString() ?? 'Descrição Indisponível';

    return Scaffold(
      backgroundColor: const Color.fromRGBO(43, 43, 43, 1),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 50),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(66, 66, 66, 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nome,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            descricao,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Configurações (a implementar)',
                            ),
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.settings, color: Colors.blue),
                      tooltip: 'Configurações',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Controle de Frotas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              _buildMenuButton(
                title: 'Iniciar Viagem',
                subtitle: 'Escaneie o QR Code do veículo',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ScannerScreen(userInfo: userInfo),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              _buildMenuButton(
                title: 'Consultar Viagens',
                subtitle: 'Consulte as suas viagens já realizadas',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              ConsultaViagensScreen(userInfo: userInfo),
                    ),
                  );
                },
              ),

              const Spacer(),
              const Center(
                child: Text(
                  'ALFAID v2.8.15 - BETA',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    IconData iconData = Icons.arrow_forward_ios,
    Color iconColor = Colors.blue,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(66, 66, 66, 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(iconData, color: iconColor, size: 20),
          ],
        ),
      ),
    );
  }
}

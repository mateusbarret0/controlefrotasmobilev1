import 'package:controlefrotasmobilev1/src/consultarViagem.dart';
import 'package:flutter/material.dart';
import 'scanner_screen.dart';

class Menu extends StatefulWidget {
  final Map<String, dynamic> userData;

  const Menu({super.key, required this.userData});

  @override
  _MenuState createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  @override
  Widget build(BuildContext context) {
    final userInfo =
        widget.userData.containsKey('data') && widget.userData['data'] is Map
            ? widget.userData['data'] as Map<String, dynamic>
            : <String, dynamic>{};

    return Scaffold(
      backgroundColor: const Color.fromRGBO(
        43,
        43,
        43,
        1,
      ), // Cor de fundo escura
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
                      // Use Expanded para evitar overflow se o nome for longo
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userInfo['nome']?.toString() ??
                                'Nome não disponível', // Mensagem mais clara
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userInfo['descricao']?.toString() ??
                                'Descrição não disponível', // Mensagem mais clara
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
                          const SnackBar(
                            content: Text('Configurações (a implementar)'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.settings, color: Colors.blue),
                      tooltip: 'Configurações', // Adiciona dica
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Título "Controle de Frotas"
              const Text(
                'Controle de Frotas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Botão "Iniciar Viagem"
              _buildMenuButton(
                title: 'Iniciar Viagem',
                subtitle:
                    'Escaneie o QR Code do veículo', // Subtítulo mais descritivo
                onTap: () {
                  // Navega para a tela do Scanner
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ScannerScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Botão "Consultar Viagens"
              _buildMenuButton(
                title: 'Consultar Viagens',
                subtitle: 'Consulte as suas viagens já realizadas',
                // TODO: Implementar navegação para consulta de viagens
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

              const Spacer(), // Empurra a versão para baixo
              // Versão Beta
              const Center(
                child: Text(
                  'ALFAID v2.8.15 - BETA', // Use o nome/versão do seu app se desejar
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ),
              const SizedBox(
                height: 16,
              ), // Adiciona um pequeno espaço abaixo da versão
            ],
          ),
        ),
      ),
    );
  }

  // Helper para construir os botões do menu
  Widget _buildMenuButton({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    IconData iconData = Icons.arrow_forward_ios, // Ícone padrão
    Color iconColor = Colors.blue,
  }) {
    return InkWell(
      // InkWell para efeito visual ao tocar
      onTap: onTap,
      borderRadius: BorderRadius.circular(
        12,
      ), // Para o efeito acompanhar a borda
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ), // Ajuste padding
        decoration: BoxDecoration(
          color: const Color.fromRGBO(66, 66, 66, 1), // Cor do botão
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              // Para o texto ocupar o espaço disponível
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14, // Pode ajustar o tamanho
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ), // Pode ajustar o tamanho
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10), // Espaço entre texto e ícone
            Icon(iconData, color: iconColor, size: 20), // Ícone à direita
            // Removido IconButton desnecessário, InkWell já cuida do onTap
          ],
        ),
      ),
    );
  }
}

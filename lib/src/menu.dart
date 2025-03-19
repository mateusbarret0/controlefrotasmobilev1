import 'package:flutter/material.dart';

class Menu extends StatefulWidget {
  const Menu({super.key});
  @override
  _MenuState createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  @override
  Widget build(BuildContext context) {
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'MATEUS OLIVEIRA BARRETO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Motorista',
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.settings, color: Colors.blue),
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
                subtitle: 'Inicie uma viagem',
                onTap: () {},
              ),
              const SizedBox(height: 12),

              // Botão "Consultar Viagens"
              _buildMenuButton(
                title: 'Consultar Viagens',
                subtitle: 'Consulte as suas viagens já realizadas',
                onTap: () {},
              ),

              const Spacer(),

              // Versão Beta
              const Center(
                child: Text(
                  'ALFAID v2.8.15 - BETA',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ),
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
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(66, 66, 66, 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
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
            IconButton(
              onPressed: onTap,
              icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }
}

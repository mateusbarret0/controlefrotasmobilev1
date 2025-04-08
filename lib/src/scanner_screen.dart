import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'result_screen.dart'; // Importa a tela de resultado

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  // Controlador para o MobileScanner
  final MobileScannerController _scannerController = MobileScannerController(
    // Configurações opcionais do controlador:
    // facing: CameraFacing.back, // Câmera traseira (padrão)
    // detectionSpeed: DetectionSpeed.normal, // Velocidade de detecção
    returnImage: false, // Não precisamos da imagem, só dos dados
  );
  bool _isScanCompleted = false; // Flag para evitar múltiplas navegações

  // Função para reiniciar o scanner e o estado
  void _resetScan() {
    setState(() {
      _isScanCompleted = false;
    });
    // Garante que o controller reinicie se necessário (pode não ser preciso com _isScanCompleted)
    // _scannerController.start(); // Descomente se houver problemas ao voltar
  }

  @override
  void dispose() {
    // Libera o controlador quando o widget for descartado
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    // Define um tamanho para o quadrado do scanner
    final double scanWindowSize = screenSize.width * 0.7;

    return Scaffold(
      // AppBar similar à imagem (simplificada)
      appBar: AppBar(
        title: const Text('scanner qr code'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: Icon(Icons.code), // Ícone </> similar
          ),
        ],
      ),
      body: Center(
        // Container principal com bordas arredondadas e fundo escuro
        child: Container(
          width: screenSize.width * 0.9, // 90% da largura da tela
          height: screenSize.height * 0.85, // 85% da altura da tela
          decoration: BoxDecoration(
            color: Colors.grey[850], // Cor de fundo escura interna
            borderRadius: BorderRadius.circular(20), // Bordas arredondadas
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Container para o texto de instrução
              Container(
                padding: const EdgeInsets.all(20.0),
                margin: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 15.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(
                    0.3,
                  ), // Fundo levemente transparente
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'ESCANEIE O QRCODE DO VEÍCULO PARA SER VINCULADO A ELE E PODER INICIAR A VIAGEM.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),

              // Espaçamento
              const SizedBox(height: 20),

              // Área do Scanner
              SizedBox(
                width: scanWindowSize,
                height: scanWindowSize,
                child: ClipRRect(
                  // Garante que o preview fique dentro dos limites
                  borderRadius: BorderRadius.circular(
                    10,
                  ), // Bordas levemente arredondadas para o preview
                  child: MobileScanner(
                    controller: _scannerController,
                    // Define a janela de escaneamento (opcional, mas melhora o foco)
                    scanWindow: Rect.fromCenter(
                      center: Offset(
                        scanWindowSize / 2,
                        scanWindowSize / 2,
                      ), // Centralizado na SizedBox
                      width:
                          scanWindowSize *
                          0.9, // Janela um pouco menor que a área total
                      height: scanWindowSize * 0.9,
                    ),
                    onDetect: (capture) {
                      if (!_isScanCompleted) {
                        final List<Barcode> barcodes = capture.barcodes;
                        // Pega o primeiro código de barras detectado
                        if (barcodes.isNotEmpty &&
                            barcodes.first.rawValue != null) {
                          final String code = barcodes.first.rawValue!;
                          print('QR Code Detectado: $code'); // Para debug

                          setState(() {
                            _isScanCompleted =
                                true; // Marca como completo para evitar re-scan
                          });

                          // Para a câmera (opcional, mas bom para performance)
                          // _scannerController.stop(); // Pode causar problemas no reinício, usar flag é mais seguro

                          // Navega para a tela de resultado passando os dados
                          Navigator.pushNamed(
                            context,
                            ResultScreen.routeName,
                            arguments: code,
                          ).then(
                            (_) => _resetScan(),
                          ); // Reseta ao voltar da tela de resultado
                        }
                      }
                    },
                    errorBuilder: (context, error, child) {
                      // Exibe uma mensagem de erro se a câmera falhar
                      print('Erro no Scanner: $error');
                      return Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          color: Colors.red.withOpacity(0.8),
                          child: const Text(
                            'Erro ao iniciar a câmera. Verifique as permissões.',
                            style: TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Espaçamento
              const SizedBox(height: 30),

              // Botão de Câmera (similar ao da imagem)
              FloatingActionButton(
                onPressed: () {
                  // Ação opcional para o botão, como ligar/desligar flash ou escolher imagem
                  // _scannerController.toggleTorch(); // Exemplo: Ligar/desligar flash
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Botão de câmera (funcionalidade futura)'),
                    ),
                  );
                },
                backgroundColor: Colors.blue, // Cor azul do botão
                child: const Icon(Icons.camera_alt, color: Colors.white),
              ),

              // Espaçador para empurrar a versão para baixo
              const Spacer(),

              // Texto da Versão
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Text(
                  'ALFAID v2.8.15 - BETA', // Texto como na imagem
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

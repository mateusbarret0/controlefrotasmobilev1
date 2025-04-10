import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:controlefrotasmobilev1/services/api.dart';
import 'package:controlefrotasmobilev1/models/vehicle_model.dart'; // Modelo de veículo

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    returnImage: false,
  );
  bool _isScanCompleted = false;
  bool _isLoading = false;
  String? _errorMessage;
  final ApiService _apiService = ApiService();

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _linkDriverToVehicle(String qrCodeData) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Extrair o hash do QR Code (ajuste conforme seu formato)
      final vehicleHash =
          qrCodeData; // Ou extrair de um JSON se o QR contiver mais dados

      // 2. Enviar requisição para vincular motorista ao veículo
      final response = await _apiService.linkDriverToVehicle(
        vehicleHash: vehicleHash,
        // Outros dados necessários como ID do motorista
      );

      if (response['success'] == true) {
        // 3. Se vinculado com sucesso, iniciar a rota
        final routeResponse = await _apiService.startRoute(
          vehicleId: response['vehicle_id'],
          driverId: response['driver_id'],
        );

        if (routeResponse['success'] == true) {
          // Navegar para tela de rota iniciada com sucesso
          Navigator.pushReplacementNamed(
            context,
            '/route_started',
            arguments: VehicleData.fromJson(response['vehicle_data']),
          );
        } else {
          setState(() {
            _errorMessage = routeResponse['message'] ?? 'Erro ao iniciar rota';
          });
        }
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Erro ao vincular veículo';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro de conexão: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
        _isScanCompleted = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final double scanWindowSize = screenSize.width * 0.7;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner QR Code'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: Icon(Icons.code),
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: Container(
              width: screenSize.width * 0.9,
              height: screenSize.height * 0.85,
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20.0),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 15.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'ESCANEIE O QRCODE DO VEÍCULO PARA SER VINCULADO A ELE E PODER INICIAR A VIAGEM.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: scanWindowSize,
                    height: scanWindowSize,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: MobileScanner(
                        controller: _scannerController,
                        onDetect: (capture) {
                          if (!_isScanCompleted && !_isLoading) {
                            final barcodes = capture.barcodes;
                            if (barcodes.isNotEmpty &&
                                barcodes.first.rawValue != null) {
                              final code = barcodes.first.rawValue!;
                              print('QR Code Detectado: $code');
                              setState(() => _isScanCompleted = true);
                              _linkDriverToVehicle(code);
                            }
                          }
                        },
                        errorBuilder: (context, error, child) {
                          return Center(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              color: Colors.red.withOpacity(0.8),
                              child: Text(
                                error.toString(),
                                style: const TextStyle(color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  FloatingActionButton(
                    onPressed: () => _scannerController.toggleTorch(),
                    backgroundColor: Colors.blue,
                    child: const Icon(Icons.flash_on, color: Colors.white),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Text(
                      'ALFAID v2.8.15 - BETA',
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          if (_errorMessage != null)
            Positioned(
              bottom: 100,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[800],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

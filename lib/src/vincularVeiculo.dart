import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:controlefrotasmobilev1/services/api.dart';
import 'package:controlefrotasmobilev1/src/verificarHodometro.dart';
import 'dart:convert';

class ScannerScreen extends StatefulWidget {
  final Map<String, dynamic> userInfo;
  const ScannerScreen({super.key, required this.userInfo});

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

  Future<void> _linkMotorista(String qrCodeRawValue) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final Map<String, dynamic> parsedData = jsonDecode(qrCodeRawValue);
      final routeInfo = parsedData['linkDriver'];

      final int codUsur = widget.userInfo['data']['cod_usur'];

      final response = await _apiService.linkMotorista(
        routeInfo: routeInfo,
        codUsur: codUsur,
      );
      if (response['success'] == true) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    HodometroScreen(routeInfo: routeInfo, codUsur: codUsur),
          ),
        );
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Erro ao iniciar rota';
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
        title: const Text('Vincular Veículo'),
        backgroundColor: Color(0xFF0261A3),
      ),
      body: Stack(
        children: [
          Center(
            child: Container(
              width: screenSize.width * 0.9,
              height: screenSize.height * 0.85,
              decoration: BoxDecoration(
                color: Color.fromRGBO(66, 66, 66, 1),
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
                      color: Color.fromARGB(43, 43, 43, 1),
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

                              print('Conteúdo do QR Code: $code');

                              setState(() => _isScanCompleted = true);
                              _linkMotorista(code);
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

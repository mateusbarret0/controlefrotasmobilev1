import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:controlefrotasmobilev1/services/api.dart';
import 'package:controlefrotasmobilev1/src/verificarHodometro.dart';
import 'dart:convert';

class ScannerScreen extends StatefulWidget {
  final Map<String, dynamic> userInfo;
  final Map<String, dynamic> userData;
  const ScannerScreen({
    super.key,
    required this.userInfo,
    required this.userData,
  });

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    // detectionSpeed: DetectionSpeed.normal,
    // detectionTimeoutMs: 250,
    // facing: CameraFacing.back,
    // torchEnabled: false,
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
    if (_isLoading || !_isScanCompleted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final Map<String, dynamic> parsedData = jsonDecode(qrCodeRawValue);
      final routeInfo = parsedData['linkDriver'];

      if (routeInfo == null) {
        throw FormatException(
          "QR Code não contém a informação 'linkDriver' esperada.",
        );
      }

      final int codUsur = widget.userInfo['data']['cod_usur'];

      final response = await _apiService.linkMotorista(
        routeInfo: routeInfo,
        codUsur: codUsur,
      );

      if (!mounted) return;

      if (response['success'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => HodometroScreen(
                  routeInfo: routeInfo,
                  codUsur: codUsur,
                  userData: widget.userData,
                ),
          ),
        );
      } else {
        setState(() {
          _errorMessage =
              response['message'] ?? 'Erro ao vincular motorista à rota.';
          _isLoading = false;
          _isScanCompleted = false;
        });
      }
    } on FormatException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Formato inválido do QR Code: ${e.message}';
        _isLoading = false;
        _isScanCompleted = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Erro durante o vínculo: $e';
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
        title: const Text(
          'Vincular Veículo',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0261A3),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Center(
            child: Container(
              width: screenSize.width * 0.9,
              height: screenSize.height * 0.85,
              decoration: BoxDecoration(
                color: const Color.fromRGBO(66, 66, 66, 1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 15.0,
                    ),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(43, 43, 43, 1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Aponte a câmera para o QR CODE do veículo para iniciar a viagem.',
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
                            final List<Barcode> barcodes = capture.barcodes;
                            if (barcodes.isNotEmpty &&
                                barcodes.first.rawValue != null &&
                                barcodes.first.rawValue!.isNotEmpty) {
                              final String code = barcodes.first.rawValue!;

                              debugPrint('QR Code Detectado: $code');

                              setState(() => _isScanCompleted = true);

                              _linkMotorista(code);
                            } else {
                              debugPrint(
                                'QR Code detectado, mas sem valor rawValue.',
                              );
                            }
                          }
                        },
                        errorBuilder: (context, error, child) {
                          String displayError = 'Erro no Scanner';
                          if (error is MobileScannerException) {
                            displayError = error.errorCode.toString();
                            if (error.errorCode ==
                                MobileScannerErrorCode.permissionDenied) {
                              displayError =
                                  "Permissão da câmera negada. Habilite nas configurações do app.";
                            }
                          } else {
                            displayError = error.toString();
                          }
                          debugPrint("Erro MobileScanner: $error");

                          return Center(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                displayError,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  ValueListenableBuilder<MobileScannerState>(
                    valueListenable: _scannerController,
                    builder: (context, state, child) {
                      final bool isTorchAvailable =
                          state.torchState != TorchState.unavailable;

                      return FloatingActionButton(
                        tooltip: 'Lanterna',
                        onPressed:
                            isTorchAvailable
                                ? () => _scannerController.toggleTorch()
                                : null,
                        backgroundColor:
                            isTorchAvailable ? Colors.blue : Colors.grey,
                        child: Icon(
                          state.torchState == TorchState.on
                              ? Icons.flash_off
                              : Icons.flash_on,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),

                  const Spacer(),
                  if (_errorMessage != null && !_isLoading)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 10.0,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[800]?.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Text(
                      'ALFAID v2.8.15 - BETA',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

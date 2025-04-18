import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import '../services/api.dart';
import 'package:controlefrotasmobilev1/src/iniciarViagem.dart';
import 'package:geolocator/geolocator.dart';

class HodometroScreen extends StatefulWidget {
  final dynamic routeInfo;
  final int codUsur;

  const HodometroScreen({
    super.key,
    required this.routeInfo,
    required this.codUsur,
  });

  @override
  State<HodometroScreen> createState() => _HodometroScreenState();
}

class _HodometroScreenState extends State<HodometroScreen> {
  List<CameraDescription>? _cameras;
  CameraController? _cameraController;
  CameraDescription? _selectedCamera;
  int _selectedCameraIndex = 0;

  XFile? _imageFile;
  bool _isCameraInitialized = false;
  bool _isTakingPicture = false;
  bool _isAnalyzing = false;
  bool _isSwitchingCamera = false;

  String? _analysisResult;
  String? _errorMessage;

  String? _confirmedMileage;
  bool _confirmationChecked = false;

  final String? _apiKey = 'AIzaSyCRKkFRIjFRUcNTjpfm46y08FOu2piqvFM';

  @override
  void initState() {
    super.initState();
    if (_apiKey == null || _apiKey!.isEmpty) {
      _errorMessage = 'Erro Crítico: Chave da API do Gemini não configurada!';
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCamera();
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera([int cameraIndex = 0]) async {
    if (_isSwitchingCamera) return;

    setState(() {
      _isCameraInitialized = false;
      _isSwitchingCamera = true;
      _errorMessage = null;
    });

    try {
      _cameras ??= await availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _errorMessage = "Nenhuma câmera encontrada neste dispositivo.";
          _isCameraInitialized = false;
          _isSwitchingCamera = false;
        });
        return;
      }

      _selectedCameraIndex = cameraIndex % _cameras!.length;
      _selectedCamera = _cameras![_selectedCameraIndex];

      await _cameraController?.dispose();

      _cameraController = CameraController(
        _selectedCamera!,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
        _errorMessage = null;
        _isSwitchingCamera = false;
      });
    } on CameraException catch (e) {
      setState(() {
        _errorMessage =
            "Erro ao inicializar a câmera (${_selectedCamera?.name}): ${e.description}";
        _isCameraInitialized = false;
        _isSwitchingCamera = false;
        _cameraController = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Erro inesperado ao configurar a câmera: $e";
        _isCameraInitialized = false;
        _isSwitchingCamera = false;
        _cameraController = null;
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras == null ||
        _cameras!.length < 2 ||
        _isSwitchingCamera ||
        _isTakingPicture ||
        _isAnalyzing) {
      return;
    }
    final nextCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;
    await _initializeCamera(nextCameraIndex);
  }

  Future<void> _takePicture() async {
    if (!_isCameraInitialized ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isTakingPicture ||
        _isAnalyzing ||
        _isSwitchingCamera) {
      return;
    }

    setState(() {
      _isTakingPicture = true;
      _errorMessage = null;
      _analysisResult = null;
    });

    try {
      final XFile image = await _cameraController!.takePicture();

      if (!mounted) return;

      setState(() {
        _imageFile = image;
      });
      await _analyzeImageWithGemini();
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "Erro ao tirar a foto: ${e.description}";
        _imageFile = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "Erro inesperado ao tirar a foto: $e";
        _imageFile = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isTakingPicture = false;
        });
      }
    }
  }

  Future<Uint8List?> _flipImageHorizontally(XFile imageFile) async {
    try {
      final Uint8List imageBytes = await imageFile.readAsBytes();

      final img.Image? originalImage = img.decodeImage(imageBytes);

      if (originalImage != null) {
        final img.Image flippedImage = img.copyFlip(
          originalImage,
          direction: img.FlipDirection.horizontal,
        );
        final List<int> flippedBytes = img.encodeJpg(flippedImage, quality: 90);
        return Uint8List.fromList(flippedBytes);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<void> _analyzeImageWithGemini() async {
    if (_imageFile == null || _apiKey == null || _apiKey!.isEmpty) {
      setState(() {
        _errorMessage =
            _apiKey == null || _apiKey!.isEmpty
                ? "Chave da API não configurada."
                : "Nenhuma imagem para analisar.";
        _isAnalyzing = false;
      });
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
      _analysisResult = null;
    });

    try {
      Uint8List imageBytes;

      final bool isFrontCamera =
          _selectedCamera?.lensDirection == CameraLensDirection.front;

      if (isFrontCamera) {
        final flippedBytes = await _flipImageHorizontally(_imageFile!);
        if (flippedBytes == null) {
          imageBytes = await _imageFile!.readAsBytes();
        } else {
          imageBytes = flippedBytes;
        }
      } else {
        imageBytes = await _imageFile!.readAsBytes();
      }

      final String base64Image = base64Encode(imageBytes);

      final Uri url = Uri.parse(
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey",
      );

      final String prompt = """
Você é uma IA especializada em análise de imagens para um sistema de controle de frotas.
A sua tarefa é analisar uma imagem enviada pelo motorista e identificar se ela contém um hodômetro veicular.

Se for um hodômetro, você deve tentar extrair a quilometragem exibida. Com base nisso, retorne um JSON no formato exato abaixo, incluindo o campo "confidence" (nível de confiança da IA sobre a leitura da imagem).
🔄 Formatos esperados:
✅ Quando for um hodômetro com quilometragem legível:

{
  "success": true,
  "isOdometer": true,
  "mileage": "123456",
  "confidence": 0.95
}

⚠️ Quando for um hodômetro, mas a leitura da quilometragem falhar:

{
  "success": false,
  "isOdometer": true,
  "error": "Não foi possível ler a quilometragem.",
  "confidence": 0.42
}

❌ Quando a imagem não parecer ser um hodômetro:

{
  "success": false,
  "isOdometer": false,
  "error": "A imagem não parece ser um hodômetro.",
  "confidence": 0.12
}

⚠️ Quando ocorrer qualquer outro erro genérico na análise:

{
  "success": false,
  "isOdometer": null,
  "error": "Erro na análise da imagem.",
  "confidence": 0.0
}

🧠 Instruções adicionais:

    A propriedade "confidence" deve ser um número decimal entre 0.0 e 1.0.

    Use "success": true somente quando a imagem for de um hodômetro e a quilometragem estiver legível.

    Sempre retorne o JSON exatamente no formato acima, com aspas duplas e campos correspondentes.

    A quilometragem deve ser retornada como string numérica, sem pontos ou vírgulas.
      """;

      final Map<String, dynamic> requestBody = {
        "contents": [
          {
            "parts": [
              {"text": prompt},
              {
                "inline_data": {"mime_type": "image/jpeg", "data": base64Image},
              },
            ],
          },
        ],
        "generationConfig": {
          "temperature": 0.1,
          "topP": 0.9,
          "topK": 1,
          "maxOutputTokens": 200,
          "responseMimeType": "application/json",
        },
        "safetySettings": [
          {
            "category": "HARM_CATEGORY_HARASSMENT",
            "threshold": "BLOCK_MEDIUM_AND_ABOVE",
          },
          {
            "category": "HARM_CATEGORY_HATE_SPEECH",
            "threshold": "BLOCK_MEDIUM_AND_ABOVE",
          },
          {
            "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
            "threshold": "BLOCK_MEDIUM_AND_ABOVE",
          },
          {
            "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
            "threshold": "BLOCK_MEDIUM_AND_ABOVE",
          },
        ],
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);

        if (responseBody['candidates'] != null &&
            responseBody['candidates'].isNotEmpty &&
            responseBody['candidates'][0]['content'] != null &&
            responseBody['candidates'][0]['content']['parts'] != null &&
            responseBody['candidates'][0]['content']['parts'].isNotEmpty) {
          try {
            final String resultJsonString =
                responseBody['candidates'][0]['content']['parts'][0]['text'];
            final Map<String, dynamic> resultData = jsonDecode(
              resultJsonString,
            );

            if (resultData['success'] == true &&
                resultData['isOdometer'] == true) {
              final String mileage = resultData['mileage'] ?? '';
              if (RegExp(r'^[0-9]+$').hasMatch(mileage) && mileage.isNotEmpty) {
                setState(() {
                  _analysisResult =
                      "Hodômetro identificado! Quilometragem: $mileage KM";
                });
              } else {
                setState(() {
                  _analysisResult =
                      "Hodômetro identificado, mas a leitura retornou um valor inesperado: '$mileage'. Tente novamente.";
                  _imageFile = null;
                });
              }

              final String rawJson =
                  responseBody['candidates'][0]['content']['parts'][0]['text'];
              final Map<String, dynamic> result = jsonDecode(rawJson);

              if (result['isOdometer'] == true && result['success'] == true) {
                String mileage = result['mileage'];
                await _showMileageConfirmationDialog(mileage, imageBytes);
              }
            } else {
              final String errorMsg =
                  resultData['error'] ?? "Erro desconhecido na resposta da IA.";
              setState(() {
                _analysisResult = errorMsg;
                _imageFile = null;
              });
            }
          } catch (e) {
            setState(() {
              _errorMessage = "Erro ao processar a resposta JSON da IA: $e";
              _imageFile = null;
            });
          }
        } else if (responseBody['promptFeedback'] != null &&
            responseBody['promptFeedback']['blockReason'] != null) {
          final blockReason = responseBody['promptFeedback']['blockReason'];
          final safetyRatings = responseBody['promptFeedback']['safetyRatings'];
          setState(() {
            _errorMessage =
                "A análise foi bloqueada pela IA. Motivo: $blockReason. Detalhes: $safetyRatings";
            _imageFile = null;
          });
        } else {
          setState(() {
            _errorMessage =
                "Resposta inesperada da API Gemini. Estrutura não reconhecida.";
            _imageFile = null;
          });
        }
      } else {
        setState(() {
          _errorMessage =
              "Erro na API Gemini (${response.statusCode}): ${response.body}";
          _imageFile = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "Erro durante a análise: $e";
        _imageFile = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  Future<Position?> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  bool _isMileageModalOpen = false;

  Future<void> _showMileageConfirmationDialog(
    String detectedMileage,
    Uint8List imageBytes,
  ) async {
    _cameraController?.dispose();
    _cameraController = null;
    setState(() {
      _isMileageModalOpen = true;
      _isCameraInitialized = false;
    });

    final _mileageController = TextEditingController(text: detectedMileage);
    bool _confirmationChecked = false;
    bool _isSaving = false;
    final String base64Image = base64Encode(imageBytes);

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color.fromRGBO(66, 66, 66, 1),
              title: const Text(
                'Confirmação de Quilometragem',
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'A leitura da quilometragem pode apresentar divergências dependendo do modelo do hodômetro. Corrija se necessário:',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _mileageController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Quilometragem identificada',
                      labelStyle: TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Color(0xFF797979),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(unselectedWidgetColor: Colors.white70),
                    child: CheckboxListTile(
                      value: _confirmationChecked,
                      onChanged:
                          (value) => setState(
                            () => _confirmationChecked = value ?? false,
                          ),
                      title: const Text(
                        'Confirmo que esta é a quilometragem real.',
                        style: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                      activeColor: Color.fromARGB(255, 0, 139, 239),
                      checkColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 2),
                    ),
                  ),
                ],
              ),
              actions: [
                _isSaving
                    ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      child: CircularProgressIndicator(),
                    )
                    : TextButton(
                      onPressed:
                          _confirmationChecked
                              ? () async {
                                setState(() => _isSaving = true);
                                try {
                                  final quilometragemConfirmada =
                                      _mileageController.text.trim();
                                  final api = ApiService();
                                  final response = await api.insertHodometro(
                                    quilometragem: quilometragemConfirmada,
                                    imageBase64: base64Image,
                                    routeInfo: widget.routeInfo,
                                    codUsur: widget.codUsur,
                                  );
                                  setState(() => _isSaving = false);
                                  if (!mounted) return;
                                  Navigator.of(context).pop(response);
                                } catch (ex) {
                                  setState(() => _isSaving = false);
                                  if (!mounted) return;
                                  Navigator.of(context).pop({
                                    'success': false,
                                    'message': ex.toString(),
                                  });
                                }
                              }
                              : null,
                      child: Text(
                        'Confirmar',
                        style: TextStyle(
                          color:
                              _confirmationChecked
                                  ? Color.fromARGB(255, 0, 139, 239)
                                  : Colors.white30,
                        ),
                      ),
                    ),
              ],
            );
          },
        );
      },
    );

    if (mounted) setState(() => _isMileageModalOpen = false);

    bool precisaReativarCamera = true;

    if (result != null && result['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green[800],
            content: const Text(
              'Registro salvo com sucesso.',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      }

      final position = await _getLocation();
      if (position != null) {
        if (!mounted) return;
        if (mounted) {
          precisaReativarCamera = false;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder:
                  (context) => IniciarViagem(
                    latitude: position.latitude,
                    longitude: position.longitude,
                    codUsur: widget.codUsur,
                    routeInfo: widget.routeInfo,
                  ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red,
              content: Text('Não foi possível obter localização'),
            ),
          );
        }
        precisaReativarCamera = true;
      }
    } else if (result != null && result['success'] == false) {
      final msg =
          result['message'] ?? 'Erro ao salvar registro da quilometragem.';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red[900],
            content: Text(msg, style: const TextStyle(color: Colors.white)),
          ),
        );
      }
      precisaReativarCamera = true;
    }

    if (precisaReativarCamera) {
      await _initializeCamera(_selectedCameraIndex);
    }
  }

  void _resetCapture() {
    setState(() {
      _imageFile = null;
      _analysisResult = null;
      _errorMessage = null;
      if (!_isCameraInitialized && !_isSwitchingCamera) {
        _initializeCamera(_selectedCameraIndex);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(43, 43, 43, 1),
      appBar: AppBar(
        title: const Text(
          'Registrar Hodômetro',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0261A3),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_cameras != null && _cameras!.length > 1)
            IconButton(
              icon: const Icon(Icons.switch_camera),
              tooltip: 'Trocar Câmera',
              onPressed:
                  (_isTakingPicture || _isAnalyzing || _isSwitchingCamera)
                      ? null
                      : _switchCamera,
            ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: const Color.fromRGBO(66, 66, 66, 1),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color.fromARGB(43, 43, 43, 1),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 7,
                  offset: const Offset(1, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 19),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (_isMileageModalOpen)
                  Container(
                    width: MediaQuery.of(context).size.width * 0.83,
                    height:
                        MediaQuery.of(context).size.width *
                        0.83 *
                        (_cameraController?.value.aspectRatio ?? (4 / 3)),
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(color: Colors.white24, width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                if (!_isMileageModalOpen)
                  Container(
                    width: MediaQuery.of(context).size.width * 0.83,
                    height:
                        MediaQuery.of(context).size.width *
                        0.83 *
                        (_cameraController?.value.aspectRatio ?? (4 / 3)),
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(color: Colors.white24, width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _buildCameraOrImageView(),
                  ),
                const SizedBox(height: 23),

                _buildStatusAndControls(),

                const SizedBox(height: 18),
                // if (_isAnalyzing)
                //   Padding(
                //     padding: const EdgeInsets.symmetric(vertical: 16.0),
                //     child: Column(
                //       children: [
                //         // Loading central maior e cor de destaque clara
                //         const SizedBox(
                //           height: 38,
                //           width: 38,
                //           child: CircularProgressIndicator(
                //             valueColor: AlwaysStoppedAnimation<Color>(
                //               Colors.cyanAccent,
                //             ),
                //             backgroundColor: Colors.white12,
                //             strokeWidth: 4,
                //           ),
                //         ),
                //         const SizedBox(height: 13),
                //         const Text(
                //           "Analisando imagem...",
                //           textAlign: TextAlign.center,
                //           style: TextStyle(
                //             color: Colors.white,
                //             fontSize: 17,
                //             fontWeight: FontWeight.w300,
                //           ),
                //         ),
                //       ],
                //     ),
                //   ),
                if (_errorMessage != null && !_isAnalyzing)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color.fromARGB(255, 255, 87, 87),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 17),
                Text(
                  'ALFAID v2.8.15 - BETA (Hodômetro v2)',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.25),
                    fontSize: 12,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCameraOrImageView() {
    if (_imageFile != null && !_isAnalyzing) {
      final bool wasFrontCamera =
          _selectedCamera?.lensDirection == CameraLensDirection.front;
      Widget imageWidget;

      if (kIsWeb) {
        imageWidget = Image.network(_imageFile!.path, fit: BoxFit.contain);
      } else {
        imageWidget = Image.file(File(_imageFile!.path), fit: BoxFit.contain);
      }
      if (wasFrontCamera && !kIsWeb) {
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.rotationY(3.14159),
          child: imageWidget,
        );
      } else {
        return imageWidget;
      }
    } else if ((!_isCameraInitialized && _errorMessage == null) ||
        _isSwitchingCamera) {
      return const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null && !_isCameraInitialized) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else if (_isCameraInitialized &&
        _cameraController != null &&
        _cameraController!.value.isInitialized) {
      try {
        return ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: OverflowBox(
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.85,
                height:
                    (MediaQuery.of(context).size.width * 0.85) /
                    _cameraController!.value.aspectRatio,
                child: CameraPreview(_cameraController!),
              ),
            ),
          ),
        );
      } catch (e) {
        return const Center(
          child: Text(
            "Erro ao exibir preview",
            style: TextStyle(color: Colors.white),
          ),
        );
      }
    } else {
      return const Center(
        child: Text(
          "Aguardando câmera...",
          style: TextStyle(color: Colors.white),
        ),
      );
    }
  }

  Widget _buildStatusAndControls() {
    if (_isMileageModalOpen) {
      return const SizedBox.shrink();
    }
    if (_isTakingPicture || _isSwitchingCamera) {
      return Column(
        children: const [
          SizedBox(
            height: 38,
            width: 38,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
              backgroundColor: Colors.white12,
              strokeWidth: 4,
            ),
          ),
          SizedBox(height: 12),
          Text(
            "Aguardando...",
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      );
    }

    if (_isAnalyzing) {
      return Column(
        children: const [
          SizedBox(
            height: 38,
            width: 38,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
              strokeWidth: 4,
            ),
          ),
          SizedBox(height: 13),
          Text(
            "Analisando imagem...",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      );
    }

    if (_imageFile != null && !_isAnalyzing) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text(
              'Tentar Novamente',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: _resetCapture,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 12),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      );
    }

    if (_isCameraInitialized &&
        _cameraController != null &&
        _cameraController!.value.isInitialized) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _selectedCamera?.lensDirection == CameraLensDirection.front
                ? "Câmera Frontal Ativa. Aponte para o HODÔMETRO."
                : "Aponte para o HODÔMETRO e tire a foto.",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
          const SizedBox(height: 15),
          FloatingActionButton.large(
            onPressed: _takePicture,
            tooltip: 'Capturar Hodômetro',
            backgroundColor: const Color(0xFF0261A3),
            child: const Icon(Icons.camera_alt, size: 36, color: Colors.white),
          ),
        ],
      );
    }
    if ((_errorMessage != null && !_isCameraInitialized) ||
        (!_isCameraInitialized && !_isSwitchingCamera)) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Text(
          _errorMessage ?? "Inicializando câmera...",
          style: const TextStyle(color: Colors.white, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }
    return const SizedBox(height: 70);
  }
}

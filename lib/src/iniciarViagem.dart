import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/api.dart';
import 'gps.dart';

class IniciarViagem extends StatefulWidget {
  final double latitude;
  final double longitude;
  final int codUsur;
  final dynamic routeInfo;

  const IniciarViagem({
    Key? key,
    required this.latitude,
    required this.longitude,
    required this.codUsur,
    required this.routeInfo,
  }) : super(key: key);

  @override
  _IniciarViagemState createState() => _IniciarViagemState();
}

class _IniciarViagemState extends State<IniciarViagem> {
  final ApiService _apiService = ApiService();
  String status = 'Carregando...';
  bool _isLoadingRoute = true;
  final Completer<GoogleMapController> _controllerCompleter = Completer();
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _initialCameraLocation;
  Map<String, dynamic>? _routeData;

  @override
  void initState() {
    super.initState();
    _initialCameraLocation = LatLng(widget.latitude, widget.longitude);
    _inicializarViagem();
  }

  Future<void> _inicializarViagem() async {
    setState(() {
      status = 'Iniciando viagem...';
      _isLoadingRoute = true;
    });
    try {
      final partidaResponse = await _insertPartida();
      if (!partidaResponse['success']) {
        setState(() {
          _isLoadingRoute = false;
        });
        return;
      }
      setState(() {
        status = 'Buscando detalhes da rota...';
      });
      await _getRoute();
    } catch (e, s) {
      if (!mounted) return;
      setState(() {
        status = 'Erro inesperado na inicialização: $e';
        _isLoadingRoute = false;
      });
    }
  }

  Future<Map<String, dynamic>> _insertPartida() async {
    final response = await _apiService.insertPartida(
      latitude: widget.latitude,
      longitude: widget.longitude,
      codUsur: widget.codUsur,
      routeInfo: widget.routeInfo,
    );

    if (!mounted) return {'success': false, 'message': 'Widget not mounted'};

    if (response['success'] == true) {
      setState(() {});
      return {'success': true};
    } else {
      setState(() {
        status = 'Erro ao registrar partida: ${response['message']}';
        _isLoadingRoute = false;
      });
      return {'success': false, 'message': response['message']};
    }
  }

  Future<void> _getRoute() async {
    try {
      final response = await _apiService.getRotaMobile(
        codUsur: widget.codUsur,
        routeInfo: widget.routeInfo,
      );

      if (!mounted) return;

      final route = response['data'];

      if (response['success'] == true && route != null && route.isNotEmpty) {
        _routeData = route;
        _updateMapWithRoute(_routeData!);
        setState(() {
          status = 'Rota carregada com sucesso!';
          _isLoadingRoute = false;
        });
      } else {
        setState(() {
          status =
              'Erro ao buscar rota: ${response['message'] ?? 'Resposta inválida da API'}';
          _isLoadingRoute = false;
        });
      }
    } catch (e, s) {
      if (!mounted) return;
      setState(() {
        status = 'Erro ao processar rota: $e';
        _isLoadingRoute = false;
      });
    }
  }

  void _updateMapWithRoute(Map<String, dynamic> route) {
    _markers.clear();
    _polylines.clear();

    try {
      final partida = route['partida'];
      final chegada = route['chegada'];

      if (partida == null || chegada == null) {
        setState(() {
          status = "Dados de partida ou chegada ausentes na resposta da API.";
          _isLoadingRoute = false;
        });
        return;
      }

      final LatLng startPoint = LatLng(
        double.parse(partida['latitude'].toString()),
        double.parse(partida['longitude'].toString()),
      );
      final LatLng endPoint = LatLng(
        double.parse(chegada['latitude'].toString()),
        double.parse(chegada['longitude'].toString()),
      );

      List<LatLng> polylinePoints = [startPoint];

      _markers.add(
        Marker(
          markerId: MarkerId('partida'),
          position: startPoint,
          infoWindow: InfoWindow(title: 'Partida'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );

      final List<dynamic> paradas =
          (route['paradas'] is List) ? route['paradas'] : [];
      for (int i = 0; i < paradas.length; i++) {
        var parada = paradas[i];
        if (parada['latitude'] != null && parada['longitude'] != null) {
          final LatLng paradaPoint = LatLng(
            double.parse(parada['latitude'].toString()),
            double.parse(parada['longitude'].toString()),
          );
          _markers.add(
            Marker(
              markerId: MarkerId('parada_$i'),
              position: paradaPoint,
              infoWindow: InfoWindow(title: 'Parada ${i + 1}'),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange,
              ),
            ),
          );
          polylinePoints.add(paradaPoint);
        }
      }

      _markers.add(
        Marker(
          markerId: MarkerId('chegada'),
          position: endPoint,
          infoWindow: InfoWindow(title: 'Chegada'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
      polylinePoints.add(endPoint);

      if (polylinePoints.length < 2) {
        setState(() {
          status = "Rota não possui pontos suficientes para traçar.";
          _isLoadingRoute = false;
        });
        return;
      }

      _polylines.add(
        Polyline(
          polylineId: const PolylineId('rota'),
          points: polylinePoints,
          color: Colors.blue,
          width: 5,
        ),
      );
      _moveCameraToBounds(polylinePoints);

      setState(() {});
    } catch (e, s) {
      setState(() {
        status = "Erro ao exibir rota no mapa.";
        _isLoadingRoute = false;
      });
    }
  }

  Future<void> _moveCameraToBounds(List<LatLng> points) async {
    if (points.isEmpty || _mapController == null) return;

    LatLngBounds bounds;
    if (points.length == 1) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(points[0], 15),
      );
      return;
    }

    final lats = points.map((e) => e.latitude);
    final lons = points.map((e) => e.longitude);

    bounds = LatLngBounds(
      southwest: LatLng(
        lats.reduce((a, b) => a < b ? a : b),
        lons.reduce((a, b) => a < b ? a : b),
      ),
      northeast: LatLng(
        lats.reduce((a, b) => a > b ? a : b),
        lons.reduce((a, b) => a > b ? a : b),
      ),
    );

    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(43, 43, 43, 1),
      appBar: AppBar(
        title: const Text(
          'Iniciar Viagem',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0261A3),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              if (_routeData != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (context) => TelaRoteiroGPS(routeData: _routeData!),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0261A3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Iniciar Viagem',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Card 2 - Informações do veículo
              if (_routeData != null && _routeData!['veiculo'] != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(66, 66, 66, 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informações do Veículo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Primeira coluna
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Modelo: ${_routeData!['veiculo']['modelo']}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Placa: ${_routeData!['veiculo']['placa']}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          // const SizedBox(width: 16), // Espaço entre as colunas
                          // Segunda coluna
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ano: ${_routeData!['veiculo']['ano']}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Capacidade: ${_routeData!['veiculo']['capacidade']} passageiros',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // Card 3 - Informações da viagem
              if (_routeData != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(66, 66, 66, 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informações da Viagem',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Partida: ${_routeData!['partida']['rua']}, ${_routeData!['partida']['numero']} - ${_routeData!['partida']['cidade']}/${_routeData!['partida']['estado']}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      Text(
                        'Chegada: ${_routeData!['chegada']['rua']}, ${_routeData!['chegada']['numero']} - ${_routeData!['chegada']['cidade']}/${_routeData!['chegada']['estado']}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      if (_routeData!['paradas'] != null &&
                          (_routeData!['paradas'] as List).isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Paradas:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        for (var parada in _routeData!['paradas'])
                          Text(
                            '${parada['rua']}, ${parada['numero']} - ${parada['cidade']}/${parada['estado']}',
                            style: const TextStyle(color: Colors.white),
                          ),
                      ],
                    ],
                  ),
                ),

              // Mapa
              Container(
                height: 320,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child:
                      _isLoadingRoute && _routeData == null
                          ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                          : GoogleMap(
                            mapType: MapType.normal,
                            initialCameraPosition: CameraPosition(
                              target:
                                  _initialCameraLocation ?? const LatLng(0, 0),
                              zoom: 5,
                            ),
                            markers: _markers,
                            polylines: _polylines,
                            onMapCreated: (GoogleMapController controller) {
                              _mapController = controller;
                              _controllerCompleter.complete(controller);
                            },
                            myLocationEnabled: !kIsWeb,
                            myLocationButtonEnabled: !kIsWeb,
                            zoomControlsEnabled: true,
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

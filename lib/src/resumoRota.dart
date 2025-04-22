import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'gps.dart';
import '../services/api.dart';

class ResumoRotaScreen extends StatefulWidget {
  final Map<String, dynamic> routeData;
  final List<RouteStep> steps;

  const ResumoRotaScreen({
    Key? key,
    required this.routeData,
    required this.steps,
  }) : super(key: key);

  @override
  _ResumoRotaScreenState createState() => _ResumoRotaScreenState();
}

class _ResumoRotaScreenState extends State<ResumoRotaScreen> {
  static const Color azulPrincipal = Color(0xFF0261A3);
  String? duracaoRota;
  Completer<GoogleMapController> _controllerCompleter = Completer();

  @override
  void initState() {
    super.initState();
    fetchDuracaoRota(widget.routeData['cod_rota']);
  }

  Future<void> fetchDuracaoRota(int codRota) async {
    final apiService = ApiService();
    final response = await apiService.getHorario(cod_rota: codRota);

    if (response['success']) {
      setState(() {
        duracaoRota = response['duracao'];
      });
    } else {
      print('Erro ao finalizar a rota: ${response['message']}');
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalDistanceKm =
        widget.steps
            .map((s) => s.distance)
            .fold<double>(0.0, (prev, distance) => prev + distance.toDouble()) /
        1000.0;
    int totalSteps = widget.steps.length;

    final infoPartida =
        widget.routeData['partida'] ?? 'Endereço não disponível';
    final infoChegada =
        widget.routeData['chegada'] ?? 'Endereço não disponível';

    return Scaffold(
      backgroundColor: const Color.fromRGBO(43, 43, 43, 1),
      appBar: AppBar(
        title: const Text('Resumo da rota finalizada'),
        backgroundColor: azulPrincipal,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const SizedBox(height: 16),
          _buildStartInfoCard(
            context,
            "${infoPartida['rua']} - ${infoPartida['numero']} / ${infoPartida['cidade']} - ${infoPartida['estado']}",
          ),
          const SizedBox(height: 16),
          _buildEndInfoCard(
            context,
            "${infoChegada['rua']} - ${infoChegada['numero']} / ${infoChegada['cidade']} - ${infoChegada['estado']}",
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            context: context,
            icon: Icons.route_outlined,
            title: 'Distância Total Percorrida',
            value: '${totalDistanceKm.toStringAsFixed(2)} km',
          ),
          const SizedBox(height: 8),
          _buildInfoCard(
            context: context,
            icon: Icons.format_list_numbered,
            title: 'Total de Instruções Seguidas',
            value: '$totalSteps',
          ),
          const SizedBox(height: 8),
          _buildInfoCard(
            context: context,
            icon: Icons.timer,
            title: 'Duração da Rota',
            value: duracaoRota ?? 'Carregando...',
          ),
          const SizedBox(height: 20),
          _buildStopsInfo(widget.routeData['paradas']),
          const SizedBox(height: 20),
          _buildRouteStepsDetails(),
          const SizedBox(height: 30),
          _buildMap(widget.routeData['paradas']),
          const SizedBox(height: 30),
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.home, color: Colors.white),
              label: const Text(
                'Voltar ao Início',
                style: TextStyle(color: Colors.white),
              ),
              onPressed:
                  () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
              style: ElevatedButton.styleFrom(
                backgroundColor: azulPrincipal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 36,
                  vertical: 16,
                ),
                textStyle: const TextStyle(fontSize: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartInfoCard(BuildContext context, String startAddress) {
    return Card(
      color: const Color.fromRGBO(66, 66, 66, 1),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Icon(Icons.directions, color: azulPrincipal, size: 30),
        title: const Text(
          'Partida',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        subtitle: Text(
          startAddress,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildEndInfoCard(BuildContext context, String endAddress) {
    return Card(
      color: const Color.fromRGBO(66, 66, 66, 1),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Icon(Icons.flag, color: azulPrincipal, size: 30),
        title: const Text(
          'Chegada',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        subtitle: Text(
          endAddress,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      color: const Color.fromRGBO(66, 66, 66, 1),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Icon(icon, color: azulPrincipal, size: 30),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        trailing: Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildStopsInfo(List<dynamic>? stops) {
    if (stops == null || stops.isEmpty) {
      return Card(
        color: const Color.fromRGBO(66, 66, 66, 1),
        elevation: 1,
        child: const Padding(
          padding: EdgeInsets.all(12.0),
          child: Text(
            'Nenhuma parada registrada nesta rota.',
            style: TextStyle(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Paradas Registradas:',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          color: const Color.fromRGBO(66, 66, 66, 1),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 12.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  stops.map((stop) {
                    final codParada = stop['cod_parada'] ?? '';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 18,
                            color: Colors.orange[700],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Parada $codParada: ${stop['rua']} - ${stop['numero']} / ${stop['cidade']} - ${stop['estado']}',
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRouteStepsDetails() {
    if (widget.steps.isEmpty) return const SizedBox.shrink();
    return ExpansionTile(
      title: const Text(
        'Detalhes dos Passos da Rota',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      initiallyExpanded: false,
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.steps.length,
          itemBuilder: (context, index) {
            final step = widget.steps[index];
            final startLat = step.start.latitude.toStringAsFixed(5);
            final startLng = step.start.longitude.toStringAsFixed(5);
            final endLat = step.end.latitude.toStringAsFixed(5);
            final endLng = step.end.longitude.toStringAsFixed(5);
            final distanceKm = (step.distance / 1000.0).toStringAsFixed(2);
            final instruction =
                step.instruction.replaceAll(RegExp(r'<[^>]*>'), ' ').trim();

            return Card(
              color: const Color.fromRGBO(66, 66, 66, 1),
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              elevation: 1,
              child: ListTile(
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text(
                  instruction.isEmpty ? "(Instrução sem texto)" : instruction,
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                ),
                subtitle: Text(
                  'Distância: $distanceKm km\nDe: ($startLat, $startLng)\nPara: ($endLat, $endLng)',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                isThreeLine: true,
                dense: true,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMap(List<dynamic>? stops) {
    List<LatLng> routePoints = widget.steps.map((step) => step.start).toList();
    routePoints.add(widget.steps.last.end);

    LatLngBounds bounds = _calculateBounds(routePoints);
    LatLng center = LatLng(
      (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
      (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
    );

    Set<Marker> stopMarkers = {};
    if (stops != null) {
      stopMarkers =
          stops.map((stop) {
            return Marker(
              markerId: MarkerId('stop_${stop['cod_parada']}'),
              position: LatLng(stop['latitude'], stop['longitude']),
              infoWindow: InfoWindow(title: 'Parada ${stop['cod_parada']}'),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange,
              ),
            );
          }).toSet();
    }

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: azulPrincipal, width: 2),
      ),
      child: GoogleMap(
        initialCameraPosition: CameraPosition(target: center, zoom: 12),
        markers: {
          Marker(
            markerId: const MarkerId('start'),
            position: widget.steps.first.start,
            infoWindow: const InfoWindow(title: 'Início'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ),
          ),
          Marker(
            markerId: const MarkerId('end'),
            position: widget.steps.last.end,
            infoWindow: const InfoWindow(title: 'Fim'),
          ),
          ...stopMarkers,
        },
        polylines: {
          Polyline(
            polylineId: const PolylineId('route'),
            color: azulPrincipal,
            width: 5,
            points: routePoints,
          ),
        },
        onMapCreated: (GoogleMapController controller) {
          _controllerCompleter.complete(controller);
          Future.delayed(Duration(milliseconds: 200), () {
            controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
          });
        },
      ),
    );
  }

  LatLngBounds _calculateBounds(List<LatLng> points) {
    double? minLat, maxLat, minLng, maxLng;

    for (LatLng point in points) {
      if (minLat == null || point.latitude < minLat) {
        minLat = point.latitude;
      }
      if (maxLat == null || point.latitude > maxLat) {
        maxLat = point.latitude;
      }
      if (minLng == null || point.longitude < minLng) {
        minLng = point.longitude;
      }
      if (maxLng == null || point.longitude > maxLng) {
        maxLng = point.longitude;
      }
    }

    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }
}

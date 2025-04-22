import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/api.dart'; // seu wrapper da Directions
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'resumoRota.dart'; // tela de resumo da rota

class ResumoRotaScreen extends StatelessWidget {
  final Map<String, dynamic> routeData;
  final List<_RouteStep> steps;

  ResumoRotaScreen({required this.routeData, required this.steps});

  @override
  Widget build(BuildContext context) {
    double totalDistance =
        steps.map((s) => s.distance).fold(0, (a, b) => a + b) / 1000.0;
    int totalSteps = steps.length;

    return Scaffold(
      appBar: AppBar(title: Text('Resumo da Rota')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Código da Rota: ${routeData['cod_rota']}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Distância Total: ${totalDistance.toStringAsFixed(2)} km',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Total de Passos: $totalSteps',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            _buildStopsInfo(routeData['paradas']),
            SizedBox(height: 8),
            _buildRouteSteps(),
          ],
        ),
      ),
    );
  }

  Widget _buildStopsInfo(List<dynamic>? stops) {
    if (stops == null || stops.isEmpty) {
      return Text('Nenhuma parada feita.', style: TextStyle(fontSize: 16));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paradas:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        ...stops.map(
          (stop) => Text(
            'Parada ${stop['cod_parada']}: ${stop['latitude']}, ${stop['longitude']}',
          ),
        ),
      ],
    );
  }

  Widget _buildRouteSteps() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Passos da Rota:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        ...steps.map((step) {
          if (step != null) {
            return Text(
              'De: ${step.start.latitude}, ${step.start.longitude} Para: ${step.end.latitude}, ${step.end.longitude}',
            );
          } else {
            return Text('Passo inválido');
          }
        }),
      ],
    );
  }
}

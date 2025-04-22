import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/api.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'resumoRota.dart';

class RouteStep {
  final LatLng start, end;
  final List<LatLng> polyline;
  final String instruction;
  final int distance;

  RouteStep({
    required this.start,
    required this.end,
    required this.polyline,
    required this.instruction,
    required this.distance,
  });
  @override
  String toString() {
    return 'RouteStep(start: $start, end: $end, distance: ${distance.toStringAsFixed(2)} km, instruction: $instruction)';
  }
}

class TelaRoteiroGPS extends StatefulWidget {
  final Map<String, dynamic> routeData;
  const TelaRoteiroGPS({Key? key, required this.routeData}) : super(key: key);

  @override
  _TelaRoteiroGPSState createState() => _TelaRoteiroGPSState();
}

class _TelaRoteiroGPSState extends State<TelaRoteiroGPS> {
  final Completer<GoogleMapController> _ctrl = Completer();
  StreamSubscription<Position>? _positionSub;

  Polyline? _routePolyline;
  List<RouteStep> _steps = [];
  int _currentStepIndex = 0;

  final List<Marker> _markers = [];
  Marker? _driverMarker;

  CameraPosition? _initialCamera;

  @override
  void initState() {
    super.initState();
    _checkPermissionAndLoad();
  }

  Future<void> _checkPermissionAndLoad() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse) {
      await _loadRouteAndStartGPS();
    } else {}
  }

  Future<void> _loadRouteAndStartGPS() async {
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    _initialCamera = CameraPosition(
      target: LatLng(pos.latitude, pos.longitude),
      zoom: 15,
    );

    _driverMarker = Marker(
      markerId: const MarkerId('driver'),
      position: LatLng(pos.latitude, pos.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
    );

    final sd = widget.routeData['partida'];
    final ed = widget.routeData['chegada'];
    final stops = List<Map<String, dynamic>>.from(
      widget.routeData['paradas'] ?? [],
    );

    _markers.clear();
    _markers.add(_driverMarker!);
    _markers.add(
      Marker(
        markerId: const MarkerId('start'),
        position: LatLng(sd['latitude'], sd['longitude']),
        infoWindow: const InfoWindow(title: 'Partida'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    );
    for (var p in stops) {
      _markers.add(
        Marker(
          markerId: MarkerId('stop_${p['cod_parada']}'),
          position: LatLng(p['latitude'], p['longitude']),
          infoWindow: InfoWindow(title: 'Parada ${p['cod_parada']}'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
        ),
      );
    }
    _markers.add(
      Marker(
        markerId: const MarkerId('end'),
        position: LatLng(ed['latitude'], ed['longitude']),
        infoWindow: const InfoWindow(title: 'Chegada'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );

    final resp = await ApiService.getDirections(
      start: sd,
      end: ed,
      stops: stops,
    );
    if (resp['success']) {
      final data = resp['data'];
      final legs = data['routes'][0]['legs'] as List;
      final stepsJson = legs.expand((leg) => leg['steps'] as List).toList();
      for (var s in stepsJson) {
        final poly = s['polyline']['points'];
      }

      _steps =
          stepsJson.map((s) {
            return RouteStep(
              start: LatLng(
                s['start_location']['lat'],
                s['start_location']['lng'],
              ),
              end: LatLng(s['end_location']['lat'], s['end_location']['lng']),

              polyline: _decodePolyline(s['polyline']['points']),
              instruction: s['html_instructions'],
              distance: s['distance']['value'],
            );
          }).toList();

      final all = <LatLng>[];
      for (var st in _steps) {
        all.addAll(
          st.polyline.where((p) => (p.latitude >= -85 && p.latitude <= 85)),
        );
      }
      for (var p in all) {
        if (p.latitude < -90 ||
            p.latitude > 90 ||
            p.longitude < -180 ||
            p.longitude > 180) {}
      }

      _routePolyline = Polyline(
        polylineId: const PolylineId('route'),
        points: all,
        color: Colors.blue,
        width: 6,
        geodesic: true,
      );

      if (all.isNotEmpty) {
        double minLat = all.first.latitude, maxLat = all.first.latitude;
        double minLng = all.first.longitude, maxLng = all.first.longitude;
        for (final p in all) {
          if (p.latitude < minLat) minLat = p.latitude;
          if (p.latitude > maxLat) maxLat = p.latitude;
          if (p.longitude < minLng) minLng = p.longitude;
          if (p.longitude > maxLng) maxLng = p.longitude;
        }
        _initialCamera = CameraPosition(
          target: LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2),
          zoom: 12,
        );
      }
    }

    setState(() {});

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen(_onPositionUpdate);
  }

  void _onPositionUpdate(Position pos) async {
    final latlng = LatLng(pos.latitude, pos.longitude);

    if (!_ctrl.isCompleted) {
      print("Google Map controller is not ready yet.");
      return;
    }

    try {
      final GoogleMapController c = await _ctrl.future;
      _driverMarker = _driverMarker!.copyWith(positionParam: latlng);
      _markers.removeWhere((m) => m.markerId.value == 'driver');
      _markers.insert(0, _driverMarker!);

      for (var i = 0; i < _steps.length; i++) {
        final distToEnd = Geolocator.distanceBetween(
          latlng.latitude,
          latlng.longitude,
          _steps[i].end.latitude,
          _steps[i].end.longitude,
        );

        if (distToEnd > 20) {
          _currentStepIndex = i;
          break;
        }
      }

      c.animateCamera(CameraUpdate.newLatLng(latlng));
      setState(() {});
    } catch (e) {
      print("Error updating position: $e");
    }
  }

  LatLngBounds _calculateBounds(List<LatLng> points) {
    double minLat = points.first.latitude, maxLat = points.first.latitude;
    double minLng = points.first.longitude, maxLng = points.first.longitude;
    for (var p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initialCamera == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final nextStep =
        (_steps.isNotEmpty && _currentStepIndex < _steps.length)
            ? _steps[_currentStepIndex]
            : null;

    double restante =
        _steps
            .skip(_currentStepIndex)
            .map((s) => s.distance)
            .fold(0, (a, b) => a + b) /
        1000.0;
    if (_routePolyline != null) {}
    return Scaffold(
      appBar: AppBar(
        title: Text('Navegação'),
        backgroundColor: Color(0xFF0261A3),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialCamera!,
            onMapCreated: (GoogleMapController controller) async {
              if (!_ctrl.isCompleted) {
                _ctrl.complete(controller);
              }

              if (_routePolyline != null && _routePolyline!.points.isNotEmpty) {
                LatLngBounds bounds = _calculateBounds(_routePolyline!.points);
                await controller.animateCamera(
                  CameraUpdate.newLatLngBounds(bounds, 50),
                );
              }
            },
            myLocationButtonEnabled: false,
            trafficEnabled: true,
            markers: Set.from(_markers),
            polylines:
                _routePolyline != null ? {_routePolyline!} : <Polyline>{},
          ),

          if (nextStep != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.white.withOpacity(0.95),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Próximo:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _stripHtml(nextStep.instruction),
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Distância: ${(nextStep.distance / 1000).toStringAsFixed(2)} km',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total restante: ${restante.toStringAsFixed(2)} km',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: ElevatedButton(
              onPressed: _finalizarRota,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(vertical: 16),
                textStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              child: Text('Finalizar Rota'),
            ),
          ),
        ],
      ),
    );
  }

  void _finalizarRota() async {
    final response = await ApiService().endRoute(
      cod_rota: widget.routeData['cod_rota'],
    );

    if (response['success']) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ResumoRotaScreen(
                routeData: widget.routeData,
                steps: _steps.where((step) => step != null).toList(),
              ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao finalizar a rota: ${response['message']}'),
        ),
      );
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> result = polylinePoints.decodePolyline(encoded);
    return result.map((e) => LatLng(e.latitude, e.longitude)).toList();
  }

  Set<Polyline> _createPolylines(List<LatLng> polylineCoordinates) {
    return {
      Polyline(
        polylineId: PolylineId('route'),
        points: polylineCoordinates,
        color: Colors.blue,
        width: 5,
      ),
    };
  }

  String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '');
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/api.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'resumoRota.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';

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
}

class TelaRoteiroGPS extends StatefulWidget {
  final Map<String, dynamic> routeData;
  final Map<String, dynamic> userData;

  const TelaRoteiroGPS({
    Key? key,
    required this.routeData,
    required this.userData,
  }) : super(key: key);

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

  @override
  void dispose() {
    _positionSub?.cancel();
    if (!_ctrl.isCompleted) {
      _ctrl.complete();
    }
    super.dispose();
  }

  Future<void> _checkPermissionAndLoad() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse) {
      await _loadRouteAndStartGPS();
    }
  }

  Future<BitmapDescriptor> _createDriverIcon() async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    const double circleRadius = 10;

    Paint paint = Paint()..color = Colors.blue;
    canvas.drawCircle(Offset(circleRadius, circleRadius), circleRadius, paint);
    final ui.Image img = await recorder.endRecording().toImage(
      circleRadius.toInt() * 2,
      circleRadius.toInt() * 2,
    );
    final ByteData? data = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  Future<void> _loadRouteAndStartGPS() async {
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    _initialCamera = CameraPosition(
      target: LatLng(pos.latitude, pos.longitude),
      zoom: 15,
    );

    final driverIcon = await _createDriverIcon();

    _driverMarker = Marker(
      markerId: const MarkerId('driver'),
      position: LatLng(pos.latitude, pos.longitude),
      icon: driverIcon,
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
    final DateTime dataHoraFim = DateTime.now();

    final codRota = widget.routeData['cod_rota'];
    final partida = widget.routeData['partida'];
    final chegada = widget.routeData['chegada'];

    if (codRota == null || partida == null || chegada == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Dados da rota incompletos.')));
      return;
    }

    final partidaLat = partida['latitude'];
    final partidaLng = partida['longitude'];
    final chegadaLat = chegada['latitude'];
    final chegadaLng = chegada['longitude'];

    if (partidaLat == null ||
        partidaLng == null ||
        chegadaLat == null ||
        chegadaLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dados de latitude ou longitude estão faltando.'),
        ),
      );
      return;
    }

    final double kmPercorrido =
        _steps.map((s) => s.distance).fold(0, (a, b) => a + b) / 1000.0;
    final int numParadas = widget.routeData['paradas']?.length ?? 0;

    final responseRouteInfo = await ApiService().insertRouteInfo(
      cod_rota: codRota,
      partidaLat: partidaLat,
      partidaLng: partidaLng,
      chegadaLat: chegadaLat,
      chegadaLng: chegadaLng,
      kmPercorrido: kmPercorrido,
      numParadas: numParadas,
      dataHoraFim: dataHoraFim,
    );

    if (responseRouteInfo == null || responseRouteInfo['success'] != true) {
      String errorMessage =
          responseRouteInfo?['message'] ??
          'Erro desconhecido ao finalizar a rota';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao finalizar a rota: $errorMessage')),
      );
      return;
    }

    final responseSteps = await ApiService().insertRouteSteps(
      cod_rota: codRota,
      steps: _steps,
    );

    if (responseSteps == null || responseSteps['success'] != true) {
      String errorMessage =
          responseSteps?['message'] ?? 'Erro desconhecido ao salvar os steps';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar os steps da rota: $errorMessage'),
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (context) => ResumoRotaScreen(
              routeData: widget.routeData,
              steps: _steps,
              userData: widget.userData,
            ),
      ),
    );
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

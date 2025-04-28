import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:controlefrotasmobilev1/services/api.dart';

class RouteStep {
  final LatLng start;
  final LatLng end;
  final double distance;
  final String instruction;

  RouteStep({
    required this.start,
    required this.end,
    required this.distance,
    required this.instruction,
  });

  factory RouteStep.fromJson(Map<String, dynamic> json) {
    final startLat = (json['start_lat'] as num?)?.toDouble() ?? 0.0;
    final startLng = (json['start_lng'] as num?)?.toDouble() ?? 0.0;
    final endLat = (json['end_lat'] as num?)?.toDouble() ?? 0.0;
    final endLng = (json['end_lng'] as num?)?.toDouble() ?? 0.0;
    final distanceKm = (json['distance'] as num?)?.toDouble() ?? 0.0;
    final instructionText = json['instruction']?.toString() ?? '';

    return RouteStep(
      start: LatLng(startLat, startLng),
      end: LatLng(endLat, endLng),
      distance: distanceKm,
      instruction: instructionText,
    );
  }
}

class ViagemDetalhesScreen extends StatefulWidget {
  final Map<String, dynamic> viagemData;

  const ViagemDetalhesScreen({super.key, required this.viagemData});

  @override
  State<ViagemDetalhesScreen> createState() => _ViagemDetalhesScreenState();
}

class _ViagemDetalhesScreenState extends State<ViagemDetalhesScreen> {
  static const Color azulPrincipal = Color(0xFF0261A3);
  static const Color backgroundCinza = Color.fromRGBO(43, 43, 43, 1);
  static const Color cardCinza = Color.fromRGBO(66, 66, 66, 1);

  Map<String, dynamic>? _rotaData;
  List<RouteStep> _steps = [];
  bool _isLoading = true;
  String? _errorLoading;
  late int _codRota;

  Completer<GoogleMapController> _controllerCompleter = Completer();

  @override
  void initState() {
    super.initState();
    print("ViagemDetalhesScreen initState");
    final codRotaValue = widget.viagemData['cod_rota'];

    if (codRotaValue != null && codRotaValue is int) {
      _codRota = codRotaValue;
      _fetchRotaCompleta();
    } else {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorLoading =
            "Erro Crítico: Código da Rota inválido ou não encontrado nos dados da viagem inicial.";
      });
      print(
        "Erro: cod_rota é nulo ou não é um inteiro: ${widget.viagemData['cod_rota']}",
      );
    }
  }

  @override
  void dispose() {
    if (!_controllerCompleter.isCompleted) {
      try {
        _controllerCompleter.complete();
        print("GoogleMap Completer finalizado no dispose (sem controller).");
      } catch (e) {
        print("Erro ao completar o Completer no dispose: $e");
      }
    } else {
      _controllerCompleter.future
          .then((controller) {
            print("Disposing GoogleMapController.");
            controller.dispose();
          })
          .catchError((e) {
            print("Erro ao obter controller para dispose: $e");
          });
    }
    super.dispose();
  }

  Future<void> _fetchRotaCompleta() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorLoading = null;
    });

    try {
      final response = await ApiService().getStepsRota(_codRota);
      print("Resposta Completa getStepsRota: $response");

      if (!mounted) return;

      if (response != null &&
          response['success'] == true &&
          response['rota'] != null) {
        final Map<String, dynamic> rota = response['rota'];
        final List<dynamic> stepsJson = rota['steps'] ?? [];
        final List<RouteStep> processedSteps =
            stepsJson
                .map(
                  (stepJson) =>
                      RouteStep.fromJson(stepJson as Map<String, dynamic>),
                )
                .toList();

        setState(() {
          _rotaData = rota;
          _steps = processedSteps;
          _isLoading = false;
        });
        print(
          "Dados da Rota carregados com sucesso. ${_steps.length} steps processados.",
        );
      } else {
        final errorMessage =
            response?['message'] ??
            'Erro desconhecido ao buscar detalhes da rota.';
        throw Exception(errorMessage);
      }
    } catch (e, stacktrace) {
      print("Erro ao buscar dados da rota $_codRota: $e");
      print("Stacktrace: $stacktrace");
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorLoading = "Erro ao carregar detalhes: $e";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorLoading!),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty)
      return 'Não informado';
    try {
      DateTime? dateTime;
      try {
        dateTime = DateTime.parse(dateTimeString);
      } catch (_) {
        try {
          dateTime = DateFormat("yyyy-MM-dd HH:mm:ss").parse(dateTimeString);
        } catch (e) {
          print("Erro ao formatar data/hora: $dateTimeString - $e");
          return 'Data inválida';
        }
      }
      return DateFormat('dd/MM/yyyy \'às\' HH:mm:ss').format(dateTime);
    } catch (e) {
      print("Erro geral ao formatar data: $dateTimeString - $e");
      return 'Data inválida';
    }
  }

  String _prettyPrintMap(Map<String, dynamic> map) {
    final buffer = StringBuffer();
    buffer.writeln('{');
    map.forEach((key, value) {
      final valueString =
          value is String
              ? '"${value.replaceAll('"', '\\"')}"'
              : value.toString();
      buffer.writeln('  "$key": $valueString,');
    });
    String result = buffer.toString().trim();
    if (map.isNotEmpty && result.endsWith(',')) {
      result = result.substring(0, result.length - 1);
    }
    return result + '\n}';
  }

  Widget _buildStatusSection(Map<String, dynamic> rotaData) {
    final status = rotaData['status'] as String?;
    final descStatus = rotaData['desc_status'] as String?;
    final supervisorData = rotaData['supervisor'] as Map<String, dynamic>?;
    final nomeSupervisor = supervisorData?['nome_supervisor'] as String?;

    Color statusColor;
    String statusTexto;
    IconData statusIcon;

    switch (status?.toLowerCase()) {
      case 'aprovado':
      case 'finalizada':
        statusColor = Colors.green.shade400;
        statusTexto = status ?? "Aprovado";
        statusIcon = Icons.check_circle_outline;
        break;
      case 'reprovado':
        statusColor = Colors.red.shade400;
        statusTexto = 'Reprovado';
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = Colors.orange.shade400;
        statusTexto = 'Pendente';
        statusIcon = Icons.pending_outlined;
    }

    if (statusTexto.isNotEmpty) {
      statusTexto = statusTexto[0].toUpperCase() + statusTexto.substring(1);
    }
    final bool showSupervisor =
        status != null &&
        status.toLowerCase() != 'pendente' &&
        nomeSupervisor != null &&
        nomeSupervisor.isNotEmpty;

    return Card(
      color: cardCinza,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 28),
                const SizedBox(width: 12),
                Text(
                  statusTexto,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            if (descStatus != null && descStatus.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: Text(
                  descStatus,
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ),
            ],
            if (showSupervisor) ...[
              const Divider(height: 20, thickness: 0.5, color: Colors.white24),
              Row(
                children: [
                  Icon(
                    Icons.supervisor_account_outlined,
                    color: Colors.blueGrey[300],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Supervisionado por:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blueGrey[200],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      nomeSupervisor!,
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStartInfoCard(
    BuildContext context,
    Map<String, dynamic>? startData,
  ) {
    final address =
        (startData != null)
            ? "${startData['rua'] ?? ''} - ${startData['numero'] ?? ''} / ${startData['cidade'] ?? ''} - ${startData['estado'] ?? ''}"
            : 'Endereço de partida não disponível';

    return Card(
      color: cardCinza,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Icon(Icons.directions, color: azulPrincipal, size: 30),
        title: const Text(
          'Partida',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        subtitle: Text(
          address,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildEndInfoCard(
    BuildContext context,
    Map<String, dynamic>? endData,
  ) {
    final address =
        (endData != null)
            ? "${endData['rua'] ?? ''} - ${endData['numero'] ?? ''} / ${endData['cidade'] ?? ''} - ${endData['estado'] ?? ''}"
            : 'Endereço de chegada não disponível';

    return Card(
      color: cardCinza,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Icon(Icons.flag, color: azulPrincipal, size: 30),
        title: const Text(
          'Chegada',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        subtitle: Text(
          address,
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
    Color? valueColor,
  }) {
    return Card(
      color: cardCinza,
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
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildStopsInfo(List<dynamic>? stops) {
    if (stops == null || stops.isEmpty) {
      return Card(
        color: cardCinza,
        elevation: 1,
        child: const Padding(
          padding: EdgeInsets.all(12.0),
          child: Text(
            'Nenhuma parada registrada nesta rota.',
            style: TextStyle(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: Text(
            'Paradas Registradas:',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        Card(
          color: cardCinza,
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
                    if (stop is! Map<String, dynamic>) {
                      return const Text(
                        "Dado de parada inválido.",
                        style: TextStyle(color: Colors.redAccent),
                      );
                    }
                    final codParada = stop['cod_parada'] ?? 'N/A';
                    final address =
                        "${stop['rua'] ?? ''} - ${stop['numero'] ?? ''} / ${stop['cidade'] ?? ''} - ${stop['estado'] ?? ''}";
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
                              'Parada $codParada: $address',
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

  Widget _buildRouteStepsDetails(List<RouteStep> steps) {
    if (steps.isEmpty) return const SizedBox.shrink();
    return ExpansionTile(
      iconColor: Colors.white70,
      collapsedIconColor: Colors.white70,
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
          itemCount: steps.length,
          itemBuilder: (context, index) {
            final step = steps[index];
            final instruction =
                step.instruction
                    .replaceAll(RegExp(r'<[^>]*>'), ' ')
                    .replaceAll(' ', ' ')
                    .replaceAll('&wbr;', '')
                    .trim();
            final distanceKm = step.distance.toStringAsFixed(2);
            return Card(
              color: cardCinza.withOpacity(0.8),
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              elevation: 1,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: azulPrincipal,
                  foregroundColor: Colors.white,
                  child: Text('${index + 1}'),
                ),
                title: Text(
                  instruction.isEmpty ? "(Instrução vazia)" : instruction,
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                ),
                subtitle: Text(
                  'Distância: $distanceKm km',
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                ),
                dense: true,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMap(List<RouteStep> steps, List<dynamic>? stops) {
    if (steps.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: cardCinza,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[600]!, width: 1),
        ),
        child: const Text(
          'Não há dados de rota para exibir o mapa.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }
    List<LatLng> routePoints = steps.map((step) => step.start).toList();
    routePoints.add(steps.last.end);
    LatLngBounds bounds = _calculateBounds(routePoints);
    LatLng center = LatLng(
      (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
      (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
    );

    Set<Marker> stopMarkers = {};
    if (stops != null) {
      stopMarkers =
          stops
              .whereType<Map<String, dynamic>>()
              .map((stop) {
                final lat = (stop['latitude'] as num?)?.toDouble();
                final lng = (stop['longitude'] as num?)?.toDouble();
                final codParada = stop['cod_parada'] ?? 'N/A';
                if (lat == null || lng == null) return null;
                return Marker(
                  markerId: MarkerId('stop_$codParada'),
                  position: LatLng(lat, lng),
                  infoWindow: InfoWindow(title: 'Parada $codParada'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueOrange,
                  ),
                );
              })
              .whereType<Marker>()
              .toSet();
    }

    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: azulPrincipal, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6.0),
        child: GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition: CameraPosition(target: center, zoom: 11),
          markers: {
            Marker(
              markerId: const MarkerId('start'),
              position: steps.first.start,
              infoWindow: const InfoWindow(title: 'Início'),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueBlue,
              ),
            ),
            Marker(
              markerId: const MarkerId('end'),
              position: steps.last.end,
              infoWindow: const InfoWindow(title: 'Fim'),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
            ),
            ...stopMarkers,
          },
          polylines: {
            Polyline(
              polylineId: const PolylineId('route'),
              color: azulPrincipal.withOpacity(0.8),
              width: 5,
              points: routePoints,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            ),
          },
          onMapCreated: (GoogleMapController controller) {
            print("GoogleMap onMapCreated - Controller recebido.");
            if (!_controllerCompleter.isCompleted) {
              _controllerCompleter.complete(controller);
              print("GoogleMap Completer completado com sucesso.");
              Future.delayed(const Duration(milliseconds: 400), () {
                if (mounted) {
                  print("Animando câmera para os limites da rota...");
                  controller.animateCamera(
                    CameraUpdate.newLatLngBounds(bounds, 60.0),
                  );
                } else {
                  print("Widget desmontado antes da animação da câmera.");
                }
              });
            } else {
              print("GoogleMap onMapCreated - Completer já estava completo.");
              controller.animateCamera(
                CameraUpdate.newLatLngBounds(bounds, 60.0),
              );
            }
          },
          zoomGesturesEnabled: true,
          scrollGesturesEnabled: true,
          tiltGesturesEnabled: false,
          rotateGesturesEnabled: true,
          myLocationButtonEnabled: false,
          myLocationEnabled: false,
        ),
      ),
    );
  }

  LatLngBounds _calculateBounds(List<LatLng> points) {
    if (points.isEmpty) {
      return LatLngBounds(
        southwest: const LatLng(0, 0),
        northeast: const LatLng(0, 0),
      );
    }
    double minLat = points.first.latitude, maxLat = points.first.latitude;
    double minLng = points.first.longitude, maxLng = points.first.longitude;
    for (LatLng point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }
    const double padding = 0.001;
    return LatLngBounds(
      southwest: LatLng(minLat - padding, minLng - padding),
      northeast: LatLng(maxLat + padding, maxLng + padding),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundCinza,
      appBar: AppBar(
        title: Text(
          'Detalhes da Rota ${_rotaData?['cod_rota'] ?? widget.viagemData['cod_rota'] ?? ''}',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: azulPrincipal,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: azulPrincipal),
      );
    }

    if (_errorLoading != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 50,
              ),
              const SizedBox(height: 15),
              Text(
                'Erro ao Carregar Detalhes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[100],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                _errorLoading!,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text("Tentar Novamente"),
                onPressed: _fetchRotaCompleta,
                style: ElevatedButton.styleFrom(backgroundColor: azulPrincipal),
              ),
            ],
          ),
        ),
      );
    }
    if (_rotaData == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            'Dados da rota indisponíveis.',
            style: TextStyle(color: Colors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final partidaData = _rotaData!['partida'] as Map<String, dynamic>?;
    final chegadaData = _rotaData!['chegada'] as Map<String, dynamic>?;
    final paradasData = _rotaData!['paradas'] as List<dynamic>?;
    final veiculoData = _rotaData!['veiculo'] as Map<String, dynamic>?;
    final motoristaData = _rotaData!['motorista'] as Map<String, dynamic>?;

    final double totalDistanceKm = _steps.fold(
      0.0,
      (prev, step) => prev + step.distance,
    );
    final int totalSteps = _steps.length;
    final String duracaoRota = _rotaData!['duracao']?.toString() ?? 'N/A';
    final String nomeMotorista =
        motoristaData?['nome_motorista']?.toString() ?? 'Não informado';

    final String nomeMotoristaCapitalized =
        nomeMotorista.isNotEmpty
            ? nomeMotorista[0].toUpperCase() + nomeMotorista.substring(1)
            : nomeMotorista;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildStatusSection(_rotaData!),
        const SizedBox(height: 16),
        _buildStartInfoCard(context, partidaData),
        const SizedBox(height: 16),
        _buildEndInfoCard(context, chegadaData),
        const SizedBox(height: 16),
        _buildInfoCard(
          context: context,
          icon: Icons.route_outlined,
          title: 'Distância Total',
          value: '${totalDistanceKm.toStringAsFixed(2)} km',
        ),
        const SizedBox(height: 8),
        _buildInfoCard(
          context: context,
          icon: Icons.timer,
          title: 'Duração Estimada',
          value: duracaoRota,
        ),
        const SizedBox(height: 8),
        _buildInfoCard(
          context: context,
          icon: Icons.format_list_numbered,
          title: 'Total de Passos',
          value: '$totalSteps',
        ),
        const SizedBox(height: 8),
        if (veiculoData != null)
          _buildInfoCard(
            context: context,
            icon: Icons.directions_car,
            title: 'Veículo',
            value:
                '${veiculoData['modelo'] ?? 'N/I'} - ${veiculoData['placa'] ?? 'N/I'}',
          ),
        const SizedBox(height: 8),
        _buildInfoCard(
          context: context,
          icon: Icons.person_outline,
          title: 'Condutor',
          value: nomeMotoristaCapitalized,
        ),
        const SizedBox(height: 20),
        _buildStopsInfo(paradasData),
        const SizedBox(height: 20),
        _buildMap(_steps, paradasData),
        const SizedBox(height: 20),
        _buildRouteStepsDetails(_steps),
        const SizedBox(height: 30),
      ],
    );
  }
}

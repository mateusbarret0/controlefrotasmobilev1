import 'package:flutter/material.dart';
import '../services/api.dart'; // ajuste o caminho conforme necessário

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

  @override
  void initState() async {
    super.initState();
    await _insertPartida();
    await _getRoute();
  }

  Future<void> _insertPartida() async {
    final response = await _apiService.insertPartida(
      latitude: widget.latitude,
      longitude: widget.longitude,
      codUsur: widget.codUsur,
      routeInfo: widget.routeInfo,
    );

    if (response['success'] == true) {
      setState(() {
        status = 'Viagem iniciada com sucesso!';
      });
    } else {
      setState(() {
        status = 'Erro ao iniciar viagem: ${response['message']}';
      });
    }
  }

  Future<void> _getRoute() async {
    final response = await _apiService.getRoute(
      latitude: widget.latitude,
      longitude: widget.longitude,
    );

    if (response['success'] == true) {
      setState(() {
        status = 'Viagem iniciada com sucesso!';
      });
    } else {
      setState(() {
        status = 'Erro ao iniciar viagem: ${response['message']}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Iniciar Viagem')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Latitude: ${widget.latitude}'),
            Text('Longitude: ${widget.longitude}'),
            SizedBox(height: 20),
            Text(status),
          ],
        ),
      ),
    );
  }
}

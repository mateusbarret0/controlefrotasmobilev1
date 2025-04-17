import 'package:flutter/material.dart';

class IniciarViagem extends StatelessWidget {
  final double latitude;
  final double longitude;

  const IniciarViagem({
    Key? key,
    required this.latitude,
    required this.longitude,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Iniciar Viagem')),
      body: Center(child: Text('Latitude: $latitude\nLongitude: $longitude')),
    );
  }
}

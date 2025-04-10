class VehicleData {
  final String id;
  final String plate;
  final String model;
  final String currentRoute;

  VehicleData({
    required this.id,
    required this.plate,
    required this.model,
    required this.currentRoute,
  });

  factory VehicleData.fromJson(Map<String, dynamic> json) {
    return VehicleData(
      id: json['id'],
      plate: json['plate'],
      model: json['model'],
      currentRoute: json['current_route'],
    );
  }
}

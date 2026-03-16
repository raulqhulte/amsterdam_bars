class Bar {
  final String id;
  final String name;
  final double latitude;
  final double longitude;

  Bar({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory Bar.fromMap(Map<String, dynamic> map) {
    return Bar(
      id: map['id'],
      name: map['name'],
      latitude: map['latitude'],
      longitude: map['longitude'],
    );
  }
}

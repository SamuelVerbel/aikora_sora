class Trip {
  final String? id;
  final String destinationName;
  final String? destinationId;
  final String type;
  final int travelers;
  final double budget;
  final DateTime startDate;
  final DateTime endDate;

  Trip({
    this.id,
    required this.destinationName,
    this.destinationId,
    required this.type,
    required this.travelers,
    required this.budget,
    required this.startDate,
    required this.endDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'destination_name': destinationName,
      'destination_id': destinationId,
      'type': type,
      'travelers': travelers,
      'budget': budget,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
    };
  }

  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      id: map['id'],
      destinationName: map['destination_name'],
      destinationId: map['destination_id'],
      type: map['type'],
      travelers: map['travelers'],
      budget: (map['budget'] as num).toDouble(),
      startDate: DateTime.parse(map['start_date']),
      endDate: DateTime.parse(map['end_date']),
    );
  }
}
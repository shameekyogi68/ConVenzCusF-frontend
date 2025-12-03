class Booking {
  final String id;
  final String vendorName;
  final String serviceName;
  final double price;
  final String status;
  final String date;

  Booking({
    required this.id,
    required this.vendorName,
    required this.serviceName,
    required this.price,
    required this.status,
    required this.date,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    // Handle populated fields safely
    final vendor = json['vendorId'] ?? {};
    final service = json['servicesId'] ?? {};

    return Booking(
      id: json['_id'] ?? '',
      // If vendor/service details are missing, show placeholders
      vendorName: vendor['name'] ?? 'Unknown Vendor',
      serviceName: service['name'] ?? 'General Service',
      price: (json['price'] ?? 0).toDouble(),
      status: json['bookingStatus'] ?? 'pending',
      date: json['booking_createdAt'] ?? DateTime.now().toString(),
    );
  }
}
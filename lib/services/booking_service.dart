import '../services/api_service.dart';
import '../utils/shared_prefs.dart';
import '../models/booking.dart';

class BookingService {

  // ----------------------------------------------------------
  // 📅 GET USER BOOKINGS
  // ----------------------------------------------------------
  static Future<List<Booking>> getUserBookings() async {
    try {
      String? userId = SharedPrefs.getUserId();
      if (userId == null) return [];

      // Call GET /api/booking/user/:userId
      final res = await ApiService.get("/booking/user/$userId");

      if (res['success'] == true) {
        List<dynamic> data = res['data'];
        return data.map((json) => Booking.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print("❌ Error fetching bookings: $e");
      return [];
    }
  }

  // ----------------------------------------------------------
  // 📝 CREATE BOOKING (Call this when user clicks "Book Now")
  // ----------------------------------------------------------
  static Future<Map<String, dynamic>> createBooking({
    required String vendorId,
    required String serviceId,
    required double price,
  }) async {
    String? userId = SharedPrefs.getUserId();
    if (userId == null) return {"success": false, "message": "User not logged in"};

    final res = await ApiService.post("/booking/create", {
      "userId": userId,
      "vendorId": vendorId,
      "servicesId": serviceId,
      "price": price
    });

    return res;
  }
}
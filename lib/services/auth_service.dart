import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../utils/shared_prefs.dart';

class AuthService {
  // ... (register, verify, etc. unchanged) ...

  static Future<Map<String, dynamic>> registerUser(String phone) async {
    // Get FCM token FIRST before registration
    String? fcmToken = NotificationService.getFcmToken();
    
    // Send both phone and fcmToken in registration request
    final res = await ApiService.post("/register", {
      "phone": phone,
      "fcmToken": fcmToken,
    });
    
    if (res["success"] == true) {
      await SharedPrefs.savePhone(phone);
      if (res["userId"] != null) {
        await SharedPrefs.saveUserId(res["userId"].toString());
      }
      await SharedPrefs.saveIsNewUser(res["isNewUser"] ?? true);
      
      // Refresh and send FCM token to backend after registration (backup)
      await NotificationService.refreshAndSendToken();
    }
    return res;
  }

  static Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    final res = await ApiService.post("/verify-otp", {"phone": phone, "otp": otp});
    if (res["success"] == true) {
      if (res["userId"] != null) {
        await SharedPrefs.saveUserId(res["userId"].toString());
      } else if (res["user"] != null && res["user"]["user_id"] != null) {
        await SharedPrefs.saveUserId(res["user"]["user_id"].toString());
      }
      await SharedPrefs.saveIsNewUser(res["isNewUser"] ?? true);
      
      // Refresh and send FCM token to backend after OTP verification
      await NotificationService.refreshAndSendToken();
    }
    return res;
  }

  static Future<Map<String, dynamic>> updateUserDetails(String phone, String name, String gender) async {
    final res = await ApiService.post("/update-user", {"phone": phone, "name": name, "gender": gender});
    if (res["success"] == true) {
      await SharedPrefs.saveUserName(name);
      await SharedPrefs.saveGender(gender);
      await SharedPrefs.saveIsNewUser(false);
    }
    return res;
  }

  // ✅ FIX: Ensure correct endpoint for fetching profile
  static Future<Map<String, dynamic>> getUserDetails(String userId) async {
    // Backend route: /api/user/profile/:userId
    final res = await ApiService.get("/profile/$userId");

    // Return the response 'data' directly if that's how your backend structures it
    // Or return the whole response and let UI parse it (preferred)
    return res;
  }

  static Future<Map<String, dynamic>> updateVendorLocation(String userId, double latitude, double longitude) async {
    final res = await ApiService.post("/update-location", {
      "userId": userId,
      "latitude": latitude,
      "longitude": longitude,
    });
    return res;
  }
}
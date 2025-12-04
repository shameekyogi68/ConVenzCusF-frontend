import '../utils/shared_prefs.dart';
import '../services/api_service.dart';

class ProfileService {
  // 🔹 GET USER PROFILE
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final userId = SharedPrefs.getUserId();

      if (userId == null) {
        return {"success": false, "message": "❌ User ID not found"};
      }

      print("📡 Fetching Profile for User ID: $userId");
      // Calls /api/user/profile/1
      final response = await ApiService.get("/user/profile/$userId");
      print("📥 Profile Response: $response");

      return response;
    } catch (e) {
      print("❌ Profile Service Error: $e");
      return {
        "success": false,
        "message": "Failed to fetch profile: $e"
      };
    }
  }

  // 🔹 UPDATE PROFILE
  static Future<Map<String, dynamic>> updateProfile({required String name}) async {
    final userId = SharedPrefs.getUserId();
    final phone = SharedPrefs.getPhone();

    if (userId == null) {
      return {"success": false, "message": "❌ User ID not found"};
    }

    final response = await ApiService.post(
      "/profile/$userId",
      {
        "name": name,
        "phone": phone,
      },
    );

    if (response["success"] == true && response["data"] != null) {
      await SharedPrefs.saveUserName(response["data"]["name"]);
    }

    return response;
  }
}